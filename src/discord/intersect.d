module discord.intersect;

import std.range;
import std.algorithm;

import gfm.math;
import discord.geometry;

/**
 * Determine if and where two rays intersect.
 *
 * If the rays are identical, returns the first point they meet.
 *
 * Params:
 * a = first ray
 * b = second ray
 *
 * Returns:
 * The point of intersection,
 */
auto intersect(ray2f a, ray2f b) {
    float u, v;
    rayIntersectProgress(a, b, u, v);
    return (u > 0 && v > 0) ? intersection(a.progress(u)) : noIntersection;
}

unittest {
    // Validate that the ray (as, ad) intersects the ray (bs, bd) at p
    bool yes(float[2] as, float[2] ad, float[2] bs, float[2] bd, float[2] p) {
        import std.math : approxEqual;

        immutable a = ray2f(vec2f(as), vec2f(ad)),
                  b = ray2f(vec2f(bs), vec2f(bd)),
                  res = intersect(a, b);

        return res && res.x.approxEqual(p[0]) && res.y.approxEqual(p[1]);
    }

    // Validate that the ray (as, ad) doesn't intersect the ray (bs, bd)
    bool no(float[2] as, float[2] ad, float[2] bs, float[2] bd) {
        immutable r1 = ray2f(vec2f(as), vec2f(ad)),
                  r2 = ray2f(vec2f(bs), vec2f(bd));
        return !intersect(r1, r2);
    }

    //            as        ad        bs        bd        p
    assert(yes([ 0, 0 ], [ 1, 1 ], [ 0, 2 ], [ 1,-1 ], [ 1, 1 ]));
    assert(yes([ 0, 0 ], [ 4, 4 ], [ 0, 2 ], [ 8,-8 ], [ 1, 1 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 4, 0 ], [ 0, 1 ], [ 4, 2 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 3, 1 ], [ 1, 1 ], [ 4, 2 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 5, 1 ], [-1, 1 ], [ 4, 2 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 4, 5 ], [ 0,-1 ], [ 4, 2 ]));

    //            as        ad        bs        bd
    assert(no([ 0, 0 ], [ 2, 1 ], [-1,-1 ], [ 0, 1 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 1, 1 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 1, 0 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 0, 1 ]));
    assert(no([ 0, 0 ], [ 1, 0 ], [ 1, 0 ], [ 1, 0 ])); // parallel
}

/**
 * Determine if and where two rays intersect.
 *
 * If the rays are identical, returns the first point they meet.
 *
 * Params:
 * a = first ray
 * b = second ray
 *
 * Returns:
 * The point of intersection,
 */
auto intersect(ray2f a, seg2f b) {
    float u, v;
    immutable rb = ray2f(b.a, b.b - b.a);
    rayIntersectProgress(a, rb, u, v);
    return (u > 0 && v > 0 && v < 1) ? intersection(a.progress(u)) : noIntersection;
}

unittest {
    // Validate that the ray (as, ad) intersects the segment (ba, bb) at p
    bool yes(float[2] as, float[2] ad, float[2] ba, float[2] bb, float[2] p) {
        import std.math : approxEqual;

        immutable a = ray2f(vec2f(as), vec2f(ad)),
                  b = seg2f(vec2f(ba), vec2f(bb)),
                  res = intersect(a, b);

        return res && res.x.approxEqual(p[0]) && res.y.approxEqual(p[1]);
    }

    // Validate that the ray (as, ad) doesn't intersect the segment (ba, bb)
    bool no(float[2] as, float[2] ad, float[2] ba, float[2] bb) {
        immutable a = ray2f(vec2f(as), vec2f(ad)),
                  b = seg2f(vec2f(ba), vec2f(bb));
        return !intersect(a, b);
    }

    //            as        ad        ba        bb        p
    assert(yes([ 0, 0 ], [ 1, 1 ], [ 4, 0 ], [ 0, 4 ], [ 2, 2 ]));
    assert(yes([ 0, 0 ], [-4, 4 ], [-2, 0 ], [ 0, 2 ], [-1, 1 ]));

    //            as        ad        ba        bb
    assert(no([ 0, 0 ], [ 1, 1 ], [ 2, 1 ], [ 4, 1 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 2, 2 ]));
}

/**
 * Determine if and where two rays intersect.
 *
 * If the rays are identical, returns the first point they meet.
 *
 * Params:
 * a = first ray
 * b = second ray
 *
 * Returns:
 * The point of intersection,
 */
auto intersect(seg2f a, seg2f b) {
    float u, v;
    immutable ra = ray2f(a.a, a.b - a.a);
    immutable rb = ray2f(b.a, b.b - b.a);
    rayIntersectProgress(ra, rb, u, v);
    return (u > 0 && u < 1 && v > 0 && v < 1) ?
        intersection(a.a + (a.b - a.a) * u) : noIntersection;
}

