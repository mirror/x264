/*****************************************************************************
 * deblock-a.S: loongarch deblock functions
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Hao Chen <chenhao@loongson.cn>
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

const shuf_loc_locn
.byte 1, 9, 17, 25, 2, 10, 18, 26, 3, 11, 19, 27, 4, 12, 20, 28
.byte 16, 24, 0, 8, 17, 25, 1, 9, 18, 26, 2, 10, 19, 27, 3, 11
endconst

const shuf_locn
.byte 0, 8, 16, 24, 1, 9, 17, 25, 2, 10, 18, 26, 3, 11, 19, 27
endconst

/*Transpose 16 * 6 block with byte elements in vectors*/
.macro LASX_TRANSPOSE in0,  in1,  in2,  in3,  in4,  in5,  in6,  in7, \
                      in8,  in9,  in10, in11, in12, in13, in14, in15,\
                      tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7,\
                      out0, out1, out2, out3, out4, out5
    xvilvl.b   \tmp0,    \in1,     \in0
    xvilvl.b   \tmp1,    \in3,     \in2
    xvilvl.b   \tmp2,    \in5,     \in4
    xvilvl.b   \tmp3,    \in7,     \in6
    xvilvl.b   \tmp4,    \in9,     \in8
    xvilvl.b   \tmp5,    \in11,    \in10
    xvilvl.b   \tmp6,    \in13,    \in12
    xvilvl.b   \tmp7,    \in15,    \in14
    xvpermi.d  \tmp0,    \tmp0,    0xD8
    xvpermi.d  \tmp1,    \tmp1,    0xD8
    xvpermi.d  \tmp2,    \tmp2,    0xD8
    xvpermi.d  \tmp3,    \tmp3,    0xD8
    xvpermi.d  \tmp4,    \tmp4,    0xD8
    xvpermi.d  \tmp5,    \tmp5,    0xD8
    xvpermi.d  \tmp6,    \tmp6,    0xD8
    xvpermi.d  \tmp7,    \tmp7,    0xD8
    xvilvl.h   \out0,    \tmp1,    \tmp0
    xvilvl.h   \out1,    \tmp3,    \tmp2
    xvilvl.h   \out2,    \tmp5,    \tmp4
    xvilvl.h   \out3,    \tmp7,    \tmp6
    xvilvl.w   \tmp0,    \out1,    \out0
    xvilvh.w   \tmp1,    \out1,    \out0
    xvilvl.w   \tmp2,    \out3,    \out2
    xvilvh.w   \tmp3,    \out3,    \out2
    xvilvl.d   \out0,    \tmp2,    \tmp0
    xvilvh.d   \out1,    \tmp2,    \tmp0
    xvilvl.d   \out2,    \tmp3,    \tmp1
    xvilvh.d   \out3,    \tmp3,    \tmp1
    xvpermi.d  \out4,    \out0,    0x4E
    xvpermi.d  \out5,    \out1,    0x4E
.endm

/*
 * void deblock_h_luma_lasx(Pixel *pix, intptr_t stride, int alpha,
 *                          int beta, int8_t *tc0)
 */
function_x264 deblock_h_luma_lasx
    slli.d          t0,    a1,    1
    slli.d          t2,    a1,    2

    xvldrepl.w      xr1,   a4,    0
    add.d           t1,    t0,    a1
    xvreplgr2vr.b   xr2,   a3
    xvilvl.b        xr1,   xr1,   xr1

    // Store registers to the stack
    addi.d          sp,    sp,    -64
    fst.d           f24,   sp,    0
    fst.d           f25,   sp,    8
    fst.d           f26,   sp,    16
    fst.d           f27,   sp,    24
    fst.d           f28,   sp,    32
    fst.d           f29,   sp,    40
    fst.d           f30,   sp,    48
    fst.d           f31,   sp,    56

    // Load data from pix
    addi.d          t4,    a0,    -3
    FLDD_LOADX_4    t4,    a1,    t0,   t1,   f10, f11, f12, f13
    add.d           t5,    t4,    t2
    FLDD_LOADX_4    t5,    a1,    t0,   t1,   f14, f15, f16, f17
    add.d           t5,    t5,    t2
    FLDD_LOADX_4    t5,    a1,    t0,   t1,   f20, f21, f22, f23
    add.d           t6,    t5,    t2
    FLDD_LOADX_4    t6,    a1,    t0,   t1,   f24, f25, f26, f27

    LASX_TRANSPOSE  xr10, xr11, xr12, xr13, xr14, xr15, xr16, xr17,  \
                    xr20, xr21, xr22, xr23, xr24, xr25, xr26, xr27,  \
                    xr8,  xr9,  xr18, xr19, xr28, xr29, xr30, xr31,  \
                    xr10, xr11, xr12, xr13, xr14, xr15

    xvilvl.h        xr1,   xr1,   xr1
    vext2xv.hu.bu   xr20,  xr10
    vext2xv.hu.bu   xr21,  xr11
    vext2xv.hu.bu   xr22,  xr12
    vext2xv.hu.bu   xr23,  xr13
    vext2xv.hu.bu   xr24,  xr14
    vext2xv.hu.bu   xr25,  xr15
    vext2xv.h.b     xr3,   xr1

    xvadd.h         xr26,  xr22,  xr23
    xvsrari.h       xr26,  xr26,  1
    xvneg.h         xr4,   xr3
    xvadd.h         xr27,  xr20,  xr26
    xvadd.h         xr28,  xr25,  xr26
    xvsub.h         xr29,  xr23,  xr22
    xvsrai.h        xr27,  xr27,  1
    xvsrai.h        xr28,  xr28,  1
    xvslli.h        xr29,  xr29,  2
    xvsub.h         xr30,  xr21,  xr24
    xvsub.h         xr27,  xr27,  xr21
    xvsub.h         xr28,  xr28,  xr24
    xvadd.h         xr29,  xr29,  xr30
    xvclip.h        xr27,  xr27,  xr4,   xr3
    xvclip.h        xr28,  xr28,  xr4,   xr3

    xvpickev.b      xr16,  xr25,  xr20
    xvpickev.b      xr17,  xr23,  xr22
    xvabsd.bu       xr5,   xr16,  xr17
    xvaddi.hu       xr6,   xr3,   1
    xvslt.bu        xr5,   xr5,   xr2
    xvilvl.b        xr30,  xr5,   xr5
    xvilvh.b        xr31,  xr5,   xr5
    xvbitsel.v      xr3,   xr3,   xr6,   xr30

    xvsrari.h       xr29,  xr29,  3
    xvaddi.hu       xr6,   xr3,   1
    xvbitsel.v      xr3,   xr3,   xr6,   xr31
    xvneg.h         xr4,   xr3

    xvclip.h        xr29,  xr29,  xr4,   xr3
    xvadd.h         xr30,  xr21,  xr27
    xvadd.h         xr18,  xr24,  xr28
    xvadd.h         xr19,  xr22,  xr29
    xvsub.h         xr26,  xr23,  xr29
    xvssrarni.bu.h  xr26,  xr19,  0

    xvpickev.b      xr25,  xr18,  xr30
    xvpickev.b      xr27,  xr24,  xr21
    xvpickev.b      xr28,  xr23,  xr22
    xvpickev.b      xr18,  xr22,  xr21

    xvabsd.bu       xr19,  xr18,  xr17
    xvreplgr2vr.b   xr30,  a2
    xvilvl.d        xr31,  xr30,  xr2
    xvabsd.bu       xr20,  xr14,  xr13
    xvslt.bu        xr19,  xr19,  xr31
    xvslt.bu        xr20,  xr20,  xr2

    xvbitsel.v      xr25,  xr27,  xr25,  xr5
    xvpermi.d       xr20,  xr20,  0x50
    xvand.v         xr21,  xr20,  xr19
    xvpermi.d       xr7,   xr21,  0xB1
    xvand.v         xr21,  xr21,  xr7
    xvbitsel.v      xr25,  xr27,  xr25,  xr21
    xvpermi.d       xr1,   xr1,   0x50
    xvbitsel.v      xr26,  xr28,  xr26,  xr21
    xvslti.b        xr30,  xr1,   0
    xvbitsel.v      xr25,  xr25,  xr27,  xr30
    xvbitsel.v      xr26,  xr26,  xr28,  xr30

    xvilvl.b        xr10,  xr26,  xr25
    xvilvh.b        xr20,  xr25,  xr26
    xvilvl.h        xr21,  xr20,  xr10
    xvilvh.h        xr22,  xr20,  xr10

    // Store data to pix
    addi.d          t5,    a0,    -2
    xvstelm.w       xr21,  t5,    0,     0
    add.d           t5,    t5,    a1
    xvstelm.w       xr21,  t5,    0,     1
    add.d           t5,    t5,    a1
    xvstelm.w       xr21,  t5,    0,     2
    add.d           t5,    t5,    a1
    xvstelm.w       xr21,  t5,    0,     3
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     0
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     1
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     2
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     3
    add.d           t5,    t5,    a1
    xvstelm.w       xr21,  t5,    0,     4
    add.d           t5,    t5,    a1
    xvstelm.w       xr21,  t5,    0,     5
    add.d           t5,    t5,    a1
    xvstelm.w       xr21,  t5,    0,     6
    add.d           t5,    t5,    a1
    xvstelm.w       xr21,  t5,    0,     7
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     4
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     5
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     6
    add.d           t5,    t5,    a1
    xvstelm.w       xr22,  t5,    0,     7
    fld.d           f24,   sp,    0
    fld.d           f25,   sp,    8
    fld.d           f26,   sp,    16
    fld.d           f27,   sp,    24
    fld.d           f28,   sp,    32
    fld.d           f29,   sp,    40
    fld.d           f30,   sp,    48
    fld.d           f31,   sp,    56
    addi.d          sp,    sp,    64
