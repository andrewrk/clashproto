const std = @import("std");
const c = @import("c.zig");
const assert = std.debug.assert;
const panic = std.debug.panic;

const Animation = struct {
    png_data: []const u8,
    texture: *c.SDL_Texture,
    frame_count: i32,
    // in frames
    frame_delay: i32,
    hit_box: c.SDL_Rect,
    frame_width: i32,
    frame_height: i32,

    fn initialize(self: *Animation, renderer: *c.SDL_Renderer) void {
        const rwops = c.SDL_RWFromConstMem(
            self.png_data.ptr,
            @intCast(c_int, self.png_data.len),
        ).?;
        const surface = c.IMG_Load_RW(rwops, 0) orelse panic("unable to load image", .{});
        self.texture = c.SDL_CreateTextureFromSurface(renderer, surface) orelse
            panic("unable to convert surface to texture", .{});
    }

    fn sourceRect(self: Animation, frame_index: i32) c.SDL_Rect {
        return .{
            .x = self.frame_width * frame_index,
            .y = 0,
            .w = self.frame_width,
            .h = self.frame_height,
        };
    }
};

var idle_animation = Animation{
    .png_data = @embedFile("../assets/GraveRobber_idle.png"),
    .texture = undefined,
    .frame_count = 4,
    .frame_delay = 10,
    .hit_box = .{
        .x = 9,
        .y = 17,
        .w = 16,
        .h = 31,
    },
    .frame_width = 48,
    .frame_height = 48,
};

var walk_animation = Animation{
    .png_data = @embedFile("../assets/GraveRobber_walk.png"),
    .texture = undefined,
    .frame_count = 6,
    .frame_delay = 10,
    .hit_box = .{
        .x = 9,
        .y = 17,
        .w = 16,
        .h = 31,
    },
    .frame_width = 48,
    .frame_height = 48,
};

var jump_animation = Animation{
    .png_data = @embedFile("../assets/GraveRobber_jump.png"),
    .texture = undefined,
    .frame_count = 6,
    .frame_delay = 4,
    .hit_box = .{
        .x = 9,
        .y = 17,
        .w = 16,
        .h = 31,
    },
    .frame_width = 48,
    .frame_height = 48,
};

var block_animation = Animation{
    .png_data = @embedFile("../assets/block.png"),
    .texture = undefined,
    .frame_count = 1,
    .frame_delay = 1,
    .hit_box = .{
        .x = 0,
        .y = 0,
        .w = 171,
        .h = 128,
    },
    .frame_width = 171,
    .frame_height = 128,
};

const all_animations = [_]*Animation{
    &idle_animation,
    &walk_animation,
    &jump_animation,
    &block_animation,
};

const Player = struct {
    /// Left of the player hit box
    x: i32,

    /// Top of the player hit box
    y: i32,

    vel_x: i32,
    vel_y: i32,
    max_spd_x: i32,
    max_spd_y: i32,
    ani: *const Animation,
    ani_frame_index: i32,
    ani_frame_delay: i32,
    jump_frame: i32,
    friction: i32,
    direction: i32,
    grounded: bool,

    fn startAnimation(player: *Player, animation: *const Animation) void {
        player.ani = animation;
        player.ani_frame_index = 0;
        player.ani_frame_delay = 0;
    }

    fn isJumping(player: *Player) bool {
        return player.jump_frame >= 0 and player.jump_frame <= jump_up_index;
    }

    fn land(player: *Player) void {
        if (player.ani == &jump_animation and player.jump_frame >= jump_down_index) {
            player.startAnimation(&idle_animation);
        }
        player.grounded = true;
    }
};

const Block = struct {
    ani: *const Animation,
    pos: c.SDL_Point,
};

const Game = struct {
    player: Player,
    all_blocks: []Block,

    fn init() Game {
        return .{
            .player = .{
                .x = 400,
                .y = 200,
                .vel_x = 0,
                .vel_y = 0,
                .max_spd_x = 3,
                .max_spd_y = 3,
                .friction = 1,
                .ani = &idle_animation,
                .ani_frame_index = 0,
                .ani_frame_delay = 0,
                .jump_frame = 666,
                .direction = 1,
                .grounded = false,
            },
            .all_blocks = &[_]Block{
                .{
                    .pos = .{
                        .x = 300,
                        .y = 400,
                    },
                    .ani = &block_animation,
                },
                .{
                    .pos = .{
                        .x = 100,
                        .y = 300,
                    },
                    .ani = &block_animation,
                },
                .{
                    .pos = .{
                        .x = 400,
                        .y = 300,
                    },
                    .ani = &block_animation,
                },
            },
        };
    }

    fn collidingWithAnyBlocks(
        game: *Game,
        x: i32,
        y: i32,
        w: i32,
        h: i32,
    ) ?*const Block {
        for (game.all_blocks) |*block| {
            const is_collision = !(x >= block.pos.x + block.ani.hit_box.w or
                y >= block.pos.y + block.ani.hit_box.h or
                x + w <= block.pos.x or
                y + h <= block.pos.y);
            if (is_collision) return block;
        }
        return null;
    }
};