unittest {
    // Validate that the ray (a1, a2) intersects the segment (b1, b2) at p
    bool yes(float[2] a1, float[2] a2, float[2] b1, float[2] b2, float[2] p) {
        import std.math : approxEqual;

        immutable a = seg2f(vec2f(a1), vec2f(a2)),
                  b = seg2f(vec2f(b1), vec2f(b2)),
                  res = intersect(a, b);

        return res && res.x.approxEqual(p[0]) && res.y.approxEqual(p[1]);
    }

    // Validate that the ray (as, ad) doesn't intersect the segment (ba, bb)
    bool no(float[2] as, float[2] ad, float[2] ba, float[2] bb) {
        immutable a = ray2f(vec2f(as), vec2f(ad)),
                  b = seg2f(vec2f(ba), vec2f(bb));
        return !intersect(a, b);
    }

    //            a1        a2        b1        b2        p
    assert(yes([ 0, 0 ], [ 2, 2 ], [ 2, 0 ], [ 0, 2 ], [ 1, 1 ]));
    assert(yes([ 2, 0 ], [ 4, 0 ], [ 3, 4 ], [ 3,-2 ], [ 3, 0 ]));

    //            a1        a2        b1        b2
    assert(no([ 0, 0 ], [ 1, 1 ], [ 2, 1 ], [ 4, 1 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 2, 2 ]));
}

/**
 * Determine if and where a ray intersects a box.
 *
 * Given multiple intersections, returns the one closest to the ray's origin.
 */
auto intersect(ray2f ray, box2f box) {
    // true if a is closer than b to the ray's origin
    auto closer(vec2f a, vec2f b) {
        return a.squaredDistanceTo(ray.orig) < b.squaredDistanceTo(ray.orig);
    }

    auto hits = box.edges
        .map!(side => ray.intersect(side)) // intersect the ray with each edge
        .filter!(hit => hit)               // remove non-hits
        .minPos!((a,b) => closer(a,b));    // take the closest hit

    return hits.empty ? noIntersection : hits.front;
}

unittest {
    // Validate that the ray (as, ad) intersects the box [b1, b2]
    bool yes(float[2] as, float[2] ad, float[2] b1, float[2] b2, float[2] p) {
        import std.math : approxEqual;

        immutable ray = ray2f(vec2f(as), vec2f(ad)),
                  box = box2f(vec2f(b1), vec2f(b2)),
                  res = intersect(ray, box);

        return res && res.x.approxEqual(p[0]) && res.y.approxEqual(p[1]);
    }

    // Validate that the ray (as, ad) doesn't intersect the segment (ba, bb)
    bool no(float[2] as, float[2] ad, float[2] b1, float[2] b2) {
        immutable ray = ray2f(vec2f(as), vec2f(ad)),
                  box = box2f(vec2f(b1), vec2f(b2));
        return !intersect(ray, box);
    }

    //            as        ad        b1        b2        p
    assert(yes([ 0, 2 ], [ 1, 0 ], [ 1, 0 ], [ 4, 4 ], [ 1, 2 ]));
    assert(yes([-1, 1 ], [ 1, 0 ], [ 0, 0 ], [ 4, 2 ], [ 0, 1 ]));
    assert(yes([ 2, 4 ], [ 0,-8 ], [ 0, 0 ], [ 4, 2 ], [ 2, 2 ]));
    assert(yes([ 6, 1 ], [-2, 0 ], [ 0, 0 ], [ 4, 2 ], [ 4, 1 ]));
    assert(yes([ 2,-2 ], [ 0, 1 ], [ 0, 0 ], [ 4, 2 ], [ 2, 0 ]));
    //assert(yes([ 0, 0 ], [ 1, 1 ], [ 1, 1 ], [ 4, 4 ], [ 1, 1 ]));

    //            as        ad        b1        b2
    assert(no([ 0, 2 ], [ 0, 1 ], [ 1, 0 ], [ 4, 4 ]));
    assert(no([-1, 1 ], [-1, 0 ], [ 0, 0 ], [ 4, 2 ]));
    assert(no([ 2, 4 ], [ 0, 8 ], [ 0, 0 ], [ 4, 2 ]));
    assert(no([ 6, 1 ], [ 2, 0 ], [ 0, 0 ], [ 4, 2 ]));
    assert(no([ 2,-2 ], [ 0,-1 ], [ 0, 0 ], [ 4, 2 ]));
}

private:
struct IntersectResult {
    vec2f _point;
    alias _point this; // behave like a vector

    bool opCast(T : bool)() const {
        import std.math : isNaN;
        return !_point.x.isNaN && !_point.y.isNaN;
    }
}

auto intersection(vec2f point) { return IntersectResult(point); }
auto noIntersection() { return IntersectResult(); }

/*
 * Helper reused for ray/segment intersection functions.
 * u,v are the progress along a,b at which the intersection occurs
 */
void rayIntersectProgress(ray2f a, ray2f b, out float u, out float v) {
    // algorithm from stack overflow answer:
    // http://stackoverflow.com/a/2932601/1435461
    immutable as = a.orig,
              bs = b.orig,
              ad = a.dir,
              bd = b.dir,
              dx = bs.x - as.x,
              dy = bs.y - as.y,
              det = bd.x * ad.y - bd.y * ad.x;

    u = (dy * bd.x - dx * bd.y) / det;
    v = (dy * ad.x - dx * ad.y) / det;
}
