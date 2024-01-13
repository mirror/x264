/*****************************************************************************
 * sad-a.S: loongarch sad functions
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Lu Wang <wanglu@loongson.cn>
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

#include "loongson_asm.S"
#include "loongson_util.S"

#if !HIGH_BIT_DEPTH


/* void x264_pixel_sad_x4_16x16_lasx(uint8_t *p_src, uint8_t *p_ref0,
 *                                   uint8_t *p_ref1, uint8_t *p_ref2,
 *                                   uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                   int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_16x16_lasx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1
    slli.d         t3,     a5,    2

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    0
    xvld           xr16,   a0,    32
    vld            vr4,    a1,    0
    vldx           vr8,    a1,    a5
    vld            vr5,    a2,    0
    vldx           vr9,    a2,    a5
    vld            vr6,    a3,    0
    vldx           vr10,   a3,    a5
    vld            vr7,    a4,    0
    vldx           vr11,   a4,    a5
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr12,   xr8,   xr8
    xvhaddw.hu.bu  xr13,   xr9,   xr9
    xvhaddw.hu.bu  xr14,   xr10,  xr10
    xvhaddw.hu.bu  xr15,   xr11,  xr11

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    vldx           vr4,    a1,    t1
    vldx           vr8,    a1,    t2
    vldx           vr5,    a2,    t1
    vldx           vr9,    a2,    t2
    vldx           vr6,    a3,    t1
    vldx           vr10,   a3,    t2
    vldx           vr7,    a4,    t1
    vldx           vr11,   a4,    t2
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr16,  xr4
    xvabsd.bu      xr9,    xr16,  xr5
    xvabsd.bu      xr10,   xr16,  xr6
    xvabsd.bu      xr11,   xr16,  xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    add.d          a4,     a4,    t3
    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    64
    xvld           xr16,   a0,    96
    vld            vr4,    a1,    0
    vldx           vr8,    a1,    a5
    vld            vr5,    a2,    0
    vldx           vr9,    a2,    a5
    vld            vr6,    a3,    0
    vldx           vr10,   a3,    a5
    vld            vr7,    a4,    0
    vldx           vr11,   a4,    a5
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    vldx           vr4,    a1,    t1
    vldx           vr8,    a1,    t2
    vldx           vr5,    a2,    t1
    vldx           vr9,    a2,    t2
    vldx           vr6,    a3,    t1
    vldx           vr10,   a3,    t2
    vldx           vr7,    a4,    t1
    vldx           vr11,   a4,    t2
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr16,  xr4
    xvabsd.bu      xr9,    xr16,  xr5
    xvabsd.bu      xr10,   xr16,  xr6
    xvabsd.bu      xr11,   xr16,  xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    add.d          a4,     a4,    t3
    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    128
    xvld           xr16,   a0,    160
    vld            vr4,    a1,    0
    vldx           vr8,    a1,    a5
    vld            vr5,    a2,    0
    vldx           vr9,    a2,    a5
    vld            vr6,    a3,    0
    vldx           vr10,   a3,    a5
    vld            vr7,    a4,    0
    vldx           vr11,   a4,    a5
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    vldx           vr4,    a1,    t1
    vldx           vr8,    a1,    t2
    vldx           vr5,    a2,    t1
    vldx           vr9,    a2,    t2
    vldx           vr6,    a3,    t1
    vldx           vr10,   a3,    t2
    vldx           vr7,    a4,    t1
    vldx           vr11,   a4,    t2
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr16,  xr4
    xvabsd.bu      xr9,    xr16,  xr5
    xvabsd.bu      xr10,   xr16,  xr6
    xvabsd.bu      xr11,   xr16,  xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    add.d          a4,     a4,    t3
    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    192
    xvld           xr16,   a0,    224
    vld            vr4,    a1,    0
    vldx           vr8,    a1,    a5
    vld            vr5,    a2,    0
    vldx           vr9,    a2,    a5
    vld            vr6,    a3,    0
    vldx           vr10,   a3,    a5
    vld            vr7,    a4,    0
    vldx           vr11,   a4,    a5
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    vldx           vr4,    a1,    t1
    vldx           vr8,    a1,    t2
    vldx           vr5,    a2,    t1
    vldx           vr9,    a2,    t2
    vldx           vr6,    a3,    t1
    vldx           vr10,   a3,    t2
    vldx           vr7,    a4,    t1
    vldx           vr11,   a4,    t2
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr16,  xr4
    xvabsd.bu      xr9,    xr16,  xr5
    xvabsd.bu      xr10,   xr16,  xr6
    xvabsd.bu      xr11,   xr16,  xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    xvori.b        xr17,   xr12,  0
    xvori.b        xr18,   xr13,  0
    xvpermi.q      xr12,   xr14,  0x02
    xvpermi.q      xr14,   xr17,  0x31
    xvpermi.q      xr13,   xr15,  0x02
    xvpermi.q      xr15,   xr18,  0x31
    xvadd.h        xr12,   xr12,  xr14
    xvadd.h        xr13,   xr13,  xr15
    xvhaddw.w.h    xr12,   xr12,  xr12
    xvhaddw.w.h    xr13,   xr13,  xr13
    xvhaddw.d.w    xr12,   xr12,  xr12
    xvhaddw.d.w    xr13,   xr13,  xr13
    xvhaddw.q.d    xr12,   xr12,  xr12
    xvhaddw.q.d    xr13,   xr13,  xr13
    xvpackev.w     xr13,   xr13,  xr12
    // Store data to p_sad_array
    xvstelm.d      xr13,   a6,    0,    0
    xvstelm.d      xr13,   a6,    8,    2
endfunc_x264

/* void x264_pixel_sad_x4_16x8_lasx(uint8_t *p_src, uint8_t *p_ref0,
 *                                  uint8_t *p_ref1, uint8_t *p_ref2,
 *                                  uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                  int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_16x8_lasx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1
    slli.d         t3,     a5,    2

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    0
    vld            vr4,    a1,    0
    vldx           vr8,    a1,    a5
    vld            vr5,    a2,    0
    vldx           vr9,    a2,    a5
    vld            vr6,    a3,    0
    vldx           vr10,   a3,    a5
    vld            vr7,    a4,    0
    vldx           vr11,   a4,    a5
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr12,   xr8,   xr8
    xvhaddw.hu.bu  xr13,   xr9,   xr9
    xvhaddw.hu.bu  xr14,   xr10,  xr10
    xvhaddw.hu.bu  xr15,   xr11,  xr11

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    32
    vldx           vr4,    a1,    t1
    vldx           vr8,    a1,    t2
    vldx           vr5,    a2,    t1
    vldx           vr9,    a2,    t2
    vldx           vr6,    a3,    t1
    vldx           vr10,   a3,    t2
    vldx           vr7,    a4,    t1
    vldx           vr11,   a4,    t2
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    add.d          a4,     a4,    t3
    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    64
    vld            vr4,    a1,    0
    vldx           vr8,    a1,    a5
    vld            vr5,    a2,    0
    vldx           vr9,    a2,    a5
    vld            vr6,    a3,    0
    vldx           vr10,   a3,    a5
    vld            vr7,    a4,    0
    vldx           vr11,   a4,    a5
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    xvld           xr3,    a0,    96
    vldx           vr4,    a1,    t1
    vldx           vr8,    a1,    t2
    vldx           vr5,    a2,    t1
    vldx           vr9,    a2,    t2
    vldx           vr6,    a3,    t1
    vldx           vr10,   a3,    t2
    vldx           vr7,    a4,    t1
    vldx           vr11,   a4,    t2
    xvpermi.q      xr4,    xr8,   0x02
    xvpermi.q      xr5,    xr9,   0x02
    xvpermi.q      xr6,    xr10,  0x02
    xvpermi.q      xr7,    xr11,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvadd.h        xr12,   xr12,  xr8
    xvadd.h        xr13,   xr13,  xr9
    xvadd.h        xr14,   xr14,  xr10
    xvadd.h        xr15,   xr15,  xr11

    xvori.b        xr17,   xr12,  0
    xvori.b        xr18,   xr13,  0
    xvpermi.q      xr12,   xr14,  0x02
    xvpermi.q      xr14,   xr17,  0x31
    xvpermi.q      xr13,   xr15,  0x02
    xvpermi.q      xr15,   xr18,  0x31
    xvadd.h        xr12,   xr12,  xr14
    xvadd.h        xr13,   xr13,  xr15
    xvhaddw.w.h    xr12,   xr12,  xr12
    xvhaddw.w.h    xr13,   xr13,  xr13
    xvhaddw.d.w    xr12,   xr12,  xr12
    xvhaddw.d.w    xr13,   xr13,  xr13
    xvhaddw.q.d    xr12,   xr12,  xr12
    xvhaddw.q.d    xr13,   xr13,  xr13
    xvpackev.w     xr13,   xr13,  xr12
    // Store data to p_sad_array
    xvstelm.d      xr13,   a6,    0,    0
    xvstelm.d      xr13,   a6,    8,    2
endfunc_x264

/* void x264_pixel_sad_x4_8x8_lasx(uint8_t *p_src, uint8_t *p_ref0,
 *                                 uint8_t *p_ref1, uint8_t *p_ref2,
 *                                 uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                 int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_8x8_lasx
    slli.d         t1,     a5,    1
    add.d          t2,     t1,    a5
    slli.d         t3,     a5,    2

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f14, f18
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f15, f19
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f16, f20
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f17, f21
    vilvl.d        vr4,    vr5,   vr4
    vilvl.d        vr6,    vr7,   vr6
    vilvl.d        vr8,    vr9,   vr8
    vilvl.d        vr10,   vr11,  vr10
    vilvl.d        vr14,   vr15,  vr14
    vilvl.d        vr16,   vr17,  vr16
    vilvl.d        vr18,   vr19,  vr18
    vilvl.d        vr20,   vr21,  vr20
    xvpermi.q      xr4,    xr6,   0x02
    xvpermi.q      xr8,    xr10,  0x02
    xvpermi.q      xr14,   xr16,  0x02
    xvpermi.q      xr18,   xr20,  0x02
    // Calculate the absolute value of the difference
    xvldrepl.d     xr3,    a0,    0
    xvabsd.bu      xr5,    xr3,   xr4
    xvldrepl.d     xr3,    a0,    16
    xvabsd.bu      xr9,    xr3,   xr8
    xvldrepl.d     xr3,    a0,    32
    xvabsd.bu      xr10,   xr3,   xr14
    xvldrepl.d     xr3,    a0,    48
    xvabsd.bu      xr11,   xr3,   xr18
    xvaddwev.h.bu  xr0,    xr5,   xr9
    xvaddwod.h.bu  xr1,    xr5,   xr9
    xvaddwev.h.bu  xr2,    xr10,  xr11
    xvaddwod.h.bu  xr22,   xr10,  xr11

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    add.d          a4,     a4,    t3
    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f14, f18
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f15, f19
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f16, f20
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f17, f21
    vilvl.d        vr4,    vr5,   vr4
    vilvl.d        vr6,    vr7,   vr6
    vilvl.d        vr8,    vr9,   vr8
    vilvl.d        vr10,   vr11,  vr10
    vilvl.d        vr14,   vr15,  vr14
    vilvl.d        vr16,   vr17,  vr16
    vilvl.d        vr18,   vr19,  vr18
    vilvl.d        vr20,   vr21,  vr20
    xvpermi.q      xr4,    xr6,   0x02
    xvpermi.q      xr8,    xr10,  0x02
    xvpermi.q      xr14,   xr16,  0x02
    xvpermi.q      xr18,   xr20,  0x02
    // Calculate the absolute value of the difference
    xvldrepl.d     xr3,    a0,    64
    xvabsd.bu      xr5,    xr3,   xr4
    xvldrepl.d     xr3,    a0,    80
    xvabsd.bu      xr9,    xr3,   xr8
    xvldrepl.d     xr3,    a0,    96
    xvabsd.bu      xr10,   xr3,   xr14
    xvldrepl.d     xr3,    a0,    112
    xvabsd.bu      xr11,   xr3,   xr18
    xvaddwev.h.bu  xr12,   xr5,   xr9
    xvaddwod.h.bu  xr13,   xr5,   xr9
    xvaddwev.h.bu  xr14,   xr10,  xr11
    xvaddwod.h.bu  xr15,   xr10,  xr11
    xvadd.h        xr5,    xr0,   xr12
    xvadd.h        xr9,    xr1,   xr13
    xvadd.h        xr10,   xr2,   xr14
    xvadd.h        xr11,   xr22,  xr15
    xvadd.h        xr5,    xr5,   xr9
    xvadd.h        xr10,   xr10,  xr11
    xvadd.h        xr10,   xr10,  xr5
    xvhaddw.wu.hu  xr10,   xr10,  xr10
    xvhaddw.du.wu  xr10,   xr10,  xr10
    xvpermi.q      xr5,    xr10,  0x01
    xvpickev.w     xr10,   xr5,   xr10
    // Store data to p_sad_array
    vst            vr10,   a6,    0
endfunc_x264

/* void x264_pixel_sad_x4_8x4_lasx(uint8_t *p_src, uint8_t *p_ref0,
 *                                 uint8_t *p_ref1, uint8_t *p_ref2,
 *                                 uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                 int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_8x4_lasx
    slli.d         t1,     a5,    1
    add.d          t2,     t1,    a5

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    fld.d          f2,     a0,    0
    fld.d          f3,     a0,    16
    fld.d          f12,    a0,    32
    fld.d          f13,    a0,    48
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f14, f18
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f15, f19
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f16, f20
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f17, f21

    vilvl.d        vr3,    vr3,   vr2
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr7,    vr11,  vr7
    vilvl.d        vr13,   vr13,  vr12
    vilvl.d        vr14,   vr18,  vr14
    vilvl.d        vr15,   vr19,  vr15
    vilvl.d        vr16,   vr20,  vr16
    vilvl.d        vr17,   vr21,  vr17
    xvpermi.q      xr3,    xr13,  0x02
    xvpermi.q      xr4,    xr16,  0x02
    xvpermi.q      xr5,    xr17,  0x02
    xvpermi.q      xr6,    xr14,  0x02
    xvpermi.q      xr7,    xr15,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr8,    xr3,   xr4
    xvabsd.bu      xr9,    xr3,   xr5
    xvabsd.bu      xr10,   xr3,   xr6
    xvabsd.bu      xr11,   xr3,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvpermi.d      xr10,   xr10,  0x4e
    xvpermi.d      xr11,   xr11,  0x4e
    xvadd.h        xr8,    xr8,   xr10
    xvadd.h        xr9,    xr9,   xr11
    xvhaddw.w.h    xr8,    xr8,   xr8
    xvhaddw.w.h    xr9,    xr9,   xr9
    xvhaddw.d.w    xr8,    xr8,   xr8
    xvhaddw.d.w    xr9,    xr9,   xr9
    xvhaddw.q.d    xr8,    xr8,   xr8
    xvhaddw.q.d    xr9,    xr9,   xr9
    xvpackev.w     xr9,    xr9,   xr8

    // Store data to p_sad_array
    xvstelm.d      xr9,    a6,    0,    0
    xvstelm.d      xr9,    a6,    8,    2
endfunc_x264

/* void x264_pixel_sad_x4_4x4_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_4x4_lsx
    slli.d         t0,     a5,    1
    add.d          t1,     a5,    t0
    slli.d         t2,     a5,    2

    // Load data from p_src, p_ref0, p_ref1, p_ref2 and p_ref3
    fld.s          f2,     a0,    0
    fld.s          f3,     a0,    16
    fld.s          f4,     a1,    0
    fldx.s         f8,     a1,    a5
    fld.s          f5,     a2,    0
    fldx.s         f9,     a2,    a5
    fld.s          f6,     a3,    0
    fldx.s         f10,    a3,    a5
    fld.s          f7,     a4,    0
    fldx.s         f11,    a4,    a5
    vilvl.w        vr3,    vr3,   vr2
    vilvl.w        vr4,    vr8,   vr4
    vilvl.w        vr5,    vr9,   vr5
    vilvl.w        vr6,    vr10,  vr6
    vilvl.w        vr7,    vr11,  vr7

    fld.s          f2,     a0,    32
    fld.s          f0,     a0,    48
    fldx.s         f8,     a1,    t0
    fldx.s         f12,    a1,    t1
    fldx.s         f9,     a2,    t0
    fldx.s         f13,    a2,    t1
    fldx.s         f10,    a3,    t0
    fldx.s         f14,    a3,    t1
    fldx.s         f11,    a4,    t0
    fldx.s         f15,    a4,    t1
    vilvl.w        vr2,    vr0,   vr2
    vilvl.w        vr8,    vr12,  vr8
    vilvl.w        vr9,    vr13,  vr9
    vilvl.w        vr10,   vr14,  vr10
    vilvl.w        vr11,   vr15,  vr11
    vilvl.d        vr3,    vr2,   vr3
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr7,    vr11,  vr7

    // Calculate the absolute value of the difference
    vabsd.bu       vr8,    vr3,   vr4
    vabsd.bu       vr9,    vr3,   vr5
    vabsd.bu       vr10,   vr3,   vr6
    vabsd.bu       vr11,   vr3,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.wu.hu   vr8,    vr8,   vr8
    vhaddw.wu.hu   vr9,    vr9,   vr9
    vhaddw.wu.hu   vr10,   vr10,  vr10
    vhaddw.wu.hu   vr11,   vr11,  vr11
    vhaddw.du.wu   vr8,    vr8,   vr8
    vhaddw.du.wu   vr9,    vr9,   vr9
    vhaddw.du.wu   vr10,   vr10,  vr10
    vhaddw.du.wu   vr11,   vr11,  vr11
    vhaddw.qu.du   vr8,    vr8,   vr8
    vhaddw.qu.du   vr9,    vr9,   vr9
    vhaddw.qu.du   vr10,   vr10,  vr10
    vhaddw.qu.du   vr11,   vr11,  vr11

    // Store data to p_sad_array
    vstelm.w       vr8,    a6,    0,  0
    vstelm.w       vr9,    a6,    4,  0
    vstelm.w       vr10,   a6,    8,  0
    vstelm.w       vr11,   a6,   12,  0
endfunc_x264

/* void x264_pixel_sad_x3_16x16_lasx(uint8_t *p_src, uint8_t *p_ref0,
 *                                   uint8_t *p_ref1, uint8_t *p_ref2,
 *                                   intptr_t i_ref_stride,
 *                                   int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_16x16_lasx
    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1
    slli.d         t3,     a4,    2

    xvld           xr2,    a0,    0
    xvld           xr3,    a0,    32
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    xvpermi.q      xr4,    xr7,   0x02
    xvpermi.q      xr5,    xr8,   0x02
    xvpermi.q      xr6,    xr9,   0x02
    xvpermi.q      xr10,   xr13,  0x02
    xvpermi.q      xr11,   xr14,  0x02
    xvpermi.q      xr12,   xr15,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr7,    xr2,   xr4
    xvabsd.bu      xr8,    xr2,   xr5
    xvabsd.bu      xr9,    xr2,   xr6
    xvabsd.bu      xr10,   xr3,   xr10
    xvabsd.bu      xr11,   xr3,   xr11
    xvabsd.bu      xr12,   xr3,   xr12
    xvhaddw.hu.bu  xr16,   xr7,   xr7
    xvhaddw.hu.bu  xr17,   xr8,   xr8
    xvhaddw.hu.bu  xr18,   xr9,   xr9
    xvhaddw.hu.bu  xr19,   xr10,  xr10
    xvhaddw.hu.bu  xr20,   xr11,  xr11
    xvhaddw.hu.bu  xr21,   xr12,  xr12

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    xvld           xr2,    a0,    64
    xvld           xr3,    a0,    96
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    xvpermi.q      xr4,    xr7,   0x02
    xvpermi.q      xr5,    xr8,   0x02
    xvpermi.q      xr6,    xr9,   0x02
    xvpermi.q      xr10,   xr13,  0x02
    xvpermi.q      xr11,   xr14,  0x02
    xvpermi.q      xr12,   xr15,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr7,    xr2,   xr4
    xvabsd.bu      xr8,    xr2,   xr5
    xvabsd.bu      xr9,    xr2,   xr6
    xvabsd.bu      xr10,   xr3,   xr10
    xvabsd.bu      xr11,   xr3,   xr11
    xvabsd.bu      xr12,   xr3,   xr12
    xvhaddw.hu.bu  xr7,    xr7,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvhaddw.hu.bu  xr12,   xr12,  xr12
    xvadd.h        xr16,   xr16,  xr7
    xvadd.h        xr17,   xr17,  xr8
    xvadd.h        xr18,   xr18,  xr9
    xvadd.h        xr19,   xr19,  xr10
    xvadd.h        xr20,   xr20,  xr11
    xvadd.h        xr21,   xr21,  xr12

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    xvld           xr2,    a0,    128
    xvld           xr3,    a0,    160
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    xvpermi.q      xr4,    xr7,   0x02
    xvpermi.q      xr5,    xr8,   0x02
    xvpermi.q      xr6,    xr9,   0x02
    xvpermi.q      xr10,   xr13,  0x02
    xvpermi.q      xr11,   xr14,  0x02
    xvpermi.q      xr12,   xr15,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr7,    xr2,   xr4
    xvabsd.bu      xr8,    xr2,   xr5
    xvabsd.bu      xr9,    xr2,   xr6
    xvabsd.bu      xr10,   xr3,   xr10
    xvabsd.bu      xr11,   xr3,   xr11
    xvabsd.bu      xr12,   xr3,   xr12
    xvhaddw.hu.bu  xr7,    xr7,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvhaddw.hu.bu  xr12,   xr12,  xr12
    xvadd.h        xr16,   xr16,  xr7
    xvadd.h        xr17,   xr17,  xr8
    xvadd.h        xr18,   xr18,  xr9
    xvadd.h        xr19,   xr19,  xr10
    xvadd.h        xr20,   xr20,  xr11
    xvadd.h        xr21,   xr21,  xr12

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    xvld           xr2,    a0,    192
    xvld           xr3,    a0,    224
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    xvpermi.q      xr4,    xr7,   0x02
    xvpermi.q      xr5,    xr8,   0x02
    xvpermi.q      xr6,    xr9,   0x02
    xvpermi.q      xr10,   xr13,  0x02
    xvpermi.q      xr11,   xr14,  0x02
    xvpermi.q      xr12,   xr15,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu      xr7,    xr2,   xr4
    xvabsd.bu      xr8,    xr2,   xr5
    xvabsd.bu      xr9,    xr2,   xr6
    xvabsd.bu      xr10,   xr3,   xr10
    xvabsd.bu      xr11,   xr3,   xr11
    xvabsd.bu      xr12,   xr3,   xr12
    xvhaddw.hu.bu  xr7,    xr7,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvhaddw.hu.bu  xr12,   xr12,  xr12
    xvadd.h        xr16,   xr16,  xr7
    xvadd.h        xr17,   xr17,  xr8
    xvadd.h        xr18,   xr18,  xr9
    xvadd.h        xr19,   xr19,  xr10
    xvadd.h        xr20,   xr20,  xr11
    xvadd.h        xr21,   xr21,  xr12
    xvadd.h        xr11,   xr16,  xr19
    xvadd.h        xr12,   xr17,  xr20
    xvadd.h        xr13,   xr18,  xr21

    xvhaddw.wu.hu  xr11,   xr11,  xr11
    xvhaddw.wu.hu  xr12,   xr12,  xr12
    xvhaddw.wu.hu  xr13,   xr13,  xr13
    xvhaddw.du.wu  xr11,   xr11,  xr11
    xvhaddw.du.wu  xr12,   xr12,  xr12
    xvhaddw.du.wu  xr13,   xr13,  xr13
    xvhaddw.qu.du  xr11,   xr11,  xr11
    xvhaddw.qu.du  xr12,   xr12,  xr12
    xvhaddw.qu.du  xr13,   xr13,  xr13
    xvpickve.w     xr17,   xr11,  4
    xvpickve.w     xr18,   xr12,  4
    xvpickve.w     xr19,   xr13,  4
    xvadd.w        xr11,   xr11,  xr17
    xvadd.w        xr12,   xr12,  xr18
    xvadd.w        xr13,   xr13,  xr19

    // Store data to p_sad_array
    vstelm.w       vr11,   a5,    0,  0
    vstelm.w       vr12,   a5,    4,  0
    vstelm.w       vr13,   a5,    8,  0
endfunc_x264

/* void x264_pixel_sad_x3_16x8_lasx(uint8_t *p_src, uint8_t *p_ref0,
 *                                  uint8_t *p_ref1, uint8_t *p_ref2,
 *                                  intptr_t i_ref_stride,
 *                                  int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_16x8_lasx
    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1
    slli.d         t3,     a4,    2

    xvld           xr2,    a0,    0
    xvld           xr3,    a0,    32
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    xvpermi.q      xr4,    xr7,   0x02
    xvpermi.q      xr5,    xr8,   0x02
    xvpermi.q      xr6,    xr9,   0x02
    xvpermi.q      xr10,   xr13,  0x02
    xvpermi.q      xr11,   xr14,  0x02
    xvpermi.q      xr12,   xr15,  0x02

    // Calculate the absolute value of the difference
    xvabsd.bu      xr7,    xr2,   xr4
    xvabsd.bu      xr8,    xr2,   xr5
    xvabsd.bu      xr9,    xr2,   xr6
    xvabsd.bu      xr10,   xr3,   xr10
    xvabsd.bu      xr11,   xr3,   xr11
    xvabsd.bu      xr12,   xr3,   xr12
    xvhaddw.hu.bu  xr16,   xr7,   xr7
    xvhaddw.hu.bu  xr17,   xr8,   xr8
    xvhaddw.hu.bu  xr18,   xr9,   xr9
    xvhaddw.hu.bu  xr19,   xr10,  xr10
    xvhaddw.hu.bu  xr20,   xr11,  xr11
    xvhaddw.hu.bu  xr21,   xr12,  xr12

    add.d          a1,     a1,    t3
    add.d          a2,     a2,    t3
    add.d          a3,     a3,    t3
    xvld           xr2,    a0,    64
    xvld           xr3,    a0,    96
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    xvpermi.q      xr4,    xr7,   0x02
    xvpermi.q      xr5,    xr8,   0x02
    xvpermi.q      xr6,    xr9,   0x02
    xvpermi.q      xr10,   xr13,  0x02
    xvpermi.q      xr11,   xr14,  0x02
    xvpermi.q      xr12,   xr15,  0x02

    // Calculate the absolute value of the difference
    xvabsd.bu      xr7,    xr2,   xr4
    xvabsd.bu      xr8,    xr2,   xr5
    xvabsd.bu      xr9,    xr2,   xr6
    xvabsd.bu      xr10,   xr3,   xr10
    xvabsd.bu      xr11,   xr3,   xr11
    xvabsd.bu      xr12,   xr3,   xr12
    xvhaddw.hu.bu  xr7,    xr7,   xr7
    xvhaddw.hu.bu  xr8,    xr8,   xr8
    xvhaddw.hu.bu  xr9,    xr9,   xr9
    xvhaddw.hu.bu  xr10,   xr10,  xr10
    xvhaddw.hu.bu  xr11,   xr11,  xr11
    xvhaddw.hu.bu  xr12,   xr12,  xr12
    xvadd.h        xr16,   xr16,  xr7
    xvadd.h        xr17,   xr17,  xr8
    xvadd.h        xr18,   xr18,  xr9
    xvadd.h        xr19,   xr19,  xr10
    xvadd.h        xr20,   xr20,  xr11
    xvadd.h        xr21,   xr21,  xr12
    xvadd.h        xr11,   xr16,  xr19
    xvadd.h        xr12,   xr17,  xr20
    xvadd.h        xr13,   xr18,  xr21

    xvhaddw.wu.hu  xr11,   xr11,  xr11
    xvhaddw.wu.hu  xr12,   xr12,  xr12
    xvhaddw.wu.hu  xr13,   xr13,  xr13
    xvhaddw.du.wu  xr11,   xr11,  xr11
    xvhaddw.du.wu  xr12,   xr12,  xr12
    xvhaddw.du.wu  xr13,   xr13,  xr13
    xvhaddw.qu.du  xr11,   xr11,  xr11
    xvhaddw.qu.du  xr12,   xr12,  xr12
    xvhaddw.qu.du  xr13,   xr13,  xr13
    xvpickve.w     xr17,   xr11,  4
    xvpickve.w     xr18,   xr12,  4
    xvpickve.w     xr19,   xr13,  4
    xvadd.w        xr11,   xr11,  xr17
    xvadd.w        xr12,   xr12,  xr18
    xvadd.w        xr13,   xr13,  xr19

    // Store data to p_sad_array
    vstelm.w       vr11,   a5,    0,  0
    vstelm.w       vr12,   a5,    4,  0
    vstelm.w       vr13,   a5,    8,  0
endfunc_x264

/* void x264_pixel_sad_x3_4x4_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                intptr_t i_ref_stride,
 *                                int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_4x4_lsx
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.s          f3,     a0,    0
    fld.s          f7,     a0,    16
    fld.s          f11,    a0,    32
    fld.s          f15,    a0,    48
    FLDS_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDS_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDS_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18

    vilvl.w        vr3,    vr7,   vr3
    vilvl.w        vr4,    vr8,   vr4
    vilvl.w        vr5,    vr9,   vr5
    vilvl.w        vr6,    vr10,  vr6
    vilvl.w        vr11,   vr15,  vr11
    vilvl.w        vr12,   vr16,  vr12
    vilvl.w        vr13,   vr17,  vr13
    vilvl.w        vr14,   vr18,  vr14
    vilvl.d        vr3,    vr11,  vr3
    vilvl.d        vr4,    vr12,  vr4
    vilvl.d        vr5,    vr13,  vr5
    vilvl.d        vr6,    vr14,  vr6

    // Calculate the absolute value of the difference
    vabsd.bu       vr7,    vr3,   vr4
    vabsd.bu       vr8,    vr3,   vr5
    vabsd.bu       vr9,    vr3,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.wu.hu   vr7,    vr7,   vr7
    vhaddw.wu.hu   vr8,    vr8,   vr8
    vhaddw.wu.hu   vr9,    vr9,   vr9
    vhaddw.du.wu   vr7,    vr7,   vr7
    vhaddw.du.wu   vr8,    vr8,   vr8
    vhaddw.du.wu   vr9,    vr9,   vr9
    vhaddw.qu.du   vr7,    vr7,   vr7
    vhaddw.qu.du   vr8,    vr8,   vr8
    vhaddw.qu.du   vr9,    vr9,   vr9

    // Store data to p_sad_array
    vstelm.w       vr7,    a5,    0,  0
    vstelm.w       vr8,    a5,    4,  0
    vstelm.w       vr9,    a5,    8,  0
endfunc_x264

/* int32_t x264_pixel_sad_8x4_lasx(uint8_t *p_src, intptr_t i_src_stride,
 *                                 uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_8x4_lasx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    // Load data from p_src and p_ref
    FLDD_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDD_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.d         vr3,   vr5,  vr3
    vilvl.d         vr4,   vr6,  vr4
    vilvl.d         vr7,   vr9,  vr7
    vilvl.d         vr8,   vr10, vr8
    xvpermi.q       xr3,   xr7,  0x02
    xvpermi.q       xr4,   xr8,  0x02
    // Calculate the absolute value of the difference
    xvabsd.bu       xr5,   xr3,  xr4
    xvhaddw.hu.bu   xr6,   xr5,  xr5
    xvhaddw.wu.hu   xr6,   xr6,  xr6
    xvhaddw.du.wu   xr6,   xr6,  xr6
    xvhaddw.qu.du   xr6,   xr6,  xr6

    xvpickve2gr.wu  t2,    xr6,  0
    xvpickve2gr.wu  t3,    xr6,  4
    add.d           a0,    t2,   t3
endfunc_x264

/* int32_t x264_pixel_sad_4x4_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_4x4_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    // Load data from p_src and p_ref
    FLDS_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDS_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.w         vr3,   vr5,  vr3
    vilvl.w         vr4,   vr6,  vr4
    vilvl.w         vr7,   vr9,  vr7
    vilvl.w         vr8,   vr10, vr8
    vilvl.d         vr3,   vr7,  vr3
    vilvl.d         vr4,   vr8,  vr4

    // Calculate the absolute value of the difference
    vabsd.bu        vr5,   vr3,  vr4
    vhaddw.hu.bu    vr6,   vr5,  vr5
    vhaddw.wu.hu    vr6,   vr6,  vr6
    vhaddw.du.wu    vr6,   vr6,  vr6
    vhaddw.qu.du    vr6,   vr6,  vr6
    vpickve2gr.wu   a0,    vr6,  0
endfunc_x264

/* int32_t x264_pixel_sad_4x8_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_4x8_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    // Load data from p_src and p_ref
    FLDS_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDS_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.w         vr3,   vr5,  vr3
    vilvl.w         vr4,   vr6,  vr4
    vilvl.w         vr7,   vr9,  vr7
    vilvl.w         vr8,   vr10, vr8
    vilvl.d         vr3,   vr7,  vr3
    vilvl.d         vr4,   vr8,  vr4
    vabsd.bu        vr11,  vr3,  vr4
    vhaddw.hu.bu    vr11,  vr11, vr11

    alsl.d          a0,    a1,   a0,  2
    alsl.d          a2,    a3,   a2,  2
    FLDS_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDS_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.w         vr3,   vr5,  vr3
    vilvl.w         vr4,   vr6,  vr4
    vilvl.w         vr7,   vr9,  vr7
    vilvl.w         vr8,   vr10, vr8
    vilvl.d         vr3,   vr7,  vr3
    vilvl.d         vr4,   vr8,  vr4
    vabsd.bu        vr5,   vr3,  vr4
    vhaddw.hu.bu    vr5,   vr5,  vr5

    vadd.h          vr6,   vr11, vr5
    vhaddw.wu.hu    vr6,   vr6,  vr6
    vhaddw.du.wu    vr6,   vr6,  vr6
    vhaddw.qu.du    vr6,   vr6,  vr6
    vpickve2gr.wu   a0,    vr6,  0
endfunc_x264

/* int32_t x264_pixel_sad_4x16_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                 uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_4x16_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    // Load data from p_src and p_ref
    FLDS_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDS_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.w         vr3,   vr5,  vr3
    vilvl.w         vr4,   vr6,  vr4
    vilvl.w         vr7,   vr9,  vr7
    vilvl.w         vr8,   vr10, vr8
    vilvl.d         vr3,   vr7,  vr3
    vilvl.d         vr4,   vr8,  vr4
    vabsd.bu        vr11,  vr3,  vr4
    vhaddw.hu.bu    vr11,  vr11, vr11

.rept 3
    alsl.d          a0,    a1,   a0,  2
    alsl.d          a2,    a3,   a2,  2
    FLDS_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDS_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.w         vr3,   vr5,  vr3
    vilvl.w         vr4,   vr6,  vr4
    vilvl.w         vr7,   vr9,  vr7
    vilvl.w         vr8,   vr10, vr8
    vilvl.d         vr3,   vr7,  vr3
    vilvl.d         vr4,   vr8,  vr4
    vabsd.bu        vr12,  vr3,  vr4
    vhaddw.hu.bu    vr12,  vr12, vr12
    vadd.h          vr11,  vr11, vr12
.endr

    vhaddw.wu.hu    vr11,  vr11, vr11
    vhaddw.du.wu    vr11,  vr11, vr11
    vhaddw.qu.du    vr11,  vr11, vr11
    vpickve2gr.wu   a0,    vr11, 0
endfunc_x264

/* int32_t x264_pixel_sad_8x4_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_8x4_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    FLDD_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDD_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.d         vr3,   vr5,  vr3
    vilvl.d         vr7,   vr9,  vr7
    vilvl.d         vr4,   vr6,  vr4
    vilvl.d         vr8,   vr10, vr8
    vabsd.bu        vr11,  vr3,  vr4
    vabsd.bu        vr12,  vr7,  vr8
    vhaddw.hu.bu    vr11,  vr11, vr11
    vhaddw.hu.bu    vr12,  vr12, vr12
    vadd.h          vr6,   vr11, vr12
    vhaddw.wu.hu    vr6,   vr6,  vr6
    vhaddw.du.wu    vr6,   vr6,  vr6
    vhaddw.qu.du    vr6,   vr6,  vr6
    vpickve2gr.wu   a0,    vr6,  0
endfunc_x264

/* int32_t x264_pixel_sad_8x8_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_8x8_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    FLDD_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDD_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.d         vr3,   vr5,  vr3
    vilvl.d         vr7,   vr9,  vr7
    vilvl.d         vr4,   vr6,  vr4
    vilvl.d         vr8,   vr10, vr8
    vabsd.bu        vr11,  vr3,  vr4
    vabsd.bu        vr12,  vr7,  vr8
    vhaddw.hu.bu    vr11,  vr11, vr11
    vhaddw.hu.bu    vr12,  vr12, vr12
    vadd.h          vr13,  vr11, vr12

    alsl.d          a0,    a1,   a0,  2
    alsl.d          a2,    a3,   a2,  2
    FLDD_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDD_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.d         vr3,   vr5,  vr3
    vilvl.d         vr7,   vr9,  vr7
    vilvl.d         vr4,   vr6,  vr4
    vilvl.d         vr8,   vr10, vr8
    vabsd.bu        vr11,  vr3,  vr4
    vabsd.bu        vr12,  vr7,  vr8
    vhaddw.hu.bu    vr11,  vr11, vr11
    vhaddw.hu.bu    vr12,  vr12, vr12
    vadd.h          vr6,   vr11, vr12
    vadd.h          vr6,   vr6,  vr13
    vhaddw.wu.hu    vr6,   vr6,  vr6
    vhaddw.du.wu    vr6,   vr6,  vr6
    vhaddw.qu.du    vr6,   vr6,  vr6
    vpickve2gr.wu   a0,    vr6,  0
endfunc_x264

/* int32_t x264_pixel_sad_8x16_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_8x16_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    FLDD_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDD_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.d         vr3,   vr5,  vr3
    vilvl.d         vr7,   vr9,  vr7
    vilvl.d         vr4,   vr6,  vr4
    vilvl.d         vr8,   vr10, vr8
    vabsd.bu        vr11,  vr3,  vr4
    vabsd.bu        vr12,  vr7,  vr8
    vhaddw.hu.bu    vr11,  vr11, vr11
    vhaddw.hu.bu    vr12,  vr12, vr12
    vadd.h          vr13,  vr11, vr12

.rept 3
    alsl.d          a0,    a1,   a0,  2
    alsl.d          a2,    a3,   a2,  2
    FLDD_LOADX_4    a0,    a1,   t1,  t3,  f3, f5, f7, f9
    FLDD_LOADX_4    a2,    a3,   t2,  t4,  f4, f6, f8, f10
    vilvl.d         vr3,   vr5,  vr3
    vilvl.d         vr7,   vr9,  vr7
    vilvl.d         vr4,   vr6,  vr4
    vilvl.d         vr8,   vr10, vr8
    vabsd.bu        vr11,  vr3,  vr4
    vabsd.bu        vr12,  vr7,  vr8
    vhaddw.hu.bu    vr11,  vr11, vr11
    vhaddw.hu.bu    vr12,  vr12, vr12
    vadd.h          vr14,  vr11, vr12
    vadd.h          vr13,  vr13, vr14
.endr
    vhaddw.wu.hu    vr13,  vr13,  vr13
    vhaddw.du.wu    vr13,  vr13,  vr13
    vhaddw.qu.du    vr13,  vr13,  vr13
    vpickve2gr.wu   a0,    vr13,  0
endfunc_x264

/* int32_t x264_pixel_sad_16x8_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                 uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_16x8_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    LSX_LOADX_4     a0,    a1,   t1, t3, vr0, vr1, vr2, vr3
    LSX_LOADX_4     a2,    a3,   t2, t4, vr4, vr5, vr6, vr7
    vabsd.bu        vr8,   vr0,  vr4
    vabsd.bu        vr9,   vr1,  vr5
    vabsd.bu        vr10,  vr2,  vr6
    vabsd.bu        vr11,  vr3,  vr7
    vhaddw.hu.bu    vr8,   vr8,  vr8
    vhaddw.hu.bu    vr9,   vr9,  vr9
    vhaddw.hu.bu    vr10,  vr10, vr10
    vhaddw.hu.bu    vr11,  vr11, vr11
    vadd.h          vr8,   vr8,  vr9
    vadd.h          vr9,   vr10, vr11
    vadd.h          vr14,  vr8,  vr9

    alsl.d          a0,    a1,   a0,   2
    alsl.d          a2,    a3,   a2,   2
    LSX_LOADX_4     a0,    a1,   t1, t3, vr0, vr1, vr2, vr3
    LSX_LOADX_4     a2,    a3,   t2, t4, vr4, vr5, vr6, vr7
    vabsd.bu        vr8,   vr0,  vr4
    vabsd.bu        vr9,   vr1,  vr5
    vabsd.bu        vr10,  vr2,  vr6
    vabsd.bu        vr11,  vr3,  vr7
    vhaddw.hu.bu    vr8,   vr8,  vr8
    vhaddw.hu.bu    vr9,   vr9,  vr9
    vhaddw.hu.bu    vr10,  vr10, vr10
    vhaddw.hu.bu    vr11,  vr11, vr11
    vadd.h          vr8,   vr8,  vr9
    vadd.h          vr9,   vr10, vr11
    vadd.h          vr12,  vr8,  vr9

    vadd.h          vr13,  vr12, vr14
    vhaddw.wu.hu    vr13,  vr13, vr13
    vhaddw.du.wu    vr13,  vr13, vr13
    vhaddw.qu.du    vr13,  vr13, vr13
    vpickve2gr.wu   a0,    vr13, 0
endfunc_x264

/* int32_t x264_pixel_sad_16x16_lsx(uint8_t *p_src, intptr_t i_src_stride,
 *                                  uint8_t *p_ref, intptr_t i_ref_stride)
 */
