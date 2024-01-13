/****************************************************************************
 * dct-a-sve.S: aarch64 transform and zigzag
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
#include "dct-a-common.S"

.arch armv8-a+sve

function sub4x4_dct_sve, export=1
    mov         x3, #FENC_STRIDE
    mov         x4, #FDEC_STRIDE
    ptrue       p0.h, vl4
    ld1b        {z0.h}, p0/z, [x1]
    add         x1, x1, x3
    ld1b        {z1.h}, p0/z, [x2]
    add         x2, x2, x4
    ld1b        {z2.h}, p0/z, [x1]
    add         x1, x1, x3
    sub         v16.4h, v0.4h, v1.4h
    ld1b        {z3.h}, p0/z, [x2]
    add         x2, x2, x4
    ld1b        {z4.h}, p0/z, [x1]
    add         x1, x1, x3
    sub         v17.4h, v2.4h, v3.4h
    ld1b        {z5.h}, p0/z, [x2]
    add         x2, x2, x4
    ld1b        {z6.h}, p0/z, [x1]
    sub         v18.4h, v4.4h, v5.4h
    ld1b        {z7.h}, p0/z, [x2]
    sub         v19.4h, v6.4h, v7.4h

    DCT_1D      v0.4h, v1.4h, v2.4h, v3.4h, v16.4h, v17.4h, v18.4h, v19.4h
    transpose4x4.h v0, v1, v2, v3, v4, v5, v6, v7
    DCT_1D      v4.4h, v5.4h, v6.4h, v7.4h, v0.4h, v1.4h, v2.4h, v3.4h
    st1         {v4.4h,v5.4h,v6.4h,v7.4h}, [x0]
    ret
endfunc

function zigzag_interleave_8x8_cavlc_sve, export=1
    mov         z31.s, #1
    ptrue       p2.s, vl2
    ld4         {v0.8h,v1.8h,v2.8h,v3.8h}, [x1],  #64
    ld4         {v4.8h,v5.8h,v6.8h,v7.8h}, [x1],  #64
    umax        v16.8h, v0.8h,  v4.8h
    umax        v17.8h, v1.8h,  v5.8h
    umax        v18.8h, v2.8h,  v6.8h
    umax        v19.8h, v3.8h,  v7.8h
    st1         {v0.8h}, [x0],  #16
    st1         {v4.8h}, [x0],  #16
    umaxp       v16.8h, v16.8h, v17.8h
    umaxp       v18.8h, v18.8h, v19.8h
    st1         {v1.8h}, [x0],  #16
    st1         {v5.8h}, [x0],  #16
    umaxp       v16.8h, v16.8h, v18.8h
    st1         {v2.8h}, [x0],  #16
    st1         {v6.8h}, [x0],  #16
    cmhs        v16.4s, v16.4s, v31.4s
    st1         {v3.8h}, [x0],  #16
    and         v16.16b, v16.16b, v31.16b
    st1         {v7.8h}, [x0],  #16
    st1b        {z16.s}, p2, [x2]
    add         x2, x2, #8
    mov         v16.d[0], v16.d[1]
    st1b        {z16.s}, p2, [x2]
    ret
endfunc
