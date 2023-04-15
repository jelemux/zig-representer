const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Main build step
    const exe = b.addExecutable("zig-representer", "src/main.zig");
    exe.install();

    // Build step to run application
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Build step to run tests
    const exe_tests = b.addTest("src/main.zig");
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

    // Build step to generate docs:
    const docs = b.addTest("src/main.zig");
    docs.emit_docs = .emit;

    const docs_step = b.step("docs", "Generate docs");
    docs_step.dependOn(&docs.step);

    const steps_with_dependencies = &[_]*LibExeObjStep{ exe, exe_tests, docs };
    configureSteps(steps_with_dependencies, target, mode);
}

fn configureSteps(steps: []*LibExeObjStep, target: CrossTarget, mode: Mode) void {
    for (steps) |step| {
        step.setTarget(target);
        step.setBuildMode(mode);
        step.addPackagePath("yazap", "libs/yazap/src/lib.zig");
    }
}
