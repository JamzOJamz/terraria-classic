const std = @import("std");

const GameObject = @import("GameObject.zig");

const Scene = @This();

objects: std.ArrayList(*GameObject),
_allocator: std.mem.Allocator,

pub fn init(ally: std.mem.Allocator) Scene {
    return .{
        .objects = .init(ally),
        ._allocator = ally,
    };
}

pub fn deinit(self: Scene) void {
    // Deinitialize all objects
    for (self.objects.items) |object| {
        object.deinit(self._allocator);
        self._allocator.destroy(object);
    }
    self.objects.deinit();
}

pub fn allocator(self: *Scene) std.mem.Allocator {
    return self._allocator;
}

pub fn addObject(self: *Scene, object: *GameObject) !void {
    object.start(self);
    try self.objects.append(object);
}

pub fn fixedUpdate(self: *Scene) void {
    for (self.objects.items) |object| {
        object.fixedUpdate();
    }
}

pub fn renderUpdate(self: *Scene) void {
    for (self.objects.items) |object| {
        object.renderUpdate();
    }
}