endfunc_x264

/*
 * void deblock_v_luma_lasx(Pixel *pix, intptr_t stride,
 *                          int alpha, int beta, int8_t *tc0)
 */
function_x264 deblock_v_luma_lasx
    slli.d          t0,    a1,    1

    // Load data from tc0
    xvldrepl.w      xr1,   a4,    0
    add.d           t1,    t0,    a1
    xvreplgr2vr.b   xr2,   a3
    xvilvl.b        xr1,   xr1,   xr1

    // Load data from pix
    sub.d           t5,    a0,    t1
    vld             vr10,  t5,    0
    vldx            vr11,  t5,    a1
    vldx            vr12,  t5,    t0
    vld             vr13,  a0,    0
    vldx            vr14,  a0,    a1
    vldx            vr15,  a0,    t0

    // Store registers to the stack
    addi.d          sp,    sp,    -64
    fst.d           f24,   sp,    0
    fst.d           f25,   sp,    8
    fst.d           f26,   sp,    16
    fst.d           f27,   sp,    24
    fst.d           f28,   sp,    32
    fst.d           f29,   sp,    40
    fst.d           f30,   sp,    48
    fst.d           f31,   sp,    56
    xvilvl.h        xr1,   xr1,   xr1
    vext2xv.hu.bu   xr20,  xr10
    vext2xv.hu.bu   xr21,  xr11
    vext2xv.hu.bu   xr22,  xr12
    vext2xv.hu.bu   xr23,  xr13
    vext2xv.hu.bu   xr24,  xr14
    vext2xv.hu.bu   xr25,  xr15
    vext2xv.h.b     xr3,   xr1

    xvadd.h         xr26,  xr22,  xr23
    xvsrari.h       xr26,  xr26,  1
    xvneg.h         xr4,   xr3
    xvadd.h         xr27,  xr20,  xr26
    xvadd.h         xr28,  xr25,  xr26
    xvsub.h         xr29,  xr23,  xr22
    xvsrai.h        xr27,  xr27,  1
    xvsrai.h        xr28,  xr28,  1
    xvslli.h        xr29,  xr29,  2
    xvsub.h         xr30,  xr21,  xr24
    xvsub.h         xr27,  xr27,  xr21
    xvsub.h         xr28,  xr28,  xr24
    xvadd.h         xr29,  xr29,  xr30
    xvclip.h        xr27,  xr27,  xr4,   xr3
    xvclip.h        xr28,  xr28,  xr4,   xr3

    xvpickev.b      xr16,  xr25,  xr20
    xvpickev.b      xr17,  xr23,  xr22
    xvabsd.bu       xr5,   xr16,  xr17
    xvaddi.hu       xr6,   xr3,   1
    xvslt.bu        xr5,   xr5,   xr2
    xvilvl.b        xr30,  xr5,   xr5
    xvilvh.b        xr31,  xr5,   xr5
    xvbitsel.v      xr3,   xr3,   xr6,   xr30

    xvsrari.h       xr29,  xr29,  3
    xvaddi.hu       xr6,   xr3,   1
    xvbitsel.v      xr3,   xr3,   xr6,   xr31
    xvneg.h         xr4,   xr3

    xvclip.h        xr29,  xr29,  xr4,   xr3
    xvadd.h         xr30,  xr21,  xr27
    xvadd.h         xr18,  xr24,  xr28
    xvadd.h         xr19,  xr22,  xr29
    xvsub.h         xr26,  xr23,  xr29
    xvssrarni.bu.h  xr26,  xr19,  0

    xvpickev.b      xr25,  xr18,  xr30
    xvpickev.b      xr27,  xr24,  xr21
    xvpickev.b      xr28,  xr23,  xr22
    xvpickev.b      xr18,  xr22,  xr21

    xvabsd.bu       xr19,  xr18,  xr17
    xvreplgr2vr.b   xr30,  a2
    xvilvl.d        xr31,  xr30,  xr2
    xvabsd.bu       xr20,  xr14,  xr13
    xvslt.bu        xr19,  xr19,  xr31
    xvslt.bu        xr20,  xr20,  xr2

    xvbitsel.v      xr25,  xr27,  xr25,  xr5
    xvpermi.d       xr20,  xr20,  0x50
    xvand.v         xr21,  xr20,  xr19
    xvpermi.d       xr7,   xr21,  0xB1
    xvand.v         xr21,  xr21,  xr7
    xvbitsel.v      xr25,  xr27,  xr25,  xr21
    xvpermi.d       xr1,   xr1,   0x50
    xvbitsel.v      xr26,  xr28,  xr26,  xr21
    xvslti.b        xr30,  xr1,   0
    xvbitsel.v      xr25,  xr25,  xr27,  xr30
    xvbitsel.v      xr26,  xr26,  xr28,  xr30

    sub.d           t5,    a0,    t0
    xvpermi.d       xr0,   xr25,  0xd8
    xvpermi.d       xr1,   xr26,  0xd8
    xvpermi.d       xr2,   xr26,  0x8D
    xvpermi.d       xr3,   xr25,  0x8D

    // Store data to pix
    vst             vr0,   t5,    0
    vstx            vr1,   t5,    a1
    vst             vr2,   a0,    0
    vstx            vr3,   a0,    a1
    fld.d           f24,   sp,    0
    fld.d           f25,   sp,    8
    fld.d           f26,   sp,    16
    fld.d           f27,   sp,    24
    fld.d           f28,   sp,    32
    fld.d           f29,   sp,    40
    fld.d           f30,   sp,    48
    fld.d           f31,   sp,    56
    addi.d          sp,    sp,    64
endfunc_x264

/*
 * void deblock_v_luma_intra_lasx(Pixel *pix, intptr_t stride,
 *                                int alpha, int beta)
 */
function_x264 deblock_v_luma_intra_lasx
    slli.d          t0,    a1,    1
    slli.d          t2,    a1,    2
    add.d           t1,    t0,    a1

    // Load data from pix
    sub.d           t5,    a0,    t2
    vld             vr9,   t5,    0
    vldx            vr10,  t5,    a1
    vldx            vr11,  t5,    t0
    vldx            vr12,  t5,    t1
    vld             vr13,  a0,    0
    vldx            vr14,  a0,    a1
    vldx            vr15,  a0,    t0
    vldx            vr16,  a0,    t1

    // Store registers to the stack
    addi.d          sp,    sp,    -64
    fst.d           f24,   sp,    0
    fst.d           f25,   sp,    8
    fst.d           f26,   sp,    16
    fst.d           f27,   sp,    24
    fst.d           f28,   sp,    32
    fst.d           f29,   sp,    40
    fst.d           f30,   sp,    48
    fst.d           f31,   sp,    56
    xvreplgr2vr.b   xr1,   a2
    xvreplgr2vr.b   xr2,   a3

    vext2xv.hu.bu   xr19,  xr9
    vext2xv.hu.bu   xr20,  xr10
    vext2xv.hu.bu   xr21,  xr11
    vext2xv.hu.bu   xr22,  xr12
    vext2xv.hu.bu   xr23,  xr13
    vext2xv.hu.bu   xr24,  xr14
    vext2xv.hu.bu   xr25,  xr15
    vext2xv.hu.bu   xr26,  xr16

    xvadd.h         xr27,  xr21,  xr22
    xvadd.h         xr29,  xr19,  xr20
    xvadd.h         xr3,   xr27,  xr23
    xvadd.h         xr6,   xr27,  xr24
    xvadd.h         xr4,   xr3,   xr20

    xvslli.h        xr29,  xr29,  1
    xvadd.h         xr5,   xr6,   xr4
    xvadd.h         xr6,   xr6,   xr21
    xvadd.h         xr5,   xr5,   xr23
    xvadd.h         xr7,   xr29,  xr4

    xvsrari.h       xr3,   xr4,   2
    xvsrari.h       xr6,   xr6,   2
    xvsrari.h       xr4,   xr5,   3
    xvadd.h         xr27,  xr24,  xr23
    xvadd.h         xr28,  xr26,  xr25
    xvsrari.h       xr5,   xr7,   3

    xvadd.h         xr29,  xr22,  xr27
    xvslli.h        xr28,  xr28,  1
    xvadd.h         xr7,   xr29,  xr25
    xvadd.h         xr17,  xr27,  xr21
    xvadd.h         xr8,   xr7,   xr28
    xvadd.h         xr18,  xr17,  xr7
    xvadd.h         xr17,  xr17,  xr24
    xvadd.h         xr18,  xr18,  xr22

    xvsrari.h       xr7,   xr7,   2
    xvsrari.h       xr8,   xr8,   3
    xvsrari.h       xr18,  xr18,  3
    xvsrari.h       xr17,  xr17,  2

    xvpickev.b      xr27,  xr25,  xr20
    xvpickev.b      xr28,  xr24,  xr21
    xvpickev.b      xr29,  xr23,  xr22

    xvpickev.b      xr9,   xr8,   xr5
    xvpickev.b      xr16,  xr7,   xr3
    xvabsd.bu       xr30,  xr27,  xr29
    xvpickev.b      xr19,  xr18,  xr4
    xvpickev.b      xr26,  xr17,  xr6

    xvslt.bu        xr31,  xr30,  xr2
    xvabsd.bu       xr20,  xr12,  xr13
    xvabsd.bu       xr21,  xr11,  xr12
    xvabsd.bu       xr22,  xr14,  xr13
    xvsrli.b        xr0,   xr1,   2
    xvbitsel.v      xr19,  xr26,  xr19,  xr31
    xvbitsel.v      xr9,   xr27,  xr9,   xr31
    xvbitsel.v      xr16,  xr28,  xr16,  xr31
    xvaddi.bu       xr0,   xr0,   2
    xvpermi.d       xr20,  xr20,  0x50
    xvpermi.d       xr21,  xr21,  0x50
    xvpermi.d       xr22,  xr22,  0x50
    xvslt.bu        xr10,  xr20,  xr0
    xvslt.bu        xr11,  xr20,  xr1
    xvslt.bu        xr12,  xr21,  xr2
    xvslt.bu        xr13,  xr22,  xr2
    xvand.v         xr30,  xr11,  xr12
    xvand.v         xr30,  xr30,  xr13
    xvbitsel.v      xr9,   xr27,  xr9,   xr10
    xvbitsel.v      xr16,  xr28,  xr16,  xr10
    xvbitsel.v      xr19,  xr26,  xr19,  xr10
    xvbitsel.v      xr9,   xr27,  xr9,   xr30
    xvbitsel.v      xr16,  xr28,  xr16,  xr30
    xvbitsel.v      xr19,  xr29,  xr19,  xr30
    xvpermi.d       xr1,   xr9,   0xD8
    xvpermi.d       xr2,   xr16,  0xD8
    xvpermi.d       xr3,   xr19,  0xD8
    xvpermi.d       xr4,   xr19,  0x8D
    xvpermi.d       xr5,   xr16,  0x8D
    xvpermi.d       xr6,   xr9,   0x8D

    // Store data to pix
    vstx            vr1,   t5,    a1
    vstx            vr2,   t5,    t0
    vstx            vr3,   t5,    t1
    vst             vr4,   a0,    0
    vstx            vr5,   a0,    a1
    vstx            vr6,   a0,    t0

    // Restore register values
    fld.d           f24,   sp,    0
    fld.d           f25,   sp,    8
    fld.d           f26,   sp,    16
    fld.d           f27,   sp,    24
    fld.d           f28,   sp,    32
    fld.d           f29,   sp,    40
    fld.d           f30,   sp,    48
    fld.d           f31,   sp,    56
    addi.d          sp,    sp,    64
