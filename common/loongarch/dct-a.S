/*****************************************************************************
 * dct-a.S: LoongArch transform and zigzag
 *****************************************************************************
 * Copyright (C) 2015-2022 x264 project
 * Copyright (C) 2022 Loongson Technology Corporation Limited
 *
 * Authors: gxw <guxiwei-hf@loongson.cn>
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

const hsub_mul
.rept 16
.byte 1, -1
.endr
endconst

const last64_shuf
.int 0, 4, 1, 5, 2, 6, 3, 7
endconst

const zigzag_scan4
.short 0, 4, 1, 2, 5, 8, 12, 9, 6, 3, 7, 10, 13, 14, 11, 15
endconst

.macro LOAD_DIFF8x4_LASX s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
    fld.d           $f\s1,  a1,      FENC_STRIDE * \s7
    fld.d           $f\s2,  a1,      FENC_STRIDE * \s8
    fld.d           $f\s5,  a1,      FENC_STRIDE * \s9
    fld.d           $f\s6,  a1,      FENC_STRIDE * \s10
    xvinsve0.d      $xr\s1, $xr\s5,  2
    xvinsve0.d      $xr\s2, $xr\s6,  2
    fld.d           $f\s3,  a2,      FDEC_STRIDE * \s7
    fld.d           $f\s4,  a2,      FDEC_STRIDE * \s8
    fld.d           $f\s5,  a2,      FDEC_STRIDE * \s9
    fld.d           $f\s6,  a2,      FDEC_STRIDE * \s10
    xvinsve0.d      $xr\s3, $xr\s5,  2
    xvinsve0.d      $xr\s4, $xr\s6,  2
    xvilvl.b        $xr\s1, xr8,     $xr\s1
    xvilvl.b        $xr\s2, xr8,     $xr\s2
    xvilvl.b        $xr\s3, xr8,     $xr\s3
    xvilvl.b        $xr\s4, xr8,     $xr\s4
    xvsub.h         $xr\s1, $xr\s1,  $xr\s3
    xvsub.h         $xr\s2, $xr\s2,  $xr\s4
.endm

.macro DCT4_1D_LASX s0, s1, s2, s3, s4
    xvadd.h         \s4,    \s3,     \s0
    xvsub.h         \s0,    \s0,     \s3
    xvadd.h         \s3,    \s2,     \s1
    xvsub.h         \s1,    \s1,     \s2
    xvadd.h         \s2,    \s3,     \s4
    xvsub.h         \s4,    \s4,     \s3
    xvsub.h         \s3,    \s0,     \s1
    xvsub.h         \s3,    \s3,     \s1
    xvadd.h         \s0,    \s0,     \s0
    xvadd.h         \s0,    \s0,     \s1
.endm

.macro LSX_SUMSUB_H sum, sub, a, b
    vadd.h          \sum,   \a,      \b
    vsub.h          \sub,   \a,      \b
.endm

.macro DCT4_1D_LSX s0, s1, s2, s3, s4, s5, s6, s7
    LSX_SUMSUB_H \s1, \s6, \s5, \s6
    LSX_SUMSUB_H \s3, \s7, \s4, \s7
    vadd.h          \s0,    \s3,     \s1
    vadd.h          \s4,    \s7,     \s7
    vadd.h          \s5,    \s6,     \s6
    vsub.h          \s2,    \s3,     \s1
    vadd.h          \s1,    \s4,     \s6
    vsub.h          \s3,    \s7,     \s5
.endm

.macro SUB8x8_DCT_CORE_LASX
    LOAD_DIFF8x4_LASX 0, 1, 2, 3, 4, 5, 0, 1, 4, 5
    LOAD_DIFF8x4_LASX 2, 3, 4, 5, 6, 7, 2, 3, 6, 7
    DCT4_1D_LASX xr0, xr1, xr2, xr3, xr4
    LASX_TRANSPOSE2x4x4_H xr0, xr2, xr3, xr4, xr0, xr1, \
                          xr2, xr3, xr0, xr2, xr3, xr4, xr1

    DCT4_1D_LASX xr2, xr0, xr3, xr1, xr4
    xvilvh.d        xr0,    xr2,     xr3 /* 6, 2 */
    xvilvl.d        xr3,    xr2,     xr3 /* 4, 0 */
    xvilvh.d        xr2,    xr1,     xr4 /* 7, 3 */
    xvilvl.d        xr4,    xr1,     xr4 /* 5, 1 */
    xvor.v          xr1,    xr3,     xr3
    xvpermi.q       xr3,    xr4,     0x02 /* 1, 0 */
    xvor.v          xr5,    xr0,     xr0
    xvpermi.q       xr0,    xr2,     0x02 /* 3, 2 */
    xvpermi.q       xr1,    xr4,     0x13 /* 4, 5 */
    xvpermi.q       xr5,    xr2,     0x13 /* 7, 6 */
    xvst            xr3,    a0,      0
    xvst            xr0,    a0,      16 * 2
    xvst            xr1,    a0,      16 * 4
    xvst            xr5,    a0,      16 * 6
.endm