function_x264 pixel_sad_16x16_lsx
    slli.d          t1,    a1,   1
    slli.d          t2,    a3,   1
    add.d           t3,    a1,   t1
    add.d           t4,    a3,   t2

    LSX_LOADX_4     a0,    a1,   t1, t3, vr0, vr1, vr2, vr3
    LSX_LOADX_4     a2,    a3,   t2, t4, vr4, vr5, vr6, vr7
    vabsd.bu        vr8,   vr0,  vr4
    vabsd.bu        vr9,   vr1,  vr5
    vabsd.bu        vr10,  vr2,  vr6
    vabsd.bu        vr11,  vr3,  vr7
    vhaddw.hu.bu    vr8,   vr8,  vr8
    vhaddw.hu.bu    vr9,   vr9,  vr9
    vhaddw.hu.bu    vr10,  vr10, vr10
    vhaddw.hu.bu    vr11,  vr11, vr11
    vadd.h          vr8,   vr8,  vr9
    vadd.h          vr9,   vr10, vr11
    vadd.h          vr13,  vr8,  vr9

.rept 3
    alsl.d          a0,    a1,   a0,   2
    alsl.d          a2,    a3,   a2,   2
    LSX_LOADX_4     a0,    a1,   t1, t3, vr0, vr1, vr2, vr3
    LSX_LOADX_4     a2,    a3,   t2, t4, vr4, vr5, vr6, vr7
    vabsd.bu        vr8,   vr0,  vr4
    vabsd.bu        vr9,   vr1,  vr5
    vabsd.bu        vr10,  vr2,  vr6
    vabsd.bu        vr11,  vr3,  vr7
    vhaddw.hu.bu    vr8,   vr8,  vr8
    vhaddw.hu.bu    vr9,   vr9,  vr9
    vhaddw.hu.bu    vr10,  vr10, vr10
    vhaddw.hu.bu    vr11,  vr11, vr11
    vadd.h          vr8,   vr8,  vr9
    vadd.h          vr9,   vr10, vr11
    vadd.h          vr12,  vr8,  vr9
    vadd.h          vr13,  vr12, vr13
