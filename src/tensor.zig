const std = @import("std");

pub const Dimension = struct {
    len: usize,
    stride: usize,
};

pub fn Tensor(comptime T: type, comptime rank: usize, comptime dimensions: [rank]Dimension) type {
    comptime var tensor_size: usize = 1;
    comptime var tensor_shape: [rank]usize = undefined;
    comptime var tensor_strides: [rank]usize = undefined;

    for (dimensions, 0..) |dimension, i| {
        tensor_size *= dimension.len;
        tensor_shape[i] = dimension.len;
        tensor_strides[i] = dimension.stride;
    }

    return struct {
        pub const Self = @This();
        pub const ElementType = T;

        pub const size = tensor_size;
        pub const shape = tensor_shape;
        pub const strides = tensor_strides;
        // comptime is_contiguous: bool = undefined,

        data: *[Self.size]T,

        pub fn Inner(depth: usize) type {
            std.debug.assert(depth <= rank);
            if ((dimensions.len - depth) > 0) {
                return Tensor(T, dimensions.len - depth, dimensions[depth..]);
            } else {
                return *T;
            }
        }

        pub fn Permute(comptime indices: [rank]usize) type {
            // verify permute indices are unique and in bounds
            comptime var sorted: [rank]usize = undefined;
            @memcpy(&sorted, &indices);
            std.mem.sort(&sorted, {}, std.sort.asc(usize));

            for (1..rank) |i| {
                if (sorted[i] != i) @compileError("unexpected permute index");
            }

            comptime var permuted: [rank]Dimension = undefined;
            for (indices, 0..) |j, i| {
                permuted[i] = j;
            }

            return Tensor(T, rank, indices);
        }

        pub fn Transpose(comptime i: usize, j: usize) type {
            comptime var indices: [rank]usize = undefined;
            for (0..rank) |k| {
                indices[k] = if (k == i) j else if (k == j) i else k;
            }

            return Permute(indices);
        }

        // pub fn View(comptime shape: anytype) type {
        //
        // }

        pub fn fill(self: Self, value: T) void {
            @memset(self.data, value);
        }

        pub fn permute(self: Self, comptime indices: [rank]usize) Permute(indices) {
            return .{ .data = self.data };
        }

        pub fn transpose(self: Self, comptime pair: struct { i: usize = 1, j: usize = 0 }) Transpose(pair.i, pair.j) {
            return .{ .data = self.data };
        }

        pub fn offset(indices: anytype) usize {
            var flattened: usize = 0;
            for (indices, 0..) |index, i| {
                const stride = dimensions[i].stride;
                flattened += index * stride;
            }
        }

        pub fn get(self: Self, indices: anytype) Inner(indices.len) {
            return .{ .data = self.data[offset(indices)] };
        }
        //     pub fn offset(indices: []usize) usize {
        //     std.debug.assert(indices.len <= rank);
        //
        // }
    };
}

pub fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return Tensor(T, 2, .{ .{ .len = rows, .stride = cols }, .{ .len = cols, .stride = 1 } });
}

pub const Order = enum {
    row_major,
    column_major,
};

pub fn ordered(comptime order: Order, comptime rank: usize, comptime lens: [rank]usize) [rank]Dimension {
    switch (order) {
        .row_major => {
            var dimensions: [rank]Dimension = undefined;
            var stride: usize = 1;

            var i = rank;
            while (i > 0) {
                i -= 1;
                dimensions[i] = .{ .len = lens[i], .stride = stride };
                stride *= lens[i];
            }

            const DummyTensor = Tensor(void, rank, dimensions);
            std.debug.assert(stride == DummyTensor.size);

            return dimensions;
        },
        .column_major => {
            var dimensions: [rank]Dimension = undefined;
            var stride: usize = 1;

            var i = 0;
            while (i < rank) {
                dimensions[i] = .{ .len = lens[i], .stride = stride };
                stride *= lens[i];
                i += 1;
            }

            const DummyTensor = Tensor(void, rank, dimensions);
            std.debug.assert(stride == DummyTensor.size);

            return dimensions;
        },
    }
}
