const std = @import("std");
const g = @import("../globals.zig");

///Looks for the specified program in relation to the current working directory
pub fn loadRomAlloc(path: []const u8, alloc: std.mem.Allocator) []u8 {
    const cwd = std.fs.cwd();

    const file = cwd.openFile(path, .{}) catch {
        g.error_msg = "Error: File doesn't exist";
        return &g.blank_screen_program; // Returns a program that just creates a blank screen in case of error
    };
    defer file.close();

    const ret = file.readToEndAlloc(alloc, 0x1000) catch {
        g.error_msg = "Error: File is too big to fit in chip8 memory";
        return &g.blank_screen_program; // Returns a program that just creates a blank screen in case of error
    };
    return ret;
}

///Looks for the specified program in relation to the current working directory
pub fn loadRom(path: []const u8, buf: []u8) void {
    const cwd = std.fs.cwd();

    const file = cwd.openFile(path, .{}) catch {
        g.error_msg = "Error: File doesn't exist";
        std.mem.copyForwards(u8, buf[0..], &g.blank_screen_program); // Returns a program that just creates a blank screen in case of error
        return;
    };
    defer file.close();

    const file_len = file.readAll(buf) catch {
        g.error_msg = "Error: Couldn't read file";
        std.mem.copyForwards(u8, buf[0..], &g.blank_screen_program); // Returns a program that just creates a blank screen in case of error
        return;
    };

    if (file_len > buf.len) {
        g.error_msg = "Error: File is too big to fit in chip8 4kB memory";
        std.mem.copyForwards(u8, buf[0..], &g.blank_screen_program); // Returns a program that just creates a blank screen in case of error
        return;
    }
}
