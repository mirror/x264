/*****************************************************************************
 * pixel-a.S: LoongArch pixel metrics
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
#if !HIGH_BIT_DEPTH

const hmul_8p
.byte 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, 1, -1, 1, -1, 1, -1
.byte 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, 1, -1, 1, -1, 1, -1
endconst

const mask_ac4b
.short 0, -1, 0, -1, -1, -1, -1, -1
.short 0, -1, 0, -1, -1, -1, -1, -1
endconst

const mask_ac8
.short 0, -1, -1, -1, -1, -1, -1, -1
.short 0, -1, -1, -1, -1, -1, -1, -1
endconst


.macro LOAD_INC_8x4W n1, n2, n3, n4, n5
    vld    $vr\n1,  a0,  0
    vldx   $vr\n2,  a0,  a1
    vldx   $vr\n3,  a0,  t0
    vldx   $vr\n4,  a0,  t1
    xvpermi.d   xr18,  $xr\n1,  0x05
    xvpermi.d   xr19,  $xr\n2,  0x05
    xvpermi.d   xr20,  $xr\n3,  0x05
    xvpermi.d   xr21,  $xr\n4,  0x05
    add.d   a0,  a0,  t2
    xvdp2.h.bu.b   $xr\n1,     xr18,    $xr\n5
    xvdp2.h.bu.b   $xr\n2,     xr19,    $xr\n5
    xvdp2.h.bu.b   $xr\n3,     xr20,    $xr\n5
    xvdp2.h.bu.b   $xr\n4,     xr21,    $xr\n5
.endm

.macro SUMSUB_BADC a, b, c, d
    xvadd.h  \a,  \a,  \b
    xvadd.h  \c,  \c,  \d
    xvadd.h  \b,  \b,  \b
    xvadd.h  \d,  \d,  \d
    xvsub.h  \b,  \b,  \a
    xvsub.h  \d,  \d,  \c
.endm

.macro HADAMARD4_V a, b, c, d
    SUMSUB_BADC  \a,  \b,  \c,  \d
    SUMSUB_BADC  \a,  \c,  \b,  \d
.endm

.macro HADAMARD_1 a, b, tmp
    xmov \tmp, \a
    xvpackod.h  \a, \b, \a
    xvpackev.h  \b, \b, \tmp
    xvadd.h     \tmp, \a, \b
    xvsub.h     \b, \b,  \a
    xmov        \a, \tmp
.endm

.macro HADAMARD_2 a, b, c
    xvpickod.w  \c,  \b,  \a
    xvpickev.w  \a,  \b,  \a
    xvadda.h    \a,  \a,  xr17
    xvadda.h    \c,  \c,  xr17
    xvmax.h     \a,  \a,  \c
.endm

.macro  HADAMARD_AC_WXH_LASX  w, h
function pixel_hadamard_ac_\w\()x\h\()_lasx
    add.d       t0,     a1,     a1
    add.d       t1,     a1,     t0
    add.d       t2,     t1,     a1
    xvxor.v     xr17,   xr17,  xr17
    move        t4,     ra
    bl hadamard_ac_16x8_lasx
.if \h == 16
    xmov    xr11,   xr9
    xmov    xr10,   xr8
    bl hadamard_ac_16x8_lasx
    xvadd.h   xr9,   xr9,   xr11
    xvadd.h   xr8,   xr8,   xr10
.endif
    move        ra,     t4
    xvhaddw.wu.hu   xr8,    xr8,    xr8
    xvhaddw.du.wu   xr8,    xr8,    xr8
    xvhaddw.qu.du   xr8,    xr8,    xr8
    xvpickve2gr.wu  t0,     xr8,    0
    xvpickve2gr.wu  t1,     xr8,    4
    add.d     t0,   t0,     t1
    xvhaddw.wu.hu   xr9,    xr9,    xr9
    xvhaddw.du.wu   xr9,    xr9,    xr9
    xvhaddw.qu.du   xr9,    xr9,    xr9
    xvpickve2gr.wu  t1,     xr9,    0
    xvpickve2gr.wu  t2,     xr9,    4
    add.d     t1,   t1,     t2
    srli.d      t0,     t0,    2
    srli.d      t1,     t1,    1
    slli.d      t0,     t0,    32
    add.d       a0,     t0,    t1
endfunc
.endm

function hadamard_ac_16x8_lasx, export=0
/* Load intermediate variable */
    la.local    t3,     hmul_8p
    xvld        xr8,    t3,     0
    LOAD_INC_8x4W  0, 1, 2, 3, 8
    HADAMARD4_V    xr0, xr1, xr2, xr3
    LOAD_INC_8x4W  4, 5, 6, 7, 8
    HADAMARD4_V    xr4, xr5, xr6, xr7
    HADAMARD_1     xr0, xr1, xr8
    HADAMARD_1     xr2, xr3, xr8
    xmov   xr18, xr1
    HADAMARD_1     xr4, xr5, xr8
    HADAMARD_1     xr6, xr7, xr8
    xmov   xr19,   xr2
    xmov   xr20,   xr3
    xvadda.h  xr1,  xr0,  xr4
    xvsub.h   xr21, xr4,  xr0
    xvadd.h   xr0,  xr4,  xr0
    la.local    t3,     mask_ac4b
    xvld        xr8,    t3,     0
    xvand.v     xr1,    xr1,    xr8
    xvadda.h    xr1,    xr1,    xr5
    xvadda.h    xr1,    xr1,    xr18
    xvadda.h    xr1,    xr1,    xr19
    xvadda.h    xr1,    xr1,    xr20
    xvadda.h    xr1,    xr1,    xr6
    xvadda.h    xr9,    xr1,    xr7

    xvadd.h     xr3,    xr7,    xr20
    xvsub.h     xr7,    xr7,    xr20
    xvadd.h     xr2,    xr6,    xr19
    xvsub.h     xr6,    xr6,    xr19
    xvadd.h     xr1,    xr5,    xr18
    xvsub.h     xr5,    xr5,    xr18

    HADAMARD_2  xr3,    xr7,    xr18
    HADAMARD_2  xr2,    xr6,    xr19
    HADAMARD_2  xr1,    xr5,    xr20

    xvpickod.w  xr5,    xr21,   xr0
    xvpickev.w  xr0,    xr21,   xr0
    xmov        xr4,    xr5
    xvadd.h     xr5,    xr0,    xr4
    xvsub.h     xr4,    xr4,    xr0

    xvadd.h     xr2,    xr2,    xr3
    xvadd.h     xr2,    xr2,    xr1
    xvadd.h     xr2,    xr2,    xr2

    la.local    t3,     mask_ac8
    xvld        xr8,    t3,     0
    xvand.v     xr0,    xr5,    xr8

    xvadda.h    xr2,    xr2,    xr4
    xvadda.h    xr8,    xr2,    xr0
endfunc

HADAMARD_AC_WXH_LASX 16, 8
HADAMARD_AC_WXH_LASX 16, 16

/* uint64_t hadamard_ac_8x8_lasx(uint8_t *p_pix,
 *                               int32_t i_stride)
 */
function hadamard_ac_8x8_lasx
/* Load intermediate variable */
    slli.d          t0,    a1,   1
    add.d           t1,    a1,   t0
    slli.d          t2,    a1,   2

    LSX_LOADX_4     a0,    a1,   t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d           a0,    a0,   t2
    LSX_LOADX_4     a0,    a1,   t0,  t1,  vr4,  vr5,  vr6,  vr7

    vilvl.d         vr8,   vr1,  vr0
    vilvl.d         vr9,   vr3,  vr2
    vilvl.d         vr10,  vr5,  vr4
    vilvl.d         vr11,  vr7,  vr6
    xvpermi.q       xr8,   xr10, 0x02
    xvpermi.q       xr9,   xr11, 0x02
    xvpickev.b      xr12,  xr9,  xr8
    xvpickod.b      xr13,  xr9,  xr8
    xvaddwev.h.bu   xr8,   xr12, xr13
    xvaddwod.h.bu   xr9,   xr12, xr13
    xvsubwev.h.bu   xr10,  xr12, xr13
    xvsubwod.h.bu   xr11,  xr12, xr13
    xvadd.h         xr12,  xr8,  xr9
    xvadd.h         xr13,  xr10, xr11
    xvsub.h         xr14,  xr8,  xr9
    xvsub.h         xr15,  xr10, xr11

    xvilvl.h        xr8,   xr13, xr12
    xvilvh.h        xr9,   xr13, xr12
    xvilvl.h        xr10,  xr15, xr14
    xvilvh.h        xr11,  xr15, xr14
    xvilvl.w        xr12,  xr10, xr8
    xvilvh.w        xr13,  xr10, xr8
    xvilvl.w        xr14,  xr11, xr9
    xvilvh.w        xr15,  xr11, xr9
    xvadd.h         xr8,   xr12, xr13
    xvadd.h         xr9,   xr14, xr15
    xvsub.h         xr10,  xr12, xr13
    xvsub.h         xr11,  xr14, xr15
    xvadd.h         xr12,  xr8,  xr9
    xvadd.h         xr13,  xr10, xr11
    xvsub.h         xr14,  xr8,  xr9
    xvsub.h         xr15,  xr10, xr11

    vpickve2gr.hu   t3,    vr12,  0
    vpickve2gr.hu   t4,    vr12,  4
    xvor.v          xr16,  xr12,  xr12
    xvpermi.q       xr16,  xr16,  0x31
    vpickve2gr.hu   t5,    vr16,  0
    vpickve2gr.hu   t6,    vr16,  4
    add.d           t3,    t3,    t4
    add.d           t5,    t5,    t6
    add.d           t3,    t3,    t5

    xvadda.h        xr16,  xr12,  xr13
    xvadda.h        xr18,  xr14,  xr15
    xvadd.h         xr16,  xr16,  xr18
    xvpermi.d       xr17,  xr16,  0x4e
    xvadd.h         xr18,  xr16,  xr17
    xvhaddw.wu.hu   xr18,  xr18,  xr18
    xvhaddw.du.wu   xr18,  xr18,  xr18
    xvhaddw.qu.du   xr18,  xr18,  xr18
    xvpickve2gr.wu  t4,    xr18,  0

    xvpackev.h      xr8,   xr13,  xr12
    xvpackev.h      xr9,   xr15,  xr14
    xvpackod.h      xr10,  xr13,  xr12
    xvpackod.h      xr11,  xr15,  xr14
    xvilvl.d        xr12,  xr9,   xr8
    xvilvh.d        xr13,  xr9,   xr8
    xvilvl.d        xr14,  xr11,  xr10
    xvilvh.d        xr15,  xr11,  xr10
    xvor.v          xr16,  xr12,  xr12
    xvor.v          xr17,  xr13,  xr13
    xvpermi.q       xr12,  xr14,  0x02
    xvpermi.q       xr13,  xr14,  0x12
    xvpermi.q       xr16,  xr15,  0x03
    xvpermi.q       xr17,  xr15,  0x13

    xvadd.h         xr8,   xr12,  xr13
    xvsub.h         xr9,   xr12,  xr13
    xvadd.h         xr10,  xr16,  xr17
    xvsub.h         xr11,  xr16,  xr17
    xvadd.h         xr12,  xr8,   xr10
    xvadd.h         xr13,  xr9,   xr11
    xvsub.h         xr14,  xr8,   xr10
    xvsub.h         xr15,  xr9,   xr11
    xvadda.h        xr16,  xr12,  xr13
    xvadda.h        xr17,  xr14,  xr15
    xvadd.h         xr18,  xr16,  xr17
    xvpermi.d       xr19,  xr18,  0x4e
    xvadd.d         xr19,  xr18,  xr19
    xvhaddw.wu.hu   xr19,  xr19,  xr19
    xvhaddw.du.wu   xr19,  xr19,  xr19
    xvhaddw.qu.du   xr19,  xr19,  xr19
    xvpickve2gr.wu  t5,    xr19,  0

    sub.d           t4,    t4,    t3
    sub.d           t5,    t5,    t3
    slli.d          t5,    t5,    32
    add.d           a0,    t5,    t4
