/*****************************************************************************
 * dct-a.S: LoongArch transform and zigzag
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Peng Zhou <zhoupeng@loongson.cn>
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
                          xr2, xr3, xr10, xr12, xr13

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

.macro SUB8x8_DCT_CORE_LSX
    fld.d           f0,  a1,     FENC_STRIDE * 0
    fld.d           f1,  a1,     FENC_STRIDE * 1
    fld.d           f4,  a1,     FENC_STRIDE * 4
    fld.d           f5,  a1,     FENC_STRIDE * 5
    fld.d           f2,  a2,     FDEC_STRIDE * 0
    fld.d           f3,  a2,     FDEC_STRIDE * 1
    fld.d           f6,  a2,     FDEC_STRIDE * 4
    fld.d           f7,  a2,     FDEC_STRIDE * 5

    vilvl.b         vr0, vr8,    vr0
    vilvl.b         vr1, vr8,    vr1
    vilvl.b         vr4, vr8,    vr4
    vilvl.b         vr5, vr8,    vr5
    vilvl.b         vr2, vr8,    vr2
    vilvl.b         vr3, vr8,    vr3
    vilvl.b         vr6, vr8,    vr6
    vilvl.b         vr7, vr8,    vr7
    vsub.h          vr0, vr0,    vr2
    vsub.h          vr4, vr4,    vr6
    vsub.h          vr1, vr1,    vr3
    vsub.h          vr5, vr5,    vr7

    fld.d           f2,   a1,     FENC_STRIDE * 2
    fld.d           f3,   a1,     FENC_STRIDE * 3
    fld.d           f6,   a1,     FENC_STRIDE * 6
    fld.d           f7,   a1,     FENC_STRIDE * 7
    fld.d           f9,   a2,     FDEC_STRIDE * 2
    fld.d           f11,  a2,     FDEC_STRIDE * 3
    fld.d           f10,  a2,     FDEC_STRIDE * 6
    fld.d           f12,  a2,     FDEC_STRIDE * 7

    vilvl.b         vr2,  vr8,    vr2
    vilvl.b         vr3,  vr8,    vr3
    vilvl.b         vr6,  vr8,    vr6
    vilvl.b         vr7,  vr8,    vr7
    vilvl.b         vr9,  vr8,    vr9
    vilvl.b         vr11, vr8,    vr11
    vilvl.b         vr10, vr8,    vr10
    vilvl.b         vr12, vr8,    vr12
    vsub.h          vr2,  vr2,    vr9
    vsub.h          vr6,  vr6,    vr10
    vsub.h          vr3,  vr3,    vr11
    vsub.h          vr7,  vr7,    vr12

    vadd.h          vr9,    vr3,    vr0
    vadd.h          vr10,   vr7,    vr4
    vsub.h          vr0,    vr0,    vr3
    vsub.h          vr4,    vr4,    vr7
    vadd.h          vr3,    vr2,    vr1
    vadd.h          vr7,    vr6,    vr5
    vsub.h          vr1,    vr1,    vr2
    vsub.h          vr5,    vr5,    vr6

    vadd.h          vr2,    vr3,    vr9
    vadd.h          vr6,    vr7,   vr10
    vsub.h          vr9,    vr9,    vr3
    vsub.h          vr10,   vr10,   vr7

    vsub.h          vr3,   vr0,    vr1
    vsub.h          vr7,   vr4,    vr5
    vsub.h          vr3,   vr3,    vr1
    vsub.h          vr7,   vr7,    vr5
    vadd.h          vr0,   vr0,    vr0
    vadd.h          vr4,   vr4,    vr4
    vadd.h          vr0,   vr0,    vr1
    vadd.h          vr4,   vr4,    vr5

    vilvh.h        vr11,  vr0,   vr2
    vilvh.h        vr12,  vr4,   vr6
    vilvl.h        vr13,  vr0,   vr2
    vilvl.h        vr14,  vr4,   vr6
    vilvh.h        vr15,  vr3,   vr9
    vilvh.h        vr16,  vr7,   vr10
    vilvl.h        vr17,  vr3,   vr9
    vilvl.h        vr18,  vr7,   vr10

    vilvh.w        vr19,  vr17,  vr13
    vilvh.w        vr20,  vr18,  vr14
    vilvl.w        vr13,  vr17,  vr13
    vilvl.w        vr14,  vr18,  vr14
    vilvh.w        vr17,  vr15,  vr11
    vilvh.w        vr18,  vr16,  vr12
    vilvl.w        vr11,  vr15,  vr11
    vilvl.w        vr12,  vr16,  vr12

    vilvh.d        vr0,  vr11, vr13
    vilvh.d        vr4,  vr12, vr14
    vilvl.d        vr2,  vr11, vr13
    vilvl.d        vr6,  vr12, vr14
    vilvh.d        vr1,  vr17, vr19
    vilvh.d        vr5,  vr18, vr20
    vilvl.d        vr3,  vr17, vr19
    vilvl.d        vr7,  vr18, vr20

    vadd.h          vr9,    vr1,    vr2
    vadd.h          vr10,   vr5,    vr6
    vsub.h          vr2,    vr2,    vr1
    vsub.h          vr6,    vr6,    vr5
    vadd.h          vr1,    vr3,    vr0
    vadd.h          vr5,    vr7,    vr4
    vsub.h          vr0,    vr0,    vr3
    vsub.h          vr4,    vr4,    vr7

    vadd.h          vr3,    vr1,    vr9
    vadd.h          vr7,    vr5,    vr10
    vsub.h          vr9,    vr9,    vr1
    vsub.h          vr10,   vr10,   vr5

    vsub.h          vr1,    vr2,    vr0
    vsub.h          vr5,    vr6,    vr4
    vsub.h          vr1,    vr1,    vr0
    vsub.h          vr5,    vr5,    vr4
    vadd.h          vr2,    vr2,    vr2
    vadd.h          vr6,    vr6,    vr6
    vadd.h          vr2,    vr2,    vr0
    vadd.h          vr6,    vr6,    vr4

    vilvh.d         vr0,    vr2,    vr3
    vilvh.d         vr4,    vr6,    vr7
    vilvl.d         vr3,    vr2,    vr3
    vilvl.d         vr7,    vr6,    vr7
    vilvh.d         vr2,    vr1,    vr9
    vilvh.d         vr6,    vr5,    vr10
    vilvl.d         vr9,    vr1,    vr9
    vilvl.d         vr10,   vr5,    vr10

    vor.v           vr1,    vr3,    vr3
    vor.v           vr5,    vr7,    vr7
    vor.v           vr12,   vr4,    vr4

    vst             vr3,    a0,     0
    vst             vr9,    a0,     16
    vst             vr0,    a0,     32
    vst             vr2,    a0,     48
    vst             vr5,    a0,     64
    vst             vr10,   a0,     80
    vst             vr12,   a0,     96
    vst             vr6,    a0,     112
.endm

/* void subwxh_dct( dctcoef*, pixel*, pixel* ) */
function_x264 sub4x4_dct_lsx
    fld.s           f0,     a1,      0
    fld.s           f4,     a2,      0
    fld.s           f1,     a1,      FENC_STRIDE
    fld.s           f5,     a2,      FDEC_STRIDE

    vsllwil.hu.bu   vr0,    vr0,     0
    vsllwil.hu.bu   vr1,    vr1,     0
    vsllwil.hu.bu   vr4,    vr4,     0
    vsllwil.hu.bu   vr5,    vr5,     0
    fld.s           f2,     a1,      FENC_STRIDE * 2
    fld.s           f6,     a2,      FDEC_STRIDE * 2
    fld.s           f3,     a1,      FENC_STRIDE * 3
    fld.s           f7,     a2,      FDEC_STRIDE * 3
    vsllwil.hu.bu   vr2,    vr2,     0
    vsllwil.hu.bu   vr3,    vr3,     0
    vsllwil.hu.bu   vr6,    vr6,     0
    vsllwil.hu.bu   vr7,    vr7,     0
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
endfunc_x264

