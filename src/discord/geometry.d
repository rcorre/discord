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

/// Return the segment composing an edge of a box
auto top(T)(Box!(T, 2) b) { return seg2f(b.topLeft, b.topRight); }
/// ditto
auto left(T)(Box!(T, 2) b) { return seg2f(b.bottomLeft, b.topLeft); }
/// ditto
auto right(T)(Box!(T, 2) b) { return seg2f(b.topRight, b.bottomRight); }
/// ditto
auto bottom(T)(Box!(T, 2) b) { return seg2f(b.bottomRight, b.bottomLeft); }

///
unittest {
    auto box = box2f(0, 2, 4, 8);

    assert(box.top    == seg2f(vec2f(0, 2), vec2f(4, 2)));
    assert(box.left   == seg2f(vec2f(0, 8), vec2f(0, 2)));
    assert(box.right  == seg2f(vec2f(4, 2), vec2f(4, 8)));
    assert(box.bottom == seg2f(vec2f(4, 8), vec2f(0, 8)));
}

/// Return the given vertex (corner) of a box
auto topLeft(T)(Box!(T, 2) box) { return box.min; }
/// Return the given vertex (corner) of a box
auto topRight(T)(Box!(T, 2) box) { return vec2f(box.max.x, box.min.y); }
/// Return the given vertex (corner) of a box
auto bottomLeft(T)(Box!(T, 2) box) { return vec2f(box.min.x, box.max.y); }
/// Return the given vertex (corner) of a box
auto bottomRight(T)(Box!(T, 2) box) { return box.max; }

///
unittest {
    auto b = box2f(0, 0, 10, 20);
    assert(b.topLeft     == vec2f(0,0));
    assert(b.topRight    == vec2f(10,0));
    assert(b.bottomLeft  == vec2f(0,20));
    assert(b.bottomRight == vec2f(10,20));
}

/// Return a range of the vertices of a shape.
auto vertices(T)(Box!(T, 2) b) {
    return only(b.topLeft, b.topRight, b.bottomRight, b.bottomLeft);
}

/// ditto
auto vertices(T)(Triangle!(T, 2) t) {
    return only(t.a, t.b, t.c);
}

///
unittest {
    import std.algorithm : equal;

    auto box = box2f(0, 0, 10, 20);
    assert(box.vertices.equal([vec2f( 0, 0),    // top left
                               vec2f(10, 0),    // top right
                               vec2f(10,20),    // bottom right
                               vec2f( 0,20)])); // bottom left

    // compose a triangle from half of the box
    auto tri = triangle2f(box.topLeft, box.topRight, box.bottomLeft);
    assert(tri.vertices.equal([vec2f(0 ,0),    // top left
                               vec2f(10,0),    // top right
                               vec2f(0,20)])); // bottom left
}

/// Returns a range of the segments composing the sides of a shape.
auto edges(T)(T a) if (is(typeof(a.vertices))) {
    // we need a function to deduce the proper segment type from the vertex type
    // for example, given two vec2f, returns a seg2f
    auto segment(V)(Vector!(V, 2) v1, Vector!(V, 2) v2) {
        return Segment!(V, 2)(v1, v2);
    }

    // create edges from the chain [v0 -> v1, v1 -> v2, ... , vn -> v0]
    auto v = a.vertices;
    return v.zip(v.drop(1).chain(v.front.only))
        .map!(pair => segment(pair[0], pair[1]));
}

///
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

/**
 * Returns a range containing the segment itself.
 */
auto edges(T)(Segment!(T, 2) seg) { return only(seg); }

unittest {
    auto seg = seg2f(vec2f(10, 10), vec2f(20, 20));
    assert(seg.edges.front == seg);
    assert(seg.edges.length == 1);
}
