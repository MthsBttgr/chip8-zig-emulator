const std = @import("std");
const g = @import("../globals.zig");

///Looks for the specified program in relation to the current working directory
pub fn loadRom(path: []const u8, alloc: std.mem.Allocator) []u8 {
    const cwd = std.fs.cwd();

    const file = cwd.openFile(path, .{}) catch {
        g.error_msg = "Error: File doesn't exist";
        return errReturn(alloc);
    };
    defer file.close();

    const ret = file.readToEndAlloc(alloc, 4096) catch {
        g.error_msg = "Error: File is too big to fit in chip8 memory";
        return errReturn(alloc);
    };
    return ret;
}

///Should loading the program fail, then a failsafe program is loaded, that just displays a blank screen
fn errReturn(alloc: std.mem.Allocator) []u8 {
    var bytes = alloc.alloc(u8, 4) catch std.debug.panic("idk man even allocation has stopped working at this point", .{});
    bytes[0] = 0;
    bytes[1] = 0xE0; // Instruction to clear screen - 0x00E0
    bytes[2] = 0x12;
    bytes[3] = 0x00; // Instruction to jump too addr 0x0200, the program start addr, results in infinite loop

    return bytes;
}