function_x264 sub8x8_dct_lasx
    xvxor.v         xr8,    xr8,     xr8
    SUB8x8_DCT_CORE_LASX
endfunc_x264

function_x264 sub8x8_dct_lsx
    vxor.v         vr8,    vr8,    vr8
    SUB8x8_DCT_CORE_LSX
endfunc_x264

function_x264 sub16x16_dct_lasx
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
endfunc_x264

function_x264 sub16x16_dct_lsx
    vxor.v   vr8,   vr8,    vr8
    SUB8x8_DCT_CORE_LSX
    addi.d         a0,      a0,    32 * 4
    addi.d         a1,      a1,    8
    addi.d         a2,      a2,    8
    SUB8x8_DCT_CORE_LSX
    addi.d         a0,      a0,    32 * 4
    addi.d         a1,      a1,    8*FENC_STRIDE - 8
    addi.d         a2,      a2,    8*FDEC_STRIDE - 8
    SUB8x8_DCT_CORE_LSX
    addi.d         a0,      a0,    32 * 4
    addi.d         a1,      a1,    8
    addi.d         a2,      a2,    8
    SUB8x8_DCT_CORE_LSX
endfunc_x264

/*
 * void add4x4_idct( pixel *p_dst, dctcoef dct[16] )
 */
function_x264 add4x4_idct_lsx
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

    vhaddw.w.h      vr7,    vr1,   vr1
    vhsubw.w.h      vr8,    vr1,   vr1
    vhaddw.w.h      vr9,    vr15,  vr15
    vhsubw.w.h      vr10,   vr16,  vr16

    vadd.w          vr1,    vr7,   vr9
    vadd.w          vr2,    vr8,   vr10
    vsub.w          vr3,    vr8,   vr10
    vsub.w          vr4,    vr7,   vr9

    vpickev.h       vr1,    vr1,   vr1
    vpickev.h       vr2,    vr2,   vr2
    vpickev.h       vr3,    vr3,   vr3
    vpickev.h       vr4,    vr4,   vr4

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
endfunc_x264

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
                        xr4, xr5

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

.macro LSX_SUMSUB_W sum0, sum1, diff0, diff1, in0, in1, in2, in3
    vadd.w          \sum0,  \in0,   \in2
    vadd.w          \sum1,  \in1,   \in3
    vsub.w          \diff0, \in0,   \in2
    vsub.w          \diff1, \in1,   \in3
.endm