/* void subwxh_dct( dctcoef*, pixel*, pixel* ) */
function sub4x4_dct_lsx
    fld.s           f0,     a1,      0
    fld.s           f4,     a2,      0
    fld.s           f1,     a1,      FENC_STRIDE
    fld.s           f5,     a2,      FDEC_STRIDE
    vext2xv.hu.bu   xr0,    xr0
    vext2xv.hu.bu   xr1,    xr1
    vext2xv.hu.bu   xr4,    xr4
    vext2xv.hu.bu   xr5,    xr5
    fld.s           f2,     a1,      FENC_STRIDE * 2
    fld.s           f6,     a2,      FDEC_STRIDE * 2
    fld.s           f3,     a1,      FENC_STRIDE * 3
    fld.s           f7,     a2,      FDEC_STRIDE * 3
    vext2xv.hu.bu   xr2,    xr2
    vext2xv.hu.bu   xr3,    xr3
    vext2xv.hu.bu   xr6,    xr6
    vext2xv.hu.bu   xr7,    xr7
    vsub.h          vr0,    vr0,     vr4
    vsub.h          vr1,    vr1,     vr5
    vsub.h          vr2,    vr2,     vr6
    vsub.h          vr3,    vr3,     vr7

    DCT4_1D_LSX vr4, vr5, vr6, vr7, vr0, vr1, vr2, vr3
    LSX_TRANSPOSE4x4_H vr4, vr5, vr6, vr7, vr4, vr5, vr6, vr7, vr0, vr1
    DCT4_1D_LSX vr0, vr1, vr2, vr3, vr4, vr5, vr6, vr7
    vshuf4i.d       vr0,    vr1,     0x8
    vshuf4i.d       vr2,    vr3,     0x8
    vst             vr0,    a0,      0
    vst             vr2,    a0,      16
endfunc

function sub8x8_dct_lasx
    xvxor.v         xr8,    xr8,     xr8
    SUB8x8_DCT_CORE_LASX
endfunc

function sub16x16_dct_lasx
    xvxor.v  xr8,  xr8,  xr8
    SUB8x8_DCT_CORE_LASX
    addi.d         a0,      a0,    32 * 4
    addi.d         a1,      a1,    8
    addi.d         a2,      a2,    8
    SUB8x8_DCT_CORE_LASX
    addi.d         a0,      a0,    32 * 4
    addi.d         a1,      a1,    8*FENC_STRIDE - 8
    addi.d         a2,      a2,    8*FDEC_STRIDE - 8
    SUB8x8_DCT_CORE_LASX
    addi.d         a0,      a0,    32 * 4
    addi.d         a1,      a1,    8
    addi.d         a2,      a2,    8
    SUB8x8_DCT_CORE_LASX
endfunc

/*
 * void add4x4_idct( pixel *p_dst, dctcoef dct[16] )
 */
function add4x4_idct_lsx
    vxor.v          vr0,    vr1,   vr1

    fld.d           f1,     a1,    0
    fld.d           f2,     a1,    8
    fld.d           f3,     a1,    16
    fld.d           f4,     a1,    24

    vsrai.h         vr5,    vr2,   1
    vsrai.h         vr6,    vr4,   1

    vilvl.h         vr1,    vr1,   vr3
    vilvl.h         vr15,   vr2,   vr6
    vilvl.h         vr16,   vr5,   vr4

    vhaddw.w.h      vr7,    vr1,  vr1
    vhsubw.w.h      vr8,    vr1,  vr1
    vhaddw.w.h      vr9,    vr15, vr15
    vhsubw.w.h      vr10,   vr16, vr16

    vadd.w          vr1,    vr7,  vr9
    vadd.w          vr2,    vr8,  vr10
    vsub.w          vr3,    vr8,  vr10
    vsub.w          vr4,    vr7,  vr9

    vpickev.h       vr1,    vr1,  vr1
    vpickev.h       vr2,    vr2,  vr2
    vpickev.h       vr3,    vr3,  vr3
    vpickev.h       vr4,    vr4,  vr4

    LSX_TRANSPOSE4x4_H vr1, vr2, vr3, vr4, vr1, vr2, vr3, vr4, vr5, vr6

    vsrai.h         vr5,    vr2,   1
    vsrai.h         vr6,    vr4,   1

    vilvl.h         vr1,    vr1,   vr3
    vilvl.h         vr15,   vr2,   vr6
    vilvl.h         vr16,   vr5,   vr4

    vhaddw.w.h      vr7,    vr1,   vr1
    vhsubw.w.h      vr8,    vr1,   vr1
    vhaddw.w.h      vr9,    vr15,  vr15
    vhsubw.w.h      vr10,   vr16,  vr16

    vadd.w          vr1,    vr7,   vr9
    vadd.w          vr2,    vr8,   vr10
    vsub.w          vr3,    vr8,   vr10
    vsub.w          vr4,    vr7,   vr9

    vssrarni.h.w    vr2,    vr1,   6
    vssrarni.h.w    vr4,    vr3,   6

    fld.s           f1,     a0,    0
    fld.s           f5,     a0,    FDEC_STRIDE
    fld.s           f3,     a0,    FDEC_STRIDE * 2
    fld.s           f6,     a0,    FDEC_STRIDE * 3

    vilvl.b         vr1,    vr0,   vr1
    vilvl.b         vr5,    vr0,   vr5
    vilvl.b         vr3,    vr0,   vr3
    vilvl.b         vr6,    vr0,   vr6

    vilvl.d         vr1,    vr5,   vr1
    vilvl.d         vr3,    vr6,   vr3
    vadd.h          vr7,    vr1,   vr2
    vadd.h          vr8,    vr3,   vr4

    vssrarni.bu.h   vr8,    vr7,   0

    vstelm.w        vr8,   a0,     0,                  0
    vstelm.w        vr8,   a0,     FDEC_STRIDE,        1
    vstelm.w        vr8,   a0,     FDEC_STRIDE * 2,    2
    vstelm.w        vr8,   a0,     FDEC_STRIDE * 3,    3
