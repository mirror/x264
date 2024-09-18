/*****************************************************************************
 * pixel-a-sve.S: aarch64 pixel metrics
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
 *
 * Authors: David Chen <david.chen@myais.com.cn>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at licensing@x264.com.
 *****************************************************************************/

#include "asm.S"
#include "pixel-a-common.S"

.arch armv8-a+sve

#if BIT_DEPTH == 8

.macro SSD_START_SVE_4
    ptrue       p0.h, vl4
    ld1b        {z16.h}, p0/z, [x0]
    ld1b        {z17.h}, p0/z, [x2]
    add         x0, x0, x1
    add         x2, x2, x3
    sub         v2.4h, v16.4h, v17.4h
    ld1b        {z16.h}, p0/z, [x0]
    ld1b        {z17.h}, p0/z, [x2]
    add         x0, x0, x1
    add         x2, x2, x3
    smull       v0.4s,  v2.4h,   v2.4h
.endm

.macro SSD_SVE_4
    sub         v2.4h, v16.4h, v17.4h
    ld1b        {z16.h}, p0/z, [x0]
    ld1b        {z17.h}, p0/z, [x2]
    add         x0, x0, x1
    add         x2, x2, x3
    smlal       v0.4s,  v2.4h,   v2.4h
.endm

.macro SSD_END_SVE_4
    sub         v2.4h, v16.4h, v17.4h
    smlal       v0.4s,  v2.4h,   v2.4h
.endm

.macro SSD_START_SVE_8
    ptrue       p0.h, vl8
    ld1b        {z16.h}, p0/z, [x0]
    ld1b        {z17.h}, p0/z, [x2]
    add         x0, x0, x1
    add         x2, x2, x3
    sub         v2.8h, v16.8h, v17.8h
    ld1b        {z16.h}, p0/z, [x0]
    smull       v0.4s,  v2.4h,   v2.4h
    ld1b        {z17.h}, p0/z, [x2]
    smlal2      v0.4s,  v2.8h,   v2.8h
    add         x0, x0, x1
    add         x2, x2, x3
.endm

.macro SSD_SVE_8
    sub         v2.8h, v16.8h, v17.8h
    ld1b        {z16.h}, p0/z, [x0]
    smlal       v0.4s,  v2.4h,   v2.4h
    ld1b        {z17.h}, p0/z, [x2]
    smlal2      v0.4s,  v2.8h,   v2.8h
    add         x0, x0, x1
    add         x2, x2, x3
.endm

.macro SSD_END_SVE_8
    sub         v2.8h,  v16.8h,  v17.8h
    smlal       v0.4s,  v2.4h,   v2.4h
    smlal2      v0.4s,  v2.8h,   v2.8h
.endm

.macro SSD_FUNC_SVE w h
function pixel_ssd_\w\()x\h\()_sve, export=1
    SSD_START_SVE_\w
.rept \h-2
    SSD_SVE_\w
.endr
    SSD_END_SVE_\w

    addv        s0,  v0.4s
    mov         w0,  v0.s[0]
    ret
endfunc
.endm

