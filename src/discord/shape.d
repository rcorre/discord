/// Provides a generic shape type.
module discord.shape;

import std.traits;
import std.variant;

public import gfm.math.box;
public import gfm.math.shapes;
public import gfm.math.vector;

public import std.variant : visit, tryVisit;

/// A generic struct that can hold any one of a number of 2D shapes.
alias Shape(T) = Algebraic!(Segment!(T, 2),
                            Triangle!(T,2),
                            Box!(T,2),
                            Sphere!(T,2));

/// Convenience shape constructor with type inference.
auto shape(T)(T someShape) if (isShapeKind!T) {
    alias V = TemplateArgsOf!T[0]; // [0] is float/double/etc, [1] is N
    return Shape!V(someShape);
}

///
unittest {
    import gfm.math.vector;

    Shape!float s;
    s = shape(seg2f(vec2f(10, 10), vec2f(20, 20)));
    s = shape(box2f(10, 10, 20, 20));
    s = shape(sphere2f(vec2f(10, 10), 20));
}

/**
 * Apply the same (overloaded) function to whatever kind shape is contained.
 *
 * Like `std.variant.visit`, but using the same function for every type.
 */
auto visitAny(alias fn, S)(ref S shape) if (isShape!S) {
    foreach(T ; shape.AllowedTypes)
        if (auto ptr = shape.peek!T)
            return fn(*ptr);

    assert(0, "Variant holds no value");
}

///
unittest {
    auto thing(T)(T obj) {
        static if (is(T == ray2f)) return 0;
        static if (is(T == seg2f)) return 1;
        static if (is(T == box2f)) return 2;
        static if (is(T == triangle2f)) return 3;
        static if (is(T == sphere2f)) return 4;
    }
}

/**
 * Apply the same (overloaded) function to whatever kind of shape is contained.
 *
 * Like `std.variant.tryVisit`, but using the same function for every type.
 */
auto tryVisitAny(alias fn, S)(ref S shape) if (isShape!S) {
    foreach(T ; shape.AllowedTypes)
        if (auto ptr = shape.peek!T) {
            static if (is(typeof(fn(*ptr))))
                return fn(*ptr);
            else
                assert(0, "No overload provided for " ~ T.stringof);
        }

    assert(0, "Variant holds no value");
}

/// Return `true` iff `T` is an instantiation of the `Shape` template.
template isShape(T) {
    // if T presents its AllowedTypes, check if each is shape-like
    // if not, it isn't a variant and definitely isn't a shape
    static if (is(T.AllowedTypes Types)) {
        import std.meta : allSatisfy;
        enum isShape = allSatisfy!(isShapeKind, Types);
    }
    else
        enum isShape = false;
}

///
unittest {
    static assert( isShape!(Shape!float));
    static assert(!isShape!(int));
    static assert(!isShape!(Algebraic!(int, float)));
}

/// `true` iff `T` is a kind of `Shape` (can construct a `Shape` from a `T`).
enum isShapeKind(T) = is(T : Segment !(U, 2), U) ||
                      is(T : Triangle!(U, 2), U) ||
                      is(T : Box     !(U, 2), U) ||
                      is(T : Sphere  !(U, 2), U);

///
unittest {
    static assert( isShapeKind!box2f);
    static assert( isShapeKind!seg2d);
    static assert( isShapeKind!sphere2d);
    static assert( isShapeKind!(Triangle!(real, 2)));
    static assert(!isShapeKind!(Ray!(uint, 2)));
    static assert(!isShapeKind!float);
    static assert(!isShapeKind!(Shape!float));
}
