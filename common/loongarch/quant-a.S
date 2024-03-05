/*****************************************************************************
 * quant-a.S: LoongArch quantization and level-run
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Shiyou Yin <yinshiyou-hf@loongson.cn>
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

const last64_shuf
.int 0, 4, 1, 5, 2, 6, 3, 7
endconst

/*
 * int quant_4x4x4( dctcoef dct[4][16], udctcoef mf[16], udctcoef bias[16] )
 */
.macro QUANT_ONE_LASX s1, s2, s3, s4
    xvld           xr1,     \s1,   0  /* Load dctcoef */
    xvadda.h       \s4,     xr1,   \s3
    xvmuh.hu       \s4,     \s4,   \s2
    xvsigncov.h    \s4,     xr1,   \s4
    xvst           \s4,     \s1,   0
.endm

function_x264 quant_4x4x4_lasx
    xvld           xr2,     a1,    0
    xvld           xr3,     a2,    0
    QUANT_ONE_LASX a0, xr2, xr3, xr4
    addi.d         a0,      a0,    32
    QUANT_ONE_LASX a0, xr2, xr3, xr0
    xvssrlni.h.w   xr0,     xr4,   0
    addi.d         a0,      a0,    32
    QUANT_ONE_LASX a0, xr2, xr3, xr4
    addi.d         a0,      a0,    32
    QUANT_ONE_LASX a0, xr2, xr3, xr5
    xvssrlni.h.w   xr5,     xr4,   0
    xvssrlni.h.w   xr5,     xr0,   0
    xvseqi.w       xr5,     xr5,   0
    xvmskltz.w     xr5,     xr5
    xvpickve2gr.w  t0,      xr5,   0
    xvpickve2gr.w  t1,      xr5,   4
    alsl.d         t0,      t1,    t0,    4
    and            t0,      t0,    t1
    xori           a0,      t0,    0xf
endfunc_x264

.macro QUANT_ONE_LSX tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7
    vld             vr0,      \tmp1,    0
    vld             vr1,      \tmp1,    16
    vadda.h         \tmp6,    vr0,      \tmp4
    vadda.h         \tmp7,    vr1,      \tmp5
    vmuh.hu         \tmp6,    \tmp6,    \tmp2
    vmuh.hu         \tmp7,    \tmp7,    \tmp3
    vsigncov.h      \tmp6,    vr0,      \tmp6
    vsigncov.h      \tmp7,    vr1,      \tmp7
    vst             \tmp6,    \tmp1,    0
    vst             \tmp7,    \tmp1,    16
.endm

function_x264 quant_4x4x4_lsx
    vld             vr2,    a1,     0
    vld             vr3,    a1,     16
    vld             vr4,    a2,     0
    vld             vr5,    a2,     16
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr6, vr7
    addi.d          a0,     a0,     32
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr8, vr9
    vssrlni.h.w     vr8,    vr6,    0
    vssrlni.h.w     vr9,    vr7,    0
    addi.d          a0,     a0,     32
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr10, vr11
    addi.d          a0,     a0,     32
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr12, vr13
    vssrlni.h.w     vr12,   vr10,   0
    vssrlni.h.w     vr13,   vr11,   0
    vssrlni.h.w     vr12,   vr8,    0
    vssrlni.h.w     vr13,   vr9,    0
    vseqi.w         vr12,   vr12,   0
    vseqi.w         vr13,   vr13,   0
    vmskltz.w       vr12,   vr12
    vmskltz.w       vr13,   vr13
    vpickve2gr.w    t0,     vr12,   0
    vpickve2gr.w    t1,     vr13,   0
    alsl.d          t0,     t1,     t0,     4
    and             t0,     t0,     t1
    xori            a0,     t0,     0xf
endfunc_x264

function_x264 quant_4x4_lsx
    vld             vr2,    a1,     0
    vld             vr3,    a1,     16
    vld             vr4,    a2,     0
    vld             vr5,    a2,     16
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr10, vr11
    vor.v           vr22,   vr10,   vr11
    vpickve2gr.d    t0,     vr22,   0
    vpickve2gr.d    t1,     vr22,   1
    or              t2,     t0,     t1
    addi.w          t3,     zero,   1
    maskeqz         a0,     t3,     t2
endfunc_x264

function_x264 quant_8x8_lsx
    vld             vr2,    a1,     0
    vld             vr3,    a1,     16
    vld             vr4,    a2,     0
    vld             vr5,    a2,     16
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr12, vr13

    addi.d          a0,     a0,     32
    vld             vr2,    a1,     32
    vld             vr3,    a1,     48
    vld             vr4,    a2,     32
    vld             vr5,    a2,     48
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr14, vr15

    addi.d          a0,     a0,     32
    vld             vr2,    a1,     64
    vld             vr3,    a1,     80
    vld             vr4,    a2,     64
    vld             vr5,    a2,     80
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr22, vr23

    addi.d          a0,     a0,     32
    vld             vr2,    a1,     96
    vld             vr3,    a1,     112
    vld             vr4,    a2,     96
    vld             vr5,    a2,     112
    QUANT_ONE_LSX   a0, vr2, vr3, vr4, vr5, vr7, vr8

    vor.v           vr12,   vr12,   vr14
    vor.v           vr13,   vr13,   vr15
    vor.v           vr22,   vr22,   vr7
    vor.v           vr23,   vr23,   vr8
    vor.v           vr12,   vr12,   vr22
    vor.v           vr13,   vr13,   vr23
    vor.v           vr11,   vr12,   vr13
    vpickve2gr.d    t0,     vr11,   0
    vpickve2gr.d    t1,     vr11,   1
    or              t2,     t0,     t1
    addi.w          t3,     zero,   1
    maskeqz         a0,     t3,     t2
endfunc_x264

