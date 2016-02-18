import std.stdio;
import discord;
import backend;
import allegro5.allegro;
import allegro5.allegro_color;
import allegro5.allegro_primitives;

int main() {
    ALLEGRO_DISPLAY     *display     = null;
    ALLEGRO_EVENT_QUEUE *event_queue = null;
    ALLEGRO_TIMER       *timer       = null;

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

    display = al_create_display(640, 480);
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

    al_register_event_source(event_queue, al_get_display_event_source(display));
    al_register_event_source(event_queue, al_get_timer_event_source(timer));

    al_start_timer(timer);

    bool redraw = true;
    while(1) {
        ALLEGRO_EVENT ev;
        al_wait_for_event(event_queue, &ev);

        if(ev.type == ALLEGRO_EVENT_TIMER) {
            redraw = true;
        }
        else if(ev.type == ALLEGRO_EVENT_DISPLAY_CLOSE) {
            break;
        }

        if(redraw && al_is_event_queue_empty(event_queue)) {
            redraw = false;
            al_clear_to_color(al_map_rgb(0,0,0));

            al_flip_display();
        }
    }

    al_destroy_timer(timer);
    al_destroy_display(display);
    al_destroy_event_queue(event_queue);

    return 0;
}