.endr

    vhaddw.wu.hu    vr13,  vr13, vr13
    vhaddw.du.wu    vr13,  vr13, vr13
    vhaddw.qu.du    vr13,  vr13, vr13
    vpickve2gr.wu   a0,    vr13, 0
endfunc_x264

/*
 * void x264_pixel_sad_x3_4x8_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                intptr_t i_ref_stride,
 *                                int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_4x8_lsx
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.s          f3,     a0,    0
    fld.s          f7,     a0,    16
    fld.s          f11,    a0,    32
    fld.s          f15,    a0,    48
    FLDS_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDS_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDS_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18
    vilvl.w        vr3,    vr7,   vr3
    vilvl.w        vr4,    vr8,   vr4
    vilvl.w        vr5,    vr9,   vr5
    vilvl.w        vr6,    vr10,  vr6
    vilvl.w        vr11,   vr15,  vr11
    vilvl.w        vr12,   vr16,  vr12
    vilvl.w        vr13,   vr17,  vr13
    vilvl.w        vr14,   vr18,  vr14
    vilvl.d        vr3,    vr11,  vr3
    vilvl.d        vr4,    vr12,  vr4
    vilvl.d        vr5,    vr13,  vr5
    vilvl.d        vr6,    vr14,  vr6
    vabsd.bu       vr0,    vr3,   vr4
    vabsd.bu       vr1,    vr3,   vr5
    vabsd.bu       vr2,    vr3,   vr6

    alsl.d         a1,     a4,    a1,   2
    alsl.d         a2,     a4,    a2,   2
    alsl.d         a3,     a4,    a3,   2
    fld.s          f3,     a0,    64
    fld.s          f7,     a0,    80
    fld.s          f11,    a0,    96
    fld.s          f15,    a0,    112
    FLDS_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDS_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDS_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18
    vilvl.w        vr3,    vr7,   vr3
    vilvl.w        vr4,    vr8,   vr4
    vilvl.w        vr5,    vr9,   vr5
    vilvl.w        vr6,    vr10,  vr6
    vilvl.w        vr11,   vr15,  vr11
    vilvl.w        vr12,   vr16,  vr12
    vilvl.w        vr13,   vr17,  vr13
    vilvl.w        vr14,   vr18,  vr14
    vilvl.d        vr3,    vr11,  vr3
    vilvl.d        vr4,    vr12,  vr4
    vilvl.d        vr5,    vr13,  vr5
    vilvl.d        vr6,    vr14,  vr6
    vabsd.bu       vr7,    vr3,   vr4
    vabsd.bu       vr8,    vr3,   vr5
    vabsd.bu       vr9,    vr3,   vr6

    vhaddw.hu.bu   vr0,    vr0,   vr0
    vhaddw.hu.bu   vr1,    vr1,   vr1
    vhaddw.hu.bu   vr2,    vr2,   vr2
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vadd.h         vr7,    vr7,   vr0
    vadd.h         vr8,    vr8,   vr1
    vadd.h         vr9,    vr9,   vr2
    vhaddw.wu.hu   vr7,    vr7,   vr7
    vhaddw.wu.hu   vr8,    vr8,   vr8
    vhaddw.wu.hu   vr9,    vr9,   vr9
    vhaddw.du.wu   vr7,    vr7,   vr7
    vhaddw.du.wu   vr8,    vr8,   vr8
    vhaddw.du.wu   vr9,    vr9,   vr9
    vhaddw.qu.du   vr7,    vr7,   vr7
    vhaddw.qu.du   vr8,    vr8,   vr8
    vhaddw.qu.du   vr9,    vr9,   vr9

    // Store data to p_sad_array
    vstelm.w       vr7,    a5,    0,  0
    vstelm.w       vr8,    a5,    4,  0
    vstelm.w       vr9,    a5,    8,  0
endfunc_x264

/*
 * void x264_pixel_sad_x3_8x4_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                intptr_t i_ref_stride,
 *                                int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_8x4_lsx
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.d          f3,     a0,    0
    fld.d          f7,     a0,    16
    fld.d          f11,    a0,    32
    fld.d          f15,    a0,    48
    FLDD_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr11,   vr15,  vr11
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr14,   vr18,  vr14
    vabsd.bu       vr0,    vr3,   vr4
    vabsd.bu       vr1,    vr3,   vr5
    vabsd.bu       vr2,    vr3,   vr6
    vabsd.bu       vr3,    vr11,  vr12
    vabsd.bu       vr4,    vr11,  vr13
    vabsd.bu       vr5,    vr11,  vr14
    vhaddw.hu.bu   vr0,    vr0,   vr0
    vhaddw.hu.bu   vr1,    vr1,   vr1
    vhaddw.hu.bu   vr2,    vr2,   vr2
    vhaddw.hu.bu   vr3,    vr3,   vr3
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vadd.h         vr7,    vr0,   vr3
    vadd.h         vr8,    vr1,   vr4
    vadd.h         vr9,    vr2,   vr5
    vhaddw.wu.hu   vr7,    vr7,   vr7
    vhaddw.wu.hu   vr8,    vr8,   vr8
    vhaddw.wu.hu   vr9,    vr9,   vr9
    vhaddw.du.wu   vr7,    vr7,   vr7
    vhaddw.du.wu   vr8,    vr8,   vr8
    vhaddw.du.wu   vr9,    vr9,   vr9
    vhaddw.qu.du   vr7,    vr7,   vr7
    vhaddw.qu.du   vr8,    vr8,   vr8
    vhaddw.qu.du   vr9,    vr9,   vr9

    // Store data to p_sad_array
    vstelm.w       vr7,    a5,    0,  0
    vstelm.w       vr8,    a5,    4,  0
    vstelm.w       vr9,    a5,    8,  0
endfunc_x264

/*
 * void x264_pixel_sad_x3_8x8_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                intptr_t i_ref_stride,
 *                                int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_8x8_lsx
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.d          f3,     a0,    0
    fld.d          f7,     a0,    16
    fld.d          f11,    a0,    32
    fld.d          f15,    a0,    48
    FLDD_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr11,   vr15,  vr11
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr14,   vr18,  vr14
    vabsd.bu       vr7,    vr3,   vr4
    vabsd.bu       vr8,    vr3,   vr5
    vabsd.bu       vr9,    vr3,   vr6
    vabsd.bu       vr10,   vr11,  vr12
    vabsd.bu       vr15,   vr11,  vr13
    vabsd.bu       vr16,   vr11,  vr14
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vadd.h         vr0,    vr7,   vr10
    vadd.h         vr1,    vr8,   vr15
    vadd.h         vr2,    vr9,   vr16

    alsl.d         a1,     a4,    a1,   2
    alsl.d         a2,     a4,    a2,   2
    alsl.d         a3,     a4,    a3,   2
    fld.d          f3,     a0,    64
    fld.d          f7,     a0,    80
    fld.d          f11,    a0,    96
    fld.d          f15,    a0,    112
    FLDD_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr11,   vr15,  vr11
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr14,   vr18,  vr14
    vabsd.bu       vr7,    vr3,   vr4
    vabsd.bu       vr8,    vr3,   vr5
    vabsd.bu       vr9,    vr3,   vr6
    vabsd.bu       vr10,   vr11,  vr12
    vabsd.bu       vr15,   vr11,  vr13
    vabsd.bu       vr16,   vr11,  vr14
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vadd.h         vr7,    vr7,   vr10
    vadd.h         vr8,    vr8,   vr15
    vadd.h         vr9,    vr9,   vr16

    vadd.h         vr7,    vr7,   vr0
    vadd.h         vr8,    vr8,   vr1
    vadd.h         vr9,    vr9,   vr2
    vhaddw.wu.hu   vr7,    vr7,   vr7
    vhaddw.wu.hu   vr8,    vr8,   vr8
    vhaddw.wu.hu   vr9,    vr9,   vr9
    vhaddw.du.wu   vr7,    vr7,   vr7
    vhaddw.du.wu   vr8,    vr8,   vr8
    vhaddw.du.wu   vr9,    vr9,   vr9
    vhaddw.qu.du   vr7,    vr7,   vr7
    vhaddw.qu.du   vr8,    vr8,   vr8
    vhaddw.qu.du   vr9,    vr9,   vr9

    // Store data to p_sad_array
    vstelm.w       vr7,    a5,    0,  0
    vstelm.w       vr8,    a5,    4,  0
    vstelm.w       vr9,    a5,    8,  0
endfunc_x264

/*
 * void x264_pixel_sad_x3_8x16_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                 uint8_t *p_ref1, uint8_t *p_ref2,
 *                                 intptr_t i_ref_stride,
 *                                 int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_8x16_lsx
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.d          f3,     a0,    0
    fld.d          f7,     a0,    16
    fld.d          f11,    a0,    32
    fld.d          f15,    a0,    48
    FLDD_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr11,   vr15,  vr11
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr14,   vr18,  vr14
    vabsd.bu       vr7,    vr3,   vr4
    vabsd.bu       vr8,    vr3,   vr5
    vabsd.bu       vr9,    vr3,   vr6
    vabsd.bu       vr10,   vr11,  vr12
    vabsd.bu       vr15,   vr11,  vr13
    vabsd.bu       vr16,   vr11,  vr14
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vadd.h         vr0,    vr7,   vr10
    vadd.h         vr1,    vr8,   vr15
    vadd.h         vr2,    vr9,   vr16

.rept 3
    alsl.d         a1,     a4,    a1,   2
    alsl.d         a2,     a4,    a2,   2
    alsl.d         a3,     a4,    a3,   2
    addi.d         a0,     a0,    64
    fld.d          f3,     a0,    0
    fld.d          f7,     a0,    16
    fld.d          f11,    a0,    32
    fld.d          f15,    a0,    48
    FLDD_LOADX_4   a1,     a4,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a4,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a4,    t1,  t2,  f6, f10, f14, f18
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr11,   vr15,  vr11
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr14,   vr18,  vr14
    vabsd.bu       vr7,    vr3,   vr4
    vabsd.bu       vr8,    vr3,   vr5
    vabsd.bu       vr9,    vr3,   vr6
    vabsd.bu       vr10,   vr11,  vr12
    vabsd.bu       vr15,   vr11,  vr13
    vabsd.bu       vr16,   vr11,  vr14
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vadd.h         vr7,    vr7,   vr10
    vadd.h         vr8,    vr8,   vr15
    vadd.h         vr9,    vr9,   vr16
    vadd.h         vr0,    vr7,   vr0
    vadd.h         vr1,    vr8,   vr1
    vadd.h         vr2,    vr9,   vr2
.endr

    vhaddw.wu.hu   vr0,    vr0,   vr0
    vhaddw.wu.hu   vr1,    vr1,   vr1
    vhaddw.wu.hu   vr2,    vr2,   vr2
    vhaddw.du.wu   vr0,    vr0,   vr0
    vhaddw.du.wu   vr1,    vr1,   vr1
    vhaddw.du.wu   vr2,    vr2,   vr2
    vhaddw.qu.du   vr0,    vr0,   vr0
    vhaddw.qu.du   vr1,    vr1,   vr1
    vhaddw.qu.du   vr2,    vr2,   vr2

    // Store data to p_sad_array
    vstelm.w       vr0,    a5,    0,  0
    vstelm.w       vr1,    a5,    4,  0
    vstelm.w       vr2,    a5,    8,  0
endfunc_x264

/*
 * void x264_pixel_sad_x3_16x8_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                 uint8_t *p_ref1, uint8_t *p_ref2,
 *                                 intptr_t i_ref_stride,
 *                                 int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_16x8_lsx
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1

    vld            vr0,    a0,    0
    vld            vr1,    a0,    16
    vld            vr2,    a0,    32
    vld            vr3,    a0,    48
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr1,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr2,   vr10
    vabsd.bu       vr11,   vr2,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr3,   vr13
    vabsd.bu       vr14,   vr3,   vr14
    vabsd.bu       vr15,   vr3,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr0,    vr7,   vr4
    vadd.h         vr1,    vr13,  vr10
    vadd.h         vr16,   vr1,   vr0
    vadd.h         vr0,    vr8,   vr5
    vadd.h         vr1,    vr14,  vr11
    vadd.h         vr17,   vr1,   vr0
    vadd.h         vr0,    vr9,   vr6
    vadd.h         vr1,    vr15,  vr12
    vadd.h         vr18,   vr1,   vr0

    // vr16, vr17, vr18
    alsl.d         a1,     a4,    a1,   2
    alsl.d         a2,     a4,    a2,   2
    alsl.d         a3,     a4,    a3,   2
    vld            vr0,    a0,    64
    vld            vr1,    a0,    80
    vld            vr2,    a0,    96
    vld            vr3,    a0,    112
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr1,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr2,   vr10
    vabsd.bu       vr11,   vr2,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr3,   vr13
    vabsd.bu       vr14,   vr3,   vr14
    vabsd.bu       vr15,   vr3,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr0,    vr7,   vr4
    vadd.h         vr1,    vr13,  vr10
    vadd.h         vr2,    vr1,   vr0
    vadd.h         vr0,    vr8,   vr5
    vadd.h         vr1,    vr14,  vr11
    vadd.h         vr3,    vr1,   vr0
    vadd.h         vr0,    vr9,   vr6
    vadd.h         vr1,    vr15,  vr12
    vadd.h         vr4,    vr1,   vr0

    vadd.h         vr0,    vr16,  vr2
    vadd.h         vr1,    vr17,  vr3
    vadd.h         vr2,    vr18,  vr4
    vhaddw.wu.hu   vr0,    vr0,   vr0
    vhaddw.wu.hu   vr1,    vr1,   vr1
    vhaddw.wu.hu   vr2,    vr2,   vr2
    vhaddw.du.wu   vr0,    vr0,   vr0
    vhaddw.du.wu   vr1,    vr1,   vr1
    vhaddw.du.wu   vr2,    vr2,   vr2
    vhaddw.qu.du   vr0,    vr0,   vr0
    vhaddw.qu.du   vr1,    vr1,   vr1
    vhaddw.qu.du   vr2,    vr2,   vr2

    // Store data to p_sad_array
    vstelm.w       vr0,    a5,    0,  0
    vstelm.w       vr1,    a5,    4,  0
    vstelm.w       vr2,    a5,    8,  0
endfunc_x264

/*
 * void x264_pixel_sad_x3_16x16_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                  uint8_t *p_ref1, uint8_t *p_ref2,
 *                                  intptr_t i_ref_stride,
 *                                  int32_t p_sad_array[3])
 */