function_x264 quant_4x4_dc_lsx
    vld             vr0,    a0,     0
    vld             vr1,    a0,     16
    vreplgr2vr.w    vr2,    a1
    vreplgr2vr.w    vr3,    a2
    vslei.h         vr4,    vr0,    0
    vslei.h         vr5,    vr1,    0

    vexth.w.h       vr7,    vr0
    vsllwil.w.h     vr6,    vr0,    0
    vexth.w.h       vr9,    vr1
    vsllwil.w.h     vr8,    vr1,    0
    vadda.w         vr6,    vr3,    vr6
    vadda.w         vr7,    vr3,    vr7
    vadda.w         vr8,    vr3,    vr8
    vadda.w         vr9,    vr3,    vr9
    vmul.w          vr6,    vr6,    vr2
    vmul.w          vr7,    vr7,    vr2
    vmul.w          vr8,    vr8,    vr2
    vmul.w          vr9,    vr9,    vr2
    vsrani.h.w      vr8,    vr6,    16
    vsrani.h.w      vr9,    vr7,    16
    vpermi.w        vr10,   vr9,    0x0E
    vpermi.w        vr9,    vr8,    0x44
    vpermi.w        vr10,   vr8,    0x4E
    vneg.h          vr11,   vr9
    vneg.h          vr12,   vr10
    vbitsel.v       vr13,   vr9,    vr11,   vr4
    vbitsel.v       vr14,   vr10,   vr12,   vr5
    vst             vr13,   a0,     0
    vst             vr14,   a0,     16

    vor.v           vr15,   vr11,   vr12
    vpickve2gr.d    t0,     vr15,   0
    vpickve2gr.d    t1,     vr15,   1
    or              t2,     t0,     t1
    addi.w          t3,     zero,   1
    maskeqz         a0,     t3,     t2
endfunc_x264

/*
 * int quant_2x2_dc( dctcoef dct[4], int mf, int bias )
 */
function_x264 quant_2x2_dc_lsx
    fld.d           f0,     a0,    0
    vreplgr2vr.w    vr1,    a1
    vreplgr2vr.w    vr2,    a2

    vslei.h         vr3,    vr0,   0

    vsllwil.w.h     vr4,    vr0,   0
    vadda.w         vr4,    vr4,   vr2
    vmul.w          vr4,    vr4,   vr1
    vsrani.h.w      vr4,    vr4,   16
    vneg.h          vr8,    vr4
    vbitsel.v       vr9,    vr4,   vr8,    vr3
    vstelm.d        vr9,    a0,    0,      0

    vpickve2gr.w   t0,      vr9,   0
    vpickve2gr.w   t1,      vr9,   1
    or             t2,      t0,    t1
    addi.w         t3,      zero,  1
    maskeqz        a0,      t3,    t2
endfunc_x264

/*
 * int coeff_last64_c(dctcoef *l)
 */
function_x264 coeff_last64_lasx
    addi.w          t0,     zero,  63
    xvxor.v         xr20,   xr0,   xr0

    xvld            xr0,    a0,    0
    xvld            xr1,    a0,    32
    xvld            xr2,    a0,    64
    xvld            xr3,    a0,    96

    xvldi           xr4,    1
    la.local        t1,     last64_shuf
    xvld            xr7,    t1,    0
    xvldi           xr9,    0x408
    xvldi           xr10,   0x401

    xvssrlni.bu.h   xr1,    xr0,   0
    xvssrlni.bu.h   xr3,    xr2,   0
    xvsle.bu        xr5,    xr4,   xr1
    xvsle.bu        xr6,    xr4,   xr3
    xvssrlni.bu.h   xr6,    xr5,   4
    xvperm.w        xr6,    xr6,   xr7
    xvclz.w         xr7,    xr6
    xvssrlni.hu.w   xr7,    xr7,   2
    xvpermi.d       xr8,    xr7,   0xd8

    xvsub.h         xr9,    xr9,   xr8
    xvsll.h         xr10,   xr10,  xr9
    xvssrlni.bu.h   xr10,   xr10,  1
    xvclz.d         xr11,   xr10
    xvpickve2gr.w   t3,     xr11,  0
    sub.w           a0,     t0,    t3
endfunc_x264

function_x264 coeff_last64_lsx
    addi.w          t0,     zero,  63
    vxor.v          vr20,   vr0,   vr0
    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    vld             vr2,    a0,    32
    vld             vr3,    a0,    48
    vld             vr4,    a0,    64
    vld             vr5,    a0,    80
    vld             vr6,    a0,    96
    vld             vr7,    a0,    112
    vldi            vr8,    1
    vldi            vr9,    0x408
    vldi            vr10,   0x401

    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vssrlni.bu.h    vr2,    vr2,   0
    vssrlni.bu.h    vr3,    vr3,   0
    vssrlni.bu.h    vr4,    vr4,   0
    vssrlni.bu.h    vr5,    vr5,   0
    vssrlni.bu.h    vr6,    vr6,   0
    vssrlni.bu.h    vr7,    vr7,   0
    vpermi.w        vr2,    vr0,   0x44
    vpermi.w        vr3,    vr1,   0x44
    vpermi.w        vr6,    vr4,   0x44
    vpermi.w        vr7,    vr5,   0x44
    vsle.bu         vr2,    vr8,   vr2
    vsle.bu         vr3,    vr8,   vr3
    vsle.bu         vr6,    vr8,   vr6
    vsle.bu         vr7,    vr8,   vr7
    vssrlni.bu.h    vr2,    vr2,   4
    vssrlni.bu.h    vr3,    vr3,   4
    vssrlni.bu.h    vr6,    vr6,   4
    vssrlni.bu.h    vr7,    vr7,   4
    vpermi.w        vr6,    vr2,   0x44
    vpermi.w        vr7,    vr3,   0x44
    vpermi.w        vr11,   vr7,   0x0E
    vpermi.w        vr7,    vr6,   0x44
    vpermi.w        vr7,    vr7,   0xD8
    vpermi.w        vr11,   vr6,   0x4E
    vpermi.w        vr11,   vr11,  0xD8
    vclz.w          vr7,    vr7
    vclz.w          vr11,   vr11
    vssrlni.hu.w    vr7,    vr7,   2
    vssrlni.hu.w    vr11,   vr11,  2
    vpermi.w        vr12,   vr11,  0x0E
    vpermi.w        vr11,   vr7,   0x44
    vpermi.w        vr12,   vr7,   0x4E
    vsub.h          vr11,   vr9,   vr11
    vsub.h          vr12,   vr9,   vr12
    vsll.h          vr13,   vr10,  vr11
    vsll.h          vr14,   vr10,  vr12
    vssrlni.bu.h    vr13,   vr13,  1
    vssrlni.bu.h    vr14,   vr14,  1

    vclz.d          vr15,   vr14
    vpickve2gr.w    t1,     vr15,   0
    sub.w           a0,     t0,    t1