.macro add8x4_idct_core_lsx
    fld.d           f1,     a1,     0
    fld.d           f2,     a1,     8
    fld.d           f3,     a1,     16
    fld.d           f4,     a1,     24
    fld.d           f5,     a1,     32
    fld.d           f6,     a1,     40
    fld.d           f7,     a1,     48
    fld.d           f8,     a1,     56

    vpermi.w        vr9,    vr6,    0x04
    vpermi.w        vr9,    vr2,    0x44
    vpermi.w        vr10,   vr8,    0x04
    vpermi.w        vr10,   vr4,    0x44

    vsrai.h         vr9,    vr9,    1
    vsrai.h         vr10,   vr10,   1

    vsllwil.w.h     vr1,    vr1,    0
    vsllwil.w.h     vr5,    vr5,    0
    vsllwil.w.h     vr2,    vr2,    0
    vsllwil.w.h     vr6,    vr6,    0
    vsllwil.w.h     vr3,    vr3,    0
    vsllwil.w.h     vr7,    vr7,    0
    vsllwil.w.h     vr4,    vr4,    0
    vsllwil.w.h     vr8,    vr8,    0
    vexth.w.h       vr11,   vr9
    vsllwil.w.h     vr9,    vr9,    0
    vexth.w.h       vr12,   vr10
    vsllwil.w.h     vr10,   vr10,   0

    LSX_SUMSUB_W    vr13, vr14, vr15, vr16, vr1, vr5, vr3, vr7
    vadd.w          vr17,   vr2,    vr10
    vadd.w          vr18,   vr6,    vr12
    vsub.w          vr19,   vr9,    vr4
    vsub.w          vr20,   vr11,   vr8

    LSX_SUMSUB_W    vr3, vr7, vr10, vr12, vr13, vr14, vr17, vr18
    LSX_SUMSUB_W    vr4, vr8, vr9,  vr11, vr15, vr16, vr19, vr20

    vpickev.h       vr13,   vr3,    vr3
    vpickev.h       vr14,   vr7,    vr7
    vpickev.h       vr15,   vr4,    vr4
    vpickev.h       vr16,   vr8,    vr8
    vpickev.h       vr17,   vr9,    vr9
    vpickev.h       vr18,   vr11,   vr11
    vpickev.h       vr19,   vr10,   vr10
    vpickev.h       vr20,   vr12,   vr12

    LSX_TRANSPOSE4x4_H vr13, vr15, vr17, vr19, vr13, vr15, vr17, vr19, vr1, vr3
    LSX_TRANSPOSE4x4_H vr14, vr16, vr18, vr20, vr14, vr16, vr18, vr20, vr2, vr4

    vsllwil.w.h      vr13,   vr13,   0
    vsllwil.w.h      vr14,   vr14,   0
    vsllwil.w.h      vr15,   vr15,   0
    vsllwil.w.h      vr16,   vr16,   0
    vsllwil.w.h      vr17,   vr17,   0
    vsllwil.w.h      vr18,   vr18,   0
    vsllwil.w.h      vr19,   vr19,   0
    vsllwil.w.h      vr20,   vr20,   0

    vsrai.w          vr1,    vr15,   1
    vsrai.w          vr2,    vr16,   1
    vsrai.w          vr3,    vr19,   1
    vsrai.w          vr4,    vr20,   1

    LSX_SUMSUB_W     vr5, vr6, vr21, vr22, vr13, vr14, vr17, vr18
    vadd.w           vr8, vr15, vr3
    vadd.w           vr9, vr16, vr4
    vsub.w           vr10, vr1, vr19
    vsub.w           vr11, vr2, vr20

    LSX_SUMSUB_W     vr13, vr14, vr19, vr20, vr5, vr6, vr8, vr9
    LSX_SUMSUB_W     vr15, vr16, vr17, vr18, vr21, vr22, vr10, vr11

    vssrarni.h.w     vr15,   vr13,   6
    vssrarni.h.w     vr16,   vr14,   6
    vssrarni.h.w     vr19,   vr17,   6
    vssrarni.h.w     vr20,   vr18,   6

    fld.s           f1,     a0,    0
    fld.s           f2,     a0,    FDEC_STRIDE
    fld.s           f3,     a0,    FDEC_STRIDE * 2
    fld.s           f4,     a0,    FDEC_STRIDE * 3
    fld.s           f5,     a0,    4
    fld.s           f6,     a0,    FDEC_STRIDE + 4
    fld.s           f7,     a0,    FDEC_STRIDE * 2 + 4
    fld.s           f8,     a0,    FDEC_STRIDE * 3 + 4

    vpickve2gr.w    t0,     vr2,   0
    vinsgr2vr.w     vr1,    t0,    1
    vpickve2gr.w    t0,     vr4,   0
    vinsgr2vr.w     vr3,    t0,    1
    vpickve2gr.w    t0,     vr6,   0
    vinsgr2vr.w     vr5,    t0,    1
    vpickve2gr.w    t0,     vr8,   0
    vinsgr2vr.w     vr7,    t0,    1

    vilvl.b         vr1,    vr0,    vr1
    vilvl.b         vr5,    vr0,    vr5
    vilvl.b         vr3,    vr0,    vr3
    vilvl.b         vr7,    vr0,    vr7

    vadd.h          vr1,    vr1,    vr15
    vadd.h          vr5,    vr5,    vr16
    vadd.h          vr3,    vr3,    vr19
    vadd.h          vr7,    vr7,    vr20

    vssrarni.bu.h   vr3,    vr1,    0
    vssrarni.bu.h   vr7,    vr5,    0

    vstelm.w       vr3,    a0,    0,                     0
    vstelm.w       vr3,    a0,    FDEC_STRIDE,           1
    vstelm.w       vr3,    a0,    FDEC_STRIDE * 2,       2
    vstelm.w       vr3,    a0,    FDEC_STRIDE * 3,       3

    vstelm.w       vr7,    a0,    4,                     0
    vstelm.w       vr7,    a0,    FDEC_STRIDE + 4,       1
    vstelm.w       vr7,    a0,    FDEC_STRIDE * 2 + 4,   2
    vstelm.w       vr7,    a0,    FDEC_STRIDE * 3 + 4,   3
.endm

/*
 * void add8x8_idct( pixel *p_dst, dctcoef dct[4][16] )
 *
 */
function_x264 add8x8_idct_lasx
    xvxor.v         xr0,    xr1,   xr1
    add8x4_idct_core_lasx

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    64
    add8x4_idct_core_lasx
endfunc_x264

.macro add8x8_idct_core_lsx
    add8x4_idct_core_lsx

    addi.d          a0,     a0,     FDEC_STRIDE * 4
    addi.d          a1,     a1,     64
    add8x4_idct_core_lsx
.endm

function_x264 add8x8_idct_lsx
    vxor.v          vr0,    vr1,    vr1
    add8x8_idct_core_lsx
endfunc_x264
/*
 * void add16x16_idct( pixel *p_dst, dctcoef dct[16][16] )
 */
function_x264 add16x16_idct_lasx
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
endfunc_x264

function_x264 add16x16_idct_lsx
    move            t4,     a0
    move            t5,     a1

    vxor.v          vr0,    vr1,   vr1
    add8x8_idct_core_lsx

    addi.d          a0,     t4,    8
    addi.d          a1,     t5,    128
    add8x8_idct_core_lsx

    addi.d          t6,     t4,    FDEC_STRIDE * 8
    move            a0,     t6
    addi.d          a1,     t5,    256
    add8x8_idct_core_lsx

    addi.d          a0,     t6,    8
    addi.d          a1,     t5,    384
    add8x8_idct_core_lsx
endfunc_x264

/*
 * void add8x8_idct8( pixel *dst, dctcoef dct[64] )
 */
function_x264 add8x8_idct8_lasx
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
endfunc_x264

