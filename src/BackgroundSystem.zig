const std = @import("std");

const rl = @import("raylib");

const Cloud = @import("Cloud.zig");
const texture_assets = @import("texture_assets.zig");
const time = @import("time.zig");

const BackgroundSystem = @This();
const max_clouds = 100;
const min_clouds = 10;

rand: *std.Random,
wind_speed: f32 = 0.0,
wind_speed_speed: f32 = 0.0,
clouds: std.BoundedArray(Cloud, max_clouds),
target_num_clouds: u32 = max_clouds,
should_reset_clouds: bool = true,

pub fn init(rand: *std.Random) !BackgroundSystem {
    const background_system = BackgroundSystem{
        .rand = rand,
        .clouds = std.BoundedArray(Cloud, max_clouds){},
    };

    return background_system;
}

pub fn tick(self: *BackgroundSystem) void {
    // If the number of clouds is too low, add more
    if (self.clouds.len < self.target_num_clouds) {
        self.addCloud();
    }

    // Vary the target number of clouds a bit
    self.target_num_clouds = @intCast(std.math.clamp(
        @as(i32, @intCast(self.target_num_clouds)) + self.rand.intRangeAtMost(i32, -1, 1),
        0,
        max_clouds,
    ));
}

pub fn renderUpdate(self: *BackgroundSystem) void {
    // Reset clouds if needed
    if (self.should_reset_clouds) {
        self.resetClouds();
        self.should_reset_clouds = false;
    }

    // Update clouds
    self.updateClouds();

    // Sort clouds by scale
    self.sortClouds();

    // Vary the wind speed a bit
    self.wind_speed_speed += @as(f32, @floatFromInt(
        self.rand.intRangeAtMost(i32, -10, 10),
    )) * 0.0001 * time.delta_time_in_ticks;
    self.wind_speed_speed = std.math.clamp(self.wind_speed_speed, -0.002, 0.002);
    self.wind_speed += self.wind_speed_speed * time.delta_time_in_ticks;
    self.wind_speed = std.math.clamp(self.wind_speed, -0.3, 0.3);
}

pub fn draw(self: *BackgroundSystem) void {
    // Draw background gradient
    const sky_blue_top = rl.Color{ .r = 25, .g = 101, .b = 255, .a = 255 };
    const sky_blue_bottom = rl.Color{ .r = 132, .g = 170, .b = 248, .a = 255 };
    rl.drawRectangleGradientV(
        0,
        0,
        rl.getScreenWidth(),
        rl.getScreenHeight(),
        sky_blue_top,
        sky_blue_bottom,
    );

    // Draw clouds
    for (self.clouds.slice()) |*cloud| {
        cloud.draw();
    }
}

fn resetClouds(self: *BackgroundSystem) void {
    // Choose a random number of clouds to spawn
    self.target_num_clouds = self.rand.intRangeAtMost(u32, min_clouds, max_clouds);

    // Randomize wind speed
    self.wind_speed = 0.0;
    while (self.wind_speed == 0.0) {
        self.wind_speed = @as(f32, @floatFromInt(self.rand.intRangeAtMost(i32, -100, 100))) * 0.01;
    }

    // Create new clouds, clearing the old ones first
    self.clouds.clear();
    for (0..self.target_num_clouds) |_| {
        self.addCloud();
    }

    // Move the clouds onto the screen
    const wind_speed_direction = std.math.sign(self.wind_speed);
    for (self.clouds.slice()) |*cloud| {
        cloud.position.x += @as(f32, @floatFromInt(rl.getScreenWidth() * 2)) * wind_speed_direction;
    }

    //std.debug.print("There are {d} clouds after reset\n", .{self.clouds.len});
}

