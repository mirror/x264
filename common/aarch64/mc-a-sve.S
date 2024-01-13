/*****************************************************************************
 * mc-a-sve.S: aarch64 motion compensation
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
#include "mc-a-common.S"

.arch armv8-a+sve

#if BIT_DEPTH == 8

// void pixel_avg( uint8_t *dst,  intptr_t dst_stride,
//                 uint8_t *src1, intptr_t src1_stride,
//                 uint8_t *src2, intptr_t src2_stride, int weight );
.macro AVGH_SVE w h
function pixel_avg_\w\()x\h\()_sve, export=1
    mov         w10, #64
    cmp         w6,  #32
    mov         w9, #\h
    b.eq        pixel_avg_w\w\()_neon
    subs        w7,  w10,  w6
    b.lt        pixel_avg_weight_w\w\()_add_sub_sve     // weight > 64
    cmp         w6,  #0
    b.ge        pixel_avg_weight_w\w\()_add_add_sve
    b           pixel_avg_weight_w\w\()_sub_add_sve     // weight < 0
endfunc
.endm

AVGH_SVE  4, 2
AVGH_SVE  4, 4
AVGH_SVE  4, 8
AVGH_SVE  4, 16

// 0 < weight < 64
.macro weight_add_add_sve dst, s1, s2, h=
    mul         \dst, \s1, v30.8h
    mla         \dst, \s2, v31.8h
.endm

// weight > 64
.macro weight_add_sub_sve dst, s1, s2, h=
    mul         \dst, \s1, v30.8h
    mls         \dst, \s2, v31.8h
.endm

// weight < 0
.macro weight_sub_add_sve dst, s1, s2, h=
    mul         \dst, \s2, v31.8h
    mls         \dst, \s1, v30.8h
.endm

.macro AVG_WEIGHT_SVE ext
function pixel_avg_weight_w4_\ext\()_sve
    load_weights_\ext
    ptrue       p0.b, vl8
    dup         v30.8h, w6
    dup         v31.8h, w7
1:  // height loop
    subs        w9,  w9,  #2
    ld1b        {z0.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b        {z1.h}, p0/z, [x4]
    add         x4, x4, x5
    weight_\ext\()_sve v4.8h,  v0.8h,  v1.8h
    ld1b        {z2.h}, p0/z, [x2]
    add         x2, x2, x3
    ld1b        {z3.h}, p0/z, [x4]
    add         x4, x4, x5

    sqrshrun    v0.8b,  v4.8h,  #6
    weight_\ext\()_sve v5.8h,  v2.8h,  v3.8h
    st1         {v0.s}[0], [x0], x1
    sqrshrun    v1.8b,  v5.8h,  #6
    st1         {v1.s}[0], [x0], x1
    b.gt        1b
    ret
endfunc
.endm

AVG_WEIGHT_SVE add_add
AVG_WEIGHT_SVE add_sub
AVG_WEIGHT_SVE sub_add

#else // BIT_DEPTH == 10


#endif