endfunc_x264

/*
 * void deblock_h_luma_intra_lasx(Pixel *pix, intptr_t stride,
 *                                int alpha, int beta)
 */
function_x264 deblock_h_luma_intra_lasx
    slli.d          t0,    a1,    1
    slli.d          t2,    a1,    2
    addi.d          t5,    a0,    -4
    add.d           t1,    t0,    a1

    // Store registers to the stack
    addi.d          sp,    sp,    -64
    fst.d           f24,   sp,    0
    fst.d           f25,   sp,    8
    fst.d           f26,   sp,    16
    fst.d           f27,   sp,    24
    fst.d           f28,   sp,    32
    fst.d           f29,   sp,    40
    fst.d           f30,   sp,    48
    fst.d           f31,   sp,    56

    // Load data from pix
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f10, f11, f12, f13
    add.d           t5,    t5,    t2
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f14, f15, f16, f17
    add.d           t5,    t5,    t2
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f20, f21, f22, f23
    add.d           t5,    t5,    t2
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f24, f25, f26, f27

    LASX_TRANSPOSE16X8_B   xr10, xr11, xr12, xr13, xr14, xr15, xr16, xr17, \
                           xr20, xr21, xr22, xr23, xr24, xr25, xr26, xr27, \
                           xr9,  xr10, xr11, xr12, xr13, xr14, xr15, xr16, \
                           xr0,  xr1,  xr2,  xr3,  xr4,  xr5,  xr6,  xr7

    xvreplgr2vr.b   xr1,   a2
    xvreplgr2vr.b   xr2,   a3
    vext2xv.hu.bu   xr19,  xr9
    vext2xv.hu.bu   xr20,  xr10
    vext2xv.hu.bu   xr21,  xr11
    vext2xv.hu.bu   xr22,  xr12
    vext2xv.hu.bu   xr23,  xr13
    vext2xv.hu.bu   xr24,  xr14
    vext2xv.hu.bu   xr25,  xr15
    vext2xv.hu.bu   xr26,  xr16

    xvadd.h         xr27,  xr21,  xr22
    xvadd.h         xr29,  xr19,  xr20
    xvadd.h         xr3,   xr27,  xr23
    xvadd.h         xr6,   xr27,  xr24
    xvadd.h         xr4,   xr3,   xr20

    xvslli.h        xr29,  xr29,  1
    xvadd.h         xr5,   xr6,   xr4
    xvadd.h         xr6,   xr6,   xr21
    xvadd.h         xr5,   xr5,   xr23
    xvadd.h         xr7,   xr29,  xr4

    xvsrari.h       xr3,   xr4,   2
    xvsrari.h       xr6,   xr6,   2
    xvsrari.h       xr4,   xr5,   3
    xvadd.h         xr27,  xr24,  xr23
    xvadd.h         xr28,  xr26,  xr25
    xvsrari.h       xr5,   xr7,   3

    xvadd.h         xr29,  xr22,  xr27
    xvslli.h        xr28,  xr28,  1
    xvadd.h         xr7,   xr29,  xr25
    xvadd.h         xr17,  xr27,  xr21
    xvadd.h         xr8,   xr7,   xr28
    xvadd.h         xr18,  xr17,  xr7
    xvadd.h         xr17,  xr17,  xr24
    xvadd.h         xr18,  xr18,  xr22

    xvsrari.h       xr7,   xr7,   2
    xvsrari.h       xr8,   xr8,   3
    xvsrari.h       xr18,  xr18,  3
    xvsrari.h       xr17,  xr17,  2

    xvpickev.b      xr27,  xr25,  xr20
    xvpickev.b      xr28,  xr24,  xr21
    xvpickev.b      xr29,  xr23,  xr22

    xvpickev.b      xr9,   xr8,   xr5
    xvpickev.b      xr16,  xr7,   xr3
    xvabsd.bu       xr30,  xr27,  xr29
    xvpickev.b      xr19,  xr18,  xr4
    xvpickev.b      xr26,  xr17,  xr6

    xvslt.bu        xr31,  xr30,  xr2
    xvabsd.bu       xr20,  xr12,  xr13
    xvabsd.bu       xr21,  xr11,  xr12
    xvabsd.bu       xr22,  xr14,  xr13
    xvsrli.b        xr0,   xr1,   2
    xvbitsel.v      xr19,  xr26,  xr19,  xr31
    xvbitsel.v      xr9,   xr27,  xr9,   xr31
    xvbitsel.v      xr16,  xr28,  xr16,  xr31
    xvaddi.bu       xr0,   xr0,   2
    xvpermi.d       xr20,  xr20,  0x50
    xvpermi.d       xr21,  xr21,  0x50
    xvpermi.d       xr22,  xr22,  0x50
    xvslt.bu        xr10,  xr20,  xr0
    xvslt.bu        xr11,  xr20,  xr1
    xvslt.bu        xr12,  xr21,  xr2
    xvslt.bu        xr13,  xr22,  xr2
    xvand.v         xr30,  xr11,  xr12
    xvand.v         xr30,  xr30,  xr13
    xvbitsel.v      xr9,   xr27,  xr9,   xr10
    xvbitsel.v      xr16,  xr28,  xr16,  xr10
    xvbitsel.v      xr19,  xr26,  xr19,  xr10

    xvbitsel.v      xr9,   xr27,  xr9,   xr30
    xvbitsel.v      xr16,  xr28,  xr16,  xr30
    xvbitsel.v      xr19,  xr29,  xr19,  xr30

    xvilvl.b        xr0,   xr16,  xr9
    xvpermi.d       xr18,  xr19,  0xB1
    xvilvh.b        xr1,   xr9,   xr16
    xvilvl.b        xr2,   xr18,  xr19
    addi.d          t5,    a0,    -3
    xvilvl.h        xr3,   xr2,   xr0
    xvilvh.h        xr4,   xr2,   xr0

    // Store data to pix
    xvstelm.w       xr3,   t5,    0,     0
    xvstelm.h       xr1,   t5,    4,     0
    add.d           t5,    t5,    a1
    xvstelm.w       xr3,   t5,    0,     1
    xvstelm.h       xr1,   t5,    4,     1
    add.d           t5,    t5,    a1
    xvstelm.w       xr3,   t5,    0,     2
    xvstelm.h       xr1,   t5,    4,     2
    add.d           t5,    t5,    a1
    xvstelm.w       xr3,   t5,    0,     3
    xvstelm.h       xr1,   t5,    4,     3
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     0
    xvstelm.h       xr1,   t5,    4,     4
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     1
    xvstelm.h       xr1,   t5,    4,     5
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     2
    xvstelm.h       xr1,   t5,    4,     6
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     3
    xvstelm.h       xr1,   t5,    4,     7
    add.d           t5,    t5,    a1
    xvstelm.w       xr3,   t5,    0,     4
    xvstelm.h       xr1,   t5,    4,     8
    add.d           t5,    t5,    a1
    xvstelm.w       xr3,   t5,    0,     5
    xvstelm.h       xr1,   t5,    4,     9
    add.d           t5,    t5,    a1
    xvstelm.w       xr3,   t5,    0,     6
    xvstelm.h       xr1,   t5,    4,     10
    add.d           t5,    t5,    a1
    xvstelm.w       xr3,   t5,    0,     7
    xvstelm.h       xr1,   t5,    4,     11
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     4
    xvstelm.h       xr1,   t5,    4,     12
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     5
    xvstelm.h       xr1,   t5,    4,     13
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     6
    xvstelm.h       xr1,   t5,    4,     14
    add.d           t5,    t5,    a1
    xvstelm.w       xr4,   t5,    0,     7
    xvstelm.h       xr1,   t5,    4,     15
    fld.d           f24,   sp,    0
    fld.d           f25,   sp,    8
    fld.d           f26,   sp,    16
    fld.d           f27,   sp,    24
    fld.d           f28,   sp,    32
    fld.d           f29,   sp,    40
    fld.d           f30,   sp,    48
    fld.d           f31,   sp,    56
    addi.d          sp,    sp,    64
