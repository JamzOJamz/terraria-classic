const std = @import("std");
const builtin = @import("builtin");

const rl = @import("raylib");
const win32 = @import("win32");

const audio_engine = @import("new/audio_engine.zig");
const font_assets = @import("new/font_assets.zig");
const FPSDisplay = @import("new/FPSDisplay.zig");
const GameObject = @import("new/GameObject.zig");
const MenuLogoBehaviour = @import("new/MenuLogoBehaviour.zig");
const MouseTextPulse = @import("new/MouseTextPulse.zig");
const Scene = @import("new/Scene.zig");
const Sprite = @import("new/Sprite.zig");
const texture_assets = @import("new/texture_assets.zig");
const time = @import("new/time.zig");
const Transform = @import("new/Transform.zig");

// NOTE: This tells NVIDIA Optimus and AMD PowerXpress to prefer to use the dedicated GPU when running the game
// https://www.reddit.com/r/gamedev/comments/bk7xbe/psa_for_anyone_developing_a_gameengine_in_c/
comptime {
    if (builtin.target.os.tag == .windows) {
        const enablement = @as(*anyopaque, @ptrFromInt(1));
        @export(&enablement, .{ .name = "NvOptimusEnablement" });
        @export(
            &enablement,
            .{ .name = "AmdPowerXpressRequestHighPerformance" },
        );
    }
}

// Emscripten main loop function that accepts an argument
// https://emscripten.org/docs/api_reference/emscripten.h.html#c.emscripten_set_main_loop_arg
extern fn emscripten_set_main_loop_arg(
    func: *const fn (*anyopaque) callconv(.c) void,
    arg: *anyopaque,
    fps: c_int,
    simulate_infinite_loop: c_int,
) callconv(.c) void;

const Game = struct {
    const fixed_tick_rate = time.fixed_tick_rate;
    const max_frame_time: f64 = @floatCast(time.maximum_delta_time);
    const fixed_dt: f64 = 1.0 / fixed_tick_rate;
    pub var mouse_color = rl.Color{
        .r = 255,
        .g = 50,
        .b = 95,
        .a = 255,
    };
    allocator: std.mem.Allocator,
    accumulator: f64 = 0.0,
    per_second_accumulator: f64 = 0.0,
    current_time: f64 = 0.0,
    frame_counter: u32 = 0,
    active_scene: *Scene,
};

