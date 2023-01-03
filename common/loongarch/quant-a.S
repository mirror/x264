/*****************************************************************************
 * quant-a.S: LoongArch quantization and level-run
 *****************************************************************************
 * Copyright (C) 2015-2018 x264 project
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

const last64_shuf
.int 0, 4, 1, 5, 2, 6, 3, 7
endconst

const decimate_table4
.byte 3, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
endconst

const decimate_table8
.byte 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1
.byte 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0
.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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

function quant_4x4x4_lasx
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
endfunc

/*
 * int quant_8x8( dctcoef dct[64], udctcoef mf[64], udctcoef bias[64] )
 */
function quant_8x8_lasx
    xvld           xr1,     a0,    0
    vld            vr2,     a1,    0
    vld            vr3,     a2,    0
    xvslei.h       xr19,    xr1,   0

    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr7,     xr6,   xr4
    xvmul.w        xr8,     xr7,   xr5

    xvpermi.q      xr1,     xr1,   0x01
    vld            vr2,     a1,    16
    vld            vr3,     a2,    16
    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr9,     xr6,   xr4
    xvmul.w        xr10,    xr9,   xr5
    xvsrani.h.w    xr10,    xr8,   16
    xvpermi.d      xr11,    xr10,  0xd8
    xvneg.h        xr12,    xr11
    xvbitsel.v     xr15,    xr11,  xr12,    xr19
    xvst           xr15,    a0,    0

    xvld           xr1,     a0,    32
    vld            vr2,     a1,    32
    vld            vr3,     a2,    32
    xvslei.h       xr19,    xr1,   0

    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr7,     xr6,   xr4
    xvmul.w        xr8,     xr7,   xr5

    xvpermi.q      xr1,     xr1,   0x01
    vld            vr2,     a1,    48
    vld            vr3,     a2,    48
    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr9,     xr6,   xr4
    xvmul.w        xr10,    xr9,   xr5
    xvsrani.h.w    xr10,    xr8,   16
    xvpermi.d      xr11,    xr10,  0xd8
    xvneg.h        xr12,    xr11
    xvbitsel.v     xr16,    xr11,  xr12,    xr19
    xvst           xr16,    a0,    32

    xvld           xr1,     a0,    64
    vld            vr2,     a1,    64
    vld            vr3,     a2,    64
    xvslei.h       xr19,    xr1,   0

    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr7,     xr6,   xr4
    xvmul.w        xr8,     xr7,   xr5

    xvpermi.q      xr1,     xr1,   0x01
    vld            vr2,     a1,    80
    vld            vr3,     a2,    80
    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr9,     xr6,   xr4
    xvmul.w        xr10,    xr9,   xr5
    xvsrani.h.w    xr10,    xr8,   16
    xvpermi.d      xr11,    xr10,  0xd8
    xvneg.h        xr12,    xr11
    xvbitsel.v     xr17,    xr11,  xr12,    xr19
    xvst           xr17,    a0,    64

    xvld           xr1,     a0,    96
    vld            vr2,     a1,    96
    vld            vr3,     a2,    96
    xvslei.h       xr19,    xr1,   0

    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr7,     xr6,   xr4
    xvmul.w        xr8,     xr7,   xr5

    xvpermi.q      xr1,     xr1,   0x01
    vld            vr2,     a1,    112
    vld            vr3,     a2,    112
    vext2xv.w.h    xr4,     xr1
    vext2xv.wu.hu  xr5,     xr2
    vext2xv.wu.hu  xr6,     xr3
    xvadda.w       xr9,     xr6,   xr4
    xvmul.w        xr10,    xr9,   xr5
    xvsrani.h.w    xr10,    xr8,   16
    xvpermi.d      xr11,    xr10,  0xd8
    xvneg.h        xr12,    xr11
    xvbitsel.v     xr18,    xr11,  xr12,    xr19
    xvst           xr18,    a0,    96

    // xr15 xr16 xr17 xr18
    xvor.v          xr15,   xr15,  xr16
    xvor.v          xr17,   xr17,  xr18
    xvor.v          xr15,   xr15,  xr17
    xvpermi.q       xr16,   xr15,  0x01
    vor.v           vr11,   vr16,  vr15
    vpickve2gr.d    t0,     vr11,  0
    vpickve2gr.d    t1,     vr11,  1
    or              t2,     t0,    t1
    addi.w          t3,     zero,  1
    maskeqz         a0,     t3,    t2
