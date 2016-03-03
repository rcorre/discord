module discord.sat;

import discord.shape;
import discord.geometry;

auto separate(A, B)(A a, B b) if (isShape!A && isShape!B) {
    return a.tryVisitAny!(_a => b.tryVisitAny!(_b => separate(_a, _b)));
}

auto separate(A, B)(A a, B b) if (is(A : Sphere!T, T) && hasVertices!B) {
    return vec2f(0, 0);
}

auto separate(A, B)(A a, B b) if (hasVertices!A && is(B : Sphere!T, T)) {
    return -separate(b, a);
}

auto separate(A, B)(A a, B b) if (hasVertices!A && hasVertices!B) {
    return vec2f(0, 0);
}

auto separate(T)(Sphere!(T, 2) a, Sphere!(T, 2) b) {
    // TODO: optimize
    immutable disp = a.center - b.center; // vector from B to A

    return (disp.length < a.radius + b.radius) ?
        disp.normalized * (a.radius + b.radius - disp.length) :
        Vector!(T, 2)(0, 0); // no intersection, no separation needed
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