endfunc

/* int x264_pixel_satd_16x16_lasx(pixel *pix1, intptr_t i_pix1,
 *                                pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_16x16_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    slli.d          t4,    a1,   2
    slli.d          t5,    a3,   2
    add.d           t6,    a1,   t2
    add.d           t7,    a3,   t3

    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t6,  vr0,  vr1,  vr2,  vr3
    add.d           a0,    a0,   t4
    LSX_LOADX_4     a0,    a1,   t2,  t6,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4     a2,    a3,   t3,  t7,  vr8,  vr9,  vr10, vr11
    add.d           a2,    a2,   t5
    LSX_LOADX_4     a2,    a3,   t3,  t7,  vr12, vr13, vr14, vr15
    xvpermi.q       xr0,   xr4,  0x02
    xvpermi.q       xr1,   xr5,  0x02
    xvpermi.q       xr2,   xr6,  0x02
    xvpermi.q       xr3,   xr7,  0x02
    xvpermi.q       xr8,   xr12, 0x02
    xvpermi.q       xr9,   xr13, 0x02
    xvpermi.q       xr10,  xr14, 0x02
    xvpermi.q       xr11,  xr15, 0x02

    // HADAMARD4
    xvsubwev.h.bu   xr4,   xr0,  xr8
    xvsubwod.h.bu   xr5,   xr0,  xr8
    xvsubwev.h.bu   xr6,   xr1,  xr9
    xvsubwod.h.bu   xr7,   xr1,  xr9
    xvsubwev.h.bu   xr8,   xr2,  xr10
    xvsubwod.h.bu   xr9,   xr2,  xr10
    xvsubwev.h.bu   xr12,  xr3,  xr11
    xvsubwod.h.bu   xr13,  xr3,  xr11
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr8,  xr9
    xvsub.h         xr5,   xr8,  xr9
    xvadd.h         xr6,   xr12, xr13
    xvsub.h         xr7,   xr12, xr13
    xvpackev.h      xr8,   xr5,  xr4
    xvpackod.h      xr9,   xr5,  xr4
    xvpackev.h      xr10,  xr7,  xr6
    xvpackod.h      xr11,  xr7,  xr6
    xvpackev.h      xr4,   xr1,  xr0
    xvpackod.h      xr5,   xr1,  xr0
    xvpackev.h      xr6,   xr3,  xr2
    xvpackod.h      xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr8,  xr9
    xvsub.h         xr5,   xr8,  xr9
    xvadd.h         xr6,   xr10, xr11
    xvsub.h         xr7,   xr10, xr11
    xvilvl.h        xr8,   xr1,  xr0
    xvilvl.h        xr9,   xr3,  xr2
    xvilvl.h        xr10,  xr5,  xr4
    xvilvl.h        xr11,  xr7,  xr6
    xvilvh.h        xr0,   xr1,  xr0
    xvilvh.h        xr1,   xr3,  xr2
    xvilvh.h        xr2,   xr5,  xr4
    xvilvh.h        xr3,   xr7,  xr6
    xvadd.h         xr4,   xr8,  xr9
    xvadd.h         xr6,   xr10, xr11
    xvsub.h         xr5,   xr8,  xr9
    xvsub.h         xr7,   xr10, xr11
    xvadd.h         xr8,   xr4,  xr6
    xvadd.h         xr9,   xr5,  xr7
    xvsub.h         xr10,  xr4,  xr6
    xvsub.h         xr11,  xr5,  xr7
    xvadd.h         xr4,   xr0,  xr1
    xvadd.h         xr6,   xr2,  xr3
    xvsub.h         xr5,   xr0,  xr1
    xvsub.h         xr7,   xr2,  xr3
    xvadd.h         xr0,   xr4,  xr6
    xvadd.h         xr1,   xr5,  xr7
    xvsub.h         xr2,   xr4,  xr6
    xvsub.h         xr3,   xr5,  xr7
    xvadda.h        xr8,   xr8,  xr9
    xvadda.h        xr9,   xr10, xr11
    xvadda.h        xr0,   xr0,  xr1
    xvadda.h        xr1,   xr2,  xr3
    xvadd.h         xr8,   xr8,  xr9
    xvadd.h         xr0,   xr0,  xr1
    xvadd.h         xr16,  xr0,  xr8

    add.d           a0,    a0,   t4
    add.d           a2,    a2,   t5
    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t6,  vr0,  vr1,  vr2,  vr3
    add.d           a0,    a0,   t4
    LSX_LOADX_4     a0,    a1,   t2,  t6,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4     a2,    a3,   t3,  t7,  vr8,  vr9,  vr10, vr11
    add.d           a2,    a2,   t5
    LSX_LOADX_4     a2,    a3,   t3,  t7,  vr12, vr13, vr14, vr15
    xvpermi.q       xr0,   xr4,  0x02
    xvpermi.q       xr1,   xr5,  0x02
    xvpermi.q       xr2,   xr6,  0x02
    xvpermi.q       xr3,   xr7,  0x02
    xvpermi.q       xr8,   xr12, 0x02
    xvpermi.q       xr9,   xr13, 0x02
    xvpermi.q       xr10,  xr14, 0x02
    xvpermi.q       xr11,  xr15, 0x02

    // HADAMARD4
    xvsubwev.h.bu   xr4,   xr0,  xr8
    xvsubwod.h.bu   xr5,   xr0,  xr8
    xvsubwev.h.bu   xr6,   xr1,  xr9
    xvsubwod.h.bu   xr7,   xr1,  xr9
    xvsubwev.h.bu   xr8,   xr2,  xr10
    xvsubwod.h.bu   xr9,   xr2,  xr10
    xvsubwev.h.bu   xr12,  xr3,  xr11
    xvsubwod.h.bu   xr13,  xr3,  xr11
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr8,  xr9
    xvsub.h         xr5,   xr8,  xr9
    xvadd.h         xr6,   xr12, xr13
    xvsub.h         xr7,   xr12, xr13
    xvpackev.h      xr8,   xr5,  xr4
    xvpackod.h      xr9,   xr5,  xr4
    xvpackev.h      xr10,  xr7,  xr6
    xvpackod.h      xr11,  xr7,  xr6
    xvpackev.h      xr4,   xr1,  xr0
    xvpackod.h      xr5,   xr1,  xr0
    xvpackev.h      xr6,   xr3,  xr2
    xvpackod.h      xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr8,  xr9
    xvsub.h         xr5,   xr8,  xr9
    xvadd.h         xr6,   xr10, xr11
    xvsub.h         xr7,   xr10, xr11
    xvilvl.h        xr8,   xr1,  xr0
    xvilvl.h        xr9,   xr3,  xr2
    xvilvl.h        xr10,  xr5,  xr4
    xvilvl.h        xr11,  xr7,  xr6
    xvilvh.h        xr0,   xr1,  xr0
    xvilvh.h        xr1,   xr3,  xr2
    xvilvh.h        xr2,   xr5,  xr4
    xvilvh.h        xr3,   xr7,  xr6
    xvadd.h         xr4,   xr8,  xr9
    xvadd.h         xr6,   xr10, xr11
    xvsub.h         xr5,   xr8,  xr9
    xvsub.h         xr7,   xr10, xr11
    xvadd.h         xr8,   xr4,  xr6
    xvadd.h         xr9,   xr5,  xr7
    xvsub.h         xr10,  xr4,  xr6
    xvsub.h         xr11,  xr5,  xr7
    xvadd.h         xr4,   xr0,  xr1
    xvadd.h         xr6,   xr2,  xr3
    xvsub.h         xr5,   xr0,  xr1
    xvsub.h         xr7,   xr2,  xr3
    xvadd.h         xr0,   xr4,  xr6
    xvadd.h         xr1,   xr5,  xr7
    xvsub.h         xr2,   xr4,  xr6
    xvsub.h         xr3,   xr5,  xr7
    xvadda.h        xr8,   xr8,  xr9
    xvadda.h        xr9,   xr10, xr11
    xvadda.h        xr0,   xr0,  xr1
    xvadda.h        xr1,   xr2,  xr3
    xvadd.h         xr8,   xr8,  xr9
    xvadd.h         xr0,   xr0,  xr1
    xvadd.h         xr0,   xr0,  xr8
    xvadd.h         xr0,   xr0,  xr16

    xvhaddw.wu.hu   xr0,   xr0,  xr0
    xvhaddw.du.wu   xr0,   xr0,  xr0
    xvhaddw.qu.du   xr0,   xr0,  xr0
    xvpickve2gr.wu  t0,    xr0,  0
    xvpickve2gr.wu  t1,    xr0,  4
    add.w           t0,    t0,   t1
    srli.d          a0,    t0,   1
endfunc

/* int x264_pixel_satd_16x8_lasx(pixel *pix1, intptr_t i_pix1,
 *                               pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_16x8_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    slli.d          t4,    t2,   1
    slli.d          t5,    t3,   1
    add.d           t6,    a1,   t2
    add.d           t7,    a3,   t3

    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t6,  vr0,  vr1,  vr2,  vr3
    add.d           a0,    a0,   t4
    LSX_LOADX_4     a0,    a1,   t2,  t6,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4     a2,    a3,   t3,  t7,  vr8,  vr9,  vr10, vr11
    add.d           a2,    a2,   t5
    LSX_LOADX_4     a2,    a3,   t3,  t7,  vr12, vr13, vr14, vr15
    xvpermi.q       xr0,   xr4,  0x02
    xvpermi.q       xr1,   xr5,  0x02
    xvpermi.q       xr2,   xr6,  0x02
    xvpermi.q       xr3,   xr7,  0x02
    xvpermi.q       xr8,   xr12, 0x02
    xvpermi.q       xr9,   xr13, 0x02
    xvpermi.q       xr10,  xr14, 0x02
    xvpermi.q       xr11,  xr15, 0x02

    // HADAMARD4
    xvsubwev.h.bu   xr4,   xr0,  xr8
    xvsubwod.h.bu   xr5,   xr0,  xr8
    xvsubwev.h.bu   xr6,   xr1,  xr9
    xvsubwod.h.bu   xr7,   xr1,  xr9
    xvsubwev.h.bu   xr8,   xr2,  xr10
    xvsubwod.h.bu   xr9,   xr2,  xr10
    xvsubwev.h.bu   xr12,  xr3,  xr11
    xvsubwod.h.bu   xr13,  xr3,  xr11
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr8,  xr9
    xvsub.h         xr5,   xr8,  xr9
    xvadd.h         xr6,   xr12, xr13
    xvsub.h         xr7,   xr12, xr13
    xvpackev.h      xr8,   xr5,  xr4
    xvpackod.h      xr9,   xr5,  xr4
    xvpackev.h      xr10,  xr7,  xr6
    xvpackod.h      xr11,  xr7,  xr6
    xvpackev.h      xr4,   xr1,  xr0
    xvpackod.h      xr5,   xr1,  xr0
    xvpackev.h      xr6,   xr3,  xr2
    xvpackod.h      xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr8,  xr9
    xvsub.h         xr5,   xr8,  xr9
    xvadd.h         xr6,   xr10, xr11
    xvsub.h         xr7,   xr10, xr11
    xvilvl.h        xr8,   xr1,  xr0
    xvilvl.h        xr9,   xr3,  xr2
    xvilvl.h        xr10,  xr5,  xr4
    xvilvl.h        xr11,  xr7,  xr6
    xvilvh.h        xr0,   xr1,  xr0
    xvilvh.h        xr1,   xr3,  xr2
    xvilvh.h        xr2,   xr5,  xr4
    xvilvh.h        xr3,   xr7,  xr6
    xvadd.h         xr4,   xr8,  xr9
    xvadd.h         xr6,   xr10, xr11
    xvsub.h         xr5,   xr8,  xr9
    xvsub.h         xr7,   xr10, xr11
    xvadd.h         xr8,   xr4,  xr6
    xvadd.h         xr9,   xr5,  xr7
    xvsub.h         xr10,  xr4,  xr6
    xvsub.h         xr11,  xr5,  xr7
    xvadd.h         xr4,   xr0,  xr1
    xvadd.h         xr6,   xr2,  xr3
    xvsub.h         xr5,   xr0,  xr1
    xvsub.h         xr7,   xr2,  xr3
    xvadd.h         xr0,   xr4,  xr6
    xvadd.h         xr1,   xr5,  xr7
    xvsub.h         xr2,   xr4,  xr6
    xvsub.h         xr3,   xr5,  xr7
    xvadda.h        xr8,   xr8,  xr9
    xvadda.h        xr9,   xr10, xr11
    xvadda.h        xr0,   xr0,  xr1
    xvadda.h        xr1,   xr2,  xr3
    xvadd.h         xr8,   xr8,  xr9
    xvadd.h         xr0,   xr0,  xr1
    xvadd.h         xr0,   xr0,  xr8

    xvhaddw.wu.hu   xr0,   xr0,  xr0
    xvhaddw.du.wu   xr0,   xr0,  xr0
    xvhaddw.qu.du   xr0,   xr0,  xr0
    xvpickve2gr.wu  t0,    xr0,  0
    xvpickve2gr.wu  t1,    xr0,  4
    add.w           t0,    t0,   t1
    srli.d          a0,    t0,   1
endfunc

/* int x264_pixel_satd_8x16_lasx(pixel *pix1, intptr_t i_pix1,
 *                               pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_8x16_lasx
    slli.d          t2,    a1,   1
    add.d           t3,    a1,   t2
    slli.d          t4,    a1,   2
    slli.d          t5,    a3,   1
    add.d           t6,    a3,   t5
    slli.d          t7,    a3,   2

    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t3,  vr0,  vr1,  vr2,  vr3
    add.d           a0,    a0,   t4
    LSX_LOADX_4     a0,    a1,   t2,  t3,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4     a2,    a3,   t5,  t6,  vr8,  vr9,  vr10, vr11
    add.d           a2,    a2,   t7
    LSX_LOADX_4     a2,    a3,   t5,  t6,  vr12, vr13, vr14, vr15
    vilvl.d         vr0,   vr1,  vr0
    vilvl.d         vr1,   vr3,  vr2
    vilvl.d         vr2,   vr5,  vr4
    vilvl.d         vr3,   vr7,  vr6
    xvpermi.q       xr0,   xr2,  0x02
    xvpermi.q       xr1,   xr3,  0x02
    vilvl.d         vr2,   vr9,  vr8
    vilvl.d         vr3,   vr11, vr10
    vilvl.d         vr4,   vr13, vr12
    vilvl.d         vr5,   vr15, vr14
    xvpermi.q       xr2,   xr4,  0x02
    xvpermi.q       xr3,   xr5,  0x02

    // HADAMARD4
    xvsubwev.h.bu   xr4,   xr0,  xr2
    xvsubwod.h.bu   xr5,   xr0,  xr2
    xvsubwev.h.bu   xr6,   xr1,  xr3
    xvsubwod.h.bu   xr7,   xr1,  xr3
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvpackev.h      xr4,   xr1,  xr0
    xvpackod.h      xr5,   xr1,  xr0
    xvpackev.h      xr6,   xr3,  xr2
    xvpackod.h      xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvilvl.h        xr4,   xr1,  xr0
    xvilvh.h        xr5,   xr1,  xr0
    xvilvl.h        xr6,   xr3,  xr2
    xvilvh.h        xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr1,   xr4,  xr5
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr0,  xr2
    xvadd.h         xr5,   xr1,  xr3
    xvsub.h         xr6,   xr0,  xr2
    xvsub.h         xr7,   xr1,  xr3
    xvadda.h        xr0,   xr4,  xr5
    xvadda.h        xr1,   xr6,  xr7
    xvadd.h         xr16,  xr0,  xr1
    add.d           a0,    a0,   t4
    add.d           a2,    a2,   t7

    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t3,  vr0,  vr1,  vr2,  vr3
    add.d           a0,    a0,   t4
    LSX_LOADX_4     a0,    a1,   t2,  t3,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4     a2,    a3,   t5,  t6,  vr8,  vr9,  vr10, vr11
    add.d           a2,    a2,   t7
    LSX_LOADX_4     a2,    a3,   t5,  t6,  vr12, vr13, vr14, vr15
    vilvl.d         vr0,   vr1,  vr0
    vilvl.d         vr1,   vr3,  vr2
    vilvl.d         vr2,   vr5,  vr4
    vilvl.d         vr3,   vr7,  vr6
    xvpermi.q       xr0,   xr2,  0x02
    xvpermi.q       xr1,   xr3,  0x02
    vilvl.d         vr2,   vr9,  vr8
    vilvl.d         vr3,   vr11, vr10
    vilvl.d         vr4,   vr13, vr12
    vilvl.d         vr5,   vr15, vr14
    xvpermi.q       xr2,   xr4,  0x02
    xvpermi.q       xr3,   xr5,  0x02

    // HADAMARD4
    xvsubwev.h.bu   xr4,   xr0,  xr2
    xvsubwod.h.bu   xr5,   xr0,  xr2
    xvsubwev.h.bu   xr6,   xr1,  xr3
    xvsubwod.h.bu   xr7,   xr1,  xr3
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvpackev.h      xr4,   xr1,  xr0
    xvpackod.h      xr5,   xr1,  xr0
    xvpackev.h      xr6,   xr3,  xr2
    xvpackod.h      xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvilvl.h        xr4,   xr1,  xr0
    xvilvh.h        xr5,   xr1,  xr0
    xvilvl.h        xr6,   xr3,  xr2
    xvilvh.h        xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr1,   xr4,  xr5
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr0,  xr2
    xvadd.h         xr5,   xr1,  xr3
    xvsub.h         xr6,   xr0,  xr2
    xvsub.h         xr7,   xr1,  xr3
    xvadda.h        xr0,   xr4,  xr5
    xvadda.h        xr1,   xr6,  xr7
    xvadd.h         xr0,   xr0,  xr1
    xvadd.h         xr0,   xr0,  xr16
    xvhaddw.wu.hu   xr0,   xr0,  xr0
    xvhaddw.du.wu   xr0,   xr0,  xr0
    xvhaddw.qu.du   xr0,   xr0,  xr0
    xvpickve2gr.wu  t0,    xr0,  0
    xvpickve2gr.wu  t1,    xr0,  4
    add.w           t0,    t0,   t1
    srli.d          a0,    t0,   1
endfunc

/* int x264_pixel_satd_8x8_lasx(pixel *pix1, intptr_t i_pix1,
 *                              pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_8x8_lasx
    slli.d          t2,    a1,   1
    slli.d          t5,    a3,   1
    add.d           t3,    a1,   t2
    add.d           t6,    a3,   t5
    slli.d          t4,    t2,   1
    slli.d          t7,    t5,   1
    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t3,  vr0,  vr1,  vr2,  vr3
    add.d           a0,    a0,   t4
    LSX_LOADX_4     a0,    a1,   t2,  t3,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4     a2,    a3,   t5,  t6,  vr8,  vr9,  vr10, vr11
    add.d           a2,    a2,   t7
    LSX_LOADX_4     a2,    a3,   t5,  t6,  vr12, vr13, vr14, vr15

    vilvl.d         vr0,   vr1,  vr0
    vilvl.d         vr1,   vr3,  vr2
    vilvl.d         vr2,   vr5,  vr4
    vilvl.d         vr3,   vr7,  vr6
    xvpermi.q       xr0,   xr2,  0x02
    xvpermi.q       xr1,   xr3,  0x02
    vilvl.d         vr2,   vr9,  vr8
    vilvl.d         vr3,   vr11, vr10
    vilvl.d         vr4,   vr13, vr12
    vilvl.d         vr5,   vr15, vr14
    xvpermi.q       xr2,   xr4,  0x02
    xvpermi.q       xr3,   xr5,  0x02

    // HADAMARD4
    xvsubwev.h.bu   xr4,   xr0,  xr2
    xvsubwod.h.bu   xr5,   xr0,  xr2
    xvsubwev.h.bu   xr6,   xr1,  xr3
    xvsubwod.h.bu   xr7,   xr1,  xr3
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvpackev.h      xr4,   xr1,  xr0
    xvpackod.h      xr5,   xr1,  xr0
    xvpackev.h      xr6,   xr3,  xr2
    xvpackod.h      xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvsub.h         xr1,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr3,   xr6,  xr7
    xvilvl.h        xr4,   xr1,  xr0
    xvilvh.h        xr5,   xr1,  xr0
    xvilvl.h        xr6,   xr3,  xr2
    xvilvh.h        xr7,   xr3,  xr2
    xvadd.h         xr0,   xr4,  xr5
    xvadd.h         xr2,   xr6,  xr7
    xvsub.h         xr1,   xr4,  xr5
    xvsub.h         xr3,   xr6,  xr7
    xvadd.h         xr4,   xr0,  xr2
    xvadd.h         xr5,   xr1,  xr3
    xvsub.h         xr6,   xr0,  xr2
    xvsub.h         xr7,   xr1,  xr3
    xvadda.h        xr0,   xr4,  xr5
    xvadda.h        xr1,   xr6,  xr7
    xvadd.h         xr0,   xr0,  xr1
    xvhaddw.wu.hu   xr0,   xr0,  xr0
    xvhaddw.du.wu   xr0,   xr0,  xr0
    xvhaddw.qu.du   xr0,   xr0,  xr0
    xvpickve2gr.wu  t0,    xr0,  0
    xvpickve2gr.wu  t1,    xr0,  4
    add.w           t0,    t0,   t1
    srli.d          a0,    t0,   1
endfunc

/* int x264_pixel_satd_8x4_lasx(pixel *pix1, intptr_t i_pix1,
 *                              pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_8x4_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    add.d           t4,    a1,   t2
    add.d           t5,    a3,   t3

    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr9,   xr11, xr13
    xvsub.h         xr10,  xr11, xr13
    xvpackev.d      xr11,  xr10, xr9
    xvpackod.d      xr12,  xr10, xr9
    xvadda.h        xr11,  xr11, xr12
    xvhaddw.wu.hu   xr11,  xr11, xr11
    xvhaddw.du.wu   xr11,  xr11, xr11
    xvhaddw.qu.du   xr11,  xr11, xr11
    xvpickve2gr.wu  t4,    xr11, 0
    xvpickve2gr.wu  t5,    xr11, 4
    add.d           t4,    t4,   t5
    srli.d          a0,    t4,   1
endfunc

/* int x264_pixel_satd_4x16_lasx(pixel *pix1, intptr_t i_pix1,
 *                               pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_4x16_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    add.d           t4,    a1,   t2
    add.d           t5,    a3,   t3
    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.w         vr1,   vr2,  vr1
    vilvl.w         vr3,   vr4,  vr3
    vilvl.d         vr9,   vr3,  vr1
    vilvl.w         vr5,   vr6,  vr5
    vilvl.w         vr7,   vr8,  vr7
    vilvl.d         vr10,  vr7,  vr5

    slli.d          t0,    a1,   2
    slli.d          t1,    a3,   2
    // Load data from pix1 and pix2
    add.d           a0,    a0,   t0
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    add.d           a2,    a2,   t1
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.w         vr1,   vr2,  vr1
    vilvl.w         vr3,   vr4,  vr3
    vilvl.d         vr1,   vr3,  vr1
    vilvl.w         vr5,   vr6,  vr5
    vilvl.w         vr7,   vr8,  vr7
    vilvl.d         vr5,   vr7,  vr5
    xvpermi.q       xr1,   xr9,  0x20
    xvpermi.q       xr5,   xr10, 0x20

    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* b0 + b1 */
    xvsub.h         xr12,  xr9,  xr10  /* b0 - b1 */
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadda.h        xr9,   xr9,  xr10
    xvhaddw.wu.hu   xr9,   xr9,  xr9
    xvhaddw.du.wu   xr9,   xr9,  xr9
    xvhaddw.qu.du   xr9,   xr9,  xr9
    xvpickve2gr.wu  t6,    xr9,  0
    xvpickve2gr.wu  t7,    xr9,  4
    add.d           t7,    t6,   t7

    // Load data from pix1 and pix2
    add.d           a0,    a0,   t0
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    add.d           a2,    a2,   t1
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.w         vr1,   vr2,  vr1
    vilvl.w         vr3,   vr4,  vr3
    vilvl.d         vr9,   vr3,  vr1
    vilvl.w         vr5,   vr6,  vr5
    vilvl.w         vr7,   vr8,  vr7
    vilvl.d         vr10,  vr7,  vr5

    // Load data from pix1 and pix2
    add.d           a0,    a0,   t0
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    add.d           a2,    a2,   t1
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.w         vr1,   vr2,  vr1
    vilvl.w         vr3,   vr4,  vr3
    vilvl.d         vr1,   vr3,  vr1
    vilvl.w         vr5,   vr6,  vr5
    vilvl.w         vr7,   vr8,  vr7
    vilvl.d         vr5,   vr7,  vr5
    xvpermi.q       xr1,   xr9,  0x20
    xvpermi.q       xr5,   xr10, 0x20

    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* b0 + b1 */
    xvsub.h         xr12,  xr9,  xr10  /* b0 - b1 */
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadda.h        xr9,   xr9,  xr10
    xvhaddw.wu.hu   xr9,   xr9,  xr9
    xvhaddw.du.wu   xr9,   xr9,  xr9
    xvhaddw.qu.du   xr9,   xr9,  xr9
    xvpickve2gr.wu  t6,    xr9,  0
    xvpickve2gr.wu  t5,    xr9,  4
    add.d           t6,    t5,   t6
    add.d           t7,    t6,   t7
    srli.d          a0,    t7,   1