endfunc

/*
 * int quant_4x4( dctcoef dct[16], udctcoef mf[16], udctcoef bias[16] )
 */
function quant_4x4_lasx
    xvld            xr1,    a0,    0
    vld             vr2,    a1,    0
    vld             vr3,    a2,    0
    xvslei.h        xr19,   xr1,   0

    vext2xv.w.h     xr4,    xr1
    vext2xv.wu.hu   xr5,    xr2
    vext2xv.wu.hu   xr6,    xr3
    xvadda.w        xr7,    xr6,   xr4
    xvmul.w         xr8,    xr7,   xr5

    xvpermi.q       xr1,    xr1,   0x01
    vld             vr2,    a1,    16
    vld             vr3,    a2,    16
    vext2xv.w.h     xr4,    xr1
    vext2xv.wu.hu   xr5,    xr2
    vext2xv.wu.hu   xr6,    xr3
    xvadda.w        xr9,    xr6,   xr4
    xvmul.w         xr10,   xr9,   xr5
    xvsrani.h.w     xr10,   xr8,   16
    xvpermi.d       xr11,   xr10,  0xd8
    xvneg.h         xr12,   xr11
    xvbitsel.v      xr9,    xr11,  xr12,    xr19
    xvst            xr9,    a0,    0

    xvpermi.q       xr10,   xr9,   0x01
    vor.v           vr11,   vr10,  vr9
    vpickve2gr.d    t0,     vr11,  0
    vpickve2gr.d    t1,     vr11,  1
    or              t2,     t0,    t1
    addi.w          t3,     zero,  1
    maskeqz         a0,     t3,    t2
endfunc

/*
 * int quant_4x4_dc( dctcoef dct[16], int mf, int bias )
 */
function quant_4x4_dc_lasx
    xvld            xr0,    a0,    0

    xvreplgr2vr.w   xr1,    a1
    xvreplgr2vr.w   xr2,    a2

    xvslei.h        xr3,    xr0,   0

    vext2xv.w.h     xr4,    xr0
    xvpermi.q       xr5,    xr0,   0x01
    vext2xv.w.h     xr5,    xr5

    xvadda.w        xr4,    xr2,   xr4
    xvadda.w        xr5,    xr2,   xr5
    xvmul.w         xr4,    xr4,   xr1
    xvmul.w         xr5,    xr5,   xr1
    xvsrani.h.w     xr5,    xr4,   16
    xvpermi.d       xr5,    xr5,   0xd8
    xvneg.h         xr8,    xr5
    xvbitsel.v      xr9,    xr5,   xr8,   xr3
    xvst            xr9,    a0,    0

    xvpermi.q       xr10,   xr9,   0x01
    vor.v           vr11,   vr10,  vr9
    vpickve2gr.d    t0,     vr11,  0
    vpickve2gr.d    t1,     vr11,  1
    or              t2,     t0,    t1
    addi.w          t3,     zero,  1
    maskeqz         a0,     t3,    t2
endfunc

/*
 * int quant_2x2_dc( dctcoef dct[4], int mf, int bias )
 */
function quant_2x2_dc_lsx
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
endfunc

/*
 * int coeff_last64_c(dctcoef *l)
 */
function coeff_last64_lasx
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
endfunc

/*
 * int coeff_last16_c(dctcoef *l)
 */
function coeff_last16_lasx
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
endfunc

/*
 * int coeff_last15_c(dctcoef *l)
 */
function coeff_last15_lasx
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
endfunc

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
function dequant_4x4_lasx
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
endfunc

/*
 * void dequant_8x8( dctcoef dct[64], int dequant_mf[6][64], int i_qp )
 */
function dequant_8x8_lasx
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

endfunc

/*
 * void dequant_4x4_dc( dctcoef dct[16], int dequant_mf[6][16], int i_qp )
 */