endfunc_x264

/*
 * int coeff_last16_c(dctcoef *l)
 */
function_x264 coeff_last16_lasx
    addi.w          t0,     zero,  15

    xvld            xr0,    a0,    0
    xvldi           xr2,    1

    xvssrlni.bu.h   xr0,    xr0,   0
    xvpermi.d       xr1,    xr0,   0xd8
    xvsle.bu        xr3,    xr2,   xr1
    xvssrlni.bu.h   xr3,    xr3,   4
    xvclz.d         xr4,    xr3
    xvpickve2gr.w   t1,     xr4,   0

    srai.w          t1,     t1,    2
    sub.w           a0,     t0,    t1
endfunc_x264

function_x264 coeff_last16_lsx
    addi.w          t0,     zero,  15
    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    vldi            vr2,    1

    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vpermi.w        vr1,    vr0,   0x44
    vsle.bu         vr3,    vr2,   vr1
    vssrlni.bu.h    vr3,    vr3,   4
    vclz.d          vr4,    vr3
    vpickve2gr.w    t1,     vr4,   0

    srai.w          t1,     t1,    2
    sub.w           a0,     t0,    t1
endfunc_x264

/*
 * int coeff_last15_c(dctcoef *l)
 */
function_x264 coeff_last15_lasx
    addi.w          t0,     zero,  15

    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    xvldi           xr3,    1

    vinsgr2vr.h     vr1,    zero,  7
    xvpermi.q       xr1,    xr0,   0x20

    xvssrlni.bu.h   xr1,    xr1,   0
    xvpermi.d       xr2,    xr1,   0xd8
    xvsle.bu        xr4,    xr3,   xr2
    xvssrlni.bu.h   xr4,    xr4,   4
    xvclz.d         xr5,    xr4
    xvpickve2gr.w   t1,     xr5,   0

    srai.w          t1,     t1,    2
    sub.w           a0,     t0,    t1
endfunc_x264

function_x264 coeff_last15_lsx
    addi.w          t0,     zero,  15
    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    vldi            vr2,    1
    vinsgr2vr.h     vr1,    zero,  7

    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vpermi.w        vr1,    vr0,   0x44
    vsle.bu         vr3,    vr2,   vr1
    vssrlni.bu.h    vr3,    vr3,   4
    vclz.d          vr4,    vr3
    vpickve2gr.w    t1,     vr4,   0

    srai.w          t1,     t1,    2
    sub.w           a0,     t0,    t1
endfunc_x264

/*
 * int coeff_last8_c(dctcoef *l)
 */
function_x264 coeff_last8_lsx
    addi.w          t0,     zero,  7
    vld             vr0,    a0,    0
    vclz.d          vr1,    vr0
    vpickve2gr.w    t1,     vr1,   0
    vpickve2gr.w    t2,     vr1,   2
    li.d            t3,     64
    bne             t2,     t3,    .LAST8_LOW_LSX
    addi.d          t4,     t1,    0
    addi.d          t0,     t0,    -4
    b               .LAST8_END_LSX
.LAST8_LOW_LSX:
    addi.d          t4,     t2,    0
.LAST8_END_LSX:
    srai.w          t4,     t4,    4
    sub.w           a0,     t0,    t4
endfunc_x264

/*
 * int coeff_last4_c(dctcoef *l)
 */
function_x264 coeff_last4_lsx
    addi.w          t0,     zero,  3
    vld             vr0,    a0,    0
    vclz.d          vr1,    vr0
    vpickve2gr.w    t1,     vr1,   0
    srai.w          t1,     t1,    4
    sub.w           a0,     t0,    t1
endfunc_x264

// (dct[i] * dequant_mf[i]) << (i_qbits)
.macro DCT_MF a0, a1, in0, out0, out1
    vld             vr1,    \a0,   0
    xvld            xr2,    \a1,   0

    vext2xv.w.h     xr5,    xr1
    xvmul.w         xr5,    xr5,   xr2
    xvsll.w         \out0,  xr5,   \in0

    vld             vr1,    \a0,   16
    xvld            xr2,    \a1,   32
    vext2xv.w.h     xr5,    xr1
    xvmul.w         xr5,    xr5,   xr2
    xvsll.w         \out1,  xr5,   \in0
.endm

// (dct[i] * dequant_mf[i] + f) >> (-i_qbits)
.macro DCT_MF_F a0, a1, in0, out0, out1
    vld             vr1,    \a0,   0
    xvld            xr2,    \a1,   0

    vext2xv.w.h     xr5,    xr1
    xvmul.w         xr5,    xr5,   xr2
    xvsrar.w        \out0,  xr5,   \in0

    vld             vr1,    \a0,   16
    xvld            xr2,    \a1,   32
    vext2xv.w.h     xr5,    xr1
    xvmul.w         xr5,    xr5,   xr2
    xvsrar.w        \out1,  xr5,   \in0
.endm

/*
 * void dequant_4x4( dctcoef dct[16], int dequant_mf[6][16], int i_qp )
 */
function_x264 dequant_4x4_lasx
    addi.w          t1,     zero,  6
    addi.w          t2,     zero,  4
    div.w           t0,     a2,    t1
    sub.w           t0,     t0,    t2  // i_qp/6 - 4
    mod.w           t1,     a2,    t1  // i_qp%6
    slli.w          t1,     t1,    6
    add.d           a1,     a1,    t1

    blt             t0,     zero,  .DQ4x4_DEQUANT_SHR

    // i_qbits >= 0
    xvreplgr2vr.w   xr0,    t0
    DCT_MF a0, a1, xr0, xr6, xr7
    b               .DQ4x4_END

