const std = @import("std");

const rl = @import("raylib");

const texture_assets = @import("texture_assets.zig");
const draw_utils = @import("utils/draw_utils.zig");

const Self = @This();

width: i32 = 0,
height: i32 = 0,
position: rl.Vector2 = .{
    .x = 0,
    .y = 0,
},
rotation: f32 = 0.0,
rotation_speed: f32 = 0.0,
scale: f32 = 0.0,
scale_speed: f32 = 0.0,
type: u32 = 0,
active: bool = false,

pub fn draw(self: *Self) void {
    const texture = texture_assets.cloud[self.type];
    const alpha = 255 - @as(u8, @intFromFloat(std.math.clamp(40.0 * (2.0 - self.scale), 0.0, 255.0)));
    const color = rl.Color{
        .r = alpha,
        .g = alpha,
        .b = alpha,
        .a = alpha,
    };

    draw_utils.drawTexturePro(
        texture,
        self.position,
        .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        },
        color,
        self.rotation,
        .{ .x = 0.5, .y = 0.5 },
        self.scale,
    );
}