function_x264 pixel_sad_x3_16x16_lsx
    slli.d         t1,     a4,    1
    add.d          t2,     a4,    t1

    vld            vr0,    a0,    0
    vld            vr1,    a0,    16
    vld            vr2,    a0,    32
    vld            vr3,    a0,    48
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr1,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr2,   vr10
    vabsd.bu       vr11,   vr2,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr3,   vr13
    vabsd.bu       vr14,   vr3,   vr14
    vabsd.bu       vr15,   vr3,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr0,    vr7,   vr4
    vadd.h         vr1,    vr13,  vr10
    vadd.h         vr16,   vr1,   vr0
    vadd.h         vr0,    vr8,   vr5
    vadd.h         vr1,    vr14,  vr11
    vadd.h         vr17,   vr1,   vr0
    vadd.h         vr0,    vr9,   vr6
    vadd.h         vr1,    vr15,  vr12
    vadd.h         vr18,   vr1,   vr0

.rept 3
    alsl.d         a1,     a4,    a1,   2
    alsl.d         a2,     a4,    a2,   2
    alsl.d         a3,     a4,    a3,   2
    addi.d         a0,     a0,    64
    vld            vr0,    a0,    0
    vld            vr1,    a0,    16
    vld            vr2,    a0,    32
    vld            vr3,    a0,    48
    LSX_LOADX_4    a1,     a4,    t1,  t2,  vr4, vr7, vr10, vr13
    LSX_LOADX_4    a2,     a4,    t1,  t2,  vr5, vr8, vr11, vr14
    LSX_LOADX_4    a3,     a4,    t1,  t2,  vr6, vr9, vr12, vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr1,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr2,   vr10
    vabsd.bu       vr11,   vr2,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr3,   vr13
    vabsd.bu       vr14,   vr3,   vr14
    vabsd.bu       vr15,   vr3,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr0,    vr7,   vr4
    vadd.h         vr1,    vr13,  vr10
    vadd.h         vr2,    vr1,   vr0
    vadd.h         vr0,    vr8,   vr5
    vadd.h         vr1,    vr14,  vr11
    vadd.h         vr3,    vr1,   vr0
    vadd.h         vr0,    vr9,   vr6
    vadd.h         vr1,    vr15,  vr12
    vadd.h         vr4,    vr1,   vr0

    vadd.h         vr16,   vr16,  vr2
    vadd.h         vr17,   vr17,  vr3
    vadd.h         vr18,   vr18,  vr4
