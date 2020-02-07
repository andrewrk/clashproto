const std = @import("std");
const c = @import("c.zig");

pub fn main() anyerror!void {
    if (!(c.SDL_SetHintWithPriority(
        c.SDL_HINT_NO_SIGNAL_HANDLERS,
        "1",
        c.SDL_HintPriority.SDL_HINT_OVERRIDE,
    ) != c.SDL_bool.SDL_FALSE)) {
        std.debug.panic("failed to disable sdl signal handlers\n", .{});
    }
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        std.debug.panic("SDL_Init failed: {c}\n", .{c.SDL_GetError()});
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow(
        "Clash Game Prototype",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        512,
        512,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse {
        std.debug.panic("SDL_CreateWindow failed: {c}\n", .{c.SDL_GetError()});
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer: *c.SDL_Renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        std.debug.panic("SDL_CreateRenderer failed: {c}\n", .{c.SDL_GetError()});
    };
    defer c.SDL_DestroyRenderer(renderer);

    while (true) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_QUIT => return,
                else => {},
            }
        }
    }
}
