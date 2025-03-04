const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const g = @import("../globals.zig");
const Emulator = @import("../emulator.zig");

const Filepicker = @This();

screen_area: rl.Rectangle,
current_file_path: FilePath,

show_filepicker: bool = false,

const padding: f32 = 4.0;
const line_height: f32 = 50;

var scroll = rl.Vector2{ .x = 0, .y = 0 };
var view_rect = rl.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 };

pub fn init(screen_area: rl.Rectangle, current_file: []const u8) Filepicker {
    var fp = Filepicker{
        .screen_area = screen_area,
        .current_file_path = FilePath.init(),
    };
    fp.current_file_path.setFile(current_file);
    return fp;
}

pub fn draw(self: *Filepicker, emulator: *Emulator) void {
    if (rg.guiButton(self.screen_area, self.current_file_path.getFileName()) > 0) {
        self.show_filepicker = !self.show_filepicker;
    }

    if (self.show_filepicker) {
        const window_rect = rl.Rectangle.init(100, 30, 500, 400);

        const sub_dir = if (std.mem.eql(u8, self.current_file_path.getDirPath(), &[_]u8{ '.', '/' })) false else true;

        const cwd = std.fs.cwd().openDir(self.current_file_path.getDirPath(), .{ .iterate = true }) catch {
            std.debug.print("Unable to open directory", .{});
            self.show_filepicker = false;
            return;
        };
        var iterator = cwd.iterate();

        // Get length of iterator
        var len: u16 = if (sub_dir) 1 else 0;
        while (iterator.next() catch {
            std.debug.print("Couldnt loop through elements in directory", .{});
            self.show_filepicker = false;
            return;
        }) |entry| {
            if (entry.kind != .file and entry.kind != .directory or entry.name.len < 3) continue;
            if (entry.kind == .file and !std.mem.eql(u8, entry.name[entry.name.len - 3 ..], "ch8")) continue;
            len += 1;
        }
        iterator.reset();

        // Using length to calculate height of the scroll panel
        const content_rect = rl.Rectangle.init(0, 0, window_rect.width - 15, @as(f32, @floatFromInt(len)) * (padding + line_height));

        var zeroterm_directory_path: [512]u8 = [_]u8{0} ** 512;
        std.mem.copyForwards(u8, &zeroterm_directory_path, self.current_file_path.getDirPath());
        _ = rg.guiScrollPanel(window_rect, @ptrCast(&zeroterm_directory_path), content_rect, &scroll, &view_rect);

        rl.beginScissorMode(@as(i32, @intFromFloat(view_rect.x)), @as(i32, @intFromFloat(view_rect.y)), @as(i32, @intFromFloat(view_rect.width)), @as(i32, @intFromFloat(view_rect.height)));
        var index: f32 = 0;

        // if we are in a subdir, add a button to go to parent dir
        if (sub_dir) {
            const button_rect = rl.Rectangle.init(view_rect.x + padding, view_rect.y + scroll.y + padding + (line_height + padding) * index, view_rect.width - 2 * padding, line_height);
            if (rg.guiButton(button_rect, "/..") > 0 and rl.checkCollisionPointRec(rl.getMousePosition(), view_rect)) {
                self.current_file_path.returnFromSubdir();
            }
            index += 1;
        }
        while (iterator.next() catch {
            std.debug.print("Couldnt loop through elements in directory", .{});
            self.show_filepicker = false;
            return;
        }) |entry| {
            if (entry.kind != .file and entry.kind != .directory or entry.name.len < 3) continue;
            if (entry.kind == .file and !std.mem.eql(u8, entry.name[entry.name.len - 3 ..], "ch8")) continue;

            var inner_buf: [64]u8 = [_]u8{0} ** 64;
            std.mem.copyForwards(u8, inner_buf[0..], entry.name);

            if (entry.kind == .directory) inner_buf[entry.name.len] = '/';

            const button_rect = rl.Rectangle.init(view_rect.x + padding, view_rect.y + scroll.y + padding + (line_height + padding) * index, view_rect.width - 2 * padding, line_height);
            if (rg.guiButton(button_rect, @ptrCast(&inner_buf)) > 0 and rl.checkCollisionPointRec(rl.getMousePosition(), view_rect)) {
                if (entry.kind == .file) {
                    self.current_file_path.setFile(entry.name);
                    emulator.loadProgram(self.current_file_path.getFullPath());

                    self.show_filepicker = false;
                } else {
                    self.current_file_path.addSubdir(entry.name);
                }
            }
            index += 1;
        }
        rl.endScissorMode();
    }
}