.DQ4x4_DEQUANT_SHR:
    sub.w           t4,     zero,  t0
    xvreplgr2vr.w   xr4,    t4
    DCT_MF_F a0, a1, xr4, xr6, xr7

.DQ4x4_END:
    xvpickev.h      xr8,    xr7,   xr6
    xvpermi.d       xr8,    xr8,   0xd8
    xvst            xr8,    a0,    0
endfunc_x264

.macro DCT_MF_LSX   tmp0, tmp1, in0, out0, out1, out2, out3
    vld             vr0,    \tmp0,  0
    vld             vr1,    \tmp1,  0
    vld             vr2,    \tmp1,  16
    vexth.w.h       vr4,    vr0
    vsllwil.w.h     vr3,    vr0,    0
    vmul.w          vr3,    vr3,    vr1
    vmul.w          vr4,    vr4,    vr2
    vsll.w          \out0,  vr3,    \in0
    vsll.w          \out1,  vr4,    \in0

    vld             vr0,    \tmp0,  16
    vld             vr1,    \tmp1,  32
    vld             vr2,    \tmp1,  48
    vsllwil.w.h     vr3,    vr0,    0
    vpermi.w        vr4,    vr0,    0x0E
    vsllwil.w.h     vr4,    vr4,    0
    vmul.w          vr3,    vr3,    vr1
    vmul.w          vr4,    vr4,    vr2
    vsll.w          \out2,  vr3,    \in0
    vsll.w          \out3,  vr4,    \in0
.endm

.macro DCT_MF_F_LSX tmp0, tmp1, in0, out0, out1, out2, out3
    vld             vr0,    \tmp0,  0
    vld             vr1,    \tmp1,  0
    vld             vr2,    \tmp1,  16
    vexth.w.h       vr4,    vr0
    vsllwil.w.h     vr3,    vr0,    0
    vmul.w          vr3,    vr3,    vr1
    vmul.w          vr4,    vr4,    vr2
    vsrar.w         \out0,  vr3,    \in0
    vsrar.w         \out1,  vr4,    \in0

    vld             vr0,    \tmp0,  16
    vld             vr1,    \tmp1,  32
    vld             vr2,    \tmp1,  48
    vexth.w.h       vr4,    vr0
    vsllwil.w.h     vr3,    vr0,    0
    vmul.w          vr3,    vr3,    vr1
    vmul.w          vr4,    vr4,    vr2
    vsrar.w         \out2,  vr3,    \in0
    vsrar.w         \out3,  vr4,    \in0
.endm

function_x264 dequant_4x4_lsx
    addi.w          t1,     zero,   6
    addi.w          t2,     zero,   4
    div.w           t0,     a2,     t1
    sub.w           t0,     t0,     t2
    mod.w           t1,     a2,     t1
    slli.w          t1,     t1,     6
    add.d           a1,     a1,     t1
    blt             t0,     zero,   .DQ4x4_DEQUANT_SHR_LSX

    vreplgr2vr.w    vr6,    t0
    DCT_MF_LSX      a0,     a1,     vr6,    vr7,    vr8,    vr9,    vr10
    b               .DQ4x4_END_LSX

.DQ4x4_DEQUANT_SHR_LSX:
    sub.w           t4,     zero,   t0
    vreplgr2vr.w    vr6,    t4
    DCT_MF_F_LSX    a0,     a1,     vr6,    vr7,    vr8,    vr9,    vr10
.DQ4x4_END_LSX:
    vpickev.h       vr11,   vr9,    vr7
    vpickev.h       vr12,   vr10,   vr8
    vpermi.w        vr13,   vr12,   0x0E
    vpermi.w        vr12,   vr11,   0x44
    vpermi.w        vr13,   vr11,   0x4E
    vst             vr12,   a0,     0
    vst             vr13,   a0,     16
endfunc_x264
/*
 * void dequant_8x8( dctcoef dct[64], int dequant_mf[6][64], int i_qp )
 */
function_x264 dequant_8x8_lasx
    addi.w          t1,     zero,  6
    div.w           t0,     a2,    t1
    sub.w           t0,     t0,    t1
    mod.w           t1,     a2,    t1  // i_qp%6
    slli.w          t1,     t1,    8
    add.d           a1,     a1,    t1

    blt             t0,     zero,  .DQ8x8_DEQUANT_SHR
    // i_qbits >= 0
    xvreplgr2vr.w   xr0,    t0
    DCT_MF a0, a1, xr0, xr6, xr7
    xvpickev.h      xr8,    xr7,   xr6
    xvpermi.d       xr8,    xr8,   0xd8
    xvst            xr8,    a0,    0

.rept 3
    addi.d          a0,     a0,    32
    addi.d          a1,     a1,    64
    DCT_MF a0, a1, xr0, xr6, xr7
    xvpickev.h      xr8,    xr7,   xr6
    xvpermi.d       xr8,    xr8,   0xd8
    xvst            xr8,    a0,    0
.endr
    b               .DQ8x8_END

// i_qbits < 0
.DQ8x8_DEQUANT_SHR:
    sub.w           t4,     zero,  t0
    xvreplgr2vr.w   xr4,    t4

    DCT_MF_F a0, a1, xr4, xr6, xr7
    xvpickev.h      xr8,    xr7,   xr6
    xvpermi.d       xr8,    xr8,   0xd8
    xvst            xr8,    a0,    0

.rept 3
    addi.d          a0,     a0,    32
    addi.d          a1,     a1,    64
    DCT_MF_F a0, a1, xr4, xr6, xr7
    xvpickev.h      xr8,    xr7,   xr6
    xvpermi.d       xr8,    xr8,   0xd8
    xvst            xr8,    a0,    0
.endr

.DQ8x8_END:
endfunc_x264

