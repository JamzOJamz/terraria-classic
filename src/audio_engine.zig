const rl = @import("raylib");

pub var music: [1]rl.Music = undefined;
pub var menu_tick: rl.Sound = undefined;
const curMusic = 0;

pub const SoundID = enum(usize) {
    menu_tick,
};

pub fn load() !void {
    music[0] = try loadMusicStream("Resources/Sounds/Music/TitleScreen.mp3", 0.225);
    menu_tick = try rl.loadSound("Resources/Sounds/Menu_Tick.wav");
}

pub fn unload() void {
    for (music) |m| {
        rl.unloadMusicStream(m);
    }
}

fn loadMusicStream(path: [*:0]const u8, volume: f32) !rl.Music {
    const music_stream = try rl.loadMusicStream(path);
    rl.setMusicVolume(music_stream, volume);
    return music_stream;
}

pub fn playSound(sound: SoundID) void {
    switch (sound) {
        SoundID.menu_tick => rl.playSound(menu_tick),
    }
}

pub fn updateMusic() void {
    if (!rl.isMusicStreamPlaying(music[curMusic])) {
        rl.playMusicStream(music[curMusic]);
    }

    rl.updateMusicStream(music[curMusic]);
}
