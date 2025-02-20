const std = @import("std");
const tensor = @import("tensor.zig");
const mkl = @cImport({
    @cDefine("MKL_ILP64", "1");
    @cInclude("/opt/intel/oneapi/mkl/2024.1/include/mkl.h");
});

const Tensor = tensor.Tensor;
const Matrix = tensor.Matrix;

pub fn mul(a: anytype, b: anytype, c: anytype) void {
    const m = @TypeOf(a).shape[0];
    const n = @TypeOf(a).shape[1];
    const k = @TypeOf(b).shape[1];
    // std.debug.assert(a.ElementType == f32);
    // std.debug.assert(b.ElementType == f32);
    // std.debug.assert(c.ElementType == f32);

    mkl.cblas_sgemm(mkl.CblasRowMajor, mkl.CblasNoTrans, mkl.CblasNoTrans, m, k, n, 1.0, a.data, n, b.data, k, 0.0, c.data, m);
}
