const std = @import("std");
const builtin = @import("builtin");

const rl = @import("raylib");

const audio_engine = @import("audio_engine.zig");
const BackgroundSystem = @import("BackgroundSystem.zig");
const Cloud = @import("Cloud.zig");
const cursor = @import("cursor.zig");
const font_assets = @import("font_assets.zig");
const menu = @import("menu.zig");
const mouse_text_system = @import("mouse_text_system.zig");
const texture_assets = @import("texture_assets.zig");
const time = @import("time.zig");

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

var allocator: std.mem.Allocator = undefined;
var prng: std.Random.DefaultPrng = undefined;
var rand: std.Random = undefined;
var show_splash: bool = true;
var splash_counter: f32 = 0;
var fade_counter: f32 = 0;
var in_game_menu: bool = true;
var show_frame_rate: bool = false;
var background: BackgroundSystem = undefined;

pub fn main() !void {
    try initialize();
    defer deinitialize();

    try startGameLoop();
}

fn initialize() !void {
    // Get the allocator for the game depending on the platform
    const is_web_build = builtin.os.tag == .emscripten;
    var gpa_state = if (!is_web_build) std.heap.GeneralPurposeAllocator(.{}){} else {};
    defer {
        if (!is_web_build) _ = gpa_state.deinit();
    }
    allocator = if (!is_web_build) gpa_state.allocator() else std.heap.c_allocator;

    // Create a random number generator for the game using the system's PRNG
    prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();

    // Initialize some game systems
    background = try BackgroundSystem.init(&rand);

    const window_width = 800;
    const window_height = 600;
    const fps_target = -1;
    const master_volume = 1.0;

    //rl.setTraceLogLevel(.none);
    rl.initAudioDevice();
    rl.setAudioStreamBufferSizeDefault(4096);
    rl.setMasterVolume(master_volume);
    rl.initWindow(window_width, window_height, getRandomWindowTitle().ptr);
    rl.setExitKey(.null);
    rl.setTargetFPS(fps_target);
    rl.hideCursor();

    try loadContent();
}

fn deinitialize() void {
    unloadContent();

    rl.closeAudioDevice();
    rl.closeWindow();
}

fn loadContent() !void {
    try font_assets.load(); // Load game fonts
    try texture_assets.load(); // Load game textures
    try audio_engine.load(); // Load game audio
}

fn unloadContent() void {
    font_assets.unload(); // Unload game fonts
    texture_assets.unload(); // Unload game textures
    audio_engine.unload(); // Unload game audio
}

fn startGameLoop() !void {
    while (!rl.windowShouldClose()) {
        try gameLoop();
    }
}

fn gameLoop() !void {
    const new_time = rl.getTime();
    var frame_time = new_time - time.current_time;
    time.per_second_accumulator += frame_time;
    time.unscaled_delta_time = @floatCast(frame_time);
    if (frame_time > time.maximum_delta_time) {
        frame_time = time.maximum_delta_time;
    }
    time.setDeltaTime(@floatCast(frame_time));
    time.current_time = new_time;

    time.accumulator += frame_time;

    while (time.accumulator >= time.fixed_dt) {
        fixedUpdate();
        time.accumulator -= time.fixed_dt;
    }

    time.trackFPS();

    renderUpdate();
    try draw();
}

fn fixedUpdate() void {
    if (show_splash) return;

    background.tick();
}

fn renderUpdate() void {
    audio_engine.updateMusic();
    cursor.animate();
    mouse_text_system.update();

    if (show_splash) return;

    background.renderUpdate();

    if (rl.isKeyPressed(.f10)) {
        show_frame_rate = !show_frame_rate;
        audio_engine.playSound(.menu_tick);
    }
}

fn draw() !void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(.black);

    rl.beginBlendMode(.alpha_premultiply);
    defer rl.endBlendMode();

    if (show_splash) {
        drawSplash();
        return;
    }

    background.draw();

    if (in_game_menu) try menu.draw();

    cursor.draw();
    drawFadeOverlay();
}

fn drawSplash() void {
    splash_counter += 1.0 * time.delta_time_in_ticks;

    var alpha: f32 = 0.0;
    if (splash_counter <= 75.0) {
        alpha = splash_counter / 75.0 * 255.0;
    } else if (splash_counter <= 200.0) {
        alpha = 255.0;
    } else if (splash_counter <= 275.0) {
        alpha = (275.0 - splash_counter) / 75.0 * 255.0;
    } else {
        show_splash = false;
        fade_counter = 75.0;
    }

    rl.drawTexture(
        texture_assets.splash_texture,
        0,
        0,
        rl.Color{
            .r = @intFromFloat(alpha),
            .g = @intFromFloat(alpha),
            .b = @intFromFloat(alpha),
            .a = @intFromFloat(alpha),
        },
    );
}

fn drawFadeOverlay() void {
    if (fade_counter <= 0.0) return;

    fade_counter -= 1.0 * time.delta_time_in_ticks;

    const alpha = fade_counter / 75.0 * 255.0;
    if (alpha <= 0.0) return;

    rl.drawRectangle(
        0,
        0,
        rl.getScreenWidth(),
        rl.getScreenHeight(),
        rl.Color{
            .r = 0,
            .g = 0,
            .b = 0,
            .a = @intFromFloat(alpha),
        },
    );
}

pub fn drawFPS() !void {
    if (!show_frame_rate) return;

    var buf: [16]u8 = undefined;
    const fps_text = try std.fmt.bufPrintZ(
        &buf,
        "{d} FPS",
        .{time.fps},
    );

    rl.endBlendMode();
    rl.beginBlendMode(.alpha);
    rl.drawTextPro(
        font_assets.andy,
        fps_text,
        rl.Vector2{
            .x = 4.0,
            .y = @as(f32, @floatFromInt(rl.getScreenHeight())) - 24.0,
        },
        rl.Vector2.zero(),
        0.0,
        24.0,
        0.0,
        mouse_text_system.color,
    );
    rl.endBlendMode();
    rl.beginBlendMode(.alpha_premultiply);
}

/// Returns a random window title for the game to use from a list of options.
fn getRandomWindowTitle() [:0]const u8 {
    const titles = [_][:0]const u8{
        "Terraria Classic: Dig Peon, Dig!",
        "Terraria Classic: Epic Dirt",
        "Terraria Classic: Hey Guys!",
        "Terraria Classic: Sand is Overpowered",
        "Terraria Classic: Shut Up and Dig Gaiden!",
    };
    return titles[rand.uintLessThan(usize, titles.len)];
}
