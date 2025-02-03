pub const maximum_delta_time: f64 = 1.0 / 3.0; // 0.3333 seconds
pub const fixed_tick_rate = 60.0; // 60 ticks per second
pub const fixed_dt = 1.0 / fixed_tick_rate; // 0.01666 seconds

pub var accumulator: f64 = 0.0;
pub var per_second_accumulator: f64 = 0.0;
pub var current_time: f64 = 0.0;
pub var delta_time: f32 = 0.0;
pub var delta_time_in_ticks: f32 = 0.0;
pub var unscaled_delta_time: f32 = 0.0;
var frame_counter: u32 = 0;
pub var fps: u32 = 0;

pub fn setDeltaTime(new_delta_time: f32) void {
    delta_time = new_delta_time;
    delta_time_in_ticks = delta_time * fixed_tick_rate;
}

pub fn trackFPS() void {
    frame_counter += 1;
    if (per_second_accumulator >= 1.0) {
        fps = frame_counter;
        per_second_accumulator = 0.0;
        frame_counter = 0;
    }
}