.endr

    vhaddw.wu.hu   vr16,   vr16,  vr16
    vhaddw.wu.hu   vr17,   vr17,  vr17
    vhaddw.wu.hu   vr18,   vr18,  vr18
    vhaddw.du.wu   vr16,   vr16,  vr16
    vhaddw.du.wu   vr17,   vr17,  vr17
    vhaddw.du.wu   vr18,   vr18,  vr18
    vhaddw.qu.du   vr16,   vr16,  vr16
    vhaddw.qu.du   vr17,   vr17,  vr17
    vhaddw.qu.du   vr18,   vr18,  vr18

    // Store data to p_sad_array
    vstelm.w       vr16,    a5,    0,  0
    vstelm.w       vr17,    a5,    4,  0
    vstelm.w       vr18,    a5,    8,  0
endfunc_x264

/*
 * void x264_pixel_sad_x4_4x8_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_4x8_lsx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1

    fld.s          f0,     a0,    0
    fld.s          f1,     a0,    16
    fld.s          f2,     a0,    32
    fld.s          f3,     a0,    48
    FLDS_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f12, f16
    FLDS_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f13, f17
    FLDS_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f14, f18
    FLDS_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f15, f19

    vilvl.w        vr0,    vr1,   vr0
    vilvl.w        vr2,    vr3,   vr2
    vilvl.d        vr0,    vr2,   vr0
    vilvl.w        vr4,    vr8,   vr4
    vilvl.w        vr12,   vr16,  vr12
    vilvl.d        vr1,    vr12,  vr4
    vilvl.w        vr5,    vr9,   vr5
    vilvl.w        vr13,   vr17,  vr13
    vilvl.d        vr2,    vr13,  vr5
    vilvl.w        vr6,    vr10,  vr6
    vilvl.w        vr14,   vr18,  vr14
    vilvl.d        vr3,    vr14,  vr6
    vilvl.w        vr7,    vr11,  vr7
    vilvl.w        vr15,   vr19,  vr15
    vilvl.d        vr4,    vr15,  vr7
    vabsd.bu       vr1,    vr0,   vr1
    vabsd.bu       vr2,    vr0,   vr2
    vabsd.bu       vr3,    vr0,   vr3
    vabsd.bu       vr4,    vr0,   vr4
    vhaddw.hu.bu   vr20,   vr1,   vr1
    vhaddw.hu.bu   vr21,   vr2,   vr2
    vhaddw.hu.bu   vr22,   vr3,   vr3
    vhaddw.hu.bu   vr23,   vr4,   vr4

    alsl.d         a1,     a5,    a1,   2
    alsl.d         a2,     a5,    a2,   2
    alsl.d         a3,     a5,    a3,   2
    alsl.d         a4,     a5,    a4,   2
    fld.s          f0,     a0,    64
    fld.s          f1,     a0,    80
    fld.s          f2,     a0,    96
    fld.s          f3,     a0,    112
    FLDS_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f12, f16
    FLDS_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f13, f17
    FLDS_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f14, f18
    FLDS_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f15, f19

    vilvl.w        vr0,    vr1,   vr0
    vilvl.w        vr2,    vr3,   vr2
    vilvl.d        vr0,    vr2,   vr0
    vilvl.w        vr4,    vr8,   vr4
    vilvl.w        vr12,   vr16,  vr12
    vilvl.d        vr1,    vr12,  vr4
    vilvl.w        vr5,    vr9,   vr5
    vilvl.w        vr13,   vr17,  vr13
    vilvl.d        vr2,    vr13,  vr5
    vilvl.w        vr6,    vr10,  vr6
    vilvl.w        vr14,   vr18,  vr14
    vilvl.d        vr3,    vr14,  vr6
    vilvl.w        vr7,    vr11,  vr7
    vilvl.w        vr15,   vr19,  vr15
    vilvl.d        vr4,    vr15,  vr7
    vabsd.bu       vr1,    vr0,   vr1
    vabsd.bu       vr2,    vr0,   vr2
    vabsd.bu       vr3,    vr0,   vr3
    vabsd.bu       vr4,    vr0,   vr4
    vhaddw.hu.bu   vr1,    vr1,   vr1
    vhaddw.hu.bu   vr2,    vr2,   vr2
    vhaddw.hu.bu   vr3,    vr3,   vr3
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vadd.h         vr16,   vr20,  vr1
    vadd.h         vr17,   vr21,  vr2
    vadd.h         vr18,   vr22,  vr3
    vadd.h         vr19,   vr23,  vr4

    vhaddw.wu.hu   vr16,   vr16,  vr16
    vhaddw.wu.hu   vr17,   vr17,  vr17
    vhaddw.wu.hu   vr18,   vr18,  vr18
    vhaddw.wu.hu   vr19,   vr19,  vr19
    vhaddw.du.wu   vr16,   vr16,  vr16
    vhaddw.du.wu   vr17,   vr17,  vr17
    vhaddw.du.wu   vr18,   vr18,  vr18
    vhaddw.du.wu   vr19,   vr19,  vr19
    vhaddw.qu.du   vr16,   vr16,  vr16
    vhaddw.qu.du   vr17,   vr17,  vr17
    vhaddw.qu.du   vr18,   vr18,  vr18
    vhaddw.qu.du   vr19,   vr19,  vr19

    // Store data to p_sad_array
    vstelm.w       vr16,   a6,    0,      0
    vstelm.w       vr17,   a6,    4,      0
    vstelm.w       vr18,   a6,    8,      0
    vstelm.w       vr19,   a6,    12,     0
endfunc_x264

/*
 * void x264_pixel_sad_x4_8x4_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_8x4_lsx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.d          f0,     a0,    0
    fld.d          f1,     a0,    16
    fld.d          f2,     a0,    32
    fld.d          f3,     a0,    48
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f14, f18
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f15, f19
    vilvl.d        vr0,    vr1,   vr0
    vilvl.d        vr2,    vr3,   vr2
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr14,   vr18,  vr14
    vilvl.d        vr7,    vr11,  vr7
    vilvl.d        vr15,   vr19,  vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr16,   vr4,   vr12
    vadd.h         vr17,   vr5,   vr13
    vadd.h         vr18,   vr6,   vr14
    vadd.h         vr19,   vr7,   vr15
    vhaddw.wu.hu   vr16,   vr16,  vr16
    vhaddw.wu.hu   vr17,   vr17,  vr17
    vhaddw.wu.hu   vr18,   vr18,  vr18
    vhaddw.wu.hu   vr19,   vr19,  vr19
    vhaddw.du.wu   vr16,   vr16,  vr16
    vhaddw.du.wu   vr17,   vr17,  vr17
    vhaddw.du.wu   vr18,   vr18,  vr18
    vhaddw.du.wu   vr19,   vr19,  vr19
    vhaddw.qu.du   vr16,   vr16,  vr16
    vhaddw.qu.du   vr17,   vr17,  vr17
    vhaddw.qu.du   vr18,   vr18,  vr18
    vhaddw.qu.du   vr19,   vr19,  vr19

    // Store data to p_sad_array
    vstelm.w       vr16,   a6,    0,      0
    vstelm.w       vr17,   a6,    4,      0
    vstelm.w       vr18,   a6,    8,      0
    vstelm.w       vr19,   a6,    12,     0
endfunc_x264

/*
 * void x264_pixel_sad_x4_8x8_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                uint8_t *p_ref1, uint8_t *p_ref2,
 *                                uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_8x8_lsx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.d          f0,     a0,    0
    fld.d          f1,     a0,    16
    fld.d          f2,     a0,    32
    fld.d          f3,     a0,    48
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f14, f18
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f15, f19
    vilvl.d        vr0,    vr1,   vr0
    vilvl.d        vr2,    vr3,   vr2
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr14,   vr18,  vr14
    vilvl.d        vr7,    vr11,  vr7
    vilvl.d        vr15,   vr19,  vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr20,   vr4,   vr12
    vadd.h         vr21,   vr5,   vr13
    vadd.h         vr22,   vr6,   vr14
    vadd.h         vr23,   vr7,   vr15

    alsl.d         a1,     a5,    a1,   2
    alsl.d         a2,     a5,    a2,   2
    alsl.d         a3,     a5,    a3,   2
    alsl.d         a4,     a5,    a4,   2
    fld.d          f0,     a0,    64
    fld.d          f1,     a0,    80
    fld.d          f2,     a0,    96
    fld.d          f3,     a0,    112
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f14, f18
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f15, f19
    vilvl.d        vr0,    vr1,   vr0
    vilvl.d        vr2,    vr3,   vr2
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr14,   vr18,  vr14
    vilvl.d        vr7,    vr11,  vr7
    vilvl.d        vr15,   vr19,  vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr16,   vr4,   vr12
    vadd.h         vr17,   vr5,   vr13
    vadd.h         vr18,   vr6,   vr14
    vadd.h         vr19,   vr7,   vr15

    vadd.h         vr16,   vr16,  vr20
    vadd.h         vr17,   vr17,  vr21
    vadd.h         vr18,   vr18,  vr22
    vadd.h         vr19,   vr19,  vr23
    vhaddw.wu.hu   vr16,   vr16,  vr16
    vhaddw.wu.hu   vr17,   vr17,  vr17
    vhaddw.wu.hu   vr18,   vr18,  vr18
    vhaddw.wu.hu   vr19,   vr19,  vr19
    vhaddw.du.wu   vr16,   vr16,  vr16
    vhaddw.du.wu   vr17,   vr17,  vr17
    vhaddw.du.wu   vr18,   vr18,  vr18
    vhaddw.du.wu   vr19,   vr19,  vr19
    vhaddw.qu.du   vr16,   vr16,  vr16
    vhaddw.qu.du   vr17,   vr17,  vr17
    vhaddw.qu.du   vr18,   vr18,  vr18
    vhaddw.qu.du   vr19,   vr19,  vr19
    // Store data to p_sad_array
    vstelm.w       vr16,   a6,    0,      0
    vstelm.w       vr17,   a6,    4,      0
    vstelm.w       vr18,   a6,    8,      0
    vstelm.w       vr19,   a6,    12,     0
endfunc_x264

/*
 * void x264_pixel_sad_x4_8x16_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                 uint8_t *p_ref1, uint8_t *p_ref2,
 *                                 uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                 int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_8x16_lsx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1

    // Load data from p_src, p_ref0, p_ref1 and p_ref2
    fld.d          f0,     a0,    0
    fld.d          f1,     a0,    16
    fld.d          f2,     a0,    32
    fld.d          f3,     a0,    48
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f14, f18
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f15, f19
    vilvl.d        vr0,    vr1,   vr0
    vilvl.d        vr2,    vr3,   vr2
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr14,   vr18,  vr14
    vilvl.d        vr7,    vr11,  vr7
    vilvl.d        vr15,   vr19,  vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr20,   vr4,   vr12
    vadd.h         vr21,   vr5,   vr13
    vadd.h         vr22,   vr6,   vr14
    vadd.h         vr23,   vr7,   vr15

.rept 3
    alsl.d         a1,     a5,    a1,   2
    alsl.d         a2,     a5,    a2,   2
    alsl.d         a3,     a5,    a3,   2
    alsl.d         a4,     a5,    a4,   2
    addi.d         a0,     a0,    64
    fld.d          f0,     a0,    0
    fld.d          f1,     a0,    16
    fld.d          f2,     a0,    32
    fld.d          f3,     a0,    48
    FLDD_LOADX_4   a1,     a5,    t1,  t2,  f4, f8,  f12, f16
    FLDD_LOADX_4   a2,     a5,    t1,  t2,  f5, f9,  f13, f17
    FLDD_LOADX_4   a3,     a5,    t1,  t2,  f6, f10, f14, f18
    FLDD_LOADX_4   a4,     a5,    t1,  t2,  f7, f11, f15, f19
    vilvl.d        vr0,    vr1,   vr0
    vilvl.d        vr2,    vr3,   vr2
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr12,   vr16,  vr12
    vilvl.d        vr5,    vr9,   vr5
    vilvl.d        vr13,   vr17,  vr13
    vilvl.d        vr6,    vr10,  vr6
    vilvl.d        vr14,   vr18,  vr14
    vilvl.d        vr7,    vr11,  vr7
    vilvl.d        vr15,   vr19,  vr15
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vadd.h         vr16,   vr4,   vr12
    vadd.h         vr17,   vr5,   vr13
    vadd.h         vr18,   vr6,   vr14
    vadd.h         vr19,   vr7,   vr15
    vadd.h         vr20,   vr16,  vr20
    vadd.h         vr21,   vr17,  vr21
    vadd.h         vr22,   vr18,  vr22
    vadd.h         vr23,   vr19,  vr23
.endr
    vhaddw.wu.hu   vr20,   vr20,  vr20
    vhaddw.wu.hu   vr21,   vr21,  vr21
    vhaddw.wu.hu   vr22,   vr22,  vr22
    vhaddw.wu.hu   vr23,   vr23,  vr23
    vhaddw.du.wu   vr20,   vr20,  vr20
    vhaddw.du.wu   vr21,   vr21,  vr21
    vhaddw.du.wu   vr22,   vr22,  vr22
    vhaddw.du.wu   vr23,   vr23,  vr23
    vhaddw.qu.du   vr20,   vr20,  vr20
    vhaddw.qu.du   vr21,   vr21,  vr21
    vhaddw.qu.du   vr22,   vr22,  vr22
    vhaddw.qu.du   vr23,   vr23,  vr23
    // Store data to p_sad_array
    vstelm.w       vr20,   a6,    0,      0
    vstelm.w       vr21,   a6,    4,      0
    vstelm.w       vr22,   a6,    8,      0
    vstelm.w       vr23,   a6,    12,     0
endfunc_x264

/*
 * void x264_pixel_sad_x4_16x8_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                 uint8_t *p_ref1, uint8_t *p_ref2,
 *                                 uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                 int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_16x8_lsx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1

    vld            vr0,    a0,    0
    vld            vr1,    a0,    16
    vld            vr2,    a0,    32
    vld            vr3,    a0,    48
    LSX_LOADX_4    a1,     a5,    t1,  t2,  vr4, vr8, vr12, vr16
    LSX_LOADX_4    a2,     a5,    t1,  t2,  vr5, vr9, vr13, vr17
    LSX_LOADX_4    a3,     a5,    t1,  t2,  vr6, vr10, vr14, vr18
    LSX_LOADX_4    a4,     a5,    t1,  t2,  vr7, vr11, vr15, vr19
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr1,   vr10
    vabsd.bu       vr11,   vr1,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vabsd.bu       vr16,   vr3,   vr16
    vabsd.bu       vr17,   vr3,   vr17
    vabsd.bu       vr18,   vr3,   vr18
    vabsd.bu       vr19,   vr3,   vr19
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vhaddw.hu.bu   vr17,   vr17,  vr17
    vhaddw.hu.bu   vr18,   vr18,  vr18
    vhaddw.hu.bu   vr19,   vr19,  vr19
    vadd.h         vr0,    vr4,   vr8
    vadd.h         vr1,    vr12,  vr16
    vadd.h         vr20,   vr0,   vr1
    vadd.h         vr0,    vr5,   vr9
    vadd.h         vr1,    vr13,  vr17
    vadd.h         vr21,   vr0,   vr1
    vadd.h         vr0,    vr6,   vr10
    vadd.h         vr1,    vr14,  vr18
    vadd.h         vr22,   vr0,   vr1
    vadd.h         vr0,    vr7,   vr11
    vadd.h         vr1,    vr15,  vr19
    vadd.h         vr23,   vr0,   vr1

    alsl.d         a1,     a5,    a1,   2
    alsl.d         a2,     a5,    a2,   2
    alsl.d         a3,     a5,    a3,   2
    alsl.d         a4,     a5,    a4,   2
    vld            vr0,    a0,    64
    vld            vr1,    a0,    80
    vld            vr2,    a0,    96
    vld            vr3,    a0,    112
    LSX_LOADX_4    a1,     a5,    t1,  t2,  vr4, vr8, vr12, vr16
    LSX_LOADX_4    a2,     a5,    t1,  t2,  vr5, vr9, vr13, vr17
    LSX_LOADX_4    a3,     a5,    t1,  t2,  vr6, vr10, vr14, vr18
    LSX_LOADX_4    a4,     a5,    t1,  t2,  vr7, vr11, vr15, vr19
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr1,   vr10
    vabsd.bu       vr11,   vr1,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vabsd.bu       vr16,   vr3,   vr16
    vabsd.bu       vr17,   vr3,   vr17
    vabsd.bu       vr18,   vr3,   vr18
    vabsd.bu       vr19,   vr3,   vr19
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vhaddw.hu.bu   vr17,   vr17,  vr17
    vhaddw.hu.bu   vr18,   vr18,  vr18
    vhaddw.hu.bu   vr19,   vr19,  vr19
    vadd.h         vr0,    vr4,   vr8
    vadd.h         vr1,    vr12,  vr16
    vadd.h         vr16,   vr0,   vr1
    vadd.h         vr0,    vr5,   vr9
    vadd.h         vr1,    vr13,  vr17
    vadd.h         vr17,   vr0,   vr1
    vadd.h         vr0,    vr6,   vr10
    vadd.h         vr1,    vr14,  vr18
    vadd.h         vr18,   vr0,   vr1
    vadd.h         vr0,    vr7,   vr11
    vadd.h         vr1,    vr15,  vr19
    vadd.h         vr19,   vr0,   vr1

    vadd.h         vr20,   vr16,  vr20
    vadd.h         vr21,   vr17,  vr21
    vadd.h         vr22,   vr18,  vr22
    vadd.h         vr23,   vr19,  vr23
    vhaddw.wu.hu   vr20,   vr20,  vr20
    vhaddw.wu.hu   vr21,   vr21,  vr21
    vhaddw.wu.hu   vr22,   vr22,  vr22
    vhaddw.wu.hu   vr23,   vr23,  vr23
    vhaddw.du.wu   vr20,   vr20,  vr20
    vhaddw.du.wu   vr21,   vr21,  vr21
    vhaddw.du.wu   vr22,   vr22,  vr22
    vhaddw.du.wu   vr23,   vr23,  vr23
    vhaddw.qu.du   vr20,   vr20,  vr20
    vhaddw.qu.du   vr21,   vr21,  vr21
    vhaddw.qu.du   vr22,   vr22,  vr22
    vhaddw.qu.du   vr23,   vr23,  vr23
    // Store data to p_sad_array
    vstelm.w       vr20,   a6,    0,      0
    vstelm.w       vr21,   a6,    4,      0
    vstelm.w       vr22,   a6,    8,      0
    vstelm.w       vr23,   a6,    12,     0
endfunc_x264

/*
 * void x264_pixel_sad_x4_16x16_lsx(uint8_t *p_src, uint8_t *p_ref0,
 *                                  uint8_t *p_ref1, uint8_t *p_ref2,
 *                                  uint8_t *p_ref3, intptr_t i_ref_stride,
 *                                  int32_t p_sad_array[4])
 */
