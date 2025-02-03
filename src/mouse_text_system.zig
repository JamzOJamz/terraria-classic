const std = @import("std");

const rl = @import("raylib");

const time = @import("time.zig");

pub var color: rl.Color = .blank;
var alpha: f32 = 0.0;
var alpha_change: i8 = 1;

pub fn update() void {
    alpha += @as(f32, @floatFromInt(alpha_change)) * time.delta_time_in_ticks;
    if (alpha >= 250.0) {
        alpha_change = -4;
    }
    if (alpha <= 175.0) {
        alpha_change = 4;
    }

    // Clamp alpha to 0-255
    alpha = std.math.clamp(alpha, 0.0, 255.0);

    color = rl.Color{
        .r = 255,
        .g = 255,
        .b = 255,
        .a = @intFromFloat(alpha),
    };
}
