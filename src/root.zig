const std = @import("std");
const tensor = @import("tensor.zig");
const ops = @import("ops.zig");
const testing = std.testing;

pub const Tensor = tensor.Tensor;
pub const Matrix = tensor.Matrix;
pub const mul = ops.mul;
