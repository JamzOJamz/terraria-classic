const std = @import("std");

const rl = @import("raylib");

const audio_engine = @import("audio_engine.zig");
const Behaviour = @import("Behaviour.zig");
const GameObject = @import("GameObject.zig");
const Scene = @import("Scene.zig");
const Sprite = @import("Sprite.zig");
const texture_assets = @import("texture_assets.zig");
const time = @import("time.zig");
const Transform = @import("Transform.zig");

const MenuLogoBehaviour = @This();

// Constants
// --------------------------------------------------
const logo_rotation_dampener = 0.00003;
const logo_scale_dampener = 0.00001;
// --------------------------------------------------

// Fields
// --------------------------------------------------
logo_transform: ?*Transform = null,
logo_sprite: ?*Sprite = null,
logo_texture_index: usize = 0,
logo_rotation_speed: f32 = 1.0,
logo_rotation_direction: f32 = 1.0,
logo_scale_speed: f32 = 0.0,
logo_scale_direction: f32 = 1.0,
// --------------------------------------------------

pub fn start(self: *MenuLogoBehaviour, scene: *Scene, object: *GameObject) void {
    _ = scene; // autofix
    self.logo_transform = object.getComponent(.transform);
    self.logo_sprite = object.getComponent(.sprite);
}

fn update(self: *MenuLogoBehaviour, object: *GameObject) void {
    _ = object; // autofix
    if (self.logo_transform) |transform| {
        const delta_time = time.getDeltaTimeInTicks();

        // Rotate logo
        transform.rotation += self.logo_rotation_speed * logo_rotation_dampener * delta_time;

        // Clamp logo rotation
        if (transform.rotation > 0.1) {
            self.logo_rotation_direction = -1.0;
        } else if (transform.rotation < -0.1) {
            self.logo_rotation_direction = 1.0;
        }

        // Adjust logo rotation speed
        if (self.logo_rotation_speed < 20.0 and self.logo_rotation_direction == 1.0) {
            self.logo_rotation_speed += 1.0 * delta_time;
        } else if (self.logo_rotation_speed > -20.0 and self.logo_rotation_direction == -1.0) {
            self.logo_rotation_speed -= 1.0 * delta_time;
        }

        // Clamp logo rotation speed
        self.logo_rotation_speed = std.math.clamp(self.logo_rotation_speed, -20.0, 20.0);

        // Scale logo
        transform.scale += self.logo_scale_speed * logo_scale_dampener * delta_time;

        // Clamp logo scale
        if (transform.scale > 1.1) {
            self.logo_scale_direction = -1.0;
        } else if (transform.scale < 0.9) {
            self.logo_scale_direction = 1.0;
        }

        // Adjust logo scale speed
        if (self.logo_scale_speed < 50.0 and self.logo_scale_direction == 1.0) {
            self.logo_scale_speed += 1.0 * delta_time;
        } else if (self.logo_scale_speed > -50.0 and self.logo_scale_direction == -1.0) {
            self.logo_scale_speed -= 1.0 * delta_time;
        }

        // Clamp logo scale speed
        self.logo_scale_speed = std.math.clamp(self.logo_scale_speed, -50.0, 50.0);

        // Debug log the transform values
        //std.debug.print("Rotation: {}, Scale: {}\n", .{ transform.rotation, transform.scale });

        // Check if space is pressed
        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            if (self.logo_sprite) |sprite| {
                // Change logo texture, cycling through all of them
                self.logo_texture_index += 1;
                if (self.logo_texture_index == texture_assets.logo.len) {
                    self.logo_texture_index = 0;
                }
                sprite.texture = texture_assets.logo[self.logo_texture_index];
                audio_engine.playSound("menu_tick");
            }
        }
    }
}

const vtable: Behaviour.VTable = .{
    .start = @ptrCast(&start),
    .renderUpdate = @ptrCast(&update),
    .deinit = Behaviour.makeDestructor(MenuLogoBehaviour),
};

pub fn behaviour(self: *MenuLogoBehaviour) Behaviour {
    return .{
        .ptr = self,
        .kind = Behaviour.id(MenuLogoBehaviour),
        .vtable = &vtable,
    };
}