endfunc

.macro LASX_SUMSUB_W sum, diff, in0, in1
    xvadd.w         \sum,   \in0,  \in1
    xvsub.w         \diff,  \in0,  \in1
.endm

.macro add8x4_idct_core_lasx
    fld.d           f1,     a1,    0
    fld.d           f2,     a1,    8
    fld.d           f3,     a1,    16
    fld.d           f4,     a1,    24

    fld.d           f5,     a1,    32
    fld.d           f6,     a1,    40
    fld.d           f7,     a1,    48
    fld.d           f8,     a1,    56

    xvinsve0.d      xr1,    xr5,   1
    xvinsve0.d      xr2,    xr6,   1
    xvinsve0.d      xr3,    xr7,   1
    xvinsve0.d      xr4,    xr8,   1

    xvsrai.h        xr8,    xr2,   1
    xvsrai.h        xr9,    xr4,   1

    vext2xv.w.h     xr1,    xr1
    vext2xv.w.h     xr5,    xr2
    vext2xv.w.h     xr6,    xr3
    vext2xv.w.h     xr7,    xr4
    vext2xv.w.h     xr8,    xr8
    vext2xv.w.h     xr9,    xr9

    LASX_SUMSUB_W xr10, xr11, xr1, xr6
    xvadd.w         xr12,   xr5,   xr9
    xvsub.w         xr13,   xr8,   xr7

    LASX_SUMSUB_W xr6, xr9, xr10, xr12
    LASX_SUMSUB_W xr7, xr8, xr11, xr13

    xvpickev.h      xr10,   xr6,   xr6
    xvpickev.h      xr11,   xr7,   xr7
    xvpickev.h      xr12,   xr8,   xr8
    xvpickev.h      xr13,   xr9,   xr9

    LASX_TRANSPOSE4x8_H xr10, xr11, xr12, xr13, xr10, xr11, xr12, xr13, \
                        xr4, xr5, xr6, xr7

    xvsllwil.w.h    xr10,   xr10,  0
    xvsllwil.w.h    xr11,   xr11,  0
    xvsllwil.w.h    xr12,   xr12,  0
    xvsllwil.w.h    xr13,   xr13,  0
    xvsrai.w        xr14,   xr11,  1
    xvsrai.w        xr15,   xr13,  1

    LASX_SUMSUB_W xr4, xr5, xr10, xr12
    xvadd.w         xr6,    xr11,  xr15
    xvsub.w         xr7,    xr14,  xr13

    LASX_SUMSUB_W xr10, xr13, xr4, xr6
    LASX_SUMSUB_W xr11, xr12, xr5, xr7

    xvssrarni.h.w   xr11,   xr10,  6
    xvssrarni.h.w   xr13,   xr12,  6

    fld.s           f1,     a0,    0
    fld.s           f2,     a0,    FDEC_STRIDE
    fld.s           f3,     a0,    FDEC_STRIDE * 2
    fld.s           f4,     a0,    FDEC_STRIDE * 3

    fld.s           f5,     a0,    4
    fld.s           f6,     a0,    FDEC_STRIDE + 4
    fld.s           f7,     a0,    FDEC_STRIDE * 2 + 4
    fld.s           f8,     a0,    FDEC_STRIDE * 3 + 4

    xvinsve0.w      xr1,    xr2,   1
    xvinsve0.w      xr3,    xr4,   1
    xvinsve0.w      xr5,    xr6,   1
    xvinsve0.w      xr7,    xr8,   1

    xvinsve0.d      xr1,    xr5,   2
    xvinsve0.d      xr3,    xr7,   2

    xvilvl.b        xr1,    xr0,   xr1
    xvilvl.b        xr3,    xr0,   xr3

    xvadd.h         xr1,    xr1,   xr11
    xvadd.h         xr3,    xr3,   xr13

    xvssrarni.bu.h  xr3,    xr1,   0

    xvstelm.w       xr3,    a0,    0,                     0
    xvstelm.w       xr3,    a0,    FDEC_STRIDE,           1
    xvstelm.w       xr3,    a0,    FDEC_STRIDE * 2,       2
    xvstelm.w       xr3,    a0,    FDEC_STRIDE * 3,       3

    xvstelm.w       xr3,    a0,    4,                     4
    xvstelm.w       xr3,    a0,    FDEC_STRIDE + 4,       5
    xvstelm.w       xr3,    a0,    FDEC_STRIDE * 2 + 4,   6
    xvstelm.w       xr3,    a0,    FDEC_STRIDE * 3 + 4,   7
.endm

/*
 * void add8x8_idct( pixel *p_dst, dctcoef dct[4][16] )
 *
 */
function add8x8_idct_lasx
    xvxor.v         xr0,    xr1,   xr1
    add8x4_idct_core_lasx

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    64
    add8x4_idct_core_lasx
endfunc
/*
 * void add16x16_idct( pixel *p_dst, dctcoef dct[16][16] )
 */