function_x264 dequant_8x8_lsx
    addi.w          t1,     zero,   6
    div.w           t0,     a2,     t1
    sub.w           t0,     t0,     t1
    mod.w           t1,     a2,     t1
    slli.w          t1,     t1,     8
    add.d           a1,     a1,     t1

    blt             t0,     zero,   .DQ8x8_DEQUANT_SHR_LSX
    vreplgr2vr.w    vr6,    t0
    DCT_MF_LSX      a0,     a1,     vr6,    vr7,    vr8,    vr9,    vr10
    vpickev.h       vr11,   vr9,    vr7
    vpickev.h       vr12,   vr10,   vr8
    vpermi.w        vr13,   vr12,   0x0E
    vpermi.w        vr12,   vr11,   0x44
    vpermi.w        vr13,   vr11,   0x4E
    vst             vr12,   a0,     0
    vst             vr13,   a0,     16
.rept 3
    addi.d          a0,     a0,     32
    addi.d          a1,     a1,     64
    DCT_MF_LSX      a0,     a1,     vr6,    vr7,    vr8,    vr9,    vr10
    vpickev.h       vr11,   vr9,    vr7
    vpickev.h       vr12,   vr10,   vr8
    vpermi.w        vr13,   vr12,   0x0E
    vpermi.w        vr12,   vr11,   0x44
    vpermi.w        vr13,   vr11,   0x4E
    vst             vr12,   a0,     0
    vst             vr13,   a0,     16
.endr
    b               .DQ8x8_END_LSX

.DQ8x8_DEQUANT_SHR_LSX:
    sub.w           t4,     zero,   t0
    vreplgr2vr.w    vr6,    t4
    DCT_MF_F_LSX    a0,     a1,     vr6,    vr7,    vr8,    vr9,    vr10
    vpickev.h       vr11,   vr9,    vr7
    vpickev.h       vr12,   vr10,   vr8
    vpermi.w        vr13,   vr12,   0x0E
    vpermi.w        vr12,   vr11,   0x44
    vpermi.w        vr13,   vr11,   0x4E
    vst             vr12,   a0,     0
    vst             vr13,   a0,     16
.rept 3
    addi.d          a0,     a0,     32
    addi.d          a1,     a1,     64
    DCT_MF_F_LSX    a0,     a1,     vr6,    vr7,    vr8,    vr9,    vr10
    vpickev.h       vr11,   vr9,    vr7
    vpickev.h       vr12,   vr10,   vr8
    vpermi.w        vr13,   vr12,   0x0E
    vpermi.w        vr12,   vr11,   0x44
    vpermi.w        vr13,   vr11,   0x4E
    vst             vr12,   a0,     0
    vst             vr13,   a0,     16
.endr
.DQ8x8_END_LSX:
endfunc_x264

/*
 * void dequant_4x4_dc( dctcoef dct[16], int dequant_mf[6][16], int i_qp )
 */
function_x264 dequant_4x4_dc_lasx
    addi.w          t0,     zero,  6
    div.w           t1,     a2,    t0
    sub.w           t1,     t1,    t0

    blt             t1,     zero,  .DQ4x4DC_LT_ZERO
    // i_qbits >= 0
    mod.w           t2,     a2,    t0
    slli.w          t2,     t2,    6
    ldx.w           t0,     a1,    t2
    sll.w           t0,     t0,    t1

    vld             vr1,    a0,    0
    vld             vr10,   a0,    16
    xvreplgr2vr.w   xr2,    t0

    vext2xv.w.h     xr3,    xr1
    xvmul.w         xr6,    xr3,   xr2

    vext2xv.w.h     xr3,    xr10
    xvmul.w         xr7,    xr3,   xr2
    b               .DQ4x4DC_END

// i_qbits < 0
.DQ4x4DC_LT_ZERO:
    mod.w           t2,     a2,    t0
    slli.w          t2,     t2,    6
    ldx.w           t0,     a1,    t2
    sub.w           t3,     zero,  t1

    vld             vr1,    a0,    0
    vld             vr10,   a0,    16
    xvreplgr2vr.w   xr2,    t0
    xvreplgr2vr.w   xr4,    t3

    vext2xv.w.h     xr5,    xr1
    xvmul.w         xr5,    xr5,   xr2
    xvsrar.w        xr6,    xr5,   xr4

    vext2xv.w.h     xr5,    xr10
    xvmul.w         xr5,    xr5,   xr2
    xvsrar.w        xr7,    xr5,   xr4

.DQ4x4DC_END:
    xvpickev.h      xr8,    xr7,   xr6
    xvpermi.d       xr8,    xr8,   0xd8
    xvst            xr8,    a0,    0
endfunc_x264

function_x264 dequant_4x4_dc_lsx
    addi.w          t0,     zero,  6
    div.w           t1,     a2,    t0
    sub.w           t1,     t1,    t0

    blt             t1,     zero,  .DQ4x4DC_LT_ZERO_LSX
    mod.w           t2,     a2,    t0
    slli.w          t2,     t2,    6
    ldx.w           t0,     a1,    t2
    sll.w           t0,     t0,    t1
    vld             vr1,    a0,    0
    vld             vr2,    a0,    16
    vreplgr2vr.w    vr3,    t0
    vexth.w.h       vr6,    vr1
    vsllwil.w.h     vr5,    vr1,   0
    vmul.w          vr5,    vr5,   vr3
    vmul.w          vr6,    vr6,   vr3

    vexth.w.h       vr8,    vr2
    vsllwil.w.h     vr7,    vr2,   0
    vmul.w          vr7,    vr7,   vr3
    vmul.w          vr8,    vr8,   vr3
    b               .DQ4x4DC_END_LSX
.DQ4x4DC_LT_ZERO_LSX:
    mod.w           t2,     a2,    t0
    slli.w          t2,     t2,    6
    ldx.w           t0,     a1,    t2
    sub.w           t3,     zero,  t1
    vld             vr1,    a0,    0
    vld             vr2,    a0,    16
    vreplgr2vr.w    vr3,    t0
    vreplgr2vr.w    vr4,    t3
    vexth.w.h       vr6,    vr1
    vsllwil.w.h     vr5,    vr1,   0
    vexth.w.h       vr8,    vr2
    vsllwil.w.h     vr7,    vr2,   0
    vmul.w          vr5,    vr5,   vr3
    vmul.w          vr6,    vr6,   vr3
    vmul.w          vr7,    vr7,   vr3
    vmul.w          vr8,    vr8,   vr3
    vsrar.w         vr5,    vr5,   vr4
    vsrar.w         vr6,    vr6,   vr4
    vsrar.w         vr7,    vr7,   vr4
    vsrar.w         vr8,    vr8,   vr4
