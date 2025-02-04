const std = @import("std");

const rl = @import("raylib");

pub fn drawTexturePro(
    texture: rl.Texture2D,
    position: rl.Vector2,
    source: rl.Rectangle,
    tint: rl.Color,
    rotation: f32,
    origin: rl.Vector2,
    scale: f32,
) void {
    const scaled_width = @as(f32, @floatFromInt(texture.width)) * scale;
    const scaled_height = @as(f32, @floatFromInt(texture.height)) * scale;
    rl.drawTexturePro(
        texture,
        source,
        .{
            .x = position.x,
            .y = position.y,
            .width = scaled_width,
            .height = scaled_height,
        },
        .{
            .x = origin.x * scaled_width,
            .y = origin.y * scaled_height,
        },
        rotation * std.math.deg_per_rad,
        tint,
    );
}
