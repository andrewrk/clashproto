const std = @import("std");
const builtin = std.builtin;
const Builder = std.build.Builder;
const path = std.fs.path;
const sep_str = path.sep_str;
const Target = std.build.Target;

pub fn build(b: *Builder) void {
    std.debug.warn("Building libsoundio with zig is not yet supported");
    std.process.exit(1);
}

pub const Options = struct {
    artifact: *std.build.LibExeObjStep,
    prefix: []const u8,
    override_mode: ?std.builtin.Mode = null,
};

pub fn linkArtifact(b: *Builder, options: Options) void {
    const mode = options.override_mode orelse options.artifact.build_mode;
    const lib = getLibrary(b, mode, options.artifact.target, options.prefix);
    options.artifact.addIncludeDir(options.prefix);
    options.artifact.linkLibrary(lib);
}

pub fn getLibrary(
    b: *Builder,
    mode: builtin.Mode,
    target: std.build.Target,
    prefix: []const u8,
) *std.build.LibExeObjStep {
    const lib_cflags = &[_][]const u8{
        "-std=c11",
        "-fvisibility=hidden",
        "-D_REENTRANT",
        "-D_POSIX_C_SOURCE=200809L",
    };
    const lib = b.addStaticLibrary("soundio", null);
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.linkSystemLibrary("c");
    lib.addIncludeDir(prefix);
    for (generic_src_files) |src_file| {
        const full_src_path = path.join(b.allocator, &[_][]const u8{ prefix, "src", src_file }) catch unreachable;
        lib.addCSourceFile(full_src_path, lib_cflags);
    }
    if (target.isWindows()) {
        lib.defineCMacro("SOUNDIO_HAVE_WASAPI=1");
        for (windows_src_files) |src_file| {
            const full_src_path = path.join(b.allocator, &[_][]const u8{ prefix, "src", src_file }) catch unreachable;
            lib.addCSourceFile(full_src_path, lib_cflags);
        }
    }
    return lib;
}

const generic_src_files = [_][]const u8{
    "channel_layout.c",
    "dummy.c",
    "os.c",
    "ring_buffer.c",
    "soundio.c",
    "util.c",
};

const windows_src_files = [_][]const u8{
    "wasapi.c",
};

// "coreaudio.c",
// "jack.c",
// "pulseaudio.c",
// "alsa.c",

//#cmakedefine SOUNDIO_HAVE_JACK
//#cmakedefine SOUNDIO_HAVE_PULSEAUDIO
//#cmakedefine SOUNDIO_HAVE_ALSA
//#cmakedefine SOUNDIO_HAVE_COREAUDIO
//