endfunc_x264

/*
 * void deblock_strength_c( uint8_t nnz[X264_SCAN8_SIZE], int8_t ref[2][X264_SCAN8_LUMA_SIZE],
 *                          int16_t mv[2][X264_SCAN8_LUMA_SIZE][2], uint8_t bs[2][8][4],
 *                          int mvy_limit, int bframe )
 */
function_x264 deblock_strength_lasx
    // dir = 0 s1 = 8 s2 = 1
    vldi            vr18,  2
    vldi            vr19,  1
    addi.d          t0,    zero,  4
    xvreplgr2vr.h   xr20,  t0
    xvreplgr2vr.h   xr21,  a4

    xvld            xr0,   a0,    11
    xvpermi.q       xr1,   xr0,   0x01
    la.local        t0,    shuf_loc_locn
    xvld            xr23,  t0,    0
    xvshuf.b        xr4,   xr1,   xr0,    xr23
    xvpermi.q       xr5,   xr4,   0x01
    vor.v           vr6,   vr4,   vr5
    vseqi.b         vr6,   vr6,   0
    vmov            vr15,  vr6
    vxor.v          vr8,   vr8,   vr8
    vbitsel.v       vr8,   vr18,  vr8,   vr6

    xvld            xr0,   a1,    11
    xvpermi.q       xr1,   xr0,   0x01
    xvshuf.b        xr4,   xr1,   xr0,   xr23
    xvpermi.q       xr5,   xr4,   0x01
    vseq.b          vr4,   vr4,   vr5
    vseqi.b         vr4,   vr4,   0

    vld             vr0,   a2,    44
    vld             vr1,   a2,    76
    vld             vr5,   a2,    108
    vld             vr6,   a2,    140
    vilvl.h         vr9,   vr1,   vr0
    vilvl.h         vr10,  vr6,   vr5
    vilvl.w         vr11,  vr10,  vr9
    vilvh.w         vr12,  vr10,  vr9
    vilvh.h         vr9,   vr1,   vr0
    vilvh.h         vr10,  vr6,   vr5
    vilvl.w         vr13,  vr10,  vr9
    vilvh.w         vr14,  vr10,  vr9

    vilvl.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    60
    ld.h            t1,    a2,    92
    ld.h            t2,    a2,    124
    ld.h            t3,    a2,    156
    vmov            vr6,   vr14
    vinsgr2vr.h     vr6,   t0,    4
    vinsgr2vr.h     vr6,   t1,    5
    vinsgr2vr.h     vr6,   t2,    6
    vinsgr2vr.h     vr6,   t3,    7
    vilvl.d         vr1,   vr12,  vr11
    vilvl.d         vr5,   vr14,  vr13
    xvpermi.q       xr0,   xr6,   0x02  // mv[0][loc][0]
    xvpermi.q       xr5,   xr1,   0x20  // mv[0][locn][0]
    xvabsd.h        xr5,   xr0,   xr5
    xvsle.h         xr5,   xr20,  xr5

    vilvh.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    62
    ld.h            t1,    a2,    94
    ld.h            t2,    a2,    126
    ld.h            t3,    a2,    158
    vbsrl.v         vr7,   vr14,  8
    vinsgr2vr.h     vr7,   t0,    4
    vinsgr2vr.h     vr7,   t1,    5
    vinsgr2vr.h     vr7,   t2,    6
    vinsgr2vr.h     vr7,   t3,    7
    vilvh.d         vr1,   vr12,  vr11
    vilvh.d         vr6,   vr14,  vr13
    xvpermi.q       xr0,   xr7,   0x02  // mv[0][loc][1]
    xvpermi.q       xr6,   xr1,   0x20  // mv[0][locn][1]
    xvabsd.h        xr6,   xr0,   xr6
    xvsle.h         xr6,   xr21,  xr6
    xvor.v          xr5,   xr5,   xr6
    xvpickev.b      xr5,   xr5,   xr5
    xvpermi.d       xr5,   xr5,   0xd8
    vor.v           vr17,  vr4,   vr5

    beqz            a5,    .bframe_iszero_0
    // bframe != 0
    xvld            xr0,   a1,    51
    xvpermi.q       xr1,   xr0,   0x01
    xvshuf.b        xr4,   xr1,   xr0,   xr23
    xvpermi.q       xr5,   xr4,   0x01
    vseq.b          vr4,   vr4,   vr5
    vseqi.b         vr4,   vr4,   0

    vld             vr0,   a2,    204
    vld             vr1,   a2,    236
    vld             vr5,   a2,    268
    vld             vr6,   a2,    300
    vilvl.h         vr9,   vr1,   vr0
    vilvl.h         vr10,  vr6,   vr5
    vilvl.w         vr11,  vr10,  vr9
    vilvh.w         vr12,  vr10,  vr9
    vilvh.h         vr9,   vr1,   vr0
    vilvh.h         vr10,  vr6,   vr5
    vilvl.w         vr13,  vr10,  vr9
    vilvh.w         vr14,  vr10,  vr9

    vilvl.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    220
    ld.h            t1,    a2,    252
    ld.h            t2,    a2,    284
    ld.h            t3,    a2,    316
    vmov            vr6,   vr14
    vinsgr2vr.h     vr6,   t0,    4
    vinsgr2vr.h     vr6,   t1,    5
    vinsgr2vr.h     vr6,   t2,    6
    vinsgr2vr.h     vr6,   t3,    7
    vilvl.d         vr1,   vr12,  vr11
    vilvl.d         vr5,   vr14,  vr13
    xvpermi.q       xr0,   xr6,   0x02  // mv[1][loc][0]
    xvpermi.q       xr5,   xr1,   0x20  // mv[1][locn][0]
    xvabsd.h        xr5,   xr0,   xr5
    xvsle.h         xr5,   xr20,  xr5

    vilvh.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    222
    ld.h            t1,    a2,    254
    ld.h            t2,    a2,    286
    ld.h            t3,    a2,    318
    vbsrl.v         vr7,   vr14,  8
    vinsgr2vr.h     vr7,   t0,    4
    vinsgr2vr.h     vr7,   t1,    5
    vinsgr2vr.h     vr7,   t2,    6
    vinsgr2vr.h     vr7,   t3,    7
    vilvh.d         vr1,   vr12,  vr11
    vilvh.d         vr6,   vr14,  vr13
    xvpermi.q       xr0,   xr7,   0x02  // mv[1][loc][1]
    xvpermi.q       xr6,   xr1,   0x20  // mv[1][locn][1]
    xvabsd.h        xr6,   xr0,   xr6
    xvsle.h         xr6,   xr21,  xr6
    xvor.v          xr5,   xr5,   xr6
    xvpickev.b      xr5,   xr5,   xr5
    xvpermi.d       xr5,   xr5,   0xd8
    vor.v           vr5,   vr5,   vr4
    vor.v           vr17,  vr5,   vr17