const jump_up_index = 3;
const jump_down_index = 4;

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

    for (all_animations) |anim| {
        anim.initialize(renderer);
    }

    var game = Game.init();
    while (true) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_QUIT => return,
                c.SDL_KEYUP => switch (event.key.keysym.scancode) {
                    .SDL_SCANCODE_BACKSPACE => game = Game.init(),
                    else => {},
                },
                else => {},
            }
        }

        const kb_state = c.SDL_GetKeyboardState(null);
        const want_left = kb_state[c.SDL_SCANCODE_LEFT] != 0;
        const want_right = kb_state[c.SDL_SCANCODE_RIGHT] != 0;
        const want_up = kb_state[c.SDL_SCANCODE_UP] != 0;
        const moving = want_left or want_right;
        if (want_left) {
            game.player.direction = -1;
            if (game.player.vel_x > -game.player.max_spd_x) game.player.vel_x -= 2;
        }
        if (want_right) {
            game.player.direction = 1;
            if (game.player.vel_x < game.player.max_spd_x) game.player.vel_x += 2;
        }
        if (!game.player.isJumping()) {
            if (moving and game.player.ani == &idle_animation) {
                game.player.startAnimation(&walk_animation);
            } else if (!moving and game.player.ani != &idle_animation) {
                game.player.startAnimation(&idle_animation);
            }
        }

        if (want_up and game.player.grounded and !game.player.isJumping()) {
            game.player.jump_frame = 0;
            game.player.startAnimation(&jump_animation);
        }

        if (game.player.isJumping()) {
            game.player.ani_frame_delay += 1;
            if (game.player.ani_frame_delay >= game.player.ani.frame_delay) {
                game.player.ani_frame_delay = 0;

                game.player.jump_frame += 1;
                if (game.player.jump_frame < jump_up_index - 1) {
                    game.player.ani_frame_index = game.player.jump_frame;
                } else {
                    const jump_velocity = 10;
                    game.player.vel_y = -jump_velocity;
                    game.player.ani_frame_index = game.player.jump_frame;
                    game.player.grounded = false;
                }
            }
        } else if (!game.player.grounded and game.player.vel_y < 0) {
            game.player.startAnimation(&jump_animation);
            game.player.ani_frame_index = jump_up_index;
        } else if (!game.player.grounded and game.player.vel_y > 0) {
            game.player.startAnimation(&jump_animation);
            game.player.ani_frame_index = jump_down_index;
        } else {
            game.player.ani_frame_delay += 1;
            if (game.player.ani_frame_delay >= game.player.ani.frame_delay) {
                game.player.ani_frame_index = @rem(
                    (game.player.ani_frame_index + 1),
                    game.player.ani.frame_count,
                );
                game.player.ani_frame_delay = 0;
            }
        }

        const new_x = game.player.x + game.player.vel_x;
        const new_y = game.player.y + game.player.vel_y;

        if (game.collidingWithAnyBlocks(
            new_x,
            new_y,
            game.player.ani.hit_box.w,
            game.player.ani.hit_box.h,
        )) |hit_block| {
            // Test the axes separately.
            const is_x_collision = game.collidingWithAnyBlocks(
                new_x,
                game.player.y,
                game.player.ani.hit_box.w,
                game.player.ani.hit_box.h,
            ) != null;
            const is_y_collision = game.collidingWithAnyBlocks(
                game.player.x,
                new_y,
                game.player.ani.hit_box.w,
                game.player.ani.hit_box.h,
            ) != null;
            if (!is_x_collision) {
                game.player.x = new_x;
                // Move them to be flush with the object.
                if (game.player.vel_y > 0) {
                    game.player.y = hit_block.pos.y - game.player.ani.hit_box.h;
                    game.player.land();
                } else {
                    game.player.y = hit_block.pos.y + hit_block.ani.hit_box.h;
                }
                game.player.vel_y = 0;
            } else if (!is_y_collision) {
                game.player.y = new_y;
                // TODO above logic here
                game.player.vel_x = 0;
            } else {
                if (game.player.vel_y > 0) {
                    game.player.land();
                }
                game.player.vel_x = 0;
                game.player.vel_y = 0;
            }
        } else {
            game.player.grounded = false;
            game.player.x = new_x;
            game.player.y = new_y;
        }

        // gravity
        game.player.vel_y += 1;

        if (game.player.vel_x > 0) {
            game.player.vel_x -= game.player.friction;
            if (game.player.vel_x < 0) game.player.vel_x = 0;
        }
        if (game.player.vel_x < 0) {
            game.player.vel_x += game.player.friction;
            if (game.player.vel_x > 0) game.player.vel_x = 0;
        }

        sdlAssertZero(c.SDL_RenderClear(renderer));

        {
            for (game.all_blocks) |block| {
                const src_rect = block.ani.sourceRect(0);
                const dst_rect = c.SDL_Rect{
                    .x = block.pos.x,
                    .y = block.pos.y,
                    .w = block.ani.frame_width,
                    .h = block.ani.frame_height,
                };
                sdlAssertZero(c.SDL_RenderCopy(
                    renderer,
                    block.ani.texture,
                    &src_rect,
                    &dst_rect,
                ));
            }
        }

        const src_rect = game.player.ani.sourceRect(game.player.ani_frame_index);
        const forward = game.player.direction >= 0;
        const x_offset = if (forward)
            -game.player.ani.hit_box.x
        else
            -game.player.ani.frame_width + game.player.ani.hit_box.x + game.player.ani.hit_box.w;
        const dst_rect = c.SDL_Rect{
            .x = game.player.x + x_offset,
            .y = game.player.y - game.player.ani.hit_box.y,
            .w = game.player.ani.frame_width,
            .h = game.player.ani.frame_height,
        };
        sdlAssertZero(c.SDL_RenderCopyEx(
            renderer,
            game.player.ani.texture,
            &src_rect,
            &dst_rect,
            0,
            null,
            if (forward) .SDL_FLIP_NONE else .SDL_FLIP_HORIZONTAL,
        ));

        c.SDL_RenderPresent(renderer);
        // delay until the next multiple of 17 milliseconds
        const delay_millis = 17 - (c.SDL_GetTicks() % 17);
        c.SDL_Delay(delay_millis);
    }
}

fn sdlAssertZero(ret: c_int) void {
    if (ret == 0) return;
    panic("sdl function returned an error: {c}", .{c.SDL_GetError()});
}
