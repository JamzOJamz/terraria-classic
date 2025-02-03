const std = @import("std");

const rl = @import("raylib");

pub var cursor: rl.Texture = undefined;
pub var splash_texture: rl.Texture = undefined;
pub var logo: rl.Texture = undefined;
pub var cloud: [4]rl.Texture = undefined;

pub fn load() !void {
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;

    cursor = try loadTexture("Resources/Images/Cursor.png");
    splash_texture = try loadTexture("Resources/Images/Splash.png");
    logo = try loadTexture("Resources/Images/Logo.png");
    for (0..cloud.len) |i| {
        const path = try std.fmt.bufPrintZ(&path_buf, "Resources/Images/Cloud_{d}.png", .{i});
        cloud[i] = try loadTexture(path.ptr);
    }
}

pub fn unload() void {
    rl.unloadTexture(cursor);
    rl.unloadTexture(splash_texture);
    rl.unloadTexture(logo);
    for (cloud) |c| {
        rl.unloadTexture(c);
    }
}

fn loadTexture(path: [*:0]const u8) !rl.Texture {
    const texture = try rl.loadTexture(path);
    rl.setTextureFilter(texture, .bilinear);
    rl.setTextureWrap(texture, .clamp);
    return texture;
}