function add16x16_idct_lasx
    move            t4,     a0
    move            t5,     a1

    xvxor.v         xr0,    xr1,   xr1
    add8x4_idct_core_lasx
    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    64
    add8x4_idct_core_lasx

    addi.d          a0,     t4,    8
    addi.d          a1,     t5,    128
    add8x4_idct_core_lasx
    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    64
    add8x4_idct_core_lasx

    addi.d          t6,     t4,    FDEC_STRIDE * 8
    move            a0,     t6
    addi.d          a1,     t5,    256
    add8x4_idct_core_lasx
    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    64
    add8x4_idct_core_lasx


    addi.d          a0,     t6,    8
    addi.d          a1,     t5,    384
    add8x4_idct_core_lasx
    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    64
    add8x4_idct_core_lasx
endfunc

/*
 * void add8x8_idct8( pixel *dst, dctcoef dct[64] )
 */
function add8x8_idct8_lasx
    xvxor.v         xr20,   xr1,   xr1

    // dct[0] += 32
    ld.h            t0,     a1,    0
    addi.w          t0,     t0,    32
    st.h            t0,     a1,    0

    vld             vr0,    a1,    0
    vld             vr2,    a1,    32
    vld             vr4,    a1,    64
    vld             vr6,    a1,    96

    vsrai.h         vr8,    vr2,   1
    vsrai.h         vr10,   vr6,   1

    vext2xv.w.h     xr0,    xr0
    vext2xv.w.h     xr2,    xr2
    vext2xv.w.h     xr4,    xr4
    vext2xv.w.h     xr6,    xr6
    vext2xv.w.h     xr8,    xr8
    vext2xv.w.h     xr10,   xr10

    LASX_SUMSUB_W xr11, xr12, xr0, xr4
    xvsub.w         xr13,   xr8,   xr6
    xvadd.w         xr14,   xr10,  xr2

    LASX_SUMSUB_W xr15, xr18, xr11, xr14
    LASX_SUMSUB_W xr16, xr17, xr12, xr13

    vld             vr0,    a1,    16
    vld             vr2,    a1,    48
    vld             vr4,    a1,    80
    vld             vr6,    a1,    112

    vsrai.h         vr1,    vr0,   1
    vsrai.h         vr3,    vr2,   1
    vsrai.h         vr5,    vr4,   1
    vsrai.h         vr7,    vr6,   1

    vext2xv.w.h     xr0,    xr0
    vext2xv.w.h     xr2,    xr2
    vext2xv.w.h     xr4,    xr4
    vext2xv.w.h     xr6,    xr6
    vext2xv.w.h     xr1,    xr1
    vext2xv.w.h     xr3,    xr3
    vext2xv.w.h     xr5,    xr5
    vext2xv.w.h     xr7,    xr7

    LASX_SUMSUB_W xr9, xr10, xr4, xr2
    LASX_SUMSUB_W xr11, xr12, xr6, xr0

    xvsub.w         xr10,   xr10,  xr6
    xvsub.w         xr10,   xr10,  xr7
    xvsub.w         xr11,   xr11,  xr2
    xvsub.w         xr11,   xr11,  xr3
    xvadd.w         xr12,   xr12,  xr4
    xvadd.w         xr12,   xr12,  xr5
    xvadd.w         xr9,    xr9,   xr0
    xvadd.w         xr9,    xr9,   xr1

    xvsrai.w        xr1,    xr10,  2
    xvsrai.w        xr2,    xr11,  2
    xvsrai.w        xr3,    xr12,  2
    xvsrai.w        xr4,    xr9,   2

    xvadd.w         xr5,    xr4,   xr10
    xvadd.w         xr6,    xr3,   xr11
    xvsub.w         xr7,    xr2,   xr12
    xvsub.w         xr8,    xr9,   xr1

    LASX_SUMSUB_W xr1, xr14, xr15, xr8
    LASX_SUMSUB_W xr2, xr13, xr16, xr7
    LASX_SUMSUB_W xr3, xr12, xr17, xr6
    LASX_SUMSUB_W xr4, xr11, xr18, xr5

    LASX_TRANSPOSE8x8_W xr1, xr2, xr3, xr4, xr11, xr12, xr13, xr14, \
                        xr5, xr6, xr7, xr8, xr15, xr16, xr17, xr18, \
                        xr9, xr10, xr21, xr22

    xvsrai.h        xr9,    xr7,   1
    xvsrai.h        xr10,   xr17,  1

    xvaddwev.w.h    xr1,    xr5,   xr15
    xvsubwev.w.h    xr2,    xr5,   xr15
    xvsubwev.w.h    xr3,    xr9,   xr17
    xvaddwev.w.h    xr4,    xr10,  xr7

    LASX_SUMSUB_W xr11, xr14, xr1, xr4
    LASX_SUMSUB_W xr12, xr13, xr2, xr3

    xvsrai.h        xr1,    xr6,   1
    xvsrai.h        xr2,    xr8,   1
    xvsrai.h        xr3,    xr16,  1
    xvsrai.h        xr4,    xr18,  1

    xvaddwev.w.h    xr5,    xr16,  xr8
    xvsubwev.w.h    xr10,   xr16,  xr8
    xvaddwev.w.h    xr7,    xr18,  xr6
    xvsubwev.w.h    xr9,    xr18,  xr6

    xvaddwev.w.h    xr4,    xr18,  xr4
    xvsub.w         xr10,   xr10,  xr4
    xvaddwev.w.h    xr2,    xr8,   xr2
    xvsub.w         xr7,    xr7,   xr2
    xvaddwev.w.h    xr3,    xr16,  xr3
    xvadd.w         xr9,    xr9,   xr3
    xvaddwev.w.h    xr1,    xr6,   xr1
    xvadd.w         xr5,    xr5,   xr1

    xvsrai.w        xr1,    xr10,  2
    xvsrai.w        xr2,    xr7,   2
    xvsrai.w        xr3,    xr9,   2
    xvsrai.w        xr4,    xr5,   2

    xvadd.w         xr15,   xr4,   xr10
    xvadd.w         xr16,   xr7,   xr3
    xvsub.w         xr17,   xr2,   xr9
    xvsub.w         xr18,   xr5,   xr1

    LASX_SUMSUB_W xr1, xr8, xr11, xr18
    LASX_SUMSUB_W xr2, xr7, xr12, xr17
    LASX_SUMSUB_W xr3, xr6, xr13, xr16
    LASX_SUMSUB_W xr4, xr5, xr14, xr15

    xvsrai.w        xr11,   xr1,   6
    xvsrai.w        xr12,   xr2,   6
    xvsrai.w        xr13,   xr3,   6
    xvsrai.w        xr14,   xr4,   6
    xvsrai.w        xr15,   xr5,   6
    xvsrai.w        xr16,   xr6,   6
    xvsrai.w        xr17,   xr7,   6
    xvsrai.w        xr18,   xr8,   6

    fld.d           f1,     a0,    0
    fld.d           f2,     a0,    FDEC_STRIDE
    fld.d           f3,     a0,    FDEC_STRIDE * 2
    fld.d           f4,     a0,    FDEC_STRIDE * 3

    fld.d           f5,     a0,    FDEC_STRIDE * 4
    fld.d           f6,     a0,    FDEC_STRIDE * 5
    fld.d           f7,     a0,    FDEC_STRIDE * 6
    fld.d           f8,     a0,    FDEC_STRIDE * 7

    vext2xv.wu.bu   xr1,    xr1
    vext2xv.wu.bu   xr2,    xr2
    vext2xv.wu.bu   xr3,    xr3
    vext2xv.wu.bu   xr4,    xr4
    vext2xv.wu.bu   xr5,    xr5
    vext2xv.wu.bu   xr6,    xr6
    vext2xv.wu.bu   xr7,    xr7
    vext2xv.wu.bu   xr8,    xr8

    xvadd.w         xr1,    xr1,   xr11
    xvadd.w         xr2,    xr2,   xr12
    xvadd.w         xr3,    xr3,   xr13
    xvadd.w         xr4,    xr4,   xr14
    xvadd.w         xr5,    xr5,   xr15
    xvadd.w         xr6,    xr6,   xr16
    xvadd.w         xr7,    xr7,   xr17
    xvadd.w         xr8,    xr8,   xr18

    xvssrarni.hu.w  xr2,    xr1,   0
    xvssrarni.hu.w  xr4,    xr3,   0
    xvssrarni.hu.w  xr6,    xr5,   0
    xvssrarni.hu.w  xr8,    xr7,   0

    xvpermi.d       xr12,   xr2,   0xd8
    xvpermi.d       xr14,   xr4,   0xd8
    xvpermi.d       xr16,   xr6,   0xd8
    xvpermi.d       xr18,   xr8,   0xd8

    xvssrlni.bu.h   xr14,   xr12,  0
    xvssrlni.bu.h   xr18,   xr16,  0

    xvstelm.d       xr14,   a0,    0,                  0
    xvstelm.d       xr14,   a0,    FDEC_STRIDE,        2
    xvstelm.d       xr14,   a0,    FDEC_STRIDE * 2,    1
    xvstelm.d       xr14,   a0,    FDEC_STRIDE * 3,    3

    xvstelm.d       xr18,   a0,    FDEC_STRIDE * 4,    0
    xvstelm.d       xr18,   a0,    FDEC_STRIDE * 5,    2
    xvstelm.d       xr18,   a0,    FDEC_STRIDE * 6,    1
    xvstelm.d       xr18,   a0,    FDEC_STRIDE * 7,    3