function_x264 pixel_sad_x4_16x16_lsx
    slli.d         t1,     a5,    1
    add.d          t2,     a5,    t1

    vld            vr0,    a0,    0
    vld            vr1,    a0,    16
    vld            vr2,    a0,    32
    vld            vr3,    a0,    48
    LSX_LOADX_4    a1,     a5,    t1,  t2,  vr4, vr8,  vr12, vr16
    LSX_LOADX_4    a2,     a5,    t1,  t2,  vr5, vr9,  vr13, vr17
    LSX_LOADX_4    a3,     a5,    t1,  t2,  vr6, vr10, vr14, vr18
    LSX_LOADX_4    a4,     a5,    t1,  t2,  vr7, vr11, vr15, vr19
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr1,   vr10
    vabsd.bu       vr11,   vr1,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vabsd.bu       vr16,   vr3,   vr16
    vabsd.bu       vr17,   vr3,   vr17
    vabsd.bu       vr18,   vr3,   vr18
    vabsd.bu       vr19,   vr3,   vr19
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vhaddw.hu.bu   vr17,   vr17,  vr17
    vhaddw.hu.bu   vr18,   vr18,  vr18
    vhaddw.hu.bu   vr19,   vr19,  vr19
    vadd.h         vr0,    vr4,   vr8
    vadd.h         vr1,    vr12,  vr16
    vadd.h         vr20,   vr0,   vr1
    vadd.h         vr0,    vr5,   vr9
    vadd.h         vr1,    vr13,  vr17
    vadd.h         vr21,   vr0,   vr1
    vadd.h         vr0,    vr6,   vr10
    vadd.h         vr1,    vr14,  vr18
    vadd.h         vr22,   vr0,   vr1
    vadd.h         vr0,    vr7,   vr11
    vadd.h         vr1,    vr15,  vr19
    vadd.h         vr23,   vr0,   vr1