endfunc

/* int x264_pixel_satd_4x8_lasx(pixel *pix1, intptr_t i_pix1,
 *                              pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_4x8_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    add.d           t4,    a1,   t2
    add.d           t5,    a3,   t3
    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.w         vr1,   vr2,  vr1
    vilvl.w         vr3,   vr4,  vr3
    vilvl.d         vr9,   vr3,  vr1
    vilvl.w         vr5,   vr6,  vr5
    vilvl.w         vr7,   vr8,  vr7
    vilvl.d         vr10,  vr7,  vr5

    slli.d          t0,    a1,   2
    slli.d          t1,    a3,   2
    add.d           a0,    a0,   t0
    add.d           a2,    a2,   t1
    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.w         vr1,   vr2,  vr1
    vilvl.w         vr3,   vr4,  vr3
    vilvl.d         vr1,   vr3,  vr1
    vilvl.w         vr5,   vr6,  vr5
    vilvl.w         vr7,   vr8,  vr7
    vilvl.d         vr5,   vr7,  vr5
    xvpermi.q       xr1,   xr9,  0x20
    xvpermi.q       xr5,   xr10, 0x20

    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* b0 + b1 */
    xvsub.h         xr12,  xr9,  xr10  /* b0 - b1 */
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadda.h        xr9,   xr9,  xr10
    xvhaddw.wu.hu   xr9,   xr9,  xr9
    xvhaddw.du.wu   xr9,   xr9,  xr9
    xvhaddw.qu.du   xr9,   xr9,  xr9
    xvpickve2gr.wu  t6,    xr9,  0
    xvpickve2gr.wu  t7,    xr9,  4
    add.d           t6,    t6,   t7
    srli.d          a0,    t6,   1
