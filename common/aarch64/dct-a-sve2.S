/****************************************************************************
 * dct-a-sve2.S: aarch64 transform and zigzag
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

.arch armv8-a+sve+sve2

function add4x4_idct_sve2, export=1
    mov         x2, #FDEC_STRIDE
    mov         x11, x0
    ptrue       p0.h, vl8
    ptrue       p1.h, vl4
    ld1         {v0.8h, v1.8h}, [x1]

    SUMSUB_AB   v4.8h, v5.8h, v0.8h, v1.8h

    sshr        v7.8h, v0.8h, #1
    sshr        v6.8h, v1.8h, #1
    sub         v7.8h, v7.8h, v1.8h
    add         v6.8h, v6.8h, v0.8h
    mov         v7.d[0], v7.d[1]
    mov         v6.d[0], v6.d[1]
    ld1b        {z28.h}, p0/z, [x11]
    add         x11, x11, x2
    SUMSUB_AB   v0.8h, v2.8h, v4.8h, v6.8h
    SUMSUB_AB   v1.8h, v3.8h, v5.8h, v7.8h

    transpose4x4.h v0, v1, v3, v2, v16, v17, v18, v19

    SUMSUB_AB   v4.4h, v5.4h, v0.4h, v3.4h

    sshr        v7.4h, v1.4h, #1
    sshr        v6.4h, v2.4h, #1
    sub         v7.4h, v7.4h, v2.4h
    add         v6.4h, v6.4h, v1.4h
    ld1b        {z29.h}, p0/z, [x11]
    add         x11, x11, x2
    SUMSUB_AB   v0.4h, v2.4h, v4.4h, v6.4h
    SUMSUB_AB   v1.4h, v3.4h, v5.4h, v7.4h

    srshr       z0.h, p1/m, z0.h, #6
    srshr       z1.h, p1/m, z1.h, #6
    ld1b        {z31.h}, p0/z, [x11]
    add         x11, x11, x2
    srshr       z2.h, p1/m, z2.h, #6
    srshr       z3.h, p1/m, z3.h, #6
    ld1b        {z30.h}, p0/z, [x11]

    add         v0.8h, v0.8h, v28.8h
    add         v1.8h, v1.8h, v29.8h
    add         v2.8h, v2.8h, v30.8h
    add         v3.8h, v3.8h, v31.8h
    sqxtunb     z0.b, z0.h
    sqxtunb     z1.b, z1.h
    sqxtunb     z2.b, z2.h
    sqxtunb     z3.b, z3.h

    st1b        {z0.h}, p1, [x0]
    add         x0, x0, x2
    st1b        {z1.h}, p1, [x0]
    add         x0, x0, x2
    st1b        {z3.h}, p1, [x0]
    add         x0, x0, x2
    st1b        {z2.h}, p1, [x0]
    ret
endfunc
