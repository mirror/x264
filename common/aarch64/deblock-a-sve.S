/*****************************************************************************
 * deblock-a-sve.S: aarch64 deblocking
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
#include "deblock-a-common.S"

.arch armv8-a+sve

.macro h264_loop_filter_chroma_sve
    ptrue           p0.b, vl16

    dup             v22.16b, w2              // alpha
    uxtl            v24.8h,  v24.8b
    uabd            v26.16b, v16.16b, v0.16b   // abs(p0 - q0)
    uxtl            v4.8h,   v0.8b
    uxtl2           v5.8h,   v0.16b
    uabd            v28.16b, v18.16b, v16.16b  // abs(p1 - p0)
    usubw           v4.8h,   v4.8h,   v16.8b
    usubw2          v5.8h,   v5.8h,   v16.16b
    sli             v24.8h,  v24.8h,  #8
    shl             v4.8h,   v4.8h,   #2
    shl             v5.8h,   v5.8h,   #2
    uabd            v30.16b, v2.16b,  v0.16b   // abs(q1 - q0)
    uxtl            v24.4s,  v24.4h
    uaddw           v4.8h,   v4.8h,   v18.8b
    uaddw2          v5.8h,   v5.8h,   v18.16b

    cmphi           p1.b, p0/z, z22.b, z26.b
    usubw           v4.8h,   v4.8h,   v2.8b
    usubw2          v5.8h,   v5.8h,   v2.16b
    sli             v24.4s,  v24.4s,  #16
    dup             v22.16b, w3              // beta
    rshrn           v4.8b,   v4.8h,   #3
    rshrn2          v4.16b,  v5.8h,   #3
    cmphi           p2.b, p0/z, z22.b, z28.b
    cmphi           p3.b, p0/z, z22.b, z30.b
    smin            v4.16b,  v4.16b,  v24.16b
    neg             v25.16b, v24.16b
    and             p1.b, p0/z, p1.b, p2.b
    smax            v4.16b,  v4.16b,  v25.16b
    and             p1.b, p0/z, p1.b, p3.b
    uxtl            v22.8h,  v0.8b
    uxtl2           v23.8h,  v0.16b

    uxtl            v28.8h,  v16.8b
    uxtl2           v29.8h,  v16.16b
    saddw           v28.8h,  v28.8h,  v4.8b
    saddw2          v29.8h,  v29.8h,  v4.16b
    ssubw           v22.8h,  v22.8h,  v4.8b
    ssubw2          v23.8h,  v23.8h,  v4.16b
    sqxtun          v16.8b,  v28.8h
    sqxtun          v0.8b,   v22.8h
    sqxtun2         v16.16b, v29.8h
    sqxtun2         v0.16b,  v23.8h
.endm

function deblock_v_chroma_sve, export=1
    h264_loop_filter_start

    sub             x0,  x0,  x1, lsl #1
    // No performance improvement if sve load is used. So, continue using
    // NEON load here
    ld1             {v18.16b}, [x0], x1
    ld1             {v16.16b}, [x0], x1
    ld1             {v0.16b},  [x0], x1
    ld1             {v2.16b},  [x0]

    h264_loop_filter_chroma_sve

    sub             x0,  x0,  x1, lsl #1
    st1b            {z16.b}, p1, [x0]
    add             x0, x0, x1
    st1b            {z0.b}, p1, [x0]

    ret
endfunc
