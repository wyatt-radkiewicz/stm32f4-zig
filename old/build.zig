const std = @import("std");
const arm = std.Target.arm;

const config = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    // Build target and optimize config
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{ .explicit = &arm.cpu.cortex_m4 },
        .cpu_features_add = arm.featureSet(&.{ arm.Feature.dsp, arm.Feature.strict_align }),
    });
    const optimize = b.standardOptimizeOption(.{});
    const unwind_tables = switch (optimize) {
        .ReleaseSmall, .ReleaseFast => std.builtin.UnwindTables.none,
        else => null,
    };

    // Build options
    const gdb_path = b.option([]const u8, "gdb", "Path to gdb for the debug step");
    const openocd_path = b.option(
        []const u8,
        "openocd",
        "Path to openocd for flashing code",
    ) orelse "openocd";
    const example = b.option([]const u8, "example", "Which example to build.");

    // Build steps
    const install_step = b.getInstallStep();
    const run_step = b.step("run", "Run the code on the stm32f4discovery");
    const debug_step = b.step("debug", "Build and install the debugger");
    const fmt_step = b.step("fmt", "Check formatting");
    const clean_step = b.step("clean", "Cleanup cached files");

    // Hardware abstraction module
    const hal_mod = b.createModule(.{
        .root_source_file = b.path(b.pathJoin(&.{ "hal", "root.zig" })),
        .target = target,
        .optimize = optimize,
        .unwind_tables = unwind_tables,
    });

    // Build every example
    const example_dir = std.fs.cwd().openDir("examples", .{ .iterate = true }) catch
        @panic("Expected example directory!");
    var example_iter = example_dir.iterate();
    while (example_iter.next() catch @panic("Problem iterating examples directory!")) |entry| {
        if (entry.kind != .file and !std.mem.eql(u8, ".zig", std.fs.path.extension(entry.name))) {
            continue;
        }

        // Example module
        const example_mod = b.createModule(.{
            .root_source_file = b.path(b.pathJoin(&.{ "examples", entry.name })),
            .target = target,
            .optimize = optimize,
            .unwind_tables = unwind_tables,
        });
        example_mod.addImport("hal", hal_mod);

        // Bootstrap code
        const bootstrap_mod = b.createModule(.{
            .root_source_file = b.path(b.pathJoin(&.{ "sys", "start.zig" })),
            .target = target,
            .optimize = optimize,
            .unwind_tables = unwind_tables,
        });
        bootstrap_mod.addImport("hal", hal_mod);
        bootstrap_mod.addImport("app", example_mod);

        // Elf executable
        const example_exe = b.addExecutable(.{
            .name = b.fmt("{s}-{s}", .{ @tagName(config.name), std.fs.path.stem(entry.name) }),
            .root_module = bootstrap_mod,
            .version = std.SemanticVersion.parse(config.version) catch @panic("Bad semver format!"),
        });
        example_exe.setLinkerScript(b.path(b.pathJoin(&.{ "sys", "linker.ld" })));

        // Install
        install_step.dependOn(&b.addInstallArtifact(example_exe, .{}).step);

        // If this isn't passed on the command line don't run it or debug it
        if (example) |name| {
            if (!std.mem.eql(u8, name, std.fs.path.stem(entry.name))) {
                continue;
            }
        } else {
            continue;
        }

        // Flash image to the device
        const openocd_run = b.addSystemCommand(&.{openocd_path});
        openocd_run.addArgs(&.{ "-f", "interface/stlink.cfg" });
        openocd_run.addArgs(&.{ "-f", "board/stm32f4discovery.cfg", "-c" });
        openocd_run.addPrefixedArtifactArg("set img_name ", example_exe);
        openocd_run.addArgs(&.{ "-c", "init; program \"$img_name\" preverify verify reset exit" });
        run_step.dependOn(&openocd_run.step);

        // Run the debugger
        if (gdb_path) |path| {
            // Run the debug script to make a little script that can be run to debug the elf file
            const debug_run = b.addSystemCommand(&.{
                "sh",
                b.pathJoin(&.{ "sys", "debug.sh" }),
                openocd_path,
                path,
            });
            debug_run.addArtifactArg(example_exe);
            const script = debug_run.addOutputFileArg("debug");

            // Install the script
            debug_step.dependOn(&b.addInstallFile(script, "debug").step);
        } else {
            debug_step.dependOn(&b.addFail("Debug step requires -Dgdb option to be set").step);
        }
    }

    // Fail on run or debug if an example to build isn't passed in
    if (example == null) {
        run_step.dependOn(&b.addFail("Pass example to run with -Dexample=<example name>").step);
        debug_step.dependOn(&b.addFail("Pass example to debug with -Dexample=<example name>").step);
    }

    // Format step
    const fmt = b.addFmt(.{
        .paths = &.{
            "examples/",
            "hal/",
            "sys/",
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
