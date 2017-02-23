/**
 * Use 'swept' collision detection to detect collisions between moving shapes.
 *
 * For more info, see TODO.
 */
module discord.sweep;

float sweep(T)(Sphere!(T, 2) a, Segment!(T, 2) b, vec2!T da) {
    immutable v = da - db; // relative velocity in normalized time

    if (a.intersects(b)) return 0;
}

unittest {
    import std.math : approxEqual;
    immutable a = box2f(0, 0, 4, 4),
              b = box2f(8, 8, 12, 12),
              da = vec2f(8, 0),
              db = vec2f(0, -8);

    assert(sweep(a, b, da, db).approxEqual(0.5f));
}