function_x264 add8x8_idct8_lsx
    ld.h            t0,     a1,     0
    addi.w          t0,     t0,     32
    st.h            t0,     a1,     0

    vld             vr0,    a1,     0
    vld             vr2,    a1,     32
    vld             vr4,    a1,     64
    vld             vr6,    a1,     96

    vsrai.h         vr8,    vr2,    1
    vsrai.h         vr10,   vr6,    1

    vexth.w.h       vr1,    vr0
    vsllwil.w.h     vr0,    vr0,    0
    vexth.w.h       vr3,    vr2
    vsllwil.w.h     vr2,    vr2,    0
    vexth.w.h       vr5,    vr4
    vsllwil.w.h     vr4,    vr4,    0
    vexth.w.h       vr7,    vr6
    vsllwil.w.h     vr6,    vr6,    0
    vexth.w.h       vr9,    vr8
    vsllwil.w.h     vr8,    vr8,    0
    vexth.w.h       vr11,   vr10
    vsllwil.w.h     vr10,   vr10,   0

    LSX_SUMSUB_W    vr12, vr13, vr14, vr15, vr0, vr1, vr4, vr5
    vsub.w          vr16,   vr8,    vr6
    vsub.w          vr17,   vr9,    vr7
    vadd.w          vr18,   vr10,   vr2
    vadd.w          vr19,   vr11,   vr3

    LSX_SUMSUB_W    vr20, vr21, vr18, vr19, vr12, vr13, vr18, vr19
    LSX_SUMSUB_W    vr22, vr23, vr16, vr17, vr14, vr15, vr16, vr17

    vld             vr0,    a1,     16
    vld             vr2,    a1,     48
    vld             vr4,    a1,     80
    vld             vr6,    a1,     112

    vsrai.h         vr1,    vr0,    1
    vsrai.h         vr3,    vr2,    1
    vsrai.h         vr5,    vr4,    1
    vsrai.h         vr7,    vr6,    1

    vexth.w.h       vr8,    vr0
    vsllwil.w.h     vr0,    vr0,    0
    vexth.w.h       vr10,   vr2
    vsllwil.w.h     vr2,    vr2,    0
    vexth.w.h       vr12,   vr4
    vsllwil.w.h     vr4,    vr4,    0
    vexth.w.h       vr14,   vr6
    vsllwil.w.h     vr6,    vr6,    0
    vexth.w.h       vr9,    vr1
    vsllwil.w.h     vr1,    vr1,    0
    vexth.w.h       vr11,   vr3
    vsllwil.w.h     vr3,    vr3,    0
    vexth.w.h       vr13,   vr5
    vsllwil.w.h     vr5,    vr5,    0
    vexth.w.h       vr15,   vr7
    vsllwil.w.h     vr7,    vr7,    0

    addi.d          sp,     sp,     -64
    fst.d           f24,    sp,     0
    fst.d           f25,    sp,     8
    fst.d           f26,    sp,     16
    fst.d           f27,    sp,     24
    fst.d           f28,    sp,     32
    fst.d           f29,    sp,     40
    fst.d           f30,    sp,     48
    fst.d           f31,    sp,     56
    LSX_SUMSUB_W    vr24, vr25, vr26, vr27, vr4, vr12, vr2, vr10
    LSX_SUMSUB_W    vr28, vr29, vr30, vr31, vr6, vr14, vr0, vr8

    vsub.w          vr26,   vr26,   vr6
    vsub.w          vr27,   vr27,   vr14
    vsub.w          vr26,   vr26,   vr7
    vsub.w          vr27,   vr27,   vr15
    vsub.w          vr28,   vr28,   vr2
    vsub.w          vr29,   vr29,   vr10
    vsub.w          vr28,   vr28,   vr3
    vsub.w          vr29,   vr29,   vr11
    vadd.w          vr30,   vr30,   vr4
    vadd.w          vr31,   vr31,   vr12
    vadd.w          vr30,   vr30,   vr5
    vadd.w          vr31,   vr31,   vr13
    vadd.w          vr24,   vr24,   vr0
    vadd.w          vr25,   vr25,   vr8
    vadd.w          vr24,   vr24,   vr1
    vadd.w          vr25,   vr25,   vr9

    vsrai.w         vr1,    vr26,   2
    vsrai.w         vr9,    vr27,   2
    vsrai.w         vr2,    vr28,   2
    vsrai.w         vr10,   vr29,   2
    vsrai.w         vr3,    vr30,   2
    vsrai.w         vr11,   vr31,   2
    vsrai.w         vr4,    vr24,   2
    vsrai.w         vr12,   vr25,   2

    vadd.w          vr5,    vr4,    vr26
    vadd.w          vr13,   vr12,   vr27
    vadd.w          vr6,    vr3,    vr28
    vadd.w          vr14,   vr11,   vr29
    vsub.w          vr7,    vr2,    vr30
    vsub.w          vr15,   vr10,   vr31
    vsub.w          vr0,    vr24,   vr1
    vsub.w          vr8,    vr25,   vr9

    LSX_SUMSUB_W    vr1, vr9, vr30, vr31, vr20, vr21, vr0, vr8
    LSX_SUMSUB_W    vr2, vr10, vr28, vr29, vr22, vr23, vr7, vr15
    LSX_SUMSUB_W    vr3, vr11, vr26, vr27, vr16, vr17, vr6, vr14
    LSX_SUMSUB_W    vr4, vr12, vr24, vr25, vr18, vr19, vr5, vr13

    LSX_TRANSPOSE4x4_W vr1, vr2, vr3, vr4, vr5, vr6, vr7, vr0, vr20, vr22
    LSX_TRANSPOSE4x4_W vr9, vr10, vr11, vr12, vr20, vr22, vr16, vr18, vr1, vr2
    LSX_TRANSPOSE4x4_W vr24, vr26, vr28, vr30, vr13, vr14, vr15, vr8, vr21, vr23
    LSX_TRANSPOSE4x4_W vr25, vr27, vr29, vr31, vr21, vr23, vr17, vr19, vr24, vr26

    vsrai.h         vr3,    vr7,    1
    vsrai.h         vr11,   vr15,   1
    vsrai.h         vr4,    vr16,   1
    vsrai.h         vr12,   vr17,   1

    vaddwev.w.h     vr1,    vr5,    vr20
    vaddwev.w.h     vr9,    vr13,   vr21
    vsubwev.w.h     vr2,    vr5,    vr20
    vsubwev.w.h     vr10,   vr13,   vr21
    vsubwev.w.h     vr3,    vr3,    vr16
    vsubwev.w.h     vr11,   vr11,   vr17
    vaddwev.w.h     vr4,    vr4,    vr7
    vaddwev.w.h     vr12,   vr12,   vr15

    LSX_SUMSUB_W    vr24, vr25, vr30, vr31, vr1, vr9, vr4, vr12
    LSX_SUMSUB_W    vr26, vr27, vr28, vr29, vr2, vr10, vr3, vr11

    vsrai.h         vr1,    vr6,    1
    vsrai.h         vr9,    vr14,   1
    vsrai.h         vr2,    vr0,    1
    vsrai.h         vr10,   vr8,    1
    vsrai.h         vr3,    vr22,   1
    vsrai.h         vr11,   vr23,   1
    vsrai.h         vr4,    vr18,   1
    vsrai.h         vr12,   vr19,   1

    vaddwev.w.h     vr5,    vr22,   vr0
    vaddwev.w.h     vr13,   vr23,   vr8
    vsubwev.w.h     vr20,   vr22,   vr0
    vsubwev.w.h     vr21,   vr23,   vr8
    vaddwev.w.h     vr7,    vr18,   vr6
    vaddwev.w.h     vr15,   vr19,   vr14
    vsubwev.w.h     vr16,   vr18,   vr6
    vsubwev.w.h     vr17,   vr19,   vr14

    vaddwev.w.h     vr4,    vr18,   vr4
    vaddwev.w.h     vr12,   vr19,   vr12
    vsub.w          vr20,   vr20,   vr4
    vsub.w          vr21,   vr21,   vr12
    vaddwev.w.h     vr2,    vr0,    vr2
    vaddwev.w.h     vr10,   vr8,    vr10
    vsub.w          vr7,    vr7,    vr2
    vsub.w          vr15,   vr15,   vr10
    vaddwev.w.h     vr3,    vr22,   vr3
    vaddwev.w.h     vr11,   vr23,   vr11
    vadd.w          vr16,   vr16,   vr3
    vadd.w          vr17,   vr17,   vr11
    vaddwev.w.h     vr1,    vr6,    vr1
    vaddwev.w.h     vr9,    vr14,   vr9
    vadd.w          vr5,    vr5,    vr1
    vadd.w          vr13,   vr13,   vr9

    vsrai.w         vr1,    vr20,   2
    vsrai.w         vr9,    vr21,   2
    vsrai.w         vr2,    vr7,    2
    vsrai.w         vr10,   vr15,   2
    vsrai.w         vr3,    vr16,   2
    vsrai.w         vr11,   vr17,   2
    vsrai.w         vr4,    vr5,    2
    vsrai.w         vr12,   vr13,   2

    vadd.w          vr20,   vr4,    vr20
    vadd.w          vr21,   vr12,   vr21
    vadd.w          vr22,   vr7,   vr3
    vadd.w          vr23,   vr15,   vr11
    vsub.w          vr16,   vr2,    vr16
    vsub.w          vr17,   vr10,   vr17
    vsub.w          vr18,   vr5,    vr1
    vsub.w          vr19,   vr13,   vr9

    LSX_SUMSUB_W    vr1, vr9, vr0, vr8, vr24, vr25, vr18, vr19
    LSX_SUMSUB_W    vr2, vr10, vr7, vr15, vr26, vr27, vr16, vr17
    LSX_SUMSUB_W    vr3, vr11, vr6, vr14, vr28, vr29, vr22, vr23
    LSX_SUMSUB_W    vr4, vr12, vr5, vr13, vr30, vr31, vr20, vr21

    vsrai.w         vr24,   vr1,    6
    vsrai.w         vr25,   vr9,    6
    vsrai.w         vr26,   vr2,    6
    vsrai.w         vr27,   vr10,   6
    vsrai.w         vr28,   vr3,    6
    vsrai.w         vr29,   vr11,   6
    vsrai.w         vr30,   vr4,    6
    vsrai.w         vr31,   vr12,   6
    vsrai.w         vr20,   vr5,    6
    vsrai.w         vr21,   vr13,   6
    vsrai.w         vr22,   vr6,    6
    vsrai.w         vr23,   vr14,   6
    vsrai.w         vr16,   vr7,    6
    vsrai.w         vr17,   vr15,   6
    vsrai.w         vr18,   vr0,    6
    vsrai.w         vr19,   vr8,    6

    fld.d           f1,     a0,    0
    fld.d           f2,     a0,    FDEC_STRIDE
    fld.d           f3,     a0,    FDEC_STRIDE * 2
    fld.d           f4,     a0,    FDEC_STRIDE * 3

    fld.d           f5,     a0,    FDEC_STRIDE * 4
    fld.d           f6,     a0,    FDEC_STRIDE * 5
    fld.d           f7,     a0,    FDEC_STRIDE * 6
    fld.d           f8,     a0,    FDEC_STRIDE * 7

    vsllwil.hu.bu   vr1,    vr1,    0
    vexth.wu.hu     vr9,    vr1
    vsllwil.wu.hu   vr1,    vr1,    0

    vsllwil.hu.bu   vr2,    vr2,    0
    vexth.wu.hu     vr10,   vr2
    vsllwil.wu.hu   vr2,    vr2,    0

    vsllwil.hu.bu   vr3,    vr3,    0
    vexth.wu.hu     vr11,   vr3
    vsllwil.wu.hu   vr3,    vr3,    0

    vsllwil.hu.bu   vr4,    vr4,    0
    vexth.wu.hu     vr12,   vr4
    vsllwil.wu.hu   vr4,    vr4,    0

    vsllwil.hu.bu   vr5,    vr5,    0
    vexth.wu.hu     vr13,   vr5
    vsllwil.wu.hu   vr5,    vr5,    0

    vsllwil.hu.bu   vr6,    vr6,    0
    vexth.wu.hu     vr14,   vr6
    vsllwil.wu.hu   vr6,    vr6,    0

    vsllwil.hu.bu   vr7,    vr7,    0
    vexth.wu.hu     vr15,   vr7
    vsllwil.wu.hu   vr7,    vr7,    0

    vsllwil.hu.bu   vr8,    vr8,    0
    vexth.wu.hu     vr0,    vr8
    vsllwil.wu.hu   vr8,    vr8,    0

    vadd.w          vr1,    vr1,    vr24
    vadd.w          vr9,    vr9,    vr25
    vadd.w          vr2,    vr2,    vr26
    vadd.w          vr10,   vr10,   vr27
    vadd.w          vr3,    vr3,    vr28
    vadd.w          vr11,   vr11,   vr29
    vadd.w          vr4,    vr4,    vr30
    vadd.w          vr12,   vr12,   vr31
    vadd.w          vr5,    vr5,    vr20
    vadd.w          vr13,   vr13,   vr21
    vadd.w          vr6,    vr6,    vr22
    vadd.w          vr14,   vr14,   vr23
    vadd.w          vr7,    vr7,    vr16
    vadd.w          vr15,   vr15,   vr17
    vadd.w          vr8,    vr8,    vr18
    vadd.w          vr0,    vr0,    vr19

    vssrarni.hu.w   vr2,    vr1,    0
    vssrarni.hu.w   vr10,   vr9,    0
    vssrarni.hu.w   vr4,    vr3,    0
    vssrarni.hu.w   vr12,   vr11,   0
    vssrarni.hu.w   vr6,    vr5,    0
    vssrarni.hu.w   vr14,   vr13,   0
    vssrarni.hu.w   vr8,    vr7,    0
    vssrarni.hu.w   vr0,    vr15,   0

    vpermi.w        vr20,   vr10,   0x0E
    vpermi.w        vr10,   vr2,    0x44
    vpermi.w        vr20,   vr2,    0x4E

    vpermi.w        vr21,   vr12,   0x0E
    vpermi.w        vr12,   vr4,    0x44
    vpermi.w        vr21,   vr4,    0x4E

    vpermi.w        vr22,   vr14,   0x0E
    vpermi.w        vr14,   vr6,    0x44
    vpermi.w        vr22,   vr6,    0x4E

    vpermi.w        vr23,   vr0,    0x0E
    vpermi.w        vr0,    vr8,    0x44
    vpermi.w        vr23,   vr8,    0x4E

    vssrlni.bu.h    vr12,   vr10,   0
    vssrlni.bu.h    vr21,   vr20,   0
    vssrlni.bu.h    vr0,    vr14,   0
    vssrlni.bu.h    vr23,   vr22,   0

    vstelm.d        vr12,   a0,     0,                  0
    vstelm.d        vr21,   a0,     FDEC_STRIDE,        0
    vstelm.d        vr12,   a0,     FDEC_STRIDE * 2,    1
    vstelm.d        vr21,   a0,     FDEC_STRIDE * 3,    1

    vstelm.d        vr0,    a0,     FDEC_STRIDE * 4,    0
    vstelm.d        vr23,   a0,     FDEC_STRIDE * 5,    0
    vstelm.d        vr0,    a0,     FDEC_STRIDE * 6,    1
    vstelm.d        vr23,   a0,     FDEC_STRIDE * 7,    1

    fld.d           f24,    sp,     0
    fld.d           f25,    sp,     8
    fld.d           f26,    sp,     16
    fld.d           f27,    sp,     24
    fld.d           f28,    sp,     32
    fld.d           f29,    sp,     40
    fld.d           f30,    sp,     48
    fld.d           f31,    sp,     56
    addi.d          sp,     sp,     64
