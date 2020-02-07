const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(null);
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("clashproto", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTheTarget(target);
    exe.linkSystemLibrary("SDL2");
    exe.addIncludeDir("/nix/store/jdlkdkp1wvkkmsndrs72rfymjxcasil0-SDL2-2.0.10-dev/include/SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