.DQ4x4DC_END_LSX:
    vpickev.h       vr9,    vr7,   vr5
    vpickev.h       vr10,   vr8,   vr6
    vpermi.w        vr11,   vr10,  0x0E
    vpermi.w        vr10,   vr9,   0x44
    vpermi.w        vr11,   vr9,   0x4E
    vst             vr10,   a0,    0
    vst             vr11,   a0,    16
endfunc_x264

/*
 * int decimate_score15( dctcoef *dct )
 */
function_x264 decimate_score15_lsx
    addi.w          t0,     zero,  15
    la.local        t3,     x264_decimate_table4
    addi.d          t4,     a0,    2

    vld             vr0,    t4,    0
    vld             vr1,    t4,    16
    vldi            vr3,    1
    vinsgr2vr.h     vr1,    zero,  7
    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vpermi.w        vr2,    vr1,   0x0E
    vpermi.w        vr1,    vr0,   0x44
    vpermi.w        vr2,    vr0,   0x4E
    vsle.bu         vr4,    vr3,   vr1
    vsle.bu         vr5,    vr3,   vr2
    vssrlni.bu.h    vr4,    vr4,   4
    vssrlni.bu.h    vr5,    vr5,   4
    vclz.d          vr4,    vr4
    vclz.d          vr5,    vr5
    vpickve2gr.w    t1,     vr4,   0

    srai.w          t1,     t1,    2
    sub.w           t2,     t0,    t1
    addi.w          t0,     zero,  2
    move            a0,     zero
    slli.d          t2,     t2,    1
.LOOP_SCORE_15_LSX:
    blt             t2,     zero,  .END_SCORE_15_LSX
    ldx.h           t5,     t4,    t2
    addi.d          t6,     t5,    1
    bltu            t0,     t6,    .RET_SCORE_15_1_LSX
    addi.d          t2,     t2,    -2
    move            t5,     zero
.WHILE_SCORE_15_LSX:
    blt             t2,     zero,  .END_WHILE_15_LSX
    ldx.h           t1,     t4,    t2
    bnez            t1,     .END_WHILE_15_LSX
    addi.d          t2,     t2,    -2
    addi.d          t5,     t5,    1
    b               .WHILE_SCORE_15_LSX
.END_WHILE_15_LSX:
    ldx.b           t1,     t3,    t5
    add.d           a0,     a0,    t1
    b               .LOOP_SCORE_15_LSX
.RET_SCORE_15_1_LSX:
    addi.d          a0,     zero,  9
    jirl            $r0,    $r1,   0x0
.END_SCORE_15_LSX:
endfunc_x264

/*
 * int decimate_score16( dctcoef *dct )
 */
function_x264 decimate_score16_lsx
    addi.w          t0,     zero,  15
    la.local        t3,     x264_decimate_table4
    addi.w          t0,     zero,  15
    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    vldi            vr2,    1

    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vpermi.w        vr3,    vr1,   0x0E
    vpermi.w        vr1,    vr0,   0x44
    vpermi.w        vr3,    vr0,   0x4E
    vsle.bu         vr4,    vr2,   vr1
    vsle.bu         vr5,    vr2,   vr3
    vssrlni.bu.h    vr4,    vr4,   4
    vssrlni.bu.h    vr5,    vr5,   4
    vclz.d          vr4,    vr4
    vclz.d          vr5,    vr5
    vpickve2gr.w    t1,     vr4,   0

    srai.w          t1,     t1,    2
    sub.w           t2,     t0,    t1
    move            t4,     a0
    addi.d          t0,     zero,  2
    move            a0,     zero
    slli.d          t2,     t2,    1
.LOOP_SCORE_16_LSX:
    blt             t2,     zero,  .END_SCORE_16_LSX
    ldx.h           t5,     t4,    t2
    addi.d          t6,     t5,    1
    bltu            t0,     t6,    .RET_SCORE_16_1_LSX
    addi.d          t2,     t2,    -2
    move            t5,     zero
.WHILE_SCORE_16_LSX:
    blt             t2,     zero,  .END_WHILE_16_LSX
    ldx.h           t1,     t4,    t2
    bnez            t1,     .END_WHILE_16_LSX
    addi.d          t2,     t2,    -2
    addi.d          t5,     t5,    1
    b               .WHILE_SCORE_16_LSX
.END_WHILE_16_LSX:
    ldx.b           t1,     t3,    t5
    add.d           a0,     a0,    t1
    b               .LOOP_SCORE_16_LSX
.RET_SCORE_16_1_LSX:
    addi.d          a0,     zero,  9
    jirl            $r0,    $r1,   0x0
.END_SCORE_16_LSX:
endfunc_x264

/*
 * int decimate_score64( dctcoef *dct )
 */
