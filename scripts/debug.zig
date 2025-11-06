//! Simple debugger wrapper
const std = @import("std");

const config = @import("config");

/// Execve into gdb
pub fn main() !void {
    const cmds = "target extended-remote | " ++ config.openocd_path ++
        " -f interface/stlink.cfg -f board/stm32f4discovery.cfg -c " ++
        "\"gdb_port pipe; init; program \"" ++ config.main_exe ++
        "\" preverify verify; reset halt;\"";
    return std.process.execv(std.heap.smp_allocator, &.{
        config.gdb_path,
        "-q",
        config.main_exe,
        "-ex",
        cmds,
    });
}