endfunc_x264

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

.macro add8x4_idct_dc_lsx
    vldrepl.h       vr11,   a1,     0
    vldrepl.h       vr12,   a1,     2
    vilvl.d         vr12,   vr12,   vr11
    vsrari.h        vr12,   vr12,   6

    fld.d           f0,     a0,    0
    fld.d           f1,     a0,    FDEC_STRIDE
    fld.d           f2,     a0,    FDEC_STRIDE * 2
    fld.d           f3,     a0,    FDEC_STRIDE * 3

    vsllwil.hu.bu   vr0,    vr0,    0
    vsllwil.hu.bu   vr1,    vr1,    0
    vsllwil.hu.bu   vr2,    vr2,    0
    vsllwil.hu.bu   vr3,    vr3,    0

    vadd.h          vr0,    vr0,    vr12
    vadd.h          vr1,    vr1,    vr12
    vadd.h          vr2,    vr2,    vr12
    vadd.h          vr3,    vr3,    vr12
    vssrarni.bu.h   vr2,    vr0,    0
    vssrarni.bu.h   vr3,    vr1,    0

    vstelm.d        vr2,    a0,     0,                  0
    vstelm.d        vr3,    a0,     FDEC_STRIDE,        0
    vstelm.d        vr2,    a0,     FDEC_STRIDE * 2,    1
    vstelm.d        vr3,    a0,     FDEC_STRIDE * 3,    1
