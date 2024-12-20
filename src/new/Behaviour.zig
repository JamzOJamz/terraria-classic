const std = @import("std");

const GameObject = @import("GameObject.zig");
const Scene = @import("Scene.zig");

const Behaviour = @This();

ptr: *anyopaque,
vtable: *const VTable,
kind: Id,

pub const VTable = struct {
    start: ?*const fn (ptr: *anyopaque, scene: *Scene, object: *GameObject) void = null,
    fixedUpdate: ?*const fn (ptr: *anyopaque, object: *GameObject) void = null,
    renderUpdate: ?*const fn (ptr: *anyopaque, object: *GameObject) void = null,
    draw: ?*const fn (ptr: *anyopaque, object: *GameObject) void = null,
    deinit: ?*const fn (ptr: *anyopaque, allocator: std.mem.Allocator) void = null,
};

pub const Id = *const struct {
    _: u8,
};

pub inline fn id(comptime T: type) Id {
    return &struct {
        comptime {
            _ = T;
        }
        var id: @typeInfo(Id).pointer.child = undefined;
    }.id;
}

pub fn makeDestructor(comptime T: type) *const fn (*anyopaque, std.mem.Allocator) void {
    const Generated = struct {
        fn destructor(target: *T, a: std.mem.Allocator) void {
            if (comptime @hasDecl(T, "deinit")) {
                target.deinit(a);
            }
            a.destroy(target);
        }
    };
    return @ptrCast(&Generated.destructor);
}

pub fn start(self: Behaviour, scene: *Scene, object: *GameObject) void {
    if (self.vtable.start) |f| {
        f(self.ptr, scene, object);
    }
}

pub fn fixedUpdate(self: Behaviour, object: *GameObject) void {
    if (self.vtable.fixedUpdate) |f| {
        f(self.ptr, object);
    }
}

pub fn renderUpdate(self: Behaviour, object: *GameObject) void {
    if (self.vtable.renderUpdate) |f| {
        f(self.ptr, object);
    }
}

pub fn draw(self: Behaviour, object: *GameObject) void {
    if (self.vtable.draw) |f| {
        f(self.ptr, object);
    }
}

pub fn deinit(self: Behaviour, allocator: std.mem.Allocator) void {
    if (self.vtable.deinit) |f| {
        f(self.ptr, allocator);
    }
}
