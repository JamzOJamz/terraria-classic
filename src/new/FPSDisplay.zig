const std = @import("std");

const rl = @import("raylib");

const audio_engine = @import("audio_engine.zig");
const Behaviour = @import("Behaviour.zig");
const GameObject = @import("GameObject.zig");
const Scene = @import("Scene.zig");
const Text = @import("Text.zig");
const time = @import("time.zig");

const FPSDisplay = @This();

// Fields
// --------------------------------------------------
text: ?*Text = null,
show_frame_rate: bool = false,
text_buffer: [16]u8 = undefined, // Should be enough to hold any FPS format string
// --------------------------------------------------

pub fn start(self: *FPSDisplay, scene: *Scene, object: *GameObject) void {
    _ = scene; // autofix
    self.text = object.getComponent(.text);
}

pub fn fixedUpdate(self: *FPSDisplay, object: *GameObject) void {
    _ = object; // autofix
    if (self.text) |text| {
        if (!self.show_frame_rate) {
            text.text = "";
            return;
        }

        const fps = time.getFrameRate();
        const fps_text = std.fmt.bufPrintZ(
            &self.text_buffer,
            "{d} FPS",
            .{fps},
        ) catch return;

        text.text = fps_text;
    }
}

pub fn update(self: *FPSDisplay, object: *GameObject) void {
    _ = object; // autofix
    if (rl.isKeyPressed(rl.KeyboardKey.key_f10)) {
        self.show_frame_rate = !self.show_frame_rate;
        audio_engine.playSound("menu_tick");
    }
}

const vtable: Behaviour.VTable = .{
    .start = @ptrCast(&start),
    .fixedUpdate = @ptrCast(&fixedUpdate),
    .renderUpdate = @ptrCast(&update),
    .deinit = Behaviour.makeDestructor(FPSDisplay),
};

pub fn behaviour(self: *FPSDisplay) Behaviour {
    return .{
        .ptr = self,
        .kind = Behaviour.id(FPSDisplay),
        .vtable = &vtable,
    };
}
