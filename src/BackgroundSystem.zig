const std = @import("std");

const rl = @import("raylib");

const Cloud = @import("Cloud.zig");
const texture_assets = @import("texture_assets.zig");

const BackgroundSystem = @This();
const max_clouds = 100;
const min_clouds = 10;

rand: *std.Random,
wind_speed: f32 = 0.0,
clouds: std.BoundedArray(Cloud, max_clouds),
should_reset_clouds: bool = true,

pub fn init(rand: *std.Random) !BackgroundSystem {
    const background_system = BackgroundSystem{
        .rand = rand,
        .clouds = std.BoundedArray(Cloud, max_clouds){},
    };

    return background_system;
}

pub fn update(self: *BackgroundSystem) void {
    if (self.should_reset_clouds) {
        self.resetClouds();
        self.should_reset_clouds = false;
    }
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
    const num_clouds = self.rand.intRangeAtMost(u32, min_clouds, max_clouds);

    // Randomize wind speed
    self.wind_speed = 0.0;
    while (self.wind_speed == 0.0) {
        self.wind_speed = @as(f32, @floatFromInt(self.rand.intRangeAtMost(i32, -100, 100))) * 0.01;
    }

    // Create new clouds, clearing the old ones first
    self.clouds.clear();
    for (0..num_clouds) |_| {
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