endfunc

/* int x264_pixel_satd_wxh4x4_lasx(pixel *pix1, intptr_t i_pix1,
 *                                 pixel *pix2, intptr_t i_pix2)
 */
function pixel_satd_4x4_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    add.d           t4,    a1,   t2
    add.d           t5,    a3,   t3

    // Load data from pix1 and pix2
    LSX_LOADX_4     a0,    a1,   t2,  t4,  vr1, vr2, vr3, vr4
    LSX_LOADX_4     a2,    a3,   t3,  t5,  vr5, vr6, vr7, vr8
    vilvl.w         vr1,   vr2,  vr1
    vilvl.w         vr3,   vr4,  vr3
    vilvl.d         vr1,   vr3,  vr1
    vilvl.w         vr5,   vr6,  vr5
    vilvl.w         vr7,   vr8,  vr7
    vilvl.d         vr5,   vr7,  vr5

    vsubwev.h.bu    vr9,   vr1,  vr5
    vsubwod.h.bu    vr10,  vr1,  vr5
    vadd.h          vr11,  vr9,  vr10  /* a0 + a1 */
    vsub.h          vr12,  vr9,  vr10  /* a0 - a1 */
    vpackev.h       vr9,   vr12, vr11
    vpackod.h       vr10,  vr12, vr11
    vadd.h          vr11,  vr9,  vr10  /* b0 + b1 */
    vsub.h          vr12,  vr9,  vr10  /* b0 - b1 */
    vpackev.w       vr9,   vr12, vr11
    vpackod.w       vr10,  vr12, vr11
    vadd.h          vr11,  vr9,  vr10  /* HADAMARD4 */
    vsub.h          vr12,  vr9,  vr10
    vpackev.d       vr9,   vr12, vr11
    vpackod.d       vr10,  vr12, vr11
    vadd.h          vr11,  vr9,  vr10
    vsub.h          vr12,  vr9,  vr10
    vpackev.d       vr9,   vr12, vr11
    vpackod.d       vr10,  vr12, vr11
    vadda.h         vr9,   vr9,  vr10
    vhaddw.wu.hu    vr9,   vr9,  vr9
    vhaddw.du.wu    vr9,   vr9,  vr9
    vhaddw.qu.du    vr9,   vr9,  vr9
    vpickve2gr.wu   t5,    vr9,  0
    srli.d          a0,    t5,   1