.rept 3
    alsl.d         a1,     a5,    a1,   2
    alsl.d         a2,     a5,    a2,   2
    alsl.d         a3,     a5,    a3,   2
    alsl.d         a4,     a5,    a4,   2
    addi.d         a0,     a0,    64
    vld            vr0,    a0,    0
    vld            vr1,    a0,    16
    vld            vr2,    a0,    32
    vld            vr3,    a0,    48
    LSX_LOADX_4    a1,     a5,    t1,  t2,  vr4, vr8,  vr12, vr16
    LSX_LOADX_4    a2,     a5,    t1,  t2,  vr5, vr9,  vr13, vr17
    LSX_LOADX_4    a3,     a5,    t1,  t2,  vr6, vr10, vr14, vr18
    LSX_LOADX_4    a4,     a5,    t1,  t2,  vr7, vr11, vr15, vr19
    vabsd.bu       vr4,    vr0,   vr4
    vabsd.bu       vr5,    vr0,   vr5
    vabsd.bu       vr6,    vr0,   vr6
    vabsd.bu       vr7,    vr0,   vr7
    vabsd.bu       vr8,    vr1,   vr8
    vabsd.bu       vr9,    vr1,   vr9
    vabsd.bu       vr10,   vr1,   vr10
    vabsd.bu       vr11,   vr1,   vr11
    vabsd.bu       vr12,   vr2,   vr12
    vabsd.bu       vr13,   vr2,   vr13
    vabsd.bu       vr14,   vr2,   vr14
    vabsd.bu       vr15,   vr2,   vr15
    vabsd.bu       vr16,   vr3,   vr16
    vabsd.bu       vr17,   vr3,   vr17
    vabsd.bu       vr18,   vr3,   vr18
    vabsd.bu       vr19,   vr3,   vr19
    vhaddw.hu.bu   vr4,    vr4,   vr4
    vhaddw.hu.bu   vr5,    vr5,   vr5
    vhaddw.hu.bu   vr6,    vr6,   vr6
    vhaddw.hu.bu   vr7,    vr7,   vr7
    vhaddw.hu.bu   vr8,    vr8,   vr8
    vhaddw.hu.bu   vr9,    vr9,   vr9
    vhaddw.hu.bu   vr10,   vr10,  vr10
    vhaddw.hu.bu   vr11,   vr11,  vr11
    vhaddw.hu.bu   vr12,   vr12,  vr12
    vhaddw.hu.bu   vr13,   vr13,  vr13
    vhaddw.hu.bu   vr14,   vr14,  vr14
    vhaddw.hu.bu   vr15,   vr15,  vr15
    vhaddw.hu.bu   vr16,   vr16,  vr16
    vhaddw.hu.bu   vr17,   vr17,  vr17
    vhaddw.hu.bu   vr18,   vr18,  vr18
    vhaddw.hu.bu   vr19,   vr19,  vr19
    vadd.h         vr0,    vr4,   vr8
    vadd.h         vr1,    vr12,  vr16
    vadd.h         vr16,   vr0,   vr1
    vadd.h         vr0,    vr5,   vr9
    vadd.h         vr1,    vr13,  vr17
    vadd.h         vr17,   vr0,   vr1
    vadd.h         vr0,    vr6,   vr10
    vadd.h         vr1,    vr14,  vr18
    vadd.h         vr18,   vr0,   vr1
    vadd.h         vr0,    vr7,   vr11
    vadd.h         vr1,    vr15,  vr19
    vadd.h         vr19,   vr0,   vr1
    vadd.h         vr20,   vr16,  vr20
    vadd.h         vr21,   vr17,  vr21
    vadd.h         vr22,   vr18,  vr22
    vadd.h         vr23,   vr19,  vr23
.endr
    vhaddw.wu.hu   vr20,   vr20,  vr20
    vhaddw.wu.hu   vr21,   vr21,  vr21
    vhaddw.wu.hu   vr22,   vr22,  vr22
    vhaddw.wu.hu   vr23,   vr23,  vr23
    vhaddw.du.wu   vr20,   vr20,  vr20
    vhaddw.du.wu   vr21,   vr21,  vr21
    vhaddw.du.wu   vr22,   vr22,  vr22
    vhaddw.du.wu   vr23,   vr23,  vr23
    vhaddw.qu.du   vr20,   vr20,  vr20
    vhaddw.qu.du   vr21,   vr21,  vr21
    vhaddw.qu.du   vr22,   vr22,  vr22
    vhaddw.qu.du   vr23,   vr23,  vr23
    // Store data to p_sad_array
    vstelm.w       vr20,   a6,    0,      0
    vstelm.w       vr21,   a6,    4,      0
    vstelm.w       vr22,   a6,    8,      0
    vstelm.w       vr23,   a6,    12,     0
endfunc_x264
#endif /* !HIGH_BIT_DEPTH */
