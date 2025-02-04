const rl = @import("raylib");

const texture_assets = @import("texture_assets.zig");
const time = @import("time.zig");
const draw_utils = @import("utils/draw_utils.zig");
const general_utils = @import("utils/general_utils.zig");

const mouseColor = rl.Color{
    .r = 255,
    .g = 50,
    .b = 95,
    .a = 255,
};
var color: rl.Color = .white;
var color_direction: i2 = 1;
var alpha: f32 = 0.0;
var scale: f32 = 0.0;

pub fn animate() void {
    alpha += @as(f32, @floatFromInt(color_direction)) * 0.015 * time.delta_time_in_ticks;
    if (alpha >= 1.0) {
        alpha = 1.0;
        color_direction = -1;
    }
    if (alpha <= 0.6) {
        alpha = 0.6;
        color_direction = 1;
    }
    const num = alpha * 0.3 + 0.7;
    color = rl.Color{
        .r = @intFromFloat(@as(f32, @floatFromInt(mouseColor.r)) * alpha),
        .g = @intFromFloat(@as(f32, @floatFromInt(mouseColor.g)) * alpha),
        .b = @intFromFloat(@as(f32, @floatFromInt(mouseColor.b)) * alpha),
        .a = @intFromFloat(255 * num),
    };
    scale = num + 0.1;
}

pub fn draw() void {
    const mouse_pos = general_utils.getMousePosition();
    const offset_mouse_pos = mouse_pos.addValue(1.0);
    const texture = texture_assets.cursor;
    const source = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(texture.width),
        .height = @floatFromInt(texture.height),
    };
    const origin = rl.Vector2.zero();

    // Draw cursor shadow
    draw_utils.drawTexturePro(
        texture,
        offset_mouse_pos,
        source,
        .init(
            @intFromFloat(@as(f32, @floatFromInt(color.r)) * 0.2),
            @intFromFloat(@as(f32, @floatFromInt(color.g)) * 0.2),
            @intFromFloat(@as(f32, @floatFromInt(color.b)) * 0.2),
            @intFromFloat(@as(f32, @floatFromInt(color.a)) * 0.5),
        ),
        0.0,
        origin,
        scale * 1.1,
    );

    // Draw cursor
    draw_utils.drawTexturePro(
        texture,
        mouse_pos,
        source,
        color,
        0.0,
        origin,
        scale,
    );
}
