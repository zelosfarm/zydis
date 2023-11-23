const std = @import("std");
const builtin = @import("builtin");

const ArrayList = std.ArrayList;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zydis = b.addStaticLibrary(.{
        .name = "zydis",
        .target = target,
        .optimize = optimize,
    });
    zydis.want_lto = false;
    zydis.disable_sanitize_c = true;
    if (optimize == .Debug or optimize == .ReleaseSafe)
        zydis.bundle_compiler_rt = true
    else
        zydis.strip = true;
    zydis.linkLibC();
    zydis.linkLibrary(b.dependency("zycore", .{
        .target = target,
        .optimize = optimize,
    }).artifact("zycore"));

    if (target.isWindows()) {
        zydis.linkSystemLibrary("ntdll");
        zydis.linkSystemLibrary("kernel32");
        zydis.linkSystemLibrary("advapi32");
    }

    zydis.addIncludePath(.{ .path = "include" });
    zydis.addIncludePath(.{ .path = "src" });
    var zydis_flags = ArrayList([]const u8).init(b.allocator);
    var zydis_sources = ArrayList([]const u8).init(b.allocator);
    defer zydis_flags.deinit();
    defer zydis_sources.deinit();

    zydis_flags.append("-DZYDIS_STATIC_BUILD=1") catch @panic("OOM");
    zydis_sources.append("src/MetaInfo.c") catch @panic("OOM");
    zydis_sources.append("src/Mnemonic.c") catch @panic("OOM");
    zydis_sources.append("src/Register.c") catch @panic("OOM");
    zydis_sources.append("src/SharedData.c") catch @panic("OOM");
    zydis_sources.append("src/String.c") catch @panic("OOM");
    zydis_sources.append("src/Utils.c") catch @panic("OOM");
    zydis_sources.append("src/Zydis.c") catch @panic("OOM");
    zydis_sources.append("src/Decoder.c") catch @panic("OOM");
    zydis_sources.append("src/DecoderData.c") catch @panic("OOM");
    zydis_sources.append("src/Encoder.c") catch @panic("OOM");
    zydis_sources.append("src/EncoderData.c") catch @panic("OOM");
    zydis_sources.append("src/Formatter.c") catch @panic("OOM");
    zydis_sources.append("src/FormatterBuffer.c") catch @panic("OOM");
    zydis_sources.append("src/FormatterATT.c") catch @panic("OOM");
    zydis_sources.append("src/FormatterBase.c") catch @panic("OOM");
    zydis_sources.append("src/FormatterIntel.c") catch @panic("OOM");
    zydis.addCSourceFiles(.{ .files = zydis_sources.items, .flags = zydis_flags.items });

    zydis.installHeadersDirectory("include/Zydis", "Zydis");

    b.installArtifact(zydis);
}
