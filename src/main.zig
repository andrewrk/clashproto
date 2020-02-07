const std = @import("std");
const c = @import("c.zig");
const assert = std.debug.assert;
const panic = std.debug.panic;

const idle_png_data = @embedFile("../assets/GraveRobber_idle.png");

const Player = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
};

pub fn main() anyerror!void {
    if (!(c.SDL_SetHintWithPriority(
        c.SDL_HINT_NO_SIGNAL_HANDLERS,
        "1",
        c.SDL_HintPriority.SDL_HINT_OVERRIDE,
    ) != c.SDL_bool.SDL_FALSE)) {
        panic("failed to disable sdl signal handlers\n", .{});
    }
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        panic("SDL_Init failed: {c}\n", .{c.SDL_GetError()});
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow(
        "Clash Game Prototype",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse {
        panic("SDL_CreateWindow failed: {c}\n", .{c.SDL_GetError()});
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer: *c.SDL_Renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        panic("SDL_CreateRenderer failed: {c}\n", .{c.SDL_GetError()});
    };
    defer c.SDL_DestroyRenderer(renderer);

    const rwops = c.SDL_RWFromConstMem(idle_png_data, idle_png_data.len).?;
    const idle_surface = c.IMG_Load_RW(rwops, 0) orelse panic("unable to load image", .{});
    const idle_texture = c.SDL_CreateTextureFromSurface(renderer, idle_surface) orelse panic("unable to convert surface to texture", .{});

    var player: Player = .{
        .x = 400,
        .y = 400,
        .w = 48,
        .h = 48,
    };

    while (true) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_QUIT => return,
                else => {},
            }
        }

        sdlAssertZero(c.SDL_RenderClear(renderer));

        const src_rect = c.SDL_Rect{
            .x = 0,
            .y = 0,
            .w = player.w,
            .h = player.h,
        };
        const dst_rect = c.SDL_Rect{
            .x = player.x,
            .y = player.y,
            .w = player.w,
            .h = player.h,
        };
        sdlAssertZero(c.SDL_RenderCopy(renderer, idle_texture, &src_rect, &dst_rect));

        c.SDL_RenderPresent(renderer);
    }
}

fn sdlAssertZero(ret: c_int) void {
    if (ret == 0) return;
    panic("sdl function returned an error: {c}", .{c.SDL_GetError()});
}