function_x264 decimate_score64_lsx
    addi.w          t0,     zero,  63
    la.local        t3,     x264_decimate_table8
    vxor.v          vr20,   vr0,   vr0
    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    vld             vr2,    a0,    32
    vld             vr3,    a0,    48
    vld             vr4,    a0,    64
    vld             vr5,    a0,    80
    vld             vr6,    a0,    96
    vld             vr7,    a0,    112
    vldi            vr8,    1
    vldi            vr9,    0x408
    vldi            vr10,   0x401

    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vssrlni.bu.h    vr2,    vr2,   0
    vssrlni.bu.h    vr3,    vr3,   0
    vssrlni.bu.h    vr4,    vr4,   0
    vssrlni.bu.h    vr5,    vr5,   0
    vssrlni.bu.h    vr6,    vr6,   0
    vssrlni.bu.h    vr7,    vr7,   0
    vpermi.w        vr2,    vr0,   0x44
    vpermi.w        vr3,    vr1,   0x44
    vpermi.w        vr6,    vr4,   0x44
    vpermi.w        vr7,    vr5,   0x44
    vsle.bu         vr2,    vr8,   vr2
    vsle.bu         vr3,    vr8,   vr3
    vsle.bu         vr6,    vr8,   vr6
    vsle.bu         vr7,    vr8,   vr7
    vssrlni.bu.h    vr2,    vr2,   4
    vssrlni.bu.h    vr3,    vr3,   4
    vssrlni.bu.h    vr6,    vr6,   4
    vssrlni.bu.h    vr7,    vr7,   4
    vpermi.w        vr6,    vr2,   0x44
    vpermi.w        vr7,    vr3,   0x44
    vpermi.w        vr11,   vr7,   0x0E
    vpermi.w        vr7,    vr6,   0x44
    vpermi.w        vr7,    vr7,   0xD8
    vpermi.w        vr11,   vr6,   0x4E
    vpermi.w        vr11,   vr11,  0xD8
    vclz.w          vr7,    vr7
    vclz.w          vr11,   vr11
    vssrlni.hu.w    vr7,    vr7,   2
    vssrlni.hu.w    vr11,   vr11,  2
    vpermi.w        vr12,   vr11,  0x0E
    vpermi.w        vr11,   vr7,   0x44
    vpermi.w        vr12,   vr7,   0x4E
    vsub.h          vr11,   vr9,   vr11
    vsub.h          vr12,   vr9,   vr12
    vsll.h          vr13,   vr10,  vr11
    vsll.h          vr14,   vr10,  vr12
    vssrlni.bu.h    vr13,   vr13,  1
    vssrlni.bu.h    vr14,   vr14,  1

    vclz.d          vr15,   vr14
    vpickve2gr.w    t1,     vr15,  0
    sub.w           t2,     t0,    t1
    move            t4,     a0
    addi.d          t0,     zero,  2
    slli.d          t2,     t2,    1
    move            a0,     zero
.LOOP_SCORE_64_LSX:
    blt             t2,     zero,  .END_SCORE_64_LSX
    ldx.h           t5,     t4,    t2
    addi.d          t6,     t5,    1
    bltu            t0,     t6,    .RET_SCORE_64_1_LSX
    addi.d          t2,     t2,    -2
    move            t5,     zero
.WHILE_SCORE_64_LSX:
    blt             t2,     zero,  .END_WHILE_64_LSX
    ldx.h           t1,     t4,    t2
    bnez            t1,     .END_WHILE_64_LSX
    addi.d          t2,     t2,    -2
    addi.d          t5,     t5,    1
    b               .WHILE_SCORE_64_LSX
.END_WHILE_64_LSX:
    ldx.b           t1,     t3,    t5
    add.d           a0,     a0,    t1
    b               .LOOP_SCORE_64_LSX
.RET_SCORE_64_1_LSX:
    addi.d          a0,     zero,  9
    jirl            $r0,    $r1,   0x0
.END_SCORE_64_LSX:
endfunc_x264

/*
 * int coeff_level_run16( dctcoef *dct, x264_run_level_t *runlevel )
 */
function_x264 coeff_level_run16_lasx
    addi.w          t0,     zero,  15

    xvld            xr0,    a0,    0
    xvldi           xr2,    1

    xvssrlni.bu.h   xr0,    xr0,   0
    xvpermi.d       xr1,    xr0,   0xd8
    xvsle.bu        xr3,    xr2,   xr1
    xvsrlni.b.h     xr3,    xr3,   4
    xvpickve2gr.du  t8,     xr3,   0
    clz.d           t1,     t8

    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    st.w            t0,     a1,    0x00 // Store runlevel->last
    addi.d          t3,     a1,    23
    nor             t2,     zero,  zero
    addi.d          t2,     t2,    -15
    and             t3,     t3,    t2 // runlevel->level
    xor             t4,     t4,    t4 // mask
    xor             t5,     t5,    t5 // total: number of non-zero elements
    addi.w          t6,     zero,  1  // const 1
.LOOP_COEFF_LEVEL_RUN16_LASX:
    slli.w          t7,     t0,    1
    ldx.h           t2,     a0,    t7
    st.h            t2,     t3,    0
    addi.d          t3,     t3,    2

    addi.w          t5,     t5,    1
    sll.w           t2,     t6,    t0
    or              t4,     t4,    t2
    bge             zero,   t4,    .END_COEFF_LEVEL_RUN16_LASX

    addi.w          t0,     t0,    -1
    slli.w          t1,     t1,    2
    addi.w          t1,     t1,    4
    sll.d           t8,     t8,    t1
    clz.d           t1,     t8
    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    bge             t0,     zero,  .LOOP_COEFF_LEVEL_RUN16_LASX
.END_COEFF_LEVEL_RUN16_LASX:
    st.w            t4,     a1,    4
    move            a0,     t5
endfunc_x264

function_x264 coeff_level_run15_lasx
    addi.w          t0,     zero,  15

    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    xvldi           xr3,    1

    vinsgr2vr.h     vr1,    zero,  7
    xvpermi.q       xr1,    xr0,   0x20

    xvssrlni.bu.h   xr1,    xr1,   0
    xvpermi.d       xr2,    xr1,   0xd8
    xvsle.bu        xr4,    xr3,   xr2
    xvsrlni.b.h     xr4,    xr4,   4
    xvpickve2gr.du  t8,     xr4,   0
    clz.d           t1,     t8

    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    st.w            t0,     a1,    0x00 // Store runlevel->last
    addi.d          t3,     a1,    23
    nor             t2,     zero,  zero
    addi.d          t2,     t2,    -15
    and             t3,     t3,    t2 // runlevel->level
    xor             t4,     t4,    t4 // mask
    xor             t5,     t5,    t5 // total: number of non-zero elements
    addi.w          t6,     zero,  1  // const 1
