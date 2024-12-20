const std = @import("std");

const Behaviour = @import("Behaviour.zig");
const Scene = @import("Scene.zig");
const Sprite = @import("Sprite.zig");
const Text = @import("Text.zig");
const Transform = @import("Transform.zig");

pub const ComponentType = enum {
    transform,
    sprite,
    text,
    behaviour,
};

pub const Component = union(ComponentType) {
    transform: Transform,
    sprite: Sprite,
    text: Text,
    behaviour: Behaviour,

    pub fn start(self: Component, scene: *Scene, object: *GameObject) void {
        switch (self) {
            .behaviour => |behaviour| return behaviour.start(scene, object),
            else => {},
        }
    }

    pub fn fixedUpdate(self: Component, object: *GameObject) void {
        switch (self) {
            .behaviour => |behaviour| return behaviour.fixedUpdate(object),
            else => {},
        }
    }

    pub fn renderUpdate(self: Component, object: *GameObject) void {
        switch (self) {
            .behaviour => |behaviour| return behaviour.renderUpdate(object),
            else => {},
        }
    }

    pub fn draw(self: Component, object: *GameObject) void {
        switch (self) {
            .behaviour => |behaviour| return behaviour.draw(object),
            else => {},
        }
    }
};

const GameObject = @This();

components: std.ArrayList(Component),

pub fn init(allocator: std.mem.Allocator) GameObject {
    return .{
        .components = .init(allocator),
    };
}

pub fn create(allocator: std.mem.Allocator) !*GameObject {
    const go = try allocator.create(GameObject);
    go.* = GameObject.init(allocator);
    return go;
}

pub fn deinit(self: GameObject, allocator: std.mem.Allocator) void {
    for (self.components.items) |component| {
        switch (component) {
            .behaviour => |behaviour| behaviour.deinit(allocator),
            else => {},
        }
    }
    self.components.deinit();
}

pub fn start(self: *GameObject, scene: *Scene) void {
    for (self.components.items) |component| {
        component.start(scene, self);
    }
}

pub fn addComponent(self: *GameObject, component: Component) !void {
    try self.components.append(component);
}

pub fn getComponent(self: *GameObject, comptime kind: ComponentType) ?*@FieldType(Component, @tagName(kind)) {
    for (self.components.items) |*component| {
        switch (component.*) {
            kind => |*active| return active,
            else => {},
        }
    }
    return null;
}

pub fn getBehaviour(self: *GameObject, comptime T: type) ?*T {
    for (self.components.items) |*component| {
        switch (component.*) {
            .behaviour => |behaviour| {
                if (behaviour.kind == Behaviour.id(T)) {
                    return @ptrCast(@alignCast(behaviour.ptr));
                }
            },
            else => {},
        }
    }
    return null;
}

pub fn fixedUpdate(self: *GameObject) void {
    for (self.components.items) |component| {
        component.fixedUpdate(self);
    }
}

pub fn renderUpdate(self: *GameObject) void {
    for (self.components.items) |component| {
        component.renderUpdate(self);
    }
}

pub fn draw(self: *GameObject) void {
    for (self.components.items) |component| {
        component.draw(self);
    }
}