fn addCloud(self: *BackgroundSystem) void {
    self.clouds.ensureUnusedCapacity(1) catch {
        std.debug.print("Failed to add new cloud, capacity reached!\n", .{});
        return;
    };

    var cloud = Cloud{};
    const @"type" = self.rand.uintLessThan(u32, 4);
    const texture = texture_assets.cloud[@"type"];
    cloud.rotation_speed = 0.0;
    cloud.scale_speed = 0.0;
    cloud.type = @"type";
    cloud.scale = @as(f32, @floatFromInt(self.rand.intRangeLessThan(i32, 8, 13))) * 0.1;
    cloud.rotation = @as(f32, @floatFromInt(self.rand.intRangeLessThan(i32, -10, 11))) * 0.01;
    cloud.width = @intFromFloat(@as(f32, @floatFromInt(texture.width)) * cloud.scale);
    cloud.height = @intFromFloat(@as(f32, @floatFromInt(texture.height)) * cloud.scale);
    if (self.wind_speed > 0.0) {
        cloud.position.x = @as(f32, @floatFromInt(-cloud.width - texture.width - self.rand.intRangeLessThan(i32, 0, rl.getScreenWidth() * 2)));
    } else {
        cloud.position.x = @as(f32, @floatFromInt(rl.getScreenWidth() + texture.width + self.rand.intRangeLessThan(i32, 0, rl.getScreenWidth() * 2)));
    }
    cloud.position.y = @as(f32, @floatFromInt(
        self.rand.intRangeLessThan(
            i32,
            @intFromFloat(@as(f32, @floatFromInt(-rl.getScreenHeight())) * 0.25),
            @intFromFloat(@as(f32, @floatFromInt(rl.getScreenHeight())) * 1.25),
        ),
    ));
    for (0..2) |_| {
        cloud.position.y = cloud.position.y - @as(f32, @floatFromInt(
            self.rand.uintLessThan(
                u32,
                @intFromFloat(@as(f32, @floatFromInt(rl.getScreenHeight())) * 0.25),
            ),
        ));
    }
    cloud.scale *= 2.2 - ((cloud.position.y + @as(f32, @floatFromInt(rl.getScreenHeight())) * 0.25) / (@as(f32, @floatFromInt(rl.getScreenHeight())) * 1.5) + 0.7);
    cloud.scale = std.math.clamp(cloud.scale, 0.6, 1.4);

    // Don't add clouds that overlap another cloud
    const rect = rl.Rectangle{
        .x = cloud.position.x,
        .y = cloud.position.y,
        .width = @floatFromInt(cloud.width),
        .height = @floatFromInt(cloud.height),
    };
    for (self.clouds.slice()) |other| {
        const other_rect = rl.Rectangle{
            .x = other.position.x,
            .y = other.position.y,
            .width = @floatFromInt(other.width),
            .height = @floatFromInt(other.height),
        };
        if (rl.checkCollisionRecs(rect, other_rect)) {
            //std.debug.print("Cloud at index {d} overlaps with cloud at index {d}\n", .{ next_free_index, i });
            return;
        }
    }

    //std.debug.print("Adding new cloud {}\n", .{cloud});
    self.clouds.appendAssumeCapacity(cloud);
}

fn updateClouds(self: *BackgroundSystem) void {
    const clouds = self.clouds.slice();
    var i = self.clouds.len;
    while (i > 0) {
        i -= 1;
        const cloud = &clouds[i];
        if (!self.updateOneCloud(cloud)) {
            _ = self.clouds.swapRemove(i);
        }
    }
}

fn updateOneCloud(self: *BackgroundSystem, cloud: *Cloud) bool {
    const texture = texture_assets.cloud[cloud.type];
    const texture_width = @as(f32, @floatFromInt(texture.width));

    // Update cloud position
    cloud.position.x += self.wind_speed * cloud.scale * 3.0 * time.delta_time_in_ticks;

    // Check if cloud is out of bounds and should be removed
    const screen_width = @as(f32, @floatFromInt(rl.getScreenWidth()));
    if (self.wind_speed > 0.0) {
        if (cloud.position.x - texture_width > screen_width) {
            return false;
        }
    } else {
        const current_width = @as(f32, @floatFromInt(cloud.width));
        if (cloud.position.x + current_width + texture_width < 0.0) {
            return false;
        }
    }

    // Update rotation and scale speeds with random variation
    cloud.rotation_speed += @as(f32, @floatFromInt(
        self.rand.intRangeAtMost(i32, -10, 10),
    )) * 0.00002 * time.delta_time_in_ticks;
    cloud.rotation_speed = std.math.clamp(cloud.rotation_speed, -0.0007, 0.0007);

    cloud.scale_speed += @as(f32, @floatFromInt(
        self.rand.intRangeAtMost(i32, -10, 10),
    )) * 0.00002 * time.delta_time_in_ticks;
    cloud.scale_speed = std.math.clamp(cloud.scale_speed, -0.0007, 0.0007);

    // Apply rotation and scale changes
    cloud.rotation += cloud.rotation_speed * time.delta_time_in_ticks;
    cloud.scale += cloud.scale_speed * time.delta_time_in_ticks;

    // Clamp rotation and scale values
    cloud.rotation = std.math.clamp(cloud.rotation, -0.05, 0.05);
    cloud.scale = std.math.clamp(cloud.scale, 0.6, 1.4);

    // Update cloud dimensions based on scale
    cloud.width = @intFromFloat(@as(f32, @floatFromInt(texture.width)) * cloud.scale);
    cloud.height = @intFromFloat(@as(f32, @floatFromInt(texture.height)) * cloud.scale);

    return true;
}

/// Sorts clouds by their scale in ascending order.
fn sortClouds(self: *BackgroundSystem) void {
    std.sort.block(Cloud, self.clouds.slice(), {}, struct {
        fn sort(_: void, a: Cloud, b: Cloud) bool {
            return a.scale < b.scale - 0.02;
        }
    }.sort);
}
