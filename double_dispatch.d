import std.stdio;
import std.variant;

struct Box { float x, y, w, h; }
struct Circle { float x, y, r; }

alias Shape = Algebraic!(Box, Circle);

auto project(alias fn, V)(ref V var) {
    foreach(T ; var.AllowedTypes)
        if (auto ptr = var.peek!T)
            return fn(*ptr);

    assert(0, "Variant holds no value");
}

void intersect(Box a, Box b) { writeln(a, b); }
void intersect(Box a, Circle b) { writeln(a, b); }
void intersect(Circle a, Box b) { writeln(a, b); }
void intersect(Circle a, Circle b) { writeln(a, b); }

void intersect(Shape a, Shape b) {
    a.project!(_a => b.project!(_b => intersect(_a, _b)));
}

unittest {
    Shape b = Box(1, 2, 3, 4);
    Shape c = Circle(5, 6, 7);

    b.intersect(b);
    c.intersect(b);
    b.intersect(c);
    c.intersect(c);
}

unittest {
    Shape b = Box(1,2,3,4);
    assert(b.project!(x => x.x) == 1);

    b = Circle(4,5,6);
    assert(b.project!(x => x.x) == 4);
}