.bframe_iszero_0:
    vxor.v          vr22,  vr22,  vr22
    vbitsel.v       vr22,  vr22,  vr19,  vr17
    vbitsel.v       vr22,  vr8,   vr22,  vr15
    vst             vr22,  a3,    0

    // dir = 1 s1 = 1 s2 = 8
    vld             vr0,   a0,    4
    vld             vr1,   a0,    20
    ld.wu           t0,    a0,    36
    vpickev.w       vr2,   vr1,   vr0
    vbsrl.v         vr3,   vr2,   4
    vinsgr2vr.w     vr3,   t0,    3
    vor.v           vr2,   vr3,   vr2
    vseqi.b         vr2,   vr2,   0
    vmov            vr15,  vr2
    vxor.v          vr3,   vr3,   vr3
    vbitsel.v       vr3,   vr18,  vr3,   vr2

    vld             vr0,   a1,    4
    vld             vr1,   a1,    20
    ld.w            t0,    a1,    36
    vpickev.w       vr2,   vr1,   vr0
    vbsrl.v         vr4,   vr2,   4
    vinsgr2vr.w     vr4,   t0,    3
    vseq.b          vr2,   vr4,   vr2
    vseqi.b         vr2,   vr2,   0

    vld             vr0,   a2,    16
    vld             vr1,   a2,    48
    vld             vr12,  a2,    80
    vld             vr13,  a2,    112
    vld             vr4,   a2,    144
    vpickev.h       vr5,   vr1,   vr0
    vpickev.h       vr14,  vr13,  vr12
    xvpermi.q       xr5,   xr14,  0x02  // mv[0][locn][0]
    vpickev.h       vr7,   vr4,   vr4
    xvpermi.d       xr6,   xr5,   0x39
    xvinsve0.d      xr6,   xr7,   3     // mv[0][loc][0]
    xvabsd.h        xr5,   xr6,   xr5
    xvsle.h         xr5,   xr20,  xr5

    vpickod.h       vr6,   vr1,   vr0
    vpickod.h       vr14,  vr13,  vr12
    xvpermi.q       xr6,   xr14,  0x02  // mv[0][locn][1]
    vpickod.h       vr7,   vr4,   vr4
    xvpermi.d       xr8,   xr6,   0x39
    xvinsve0.d      xr8,   xr7,   3     // mv[0][loc][1]
    xvabsd.h        xr6,   xr8,   xr6
    xvsle.h         xr6,   xr21,  xr6

    xvor.v          xr5,   xr6,   xr5
    xvpickev.b      xr6,   xr5,   xr5
    xvpermi.d       xr6,   xr6,   0xd8
    vor.v           vr2,   vr6,   vr2

    beqz            a5,    .bframe_iszero_1
    // bframe != 0 ref[1]
    vld             vr0,   a1,    44
    vld             vr1,   a1,    60
    ld.w            t0,    a1,    76
    vpickev.w       vr0,   vr1,   vr0
    vbsrl.v         vr1,   vr0,   4
    vinsgr2vr.w     vr1,   t0,    3
    vseq.b          vr11,  vr1,   vr0
    vseqi.b         vr11,  vr11,  0

    vld             vr0,   a2,    176
    vld             vr1,   a2,    208
    vld             vr12,  a2,    240
    vld             vr13,  a2,    272
    vld             vr4,   a2,    304
    vpickev.h       vr5,   vr1,   vr0
    vpickev.h       vr14,  vr13,  vr12
    xvpermi.q       xr5,   xr14,  0x02  // mv[1][locn][0]
    vpickev.h       vr7,   vr4,   vr4
    xvpermi.d       xr6,   xr5,   0x39
    xvinsve0.d      xr6,   xr7,   3     // mv[1][loc][0]
    xvabsd.h        xr5,   xr6,   xr5
    xvsle.h         xr5,   xr20,  xr5

    vpickod.h       vr6,   vr1,   vr0
    vpickod.h       vr14,  vr13,  vr12
    xvpermi.q       xr6,   xr14,  0x02  // mv[1][locn][1]
    vpickod.h       vr7,   vr4,   vr4
    xvpermi.d       xr8,   xr6,   0x39
    xvinsve0.d      xr8,   xr7,   3     // mv[1][loc][1]
    xvabsd.h        xr6,   xr8,   xr6
    xvsle.h         xr6,   xr21,  xr6

    xvor.v          xr5,   xr6,   xr5
    xvpickev.b      xr6,   xr5,   xr5
    xvpermi.d       xr6,   xr6,   0xd8
    vor.v           vr6,   vr6,   vr11
    vor.v           vr2,   vr6,   vr2

.bframe_iszero_1:
    vxor.v          vr22,  vr22,  vr22
    vbitsel.v       vr22,  vr22,  vr19,  vr2
    vbitsel.v       vr22,  vr3,   vr22,  vr15
    vst             vr22,  a3,    32
endfunc_x264

/*
 * void deblock_strength_c( uint8_t nnz[X264_SCAN8_SIZE], int8_t ref[2][X264_SCAN8_LUMA_SIZE],
 *                          int16_t mv[2][X264_SCAN8_LUMA_SIZE][2], uint8_t bs[2][8][4],
 *                          int mvy_limit, int bframe )
 */
function_x264 deblock_strength_lsx
    // dir = 0 s1 = 8 s2 = 1
    vldi            vr18,  2
    vldi            vr19,  1
    addi.d          t0,    zero,  4
    vreplgr2vr.h    vr20,  t0
    vreplgr2vr.h    vr21,  a4

    vld             vr0,   a0,    11
    vld             vr1,   a0,    27
    la.local        t0,    shuf_loc_locn
    la.local        t1,    shuf_locn
    vld             vr2,   t0,    0
    vld             vr3,   t1,    0
    vshuf.b         vr4,   vr1,   vr0,   vr2
    vshuf.b         vr5,   vr1,   vr0,   vr3
    vor.v           vr6,   vr4,   vr5
    vseqi.b         vr6,   vr6,   0
    vmov            vr15,  vr6
    vxor.v          vr8,   vr8,   vr8
    vbitsel.v       vr8,   vr18,  vr8,   vr6

    vld             vr0,   a1,    11
    vld             vr1,   a1,    27
    vshuf.b         vr4,   vr1,   vr0,   vr2
    vshuf.b         vr5,   vr1,   vr0,   vr3
    vseq.b          vr4,   vr4,   vr5
    vseqi.b         vr4,   vr4,   0

    vld             vr0,   a2,    44
    vld             vr1,   a2,    76
    vld             vr5,   a2,    108
    vld             vr6,   a2,    140
    vilvl.h         vr9,   vr1,   vr0
    vilvl.h         vr10,  vr6,   vr5
    vilvl.w         vr11,  vr10,  vr9
    vilvh.w         vr12,  vr10,  vr9
    vilvh.h         vr9,   vr1,   vr0
    vilvh.h         vr10,  vr6,   vr5
    vilvl.w         vr13,  vr10,  vr9
    vilvh.w         vr14,  vr10,  vr9

    vilvl.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    60
    ld.h            t1,    a2,    92
    ld.h            t2,    a2,    124
    ld.h            t3,    a2,    156
    vmov            vr6,   vr14
    vinsgr2vr.h     vr6,   t0,    4
    vinsgr2vr.h     vr6,   t1,    5
    vinsgr2vr.h     vr6,   t2,    6
    vinsgr2vr.h     vr6,   t3,    7
    vilvl.d         vr1,   vr12,  vr11
    vilvl.d         vr5,   vr14,  vr13
    vabsd.h         vr9,   vr0,   vr1
    vabsd.h         vr5,   vr6,   vr5
    vsle.h          vr9,   vr20,  vr9
    vsle.h          vr5,   vr20,  vr5

    vilvh.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    62
    ld.h            t1,    a2,    94
    ld.h            t2,    a2,    126
    ld.h            t3,    a2,    158
    vbsrl.v         vr7,   vr14,  8
    vinsgr2vr.h     vr7,   t0,    4
    vinsgr2vr.h     vr7,   t1,    5
    vinsgr2vr.h     vr7,   t2,    6
    vinsgr2vr.h     vr7,   t3,    7
    vilvh.d         vr1,   vr12,  vr11
    vilvh.d         vr6,   vr14,  vr13
    vabsd.h         vr0,   vr0,   vr1
    vabsd.h         vr6,   vr7,   vr6
    vsle.h          vr0,   vr21,  vr0
    vsle.h          vr6,   vr21,  vr6

    vor.v           vr9,   vr9,   vr0
    vor.v           vr5,   vr5,   vr6
    vpickev.b       vr5,   vr5,   vr9
    vor.v           vr17,  vr4,   vr5

    beqz            a5,    .bframeiszero_0_lsx
    // bframe != 0
    vld             vr0,   a1,    51
    vld             vr1,   a1,    67
    vshuf.b         vr4,   vr1,   vr0,   vr2
    vshuf.b         vr5,   vr1,   vr0,   vr3
    vseq.b          vr4,   vr4,   vr5
    vseqi.b         vr4,   vr4,   0

    vld             vr0,   a2,    204
    vld             vr1,   a2,    236
    vld             vr5,   a2,    268
    vld             vr6,   a2,    300
    vilvl.h         vr9,   vr1,   vr0
    vilvl.h         vr10,  vr6,   vr5
    vilvl.w         vr11,  vr10,  vr9
    vilvh.w         vr12,  vr10,  vr9
    vilvh.h         vr9,   vr1,   vr0
    vilvh.h         vr10,  vr6,   vr5
    vilvl.w         vr13,  vr10,  vr9
    vilvh.w         vr14,  vr10,  vr9

    vilvl.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    220
    ld.h            t1,    a2,    252
    ld.h            t2,    a2,    284
    ld.h            t3,    a2,    316
    vmov            vr6,   vr14
    vinsgr2vr.h     vr6,   t0,    4
    vinsgr2vr.h     vr6,   t1,    5
    vinsgr2vr.h     vr6,   t2,    6
    vinsgr2vr.h     vr6,   t3,    7
    vilvl.d         vr1,   vr12,  vr11
    vilvl.d         vr5,   vr14,  vr13
    vabsd.h         vr9,   vr0,   vr1
    vabsd.h         vr5,   vr6,   vr5
    vsle.h          vr9,   vr20,  vr9
    vsle.h          vr5,   vr20,  vr5

    vilvh.d         vr0,   vr13,  vr12
    ld.h            t0,    a2,    222
    ld.h            t1,    a2,    254
    ld.h            t2,    a2,    286
    ld.h            t3,    a2,    318
    vbsrl.v         vr7,   vr14,  8
    vinsgr2vr.h     vr7,   t0,    4
    vinsgr2vr.h     vr7,   t1,    5
    vinsgr2vr.h     vr7,   t2,    6
    vinsgr2vr.h     vr7,   t3,    7
    vilvh.d         vr1,   vr12,  vr11
    vilvh.d         vr6,   vr14,  vr13
    vabsd.h         vr0,   vr0,   vr1
    vabsd.h         vr6,   vr7,   vr6
    vsle.h          vr0,   vr21,  vr0
    vsle.h          vr6,   vr21,  vr6

    vor.v           vr9,   vr9,   vr0
    vor.v           vr5,   vr5,   vr6
    vpickev.b       vr5,   vr5,   vr9
    vor.v           vr5,   vr5,   vr4
    vor.v           vr17,  vr5,   vr17