endfunc

/*
 * int pixel_ssd_16x16_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                          const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_16x16_lasx
    slli.d         t0,     a1,    1
    add.d          t1,     a1,    t0
    add.d          t2,     a1,    t1
    slli.d         t3,     a3,    1
    add.d          t4,     a3,    t3
    add.d          t5,     a3,    t4

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr2,    xr2
    vext2xv.hu.bu  xr3,    xr3
    vext2xv.hu.bu  xr4,    xr4
    vext2xv.hu.bu  xr5,    xr5
    vext2xv.hu.bu  xr6,    xr6
    vext2xv.hu.bu  xr7,    xr7
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9
    vext2xv.hu.bu  xr10,   xr10
    vext2xv.hu.bu  xr11,   xr11
    vext2xv.hu.bu  xr12,   xr12
    vext2xv.hu.bu  xr13,   xr13
    vext2xv.hu.bu  xr14,   xr14
    vext2xv.hu.bu  xr15,   xr15

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvsub.h        xr2,    xr2,   xr10
    xvsub.h        xr3,    xr3,   xr11
    xvsub.h        xr4,    xr4,   xr12
    xvsub.h        xr5,    xr5,   xr13
    xvsub.h        xr6,    xr6,   xr14
    xvsub.h        xr7,    xr7,   xr15
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvmul.h        xr2,    xr2,   xr2
    xvmul.h        xr3,    xr3,   xr3
    xvmul.h        xr4,    xr4,   xr4
    xvmul.h        xr5,    xr5,   xr5
    xvmul.h        xr6,    xr6,   xr6
    xvmul.h        xr7,    xr7,   xr7
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr2,    xr2,   xr2
    xvhaddw.wu.hu  xr3,    xr3,   xr3
    xvhaddw.wu.hu  xr4,    xr4,   xr4
    xvhaddw.wu.hu  xr5,    xr5,   xr5
    xvhaddw.wu.hu  xr6,    xr6,   xr6
    xvhaddw.wu.hu  xr7,    xr7,   xr7
    xvadd.w        xr16,   xr0,   xr1
    xvadd.w        xr17,   xr2,   xr3
    xvadd.w        xr18,   xr4,   xr5
    xvadd.w        xr19,   xr6,   xr7
    xvadd.w        xr16,   xr16,  xr17
    xvadd.w        xr18,   xr18,  xr19
    xvadd.w        xr16,   xr16,  xr18

    // Load data from pix1 and pix2
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr2,    xr2
    vext2xv.hu.bu  xr3,    xr3
    vext2xv.hu.bu  xr4,    xr4
    vext2xv.hu.bu  xr5,    xr5
    vext2xv.hu.bu  xr6,    xr6
    vext2xv.hu.bu  xr7,    xr7
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9
    vext2xv.hu.bu  xr10,   xr10
    vext2xv.hu.bu  xr11,   xr11
    vext2xv.hu.bu  xr12,   xr12
    vext2xv.hu.bu  xr13,   xr13
    vext2xv.hu.bu  xr14,   xr14
    vext2xv.hu.bu  xr15,   xr15

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvsub.h        xr2,    xr2,   xr10
    xvsub.h        xr3,    xr3,   xr11
    xvsub.h        xr4,    xr4,   xr12
    xvsub.h        xr5,    xr5,   xr13
    xvsub.h        xr6,    xr6,   xr14
    xvsub.h        xr7,    xr7,   xr15
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvmul.h        xr2,    xr2,   xr2
    xvmul.h        xr3,    xr3,   xr3
    xvmul.h        xr4,    xr4,   xr4
    xvmul.h        xr5,    xr5,   xr5
    xvmul.h        xr6,    xr6,   xr6
    xvmul.h        xr7,    xr7,   xr7
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr2,    xr2,   xr2
    xvhaddw.wu.hu  xr3,    xr3,   xr3
    xvhaddw.wu.hu  xr4,    xr4,   xr4
    xvhaddw.wu.hu  xr5,    xr5,   xr5
    xvhaddw.wu.hu  xr6,    xr6,   xr6
    xvhaddw.wu.hu  xr7,    xr7,   xr7
    xvadd.w        xr0,    xr0,   xr1
    xvadd.w        xr2,    xr2,   xr3
    xvadd.w        xr4,    xr4,   xr5
    xvadd.w        xr6,    xr6,   xr7
    xvadd.w        xr0,    xr0,   xr2
    xvadd.w        xr4,    xr4,   xr6
    xvadd.w        xr0,    xr0,   xr4
    xvadd.w        xr0,    xr0,   xr16

    // Calculate the sum
    xvhaddw.d.w    xr0,    xr0,   xr0
    xvhaddw.q.d    xr0,    xr0,   xr0
    xvpickve2gr.w  t2,     xr0,   0
    xvpickve2gr.w  t3,     xr0,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_ssd_16x8_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                         const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_16x8_lasx
    slli.d         t0,     a1,    1
    add.d          t1,     a1,    t0
    add.d          t2,     a1,    t1
    slli.d         t3,     a3,    1
    add.d          t4,     a3,    t3
    add.d          t5,     a3,    t4

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr2,    xr2
    vext2xv.hu.bu  xr3,    xr3
    vext2xv.hu.bu  xr4,    xr4
    vext2xv.hu.bu  xr5,    xr5
    vext2xv.hu.bu  xr6,    xr6
    vext2xv.hu.bu  xr7,    xr7
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9
    vext2xv.hu.bu  xr10,   xr10
    vext2xv.hu.bu  xr11,   xr11
    vext2xv.hu.bu  xr12,   xr12
    vext2xv.hu.bu  xr13,   xr13
    vext2xv.hu.bu  xr14,   xr14
    vext2xv.hu.bu  xr15,   xr15

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvsub.h        xr2,    xr2,   xr10
    xvsub.h        xr3,    xr3,   xr11
    xvsub.h        xr4,    xr4,   xr12
    xvsub.h        xr5,    xr5,   xr13
    xvsub.h        xr6,    xr6,   xr14
    xvsub.h        xr7,    xr7,   xr15
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvmul.h        xr2,    xr2,   xr2
    xvmul.h        xr3,    xr3,   xr3
    xvmul.h        xr4,    xr4,   xr4
    xvmul.h        xr5,    xr5,   xr5
    xvmul.h        xr6,    xr6,   xr6
    xvmul.h        xr7,    xr7,   xr7
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr2,    xr2,   xr2
    xvhaddw.wu.hu  xr3,    xr3,   xr3
    xvhaddw.wu.hu  xr4,    xr4,   xr4
    xvhaddw.wu.hu  xr5,    xr5,   xr5
    xvhaddw.wu.hu  xr6,    xr6,   xr6
    xvhaddw.wu.hu  xr7,    xr7,   xr7
    xvadd.w        xr0,    xr0,   xr1
    xvadd.w        xr2,    xr2,   xr3
    xvadd.w        xr4,    xr4,   xr5
    xvadd.w        xr6,    xr6,   xr7
    xvadd.w        xr0,    xr0,   xr2
    xvadd.w        xr4,    xr4,   xr6
    xvadd.w        xr0,    xr0,   xr4

    // Calculate the sum
    xvhaddw.d.w    xr0,    xr0,   xr0
    xvhaddw.q.d    xr0,    xr0,   xr0
    xvpickve2gr.w  t2,     xr0,   0
    xvpickve2gr.w  t3,     xr0,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_ssd_8x16_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                         const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_8x16_lasx
    slli.d         t0,     a1,    1
    add.d          t1,     a1,    t0
    add.d          t2,     a1,    t1
    slli.d         t3,     a3,    1
    add.d          t4,     a3,    t3
    add.d          t5,     a3,    t4

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15

    vilvl.d        vr0,    vr4,   vr0
    vilvl.d        vr1,    vr5,   vr1
    vilvl.d        vr2,    vr6,   vr2
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr8,    vr12,  vr8
    vilvl.d        vr9,    vr13,  vr9
    vilvl.d        vr10,   vr14,  vr10
    vilvl.d        vr11,   vr15,  vr11
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr2,    xr2
    vext2xv.hu.bu  xr3,    xr3
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9
    vext2xv.hu.bu  xr10,   xr10
    vext2xv.hu.bu  xr11,   xr11

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvsub.h        xr2,    xr2,   xr10
    xvsub.h        xr3,    xr3,   xr11
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvmul.h        xr2,    xr2,   xr2
    xvmul.h        xr3,    xr3,   xr3
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr2,    xr2,   xr2
    xvhaddw.wu.hu  xr3,    xr3,   xr3
    xvadd.w        xr0,    xr0,   xr1
    xvadd.w        xr2,    xr2,   xr3
    xvadd.w        xr16,   xr0,   xr2

    // Load data from pix1 and pix2
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15

    vilvl.d        vr0,    vr4,   vr0
    vilvl.d        vr1,    vr5,   vr1
    vilvl.d        vr2,    vr6,   vr2
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr8,    vr12,  vr8
    vilvl.d        vr9,    vr13,  vr9
    vilvl.d        vr10,   vr14,  vr10
    vilvl.d        vr11,   vr15,  vr11
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr2,    xr2
    vext2xv.hu.bu  xr3,    xr3
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9
    vext2xv.hu.bu  xr10,   xr10
    vext2xv.hu.bu  xr11,   xr11

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvsub.h        xr2,    xr2,   xr10
    xvsub.h        xr3,    xr3,   xr11
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvmul.h        xr2,    xr2,   xr2
    xvmul.h        xr3,    xr3,   xr3
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr2,    xr2,   xr2
    xvhaddw.wu.hu  xr3,    xr3,   xr3
    xvadd.w        xr0,    xr0,   xr1
    xvadd.w        xr2,    xr2,   xr3
    xvadd.w        xr0,    xr0,   xr2
    xvadd.w        xr0,    xr0,   xr16

    // Calculate the sum
    xvhaddw.d.w    xr0,    xr0,   xr0
    xvhaddw.q.d    xr0,    xr0,   xr0
    xvpickve2gr.w  t2,     xr0,   0
    xvpickve2gr.w  t3,     xr0,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_ssd_8x8_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                        const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_8x8_lasx
    slli.d         t0,     a1,    1
    add.d          t1,     a1,    t0
    add.d          t2,     a1,    t1
    slli.d         t3,     a3,    1
    add.d          t4,     a3,    t3
    add.d          t5,     a3,    t4

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15

    vilvl.d        vr0,    vr4,   vr0
    vilvl.d        vr1,    vr5,   vr1
    vilvl.d        vr2,    vr6,   vr2
    vilvl.d        vr3,    vr7,   vr3
    vilvl.d        vr8,    vr12,  vr8
    vilvl.d        vr9,    vr13,  vr9
    vilvl.d        vr10,   vr14,  vr10
    vilvl.d        vr11,   vr15,  vr11
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr2,    xr2
    vext2xv.hu.bu  xr3,    xr3
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9
    vext2xv.hu.bu  xr10,   xr10
    vext2xv.hu.bu  xr11,   xr11

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvsub.h        xr2,    xr2,   xr10
    xvsub.h        xr3,    xr3,   xr11
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvmul.h        xr2,    xr2,   xr2
    xvmul.h        xr3,    xr3,   xr3
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr2,    xr2,   xr2
    xvhaddw.wu.hu  xr3,    xr3,   xr3
    xvadd.w        xr0,    xr0,   xr1
    xvadd.w        xr2,    xr2,   xr3
    xvadd.w        xr0,    xr0,   xr2

    // Calculate the sum
    xvhaddw.d.w    xr0,    xr0,   xr0
    xvhaddw.q.d    xr0,    xr0,   xr0
    xvpickve2gr.w  t2,     xr0,   0
    xvpickve2gr.w  t3,     xr0,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_ssd_8x4_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                        const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_8x4_lasx
    slli.d         t0,     a1,    1
    add.d          t1,     a1,    t0
    add.d          t2,     a1,    t1
    slli.d         t3,     a3,    1
    add.d          t4,     a3,    t3
    add.d          t5,     a3,    t4

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr4,  vr5,  vr6,  vr7

    vilvl.d        vr0,    vr2,   vr0
    vilvl.d        vr1,    vr3,   vr1
    vilvl.d        vr4,    vr6,   vr4
    vilvl.d        vr5,    vr7,   vr5
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr4,    xr4
    vext2xv.hu.bu  xr5,    xr5

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr4
    xvsub.h        xr1,    xr1,   xr5
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvadd.w        xr0,    xr0,   xr1

    // Calculate the sum
    xvhaddw.d.w    xr0,    xr0,   xr0
    xvhaddw.q.d    xr0,    xr0,   xr0
    xvpickve2gr.w  t2,     xr0,   0
    xvpickve2gr.w  t3,     xr0,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_ssd_4x16_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                         const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_4x16_lasx
    slli.d         t0,     a1,    1
    add.d          t1,     a1,    t0
    add.d          t2,     a1,    t1
    slli.d         t3,     a3,    1
    add.d          t4,     a3,    t3
    add.d          t5,     a3,    t4

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15

    vilvl.w        vr0,    vr4,   vr0
    vilvl.w        vr1,    vr5,   vr1
    vilvl.w        vr2,    vr6,   vr2
    vilvl.w        vr3,    vr7,   vr3
    vilvl.w        vr8,    vr12,  vr8
    vilvl.w        vr9,    vr13,  vr9
    vilvl.w        vr10,   vr14,  vr10
    vilvl.w        vr11,   vr15,  vr11
    vilvl.d        vr0,    vr2,   vr0
    vilvl.d        vr1,    vr3,   vr1
    vilvl.d        vr8,    vr10,  vr8
    vilvl.d        vr9,    vr11,  vr9
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvadd.w        xr16,   xr0,   xr1

    // Load data from pix1 and pix2
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15

    vilvl.w        vr0,    vr4,   vr0
    vilvl.w        vr1,    vr5,   vr1
    vilvl.w        vr2,    vr6,   vr2
    vilvl.w        vr3,    vr7,   vr3
    vilvl.w        vr8,    vr12,  vr8
    vilvl.w        vr9,    vr13,  vr9
    vilvl.w        vr10,   vr14,  vr10
    vilvl.w        vr11,   vr15,  vr11
    vilvl.d        vr0,    vr2,   vr0
    vilvl.d        vr1,    vr3,   vr1
    vilvl.d        vr8,    vr10,  vr8
    vilvl.d        vr9,    vr11,  vr9
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvadd.w        xr0,    xr0,   xr1
    xvadd.w        xr0,    xr0,   xr16

    // Calculate the sum
    xvhaddw.d.w    xr0,    xr0,   xr0
    xvhaddw.q.d    xr0,    xr0,   xr0
    xvpickve2gr.w  t2,     xr0,   0
    xvpickve2gr.w  t3,     xr0,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_ssd_4x8_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                        const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_4x8_lasx
    slli.d         t0,     a1,    1
    add.d          t1,     a1,    t0
    add.d          t2,     a1,    t1
    slli.d         t3,     a3,    1
    add.d          t4,     a3,    t3
    add.d          t5,     a3,    t4

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr0,  vr1,  vr2,  vr3
    add.d          a0,     a0,    t2
    LSX_LOADX_4    a0,     a1,    t0,  t1,  vr4,  vr5,  vr6,  vr7
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr8,  vr9,  vr10, vr11
    add.d          a2,     a2,    t5
    LSX_LOADX_4    a2,     a3,    t3,  t4,  vr12, vr13, vr14, vr15

    vilvl.w        vr0,    vr4,   vr0
    vilvl.w        vr1,    vr5,   vr1
    vilvl.w        vr2,    vr6,   vr2
    vilvl.w        vr3,    vr7,   vr3
    vilvl.w        vr8,    vr12,  vr8
    vilvl.w        vr9,    vr13,  vr9
    vilvl.w        vr10,   vr14,  vr10
    vilvl.w        vr11,   vr15,  vr11
    vilvl.d        vr0,    vr2,   vr0
    vilvl.d        vr1,    vr3,   vr1
    vilvl.d        vr8,    vr10,  vr8
    vilvl.d        vr9,    vr11,  vr9
    vext2xv.hu.bu  xr0,    xr0
    vext2xv.hu.bu  xr1,    xr1
    vext2xv.hu.bu  xr8,    xr8
    vext2xv.hu.bu  xr9,    xr9

    // Calculate the square of the difference
    xvsub.h        xr0,    xr0,   xr8
    xvsub.h        xr1,    xr1,   xr9
    xvmul.h        xr0,    xr0,   xr0
    xvmul.h        xr1,    xr1,   xr1
    xvhaddw.wu.hu  xr0,    xr0,   xr0
    xvhaddw.wu.hu  xr1,    xr1,   xr1
    xvadd.w        xr0,    xr0,   xr1

    // Calculate the sum
    xvhaddw.d.w    xr0,    xr0,   xr0
    xvhaddw.q.d    xr0,    xr0,   xr0
    xvpickve2gr.w  t2,     xr0,   0
    xvpickve2gr.w  t3,     xr0,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_ssd_4x4_lasx(const Pixel *pix1, intptr_t stride_pix1,
 *                        const Pixel *pix2, intptr_t stride_pix2)
 */