fn initScene(allocator: std.mem.Allocator) !Scene {
    var scene = Scene.init(allocator);

    // Logo game object
    var logo_go = try GameObject.create(allocator);
    try logo_go.addComponent(GameObject.Component{
        .transform = .{
            .position = .{ .x = 400, .y = 100 },
            .origin = .{ .x = 0.5, .y = 0.5 },
        },
    });
    try logo_go.addComponent(GameObject.Component{
        .sprite = .{
            .texture = texture_assets.logo[0],
        },
    });
    var menu_logo_behaviour = try allocator.create(MenuLogoBehaviour);
    menu_logo_behaviour.* = .{};
    try logo_go.addComponent(GameObject.Component{
        .behaviour = menu_logo_behaviour.behaviour(),
    });
    try scene.addObject(logo_go);

    // FPS text game object
    var fps_text_go = try GameObject.create(allocator);
    try fps_text_go.addComponent(GameObject.Component{
        .transform = .{
            .position = .{ .x = 4, .y = @floatFromInt(rl.getScreenHeight() - 24) },
        },
    });
    try fps_text_go.addComponent(GameObject.Component{
        .text = .{ .font = font_assets.andy },
    });
    var mouse_text_pulse = try allocator.create(MouseTextPulse);
    mouse_text_pulse.* = .{};
    try fps_text_go.addComponent(GameObject.Component{
        .behaviour = mouse_text_pulse.behaviour(),
    });
    var fps_display = try allocator.create(FPSDisplay);
    fps_display.* = .{};
    try fps_text_go.addComponent(GameObject.Component{
        .behaviour = fps_display.behaviour(),
    });
    try scene.addObject(fps_text_go);

    // Message text game object
    var message_text_go = try GameObject.create(allocator);
    try message_text_go.addComponent(GameObject.Component{
        .transform = .{
            .position = .{
                .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2,
                .y = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2 + 10,
            },
            .origin = .{ .x = 0.5, .y = 0.5 },
        },
    });
    try message_text_go.addComponent(GameObject.Component{
        .text = .{
            .font = font_assets.andy,
            .text = "Terraria Classic in Zig + raylib!\nPress Space to cycle logo textures.\nPress F10 to toggle FPS display.\nPress ESC to quit.",
            .tint = rl.Color.white,
        },
    });
    var mouse_text_pulse_2 = try allocator.create(MouseTextPulse);
    mouse_text_pulse_2.* = .{};
    try message_text_go.addComponent(GameObject.Component{
        .behaviour = mouse_text_pulse_2.behaviour(),
    });
    try scene.addObject(message_text_go);

    // Version number text game object
    var version_number_text_go = try GameObject.create(allocator);
    try version_number_text_go.addComponent(GameObject.Component{
        .transform = .{
            .position = .{
                .x = @floatFromInt(rl.getScreenWidth() - 4),
                .y = @floatFromInt(rl.getScreenHeight() - 24),
            },
            .origin = .{ .x = 1.0, .y = 0.0 },
        },
    });
    try version_number_text_go.addComponent(GameObject.Component{
        .text = .{
            .font = font_assets.andy,
            .text = "v0.0.1a",
            .tint = rl.Color.white,
        },
    });
    var mouse_text_pulse_3 = try allocator.create(MouseTextPulse);
    mouse_text_pulse_3.* = .{};
    try version_number_text_go.addComponent(GameObject.Component{
        .behaviour = mouse_text_pulse_3.behaviour(),
    });
    try scene.addObject(version_number_text_go);

    // Start playing music
    // TODO: Don't hardcode this
    const music = audio_engine.MusicId.new_title;
    audio_engine.playMusic(music);
    audio_engine.setMusicInstanceVolume(music, 0.14);

    return scene;
}

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const window_width = 800;
    const window_height = 600;
    const fps_target = 144;
    const use_vsync = true;

    rl.setConfigFlags(.{ .vsync_hint = use_vsync }); // Enable V-Sync on GPU
    rl.setRandomSeed(@intCast(std.time.milliTimestamp())); // Initialize random seed based on current time
    rl.initWindow(window_width, window_height, getRandomWindowTitle());
    defer rl.closeWindow();
    rl.initAudioDevice(); // Initialize audio device
    defer rl.closeAudioDevice();
    rl.hideCursor(); // We have a custom cursor
    //rl.setExitKey(rl.KeyboardKey.key_null); // By default, ESC will close the game window when pressed

    if (!use_vsync) rl.setTargetFPS(fps_target);
    //--------------------------------------------------------------------------------------

    // Get platform-specific allocator
    const is_web_build = builtin.os.tag == .emscripten;
    var gpa_state = if (!is_web_build) std.heap.GeneralPurposeAllocator(.{}){} else {};
    defer {
        if (!is_web_build) _ = gpa_state.deinit();
    }
    const allocator = if (!is_web_build) gpa_state.allocator() else std.heap.c_allocator;

    // Load game assets
    try loadContent(allocator);
    defer unloadContent();

    var main_scene = try initScene(allocator);
    defer main_scene.deinit();

    // Create new game instance
    var game_instance = Game{
        .allocator = allocator,
        .current_time = rl.getTime(),
        .active_scene = &main_scene,
    };

    // Start the main game loop depending on the platform
    if (!is_web_build) {
        while (!rl.windowShouldClose()) {
            try mainLoop(&game_instance);
        }
    } else {
        emscripten_set_main_loop_arg(
            emscriptenMainLoop,
            @ptrCast(&game_instance),
            0,
            1,
        );
    }
}

fn mainLoop(game: *Game) !void {
    const new_time = rl.getTime();
    var frame_time = new_time - game.current_time;
    game.per_second_accumulator += frame_time;
    time.storeRealtimeForCurrentFrame(new_time);
    time.storeDeltaTimeForCurrentFrame(@as(f32, @floatCast(frame_time)));
    if (frame_time > Game.max_frame_time) {
        frame_time = Game.max_frame_time;
    }
    time.incrementTime(frame_time);
    game.current_time = new_time;

    game.accumulator += frame_time;

    while (game.accumulator >= Game.fixed_dt) {
        fixedUpdate(game.active_scene);
        //t += fixed_dt;
        game.accumulator -= Game.fixed_dt;
    }

    // Track FPS
    game.frame_counter += 1;
    if (game.per_second_accumulator >= 1.0) {
        time.storeFPS(game.frame_counter); // Store FPS for the current second
        game.per_second_accumulator = 0.0;
        game.frame_counter = 0;
    }

    renderUpdate(game.active_scene);
    draw(game.active_scene);
}

fn emscriptenMainLoop(ptr: *anyopaque) callconv(.c) void {
    const game_instance: *Game = @ptrCast(@alignCast(ptr));
    try mainLoop(game_instance);
}

fn loadContent(allocator: std.mem.Allocator) !void {
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;

    // Load music and sound effects
    audio_engine.init(allocator);
    for (1..audio_engine.music.len) |i| {
        const path = try std.fmt.bufPrintZ(&path_buf, "resources/sounds/music/Music_{d}.ogg", .{i + 1});
        audio_engine.music[i] = rl.loadMusicStream(path.ptr);
    }
    try audio_engine.loadSound("menu_tick", "resources/sounds/Menu_Tick.wav");

    // Load textures
    texture_assets.cursor = texture_assets.load("resources/images/Cursor.png");
    for (0..texture_assets.logo.len) |i| {
        const path = try std.fmt.bufPrintZ(&path_buf, "resources/images/Logo_{d}.png", .{i + 1});
        texture_assets.logo[i] = texture_assets.load(path);
    }

    // Load fonts
    font_assets.init(allocator);
    font_assets.andy = try font_assets.load("resources/fonts/Andy Bold.ttf", 24);
}