const FilePath = struct {
    path: [512]u8,
    len: u16,

    end_is_file: bool = false,
    file_name: [64]u8,

    pub fn init() FilePath {
        return FilePath{
            .path = [_]u8{ '.', '/' } ++ [_]u8{0} ** 510,
            .len = 2,
            .file_name = [_]u8{0} ** 64,
        };
    }

    pub fn getDirPath(self: *const FilePath) []const u8 {
        if (!self.end_is_file) return self.path[0..self.len];

        const index = std.mem.lastIndexOf(u8, self.path[1..self.len], &[_]u8{'/'});

        return self.path[0..(index.? + 2)];
    }

    pub fn getFullPath(self: *const FilePath) []const u8 {
        return self.path[0..self.len];
    }
    pub fn getFullPathZeroterm(self: *FilePath) [:0]const u8 {
        self.path[self.len] = 0;
        return @ptrCast(self.path[0..(self.len + 1)]);
    }

    pub fn addSubdir(self: *FilePath, subdir: []const u8) void {
        if (self.end_is_file) self.previous();
        if (subdir.len + self.len > 512) {
            g.error_msg = "Error: Path to file is too long";
            return;
        }

        std.mem.copyForwards(u8, self.path[self.len..], subdir);
        self.len += @as(u16, @truncate(subdir.len));
        self.path[self.len] = '/';
        self.len += 1;
        self.end_is_file = false;
    }

    pub fn getFileName(self: *FilePath) [:0]const u8 {
        if (self.file_name[0] == 0) return "No file selected";

        return @ptrCast(&self.file_name);
    }

    pub fn setFile(self: *FilePath, file: []const u8) void {
        if (self.end_is_file) self.previous();
        if (file.len + self.len > 512) {
            g.error_msg = "Error: Path to file is too long";
            return;
        }

        std.mem.copyForwards(u8, self.path[self.len..], file);
        std.mem.copyForwards(u8, self.file_name[0..], file);
        self.file_name[file.len] = 0;
        self.len += @as(u16, @truncate(file.len));
        self.path[self.len] = 0;
        self.end_is_file = true;
        return;
    }

    pub fn returnFromSubdir(self: *FilePath) void {
        if (self.end_is_file) self.previous();
        self.previous();
    }

    pub fn previous(self: *FilePath) void {
        if (self.len < 3) return;
        if (!self.end_is_file) self.len -= 1;
        const index = std.mem.lastIndexOf(u8, self.path[1..self.len], &[_]u8{'/'});

        if (index) |i| {
            self.len = @as(u16, @truncate(i)) + 2; // i points to the index before '/', i want len to point to the character after -> +2
        }
        self.end_is_file = false;
    }
};

test "Filepath tests" {
    const testing = std.testing;
    var fp = FilePath.init();

    try testing.expectEqualSlices(u8, "./", fp.getFullPath());

    fp.addSubdir("src");
    try testing.expectEqualSlices(u8, "./src/", fp.getFullPath());

    fp.addSubdir("temp");
    try testing.expectEqualSlices(u8, "./src/temp/", fp.getFullPath());

    fp.addSubdir("temp2");
    try testing.expectEqualSlices(u8, "./src/temp/temp2/", fp.getFullPath());

    fp.setFile("tfile.ch8");
    try testing.expectEqualSlices(u8, "./src/temp/temp2/tfile.ch8", fp.getFullPath());
    try testing.expectEqualSlices(u8, "./src/temp/temp2/", fp.getDirPath());

    fp.setFile("bfile.ch8");
    try testing.expectEqualSlices(u8, "./src/temp/temp2/bfile.ch8", fp.getFullPath());

    fp.previous();
    try testing.expectEqualSlices(u8, "./src/temp/temp2/", fp.getFullPath());
    try testing.expectEqualSlices(u8, "./src/temp/temp2/", fp.getDirPath());

    fp.previous();
    try testing.expectEqualSlices(u8, "./src/temp/", fp.getFullPath());

    fp.previous();
    try testing.expectEqualSlices(u8, "./src/", fp.getFullPath());

    fp.previous();
    try testing.expectEqualSlices(u8, "./", fp.getFullPath());

    fp.previous();
    try testing.expectEqualSlices(u8, "./", fp.getFullPath());
}