function pixel_ssd_4x4_lasx
    slli.d         t0,     a1,    1
    slli.d         t1,     a3,    1
    add.d          t2,     t0,    a1
    add.d          t3,     t1,    a3

    // Load data from pix1 and pix2
    LSX_LOADX_4    a0,     a1,    t0,  t2,  vr4, vr6, vr8, vr10
    LSX_LOADX_4    a2,     a3,    t1,  t3,  vr5, vr7, vr9, vr11
    vilvl.w        vr4,    vr6,   vr4
    vilvl.w        vr5,    vr7,   vr5
    vilvl.w        vr8,    vr10,  vr8
    vilvl.w        vr9,    vr11,  vr9
    vilvl.d        vr4,    vr8,   vr4
    vilvl.d        vr5,    vr9,   vr5
    vext2xv.hu.bu  xr4,    xr4
    vext2xv.hu.bu  xr5,    xr5

    // Calculate the square of the difference
    xvsub.h        xr6,    xr4,   xr5
    xvmul.h        xr6,    xr6,   xr6
    // Calculate the sum
    xvhaddw.wu.hu  xr6,    xr6,   xr6
    xvhaddw.du.wu  xr6,    xr6,   xr6
    xvhaddw.qu.du  xr6,    xr6,   xr6
    xvpickve2gr.wu t2,     xr6,   0
    xvpickve2gr.wu t3,     xr6,   4
    add.d          a0,     t2,    t3
endfunc

/*
 * int pixel_sa8d_16x16_lasx(const Pixel *pix1, intptr_t i_pix1,
 *                           const Pixel *pix2, intptr_t i_pix2)
 */