endfunc

.macro add8x4_idct_dc_lasx
    xvldrepl.h      xr11,   a1,    0
    xvldrepl.h      xr12,   a1,    2
    xvilvl.d        xr12,   xr12,  xr11
    xvsrari.h       xr12,   xr12,  6

    fld.d           f0,     a0,    0
    fld.d           f1,     a0,    FDEC_STRIDE
    fld.d           f2,     a0,    FDEC_STRIDE * 2
    fld.d           f3,     a0,    FDEC_STRIDE * 3

    xvinsve0.d      xr0,    xr1,   1
    xvinsve0.d      xr2,    xr3,   1

    vext2xv.hu.bu   xr0,    xr0
    vext2xv.hu.bu   xr2,    xr2

    xvadd.h         xr0,    xr0,   xr12
    xvadd.h         xr2,    xr2,   xr12
    xvssrarni.bu.h  xr2,    xr0,   0

    xvstelm.d       xr2,    a0,    0,                  0
    xvstelm.d       xr2,    a0,    FDEC_STRIDE,        2
    xvstelm.d       xr2,    a0,    FDEC_STRIDE * 2,    1
    xvstelm.d       xr2,    a0,    FDEC_STRIDE * 3,    3
.endm

/*
 * void add8x8_idct_dc( pixel *p_dst, dctcoef dct[4] )
 */