.macro load_diff_fly_sve_8x8
    ld1b        {z1.h}, p0/z, [x2]
    ld1b        {z0.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1
    ld1b        {z3.h}, p0/z, [x2]
    ld1b        {z2.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1
    sub         v16.8h, v0.8h,  v1.8h
    sub         v17.8h, v2.8h,  v3.8h
    ld1b        {z5.h}, p0/z, [x2]
    ld1b        {z4.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1
    ld1b        {z7.h}, p0/z, [x2]
    ld1b        {z6.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1
    sub         v18.8h, v4.8h,  v5.8h
    sub         v19.8h, v6.8h,  v7.8h
    ld1b        {z1.h}, p0/z, [x2]
    ld1b        {z0.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1
    ld1b        {z3.h}, p0/z, [x2]
    ld1b        {z2.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1
    sub         v20.8h, v0.8h,  v1.8h
    sub         v21.8h, v2.8h,  v3.8h
    ld1b        {z5.h}, p0/z, [x2]
    ld1b        {z4.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1
    ld1b        {z7.h}, p0/z, [x2]
    ld1b        {z6.h}, p0/z, [x0]
    add         x2, x2, x3
    add         x0, x0, x1

    SUMSUB_AB   v0.8h,  v1.8h,  v16.8h, v17.8h
    SUMSUB_AB   v2.8h,  v3.8h,  v18.8h, v19.8h

    sub         v22.8h, v4.8h,  v5.8h
    sub         v23.8h, v6.8h,  v7.8h
.endm

.macro pixel_var_sve_8 h
function pixel_var_8x\h\()_sve, export=1
    ptrue           p0.h, vl8
    ld1b            {z16.h}, p0/z, [x0]
    add             x0, x0, x1
    ld1b            {z17.h}, p0/z, [x0]
    add             x0, x0, x1
    mov             x2,  \h - 4
    mul             v1.8h,  v16.8h, v16.8h
    mul             v2.8h,  v17.8h, v17.8h
    add             v0.8h,  v16.8h,  v17.8h
    ld1b            {z18.h}, p0/z, [x0]
    add             x0, x0, x1
    uaddlp          v1.4s,  v1.8h
    uaddlp          v2.4s,  v2.8h
    ld1b            {z19.h}, p0/z, [x0]
    add             x0, x0, x1

1:  subs            x2,  x2,  #4
    add             v0.8h,  v0.8h,  v18.8h
    mul             v24.8h, v18.8h, v18.8h
    ld1b            {z20.h}, p0/z, [x0]
    add             x0, x0, x1
    add             v0.8h,  v0.8h,  v19.8h
    mul             v25.8h, v19.8h, v19.8h
    uadalp          v1.4s,  v24.8h
    ld1b            {z21.h}, p0/z, [x0]
    add             x0, x0, x1
    add             v0.8h,  v0.8h,  v20.8h
    mul             v26.8h, v20.8h, v20.8h
    uadalp          v2.4s,  v25.8h
    ld1b            {z18.h}, p0/z, [x0]
    add             x0, x0, x1
    add             v0.8h,  v0.8h,  v21.8h
    mul             v27.8h, v21.8h, v21.8h
    uadalp          v1.4s,  v26.8h
    ld1b            {z19.h}, p0/z, [x0]
    add             x0, x0, x1
    uadalp          v2.4s,  v27.8h
    b.gt            1b

    add             v0.8h,  v0.8h,  v18.8h
    mul             v28.8h, v18.8h, v18.8h
    add             v0.8h,  v0.8h,  v19.8h
    mul             v29.8h, v19.8h, v19.8h
    uadalp          v1.4s,  v28.8h
    uadalp          v2.4s,  v29.8h

    b               var_end
endfunc
.endm

function var_end
    add             v1.4s,  v1.4s,  v2.4s
    uaddlv          s0,  v0.8h
    uaddlv          d1,  v1.4s
    mov             w0,  v0.s[0]
    mov             x1,  v1.d[0]
    orr             x0,  x0,  x1,  lsl #32
    ret
endfunc

.macro SUMSUBL_AB_SVE  sum, sub, a, b
    add         \sum,  \a,  \b
    sub         \sub,  \a,  \b
.endm

function pixel_sa8d_8x8_sve, export=1
    ptrue       p0.h, vl8
    mov         x4,  x30
    bl          pixel_sa8d_8x8_sve
    add         v0.8h,  v0.8h,  v1.8h
    uaddlv      s0,  v0.8h
    mov         w0,  v0.s[0]
    add         w0,  w0,  #1
    lsr         w0,  w0,  #1
    ret         x4
endfunc

.macro sa8d_satd_sve_8x8 satd=
function pixel_sa8d_\satd\()8x8_sve
    load_diff_fly_sve_8x8

    SUMSUB_AB   v16.8h, v18.8h, v0.8h,  v2.8h
    SUMSUB_AB   v17.8h, v19.8h, v1.8h,  v3.8h

    HADAMARD4_V v20.8h, v21.8h, v22.8h, v23.8h, v0.8h,  v1.8h, v2.8h, v3.8h
.ifc \satd, satd_
    transpose   v0.8h,  v1.8h,  v16.8h, v17.8h
    transpose   v2.8h,  v3.8h,  v18.8h, v19.8h
    transpose   v4.8h,  v5.8h,  v20.8h, v21.8h
    transpose   v6.8h,  v7.8h,  v22.8h, v23.8h

    SUMSUB_AB   v24.8h, v25.8h, v0.8h,  v1.8h
    SUMSUB_AB   v26.8h, v27.8h, v2.8h,  v3.8h
    SUMSUB_AB   v0.8h,  v1.8h,  v4.8h,  v5.8h
    SUMSUB_AB   v2.8h,  v3.8h,  v6.8h,  v7.8h

    transpose   v4.4s,  v6.4s,  v24.4s, v26.4s
    transpose   v5.4s,  v7.4s,  v25.4s, v27.4s
    transpose   v24.4s, v26.4s, v0.4s,  v2.4s
    transpose   v25.4s, v27.4s, v1.4s,  v3.4s

    abs         v0.8h,  v4.8h
    abs         v1.8h,  v5.8h
    abs         v2.8h,  v6.8h
    abs         v3.8h,  v7.8h
    abs         v4.8h,  v24.8h
    abs         v5.8h,  v25.8h
    abs         v6.8h,  v26.8h
    abs         v7.8h,  v27.8h

    umax        v0.8h,  v0.8h,  v2.8h
    umax        v1.8h,  v1.8h,  v3.8h
    umax        v2.8h,  v4.8h,  v6.8h
    umax        v3.8h,  v5.8h,  v7.8h

    add         v26.8h, v0.8h,  v1.8h
    add         v27.8h, v2.8h,  v3.8h
.endif

    SUMSUB_AB   v0.8h,  v16.8h, v16.8h, v20.8h
    SUMSUB_AB   v1.8h,  v17.8h, v17.8h, v21.8h
    SUMSUB_AB   v2.8h,  v18.8h, v18.8h, v22.8h
    SUMSUB_AB   v3.8h,  v19.8h, v19.8h, v23.8h

    transpose   v20.8h, v21.8h, v16.8h, v17.8h
    transpose   v4.8h,  v5.8h,  v0.8h,  v1.8h
    transpose   v22.8h, v23.8h, v18.8h, v19.8h
    transpose   v6.8h,  v7.8h,  v2.8h,  v3.8h

    SUMSUB_AB   v2.8h,  v3.8h,  v20.8h, v21.8h
    SUMSUB_AB   v24.8h, v25.8h, v4.8h,  v5.8h
    SUMSUB_AB   v0.8h,  v1.8h,  v22.8h, v23.8h
    SUMSUB_AB   v4.8h,  v5.8h,  v6.8h,  v7.8h

    transpose   v20.4s, v22.4s, v2.4s,  v0.4s
    transpose   v21.4s, v23.4s, v3.4s,  v1.4s
    transpose   v16.4s, v18.4s, v24.4s, v4.4s
    transpose   v17.4s, v19.4s, v25.4s, v5.4s

    SUMSUB_AB   v0.8h,  v2.8h,  v20.8h, v22.8h
    SUMSUB_AB   v1.8h,  v3.8h,  v21.8h, v23.8h
    SUMSUB_AB   v4.8h,  v6.8h,  v16.8h, v18.8h
    SUMSUB_AB   v5.8h,  v7.8h,  v17.8h, v19.8h

    transpose   v16.2d, v20.2d,  v0.2d,  v4.2d
    transpose   v17.2d, v21.2d,  v1.2d,  v5.2d
    transpose   v18.2d, v22.2d,  v2.2d,  v6.2d
    transpose   v19.2d, v23.2d,  v3.2d,  v7.2d

    abs         v16.8h, v16.8h
    abs         v20.8h, v20.8h
    abs         v17.8h, v17.8h
    abs         v21.8h, v21.8h
    abs         v18.8h, v18.8h
    abs         v22.8h, v22.8h
    abs         v19.8h, v19.8h
    abs         v23.8h, v23.8h

    umax        v16.8h, v16.8h, v20.8h
    umax        v17.8h, v17.8h, v21.8h
    umax        v18.8h, v18.8h, v22.8h
    umax        v19.8h, v19.8h, v23.8h

    add         v0.8h,  v16.8h, v17.8h
    add         v1.8h,  v18.8h, v19.8h

    ret
endfunc
.endm

.macro HADAMARD_AC_SVE w h
function pixel_hadamard_ac_\w\()x\h\()_sve, export=1
    ptrue       p0.h, vl8
    movrel      x5, mask_ac_4_8
    mov         x4,  x30
    ld1         {v30.8h,v31.8h}, [x5]
    movi        v28.16b, #0
    movi        v29.16b, #0

    bl          hadamard_ac_8x8_sve
.if \h > 8
    bl          hadamard_ac_8x8_sve
.endif
.if \w > 8
    sub         x0,  x0,  x1,  lsl #3
    add         x0,  x0,  #8
    bl          hadamard_ac_8x8_sve
.endif
.if \w * \h == 256
    sub         x0,  x0,  x1,  lsl #4
    bl          hadamard_ac_8x8_sve
.endif

    addv        s1,  v29.4s
    addv        s0,  v28.4s
    mov         w1,  v1.s[0]
    mov         w0,  v0.s[0]
    lsr         w1,  w1,  #2
    lsr         w0,  w0,  #1
    orr         x0,  x0,  x1, lsl #32
    ret         x4
endfunc
.endm

// v28: satd  v29: sa8d  v30: mask_ac4  v31: mask_ac8
function hadamard_ac_8x8_sve
    ld1b        {z16.h}, p0/z, [x0]
    add         x0, x0, x1
    ld1b        {z17.h}, p0/z, [x0]
    add         x0, x0, x1
    ld1b        {z18.h}, p0/z, [x0]
    add         x0, x0, x1
    ld1b        {z19.h}, p0/z, [x0]
    add         x0, x0, x1
    SUMSUBL_AB_SVE  v0.8h,  v1.8h, v16.8h, v17.8h
    ld1b        {z20.h}, p0/z, [x0]
    add         x0, x0, x1
    ld1b        {z21.h}, p0/z, [x0]
    add         x0, x0, x1
    SUMSUBL_AB_SVE  v2.8h,  v3.8h, v18.8h, v19.8h
    ld1b        {z22.h}, p0/z, [x0]
    add         x0, x0, x1
    ld1b        {z23.h}, p0/z, [x0]
    add         x0, x0, x1
    SUMSUBL_AB_SVE  v4.8h,  v5.8h, v20.8h, v21.8h
    SUMSUBL_AB_SVE  v6.8h,  v7.8h, v22.8h, v23.8h

    SUMSUB_ABCD v16.8h, v18.8h, v17.8h, v19.8h, v0.8h,  v2.8h,  v1.8h,  v3.8h
    SUMSUB_ABCD v20.8h, v22.8h, v21.8h, v23.8h, v4.8h,  v6.8h,  v5.8h,  v7.8h

    transpose   v0.8h,  v1.8h,  v16.8h,  v17.8h
    transpose   v2.8h,  v3.8h,  v18.8h,  v19.8h
    transpose   v4.8h,  v5.8h,  v20.8h,  v21.8h
    transpose   v6.8h,  v7.8h,  v22.8h,  v23.8h

    SUMSUB_AB   v16.8h, v17.8h, v0.8h,  v1.8h
    SUMSUB_AB   v18.8h, v19.8h, v2.8h,  v3.8h
    SUMSUB_AB   v20.8h, v21.8h, v4.8h,  v5.8h
    SUMSUB_AB   v22.8h, v23.8h, v6.8h,  v7.8h

    transpose   v0.4s,  v2.4s,  v16.4s, v18.4s
    transpose   v1.4s,  v3.4s,  v17.4s, v19.4s
    transpose   v4.4s,  v6.4s,  v20.4s, v22.4s
    transpose   v5.4s,  v7.4s,  v21.4s, v23.4s

    SUMSUB_AB   v16.8h, v18.8h, v0.8h,  v2.8h
    SUMSUB_AB   v17.8h, v19.8h, v1.8h,  v3.8h
    SUMSUB_ABCD v20.8h, v22.8h, v21.8h, v23.8h, v4.8h,  v6.8h,  v5.8h,  v7.8h

    abs         v0.8h,  v16.8h
    abs         v4.8h,  v20.8h
    abs         v1.8h,  v17.8h
    abs         v5.8h,  v21.8h
    abs         v2.8h,  v18.8h
    abs         v6.8h,  v22.8h
    abs         v3.8h,  v19.8h
    abs         v7.8h,  v23.8h

    add         v0.8h,  v0.8h,  v4.8h
    add         v1.8h,  v1.8h,  v5.8h
    and         v0.16b, v0.16b, v30.16b
    add         v2.8h,  v2.8h,  v6.8h
    add         v3.8h,  v3.8h,  v7.8h
    add         v0.8h,  v0.8h,  v2.8h
    add         v1.8h,  v1.8h,  v3.8h
    uadalp      v28.4s, v0.8h
    uadalp      v28.4s, v1.8h

    SUMSUB_AB   v6.8h,  v7.8h,  v23.8h, v19.8h
    SUMSUB_AB   v4.8h,  v5.8h,  v22.8h, v18.8h
    SUMSUB_AB   v2.8h,  v3.8h,  v21.8h, v17.8h
    SUMSUB_AB   v1.8h,  v0.8h,  v16.8h,  v20.8h

    transpose   v16.2d, v17.2d,  v6.2d,  v7.2d
    transpose   v18.2d, v19.2d,  v4.2d,  v5.2d
    transpose   v20.2d, v21.2d,  v2.2d,  v3.2d

    abs         v16.8h,  v16.8h
    abs         v17.8h,  v17.8h
    abs         v18.8h,  v18.8h
    abs         v19.8h,  v19.8h
    abs         v20.8h,  v20.8h
    abs         v21.8h,  v21.8h

    transpose   v7.2d,  v6.2d,  v1.2d,  v0.2d

    umax        v3.8h,  v16.8h,  v17.8h
    umax        v2.8h,  v18.8h,  v19.8h
    umax        v1.8h,  v20.8h,  v21.8h

    SUMSUB_AB   v4.8h,  v5.8h,  v7.8h,  v6.8h

    add         v2.8h,  v2.8h,  v3.8h
    add         v2.8h,  v2.8h,  v1.8h
    and         v4.16b, v4.16b, v31.16b
    add         v2.8h,  v2.8h,  v2.8h
    abs         v5.8h,  v5.8h
    abs         v4.8h,  v4.8h
    add         v2.8h,  v2.8h,  v5.8h
    add         v2.8h,  v2.8h,  v4.8h
    uadalp      v29.4s, v2.8h
    ret
endfunc

SSD_FUNC_SVE   4, 4
SSD_FUNC_SVE   4, 8
SSD_FUNC_SVE   4, 16
SSD_FUNC_SVE   8, 4
SSD_FUNC_SVE   8, 8

pixel_var_sve_8  8
pixel_var_sve_8 16

sa8d_satd_sve_8x8

HADAMARD_AC_SVE  8, 8
HADAMARD_AC_SVE  8, 16
HADAMARD_AC_SVE 16, 8
HADAMARD_AC_SVE 16, 16

#else /* BIT_DEPTH == 10 */

.macro SSD_START_SVE_4
    ptrue       p0.s, vl4
    ld1h        {z16.s}, p0/z, [x0]
    ld1h        {z17.s}, p0/z, [x2]
    add         x0, x0, x1, lsl #1
    add         x2, x2, x3, lsl #1
    sub         v2.4s, v16.4s, v17.4s
    ld1h        {z16.s}, p0/z, [x0]
    ld1h        {z17.s}, p0/z, [x2]
    add         x0, x0, x1, lsl #1
    add         x2, x2, x3, lsl #1
    mul         v0.4s, v2.4s, v2.4s
.endm

.macro SSD_SVE_4
    sub         v2.4s, v16.4s, v17.4s
    ld1h        {z16.s}, p0/z, [x0]
    ld1h        {z17.s}, p0/z, [x2]
    add         x0, x0, x1, lsl #1
    add         x2, x2, x3, lsl #1
    mla         v0.4s, v2.4s, v2.4s
.endm

.macro SSD_END_SVE_4
    sub         v2.4s, v16.4s, v17.4s
    mla         v0.4s,  v2.4s, v2.4s
.endm

.macro SSD_FUNC_SVE w h
function pixel_ssd_\w\()x\h\()_sve, export=1
    SSD_START_SVE_\w
.rept \h-2
    SSD_SVE_\w
.endr
    SSD_END_SVE_\w

    addv        s0, v0.4s
    fmov        w0, s0
    ret
endfunc
.endm

SSD_FUNC_SVE   4, 4
SSD_FUNC_SVE   4, 8
SSD_FUNC_SVE   4, 16

#endif /* BIT_DEPTH == 8 */

.arch armv8-a+sve+sve2

.macro ADS_FUNC_SVE_ABSD_ADD_SVE dst tmp_src0 src1
    sabd   \tmp_src0\().s, p0/m, \tmp_src0\().s, \src1\().s
    add    \dst\().s, p0/m, \dst\().s, \tmp_src0\().s
.endm

.macro ADS_FUNC_SVE_ABSD_ADD_SVE2 dst tmp_src0 src1
    saba   \dst\().s, \tmp_src0\().s, \src1\().s
.endm

.macro ADS1_FUNC_SVE sve_version
/**
 * int pixel_ads1(
 * x0 = int enc_dc[1],
 * x1 = uint16_t *sums,
 * x2 = int delta,
 * x3 = uint16_t *cost_mvx,
 * x4 = int16_t *mvs,
 * x5 = int width,
 * x6 = int thresh)
 */
function pixel_ads1_sve\sve_version\(), export=1
    ptrue  p0.s
    index  z7.s, #0, #1  // indices for compactification
    ld1rw  z0.s, p0/z, [x0]  // enc_dc
    dup    z6.s, w6    // threshold

    cntw   x7
    dup    z5.s, w7
    sxtw   x5, w5
    mov    x10, #0  // i
    mov    x0, #0  // nmv

    // for( int i = 0; i<width; i++ )
PIXEL_ADS1_SVE\sve_version\()_LOOP:
    whilelt p0.s, x10, x5

    // int ads = abs( enc_dc[0] - sums[i] ) + cost_mvx[i];
    ld1h   z16.s, p0/z, [x1, x10, lsl #1]
    ld1h   z17.s, p0/z, [x3, x10, lsl #1]
    add    x10, x10, x7
    ADS_FUNC_SVE_ABSD_ADD_SVE\sve_version\()  z17, z16, z0
    
    // if( ads < thresh ) mvs[nmv++] = i;
    cmplt   p1.s, p0/z, z17.s, z6.s
    compact z17.s, p1, z7.s
    cntp    x14, p0, p1.s
    whilelt p2.s, xzr, x14
    st1h    z17.s, p2, [x4, x0, lsl #1]
    add     x0, x0, x14
    add     z7.s, p0/m, z7.s, z5.s
    
    cmp    x10, x5
    b.lt   PIXEL_ADS1_SVE\sve_version\()_LOOP

    ret
endfunc
.endm

ADS1_FUNC_SVE
ADS1_FUNC_SVE 2

.macro ADS2_FUNC_SVE sve_version
/**
 * int pixel_ads2(
 * x0 = int enc_dc[2],
 * x1 = uint16_t *sums,
 * x2 = int delta,
 * x3 = uint16_t *cost_mvx,
 * x4 = int16_t *mvs,
 * x5 = int width,
 * x6 = int thresh)
 */
function pixel_ads2_sve\sve_version\(), export=1
    ptrue  p0.s, VL2
    index  z7.s, #0, #1  // indices for compactification
    ld1w   z31.s, p0/z, [x0]
    dup    z0.s, z31.s[0]  // enc_dc[0]
    dup    z1.s, z31.s[1]  // enc_dc[1]
    dup    z6.s, w6    // threshold

    cntw   x7
    dup    z5.s, w7
    sxtw   x2, w2
    sxtw   x5, w5
    mov    x10, #0  // i
    mov    x0, #0  // nmv

    // for( int i = 0; i < width; i++ )
PIXEL_ADS2_SVE\sve_version\()_LOOP:
    whilelt p0.s, x10, x5

    // int ads = abs( enc_dc[0] - sums[i] )
    //         + abs( enc_dc[1] - sums[i + delta] )
    //         + cost_mvx[i];
    ld1h   z16.s, p0/z, [x1, x10, lsl #1]  // sums[i...]
    ld1h   z17.s, p0/z, [x3, x10, lsl #1]  // cmvx[i...]
    ld1h   z18.s, p0/z, [x1, x2, lsl #1]   // sums[i + delta...]
    add    x10, x10, x7
    add    x2, x2, x7
    ADS_FUNC_SVE_ABSD_ADD_SVE\sve_version\()  z17, z16, z0
    ADS_FUNC_SVE_ABSD_ADD_SVE\sve_version\()  z17, z18, z1

    // if( ads < thresh ) mvs[nmv++] = i;
    cmplt   p1.s, p0/z, z17.s, z6.s
    compact z17.s, p1, z7.s
    cntp    x14, p0, p1.s
    whilelt p2.s, xzr, x14
    st1h    z17.s, p2, [x4, x0, lsl #1]
    add     x0, x0, x14
    add     z7.s, p0/m, z7.s, z5.s

    cmp    x10, x5
    b.lt   PIXEL_ADS2_SVE\sve_version\()_LOOP

    ret
endfunc
.endm

ADS2_FUNC_SVE
ADS2_FUNC_SVE 2

.macro ADS4_FUNC_SVE sve_version
/**
 * int pixel_ads4(
 * x0 = int enc_dc[4],
 * x1 = uint16_t *sums,
 * x2 = int delta,
 * x3 = uint16_t *cost_mvx,
 * x4 = int16_t *mvs,
 * x5 = int width,
 * x6 = int thresh)
 */
function pixel_ads4_sve\sve_version\(), export=1
    ptrue  p0.s, VL4
    index  z7.s, #0, #1  // indices for compactification
    ld1w   z31.s, p0/z, [x0]
    dup    z0.s, z31.s[0]  // enc_dc[0]
    dup    z1.s, z31.s[1]  // enc_dc[1]
    dup    z2.s, z31.s[2]  // enc_dc[2]
    dup    z3.s, z31.s[3]  // enc_dc[3]
    dup    z6.s, w6    // threshold

    cntw   x7
    dup    z5.s, w7
    sub    x7, x7, #8
    sxtw   x2, w2
    sxtw   x5, w5
    mov    x10, #0  // i
    mov    x0, #0  // nmv

    // for( int i = 0; i<width; i++ )
PIXEL_ADS4_SVE\sve_version\()_LOOP:
    whilelt p0.s, x10, x5

    // int ads = abs( enc_dc[0] - sums[0] )
    //         + abs( enc_dc[1] - sums[8] )
    //         + abs( enc_dc[2] - sums[delta] )
    //         + abs( enc_dc[3] - sums[delta+8] )
    //         + cost_mvx[i];
    ld1h   z16.s, p0/z, [x1, x10, lsl #1]  // sums[i...]
    ld1h   z17.s, p0/z, [x3, x10, lsl #1]  // cmvx[i...]
    ld1h   z18.s, p0/z, [x1, x2, lsl #1]   // sums[i + delta...]
    add    x10, x10, #8
    add    x2, x2, #8
    ADS_FUNC_SVE_ABSD_ADD_SVE\sve_version\()  z17, z16, z0
    ADS_FUNC_SVE_ABSD_ADD_SVE\sve_version\()  z17, z18, z2

    ld1h   z19.s, p0/z, [x1, x10, lsl #1]  // sums[i + 8...]
    ld1h   z20.s, p0/z, [x1, x2, lsl #1]  // sums[i + delta + 8...]
    add    x10, x10, x7
    add    x2, x2, x7
    ADS_FUNC_SVE_ABSD_ADD_SVE\sve_version\()  z17, z19, z1
    ADS_FUNC_SVE_ABSD_ADD_SVE\sve_version\()  z17, z20, z3

    // if( ads < thresh ) mvs[nmv++] = i;
    cmplt   p1.s, p0/z, z17.s, z6.s
    compact z17.s, p1, z7.s
    cntp    x14, p0, p1.s
    whilelt p2.s, xzr, x14
    st1h    z17.s, p2, [x4, x0, lsl #1]
    add     x0, x0, x14
    add     z7.s, p0/m, z7.s, z5.s

    cmp    x10, x5
    b.lt   PIXEL_ADS4_SVE\sve_version\()_LOOP

    ret
endfunc
.endm

ADS4_FUNC_SVE
ADS4_FUNC_SVE 2