.bframeiszero_0_lsx:
    vxor.v          vr22,  vr22,  vr22
    vbitsel.v       vr22,  vr22,  vr19,  vr17
    vbitsel.v       vr22,  vr8,   vr22,  vr15
    vst             vr22,  a3,    0

    // dir = 1 s1 = 1 s2 = 8
    vld             vr0,   a0,    4
    vld             vr1,   a0,    20
    ld.wu           t0,    a0,    36
    vpickev.w       vr2,   vr1,   vr0
    vbsrl.v         vr3,   vr2,   4
    vinsgr2vr.w     vr3,   t0,    3
    vor.v           vr2,   vr3,   vr2
    vseqi.b         vr2,   vr2,   0
    vmov            vr15,  vr2
    vxor.v          vr3,   vr3,   vr3
    vbitsel.v       vr3,   vr18,  vr3,   vr2

    vld             vr0,   a1,    4
    vld             vr1,   a1,    20
    ld.w            t0,    a1,    36
    vpickev.w       vr2,   vr1,   vr0
    vbsrl.v         vr4,   vr2,   4
    vinsgr2vr.w     vr4,   t0,    3
    vseq.b          vr2,   vr4,   vr2
    vseqi.b         vr2,   vr2,   0

    vld             vr0,   a2,    16
    vld             vr1,   a2,    48
    vld             vr12,  a2,    80
    vld             vr13,  a2,    112
    vld             vr4,   a2,    144
    vpickev.h       vr5,   vr1,   vr0
    vpickev.h       vr14,  vr13,  vr12
    vpickev.h       vr7,   vr4,   vr4
    vbsrl.v         vr6,   vr5,   8
    vilvl.d         vr6,   vr14,  vr6
    vilvh.d         vr9,   vr7,   vr14
    vabsd.h         vr5,   vr6,   vr5
    vabsd.h         vr9,   vr9,   vr14
    vsle.h          vr5,   vr20,  vr5
    vsle.h          vr9,   vr20,  vr9

    vpickod.h       vr6,   vr1,   vr0
    vpickod.h       vr14,  vr13,  vr12
    vpickod.h       vr7,   vr4,   vr4
    vbsrl.v         vr8,   vr6,   8
    vilvl.d         vr8,   vr14,  vr8
    vilvh.d         vr7,   vr7,   vr14
    vabsd.h         vr8,   vr8,   vr6
    vabsd.h         vr7,   vr7,   vr14
    vsle.h          vr8,   vr21,  vr8
    vsle.h          vr6,   vr21,  vr7

    vor.v           vr5,   vr5,   vr8
    vor.v           vr6,   vr9,   vr6
    vpickev.b       vr6,   vr6,   vr5
    vor.v           vr2,   vr6,   vr2

    beqz            a5,    .bframeiszero_1_lsx
    // bframe != 0 ref[1]
    vld             vr0,   a1,    44
    vld             vr1,   a1,    60
    ld.w            t0,    a1,    76
    vpickev.w       vr0,   vr1,   vr0
    vbsrl.v         vr1,   vr0,   4
    vinsgr2vr.w     vr1,   t0,    3
    vseq.b          vr11,  vr1,   vr0
    vseqi.b         vr11,  vr11,  0

    vld             vr0,   a2,    176
    vld             vr1,   a2,    208
    vld             vr12,  a2,    240
    vld             vr13,  a2,    272
    vld             vr4,   a2,    304
    vpickev.h       vr5,   vr1,   vr0
    vpickev.h       vr14,  vr13,  vr12
    vpickev.h       vr7,   vr4,   vr4
    vbsrl.v         vr6,   vr5,   8
    vilvl.d         vr6,   vr14,  vr6
    vilvh.d         vr9,   vr7,   vr14
    vabsd.h         vr5,   vr6,   vr5
    vabsd.h         vr9,   vr9,   vr14
    vsle.h          vr5,   vr20,  vr5
    vsle.h          vr9,   vr20,  vr9

    vpickod.h       vr6,   vr1,   vr0
    vpickod.h       vr14,  vr13,  vr12
    vpickod.h       vr7,   vr4,   vr4
    vbsrl.v         vr8,   vr6,   8
    vilvl.d         vr8,   vr14,  vr8
    vilvh.d         vr7,   vr7,   vr14
    vabsd.h         vr8,   vr8,   vr6
    vabsd.h         vr6,   vr7,   vr14
    vsle.h          vr8,   vr21,  vr8
    vsle.h          vr6,   vr21,  vr6

    vor.v           vr5,   vr5,   vr8
    vor.v           vr7,   vr9,   vr6
    vpickev.b       vr6,   vr7,   vr5
    vor.v           vr6,   vr6,   vr11
    vor.v           vr2,   vr6,   vr2

.bframeiszero_1_lsx:
    vxor.v          vr22,  vr22,  vr22
    vbitsel.v       vr22,  vr22,  vr19,  vr2
    vbitsel.v       vr22,  vr3,   vr22,  vr15
    vst             vr22,  a3,    32
endfunc_x264

/*
 * void deblock_v_luma_intra_lsx( pixel *pix, intptr_t stride, int alpha, int beta )
 */
