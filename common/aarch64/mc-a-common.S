/****************************************************************************
 * mc-a-common.S: aarch64 motion compensation
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *          Janne Grunau <janne-x264@jannau.net>
 *          Mans Rullgard <mans@mansr.com>
 *          Stefan Groenroos <stefan.gronroos@gmail.com>
 *          David Chen   <david.chen@myais.com.cn>
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

// This file contains the NEON macros and functions that are intended to be used by
// the SVE/SVE2 functions as well

#if BIT_DEPTH == 8

// 0 < weight < 64
.macro load_weights_add_add
    mov         w6,  w6
.endm

// weight > 64
.macro load_weights_add_sub
    neg         w7,  w7
.endm

// weight < 0
.macro load_weights_sub_add
    neg         w6,  w6
.endm

function pixel_avg_w4_neon
1:  subs        w9,  w9,  #2
    ld1         {v0.s}[0], [x2], x3
    ld1         {v2.s}[0], [x4], x5
    urhadd      v0.8b,  v0.8b,  v2.8b
    ld1         {v1.s}[0], [x2], x3
    ld1         {v3.s}[0], [x4], x5
    urhadd      v1.8b,  v1.8b,  v3.8b
    st1         {v0.s}[0], [x0], x1
    st1         {v1.s}[0], [x0], x1
    b.gt        1b
    ret
endfunc

#else // BIT_DEPTH == 10

#endif
