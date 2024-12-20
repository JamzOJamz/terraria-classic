const std = @import("std");

const rlz = @import("raylib-zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add a dependency on the raylib-zig package
    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    // Add a dependency on the zig-ecs package
    const ecs_dep = b.dependency("zig-ecs", .{ .target = target, .optimize = optimize });
    const ecs = ecs_dep.module("zig-ecs");

    // Web exports
    if (target.query.os_tag == .emscripten) {
        const exe_lib = try rlz.emcc.compileForEmscripten(b, "terraria-classic", "src/main.zig", target, optimize);

        exe_lib.linkLibrary(raylib_artifact);
        exe_lib.root_module.addImport("raylib", raylib);
        exe_lib.root_module.addImport("ecs", ecs);

        // Note that raylib itself is not actually added to the exe_lib output file, so it also needs to be linked with emscripten.
        const link_step = try rlz.emcc.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{ exe_lib, raylib_artifact });
        //this lets your program access files like "resources/my-image.png":
        //link_step.addArg("-sINITIAL_HEAP=0KB");
        //link_step.addArg("-sINITIAL_MEMORY=512MB");
        link_step.addArg("--embed-file");
        link_step.addArg("resources/");
        //custom html template (shell) for the web build
        link_step.addArg("--shell-file");
        link_step.addArg("shell.html");

        b.getInstallStep().dependOn(&link_step.step);
        const run_step = try rlz.emcc.emscriptenRunStep(b);
        run_step.step.dependOn(&link_step.step);
        const run_option = b.step("run-emscripten", "Run terraria-classic in a web browser");
        run_option.dependOn(&run_step.step);
        return;
    }

    const exe = b.addExecutable(.{
        .name = "terraria-classic",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        //.strip = true,
    });
    exe.rdynamic = true;

    //const raygui = raylib_dep.module("raygui"); // raygui module
    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    //exe.root_module.addImport("raygui", raygui);

    exe.root_module.addImport("ecs", ecs);

    if (target.result.os.tag == .windows) {
        const win32api = b.addModule("zigwin32", .{
            .root_source_file = b.path("libs/zigwin32/win32.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("win32", win32api);
    }

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