.LOOP_COEFF_LEVEL_RUN15_LASX:
    slli.w          t7,     t0,    1
    ldx.h           t2,     a0,    t7
    st.h            t2,     t3,    0
    addi.d          t3,     t3,    2

    addi.w          t5,     t5,    1
    sll.w           t2,     t6,    t0
    or              t4,     t4,    t2
    bge             zero,   t4,    .END_COEFF_LEVEL_RUN15_LASX

    addi.w          t0,     t0,    -1
    slli.w          t1,     t1,    2
    addi.w          t1,     t1,    4
    sll.d           t8,     t8,    t1
    clz.d           t1,     t8
    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    bge             t0,     zero,  .LOOP_COEFF_LEVEL_RUN15_LASX
.END_COEFF_LEVEL_RUN15_LASX:
    st.w            t4,     a1,    4
    move            a0,     t5
endfunc_x264

function_x264 coeff_level_run16_lsx
    addi.w          t0,     zero,  15
    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    vldi            vr2,    1

    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vpermi.w        vr1,    vr0,   0x44
    vsle.bu         vr3,    vr2,   vr1
    vsrlni.b.h      vr3,    vr3,   4
    vpickve2gr.du   t8,     vr3,   0
    clz.d           t1,     t8

    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    st.w            t0,     a1,    0x00 // Store runlevel->last
    addi.d          t3,     a1,    23
    nor             t2,     zero,  zero
    addi.d          t2,     t2,    -15
    and             t3,     t3,    t2 // runlevel->level
    xor             t4,     t4,    t4 // mask
    xor             t5,     t5,    t5 // total: number of non-zero elements
    addi.w          t6,     zero,  1  // const 1
.LOOP_COEFF_LEVEL_RUN16_LSX:
    slli.w          t7,     t0,    1
    ldx.h           t2,     a0,    t7
    st.h            t2,     t3,    0
    addi.d          t3,     t3,    2

    addi.w          t5,     t5,    1
    sll.w           t2,     t6,    t0
    or              t4,     t4,    t2
    bge             zero,   t4,    .END_COEFF_LEVEL_RUN16_LSX

    addi.w          t0,     t0,    -1
    slli.w          t1,     t1,    2
    addi.w          t1,     t1,    4
    sll.d           t8,     t8,    t1
    clz.d           t1,     t8
    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    bge             t0,     zero,  .LOOP_COEFF_LEVEL_RUN16_LSX
.END_COEFF_LEVEL_RUN16_LSX:
    st.w            t4,     a1,    4
    move            a0,     t5
endfunc_x264

function_x264 coeff_level_run15_lsx
    addi.w          t0,     zero,  15
    vld             vr0,    a0,    0
    vld             vr1,    a0,    16
    vldi            vr2,    1
    vinsgr2vr.h     vr1,    zero,  7

    vssrlni.bu.h    vr0,    vr0,   0
    vssrlni.bu.h    vr1,    vr1,   0
    vpermi.w        vr1,    vr0,   0x44
    vsle.bu         vr3,    vr2,   vr1
    vsrlni.b.h      vr3,    vr3,   4
    vpickve2gr.du   t8,     vr3,   0
    clz.d           t1,     t8

    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    st.w            t0,     a1,    0x00 // Store runlevel->last
    addi.d          t3,     a1,    23
    nor             t2,     zero,  zero
    addi.d          t2,     t2,    -15
    and             t3,     t3,    t2 // runlevel->level
    xor             t4,     t4,    t4 // mask
    xor             t5,     t5,    t5 // total: number of non-zero elements
    addi.w          t6,     zero,  1  // const 1
.LOOP_COEFF_LEVEL_RUN15_LSX:
    slli.w          t7,     t0,    1
    ldx.h           t2,     a0,    t7
    st.h            t2,     t3,    0
    addi.d          t3,     t3,    2

    addi.w          t5,     t5,    1
    sll.w           t2,     t6,    t0
    or              t4,     t4,    t2
    bge             zero,   t4,    .END_COEFF_LEVEL_RUN15_LSX

    addi.w          t0,     t0,    -1
    slli.w          t1,     t1,    2
    addi.w          t1,     t1,    4
    sll.d           t8,     t8,    t1
    clz.d           t1,     t8
    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    bge             t0,     zero,  .LOOP_COEFF_LEVEL_RUN15_LSX
.END_COEFF_LEVEL_RUN15_LSX:
    st.w            t4,     a1,    4
    move            a0,     t5
endfunc_x264

function_x264 coeff_level_run8_lsx
    addi.w          t0,     zero,  15
    vld             vr0,    a0,    0
    vxor.v          vr1,    vr1,   vr1
    vldi            vr2,    1

    vssrlni.bu.h    vr0,    vr0,   0
    vpermi.w        vr1,    vr0,   0x44
    vsle.bu         vr3,    vr2,   vr1
    vsrlni.b.h      vr3,    vr3,   4
    vpickve2gr.du   t8,     vr3,   0
    clz.d           t1,     t8

    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    st.w            t0,     a1,    0x00 // Store runlevel->last
    addi.d          t3,     a1,    23
    nor             t2,     zero,  zero
    addi.d          t2,     t2,    -15
    and             t3,     t3,    t2 // runlevel->level
    xor             t4,     t4,    t4 // mask
    xor             t5,     t5,    t5 // total: number of non-zero elements
    addi.w          t6,     zero,  1  // const 1
.LOOP_COEFF_LEVEL_RUN8_LSX:
    slli.w          t7,     t0,    1
    ldx.h           t2,     a0,    t7
    st.h            t2,     t3,    0
    addi.d          t3,     t3,    2

    addi.w          t5,     t5,    1
    sll.w           t2,     t6,    t0
    or              t4,     t4,    t2
    bge             zero,   t4,    .END_COEFF_LEVEL_RUN8_LSX

    addi.w          t0,     t0,    -1
    slli.w          t1,     t1,    2
    addi.w          t1,     t1,    4
    sll.d           t8,     t8,    t1
    clz.d           t1,     t8
    srai.w          t1,     t1,    2
    sub.w           t0,     t0,    t1 // Index of the first non-zero element starting from the highest bit
    bge             t0,     zero,  .LOOP_COEFF_LEVEL_RUN8_LSX
.END_COEFF_LEVEL_RUN8_LSX:
    st.w            t4,     a1,    4
    move            a0,     t5
endfunc_x264
