const std = @import("std");

const rl = @import("raylib");

var frame_rate: u32 = 0;
var delta_time: f32 = 0.0;
var delta_time_in_ticks: f32 = 0.0;
var unscaled_delta_time: f32 = 0.0;
var unscaled_delta_time_in_ticks: f32 = 0.0;
var time: f32 = 0.0;
var time_in_ticks: f32 = 0.0;
var time_as_double: f64 = 0.0;
var real_time_since_startup: f64 = 0.0;
pub const maximum_delta_time = 1.0 / 3.0; // 0.3333 seconds
pub const fixed_tick_rate = 60.0; // 60 ticks per second

pub fn getDeltaTime() f32 {
    return delta_time;
}

pub fn getUnscaledDeltaTime() f32 {
    return unscaled_delta_time;
}

pub fn getDeltaTimeInTicks() f32 {
    return delta_time_in_ticks;
}

pub fn getTime() f32 {
    return time;
}

pub fn getTimeInTicks() f32 {
    return time_in_ticks;
}

pub fn getTimeAsDouble() f64 {
    return time_as_double;
}

pub fn getFrameRate() u32 {
    return frame_rate;
}

pub fn storeFPS(fps: u32) void {
    frame_rate = fps;
}

pub fn storeDeltaTimeForCurrentFrame(dt: f32) void {
    delta_time = dt;
    delta_time_in_ticks = dt * fixed_tick_rate;
    unscaled_delta_time = delta_time;
    unscaled_delta_time_in_ticks = delta_time_in_ticks;
    if (delta_time > maximum_delta_time) {
        delta_time = maximum_delta_time;
    }
    if (delta_time_in_ticks > maximum_delta_time * fixed_tick_rate) {
        delta_time_in_ticks = maximum_delta_time * fixed_tick_rate;
    }
}

pub fn storeRealtimeForCurrentFrame(t: f64) void {
    real_time_since_startup = t;
}

pub fn incrementTime(dt: f64) void {
    time_as_double += dt;
    time = @floatCast(time_as_double);
    time_in_ticks = time * fixed_tick_rate;
}
