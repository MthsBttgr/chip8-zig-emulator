const std = @import("std");
const g = @import("../globals.zig");

pub const Registers = struct {
    V0: u8 = 0,
    V1: u8 = 0,
    V2: u8 = 0,
    V3: u8 = 0,
    V4: u8 = 0,
    V5: u8 = 0,
    V6: u8 = 0,
    V7: u8 = 0,
    V8: u8 = 0,
    V9: u8 = 0,
    VA: u8 = 0,
    VB: u8 = 0,
    VC: u8 = 0,
    VD: u8 = 0,
    VE: u8 = 0,
    VF: u8 = 0,

    ///Sets all registers to 0
    pub fn reset(self: *Registers) void {
        self.* = Registers{};
    }

    pub fn get(self: *const Registers, nr: u16) u8 {
        return switch (nr) {
            0 => self.V0,
            1 => self.V1,
            2 => self.V2,
            3 => self.V3,
            4 => self.V4,
            5 => self.V5,
            6 => self.V6,
            7 => self.V7,
            8 => self.V8,
            9 => self.V9,
            10 => self.VA,
            11 => self.VB,
            12 => self.VC,
            13 => self.VD,
            14 => self.VE,
            15 => self.VF,
            else => {
                g.error_msg = "Read of non-existing register";
                g.paused = true;
                return 0xAA; //Returns a 01010... pattern
            },
        };
    }

    pub fn set(self: *Registers, nr: u16, value: u8) void {
        return switch (nr) {
            0 => self.V0 = value,
            1 => self.V1 = value,
            2 => self.V2 = value,
            3 => self.V3 = value,
            4 => self.V4 = value,
            5 => self.V5 = value,
            6 => self.V6 = value,
            7 => self.V7 = value,
            8 => self.V8 = value,
            9 => self.V9 = value,
            10 => self.VA = value,
            11 => self.VB = value,
            12 => self.VC = value,
            13 => self.VD = value,
            14 => self.VE = value,
            15 => self.VF = value,
            else => {
                g.error_msg = "Access of non-existing register";
                g.paused = true;
            },
        };
    }

    ///Returns an array with the string with null bytes at the end
    pub fn get_nullterminated_string(self: *const Registers, nr: u16) [20]u8 {
        var buf: [20]u8 = [_]u8{0} ** 20;

        _ = std.fmt.bufPrint(&buf, "V{X} = 0x{X:0>2}", .{ nr, self.get(nr) }) catch unreachable; // 20 bytes is more than enough for this string

        return buf;
    }
};
