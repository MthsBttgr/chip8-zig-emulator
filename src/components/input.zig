const std = @import("std");
const rl = @import("raylib");

///Tracks what keys are down
pub const KeyInput = packed struct(u16) {
    k0: bool = false,
    k1: bool = false,
    k2: bool = false,
    k3: bool = false,
    k4: bool = false,
    k5: bool = false,
    k6: bool = false,
    k7: bool = false,
    k8: bool = false,
    k9: bool = false,
    kA: bool = false,
    kB: bool = false,
    kC: bool = false,
    kD: bool = false,
    kE: bool = false,
    kF: bool = false,

    ///Sets all keyinput to false
    pub fn reset(self: *KeyInput) void {
        self.* = @bitCast(@as(u16, 0));
    }

    pub fn update(self: *KeyInput) void {
        self.reset();
        for (0..16) |i| {
            self.set(@truncate(i), rl.isKeyDown(map(@truncate(i))));
        }
    }

    pub fn set(self: *KeyInput, nr: u8, val: bool) void {
        switch (nr & 0x0F) {
            0 => self.k0 = val,
            1 => self.k1 = val,
            2 => self.k2 = val,
            3 => self.k3 = val,
            4 => self.k4 = val,
            5 => self.k5 = val,
            6 => self.k6 = val,
            7 => self.k7 = val,
            8 => self.k8 = val,
            9 => self.k9 = val,
            10 => self.kA = val,
            11 => self.kB = val,
            12 => self.kC = val,
            13 => self.kD = val,
            14 => self.kE = val,
            15 => self.kF = val,
            else => unreachable,
        }
    }
    pub fn get(self: *KeyInput, nr: u8) bool {
        return switch (nr & 0x0F) {
            0 => self.k0,
            1 => self.k1,
            2 => self.k2,
            3 => self.k3,
            4 => self.k4,
            5 => self.k5,
            6 => self.k6,
            7 => self.k7,
            8 => self.k8,
            9 => self.k9,
            10 => self.kA,
            11 => self.kB,
            12 => self.kC,
            13 => self.kD,
            14 => self.kE,
            15 => self.kF,
            else => unreachable,
        };
    }

    fn map(key: u8) rl.KeyboardKey {
        return switch (key) {
            0 => .x,
            1 => .one,
            2 => .two,
            3 => .three,
            4 => .q,
            5 => .w,
            6 => .e,
            7 => .a,
            8 => .s,
            9 => .d,
            0xA => .z,
            0xB => .c,
            0xC => .four,
            0xD => .r,
            0xE => .f,
            0xF => .v,
            else => unreachable,
        };
    }
};
