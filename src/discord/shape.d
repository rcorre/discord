/// Provides a generic shape type.
module discord.shape;

import std.traits;
import std.variant;

import gfm.math.box;
import gfm.math.shapes;

public import std.variant : visit, tryVisit;

/// A generic struct that can hold any one of a number of 2D shapes.
alias Shape(T) = Algebraic!(Segment!(T, 2),
                            Triangle!(T,2),
                            Box!(T,2),
                            Sphere!(T,2));

/// Convenience shape constructor with type inference.
auto shape(T)(T someShape) {
    alias V = TemplateArgsOf!T[0]; // [0] is float/double/etc, [1] is N
    return Shape!V(someShape);
}

/**
 * Apply the same function (or overload set) to whatever shape this contains.
 */
auto visitAny(alias fn, S)(ref S shape) if (isShape!S) {
    foreach(T ; shape.AllowedTypes)
        if (auto ptr = shape.peek!T)
            return fn(*ptr);

    assert(0, "Variant holds no value");
}

template isShape(V : VariantN!T, T...) {
    static if (__traits(compiles, TemplateArgsOf!(T[1])[0])) {
        alias NumericType = TemplateArgsOf!(T[1])[0]; // e.g. float, int, etc
        enum isShape = is(V == Shape!NumericType);
    }
    else {
        enum isShape = false;
    }
}

template isShape(T) {
    enum isShape = false;
}

unittest {
    static assert(isShape!(Shape!float));
    static assert(!isShape!(int));
    static assert(!isShape!(Algebraic!(int, float)));
}