function pixel_sa8d_16x16_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    add.d           t4,    a1,   t2
    add.d           t5,    a3,   t3
    slli.d          t6,    a1,   2
    slli.d          t7,    a3,   2
    slli.d          t0,    a1,   3
    slli.d          t1,    a3,   3

    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr15,  xr11, xr13
    xvsub.h         xr16,  xr11, xr13

    add.d           a0,    a0,   t6
    add.d           a2,    a2,   t7
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr9,   xr11, xr13
    xvsub.h         xr10,  xr11, xr13
    xvadd.h         xr17,  xr15, xr9
    xvadd.h         xr18,  xr16, xr10
    xvsub.h         xr19,  xr15, xr9
    xvsub.h         xr20,  xr16, xr10
    xvadda.h        xr17,  xr17, xr18
    xvadda.h        xr19,  xr19, xr20
    xvadd.h         xr21,  xr17, xr19

    add.d           a0,    a0,   t6
    add.d           a2,    a2,   t7
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr15,  xr11, xr13
    xvsub.h         xr16,  xr11, xr13

    add.d           a0,    a0,   t6
    add.d           a2,    a2,   t7
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr9,   xr11, xr13
    xvsub.h         xr10,  xr11, xr13
    xvadd.h         xr17,  xr15, xr9
    xvadd.h         xr18,  xr16, xr10
    xvsub.h         xr19,  xr15, xr9
    xvsub.h         xr20,  xr16, xr10
    xvadda.h        xr17,  xr17, xr18
    xvadda.h        xr19,  xr19, xr20
    xvadd.h         xr22,  xr17, xr19

    sub.d           a0,    a0,   t6
    sub.d           a2,    a2,   t7
    addi.d          a0,    a0,   8
    addi.d          a2,    a2,   8
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr15,  xr11, xr13
    xvsub.h         xr16,  xr11, xr13

    add.d           a0,    a0,   t6
    add.d           a2,    a2,   t7
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr9,   xr11, xr13
    xvsub.h         xr10,  xr11, xr13
    xvadd.h         xr17,  xr15, xr9
    xvadd.h         xr18,  xr16, xr10
    xvsub.h         xr19,  xr15, xr9
    xvsub.h         xr20,  xr16, xr10
    xvadda.h        xr17,  xr17, xr18
    xvadda.h        xr19,  xr19, xr20
    xvadd.h         xr23,  xr17, xr19

    sub.d           a0,    a0,   t0
    sub.d           a2,    a2,   t1
    sub.d           a0,    a0,   t6
    sub.d           a2,    a2,   t7
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr15,  xr11, xr13
    xvsub.h         xr16,  xr11, xr13

    add.d           a0,    a0,   t6
    add.d           a2,    a2,   t7
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr12, 0x13
    xvadd.h         xr9,   xr11, xr13
    xvsub.h         xr10,  xr11, xr13
    xvadd.h         xr17,  xr15, xr9
    xvadd.h         xr18,  xr16, xr10
    xvsub.h         xr19,  xr15, xr9
    xvsub.h         xr20,  xr16, xr10
    xvadda.h        xr17,  xr17, xr18
    xvadda.h        xr19,  xr19, xr20
    xvadd.h         xr24,  xr17, xr19

    xvadd.h         xr21,  xr21, xr22
    xvadd.h         xr23,  xr23, xr24
    xvhaddw.wu.hu   xr21,  xr21, xr21
    xvhaddw.wu.hu   xr23,  xr23, xr23
    xvadd.w         xr21,  xr21, xr23
    xvhaddw.du.wu   xr21,  xr21, xr21
    xvhaddw.qu.du   xr21,  xr21, xr21
    xvpickve2gr.du  t4,    xr21, 0
    xvpickve2gr.du  t5,    xr21, 2
    add.d           t4,    t4,   t5
    addi.d          t4,    t4,   2
    srli.d          a0,    t4,   2
endfunc

/*
 * int pixel_sa8d_8x8_lasx(const Pixel *pix1, intptr_t i_pix1,
 *                         const Pixel *pix2, intptr_t i_pix2)
 */
function pixel_sa8d_8x8_lasx
    slli.d          t2,    a1,   1
    slli.d          t3,    a3,   1
    add.d           t4,    a1,   t2
    add.d           t5,    a3,   t3
    slli.d          t6,    a1,   2
    slli.d          t7,    a3,   2

    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvor.v          xr14,  xr12, xr12
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr14, 0x13
    xvadd.h         xr15,  xr11, xr13
    xvsub.h         xr16,  xr11, xr13

    add.d           a0,    a0,   t6
    add.d           a2,    a2,   t7
    // Load data from pix1 and pix2
    FLDD_LOADX_4    a0,    a1,   t2,  t4,  f1, f2, f3, f4
    FLDD_LOADX_4    a2,    a3,   t3,  t5,  f5, f6, f7, f8
    vilvl.d         vr1,   vr2,  vr1
    vilvl.d         vr3,   vr4,  vr3
    vilvl.d         vr5,   vr6,  vr5
    vilvl.d         vr7,   vr8,  vr7
    xvpermi.q       xr1,   xr3,  0x02
    xvpermi.q       xr5,   xr7,  0x02
    xvsubwev.h.bu   xr9,   xr1,  xr5
    xvsubwod.h.bu   xr10,  xr1,  xr5
    xvadd.h         xr11,  xr9,  xr10  /* a0 + a1 */
    xvsub.h         xr12,  xr9,  xr10  /* a0 - a1 */
    xvpackev.h      xr9,   xr12, xr11
    xvpackod.h      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.w      xr9,   xr12, xr11
    xvpackod.w      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10
    xvsub.h         xr12,  xr9,  xr10
    xvpackev.d      xr9,   xr12, xr11
    xvpackod.d      xr10,  xr12, xr11
    xvadd.h         xr11,  xr9,  xr10  /* HADAMARD4 */
    xvsub.h         xr12,  xr9,  xr10
    xvor.v          xr13,  xr11, xr11
    xvor.v          xr14,  xr12, xr12
    xvpermi.q       xr11,  xr12, 0x02
    xvpermi.q       xr13,  xr14, 0x13
    xvadd.h         xr9,   xr11, xr13
    xvsub.h         xr10,  xr11, xr13

    xvadd.h         xr17,  xr15, xr9
    xvadd.h         xr18,  xr16, xr10
    xvsub.h         xr19,  xr15, xr9
    xvsub.h         xr20,  xr16, xr10
    xvadda.h        xr17,  xr17, xr18
    xvadda.h        xr19,  xr19, xr20
    xvadd.h         xr17,  xr17, xr19
    xvhaddw.wu.hu   xr17,  xr17, xr17
    xvhaddw.du.wu   xr17,  xr17, xr17
    xvhaddw.qu.du   xr17,  xr17, xr17
    xvpickve2gr.wu  t4,    xr17, 0
    xvpickve2gr.wu  t5,    xr17, 4
    add.d           t4,    t4,   t5
    addi.d          t4,    t4,   2
    srli.d          a0,    t4,   2
endfunc

/*
 * uint64_t pixel_var_16x16( pixel *pix, intptr_t i_stride )
 */
function pixel_var_16x16_lasx
    slli.d          t0,    a1,   1
    add.d           t1,    t0,   a1
    xvxor.v         xr15,  xr15, xr15
    xvxor.v         xr16,  xr16, xr16
    xvxor.v         xr17,  xr17, xr17
    addi.d          t3,    zero, 16
.var_h16_0:
    vld             vr0,   a0,   0
    vldx            vr1,   a0,   a1
    vldx            vr2,   a0,   t0
    vldx            vr3,   a0,   t1
    xvpermi.q       xr1,   xr0,  0x20
    xvhaddw.hu.bu   xr4,   xr1,  xr1
    xvhaddw.wu.hu   xr4,   xr4,  xr4
    xvilvl.b        xr5,   xr15, xr1
    xvilvh.b        xr6,   xr15, xr1
    xvdp2add.w.h    xr16,  xr5,  xr5
    xvdp2add.w.h    xr16,  xr6,  xr6

    xvpermi.q       xr2,   xr3,  0x20
    xvhaddw.hu.bu   xr7,   xr2,  xr2
    xvhaddw.wu.hu   xr7,   xr7,  xr7
    xvilvl.b        xr5,   xr15, xr2
    xvilvh.b        xr6,   xr15, xr2
    xvdp2add.w.h    xr16,  xr5,  xr5
    xvdp2add.w.h    xr16,  xr6,  xr6

    xvadd.w         xr17,  xr4,  xr17
    xvadd.w         xr17,  xr7,  xr17
    alsl.d          a0,    a1,   a0,    2
    addi.d          t3,    t3,   -4
    blt             zero,  t3,   .var_h16_0

    xvhaddw.du.wu   xr17,  xr17,  xr17
    xvhaddw.qu.du   xr17,  xr17,  xr17
    xvpickve2gr.wu  t4,    xr17,  0
    xvpickve2gr.wu  t5,    xr17,  4
    add.w           t4,    t4,    t5

    xvhaddw.d.w     xr16,  xr16,  xr16
    xvhaddw.q.d     xr16,  xr16,  xr16
    xvpickve2gr.d   t5,    xr16,  0
    xvpickve2gr.d   t6,    xr16,  2
    add.d           t5,    t5,    t6
    slli.d          t5,    t5,    32
    add.d           a0,    t4,    t5
endfunc

/*
 * uint64_t pixel_var_8x16( uint8_t *p_pix, intptr_t i_stride )
 */
function pixel_var_8x16_lasx
    slli.d          t0,    a1,   1
    add.d           t1,    t0,   a1
    xvxor.v         xr15,  xr15, xr15
    xvxor.v         xr16,  xr16, xr16
    xvxor.v         xr17,  xr17, xr17
    addi.d          t6,    zero, 16
.var_h16_1:
    fld.d           f0,    a0,   0
    fldx.d          f1,    a0,   a1
    fldx.d          f2,    a0,   t0
    fldx.d          f3,    a0,   t1
    alsl.d          a0,    a1,   a0,   2
    fld.d           f4,    a0,   0
    fldx.d          f5,    a0,   a1
    fldx.d          f6,    a0,   t0
    fldx.d          f7,    a0,   t1

    vilvl.d         vr0,   vr1,  vr0
    vilvl.d         vr2,   vr3,  vr2
    xvpermi.q       xr2,   xr0,  0x20
    xvhaddw.hu.bu   xr3,   xr2,  xr2
    xvhaddw.wu.hu   xr3,   xr3,  xr3
    xvilvl.b        xr8,   xr15, xr2
    xvilvh.b        xr9,   xr15, xr2
    xvdp2add.w.h    xr16,  xr8,  xr8
    xvdp2add.w.h    xr16,  xr9,  xr9

    vilvl.d         vr0,   vr5,  vr4
    vilvl.d         vr2,   vr7,  vr6
    xvpermi.q       xr2,   xr0,  0x20
    xvhaddw.hu.bu   xr6,   xr2,  xr2
    xvhaddw.wu.hu   xr6,   xr6,  xr6
    xvilvl.b        xr8,   xr15, xr2
    xvilvh.b        xr9,   xr15, xr2
    xvdp2add.w.h    xr16,  xr8,  xr8
    xvdp2add.w.h    xr16,  xr9,  xr9

    xvadd.w         xr17,  xr17, xr3
    xvadd.w         xr17,  xr17, xr6
    alsl.d          a0,    a1,   a0,   2
    addi.d          t6,    t6,   -8
    blt             zero,  t6,   .var_h16_1

    xvhaddw.du.wu   xr17,  xr17,  xr17
    xvhaddw.qu.du   xr17,  xr17,  xr17
    xvpickve2gr.wu  t4,    xr17,  0
    xvpickve2gr.wu  t5,    xr17,  4
    add.w           t4,    t4,    t5

    xvhaddw.d.w     xr16,  xr16,  xr16
    xvhaddw.q.d     xr16,  xr16,  xr16
    xvpickve2gr.d   t5,    xr16,  0
    xvpickve2gr.d   t6,    xr16,  2
    add.d           t5,    t5,    t6
    slli.d          t5,    t5,    32
    add.d           a0,    t4,    t5