.endm
/*
 * void add8x8_idct_dc( pixel *p_dst, dctcoef dct[4] )
 */
function_x264 add8x8_idct_dc_lasx
    add8x4_idct_dc_lasx

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    4
    add8x4_idct_dc_lasx
endfunc_x264

function_x264 add8x8_idct_dc_lsx
    add8x4_idct_dc_lsx

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    4
    add8x4_idct_dc_lsx
endfunc_x264

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
function_x264 add16x16_idct_dc_lasx
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
endfunc_x264

.macro add_16x16_idct_dc_core_lsx a0, a1
    vldrepl.h       vr11,   \a1,   0
    vldrepl.h       vr12,   \a1,   2
    vldrepl.h       vr13,   \a1,   4
    vldrepl.h       vr14,   \a1,   6

    vpermi.w        vr12,   vr11,   0x44
    vpermi.w        vr14,   vr13,   0x44
    vsrari.h        vr12,   vr12,   6
    vsrari.h        vr14,   vr14,   6

    vld             vr0,    \a0,   0
    vld             vr1,    \a0,   FDEC_STRIDE
    vld             vr2,    \a0,   FDEC_STRIDE * 2
    vld             vr3,    \a0,   FDEC_STRIDE * 3

    vexth.hu.bu     vr5,    vr0
    vsllwil.hu.bu   vr0,    vr0,    0
    vexth.hu.bu     vr6,    vr1
    vsllwil.hu.bu   vr1,    vr1,    0
    vexth.hu.bu     vr7,    vr2
    vsllwil.hu.bu   vr2,    vr2,    0
    vexth.hu.bu     vr8,    vr3
    vsllwil.hu.bu   vr3,    vr3,    0

    vadd.h          vr0,    vr0,    vr12
    vadd.h          vr5,    vr5,    vr14
    vadd.h          vr1,    vr1,    vr12
    vadd.h          vr6,    vr6,    vr14
    vadd.h          vr2,    vr2,    vr12
    vadd.h          vr7,    vr7,    vr14
    vadd.h          vr3,    vr3,    vr12
    vadd.h          vr8,    vr8,    vr14

    vssrarni.bu.h   vr1,    vr0,    0
    vssrarni.bu.h   vr6,    vr5,    0
    vssrarni.bu.h   vr3,    vr2,    0
    vssrarni.bu.h   vr8,    vr7,    0

    vpermi.w        vr9,    vr6,    0x0E
    vpermi.w        vr6,    vr1,    0x44
    vpermi.w        vr9,    vr1,    0x4E
    vpermi.w        vr10,   vr8,    0x0E
    vpermi.w        vr8,    vr3,    0x44
    vpermi.w        vr10,   vr3,    0x4E

    vst             vr6,    \a0,    0
    vst             vr9,    \a0,    FDEC_STRIDE
    vst             vr8,    \a0,    FDEC_STRIDE * 2
    vst             vr10,   \a0,    FDEC_STRIDE * 3
.endm

function_x264 add16x16_idct_dc_lsx
    add_16x16_idct_dc_core_lsx a0, a1

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    8
    add_16x16_idct_dc_core_lsx a0, a1

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    8
    add_16x16_idct_dc_core_lsx a0, a1

    addi.d          a0,     a0,    FDEC_STRIDE * 4
    addi.d          a1,     a1,    8
    add_16x16_idct_dc_core_lsx a0, a1
endfunc_x264

/*
 * void idct4x4dc( dctcoef d[16] )
 */
function_x264 idct4x4dc_lasx
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
endfunc_x264

