module discord.geometry;

import std.range;
import std.algorithm;

import gfm.math;

/**
 * Returns the vector normal to the given segment as a unit vector.
 *
 * In a cartesian space where the +y axis goes 'up', `seg.normal` corresponds to the normal
 * _clockwise_ from the direction of the segment (counterclockwise if the +y axis goes 'down').
 * The other normal is given as `-seg.normal`.
 */
auto normal(seg2f seg) {
    immutable dir = seg.b - seg.a;
    return vec2f(dir.y, -dir.x).normalized;
}

unittest {
    bool test(seg2f seg, vec2f expected) {
        import std.math : approxEqual;
        immutable norm = seg.normal;
        return norm.x.approxEqual(expected.normalized.x) &&
               norm.y.approxEqual(expected.normalized.y);
    }

    assert(test(seg2f(vec2f( 0, 0), vec2f( 6, 0)), vec2f( 0,-1)));
    assert(test(seg2f(vec2f( 0, 0), vec2f(-8, 0)), vec2f( 0, 1)));
    assert(test(seg2f(vec2f( 0, 0), vec2f( 0, 3)), vec2f( 1, 0)));
    assert(test(seg2f(vec2f( 0, 0), vec2f( 0,-1)), vec2f(-1, 0)));
    assert(test(seg2f(vec2f(-2,-2), vec2f( 2, 2)), vec2f( 1,-1)));
    assert(test(seg2f(vec2f( 2, 2), vec2f(-2,-2)), vec2f(-1, 1)));
}

auto topLeft(box2f box) { return box.min; }
auto topRight(box2f box) { return vec2f(box.max.x, box.min.y); }
auto bottomLeft(box2f box) { return vec2f(box.min.x, box.max.y); }
auto bottomRight(box2f box) { return box.max; }

/**
 * Returns a range of the segments composing the sides of a box.
 */
auto edges(box2f box) {
    return only(seg2f(box.topLeft, box.topRight),       // top
                seg2f(box.topRight, box.bottomRight),   // right
                seg2f(box.bottomRight, box.bottomLeft), // bottom
                seg2f(box.bottomLeft, box.topLeft));    // left
}

unittest {
    import std.algorithm : map, equal;

    auto actual = box2f(0, 2, 4, 8).edges;
    auto expected = [
        seg2f(vec2f(0, 2), vec2f(4, 2)), // top
        seg2f(vec2f(4, 2), vec2f(4, 8)), // right
        seg2f(vec2f(4, 8), vec2f(0, 8)), // bottom
        seg2f(vec2f(0, 8), vec2f(0, 2)), // left
    ];

    assert(actual.equal(expected));

    auto actualNormals = expected.map!(x => x.normal);
    auto expectedNormals = [
        vec2f(0, -1), vec2f(1, 0), vec2f(0, 1), vec2f(-1, 0)
    ];

    assert(actualNormals.equal(expectedNormals));
}