function add8x8_idct_dc_lasx
    add8x4_idct_dc_lasx

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    4
    add8x4_idct_dc_lasx
endfunc

.macro add_16x16_idct_dc_core_lasx a0, a1
    vldrepl.h       vr11,   \a1,   0
    vldrepl.h       vr12,   \a1,   2
    vldrepl.h       vr13,   \a1,   4
    vldrepl.h       vr14,   \a1,   6

    xvinsve0.d      xr11,   xr12,  1
    xvinsve0.d      xr11,   xr13,  2
    xvinsve0.d      xr11,   xr14,  3

    xvsrari.h       xr11,   xr11,  6

    vld             vr0,    \a0,   0
    vld             vr1,    \a0,   FDEC_STRIDE
    vld             vr2,    \a0,   FDEC_STRIDE * 2
    vld             vr3,    \a0,   FDEC_STRIDE * 3
    vext2xv.hu.bu   xr0,    xr0
    vext2xv.hu.bu   xr1,    xr1
    vext2xv.hu.bu   xr2,    xr2
    vext2xv.hu.bu   xr3,    xr3
    xvadd.h         xr0,    xr0,   xr11
    xvadd.h         xr1,    xr1,   xr11
    xvadd.h         xr2,    xr2,   xr11
    xvadd.h         xr3,    xr3,   xr11
    xvssrarni.bu.h  xr1,    xr0,   0
    xvssrarni.bu.h  xr3,    xr2,   0
    xvpermi.d       xr4,    xr1,   0xD8
    xvpermi.d       xr5,    xr1,   0x8D
    xvpermi.d       xr6,    xr3,   0xD8
    xvpermi.d       xr7,    xr3,   0x8D
    vst             vr4,    \a0,   0
    vst             vr5,    \a0,   FDEC_STRIDE
    vst             vr6,    \a0,   FDEC_STRIDE * 2
    vst             vr7,    \a0,   FDEC_STRIDE * 3
.endm

/*
 * void add16x16_idct_dc( pixel *p_dst, dctcoef dct[16] )
 */
function add16x16_idct_dc_lasx
    add_16x16_idct_dc_core_lasx a0, a1

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    8
    add_16x16_idct_dc_core_lasx a0, a1

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    8
    add_16x16_idct_dc_core_lasx a0, a1

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    8
    add_16x16_idct_dc_core_lasx a0, a1
endfunc

/*
 * void idct4x4dc( dctcoef d[16] )
 */
function idct4x4dc_lasx
    la.local        t0,     last64_shuf
    xvld            xr0,    a0,    0
    xvld            xr20,   t0,    0
    xvshuf4i.b      xr1,    xr0,   0x4E
    xvhaddw.w.h     xr2,    xr0,   xr0
    xvhsubw.w.h     xr3,    xr1,   xr1
    xvshuf4i.h      xr2,    xr2,   0x4E
    xvshuf4i.h      xr3,    xr3,   0x4E
    xvhaddw.d.w     xr4,    xr2,   xr2
    xvhsubw.d.w     xr5,    xr2,   xr2
    xvhsubw.d.w     xr6,    xr3,   xr3
    xvhaddw.d.w     xr7,    xr3,   xr3
    xvpickev.w      xr8,    xr5,   xr4
    xvpickev.w      xr9,    xr7,   xr6
    xvpickev.h      xr10,   xr9,   xr8
    xvperm.w        xr10,   xr10,  xr20
    xvshuf4i.b      xr11,   xr10,  0x4E
    xvhaddw.w.h     xr12,   xr10,  xr10
    xvhsubw.w.h     xr13,   xr11,  xr11
    xvshuf4i.h      xr12,   xr12,  0x4E
    xvshuf4i.h      xr13,   xr13,  0x4E
    xvhaddw.d.w     xr14,   xr12,  xr12
    xvhsubw.d.w     xr15,   xr12,  xr12
    xvhsubw.d.w     xr16,   xr13,  xr13
    xvhaddw.d.w     xr17,   xr13,  xr13
    xvpackev.w      xr18,   xr15,  xr14
    xvpackev.w      xr19,   xr17,  xr16
    xvilvl.d        xr0,    xr19,  xr18
    xvilvh.d        xr1,    xr19,  xr18
    xvpickev.h      xr2,    xr1,   xr0
    xvst            xr2,    a0,    0
endfunc

/*
 * void dct4x4dc( dctcoef d[16] )
 */
function dct4x4dc_lasx
    la.local        t0,     last64_shuf
    xvld            xr0,    a0,    0
    xvld            xr20,   t0,    0
    xvshuf4i.b      xr1,    xr0,   0x4E
    xvhaddw.w.h     xr2,    xr0,   xr0
    xvhsubw.w.h     xr3,    xr1,   xr1
    xvshuf4i.h      xr2,    xr2,   0x4E
    xvshuf4i.h      xr3,    xr3,   0x4E
    xvhaddw.d.w     xr4,    xr2,   xr2
    xvhsubw.d.w     xr5,    xr2,   xr2
    xvhsubw.d.w     xr6,    xr3,   xr3
    xvhaddw.d.w     xr7,    xr3,   xr3
    xvpickev.w      xr8,    xr5,   xr4
    xvpickev.w      xr9,    xr7,   xr6
    xvpickev.h      xr10,   xr9,   xr8
    xvperm.w        xr10,   xr10,  xr20
    xvshuf4i.b      xr11,   xr10,  0x4E
    xvhaddw.w.h     xr12,   xr10,  xr10
    xvhsubw.w.h     xr13,   xr11,  xr11
    xvshuf4i.h      xr12,   xr12,  0x4E
    xvshuf4i.h      xr13,   xr13,  0x4E
    xvhaddw.d.w     xr14,   xr12,  xr12
    xvhsubw.d.w     xr15,   xr12,  xr12
    xvhsubw.d.w     xr16,   xr13,  xr13
    xvhaddw.d.w     xr17,   xr13,  xr13
    xvpackev.w      xr18,   xr15,  xr14
    xvpackev.w      xr19,   xr17,  xr16
    xvsrari.w       xr18,   xr18,  1
    xvsrari.w       xr19,   xr19,  1
    xvilvl.d        xr0,    xr19,  xr18
    xvilvh.d        xr1,    xr19,  xr18
    xvpickev.h      xr2,    xr1,   xr0
    xvst            xr2,    a0,    0
