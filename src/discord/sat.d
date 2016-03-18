module discord.sat;

import std.math;
import std.range;
import std.traits;
import std.algorithm;

import discord.shape;
import discord.geometry;

enum isSphere(T) = is(T : Sphere!(U, 2), U);

auto separate(A, B)(in A a, in B b) if (isShape!A && isShape!B) {
    return a.visitAny!(_a => b.visitAny!(_b => separate(_a, _b)));
}

auto separate(A, B)(in A a, in B b) if (isShapeKind!A && isShapeKind!B)
{
    alias D = CommonType!(DimensionType!A, DimensionType!B);

    auto minAxis = Vector!(D, 2)(0, 0);
    D minOverlap = D.max;

     /* Consider the projection of each shape onto each axis of separation.
      * We are looking for the axis with the minimum overlap.
      * A vector along this axis with the length of the overlap is the minimum
      * separation needed to push `a` out of intersection with `b`.
      */
    foreach(axis ; separatingAxes(a, b)) {
        auto spanA = project(a, axis);
        auto spanB = project(b, axis);
        D overlap;

        if (spanA[1] < spanB[0] || spanA[0] > spanB[1]) {
            /* There is no overlap along the current axis:
             *      A: a0|------|a1
             *      B:               b0|---------|b1
             * or
             *      A:               a0|------|a1
             *      B: b0|---------|b1
             * This implies the shapes do not overlap at all - bail out early!
             */
            return Vector!(D, 2)(0, 0);
        }

        if ((overlap = spanA[1] - spanB[0]) > 0 && overlap < abs(minOverlap)) {
            /*      A:   a0|------|a1
             *      B:      b0|---------|b1
             *                +---+ (overlap)
             * A must be pushed in the - direction across this axis to separate
             */
            minOverlap = -overlap;
            minAxis = axis;
        }

        // this is deliberately not an else-if; the previous if could pass but
        // we have an even smaller overlap in this direction.
        // this is important if one span contains the other.
        if ((overlap = spanB[1] - spanA[0]) > 0 && overlap < abs(minOverlap)) {
            /*     A:        a0|------|a1
             *     B: b0|---------|b1
             *                 +--+ (overlap)
             * A must be pushed in the + direction across this axis to separate
             */
            minOverlap = overlap;
            minAxis = axis;
        }
    }

    return minAxis * minOverlap;
}

unittest {
    auto test(float[4] a, float[4] b, vec2f expected) {
        auto boxA = box2f(a[0], a[1], a[2], a[3]);
        auto boxB = box2f(b[0], b[1], b[2], b[3]);

        auto res1 = separate(boxA, boxB);
        assert(res1.x.approxEqual(expected.x));
        assert(res1.y.approxEqual(expected.y));

        // reversing the order should reverse the separation vector
        auto res2 = separate(boxB, boxA);
        //assert(res2.x.approxEqual(-expected.x));
        //assert(res2.y.approxEqual(-expected.y));
    }

    // no intersection
    test([0,0,4,4], [0,5,6,6], vec2f( 0, 0));
    test([0,0,4,4], [5,0,6,6], vec2f( 0, 0));
    test([0,0,4,4], [5,5,6,6], vec2f( 0, 0));

    test([0,0,4,4], [0,3,6,6], vec2f( 0,-1)); // A above B
    test([0,0,4,4], [3,0,6,6], vec2f(-1, 0)); // A left of B
    test([0,0,4,4], [2,3,6,6], vec2f( 0,-1)); // min overlap is up
    test([0,0,4,4], [3,2,6,6], vec2f(-1, 0)); // min overlap is left

    // A contains B
    test([0,0,4,4], [0,0,2,1], vec2f( 0, 1));
    test([0,0,4,4], [0,0,2,3], vec2f( 2, 0));
}

unittest {
    auto sep(float[2] ac, float ar, float[2] bc, float br) {
        return separate(sphere2f(vec2f(ac), ar), sphere2f(vec2f(bc), br));
    }

    assert(sep([0, 0], 4, [6, 0], 3) == vec2f(-1, 0));
    assert(sep([0, 0], 4, [7, 0], 3) == vec2f( 0, 0));
    assert(sep([0, 0], 4, [8, 0], 3) == vec2f( 0, 0));
    assert(sep([6, 0], 3, [0, 0], 4) == vec2f( 1, 0)); // reverse of first case
}

private:
// order-insensitive range comparison for tests
version(unittest)
    auto equivalent(R1, R2)(R1 r1, R2 r2) {
        return r1.length == r2.length && r1.all!(a => r2.canFind(a));
    }

auto separatingAxes(A, B)(A a, B b) {
    static if (hasVertices!A && hasVertices!B)
            return chain(a.axes, b.axes);
    else static if (hasVertices!A && isSphere!B)
        // for a circle and a polygon, draw a line from the circle's center through
        // each vertex of the polygon. Each of these is a separating axis.
        // combine this with the normals of the polygon's edges to get all axes.
        return a.vertices
            .map!(x => x - b.center)
            .chain(a.axes);
    else static if (hasVertices!B && isSphere!A)
        return separatingAxes(b, a);
    else static if (isSphere!A && isSphere!B)
        return only((a.center - b.center).normalized);
}

unittest {
    assert(seg2f(vec2f(0, 0), vec2f(5, 0)).axes.equivalent(
            [vec2f(0, -1), vec2f(0, 1)]));

    assert(seg2f(vec2f(0, 0), vec2f(0, 4)).axes.equivalent(
            [vec2f(-1, 0), vec2f(1, 0)]));
}

auto axes(T)(in T t) {
    static if (is(T : Box!(U, 2), U))
        // specialization for AABB -- we know it only has two axes (the x/y axes)
        return only(vec2f(1, 0), vec2f(0, 1));
    else
        // in the general case, the axes are the normals of a shape's edges
        return t.edges.map!(x => x.normal);
}

unittest {
    assert(seg2f(vec2f(0, 0), vec2f(5, 0)).axes.equivalent(
            [vec2f(0, -1), vec2f(0, 1)]));

    assert(seg2f(vec2f(0, 0), vec2f(0, 4)).axes.equivalent(
            [vec2f(-1, 0), vec2f(1, 0)]));
}

// Project a polygon onto an axis
auto project(T, V)(T poly, V axis) if (hasVertices!T) {
    alias D = DimensionType!T;
    D[2] span = [D.max, 0];
    foreach(v ; poly.vertices) {
        auto scalarProj = v.dot(axis);
        span[0] = min(span[0], scalarProj);
        span[1] = max(span[1], scalarProj);
    }

    return span;
}

unittest {
    assert(box2f(2, 4, 6, 8).project(vec2f(1, 0)) == [2, 6]);
    assert(box2f(2, 4, 6, 8).project(vec2f(0, 1)) == [4, 8]);
    assert(seg2f(vec2f(2, 3), vec2f(4, 8)).project(vec2f(1, 0)) == [2, 4]);
    assert(seg2f(vec2f(2, 3), vec2f(4, 8)).project(vec2f(0, 1)) == [3, 8]);
}

// Project a sphere onto an axis
auto project(T, V)(T sphere, V axis) if (isSphere!T) {
    alias D = DimensionType!T;

    // the projection is the diameter along the given axis
    auto m = sphere.center.dot(axis);
    D[2] span = [m - sphere.radius, m + sphere.radius];

    return span;
}

unittest {
    assert(sphere2f(vec2f(3, 4), 2).project(vec2f(1, 0)) == [1, 5]);
    assert(sphere2f(vec2f(3, 4), 2).project(vec2f(0, 1)) == [2, 6]);
}
