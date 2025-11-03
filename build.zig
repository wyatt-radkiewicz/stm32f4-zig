const std = @import("std");
const arm = std.Target.arm;

const config = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    // Setup common configuration
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{ .explicit = arm.cpu.cortex_m4 },
        .cpu_features_add = .{ .ints = .{
            arm.Feature.dsp,
            arm.Feature.strict_align,
        } },
    });
    const optimize = b.standardOptimizeOption(.{});

    // Gather build steps
    const install_step = b.getInstallStep();
    const build_step = b.step("build", "Build the main elf executable file");
    const flash_step = b.step("flash", "Build, flash, and run the code on the stm32f4discovery");
    const fmt_step = b.step("fmt", "Check formatting");
    const clean_step = b.step("clean", "Cleanup cached files");

    // Create the main application module
    const main_mod = b.createModule(.{
        .root_source_file = b.path(b.pathJoin("src", "start.zig")),
        .target = target,
        .optimize = optimize,
    });

    // Create the main elf file
    const main_exe = b.addExecutable(.{
        .name = config.name,
        .root_module = main_mod,
        .version = std.SemanticVersion.parse(config.version) catch @panic("Bad semver format!"),
    });
    main_exe.setLinkerScript(b.path("linker.ld"));
    build_step.dependOn(&main_exe.step);
    install_step.dependOn(&b.addInstallArtifact(main_exe, .{}).step);

    // Flash code to the elf file
    const openocd_run = b.addSystemCommand(&.{
        "openocd",
        "-f",
        "interface/stlink.cfg",
        "-f",
        "board/stm32f4discovery.cfg",
        "-c",
        "init; reset halt",
        "-c",
    });
    openocd_run.addPrefixedArtifactArg("flash write_image ", main_exe);
    openocd_run.addArgs(&.{ "-c", "reset run; shutdown" });
    flash_step.dependOn(&openocd_run.step);

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
    clean_step.dependOn(&b.addRemoveDirTree(b.pathFromRoot(".zig-cache")).step);
}
