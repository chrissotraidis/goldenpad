#include <ultra64.h>

#include <math.h>
#include <stdint.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* Real host-side GU math, isolated from MGB64's desktop SDL compatibility TU. */

static void goldenpad_gu_identity(f32 matrix[4][4]) {
    for (int row = 0; row < 4; ++row) {
        for (int column = 0; column < 4; ++column) {
            matrix[row][column] = row == column ? 1.0f : 0.0f;
        }
    }
}

static s32 goldenpad_gu_fixed16(f32 value) {
    f32 scaled = value * 65536.0f;
    if (scaled >= 2147483647.0f) {
        return INT32_MAX;
    }
    if (scaled <= -2147483648.0f) {
        return INT32_MIN;
    }
    return (s32)scaled;
}

void guMtxF2L(f32 source[4][4], Mtx *destination) {
    s32 *integer = (s32 *)&destination->m[0][0];
    s32 *fraction = (s32 *)&destination->m[2][0];
    for (int row = 0; row < 4; ++row) {
        for (int pair = 0; pair < 2; ++pair) {
            s32 first = goldenpad_gu_fixed16(source[row][pair * 2]);
            s32 second = goldenpad_gu_fixed16(source[row][pair * 2 + 1]);
            *integer++ = (first & (s32)0xffff0000) | ((u32)second >> 16);
            *fraction++ = ((u32)first << 16) | ((u32)second & 0xffff);
        }
    }
}

void guOrthoF(f32 matrix[4][4], f32 left, f32 right, f32 bottom, f32 top,
              f32 near, f32 far, f32 scale) {
    goldenpad_gu_identity(matrix);
    matrix[0][0] = 2.0f / (right - left);
    matrix[1][1] = 2.0f / (top - bottom);
    matrix[2][2] = -2.0f / (far - near);
    matrix[3][0] = -(right + left) / (right - left);
    matrix[3][1] = -(top + bottom) / (top - bottom);
    matrix[3][2] = -(far + near) / (far - near);
    if (scale != 1.0f) {
        for (int row = 0; row < 4; ++row) {
            for (int column = 0; column < 4; ++column) {
                matrix[row][column] *= scale;
            }
        }
    }
}

void guOrtho(Mtx *matrix, f32 left, f32 right, f32 bottom, f32 top,
             f32 near, f32 far, f32 scale) {
    f32 result[4][4];
    guOrthoF(result, left, right, bottom, top, near, far, scale);
    guMtxF2L(result, matrix);
}

void guPerspectiveF(f32 matrix[4][4], u16 *perspective_normal,
                    f32 field_of_view, f32 aspect, f32 near, f32 far,
                    f32 scale) {
    f32 radians = field_of_view * (f32)M_PI / 180.0f;
    f32 cotangent = cosf(radians / 2.0f) / sinf(radians / 2.0f);
    goldenpad_gu_identity(matrix);
    matrix[0][0] = cotangent / aspect;
    matrix[1][1] = cotangent;
    matrix[2][2] = (near + far) / (near - far);
    matrix[2][3] = -1.0f;
    matrix[3][2] = 2.0f * near * far / (near - far);
    matrix[3][3] = 0.0f;
    for (int row = 0; row < 4; ++row) {
        for (int column = 0; column < 4; ++column) {
            matrix[row][column] *= scale;
        }
    }
    if (perspective_normal != NULL) {
        if (near + far <= 2.0f) {
            *perspective_normal = 0xffff;
        } else {
            *perspective_normal = (u16)(2.0f * 65536.0f / (near + far));
            if (*perspective_normal == 0) {
                *perspective_normal = 1;
            }
        }
    }
}

void guPerspective(Mtx *matrix, u16 *perspective_normal, f32 field_of_view,
                   f32 aspect, f32 near, f32 far, f32 scale) {
    f32 result[4][4];
    guPerspectiveF(result, perspective_normal, field_of_view, aspect, near, far,
                   scale);
    guMtxF2L(result, matrix);
}

void guLookAtF(f32 matrix[4][4], f32 eye_x, f32 eye_y, f32 eye_z,
               f32 at_x, f32 at_y, f32 at_z,
               f32 up_x, f32 up_y, f32 up_z) {
    f32 look_x = at_x - eye_x;
    f32 look_y = at_y - eye_y;
    f32 look_z = at_z - eye_z;
    f32 length = -1.0f / sqrtf(look_x * look_x + look_y * look_y + look_z * look_z);
    look_x *= length;
    look_y *= length;
    look_z *= length;

    f32 right_x = up_y * look_z - up_z * look_y;
    f32 right_y = up_z * look_x - up_x * look_z;
    f32 right_z = up_x * look_y - up_y * look_x;
    length = 1.0f / sqrtf(right_x * right_x + right_y * right_y + right_z * right_z);
    right_x *= length;
    right_y *= length;
    right_z *= length;

    up_x = look_y * right_z - look_z * right_y;
    up_y = look_z * right_x - look_x * right_z;
    up_z = look_x * right_y - look_y * right_x;
    length = 1.0f / sqrtf(up_x * up_x + up_y * up_y + up_z * up_z);
    up_x *= length;
    up_y *= length;
    up_z *= length;

    matrix[0][0] = right_x;
    matrix[1][0] = right_y;
    matrix[2][0] = right_z;
    matrix[3][0] = -(eye_x * right_x + eye_y * right_y + eye_z * right_z);
    matrix[0][1] = up_x;
    matrix[1][1] = up_y;
    matrix[2][1] = up_z;
    matrix[3][1] = -(eye_x * up_x + eye_y * up_y + eye_z * up_z);
    matrix[0][2] = look_x;
    matrix[1][2] = look_y;
    matrix[2][2] = look_z;
    matrix[3][2] = -(eye_x * look_x + eye_y * look_y + eye_z * look_z);
    matrix[0][3] = 0.0f;
    matrix[1][3] = 0.0f;
    matrix[2][3] = 0.0f;
    matrix[3][3] = 1.0f;
}