fn unloadContent() void {
    // Unload music and sound effects
    audio_engine.deinit();

    // Unload textures
    rl.unloadTexture(texture_assets.cursor);
    for (texture_assets.logo) |texture| {
        rl.unloadTexture(texture);
    }

    // Unload fonts
    font_assets.deinit();
    rl.unloadFont(font_assets.andy);
}

fn fixedUpdate(scene: *Scene) void {
    //std.debug.print("Fixed update\n", .{});
    scene.fixedUpdate();
}

fn renderUpdate(scene: *Scene) void {
    audio_engine.updateMusic(); // Update music to keep it playing

    scene.renderUpdate();
}

fn draw(scene: *Scene) void {
    animateCursor();

    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);

    // Draw sky gradient
    const sky_blue_top = rl.Color{ .r = 25, .g = 101, .b = 255, .a = 255 };
    const sky_blue_bottom = rl.Color{ .r = 132, .g = 170, .b = 248, .a = 255 };
    rl.drawRectangleGradientV(
        0,
        0,
        rl.getScreenWidth(),
        rl.getScreenHeight(),
        sky_blue_top,
        sky_blue_bottom,
    );

    drawRenderables(scene);

    // Draw custom mouse cursor above everything else
    const cursor_pos = getMousePosition();
    const should_draw_cursor = if (builtin.os.tag == .windows) true else rl.isCursorOnScreen();
    if (should_draw_cursor) {
        rl.drawTexture(
            texture_assets.cursor,
            @intFromFloat(cursor_pos.x),
            @intFromFloat(cursor_pos.y),
            Game.mouse_color,
        );
    }

    rl.endDrawing();
}

fn drawRenderables(scene: *Scene) void {
    for (scene.objects.items) |object| {
        const transform = object.getComponent(.transform);
        if (transform) |tr| {
            // Calls any custom draw logic on any behaviours attached to the object
            object.draw();

            const sprite = object.getComponent(.sprite);
            if (sprite) |s| {
                rl.drawTexturePro(
                    s.texture,
                    .{ .x = 0, .y = 0, .width = @floatFromInt(s.texture.width), .height = @floatFromInt(s.texture.height) },
                    .{
                        // Adjusting for origin offset scaled by the texture dimensions and t.scale
                        .x = tr.position.x,
                        .y = tr.position.y,
                        .width = @as(f32, @floatFromInt(s.texture.width)) * tr.scale,
                        .height = @as(f32, @floatFromInt(s.texture.height)) * tr.scale,
                    },
                    .{
                        .x = @as(f32, @floatFromInt(s.texture.width)) * tr.origin.x * tr.scale,
                        .y = @as(f32, @floatFromInt(s.texture.height)) * tr.origin.y * tr.scale,
                    },
                    tr.rotation * (180.0 / std.math.pi),
                    s.tint,
                );
            }

            const text = object.getComponent(.text);
            if (text) |te| {
                if (te.text.len == 0) { // Skip rendering empty text
                    continue;
                }
                const font_size = font_assets.getBaseFontSize(te.font.texture).? * tr.scale;
                const text_size = rl.measureTextEx(te.font, te.text, font_size, te.spacing);
                rl.drawTextPro(
                    te.font,
                    te.text,
                    tr.position,
                    .{
                        .x = tr.origin.x * text_size.x,
                        .y = tr.origin.y * text_size.y,
                    },
                    tr.rotation,
                    font_size,
                    te.spacing,
                    te.tint,
                );
            }
        }
    }
}

fn getMousePosition() rl.Vector2 {
    if (builtin.target.os.tag == .windows) {
        var point = win32.foundation.POINT{ .x = 0, .y = 0 };
        _ = win32.ui.windows_and_messaging.GetCursorPos(&point);
        std.debug.print("Mouse position: ({d}, {d})\n", .{ point.x, point.y });
        const window_pos = rl.getWindowPosition();
        point.x -= @intFromFloat(window_pos.x);
        point.y -= @intFromFloat(window_pos.y);
        const cursor_pos = rl.Vector2{
            .x = @floatFromInt(point.x),
            .y = @floatFromInt(point.y),
        };
        return cursor_pos;
    } else {
        return rl.getMousePosition();
    }
}

fn animateCursor() void {
    _ = rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
}

fn getRandomWindowTitle() [*:0]const u8 {
    const rand = rl.getRandomValue(0, 4);
    switch (rand) {
        0 => return "Terraria Classic: Dig Peon, Dig!",
        1 => return "Terraria Classic: Hey Guys!",
        2 => return "Terraria Classic: Epic Dirt",
        3 => return "Terraria Classic: Nobody Asked For This",
        4 => return "Terraria Classic 2: Electric Boogaloo",
        else => unreachable,
    }
}
