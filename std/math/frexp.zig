// Special Cases:
//
// - frexp(+-0)   = +-0, 0
// - frexp(+-inf) = +-inf, 0
// - frexp(nan)   = nan, undefined

const std = @import("../index.zig");
const math = std.math;
const assert = std.debug.assert;

fn frexp_result(comptime T: type) -> type {
    return struct {
        significand: T,
        exponent: i32,
    };
}
pub const frexp32_result = frexp_result(f32);
pub const frexp64_result = frexp_result(f64);

pub fn frexp(x: var) -> frexp_result(@typeOf(x)) {
    const T = @typeOf(x);
    return switch (T) {
        f32 => frexp32(x),
        f64 => frexp64(x),
        else => @compileError("frexp not implemented for " ++ @typeName(T)),
    };
}

fn frexp32(x: f32) -> frexp32_result {
    var result: frexp32_result = undefined;

    var y = @bitCast(u32, x);
    const e = i32(y >> 23) & 0xFF;

    if (e == 0) {
        if (x != 0) {
            // subnormal
            result = frexp32(x * 0x1.0p64);
            result.exponent -= 64;
        } else {
            // frexp(+-0) = (+-0, 0)
            result.significand = x;
            result.exponent = 0;
        }
        return result;
    } else if (e == 0xFF) {
        // frexp(nan) = (nan, undefined)
        result.significand = x;
        result.exponent = undefined;

        // frexp(+-inf) = (+-inf, 0)
        if (math.isInf(x)) {
            result.exponent = 0;
        }

        return result;
    }

    result.exponent = e - 0x7E;
    y &= 0x807FFFFF;
    y |= 0x3F000000;
    result.significand = @bitCast(f32, y);
    return result;
}

fn frexp64(x: f64) -> frexp64_result {
    var result: frexp64_result = undefined;

    var y = @bitCast(u64, x);
    const e = i32(y >> 52) & 0x7FF;

    if (e == 0) {
        if (x != 0) {
            // subnormal
            result = frexp64(x * 0x1.0p64);
            result.exponent -= 64;
        } else {
            // frexp(+-0) = (+-0, 0)
            result.significand = x;
            result.exponent = 0;
        }
        return result;
    } else if (e == 0x7FF) {
        // frexp(nan) = (nan, undefined)
        result.significand = x;
        result.exponent = undefined;

        // frexp(+-inf) = (+-inf, 0)
        if (math.isInf(x)) {
            result.exponent = 0;
        }

        return result;
    }

    result.exponent = e - 0x3FE;
    y &= 0x800FFFFFFFFFFFFF;
    y |= 0x3FE0000000000000;
    result.significand = @bitCast(f64, y);
    return result;
}

test "math.frexp" {
    const a = frexp(f32(1.3));
    const b = frexp32(1.3);
    assert(a.significand == b.significand and a.exponent == b.exponent);

    const c = frexp(f64(1.3));
    const d = frexp64(1.3);
    assert(c.significand == d.significand and c.exponent == d.exponent);
}

test "math.frexp32" {
    const epsilon = 0.000001;
    var r: frexp32_result = undefined;

    r = frexp32(1.3);
    assert(math.approxEq(f32, r.significand, 0.65, epsilon) and r.exponent == 1);

    r = frexp32(78.0234);
    assert(math.approxEq(f32, r.significand, 0.609558, epsilon) and r.exponent == 7);
}

test "math.frexp64" {
    const epsilon = 0.000001;
    var r: frexp64_result = undefined;

    r = frexp64(1.3);
    assert(math.approxEq(f64, r.significand, 0.65, epsilon) and r.exponent == 1);

    r = frexp64(78.0234);
    assert(math.approxEq(f64, r.significand, 0.609558, epsilon) and r.exponent == 7);
}

test "math.frexp32.special" {
    var r: frexp32_result = undefined;

    r = frexp32(0.0);
    assert(r.significand == 0.0 and r.exponent == 0);

    r = frexp32(-0.0);
    assert(r.significand == -0.0 and r.exponent == 0);

    r = frexp32(math.inf(f32));
    assert(math.isPositiveInf(r.significand) and r.exponent == 0);

    r = frexp32(-math.inf(f32));
    assert(math.isNegativeInf(r.significand) and r.exponent == 0);

    r = frexp32(math.nan(f32));
    assert(math.isNan(r.significand));
}

test "math.frexp64.special" {
    var r: frexp64_result = undefined;

    r = frexp64(0.0);
    assert(r.significand == 0.0 and r.exponent == 0);

    r = frexp64(-0.0);
    assert(r.significand == -0.0 and r.exponent == 0);

    r = frexp64(math.inf(f64));
    assert(math.isPositiveInf(r.significand) and r.exponent == 0);

    r = frexp64(-math.inf(f64));
    assert(math.isNegativeInf(r.significand) and r.exponent == 0);

    r = frexp64(math.nan(f64));
    assert(math.isNan(r.significand));
}