endfunc

.macro LSX_LOAD_PIX_2 data1, data2
    vld             vr0,    a1,    0
    vld             vr1,    a1,    FENC_STRIDE
    vld             vr2,    a2,    0
    vld             vr3,    a2,    FDEC_STRIDE

    vilvl.b         vr0,    vr8,   vr0
    vilvl.b         vr1,    vr8,   vr1
    vilvl.b         vr2,    vr8,   vr2
    vilvl.b         vr3,    vr8,   vr3

    vsub.h          \data1, vr0,   vr2
    vsub.h          \data2, vr1,   vr3
    addi.d          a1,     a1,    FENC_STRIDE * 2
    addi.d          a2,     a2,    FDEC_STRIDE * 2
.endm

.macro LSX_DCT8_1D
    LSX_SUMSUB_H vr0, vr8, vr12, vr19
    LSX_SUMSUB_H vr1, vr9, vr13, vr18
    LSX_SUMSUB_H vr2, vr10, vr14, vr17
    LSX_SUMSUB_H vr3, vr11, vr15, vr16

    LSX_SUMSUB_H vr4, vr6, vr0, vr3
    LSX_SUMSUB_H vr5, vr7, vr1, vr2

    vsrai.h         vr20,   vr8,   1
    vadd.h          vr20,   vr20,  vr9
    vadd.h          vr20,   vr20,  vr10
    vadd.h          vr0,    vr20,  vr8

    vsrai.h         vr20,   vr10,  1
    vsub.h          vr21,   vr8,   vr11
    vsub.h          vr21,   vr21,  vr10
    vsub.h          vr1,    vr21,  vr20

    vsrai.h         vr20,   vr9,   1
    vadd.h          vr21,   vr8,   vr11
    vsub.h          vr21,   vr21,  vr9
    vsub.h          vr2,    vr21,  vr20

    vsrai.h         vr20,   vr11,  1
    vsub.h          vr21,   vr9,   vr10
    vadd.h          vr21,   vr21,  vr11
    vadd.h          vr3,    vr21,  vr20

    vadd.h          vr12,   vr4,   vr5
    vsrai.h         vr20,   vr3,   2
    vadd.h          vr13,   vr0,   vr20
    vsrai.h         vr20,   vr7,   1
    vadd.h          vr14,   vr6,   vr20
    vsrai.h         vr20,   vr2,   2
    vadd.h          vr15,   vr1,   vr20

    vsub.h          vr16,   vr4,   vr5
    vsrai.h         vr20,   vr1,   2
    vsub.h          vr17,   vr2,   vr20
    vsrai.h         vr20,   vr6,   1
    vsub.h          vr18,   vr20,  vr7
    vsrai.h         vr20,   vr0,   2
    vsub.h          vr19,   vr20,  vr3
.endm

/*
 * void sub8x8_dct8( dctcoef dct[64], pixel *pix1, pixel *pix2 )
 */
function sub8x8_dct8_lsx
    vor.v           vr8,    vr0,   vr0

    // vr12 ... vr19
    LSX_LOAD_PIX_2  vr12, vr13
    LSX_LOAD_PIX_2  vr14, vr15
    LSX_LOAD_PIX_2  vr16, vr17
    LSX_LOAD_PIX_2  vr18, vr19

    LSX_DCT8_1D
    LSX_TRANSPOSE8x8_H vr12, vr13, vr14, vr15, vr16, vr17, vr18, vr19, \
                       vr12, vr13, vr14, vr15, vr16, vr17, vr18, vr19, \
                       vr0, vr1, vr2, vr3, vr4, vr5, vr6, vr7
    LSX_DCT8_1D

    vst             vr12,   a0,    0
    vst             vr13,   a0,    16
    vst             vr14,   a0,    32
    vst             vr15,   a0,    48
    vst             vr16,   a0,    64
    vst             vr17,   a0,    80
    vst             vr18,   a0,    96
    vst             vr19,   a0,    112
endfunc

.macro LASX_LOAD_PIX_2 data1, data2
    xvld            xr0,    a1,    0
    xvld            xr1,    a1,    FENC_STRIDE
    xvld            xr2,    a2,    0
    xvld            xr3,    a2,    FDEC_STRIDE

    xvpermi.d       xr0,    xr0,   0x50
    xvpermi.d       xr1,    xr1,   0x50
    xvpermi.d       xr2,    xr2,   0x50
    xvpermi.d       xr3,    xr3,   0x50

    xvxor.v         xr4,    xr0,   xr0
    xvilvl.b        xr0,    xr4,   xr0
    xvilvl.b        xr1,    xr4,   xr1
    xvilvl.b        xr2,    xr4,   xr2
    xvilvl.b        xr3,    xr4,   xr3

    xvsub.h         \data1, xr0,   xr2
    xvsub.h         \data2, xr1,   xr3
    addi.d           a1,     a1,   FENC_STRIDE * 2
    addi.d           a2,     a2,   FDEC_STRIDE * 2
