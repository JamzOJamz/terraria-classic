const rl = @import("raylib");

pub var andy: rl.Font = undefined;

pub fn load() !void {
    andy = try loadFont("Resources/Fonts/Andy Bold.ttf");
}

pub fn unload() void {
    rl.unloadFont(andy);
}

fn loadFont(path: [*:0]const u8) !rl.Font {
    var font = try rl.loadFont(path);
    rl.genTextureMipmaps(&font.texture);
    rl.setTextureFilter(font.texture, .bilinear);
    return font;
}
