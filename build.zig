const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("clashproto", "src/main.zig");
    exe.addCSourceFile("deps/stb_image.c", &[_][]const u8{"-std=c99"});
    exe.addIncludeDir("deps");
    exe.setBuildMode(mode);
    exe.setTarget(target);

    if (target.getOsTag() == .windows and target.getAbi() == .gnu) {
        @import("deps/zig-sdl/build.zig").linkArtifact(b, .{
            .artifact = exe,
            .prefix = "deps/zig-sdl",
            .override_mode = .ReleaseFast,
        });
    } else {
        exe.linkSystemLibrary("SDL2");
    }

    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