.endm

.macro LASX_SUMSUB_H sum, diff, a, b
    xvadd.h         \sum,   \a,    \b
    xvsub.h         \diff,  \a,    \b
.endm

.macro LASX_DCT8_1D
    LASX_SUMSUB_H xr0, xr8, xr12, xr19
    LASX_SUMSUB_H xr1, xr9, xr13, xr18
    LASX_SUMSUB_H xr2, xr10, xr14, xr17
    LASX_SUMSUB_H xr3, xr11, xr15, xr16

    LASX_SUMSUB_H xr4, xr6, xr0, xr3
    LASX_SUMSUB_H xr5, xr7, xr1, xr2

    xvsrai.h        xr20,   xr8,   1
    xvadd.h         xr20,   xr20,  xr9
    xvadd.h         xr20,   xr20,  xr10
    xvadd.h         xr0,    xr20,  xr8

    xvsrai.h        xr20,   xr10,  1
    xvsub.h         xr21,   xr8,   xr11
    xvsub.h         xr21,   xr21,  xr10
    xvsub.h         xr1,    xr21,  xr20

    xvsrai.h        xr20,   xr9,   1
    xvadd.h         xr21,   xr8,   xr11
    xvsub.h         xr21,   xr21,  xr9
    xvsub.h         xr2,    xr21,  xr20

    xvsrai.h        xr20,   xr11,  1
    xvsub.h         xr21,   xr9,   xr10
    xvadd.h         xr21,   xr21,  xr11
    xvadd.h         xr3,    xr21,  xr20

    xvadd.h         xr12,   xr4,   xr5
    xvsrai.h        xr20,   xr3,   2
    xvadd.h         xr13,   xr0,   xr20
    xvsrai.h        xr20,   xr7,   1
    xvadd.h         xr14,   xr6,   xr20
    xvsrai.h        xr20,   xr2,   2
    xvadd.h         xr15,   xr1,   xr20

    xvsub.h         xr16,   xr4,   xr5
    xvsrai.h        xr20,   xr1,   2
    xvsub.h         xr17,   xr2,   xr20
    xvsrai.h        xr20,   xr6,   1
    xvsub.h         xr18,   xr20,  xr7
    xvsrai.h        xr20,   xr0,   2
    xvsub.h         xr19,   xr20,  xr3
.endm

.macro SUB16x8_DCT8_LASX
    LASX_LOAD_PIX_2 xr12, xr13
    LASX_LOAD_PIX_2 xr14, xr15
    LASX_LOAD_PIX_2 xr16, xr17
    LASX_LOAD_PIX_2 xr18, xr19

    LASX_DCT8_1D
    LASX_TRANSPOSE8x8_H xr12, xr13, xr14, xr15, xr16, xr17, xr18, xr19, \
                        xr12, xr13, xr14, xr15, xr16, xr17, xr18, xr19, \
                        xr0, xr1, xr2, xr3, xr4, xr5, xr6, xr7
    LASX_DCT8_1D

    xmov            xr0,    xr13
    xvpermi.q       xr13,   xr12,  0x20
    xvst            xr13,   a0,    0
    xmov            xr1,    xr15
    xvpermi.q       xr15,   xr14,  0x20
    xvst            xr15,   a0,    32
    xmov            xr2,    xr17
    xvpermi.q       xr17,   xr16,  0x20
    xvst            xr17,   a0,    64
    xmov            xr3,    xr19
    xvpermi.q       xr19,   xr18,  0x20
    xvst            xr19,   a0,    96

    xvpermi.q       xr12,   xr0,   0x13
    xvpermi.q       xr14,   xr1,   0x13
    xvpermi.q       xr16,   xr2,   0x13
    xvpermi.q       xr18,   xr3,   0x13

    xvst            xr12,   a0,    128
    xvst            xr14,   a0,    160
    xvst            xr16,   a0,    192
    xvst            xr18,   a0,    224
.endm

/*
 * void sub16x16_dct8( dctcoef dct[4][64], pixel *pix1, pixel *pix2 )
 */
function sub16x16_dct8_lasx
    move            t1,     a1
    move            t3,     a2
    SUB16x8_DCT8_LASX

    addi.d          a0,     a0,    256
    addi.d          a1,     t1,    FENC_STRIDE * 8
    addi.d          a2,     t3,    FDEC_STRIDE * 8
    SUB16x8_DCT8_LASX
endfunc

/*
 * void zigzag_scan_4x4_frame( dctcoef level[16], dctcoef dct[16] )
 */
function zigzag_scan_4x4_frame_lasx
    xvld            xr1,    a1,    0
    xvor.v          xr2,    xr1,   xr1
    xvpermi.q       xr2,    xr2,   0x13
    xvpermi.q       xr1,    xr1,   0x02
    la.local        t0,     zigzag_scan4
    xvld            xr3,    t0,    0
    xvshuf.h        xr3,    xr2,   xr1
    xvst            xr3,    a0,    0
endfunc