void guLookAt(Mtx *matrix, f32 eye_x, f32 eye_y, f32 eye_z,
              f32 at_x, f32 at_y, f32 at_z,
              f32 up_x, f32 up_y, f32 up_z) {
    f32 result[4][4];
    guLookAtF(result, eye_x, eye_y, eye_z, at_x, at_y, at_z, up_x, up_y, up_z);
    guMtxF2L(result, matrix);
}

void guLookAtReflect(Mtx *matrix, LookAt *look_at,
                     f32 eye_x, f32 eye_y, f32 eye_z,
                     f32 at_x, f32 at_y, f32 at_z,
                     f32 up_x, f32 up_y, f32 up_z) {
    f32 result[4][4];
    guLookAtF(result, eye_x, eye_y, eye_z, at_x, at_y, at_z, up_x, up_y, up_z);
    guMtxF2L(result, matrix);
    if (look_at == NULL) {
        return;
    }

    f32 look_x = at_x - eye_x;
    f32 look_y = at_y - eye_y;
    f32 look_z = at_z - eye_z;
    f32 length = -1.0f / sqrtf(look_x * look_x + look_y * look_y + look_z * look_z);
    look_x *= length;
    look_y *= length;
    look_z *= length;
    f32 right_x = up_y * look_z - up_z * look_y;
    f32 right_y = up_z * look_x - up_x * look_z;
    f32 right_z = up_x * look_y - up_y * look_x;
    length = 1.0f / sqrtf(right_x * right_x + right_y * right_y + right_z * right_z);
    right_x *= length;
    right_y *= length;
    right_z *= length;
    up_x = look_y * right_z - look_z * right_y;
    up_y = look_z * right_x - look_x * right_z;
    up_z = look_x * right_y - look_y * right_x;
    length = 1.0f / sqrtf(up_x * up_x + up_y * up_y + up_z * up_z);
    up_x *= length;
    up_y *= length;
    up_z *= length;

    memset(look_at, 0, sizeof(*look_at));
    look_at->l[0].l.dir[0] = FTOFRAC8(right_x);
    look_at->l[0].l.dir[1] = FTOFRAC8(right_y);
    look_at->l[0].l.dir[2] = FTOFRAC8(right_z);
    look_at->l[1].l.dir[0] = FTOFRAC8(up_x);
    look_at->l[1].l.dir[1] = FTOFRAC8(up_y);
    look_at->l[1].l.dir[2] = FTOFRAC8(up_z);
    look_at->l[1].l.col[1] = 0x80;
    look_at->l[1].l.colc[1] = 0x80;
}

void guRotateF(f32 matrix[4][4], f32 angle, f32 x, f32 y, f32 z) {
    f32 radians = angle * (f32)M_PI / 180.0f;
    f32 cosine = cosf(radians);
    f32 sine = sinf(radians);
    f32 inverse_cosine = 1.0f - cosine;
    f32 length = sqrtf(x * x + y * y + z * z);
    if (length > 0.0f) {
        x /= length;
        y /= length;
        z /= length;
    }
    goldenpad_gu_identity(matrix);
    matrix[0][0] = inverse_cosine * x * x + cosine;
    matrix[0][1] = inverse_cosine * x * y + sine * z;
    matrix[0][2] = inverse_cosine * x * z - sine * y;
    matrix[1][0] = inverse_cosine * x * y - sine * z;
    matrix[1][1] = inverse_cosine * y * y + cosine;
    matrix[1][2] = inverse_cosine * y * z + sine * x;
    matrix[2][0] = inverse_cosine * x * z + sine * y;
    matrix[2][1] = inverse_cosine * y * z - sine * x;
    matrix[2][2] = inverse_cosine * z * z + cosine;
}

void guRotate(Mtx *matrix, f32 angle, f32 x, f32 y, f32 z) {
    f32 result[4][4];
    guRotateF(result, angle, x, y, z);
    guMtxF2L(result, matrix);
}

void guScaleF(f32 matrix[4][4], f32 x, f32 y, f32 z) {
    goldenpad_gu_identity(matrix);
    matrix[0][0] = x;
    matrix[1][1] = y;
    matrix[2][2] = z;
}

void guScale(Mtx *matrix, f32 x, f32 y, f32 z) {
    f32 result[4][4];
    guScaleF(result, x, y, z);
    guMtxF2L(result, matrix);
}

static void goldenpad_gu_translate_f(f32 matrix[4][4], f32 x, f32 y, f32 z) {
    goldenpad_gu_identity(matrix);
    matrix[3][0] = x;
    matrix[3][1] = y;
    matrix[3][2] = z;
}

void guTranslate(Mtx *matrix, f32 x, f32 y, f32 z) {
    f32 result[4][4];
    goldenpad_gu_translate_f(result, x, y, z);
    guMtxF2L(result, matrix);
}

void guNormalize(f32 *x, f32 *y, f32 *z) {
    f32 length = sqrtf(*x * *x + *y * *y + *z * *z);
    if (length > 0.0f) {
        *x /= length;
        *y /= length;
        *z /= length;
    }
}

void guAlignF(f32 matrix[4][4], f32 angle, f32 x, f32 y, f32 z) {
    guRotateF(matrix, angle, x, y, z);
}
