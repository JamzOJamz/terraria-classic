//! Provides cross-platform abstractions, helper functions, and common
//! development tools to simplify repetitive tasks and ensure consistent
//! behavior across different environments. Contains platform-aware
//! implementations where necessary to handle OS-specific differences
//! transparently.

const std = @import("std");
const builtin = @import("builtin");

const rl = @import("raylib");
const win32 = @import("win32");

/// Returns mouse position relative to window client area
/// - Windows: Continuously tracks via Win32 (works outside window, adjusts for decorations)
/// - Others: Uses Raylib's default (only updates within window bounds)
pub fn getMousePosition() rl.Vector2 {
    if (builtin.target.os.tag == .windows) {
        var point = win32.foundation.POINT{ .x = 0, .y = 0 };
        _ = win32.ui.windows_and_messaging.GetCursorPos(&point);
        const window_pos = rl.getWindowPosition();
        point.x -= @intFromFloat(window_pos.x);
        point.y -= @intFromFloat(window_pos.y);
        const cursor_pos = rl.Vector2{
            .x = @floatFromInt(point.x),
            .y = @floatFromInt(point.y),
        };
        return cursor_pos;
    } else {
        return rl.getMousePosition();
    }
}