function dequant_4x4_dc_lasx
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
endfunc

/*
 * int decimate_score15( dctcoef *dct )
 */
function decimate_score15_lasx
    addi.w          t0,     zero,  15
    la.local        t3,     decimate_table4

    addi.d          t4,     a0,    2
    vld             vr0,    t4,    0
    vld             vr1,    t4,    16
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
    sub.w           t2,     t0,    t1
    addi.d          t0,     zero,  2
    move            a0,     zero
    slli.d          t2,     t2,    1
.LOOP_SCORE_15:
    blt             t2,     zero,  .END_SCORE_15
    ldx.h           t5,     t4,    t2
    addi.d          t6,     t5,    1
    bltu            t0,     t6,    .RET_SCORE_15_1
    addi.d          t2,     t2,    -2
    move            t5,     zero
.WHILE_SCORE_15:
    blt             t2,     zero,  .END_WHILE_15
    ldx.h           t1,     t4,    t2
    bnez            t1,     .END_WHILE_15
    addi.d          t2,     t2,    -2
    addi.d          t5,     t5,    1
    b               .WHILE_SCORE_15
.END_WHILE_15:
    ldx.b           t1,     t3,    t5
    add.d           a0,     a0,    t1
    b               .LOOP_SCORE_15
.RET_SCORE_15_1:
    addi.d          a0,     zero,  9
    jirl            $r0,    $r1,   0x0
.END_SCORE_15:
endfunc

/*
 * int decimate_score16( dctcoef *dct )
 */
function decimate_score16_lasx
    addi.w          t0,     zero,  15
    la.local        t3,     decimate_table4

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
    sub.w           t2,     t0,    t1
    move            t4,     a0
    addi.d          t0,     zero,  2
    move            a0,     zero
    slli.d          t2,     t2,    1
.LOOP_SCORE_16:
    blt             t2,     zero,  .END_SCORE_16
    ldx.h           t5,     t4,    t2
    addi.d          t6,     t5,    1
    bltu            t0,     t6,    .RET_SCORE_16_1
    addi.d          t2,     t2,    -2
    move            t5,     zero
.WHILE_SCORE_16:
    blt             t2,     zero,  .END_WHILE_16
    ldx.h           t1,     t4,    t2
    bnez            t1,     .END_WHILE_16
    addi.d          t2,     t2,    -2
    addi.d          t5,     t5,    1
    b               .WHILE_SCORE_16
.END_WHILE_16:
    ldx.b           t1,     t3,    t5
    add.d           a0,     a0,    t1
    b               .LOOP_SCORE_16
.RET_SCORE_16_1:
    addi.d          a0,     zero,  9
    jirl            $r0,    $r1,   0x0
.END_SCORE_16:
endfunc

/*
 * int decimate_score64( dctcoef *dct )
 */
function decimate_score64_lasx
    addi.w          t0,     zero,  63
    xvxor.v         xr20,   xr0,   xr0
    la.local        t3,     decimate_table8

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
    xvpickve2gr.w   t1,     xr11,  0
    sub.w           t2,     t0,    t1
    move            t4,     a0
    addi.d          t0,     zero,  2
    slli.d          t2,     t2,    1
    move            a0,     zero
.LOOP_SCORE_64:
    blt             t2,     zero,  .END_SCORE_64
    ldx.h           t5,     t4,    t2
    addi.d          t6,     t5,    1
    bltu            t0,     t6,    .RET_SCORE_64_1
    addi.d          t2,     t2,    -2
    move            t5,     zero
.WHILE_SCORE_64:
    blt             t2,     zero,  .END_WHILE_64
    ldx.h           t1,     t4,    t2
    bnez            t1,     .END_WHILE_64
    addi.d          t2,     t2,    -2
    addi.d          t5,     t5,    1
    b               .WHILE_SCORE_64
.END_WHILE_64:
    ldx.b           t1,     t3,    t5
    add.d           a0,     a0,    t1
    b               .LOOP_SCORE_64
.RET_SCORE_64_1:
    addi.d          a0,     zero,  9
    jirl            $r0,    $r1,   0x0
.END_SCORE_64:
endfunc
