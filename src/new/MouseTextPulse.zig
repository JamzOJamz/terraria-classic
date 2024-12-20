const std = @import("std");

const Behaviour = @import("Behaviour.zig");
const GameObject = @import("GameObject.zig");
const Scene = @import("Scene.zig");
const Text = @import("Text.zig");
const time = @import("time.zig");

const MouseTextPulse = @This();

// Constants
// --------------------------------------------------

/// Minimum alpha value (transparency) for the pulse effect.
const alpha_min = 175.0;

/// Maximum alpha value (transparency) for the pulse effect.
const alpha_max = 250.0;

/// Number of ticks it takes to complete half a pulse cycle (bottom to top or top to bottom).
const half_period_ticks = 19.0;

// --------------------------------------------------

// Fields
// --------------------------------------------------
text: ?*Text = null,
// --------------------------------------------------

fn start(self: *MouseTextPulse, scene: *Scene, object: *GameObject) void {
    _ = scene; // autofix
    self.text = object.getComponent(.text);
}

fn update(self: *MouseTextPulse, object: *GameObject) void {
    _ = object; // autofix
    if (self.text) |text| {
        text.tint.a = calculatePulse();
    }
}

fn calculatePulse() u8 {
    const current_time = time.getTimeInTicks();
    const ping_pong_timer = pingPong(current_time / half_period_ticks, 1);
    const alpha: u8 = @as(u8, @intFromFloat(std.math.lerp(alpha_min, alpha_max, ping_pong_timer)));
    return alpha;
}

fn pingPong(t: f32, length: f32) f32 {
    const mod = @mod(t, 2 * length);
    return length - @abs(mod - length);
}

const vtable: Behaviour.VTable = .{
    .start = @ptrCast(&start),
    .renderUpdate = @ptrCast(&update),
    .deinit = Behaviour.makeDestructor(MouseTextPulse),
};

pub fn behaviour(self: *MouseTextPulse) Behaviour {
    return .{
        .ptr = self,
        .kind = Behaviour.id(MouseTextPulse),
        .vtable = &vtable,
    };
}
