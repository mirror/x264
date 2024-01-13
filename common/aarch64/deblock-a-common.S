/*****************************************************************************
 * deblock-a-common.S: aarch64 deblocking
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
 *
 * Authors: Mans Rullgard <mans@mansr.com>
 *          Janne Grunau <janne-x264@jannau.net>
 *          David Chen <david.chen@myais.com.cn>
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

// This file contains the NEON macros that are intended to be used by
// the SVE/SVE2 functions as well

.macro h264_loop_filter_start
    cmp             w2,  #0
    ldr             w6,  [x4]
    ccmp            w3,  #0, #0, ne
    mov             v24.s[0], w6
    and             w8,  w6,  w6,  lsl #16
    b.eq            1f
    ands            w8,  w8,  w8,  lsl #8
    b.ge            2f
1:
    ret
2:
.endm
