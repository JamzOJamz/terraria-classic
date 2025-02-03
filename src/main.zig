const std = @import("std");
const builtin = @import("builtin");

const rl = @import("raylib");

const audio_engine = @import("audio_engine.zig");
const Cloud = @import("Cloud.zig");
const cursor = @import("cursor.zig");
const font_assets = @import("font_assets.zig");
const menu = @import("menu.zig");
const mouse_text_system = @import("mouse_text_system.zig");
const texture_assets = @import("texture_assets.zig");
const time = @import("time.zig");
const utils = @import("utils.zig");

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

var rand: std.Random = undefined;
var show_splash: bool = true;
var splash_counter: f32 = 0;
var fade_counter: f32 = 0;
var in_game_menu: bool = true;
var show_frame_rate: bool = false;

const max_clouds = 100;
const min_clouds = 10;
var clouds: [max_clouds]Cloud = undefined;
var num_clouds: u32 = max_clouds;
var should_reset_clouds: bool = true;
var wind_speed: f32 = 0.0;

pub fn main() !void {
    try initialize();
    defer deinitialize();

    try startGameLoop();
}

fn initialize() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();
    @memset(&clouds, .{});

    const window_width = 800;
    const window_height = 600;
    const fps_target = -1;

    //rl.setTraceLogLevel(.none);
    rl.initAudioDevice();
    rl.setAudioStreamBufferSizeDefault(4096);
    rl.setMasterVolume(1.0);
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

fn fixedUpdate() void {}

fn renderUpdate() void {
    audio_engine.updateMusic();
    cursor.animate();
    mouse_text_system.update();

    if (show_splash) return;

    if (should_reset_clouds) {
        resetClouds();
        should_reset_clouds = false;
    }

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

    // Draw clouds
    for (0..100) |i| {
        var cloud = clouds[i];
        if (!cloud.active) continue;
        cloud.draw();
    }

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

fn resetClouds() void {
    num_clouds = rand.intRangeAtMost(u32, min_clouds, max_clouds);
    wind_speed = 0.0;
    while (wind_speed == 0.0) {
        wind_speed = @as(f32, @floatFromInt(rand.intRangeAtMost(i32, -100, 100))) * 0.01;
    }
    for (&clouds) |*cloud| {
        cloud.active = false;
    }
    for (0..num_clouds) |_| {
        addCloud();
    }
    const wind_speed_direction = std.math.sign(wind_speed);
    for (0..num_clouds) |i| {
        var cloud = &clouds[i];
        cloud.position.x += @as(f32, @floatFromInt(rl.getScreenWidth() * 2)) * wind_speed_direction;
    }
}

fn addCloud() void {
    var next_free_index: u32 = std.math.maxInt(u32);
    for (0..100) |i| {
        if (!clouds[i].active) {
            next_free_index = @intCast(i);
            break;
        }
    }

    if (next_free_index == std.math.maxInt(u32)) return;

    var cloud = &clouds[next_free_index];
    const @"type" = rand.uintLessThan(u32, 4);
    const texture = texture_assets.cloud[@"type"];
    cloud.rotation_speed = 0.0;
    cloud.scale_speed = 0.0;
    cloud.type = @"type";
    cloud.scale = @as(f32, @floatFromInt(rand.intRangeLessThan(i32, 8, 13))) * 0.1;
    cloud.rotation = @as(f32, @floatFromInt(rand.intRangeLessThan(i32, -10, 11))) * 0.01;
    cloud.width = @intFromFloat(@as(f32, @floatFromInt(texture.width)) * cloud.scale);
    cloud.height = @intFromFloat(@as(f32, @floatFromInt(texture.height)) * cloud.scale);
    if (wind_speed > 0.0) {
        cloud.position.x = @as(f32, @floatFromInt(-cloud.width - texture.width - rand.intRangeLessThan(i32, 0, rl.getScreenWidth() * 2)));
    } else {
        cloud.position.x = @as(f32, @floatFromInt(rl.getScreenWidth() + texture.width + rand.intRangeLessThan(i32, 0, rl.getScreenWidth() * 2)));
    }
    cloud.position.y = @as(f32, @floatFromInt(
        rand.intRangeLessThan(
            i32,
            @intFromFloat(@as(f32, @floatFromInt(-rl.getScreenHeight())) * 0.25),
            @intFromFloat(@as(f32, @floatFromInt(rl.getScreenHeight())) * 1.25),
        ),
    ));
    for (0..2) |_| {
        cloud.position.y = cloud.position.y - @as(f32, @floatFromInt(
            rand.uintLessThan(
                u32,
                @intFromFloat(@as(f32, @floatFromInt(rl.getScreenHeight())) * 0.25),
            ),
        ));
    }
    cloud.scale *= 2.2 - ((cloud.position.y + @as(f32, @floatFromInt(rl.getScreenHeight())) * 0.25) / (@as(f32, @floatFromInt(rl.getScreenHeight())) * 1.5) + 0.7);
    cloud.scale = std.math.clamp(cloud.scale, 0.6, 1.4);
    cloud.active = true;

    // Remove clouds that overlap each other
    const rect = rl.Rectangle{
        .x = cloud.position.x,
        .y = cloud.position.y,
        .width = @floatFromInt(cloud.width),
        .height = @floatFromInt(cloud.height),
    };
    for (0..100) |i| {
        if (i == next_free_index) continue;
        const other = &clouds[i];
        if (!other.active) continue;
        const other_rect = rl.Rectangle{
            .x = other.position.x,
            .y = other.position.y,
            .width = @floatFromInt(other.width),
            .height = @floatFromInt(other.height),
        };
        if (rl.checkCollisionRecs(rect, other_rect)) {
            cloud.active = false;
        }
    }

    //std.debug.print("New cloud at index {d}: {}\n", .{ next_free_index, cloud });
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