function_x264 idct4x4dc_lsx
    vld             vr0,    a0,     0
    vld             vr20,   a0,     16

    vshuf4i.b       vr1,    vr0,    0x4E
    vshuf4i.b       vr11,   vr20,   0x4E
    vhaddw.w.h      vr2,    vr0,    vr0
    vhaddw.w.h      vr12,   vr20,   vr20
    vhsubw.w.h      vr3,    vr1,    vr1
    vhsubw.w.h      vr13,   vr11,   vr11
    vshuf4i.h       vr2,    vr2,    0x4E
    vshuf4i.h       vr12,   vr12,   0x4E
    vshuf4i.h       vr3,    vr3,    0x4E
    vshuf4i.h       vr13,   vr13,   0x4E

    vhaddw.d.w      vr4,    vr2,    vr2
    vhaddw.d.w      vr14,   vr12,   vr12
    vhsubw.d.w      vr5,    vr2,    vr2
    vhsubw.d.w      vr15,   vr12,   vr12
    vhsubw.d.w      vr6,    vr3,    vr3
    vhsubw.d.w      vr16,   vr13,   vr13
    vhaddw.d.w      vr7,    vr3,    vr3
    vhaddw.d.w      vr17,   vr13,   vr13

    vpickev.w       vr8,    vr5,    vr4
    vpickev.w       vr18,   vr15,   vr14
    vpickev.w       vr9,    vr7,    vr6
    vpickev.w       vr19,   vr17,   vr16
    vpickev.h       vr10,   vr9,    vr8
    vpickev.h       vr21,   vr19,   vr18

    vpermi.w        vr22,   vr21,   0x0E
    vpermi.w        vr21,   vr10,   0x44
    vpermi.w        vr22,   vr10,   0x4E
    vpermi.w        vr21,   vr21,   0xD8
    vpermi.w        vr22,   vr22,   0xD8

    vshuf4i.b       vr11,   vr21,   0x4E
    vshuf4i.b       vr12,   vr22,   0x4E
    vhaddw.w.h      vr21,   vr21,   vr21
    vhaddw.w.h      vr22,   vr22,   vr22
    vhsubw.w.h      vr11,   vr11,   vr11
    vhsubw.w.h      vr12,   vr12,   vr12
    vshuf4i.h       vr21,   vr21,   0x4E
    vshuf4i.h       vr22,   vr22,   0x4E
    vshuf4i.h       vr11,   vr11,   0x4E
    vshuf4i.h       vr12,   vr12,   0x4E

    vhaddw.d.w      vr13,   vr21,   vr21
    vhaddw.d.w      vr14,   vr22,   vr22
    vhsubw.d.w      vr15,   vr21,   vr21
    vhsubw.d.w      vr16,   vr22,   vr22
    vhsubw.d.w      vr17,   vr11,   vr11
    vhsubw.d.w      vr18,   vr12,   vr12
    vhaddw.d.w      vr19,   vr11,   vr11
    vhaddw.d.w      vr20,   vr12,   vr12

    vpackev.w       vr7,    vr15,   vr13
    vpackev.w       vr8,    vr16,   vr14
    vpackev.w       vr9,    vr19,   vr17
    vpackev.w       vr10,   vr20,   vr18
    vilvl.d         vr0,    vr9,    vr7
    vilvl.d         vr4,    vr10,   vr8
    vilvh.d         vr1,    vr9,    vr7
    vilvh.d         vr5,    vr10,   vr8

    vpickev.h       vr2,    vr1,    vr0
    vpickev.h       vr3,    vr5,    vr4
    vst             vr2,    a0,     0
    vst             vr3,    a0,     16
endfunc_x264

/*
 * void dct4x4dc( dctcoef d[16] )
 */
function_x264 dct4x4dc_lasx
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
endfunc_x264

function_x264 dct4x4dc_lsx
    vld             vr0,    a0,     0
    vld             vr20,   a0,     16

    vshuf4i.b       vr1,    vr0,    0x4E
    vshuf4i.b       vr11,   vr20,   0x4E
    vhaddw.w.h      vr2,    vr0,    vr0
    vhaddw.w.h      vr12,   vr20,   vr20
    vhsubw.w.h      vr3,    vr1,    vr1
    vhsubw.w.h      vr13,   vr11,   vr11
    vshuf4i.h       vr2,    vr2,    0x4E
    vshuf4i.h       vr12,   vr12,   0x4E
    vshuf4i.h       vr3,    vr3,    0x4E
    vshuf4i.h       vr13,   vr13,   0x4E

    vhaddw.d.w      vr4,    vr2,    vr2
    vhaddw.d.w      vr14,   vr12,   vr12
    vhsubw.d.w      vr5,    vr2,    vr2
    vhsubw.d.w      vr15,   vr12,   vr12
    vhsubw.d.w      vr6,    vr3,    vr3
    vhsubw.d.w      vr16,   vr13,   vr13
    vhaddw.d.w      vr7,    vr3,    vr3
    vhaddw.d.w      vr17,   vr13,   vr13

    vpickev.w       vr8,    vr5,    vr4
    vpickev.w       vr18,   vr15,   vr14
    vpickev.w       vr9,    vr7,    vr6
    vpickev.w       vr19,   vr17,   vr16
    vpickev.h       vr10,   vr9,    vr8
    vpickev.h       vr21,   vr19,   vr18

    vpermi.w        vr22,   vr21,   0x0E
    vpermi.w        vr21,   vr10,   0x44
    vpermi.w        vr22,   vr10,   0x4E
    vpermi.w        vr21,   vr21,   0xD8
    vpermi.w        vr22,   vr22,   0xD8

    vshuf4i.b       vr11,   vr21,   0x4E
    vshuf4i.b       vr12,   vr22,   0x4E
    vhaddw.w.h      vr21,   vr21,   vr21
    vhaddw.w.h      vr22,   vr22,   vr22
    vhsubw.w.h      vr11,   vr11,   vr11
    vhsubw.w.h      vr12,   vr12,   vr12
    vshuf4i.h       vr21,   vr21,   0x4E
    vshuf4i.h       vr22,   vr22,   0x4E
    vshuf4i.h       vr11,   vr11,   0x4E
    vshuf4i.h       vr12,   vr12,   0x4E

    vhaddw.d.w      vr13,   vr21,   vr21
    vhaddw.d.w      vr14,   vr22,   vr22
    vhsubw.d.w      vr15,   vr21,   vr21
    vhsubw.d.w      vr16,   vr22,   vr22
    vhsubw.d.w      vr17,   vr11,   vr11
    vhsubw.d.w      vr18,   vr12,   vr12
    vhaddw.d.w      vr19,   vr11,   vr11
    vhaddw.d.w      vr20,   vr12,   vr12

    vpackev.w       vr7,    vr15,   vr13
    vpackev.w       vr8,    vr16,   vr14
    vpackev.w       vr9,    vr19,   vr17
    vpackev.w       vr10,   vr20,   vr18

    vsrari.w        vr7,    vr7,    1
    vsrari.w        vr8,    vr8,    1
    vsrari.w        vr9,    vr9,    1
    vsrari.w        vr10,   vr10,   1

    vilvl.d         vr0,    vr9,    vr7
    vilvl.d         vr4,    vr10,   vr8
    vilvh.d         vr1,    vr9,    vr7
    vilvh.d         vr10,   vr10,   vr8
    vpickev.h       vr2,    vr1,    vr0
    vpickev.h       vr3,    vr10,   vr4
    vst             vr2,    a0,     0
    vst             vr3,    a0,     16
