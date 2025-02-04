const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add raylib-zig as a dependency
    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    // Import the raylib and raygui modules
    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module

    // Get the raylib C library artifact
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "terraria-classic",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        //.strip = true,
    });
    exe.rdynamic = true;

    // Link the raylib C library to the executable
    exe.linkLibrary(raylib_artifact);

    // Add the raylib and raygui modules to the executable's root module
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    // Include zigwin32 on Windows to access Win32 APIs
    if (target.result.os.tag == .windows) {
        const win32_dep = b.dependency("zigwin32", .{});
        exe.root_module.addImport("win32", win32_dep.module("win32"));
    }

    // Install the executable
    b.installArtifact(exe);

    // Add a run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Add unit tests for the library
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Add unit tests for the executable
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Add a test step
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
