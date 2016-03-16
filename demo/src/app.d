import std.stdio;
import std.range;
import std.algorithm;

import allegro5.allegro;
import allegro5.allegro_color;
import allegro5.allegro_primitives;

import discord;
import backend;

enum {
    screenW = 800,
    screenH = 600,
    gridSpace = 20,
}

enum Mode {
    none,
    placeRect,
    placeCircle,
    placeSegment,
    placeTriangle,
}


int main() {
    ALLEGRO_DISPLAY     *display     = null;
    ALLEGRO_EVENT_QUEUE *event_queue = null;
    ALLEGRO_TIMER       *timer       = null;

    Shape!float[] shapes;
    Mode mode;
    vec2f[] verts;

    if(!al_init()) {
        stderr.writeln("failed to initialize allegro!\n");
        return -1;
    }

    al_init_primitives_addon();

    timer = al_create_timer(1.0 / 60);
    if(!timer) {
        stderr.writeln("failed to create timer!\n");
        return -1;
    }

    display = al_create_display(screenW, screenH);
    if(!display) {
        stderr.writeln("failed to create display!\n");
        al_destroy_timer(timer);
        return -1;
    }

    event_queue = al_create_event_queue();
    if(!event_queue) {
        stderr.writeln("failed to create event_queue!\n");
        al_destroy_display(display);
        al_destroy_timer(timer);
        return -1;
    }

    al_install_mouse();
    al_install_keyboard();

    al_register_event_source(event_queue, al_get_display_event_source(display));
    al_register_event_source(event_queue, al_get_timer_event_source(timer));
    al_register_event_source(event_queue, al_get_mouse_event_source());
    al_register_event_source(event_queue, al_get_keyboard_event_source());

    al_start_timer(timer);

    bool redraw = true;
    bool done = false;
    vec2f mousePos;
    while(!done) {
        ALLEGRO_EVENT ev;
        al_wait_for_event(event_queue, &ev);

        switch (ev.type) {
            case ALLEGRO_EVENT_TIMER:
                redraw = true;
                break;
            case ALLEGRO_EVENT_DISPLAY_CLOSE:
                done = true;
                break;
            case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
                // start placing a shape that (so far) has no size
                if (mode != Mode.none) verts ~= vec2f(ev.mouse.x, ev.mouse.y);
                if (shapeComplete(verts, mode)) {
                    shapes ~= createShape(verts, mode);
                    verts = [];
                }
                break;
            case ALLEGRO_EVENT_MOUSE_AXES:
                mousePos = vec2f(ev.mouse.x, ev.mouse.y);
                break;
            case ALLEGRO_EVENT_KEY_DOWN:
                switch (ev.keyboard.keycode) {
                    case ALLEGRO_KEY_R:
                        mode = Mode.placeRect;
                        break;
                    case ALLEGRO_KEY_C:
                        mode = Mode.placeCircle;
                        break;
                    case ALLEGRO_KEY_S:
                        mode = Mode.placeSegment;
                        break;
                    case ALLEGRO_KEY_ESCAPE:
                        mode = Mode.none;
                        break;
                    default: // ignore other keys
                }
                break;
            default: // ignore other events
        }

        if(redraw && al_is_event_queue_empty(event_queue)) {
            redraw = false;
            al_clear_to_color(al_map_rgb(0,0,0));

            drawGrid();

            foreach(shape ; shapes) draw(shape, al_map_rgb(0, 255, 0));

            // draw separating projection vectors for collisions
            foreach(i ; 0..shapes.length)
                foreach(j ; 0..shapes.length) {
                    if (i == j) continue; // don't check shape against itself
                    immutable a = shapes[i],
                              b = shapes[j],
                              proj = a.separate(b),
                              center = a.tryVisitAny!(x => x.center),
                              seg = seg2f(center, center + proj);

                    if (proj.squaredLength > 0)
                        draw(seg, al_map_rgb(255,0,0));
                }

            // draw shape currently being created, using the current mouse 
            // position as the next vertex so the shape resizes in real time
            if (verts.length > 0)
                drawPartialShape(verts, mousePos, mode);

            al_flip_display();
        }
    }

    al_destroy_timer(timer);
    al_destroy_display(display);
    al_destroy_event_queue(event_queue);

    return 0;
}

void drawGrid() {
    immutable color = al_map_rgb(100, 100, 100);

    foreach(x ; 0.iota(screenW, gridSpace))
        draw(seg2f(vec2f(x, -10), vec2f(x, screenH + 10)), color);

    foreach(y ; 0.iota(screenH, gridSpace))
        draw(seg2f(vec2f(-10, y), vec2f(screenW + 10, y)), color);
}

void drawPartialShape(vec2f[] verts, vec2f mousePos, Mode mode) {
    immutable color = al_map_rgb(0,0,255);

    final switch (mode) with (Mode) {
        case none:
            break;
        case placeRect:
            box2f(verts[0], mousePos).draw(color);
            break;
        case placeCircle:
                auto box = box2f(verts[0], mousePos);
                sphere2f(box.center, box.width / 2).draw(color);
            break;
        case placeSegment:
            seg2f(verts[0], mousePos).draw(color);
            break;
        case placeTriangle:
            break;
    }
}

auto createShape(vec2f[] verts, Mode mode) {
    final switch (mode) with (Mode) {
        case none:
            assert(0);
        case placeRect:
            return box2f(verts[0], verts[1]).shape;
        case placeCircle:
            auto box = box2f(verts[0], verts[1]);
            return sphere2f(box.center, box.width / 2).shape;
        case placeSegment:
            return seg2f(verts[0], verts[1]).shape;
        case placeTriangle:
            return triangle2f(verts[0], verts[1], verts[2]).shape;
    }
}

bool shapeComplete(vec2f[] verts, Mode mode) {
    final switch (mode) with (Mode) {
        case none:          return false;
        case placeRect:     return verts.length == 2;
        case placeCircle:   return verts.length == 2;
        case placeSegment:  return verts.length == 2;
        case placeTriangle: return verts.length == 3;
    }
}
