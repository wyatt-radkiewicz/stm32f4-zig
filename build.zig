const std = @import("std");
const arm = std.Target.arm;

const config = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    // Setup common configuration and build options
    const host = b.standardTargetOptions(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{ .explicit = &arm.cpu.cortex_m4 },
        .cpu_features_add = arm.featureSet(&.{ arm.Feature.dsp, arm.Feature.strict_align }),
    });
    const optimize = b.standardOptimizeOption(.{});
    const gdb_path = b.option([]const u8, "gdb", "Path to gdb for the debug step");
    const openocd_path = b.option(
        []const u8,
        "openocd",
        "Path to openocd for flashing code",
    ) orelse "openocd";

    // Gather build steps
    const install_step = b.getInstallStep();
    const run_step = b.step("run", "Run the code on the stm32f4discovery");
    const debug_step = b.step("debug", "Build and install the debugger");
    const fmt_step = b.step("fmt", "Check formatting");
    const clean_step = b.step("clean", "Cleanup cached files");

    // Create the main application module
    const main_mod = b.createModule(.{
        .root_source_file = b.path(b.pathJoin(&.{ "src", "start.zig" })),
        .target = target,
        .optimize = optimize,
    });

    // Create the main elf file
    const main_exe = b.addExecutable(.{
        .name = @tagName(config.name),
        .root_module = main_mod,
        .version = std.SemanticVersion.parse(config.version) catch @panic("Bad semver format!"),
    });
    main_exe.setLinkerScript(b.path(b.pathJoin(&.{ "scripts", "linker.ld" })));
    install_step.dependOn(&b.addInstallArtifact(main_exe, .{}).step);

    // Flash image to the device
    const openocd_run = b.addSystemCommand(&.{openocd_path});
    openocd_run.addArgs(&.{ "-f", "interface/stlink.cfg" });
    openocd_run.addArgs(&.{ "-f", "board/stm32f4discovery.cfg", "-c" });
    openocd_run.addPrefixedArtifactArg("set img_name ", main_exe);
    openocd_run.addArgs(&.{ "-c", "init; program \"$img_name\" preverify verify reset exit" });
    run_step.dependOn(&openocd_run.step);

    // Run the debugger
    if (gdb_path) |path| {
        // Create the debugger options
        const debug_cfg = b.addOptions();
        debug_cfg.addOption([]const u8, "openocd_path", openocd_path);
        debug_cfg.addOption([]const u8, "gdb_path", path);
        debug_cfg.addOptionPath("main_exe", main_exe.getEmittedBin());

        // Create the debugger module
        const debug_mod = b.createModule(.{
            .root_source_file = b.path(b.pathJoin(&.{ "scripts", "debug.zig" })),
            .optimize = .Debug,
            .target = host,
        });
        debug_mod.addOptions("config", debug_cfg);

        // Create the debugger executable
        const debug_exe = b.addExecutable(.{
            .name = "debug",
            .root_module = debug_mod,
        });

        // Install the debugger in the debug step
        debug_step.dependOn(&b.addInstallArtifact(debug_exe, .{}).step);
    } else {
        debug_step.dependOn(&b.addFail("Debug step requires -Dgdb option to be set").step);
    }

    // Format step
    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            "build.zig.zon",
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    install_step.dependOn(&fmt.step);

    // Cleanup step
    clean_step.dependOn(&b.addRemoveDirTree(b.path("zig-out")).step);
    clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);
}
