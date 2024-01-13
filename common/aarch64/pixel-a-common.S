/****************************************************************************
 * pixel-a-common.S: aarch64 pixel metrics
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *          Janne Grunau <janne-x264@jannau.net>
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

// This file contains the NEON macros and constants that are intended to be used by
// the SVE/SVE2 functions as well

const mask_ac_4_8
.short 0, -1, -1, -1,  0, -1, -1, -1
.short 0, -1, -1, -1, -1, -1, -1, -1
endconst

.macro SUMSUB_ABCD s1, d1, s2, d2, a, b, c, d
    SUMSUB_AB   \s1, \d1, \a, \b
    SUMSUB_AB   \s2, \d2, \c, \d
.endm

.macro HADAMARD4_V r1, r2, r3, r4, t1, t2, t3, t4
    SUMSUB_ABCD \t1, \t2, \t3, \t4, \r1, \r2, \r3, \r4
    SUMSUB_ABCD \r1, \r3, \r2, \r4, \t1, \t3, \t2, \t4
.endm