endfunc_x264

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
function_x264 sub8x8_dct8_lsx
    vxor.v           vr8,    vr0,   vr0

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
endfunc_x264

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
function_x264 sub16x16_dct8_lasx
    move            t1,     a1
    move            t3,     a2
    SUB16x8_DCT8_LASX

    addi.d          a0,     a0,    256
    addi.d          a1,     t1,    FENC_STRIDE * 8
    addi.d          a2,     t3,    FDEC_STRIDE * 8
    SUB16x8_DCT8_LASX
endfunc_x264


.macro LSX_LOAD_PIX_22 data1, data2, data3, data4
    vld             vr0,    a1,     0
    vld             vr4,    a1,     16
    vld             vr1,    a1,     FENC_STRIDE
    vld             vr5,    a1,     FENC_STRIDE + 16
    vld             vr2,    a2,     0
    vld             vr6,    a2,     16
    vld             vr3,    a2,     FDEC_STRIDE
    vld             vr7,    a2,     FDEC_STRIDE + 16

    vpermi.w        vr8,    vr0,    0x0E
    vpermi.w        vr0,    vr0,    0x44
    vpermi.w        vr8,    vr8,    0x44
    vpermi.w        vr9,    vr1,    0x0E
    vpermi.w        vr1,    vr1,    0x44
    vpermi.w        vr9,    vr9,    0x44
    vpermi.w        vr10,   vr2,    0x0E
    vpermi.w        vr2,    vr2,    0x44
    vpermi.w        vr10,   vr10,   0x44
    vpermi.w        vr11,   vr3,    0x0E
    vpermi.w        vr3,    vr3,    0x44
    vpermi.w        vr11,   vr11,   0x44

    vxor.v          vr30,   vr0,    vr0
    vxor.v          vr31,   vr8,    vr8

    vilvl.b         vr0,    vr30,   vr0
    vilvl.b         vr8,    vr31,   vr8
    vilvl.b         vr1,    vr30,   vr1
    vilvl.b         vr9,    vr31,   vr9
    vilvl.b         vr2,    vr30,   vr2
    vilvl.b         vr10,   vr31,   vr10
    vilvl.b         vr3,    vr30,   vr3
    vilvl.b         vr11,   vr31,   vr11

    vsub.h          \data1, vr0,    vr2
    vsub.h          \data3, vr8,    vr10
    vsub.h          \data2, vr1,    vr3
    vsub.h          \data4, vr9,    vr11
    addi.d          a1,     a1,     FENC_STRIDE * 2
    addi.d          a2,     a2,     FDEC_STRIDE * 2
.endm

.macro SUB16x8_DCT8_LSX
    LSX_LOAD_PIX_22 vr12,    vr13,   vr22,   vr23
    LSX_LOAD_PIX_22 vr14,    vr15,   vr24,   vr25
    LSX_LOAD_PIX_22 vr16,    vr17,   vr26,   vr27
    LSX_LOAD_PIX_22 vr18,    vr19,   vr28,   vr29

    LSX_DCT8_1D
    LSX_TRANSPOSE8x8_H vr12, vr13, vr14, vr15, vr16, vr17, vr18, vr19, \
                        vr12, vr13, vr14, vr15, vr16, vr17, vr18, vr19, \
                        vr0, vr1, vr2, vr3, vr4, vr5, vr6, vr7
    LSX_DCT8_1D

    vst             vr12,   a0,     0
    vst             vr13,   a0,     16
    vst             vr14,   a0,     32
    vst             vr15,   a0,     48
    vst             vr16,   a0,     64
    vst             vr17,   a0,     80
    vst             vr18,   a0,     96
    vst             vr19,   a0,     112

    vmov            vr12,   vr22
    vmov            vr13,   vr23
    vmov            vr14,   vr24
    vmov            vr15,   vr25
    vmov            vr16,   vr26
    vmov            vr17,   vr27
    vmov            vr18,   vr28
    vmov            vr19,   vr29

    LSX_DCT8_1D
    LSX_TRANSPOSE8x8_H vr12, vr13, vr14, vr15, vr16, vr17, vr18, vr19, \
                        vr12, vr13, vr14, vr15, vr16, vr17, vr18, vr19, \
                        vr0, vr1, vr2, vr3, vr4, vr5, vr6, vr7
    LSX_DCT8_1D

    vst             vr12,   a0,     128
    vst             vr13,   a0,     144
    vst             vr14,   a0,     160
    vst             vr15,   a0,     176
    vst             vr16,   a0,     192
    vst             vr17,   a0,     208
    vst             vr18,   a0,     224
    vst             vr19,   a0,     240
.endm

function_x264 sub16x16_dct8_lsx
    addi.d          sp,     sp,     -64
    fst.d           f24,    sp,     0
    fst.d           f25,    sp,     8
    fst.d           f26,    sp,     16
    fst.d           f27,    sp,     24
    fst.d           f28,    sp,     32
    fst.d           f29,    sp,     40
    fst.d           f30,    sp,     48
    fst.d           f31,    sp,     56

    move            t1,     a1
    move            t3,     a2
    SUB16x8_DCT8_LSX

    addi.d          a0,     a0,    256
    addi.d          a1,     t1,    FENC_STRIDE * 8
    addi.d          a2,     t3,    FDEC_STRIDE * 8
    SUB16x8_DCT8_LSX

    fld.d           f24,    sp,     0
    fld.d           f25,    sp,     8
    fld.d           f26,    sp,     16
    fld.d           f27,    sp,     24
    fld.d           f28,    sp,     32
    fld.d           f29,    sp,     40
    fld.d           f30,    sp,     48
    fld.d           f31,    sp,     56
    addi.d          sp,     sp,     64
endfunc_x264

/*
 * void zigzag_scan_4x4_frame( dctcoef level[16], dctcoef dct[16] )
 */
function_x264 zigzag_scan_4x4_frame_lasx
    xvld            xr1,    a1,    0
    xvor.v          xr2,    xr1,   xr1
    xvpermi.q       xr2,    xr2,   0x13
    xvpermi.q       xr1,    xr1,   0x02
    la.local        t0,     zigzag_scan4
    xvld            xr3,    t0,    0
    xvshuf.h        xr3,    xr2,   xr1
    xvst            xr3,    a0,    0
endfunc_x264

function_x264 zigzag_scan_4x4_frame_lsx
    vld             vr1,    a1,     0
    vld             vr2,    a1,     16
    vor.v           vr3,    vr1,    vr1
    vor.v           vr4,    vr2,    vr2
    la.local        t0,     zigzag_scan4
    vld             vr5,    t0,     0
    vld             vr6,    t0,     16
    vshuf.h         vr5,    vr4,    vr1
    vshuf.h         vr6,    vr4,    vr1
    vst             vr5,    a0,     0
    vst             vr6,    a0,     16
endfunc_x264
