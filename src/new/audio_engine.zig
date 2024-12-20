const std = @import("std");

const rl = @import("raylib");

pub const MusicId = enum {
    old_title,
    new_title,
};

pub var music: [2]rl.Music = undefined;
var active_music: ?MusicId = null;
var sound_misc_map: std.StringHashMap(rl.Sound) = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    sound_misc_map = std.StringHashMap(rl.Sound).init(allocator);
}

pub fn deinit() void {
    for (music) |m| {
        rl.unloadMusicStream(m);
    }
    var it = sound_misc_map.valueIterator();
    while (it.next()) |sound| {
        rl.unloadSound(sound.*);
    }
    sound_misc_map.deinit();
}

pub fn playMusic(id: MusicId) void {
    if (active_music) |active_id| {
        rl.stopMusicStream(music[@intFromEnum(active_id)]);
        active_music = null;
    }
    rl.playMusicStream(music[@intFromEnum(id)]);
    active_music = id;
}

pub fn setMusicInstanceVolume(id: MusicId, volume: f32) void {
    rl.setMusicVolume(music[@intFromEnum(id)], volume);
}

pub fn updateMusic() void {
    if (active_music) |id| {
        rl.updateMusicStream(music[@intFromEnum(id)]);
    }
}

pub fn loadSound(key: []const u8, path: [:0]const u8) !void {
    const sound = rl.loadSound(path.ptr);
    try sound_misc_map.put(key, sound);
}

pub fn playSound(key: []const u8) void {
    if (sound_misc_map.get(key)) |sound| {
        rl.playSound(sound);
    }
}
