import std.stdio;
import std.range;

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

int main() {
    ALLEGRO_DISPLAY     *display     = null;
    ALLEGRO_EVENT_QUEUE *event_queue = null;
    ALLEGRO_TIMER       *timer       = null;

    Shape!float[] shapes;
    Shape!float selectedShape;
    Shape!float function(vec2f mousePos) startShape = &startRect;

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
                selectedShape = startShape(vec2f(ev.mouse.x, ev.mouse.y));
                break;
            case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
                // confirm placement of the current shape
                shapes ~= selectedShape;
                selectedShape = Shape!float();
                break;
            case ALLEGRO_EVENT_MOUSE_AXES:
                if (selectedShape.hasValue) {
                    // drag out the size of the shape
                    immutable m = vec2f(ev.mouse.x, ev.mouse.y);
                    selectedShape = selectedShape.tryVisit!(
                        (box2f b) => shape(box2f(b.min, m)),
                        (sphere2f s) => shape(sphere2f(s.center, s.center.distanceTo(m))));
                }
                break;
            case ALLEGRO_EVENT_KEY_DOWN:
                switch (ev.keyboard.keycode) {
                    case ALLEGRO_KEY_R:
                        startShape = &startRect;
                        break;
                    case ALLEGRO_KEY_C:
                        startShape = &startCircle;
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

            if (selectedShape.hasValue) draw(selectedShape, al_map_rgb(0,128,0));

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

auto startRect(vec2f pos) { return shape(box2f(pos, pos)); }
auto startCircle(vec2f pos) { return shape(sphere2f(pos, 0)); }
