const rl = @import("raylib");

pub var cursor: rl.Texture = undefined;
pub var splash: rl.Texture = undefined;
pub var logo: [5]rl.Texture = undefined;

pub fn load(path: [:0]const u8) rl.Texture {
    const texture = rl.loadTexture(path.ptr);
    rl.setTextureFilter(texture, rl.TextureFilter.texture_filter_bilinear);
    rl.setTextureWrap(texture, rl.TextureWrap.texture_wrap_clamp);
    return texture;
}

pub fn eql(a: rl.Texture, b: rl.Texture) bool {
    return a.id == b.id;
}