endfunc

/*
 * uint64_t pixel_var_8x8( uint8_t *p_pix, intptr_t i_stride )
 */
function pixel_var_8x8_lasx
    slli.d          t0,    a1,   1
    add.d           t1,    t0,   a1
    xvxor.v         xr15,  xr15, xr15
    xvxor.v         xr16,  xr16, xr16
    xvxor.v         xr17,  xr17, xr17

    fld.d           f0,    a0,   0
    fldx.d          f1,    a0,   a1
    fldx.d          f2,    a0,   t0
    fldx.d          f3,    a0,   t1
    alsl.d          a0,    a1,   a0,   2
    fld.d           f4,    a0,   0
    fldx.d          f5,    a0,   a1
    fldx.d          f6,    a0,   t0
    fldx.d          f7,    a0,   t1

    vilvl.d         vr0,   vr1,  vr0
    vilvl.d         vr2,   vr3,  vr2
    xvpermi.q       xr2,   xr0,  0x20
    xvhaddw.hu.bu   xr3,   xr2,  xr2
    xvhaddw.wu.hu   xr3,   xr3,  xr3
    xvilvl.b        xr8,   xr15, xr2
    xvilvh.b        xr9,   xr15, xr2
    xvdp2add.w.h    xr16,  xr8,  xr8
    xvdp2add.w.h    xr16,  xr9,  xr9

    vilvl.d         vr0,   vr5,  vr4
    vilvl.d         vr2,   vr7,  vr6
    xvpermi.q       xr2,   xr0,  0x20
    xvhaddw.hu.bu   xr6,   xr2,  xr2
    xvhaddw.wu.hu   xr6,   xr6,  xr6
    xvilvl.b        xr8,   xr15, xr2
    xvilvh.b        xr9,   xr15, xr2
    xvdp2add.w.h    xr16,  xr8,  xr8
    xvdp2add.w.h    xr16,  xr9,  xr9

    xvadd.w         xr17,  xr17, xr3
    xvadd.w         xr17,  xr17, xr6

    xvhaddw.du.wu   xr17,  xr17,  xr17
    xvhaddw.qu.du   xr17,  xr17,  xr17
    xvpickve2gr.wu  t4,    xr17,  0
    xvpickve2gr.wu  t5,    xr17,  4
    add.w           t4,    t4,    t5

    xvhaddw.d.w     xr16,  xr16,  xr16
    xvhaddw.q.d     xr16,  xr16,  xr16
    xvpickve2gr.d   t5,    xr16,  0
    xvpickve2gr.d   t6,    xr16,  2
    add.d           t5,    t5,    t6
    slli.d          t5,    t5,    32
    add.d           a0,    t4,    t5
endfunc

.macro sse_diff_8width_lasx in0, in1
    fld.d           f0,    \in0,  0
    fld.d           f1,    \in0,  FENC_STRIDE
    fld.d           f2,    \in0,  FENC_STRIDE * 2
    fld.d           f3,    \in0,  FENC_STRIDE * 3
    fld.d           f4,    \in1,  0
    fld.d           f5,    \in1,  FDEC_STRIDE
    fld.d           f6,    \in1,  FDEC_STRIDE * 2
    fld.d           f7,    \in1,  FDEC_STRIDE * 3

    vilvl.d         vr0,   vr1,   vr0
    vilvl.d         vr1,   vr3,   vr2
    vilvl.d         vr4,   vr5,   vr4
    vilvl.d         vr5,   vr7,   vr6
    xvpermi.q       xr1,   xr0,   0x20
    xvpermi.q       xr5,   xr4,   0x20

    xvilvl.b        xr2,   xr5,   xr1
    xvilvh.b        xr6,   xr5,   xr1
    xvhsubw.hu.bu   xr3,   xr2,   xr2
    xvhsubw.hu.bu   xr4,   xr6,   xr6
    xvdp2add.w.h    xr8,   xr3,   xr3
    xvdp2add.w.h    xr8,   xr4,   xr4
    xvadd.h         xr9,   xr9,   xr3
    xvadd.h         xr9,   xr9,   xr4
.endm

/*
 * int32_t x264_pixel_var2_8x16_lasx( uint8_t *p_pix1, uint8_t *p_pix2,
 *                                    int32_t ssd[2] )
 */
function pixel_var2_8x16_lasx
    add.d           t0,    a0,    zero
    add.d           t1,    a1,    zero
    xvxor.v         xr8,   xr8,   xr8
    xvxor.v         xr9,   xr9,   xr9

    sse_diff_8width_lasx a0, a1
    addi.d          a0,    a0,    FENC_STRIDE * 4
    addi.d          a1,    a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1
    addi.d          a0,    a0,    FENC_STRIDE * 4
    addi.d          a1,    a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1
    addi.d          a0,    a0,    FENC_STRIDE * 4
    addi.d          a1,    a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1

    xvhaddw.w.h     xr9,   xr9,   xr9
    xvhaddw.d.w     xr9,   xr9,   xr9
    xvhaddw.q.d     xr9,   xr9,   xr9
    xvpickve2gr.wu  t2,    xr9,   0
    xvpickve2gr.wu  t3,    xr9,   4
    add.w           t2,    t2,    t3
    xvhaddw.d.w     xr8,   xr8,   xr8
    xvhaddw.q.d     xr8,   xr8,   xr8
    xvpickve2gr.wu  t3,    xr8,   0
    xvpickve2gr.wu  t4,    xr8,   4
    add.w           t3,    t4,    t3
    st.w            t3,    a2,    0
    mul.w           t2,    t2,    t2
    srai.w          t2,    t2,    7
    sub.w           t3,    t3,    t2

    xvxor.v         xr8,   xr8,   xr8
    xvxor.v         xr9,   xr9,   xr9
    addi.d          a0,    t0,    FENC_STRIDE / 2
    addi.d          a1,    t1,    FDEC_STRIDE / 2
    sse_diff_8width_lasx a0, a1
    addi.d          a0,    a0,    FENC_STRIDE * 4
    addi.d          a1,    a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1
    addi.d          a0,    a0,    FENC_STRIDE * 4
    addi.d          a1,    a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1
    addi.d          a0,    a0,    FENC_STRIDE * 4
    addi.d          a1,    a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1

    xvhaddw.w.h     xr9,   xr9,   xr9
    xvhaddw.d.w     xr9,   xr9,   xr9
    xvhaddw.q.d     xr9,   xr9,   xr9
    xvpickve2gr.wu  t4,    xr9,   0
    xvpickve2gr.wu  t5,    xr9,   4
    add.w           t4,    t4,    t5
    xvhaddw.d.w     xr8,   xr8,   xr8
    xvhaddw.q.d     xr8,   xr8,   xr8
    xvpickve2gr.wu  t5,    xr8,   0
    xvpickve2gr.wu  t6,    xr8,   4
    add.w           t5,    t6,    t5
    st.w            t5,    a2,    4
    mul.w           t4,    t4,    t4
    srai.w          t4,    t4,    7
    sub.w           t5,    t5,    t4
    add.w           a0,    t3,    t5
endfunc

/*
 * int32_t x264_pixel_var2_8x8_lasx( uint8_t *p_pix1, uint8_t *p_pix2,
 *                                   int32_t ssd[2] )
 */
function pixel_var2_8x8_lasx
    add.d           t0,    a0,    zero
    add.d           t1,    a1,    zero
    xvxor.v         xr8,   xr8,   xr8
    xvxor.v         xr9,   xr9,   xr9

    sse_diff_8width_lasx a0, a1
    addi.d          a0,    a0,    FENC_STRIDE * 4
    addi.d          a1,    a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1

    xvhaddw.w.h     xr9,   xr9,   xr9
    xvhaddw.d.w     xr9,   xr9,   xr9
    xvhaddw.q.d     xr9,   xr9,   xr9
    xvpickve2gr.wu  t2,    xr9,   0
    xvpickve2gr.wu  t3,    xr9,   4
    add.w           t2,    t2,    t3
    xvhaddw.d.w     xr8,   xr8,   xr8
    xvhaddw.q.d     xr8,   xr8,   xr8
    xvpickve2gr.wu  t3,    xr8,   0
    xvpickve2gr.wu  t4,    xr8,   4
    add.w           t3,    t4,    t3
    st.w            t3,    a2,    0
    mul.w           t2,    t2,    t2
    srai.w          t2,    t2,    6
    sub.w           t3,    t3,    t2

    xvxor.v        xr8,    xr8,   xr8
    xvxor.v        xr9,    xr9,   xr9
    addi.d         a0,     t0,    FENC_STRIDE / 2
    addi.d         a1,     t1,    FDEC_STRIDE / 2
    sse_diff_8width_lasx a0, a1
    addi.d         a0,     a0,    FENC_STRIDE * 4
    addi.d         a1,     a1,    FDEC_STRIDE * 4
    sse_diff_8width_lasx a0, a1

    xvhaddw.w.h    xr9,   xr9,   xr9
    xvhaddw.d.w    xr9,   xr9,   xr9
    xvhaddw.q.d    xr9,   xr9,   xr9
    xvpickve2gr.wu t4,    xr9,   0
    xvpickve2gr.wu t5,    xr9,   4
    add.w          t4,    t4,    t5
    xvhaddw.d.w    xr8,   xr8,   xr8
    xvhaddw.q.d    xr8,   xr8,   xr8
    xvpickve2gr.wu t5,    xr8,   0
    xvpickve2gr.wu t6,    xr8,   4
    add.w          t5,    t6,    t5
    st.w           t5,    a2,    4
    mul.w          t4,    t4,    t4
    srai.w         t4,    t4,    6
    sub.w          t5,    t5,    t4
    add.w          a0,    t3,    t5
endfunc

#endif /* !HIGH_BIT_DEPTH */
