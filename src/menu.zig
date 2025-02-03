const std = @import("std");

const rl = @import("raylib");

const main = @import("main.zig");
const texture_assets = @import("texture_assets.zig");
const time = @import("time.zig");

var logo_rotation: f32 = 0.0;
var logo_rotation_direction: f32 = 1.0;
var logo_rotation_speed: f32 = 1.0;
var logo_scale: f32 = 1.0;
var logo_scale_direction: f32 = 1.0;
var logo_scale_speed: f32 = 1.0;

pub fn draw() !void {
    drawLogo();

    try main.drawFPS();
}

/// Draws the game logo with a rotating and scaling effect.
fn drawLogo() void {
    const logo_rotation_factor = 0.00003;
    const logo_rotation_max = 0.1;
    const logo_rotation_min = -0.1;
    const rotation_speed_increment = 1.0;
    const rotation_speed_max = 20.0;
    const rotation_speed_min = -20.0;

    const logo_scale_factor = 0.00001;
    const logo_scale_max = 1.1;
    const logo_scale_min = 0.9;
    const scale_speed_increment = 1.0;
    const scale_speed_max = 50.0;
    const scale_speed_min = -50.0;

    logo_rotation += logo_rotation_speed * logo_rotation_factor * time.delta_time_in_ticks;
    if (logo_rotation > logo_rotation_max) {
        logo_rotation_direction = -1.0;
    } else if (logo_rotation < logo_rotation_min) {
        logo_rotation_direction = 1.0;
    }
    if (logo_rotation_speed < rotation_speed_max and logo_rotation_direction == 1.0) {
        logo_rotation_speed += rotation_speed_increment * time.delta_time_in_ticks;
    } else if (logo_rotation_speed > rotation_speed_min and logo_rotation_direction == -1.0) {
        logo_rotation_speed -= rotation_speed_increment * time.delta_time_in_ticks;
    }

    logo_scale += logo_scale_speed * logo_scale_factor * time.delta_time_in_ticks;
    if (logo_scale > logo_scale_max) {
        logo_scale_direction = -1.0;
    } else if (logo_scale < logo_scale_min) {
        logo_scale_direction = 1.0;
    }
    if (logo_scale_speed < scale_speed_max and logo_scale_direction == 1.0) {
        logo_scale_speed += scale_speed_increment * time.delta_time_in_ticks;
    } else if (logo_scale_speed > scale_speed_min and logo_scale_direction == -1.0) {
        logo_scale_speed -= scale_speed_increment * time.delta_time_in_ticks;
    }

    const logo_texture = texture_assets.logo;
    const scaled_width = @as(f32, @floatFromInt(logo_texture.width)) * logo_scale;
    const scaled_height = @as(f32, @floatFromInt(logo_texture.height)) * logo_scale;
    rl.drawTexturePro(
        logo_texture,
        rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(logo_texture.width),
            .height = @floatFromInt(logo_texture.height),
        },
        rl.Rectangle{
            .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0,
            .y = 100,
            .width = scaled_width,
            .height = scaled_height,
        },
        rl.Vector2{
            .x = scaled_width / 2.0,
            .y = scaled_height / 2.0,
        },
        logo_rotation * (180.0 / std.math.pi),
        .white,
    );
}
