const std = @import("std");

const rl = @import("raylib");

var font_base_sizes: std.AutoHashMap(u32, f32) = undefined;
pub var andy: rl.Font = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    font_base_sizes = std.AutoHashMap(u32, f32).init(allocator);
}

pub fn deinit() void {
    font_base_sizes.deinit();
}

pub fn load(path: [:0]const u8, base_size: i32) !rl.Font {
    var font = rl.loadFont(path.ptr);
    rl.genTextureMipmaps(&font.texture);
    rl.setTextureFilter(font.texture, rl.TextureFilter.texture_filter_trilinear);
    try font_base_sizes.put(font.texture.id, @floatFromInt(base_size));
    return font;
}

pub fn getBaseFontSize(font_texture: rl.Texture) ?f32 {
    return font_base_sizes.get(font_texture.id);
}
