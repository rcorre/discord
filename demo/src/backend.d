module backend;

import allegro5.allegro;
import allegro5.allegro_primitives;

import discord;

private enum rayLength = 2000; // how far to extend a ray's 'beam'

void draw(T)(Vector!(T,2) v, ALLEGRO_COLOR color, float radius = 2) {
	al_draw_filled_circle(v.x, v.y, radius, color); // draw a point
}

void draw(T)(Ray!(T,2) r, ALLEGRO_COLOR color, float thickness = 1) {
    immutable start = r.orig;
    immutable end = start + r.dir.normalized * rayLength;

    // dot the start point
	draw(start, color);

    // draw a segment extending from the start
	al_draw_line(start.x, start.y, end.x, end.y, color, thickness);
}

void draw(T)(Segment!(T,2) s, ALLEGRO_COLOR color, float thickness = 1) {
    // dot the endpoints
	draw(s.a, color);
	draw(s.b, color);

    // draw the segment
	al_draw_line(s.a.x, s.a.y, s.b.x, s.b.y, color, thickness);
}

void draw(T)(Box!(T, 2) b, ALLEGRO_COLOR color, float thickness = 1) {
	al_draw_rectangle(b.min.x, b.min.y, b.max.x, b.max.y, color, thickness);
}

void draw(T)(Sphere!(T,2) c, ALLEGRO_COLOR color, float thickness = 1) {
	al_draw_circle(c.center.x, c.center.y, c.radius, color, thickness);
}

void draw(T)(Triangle!(T,2) t, ALLEGRO_COLOR color, float thickness = 1) {
	al_draw_triangle(t.a.x, t.a.y, t.b.x, t.b.y, t.c.x, t.c.y, color, thickness);
}