function_x264 deblock_v_luma_intra_lsx
    slli.d          t0,    a1,    1
    add.d           t1,    t0,    a1
    slli.d          t2,    a1,    2

    // Store registers to the stack
    addi.d          sp,    sp,    -64
    fst.d           f24,   sp,    0
    fst.d           f25,   sp,    8
    fst.d           f26,   sp,    16
    fst.d           f27,   sp,    24
    fst.d           f28,   sp,    32
    fst.d           f29,   sp,    40
    fst.d           f30,   sp,    48
    fst.d           f31,   sp,    56

    // Load data from pix
    sub.d           t3,    a0,    t2 // t3 = a0 - 4 * stride
    vld             vr3,   t3,    0  // p3
    vldx            vr2,   t3,    a1 // p2
    vldx            vr1,   t3,    t0 // p1
    vldx            vr0,   t3,    t1 // p0
    vld             vr10,  a0,    0  // q0
    vldx            vr11,  a0,    a1 // q1
    vldx            vr12,  a0,    t0 // q2
    vldx            vr13,  a0,    t1 // q3

    vsllwil.hu.bu   vr7,   vr3,   0
    vsllwil.hu.bu   vr6,   vr2,   0
    vsllwil.hu.bu   vr5,   vr1,   0
    vsllwil.hu.bu   vr4,   vr0,   0
    vsllwil.hu.bu   vr14,  vr10,  0
    vsllwil.hu.bu   vr15,  vr11,  0
    vsllwil.hu.bu   vr16,  vr12,  0
    vsllwil.hu.bu   vr17,  vr13,  0

    /* p0', p1', p2' */
    vadd.h          vr8,   vr5,   vr4
    vadd.h          vr9,   vr8,   vr14
    vadd.h          vr19,  vr7,   vr6
    vadd.h          vr18,  vr6,   vr9    // pix[-2*xstride]
    vslli.h         vr19,  vr19,  1
    vadd.h          vr20,  vr9,   vr18
    vadd.h          vr19,  vr19,  vr18   // pix[-3*xstride]
    vadd.h          vr20,  vr20,  vr15   // pix[-1*xstride]

    /* p0' */
    vadd.h          vr8,   vr8,   vr15
    vadd.h          vr21,  vr8,   vr5    // pix[-1*xstride]

    // /* q0', q1', q2' */
    vadd.h          vr8,   vr15,  vr14
    vadd.h          vr9,   vr8,   vr4
    vadd.h          vr23,  vr17,  vr16
    vadd.h          vr22,  vr9,   vr16  // pix[1*xstride]
    vslli.h         vr23,  vr23,  1
    vadd.h          vr24,  vr9,   vr22
    vadd.h          vr23,  vr23,  vr22  // pix[2*xstride]
    vadd.h          vr24,  vr24,  vr5   // pix[0*xstride]

    /* q0' */
    vadd.h          vr8,   vr8,   vr5
    vadd.h          vr25,  vr8,   vr15  // pix[0*xstride]

    vexth.hu.bu     vr7,   vr3
    vexth.hu.bu     vr6,   vr2
    vexth.hu.bu     vr5,   vr1
    vexth.hu.bu     vr4,   vr0
    vexth.hu.bu     vr14,  vr10
    vexth.hu.bu     vr15,  vr11
    vexth.hu.bu     vr16,  vr12
    vexth.hu.bu     vr17,  vr13

    /* p0', p1', p2' */
    vadd.h          vr8,   vr5,   vr4
    vadd.h          vr9,   vr8,   vr14
    vadd.h          vr27,  vr6,   vr9   // pix[-2*xstride]
    vadd.h          vr28,  vr7,   vr6
    vslli.h         vr28,  vr28,  1
    vadd.h          vr29,  vr9,   vr27
    vadd.h          vr28,  vr28,  vr27  // pix[-3*xstride]
    vadd.h          vr29,  vr29,  vr15  // pix[-1*xstride]

    /* p0' */
    vadd.h          vr8,   vr8,   vr15
    vadd.h          vr30,  vr8,   vr5  // pix[-1*xstride]

    /* q0', q1', q2' */
    vadd.h          vr8,   vr15,  vr14
    vadd.h          vr9,   vr8,   vr4
    vadd.h          vr3,   vr17,  vr16
    vadd.h          vr31,  vr9,   vr16  // pix[1*xstride]
    vslli.h         vr3,   vr3,   1
    vadd.h          vr13,  vr9,   vr31
    vadd.h          vr3,   vr3,   vr31  // pix[2*xstride]
    vadd.h          vr13,  vr13,  vr5   // pix[0*xstride]

    /* q0' */
    vadd.h          vr8,   vr8,   vr5
    vadd.h          vr9,   vr8,   vr15  // pix[0*xstride]

    vsrarni.b.h     vr28,  vr19,  3     // pix[-3*xstride]
    vsrarni.b.h     vr27,  vr18,  2     // pix[-2*xstride]
    vsrarni.b.h     vr29,  vr20,  3     // pix[-1*xstride]
    vsrarni.b.h     vr30,  vr21,  2     // pix[-1*xstride] p0'
    vsrarni.b.h     vr13,  vr24,  3     // pix[ 0*xstride]
    vsrarni.b.h     vr31,  vr22,  2     // pix[ 1*xstride]
    vsrarni.b.h     vr3,   vr23,  3     // pix[ 2*xstride]
    vsrarni.b.h     vr9,   vr25,  2     // pix[ 0*xstride] q0'

    vreplgr2vr.b    vr18,  a2           // alpha
    vreplgr2vr.b    vr19,  a3           // beta

    vabsd.bu        vr26,  vr0,   vr10
    vabsd.bu        vr8,   vr1,   vr0
    vabsd.bu        vr16,  vr11,  vr10
    vslt.bu         vr20,  vr26,  vr18
    vslt.bu         vr21,  vr8,   vr19
    vslt.bu         vr22,  vr16,  vr19
    vand.v          vr20,  vr20,  vr21
    vand.v          vr20,  vr20,  vr22  // if_1

    vsrli.b         vr18,  vr18,  2
    vaddi.bu        vr18,  vr18,  2

    vslt.bu         vr26,  vr26,  vr18  // if_2

    vabsd.bu        vr23,   vr2,   vr0
    vslt.bu         vr23,   vr23,  vr19 // if_3

    vand.v          vr16,  vr23,  vr26  // if_2 && if_3
    vnor.v          vr24,  vr16,  vr16  // !(if_2 && if_3)
    vand.v          vr24,  vr24,  vr20  // if_1 && !(if_2 && if_3)
    vand.v          vr16,  vr16,  vr20  // if_1 && if_2 && if_3

    vbitsel.v       vr4,   vr2,   vr28, vr16  // pix[-3*xstride]
    vbitsel.v       vr5,   vr1,   vr27, vr16  // pix[-2*xstride]
    vbitsel.v       vr6,   vr0,   vr30, vr24
    vbitsel.v       vr6,   vr6,   vr29, vr16  // pix[-1*xstride]

    vabsd.bu        vr7,   vr12,  vr10
    vslt.bu         vr7,   vr7,   vr19  // if_4

    vand.v          vr17,  vr7,   vr26  // if_2 && if_4
    vnor.v          vr14,  vr17,  vr17  // !(if_2 && if_4)
    vand.v          vr14,  vr14,  vr20  // if_1 && !(if_2 && if_4)
    vand.v          vr17,  vr17,  vr20  // if_1 && if_2 && if_4

    vbitsel.v       vr15,  vr10,  vr9,  vr14
    vbitsel.v       vr15,  vr15,  vr13, vr17 // pix[ 0*xstride]
    vbitsel.v       vr9,   vr11,  vr31, vr17 // pix[ 1*xstride]
    vbitsel.v       vr13,  vr12,  vr3,  vr17 // pix[ 2*xstride]

    vstx            vr4,   t3,    a1
    vstx            vr5,   t3,    t0
    vstx            vr6,   t3,    t1
    vst             vr15,  a0,    0
    vstx            vr9,   a0,    a1
    vstx            vr13,  a0,    t0

    fld.d           f24,   sp,    0
    fld.d           f25,   sp,    8
    fld.d           f26,   sp,    16
    fld.d           f27,   sp,    24
    fld.d           f28,   sp,    32
    fld.d           f29,   sp,    40
    fld.d           f30,   sp,    48
    fld.d           f31,   sp,    56
    addi.d          sp,    sp,    64
endfunc_x264

/*
 * void deblock_h_luma_intra_c( pixel *pix, intptr_t stride, int alpha, int beta )
 */
