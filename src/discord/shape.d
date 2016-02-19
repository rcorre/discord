/// Provides a generic shape type.
module discord.shape;

import std.traits;
import std.variant;

import gfm.math.box;
import gfm.math.shapes;

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

auto visitAny(alias fn, V)(ref V var) {
    foreach(T ; var.AllowedTypes)
        if (auto ptr = var.peek!T)
            return fn(*ptr);

    assert(0, "Variant holds no value");
}
