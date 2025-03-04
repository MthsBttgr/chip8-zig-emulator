///Just a builder for raylib rectangles
/// It became annoying and space consuming to init and adjust every Rectangle
/// This atleast makes it a bit more ergonomic
const std = @import("std");
const rl = @import("raylib");

const Rect = @This();

rl_rectangle: rl.Rectangle,

pub fn init() Rect {
    return Rect{ .rl_rectangle = rl.Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 } };
}

pub fn initRect(rect: rl.Rectangle) Rect {
    return Rect{ .rl_rectangle = rect };
}

pub fn setX(self: Rect, new_x: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.x = new_x;
    return new_self;
}
pub fn setY(self: Rect, new_y: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.y = new_y;
    return new_self;
}
pub fn setWidth(self: Rect, new_width: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.width = new_width;
    return new_self;
}
pub fn setHeight(self: Rect, new_height: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.height = new_height;
    return new_self;
}
pub fn addToX(self: Rect, add_x: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.x += add_x;
    return new_self;
}
pub fn addToY(self: Rect, add_y: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.y += add_y;
    return new_self;
}
pub fn addToWidth(self: Rect, add_width: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.width += add_width;
    return new_self;
}
pub fn addToHeight(self: Rect, add_height: f32) Rect {
    var new_self = self;
    new_self.rl_rectangle.height += add_height;
    return new_self;
}
pub fn x(self: Rect) f32 {
    return self.rl_rectangle.x;
}
pub fn y(self: Rect) f32 {
    return self.rl_rectangle.y;
}
pub fn width(self: Rect) f32 {
    return self.rl_rectangle.width;
}
pub fn height(self: Rect) f32 {
    return self.rl_rectangle.height;
}

pub fn build(self: Rect) rl.Rectangle {
    return self.rl_rectangle;
}