function_x264 deblock_h_luma_intra_lsx
    slli.d          t0,    a1,    1
    slli.d          t2,    a1,    2
    addi.d          t5,    a0,    -4
    add.d           t1,    t0,    a1

    // Store registers to the stack
    addi.d          sp,    sp,    -64
    fst.d           f24,   sp,    0
    fst.d           f25,   sp,    8
    fst.d           f26,   sp,    16
    fst.d           f27,   sp,    24
    fst.d           f28,   sp,    32
    fst.d           f29,   sp,    40
    fst.d           f30,   sp,    48
    fst.d           f31,   sp,    56

    // Load data from pix
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f10, f11, f12, f13
    add.d           t5,    t5,    t2
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f14, f15, f16, f17
    add.d           t5,    t5,    t2
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f20, f21, f22, f23
    add.d           t5,    t5,    t2
    FLDD_LOADX_4    t5,    a1,    t0,    t1,    f24, f25, f26, f27

    vilvl.b         vr11,  vr11,  vr10
    vilvl.b         vr13,  vr13,  vr12
    vilvl.b         vr15,  vr15,  vr14
    vilvl.b         vr17,  vr17,  vr16
    vilvl.h         vr0,   vr13,  vr11
    vilvl.h         vr1,   vr17,  vr15
    vilvh.h         vr2,   vr13,  vr11
    vilvh.h         vr3,   vr17,  vr15
    vilvl.w         vr4,   vr1,   vr0
    vilvl.w         vr6,   vr3,   vr2
    vilvh.w         vr5,   vr1,   vr0
    vilvh.w         vr7,   vr3,   vr2

    vilvl.b         vr11,  vr21,  vr20
    vilvl.b         vr13,  vr23,  vr22
    vilvl.b         vr15,  vr25,  vr24
    vilvl.b         vr17,  vr27,  vr26
    vilvl.h         vr0,   vr13,  vr11
    vilvl.h         vr1,   vr17,  vr15
    vilvh.h         vr2,   vr13,  vr11
    vilvh.h         vr3,   vr17,  vr15
    vilvl.w         vr24,  vr1,   vr0
    vilvl.w         vr26,  vr3,   vr2
    vilvh.w         vr25,  vr1,   vr0
    vilvh.w         vr27,  vr3,   vr2

    vilvl.d         vr3,  vr24, vr4  // p3
    vilvh.d         vr2,  vr24, vr4  // p2
    vilvl.d         vr1,  vr25, vr5  // p1
    vilvh.d         vr0,  vr25, vr5  // p0
    vilvl.d         vr10, vr26, vr6  // q0
    vilvh.d         vr11, vr26, vr6  // q1
    vilvl.d         vr12, vr27, vr7  // q2
    vilvh.d         vr13, vr27, vr7  // q3

    vsllwil.hu.bu   vr7,   vr3,   0
    vsllwil.hu.bu   vr6,   vr2,   0
    vsllwil.hu.bu   vr5,   vr1,   0
    vsllwil.hu.bu   vr4,   vr0,   0
    vsllwil.hu.bu   vr14,  vr10,  0
    vsllwil.hu.bu   vr15,  vr11,  0
    vsllwil.hu.bu   vr16,  vr12,  0
    vsllwil.hu.bu   vr17,  vr13,  0

    /* p0', p1', p2' */
    vadd.h          vr8,   vr5,   vr4
    vadd.h          vr9,   vr8,   vr14
    vadd.h          vr19,  vr7,   vr6
    vadd.h          vr18,  vr6,   vr9    // pix[-2*xstride]
    vslli.h         vr19,  vr19,  1
    vadd.h          vr20,  vr9,   vr18
    vadd.h          vr19,  vr19,  vr18   // pix[-3*xstride]
    vadd.h          vr20,  vr20,  vr15   // pix[-1*xstride]

    /* p0' */
    vadd.h          vr8,   vr8,   vr15
    vadd.h          vr21,  vr8,   vr5    // pix[-1*xstride]

    /* q0', q1', q2' */
    vadd.h          vr8,   vr15,  vr14
    vadd.h          vr9,   vr8,   vr4
    vadd.h          vr23,  vr17,  vr16
    vadd.h          vr22,  vr9,   vr16  // pix[1*xstride]
    vslli.h         vr23,  vr23,  1
    vadd.h          vr24,  vr9,   vr22
    vadd.h          vr23,  vr23,  vr22  // pix[2*xstride]
    vadd.h          vr24,  vr24,  vr5   // pix[0*xstride]

    /* q0' */
    vadd.h          vr8,   vr8,   vr5
    vadd.h          vr25,  vr8,   vr15  // pix[0*xstride]

    vexth.hu.bu     vr7,   vr3
    vexth.hu.bu     vr6,   vr2
    vexth.hu.bu     vr5,   vr1
    vexth.hu.bu     vr4,   vr0
    vexth.hu.bu     vr14,  vr10
    vexth.hu.bu     vr15,  vr11
    vexth.hu.bu     vr16,  vr12
    vexth.hu.bu     vr17,  vr13

    /* p0', p1', p2' */
    vadd.h          vr8,   vr5,   vr4
    vadd.h          vr9,   vr8,   vr14
    vadd.h          vr27,  vr6,   vr9   // pix[-2*xstride]
    vadd.h          vr28,  vr7,   vr6
    vslli.h         vr28,  vr28,  1
    vadd.h          vr29,  vr9,   vr27
    vadd.h          vr28,  vr28,  vr27  // pix[-3*xstride]
    vadd.h          vr29,  vr29,  vr15  // pix[-1*xstride]

    /* p0' */
    vadd.h          vr8,   vr8,   vr15
    vadd.h          vr30,  vr8,   vr5  // pix[-1*xstride]

    /* q0', q1', q2' */
    vadd.h          vr8,   vr15,  vr14
    vadd.h          vr9,   vr8,   vr4
    vadd.h          vr3,   vr17,  vr16
    vadd.h          vr31,  vr9,   vr16  // pix[1*xstride]
    vslli.h         vr3,   vr3,   1
    vadd.h          vr13,  vr9,   vr31
    vadd.h          vr3,   vr3,   vr31  // pix[2*xstride]
    vadd.h          vr13,  vr13,  vr5   // pix[0*xstride]

    /* q0' */
    vadd.h          vr8,   vr8,   vr5
    vadd.h          vr9,   vr8,   vr15  // pix[0*xstride]

    vsrarni.b.h     vr28,  vr19,  3     // pix[-3*xstride]
    vsrarni.b.h     vr27,  vr18,  2     // pix[-2*xstride]
    vsrarni.b.h     vr29,  vr20,  3     // pix[-1*xstride]
    vsrarni.b.h     vr30,  vr21,  2     // pix[-1*xstride] p0'
    vsrarni.b.h     vr13,  vr24,  3     // pix[ 0*xstride]
    vsrarni.b.h     vr31,  vr22,  2     // pix[ 1*xstride]
    vsrarni.b.h     vr3,   vr23,  3     // pix[ 2*xstride]
    vsrarni.b.h     vr9,   vr25,  2     // pix[ 0*xstride] q0'

    vreplgr2vr.b    vr18,  a2           // alpha
    vreplgr2vr.b    vr19,  a3           // beta

    vabsd.bu        vr26,  vr0,   vr10
    vabsd.bu        vr8,   vr1,   vr0
    vabsd.bu        vr16,  vr11,  vr10
    vslt.bu         vr20,  vr26,  vr18
    vslt.bu         vr21,  vr8,   vr19
    vslt.bu         vr22,  vr16,  vr19
    vand.v          vr20,  vr20,  vr21
    vand.v          vr20,  vr20,  vr22  // if_1

    vsrli.b         vr18,  vr18,  2
    vaddi.bu        vr18,  vr18,  2

    vslt.bu         vr26,  vr26,  vr18  // if_2

    vabsd.bu        vr23,   vr2,   vr0
    vslt.bu         vr23,   vr23,  vr19 // if_3

    vand.v          vr16,  vr23,  vr26        // if_2 && if_3
    vnor.v          vr24,  vr16,  vr16        // !(if_2 && if_3)
    vand.v          vr24,  vr24,  vr20        // if_1 && !(if_2 && if_3)
    vand.v          vr16,  vr16,  vr20        // if_1 && if_2 && if_3
    vbitsel.v       vr4,   vr2,   vr28, vr16  // pix[-3*xstride]
    vbitsel.v       vr5,   vr1,   vr27, vr16  // pix[-2*xstride]
    vbitsel.v       vr6,   vr0,   vr30, vr24
    vbitsel.v       vr6,   vr6,   vr29, vr16  // pix[-1*xstride]

    vabsd.bu        vr7,   vr12,  vr10
    vslt.bu         vr7,   vr7,   vr19       // if_4

    vand.v          vr17,  vr7,   vr26       // if_2 && if_4
    vnor.v          vr14,  vr17,  vr17       // !(if_2 && if_4)
    vand.v          vr14,  vr14,  vr20       // if_1 && !(if_2 && if_4)
    vand.v          vr17,  vr17,  vr20       // if_1 && if_2 && if_4
    vbitsel.v       vr15,  vr10,  vr9,  vr14
    vbitsel.v       vr15,  vr15,  vr13, vr17 // pix[ 0*xstride]
    vbitsel.v       vr9,   vr11,  vr31, vr17 // pix[ 1*xstride]
    vbitsel.v       vr13,  vr12,  vr3,  vr17 // pix[ 2*xstride]

    vilvl.b         vr16,  vr5,   vr4
    vilvl.b         vr17,  vr15,  vr6
    vilvl.b         vr18,  vr13,  vr9
    vilvh.b         vr19,  vr5,   vr4
    vilvh.b         vr20,  vr15,  vr6
    vilvh.b         vr21,  vr13,  vr9
    vilvl.h         vr0,   vr17,  vr16
    vilvh.h         vr1,   vr17,  vr16
    vilvl.h         vr2,   vr20,  vr19
    vilvh.h         vr3,   vr20,  vr19

    addi.d          t6,    a0,    -3     // t6 = a0 -3
    vstelm.w        vr0,   t6,    0,   0
    vstelm.h        vr18,  t6,    4,   0
    add.d           t6,    t6,    a1
    vstelm.w        vr0,   t6,    0,   1
    vstelm.h        vr18,  t6,    4,   1
    add.d           t6,    t6,    a1
    vstelm.w        vr0,   t6,    0,   2
    vstelm.h        vr18,  t6,    4,   2
    add.d           t6,    t6,    a1
    vstelm.w        vr0,   t6,    0,   3
    vstelm.h        vr18,  t6,    4,   3
    add.d           t6,    t6,    a1

    vstelm.w        vr1,   t6,    0,   0
    vstelm.h        vr18,  t6,    4,   4
    add.d           t6,    t6,    a1
    vstelm.w        vr1,   t6,    0,   1
    vstelm.h        vr18,  t6,    4,   5
    add.d           t6,    t6,    a1
    vstelm.w        vr1,   t6,    0,   2
    vstelm.h        vr18,  t6,    4,   6
    add.d           t6,    t6,    a1
    vstelm.w        vr1,   t6,    0,   3
    vstelm.h        vr18,  t6,    4,   7
    add.d           t6,    t6,    a1

    vstelm.w        vr2,   t6,    0,   0
    vstelm.h        vr21,  t6,    4,   0
    add.d           t6,    t6,    a1
    vstelm.w        vr2,   t6,    0,   1
    vstelm.h        vr21,  t6,    4,   1
    add.d           t6,    t6,    a1
    vstelm.w        vr2,   t6,    0,   2
    vstelm.h        vr21,  t6,    4,   2
    add.d           t6,    t6,    a1
    vstelm.w        vr2,   t6,    0,   3
    vstelm.h        vr21,  t6,    4,   3
    add.d           t6,    t6,    a1

    vstelm.w        vr3,   t6,    0,   0
    vstelm.h        vr21,  t6,    4,   4
    add.d           t6,    t6,    a1
    vstelm.w        vr3,   t6,    0,   1
    vstelm.h        vr21,  t6,    4,   5
    add.d           t6,    t6,    a1
    vstelm.w        vr3,   t6,    0,   2
    vstelm.h        vr21,  t6,    4,   6
    add.d           t6,    t6,    a1
    vstelm.w        vr3,   t6,    0,   3
    vstelm.h        vr21,  t6,    4,   7

    fld.d           f24,   sp,    0
    fld.d           f25,   sp,    8
    fld.d           f26,   sp,    16
    fld.d           f27,   sp,    24
    fld.d           f28,   sp,    32
    fld.d           f29,   sp,    40
    fld.d           f30,   sp,    48
    fld.d           f31,   sp,    56
    addi.d          sp,    sp,    64
endfunc_x264
#endif /* !HIGH_BIT_DEPTH */
