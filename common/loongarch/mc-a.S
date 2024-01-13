/*****************************************************************************
 * mc-a.S: LoongArch motion compensation
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Xiwei Gu <guxiwei-hf@loongson.cn>
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

const ch_shuf
.byte 0, 2, 2, 4, 4, 6, 6, 8, 1, 3, 3, 5, 5, 7, 7, 9
.byte 0, 2, 2, 4, 4, 6, 6, 8, 1, 3, 3, 5, 5, 7, 7, 9
endconst

const pw_1024
.rept 16
.short 1024
.endr
endconst

const filt_mul20
.rept 32
.byte 20
.endr
endconst

const filt_mul15
.rept 16
.byte 1, -5
.endr
endconst

const filt_mul51
.rept 16
.byte -5, 1
.endr
endconst

const hpel_shuf
.rept 2
.byte 0,8,1,9,2,10,3,11,4,12,5,13,6,14,7,15
.endr
endconst

const shuf_12
.rept 2
.byte 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27
.endr
endconst

const shuf_14
.rept 2
.byte 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
.endr
endconst

const shuf_15
.rept 2
.byte 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
.endr
endconst

const shuf_1
.rept 2
.byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
.endr
endconst

const shuf_2
.rept 2
.byte 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17
.endr
endconst

const shuf_3
.rept 2
.byte 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
.endr
endconst

const shuf_4
.rept 2
.byte 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
.endr
endconst

const shuf_6
.rept 2
.byte 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
.endr
endconst

#if !HIGH_BIT_DEPTH

.macro  MC_CHROMA_START
    srai.d         t0,      a5,    3
    srai.d         t1,      a6,    3
    slli.d         t0,      t0,    1
    mul.d          t1,      t1,    a4
    add.d          t1,      t1,    t0
    add.d          a3,      a3,    t1 /* src += (m_vy >> 3) * i_src_stride + (m_vx >> 3) * 2 */
.endm

/*
 * void mc_chroma( uint8_t *p_dst_u, uint8_t *p_dst_v,
 *                 intptr_t i_dst_stride,
 *                 uint8_t *p_src, intptr_t i_src_stride,
 *                 int32_t m_vx, int32_t m_vy,
 *                 int32_t i_width, int32_t i_height )
 */
function_x264 mc_chroma_lasx
    MC_CHROMA_START
    andi           a5,      a5,    0x07    /* m_vx & 0x07 */
    andi           a6,      a6,    0x07    /* m_vy & 0x07 */
    move           t0,      a5
    slli.d         t0,      t0,    8
    sub.d          t0,      t0,    a5
    li.d           a5,      8
    addi.d         t0,      t0,    8
    sub.d          a5,      a5,    a6
    mul.d          a6,      a6,    t0      /* (x * 255 + 8) * y */
    mul.d          a5,      a5,    t0      /* (x * 255 + 8) * (8 - y) */
    xvreplgr2vr.h  xr6,     a6      /* cD cC ... cD cC */
    xvreplgr2vr.h  xr7,     a5      /* cB cA ... cB cA */
    la.local       t0,      ch_shuf
    xvld           xr5,     t0,    0
    addi.d         t0,      a7,    -4
    ldptr.w        a7,      sp,    0       /* a7 = i_height */
    slli.d         t1,      a4,    1
    blt            zero,    t0,    .L_WIDTH8
.L_LOOP4:
    vld            vr0,     a3,    0
    vldx           vr1,     a3,    a4
    vldx           vr2,     a3,    t1
    xvpermi.q      xr0,     xr1,   0x02
    xvpermi.q      xr1,     xr2,   0x02
    xvshuf.b       xr0,     xr0,   xr0,   xr5
    xvshuf.b       xr1,     xr1,   xr1,   xr5
    xvdp2.h.bu     xr2,     xr0,   xr7
    xvdp2.h.bu     xr3,     xr1,   xr6
    xvadd.h        xr0,     xr2,   xr3
    xvssrlrni.bu.h xr0,     xr0,   6
    xvstelm.w      xr0,     a0,    0,     0
    xvstelm.w      xr0,     a1,    0,     1
    add.d          a0,      a0,    a2
    add.d          a1,      a1,    a2
    xvstelm.w      xr0,     a0,    0,     4
    xvstelm.w      xr0,     a1,    0,     5
    add.d          a0,      a0,    a2
    add.d          a1,      a1,    a2
    add.d          a3,      a3,    t1
    addi.d         a7,      a7,    -2
    blt            zero,    a7,    .L_LOOP4
    b              .ENDFUNC
.L_WIDTH8:
    xvld           xr0,     a3,    0
    xvpermi.d      xr0,     xr0,   0x94
    xvshuf.b       xr0,     xr0,   xr0,   xr5
.L_LOOP8:
    xvldx          xr3,     a3,    a4
    xvpermi.d      xr3,     xr3,   0x94
    xvshuf.b       xr3,     xr3,   xr3,   xr5
    xvdp2.h.bu     xr1,     xr0,   xr7
    xvdp2.h.bu     xr2,     xr3,   xr6
    xvdp2.h.bu     xr8,     xr3,   xr7

    xvldx          xr0,     a3,    t1
    xvpermi.d      xr0,     xr0,   0x94
    xvshuf.b       xr0,     xr0,   xr0,   xr5
    xvdp2.h.bu     xr4,     xr0,   xr6
    xvadd.h        xr1,     xr1,   xr2
    xvadd.h        xr3,     xr8,   xr4

    xvssrlrni.bu.h xr3,     xr1,   6

    xvpermi.q      xr4,     xr3,   0x01
    xvpackev.w     xr8,     xr4,   xr3
    xvpackod.w     xr9,     xr4,   xr3
    vstelm.d       vr8,     a0,    0,     0
    vstelm.d       vr9,     a1,    0,     0
    add.d          a0,      a0,    a2
    add.d          a1,      a1,    a2
    vstelm.d       vr8,     a0,    0,     1
    vstelm.d       vr9,     a1,    0,     1

    addi.d         a7,      a7,    -2
    add.d          a0,      a0,    a2
    add.d          a1,      a1,    a2
    add.d          a3,      a3,    t1
    blt            zero,    a7,    .L_LOOP8
.ENDFUNC:
endfunc_x264

.macro PIXEL_AVG_START
    slli.d         t0,      a3,    1
    add.w          t1,      t0,    a3
    slli.d         t2,      a3,    2
    slli.d         t3,      a5,    1
    add.w          t4,      t3,    a5
    slli.d         t5,      a5,    2
    slli.d         t6,      a1,    1
    add.w          t7,      t6,    a1
    slli.d         t8,      a1,    2
.endm

.macro BIWEIGHT_AVG_START
    addi.d         t0,      zero,  64
    sub.d          t0,      t0,    a6
    xvreplgr2vr.b  xr0,     a6
    xvreplgr2vr.b  xr1,     t0
    xvpackev.b     xr8,     xr1,   xr0
    xvxor.v        xr9,     xr9,   xr9
    xvaddi.hu      xr9,     xr9,   6
.endm

.macro BIWEIGHT_AVG_CORE a, b
    xvpermi.d        \a,      \a,    0x50
    xvpermi.d        \b,      \b,    0x50
    xvilvl.b         \a,      \b,    \a
    xvmulwev.h.bu.b  \b,      \a,    xr8
    xvmaddwod.h.bu.b \b,      \a,    xr8
    xvssrarn.bu.h    \b,      \b,    xr9
    xvpermi.d        \b,      \b,    0x08
.endm

.macro PIXEL_AVG_START_W8
    slli.d           t0,      a3,    1
    add.w            t1,      t0,    a3
    slli.d           t3,      a5,    1
    add.w            t4,      t3,    a5
.endm

function_x264 pixel_avg_weight_w4_lasx
    addi.d           t0,      zero,  64
    sub.d            t0,      t0,    a6
    vreplgr2vr.b     vr0,     a6
    vreplgr2vr.b     vr1,     t0
    vpackev.b        vr8,     vr1,   vr0
.LOOP_HEIGHT_W4_1:
    fld.s            f0,      a2,    0
    fldx.s           f1,      a2,    a3
    fld.s            f2,      a4,    0
    fldx.s           f3,      a4,    a5
    vilvl.w          vr0,     vr1,   vr0
    vilvl.w          vr2,     vr3,   vr2
    vilvl.b          vr0,     vr2,   vr0
    vmulwev.h.bu.b   vr1,     vr0,   vr8
    vmaddwod.h.bu.b  vr1,     vr0,   vr8
    vssrarni.bu.h    vr1,     vr1,   6
    fst.s            f1,      a0,    0
    add.d            a0,      a0,    a1
    vstelm.w         vr1,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a5,    a4,   1
    addi.w           a7,      a7,    -2
    bnez             a7,      .LOOP_HEIGHT_W4_1
endfunc_x264

function_x264 pixel_avg_w4_lasx
.LOOP_HEIGHT_W4:
    fld.s            f0,      a2,    0
    fldx.s           f1,      a2,    a3
    fld.s            f4,      a4,    0
    fldx.s           f5,      a4,    a5
    vilvl.w          vr0,     vr1,   vr0
    vilvl.w          vr4,     vr5,   vr4
    vavgr.bu         vr0,     vr0,   vr4
    fst.s            f0,      a0,    0
    add.d            a0,      a0,    a1
    vstelm.w         vr0,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a5,    a4,   1
    addi.w           a7,      a7,    -2
    bnez             a7,      .LOOP_HEIGHT_W4
endfunc_x264

function_x264 pixel_avg_weight_w8_lasx
    addi.d           t0,      zero,  64
    sub.d            t0,      t0,    a6
    xvreplgr2vr.b    xr0,     a6
    xvreplgr2vr.b    xr1,     t0
    xvpackev.b       xr8,     xr1,   xr0
    PIXEL_AVG_START_W8
.LOOP_HEIGHT_W8_1:
    fld.d            f0,      a2,    0
    fldx.d           f1,      a2,    a3
    fldx.d           f2,      a2,    t0
    fldx.d           f3,      a2,    t1
    fld.d            f4,      a4,    0
    fldx.d           f5,      a4,    a5
    fldx.d           f6,      a4,    t3
    fldx.d           f7,      a4,    t4
    vilvl.b          vr0,     vr4,   vr0
    vilvl.b          vr1,     vr5,   vr1
    vilvl.b          vr2,     vr6,   vr2
    vilvl.b          vr3,     vr7,   vr3
    xvpermi.q        xr1,     xr0,   0x20
    xvpermi.q        xr3,     xr2,   0x20
    xvmulwev.h.bu.b  xr2,     xr1,   xr8
    xvmaddwod.h.bu.b xr2,     xr1,   xr8
    xvmulwev.h.bu.b  xr4,     xr3,   xr8
    xvmaddwod.h.bu.b xr4,     xr3,   xr8
    xvssrarni.bu.h   xr4,     xr2,   6
    fst.d            f4,      a0,    0
    add.d            a0,      a0,    a1
    xvstelm.d        xr4,     a0,    0,    2
    add.d            a0,      a0,    a1
    xvstelm.d        xr4,     a0,    0,    1
    add.d            a0,      a0,    a1
    xvstelm.d        xr4,     a0,    0,    3
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   2
    alsl.d           a4,      a5,    a4,   2
    addi.w           a7,      a7,    -4
    bnez             a7,      .LOOP_HEIGHT_W8_1
endfunc_x264

function_x264 pixel_avg_w8_lasx
    PIXEL_AVG_START_W8
.LOOP_HEIGHT_W8:
    fld.d            f0,      a2,    0
    fldx.d           f1,      a2,    a3
    fldx.d           f2,      a2,    t0
    fldx.d           f3,      a2,    t1
    fld.d            f4,      a4,    0
    fldx.d           f5,      a4,    a5
    fldx.d           f6,      a4,    t3
    fldx.d           f7,      a4,    t4
    vilvl.d          vr0,     vr1,   vr0
    vilvl.d          vr2,     vr3,   vr2
    vilvl.d          vr4,     vr5,   vr4
    vilvl.d          vr6,     vr7,   vr6
    vavgr.bu         vr0,     vr0,   vr4
    vavgr.bu         vr2,     vr2,   vr6
    fst.d            f0,      a0,    0
    add.d            a0,      a0,    a1
    vstelm.d         vr0,     a0,    0,    1
    fstx.d           f2,      a0,    a1
    alsl.d           a0,      a1,    a0,   1
    vstelm.d         vr2,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   2
    alsl.d           a4,      a5,    a4,   2
    addi.w           a7,      a7,    -4
    bnez             a7,      .LOOP_HEIGHT_W8
endfunc_x264

function_x264 pixel_avg_weight_w16_lasx
    BIWEIGHT_AVG_START
    PIXEL_AVG_START
.L_HEIGHT_LOOP_T:
    LSX_LOADX_4 a2, a3, t0, t1, vr0, vr1, vr2, vr3
    LSX_LOADX_4 a4, a5, t3, t4, vr4, vr5, vr6, vr7
    BIWEIGHT_AVG_CORE xr0, xr4
    BIWEIGHT_AVG_CORE xr1, xr5
    vst              vr4,     a0,    0
    vstx             vr5,     a0,    a1
    BIWEIGHT_AVG_CORE xr2, xr6
    BIWEIGHT_AVG_CORE xr3, xr7
    vstx             vr6,     a0,    t6
    vstx             vr7,     a0,    t7
    add.d            a2,      a2,    t2
    add.d            a4,      a4,    t5
    add.d            a0,      a0,    t8
    addi.d           a7,      a7,    -4
    bnez             a7,      .L_HEIGHT_LOOP_T
endfunc_x264

function_x264 pixel_avg_w16_lasx
    PIXEL_AVG_START
.L_HEIGHT_LOOP:
    vld              vr0,     a2,    0
    vldx             vr1,     a2,    a3
    vldx             vr2,     a2,    t0
    vldx             vr3,     a2,    t1
    vld              vr4,     a4,    0
    vldx             vr5,     a4,    a5
    vldx             vr6,     a4,    t3
    vldx             vr7,     a4,    t4
    vavgr.bu         vr0,     vr0,   vr4
    vavgr.bu         vr1,     vr1,   vr5
    vavgr.bu         vr2,     vr2,   vr6
    vavgr.bu         vr3,     vr3,   vr7
    vst              vr0,     a0,    0
    vstx             vr1,     a0,    a1
    vstx             vr2,     a0,    t6
    vstx             vr3,     a0,    t7
    add.d            a0,      a0,    t8
    add.d            a2,      a2,    t2
    add.d            a4,      a4,    t5

    vld              vr0,     a2,    0
    vldx             vr1,     a2,    a3
    vldx             vr2,     a2,    t0
    vldx             vr3,     a2,    t1
    vld              vr4,     a4,    0
    vldx             vr5,     a4,    a5
    vldx             vr6,     a4,    t3
    vldx             vr7,     a4,    t4
    vavgr.bu         vr0,     vr0,   vr4
    vavgr.bu         vr1,     vr1,   vr5
    vavgr.bu         vr2,     vr2,   vr6
    vavgr.bu         vr3,     vr3,   vr7
    vst              vr0,     a0,    0
    vstx             vr1,     a0,    a1
    vstx             vr2,     a0,    t6
    vstx             vr3,     a0,    t7
    add.d            a2,      a2,    t2
    add.d            a4,      a4,    t5
    add.d            a0,      a0,    t8
    addi.d           a7,      a7,    -8
    bnez             a7,      .L_HEIGHT_LOOP
endfunc_x264

.macro FILT_PACK_LASX s1, s2, s3
    xvmulwev.w.h     xr16,    \s1,   \s3
    xvmulwev.w.h     xr17,    \s2,   \s3
    xvsrarni.h.w     xr17,    xr16,  15
    xvmaxi.h         xr17,    xr17,  0
    xvsat.hu         xr17,    xr17,  7
    xvmulwod.w.h     xr18,    \s1,   \s3
    xvmulwod.w.h     xr19,    \s2,   \s3
    xvsrarni.h.w     xr19,    xr18,  15
    xvmaxi.h         xr19,    xr19,  0
    xvsat.hu         xr19,    xr19,  7
    xvpackev.b       \s1,     xr19,  xr17
.endm

/* s3: temp, s4: UNUSED, s5: imm */
.macro DO_FILT_V_LASX s1, s2, s3, s4, s5
    alsl.d           t1,      a2,    a1,  1  /* t1 = a1 + 2 * a2 */
    alsl.d           t2,      a2,    a3,  1  /* t2 = a3 + 2 * a2 */
    xvld             xr1,     a3,    0
    xvldx            xr2,     a3,    a2
    xvld             \s3,     t2,    0
    xvld             xr3,     a1,    0
    xvldx            \s1,     a1,    a2
    xvld             \s2,     t1,    0
    xvilvh.b         xr16,    xr2,   xr1
    xvilvl.b         xr17,    xr2,   xr1
    xvilvh.b         xr18,    \s2,   \s1
    xvilvl.b         xr19,    \s2,   \s1
    xvilvh.b         xr20,    \s3,   xr3
    xvilvl.b         xr21,    \s3,   xr3
    xvdp2.h.bu.b     xr1,     xr17,  xr12
    xvdp2.h.bu.b     xr4,     xr16,  xr12
    xvdp2.h.bu.b     \s1,     xr19,  xr0
    xvdp2.h.bu.b     xr2,     xr18,  xr0
    xvdp2.h.bu.b     xr3,     xr21,  xr14
    xvdp2.h.bu.b     \s2,     xr20,  xr14
    xvadd.h          xr1,     xr1,   \s1
    xvadd.h          xr4,     xr4,   xr2
    xvadd.h          xr1,     xr1,   xr3
    xvadd.h          xr4,     xr4,   \s2
    xmov             \s1,     xr1
    xmov             \s2,     xr1
    addi.d           a3,      a3,    32
    addi.d           a1,      a1,    32
    xvpermi.q        \s1,     xr4,   0x2
    xvpermi.q        \s2,     xr4,   0x13
    FILT_PACK_LASX  xr1,  xr4,  xr15
    addi.d           t1,      a4,    \s5
    xvstx            xr1,     t0,    t1
.endm

.macro FILT_H s1, s2, s3
    xvsub.h          \s1,     \s1,   \s2
    xvsrai.h         \s1,     \s1,   2
    xvsub.h          \s1,     \s1,   \s2
    xvadd.h          \s1,     \s1,   \s3
    xvsrai.h         \s1,     \s1,   2
    xvadd.h          \s1,     \s1,   \s3
.endm

.macro FILT_C s1, s2, s3
    xmov             xr3,     \s1
    xvpermi.q        xr3,     \s2,   0x03
    xvshuf.b         xr1,     \s2,   xr3,  xr23
    xvshuf.b         xr2,     \s2,   xr3,  xr24
    xmov             \s1,     \s2
    xvpermi.q        \s1,     \s3,   0x03
    xvshuf.b         xr3,     \s1,   \s2,  xr29
    xvshuf.b         xr4,     \s1,   \s2,  xr27
    xvadd.h          xr3,     xr2,   xr3
    xmov             xr2,     \s1
    xmov             \s1,     \s3
    xvshuf.b         \s3,     xr2,   \s2,  xr30
    xvadd.h          xr4,     xr4,   \s2
    xvadd.h          \s3,     \s3,   xr1
    FILT_H \s3, xr3, xr4
.endm

.macro DO_FILT_C_LASX s1, s2, s3, s4
    FILT_C \s1, \s2, \s3
    FILT_C \s2, \s1, \s4
    FILT_PACK_LASX \s3, \s4, xr15
    xvpermi.d        \s3,     \s3,   0xd8
    xvstx            \s3,     a5,    a4
.endm

.macro DO_FILT_H_LASX s1, s2, s3
    xmov             xr3,     \s1
    xvpermi.q        xr3,     \s2,   0x03
    xvshuf.b         xr1,     \s2,   xr3,  xr24
    xvshuf.b         xr2,     \s2,   xr3,  xr25
    xmov             xr3,     \s2
    xvpermi.q        xr3,     \s3,   0x03
    xvshuf.b         xr4,     xr3,   \s2,  xr26
    xvshuf.b         xr5,     xr3,   \s2,  xr27
    xvshuf.b         xr6,     xr3,   \s2,  xr28
    xmov             \s1,     \s2
    xvdp2.h.bu.b     xr16,    xr1,   xr12
    xvdp2.h.bu.b     xr17,    xr2,   xr12
    xvdp2.h.bu.b     xr18,    \s2,   xr14
    xvdp2.h.bu.b     xr19,    xr4,   xr14
    xvdp2.h.bu.b     xr20,    xr5,   xr0
    xvdp2.h.bu.b     xr21,    xr6,   xr0
    xvadd.h          xr1,     xr16,  xr18
    xvadd.h          xr2,     xr17,  xr19
    xvadd.h          xr1,     xr1,   xr20
    xvadd.h          xr2,     xr2,   xr21
    FILT_PACK_LASX xr1, xr2, xr15
    xvshuf.b         xr1,     xr1,   xr1,  xr22
    xvstx            xr1,     a0,    a4
    xmov             \s2,     \s3
.endm

/*
 * void hpel_filter( uint8_t *dsth, uint8_t *dstv, uint8_t *dstc,
 *                  uint8_t *src, intptr_t stride, int width, int height )
 */
function_x264 hpel_filter_lasx
    addi.d           sp,      sp,    -56
    fst.d            f24,     sp,    0
    fst.d            f25,     sp,    8
    fst.d            f26,     sp,    16
    fst.d            f27,     sp,    24
    fst.d            f28,     sp,    32
    fst.d            f29,     sp,    40
    fst.d            f30,     sp,    48

    move             a7,      a3
    addi.d           a5,      a5,    -32
    move             t0,      a1
    andi             a7,      a7,    31
    sub.d            a3,      a3,    a7
    add.d            a0,      a0,    a5
    add.d            t0,      t0,    a5
    add.d            a7,      a7,    a5
    add.d            a5,      a5,    a2
    move             a2,      a4
    sub.d            a7,      zero,  a7
    add.d            a1,      a3,    a2
    sub.d            a3,      a3,    a2
    sub.d            a3,      a3,    a2
    move             a4,      a7
    la.local         t1,      filt_mul51
    xvld             xr0,     t1,    0
    la.local         t2,      filt_mul15
    xvld             xr12,    t2,    0
    la.local         t3,      filt_mul20
    xvld             xr14,    t3,    0
    la.local         t4,      pw_1024
    xvld             xr15,    t4,    0
    la.local         t1,      hpel_shuf
    xvld             xr22,    t1,    0
    la.local         t2,      shuf_12
    xvld             xr23,    t2,    0
    la.local         t3,      shuf_1
    xvld             xr26,    t3,    0
    xvaddi.bu        xr24,    xr23,  2 /* shuf_14  */
    xvaddi.bu        xr25,    xr23,  3 /* shuf_15  */
    xvaddi.bu        xr27,    xr26,  1 /* shuf_2   */
    xvaddi.bu        xr28,    xr26,  2 /* shuf_3   */
    xvaddi.bu        xr29,    xr26,  3 /* shuf_4   */
    xvaddi.bu        xr30,    xr26,  5 /* shuf_6   */
    xvxor.v          xr9,     xr9,   xr9
    xvxor.v          xr10,    xr10,  xr10
.LOOPY:
    DO_FILT_V_LASX xr8, xr7, xr13, xr12, 0
.LOOPX:
    DO_FILT_V_LASX xr6, xr5, xr11, xr12, 32
.LASTX:
    xvsrli.h         xr15,    xr15,  1
    DO_FILT_C_LASX xr9, xr8, xr7, xr6
    xvadd.h          xr15,    xr15,  xr15
    xmov             xr7,     xr5
    DO_FILT_H_LASX xr10, xr13, xr11
    addi.d           a4,      a4,    32
    blt              a4,      zero,  .LOOPX
    addi.d           t1,      a4,    -32
    blt              t1,      zero,  .LASTX
    //setup regs for next y
    sub.d            a4,      a4,    a7
    sub.d            a4,      a4,    a2
    sub.d            a1,      a1,    a4
    sub.d            a3,      a3,    a4
    add.d            a0,      a0,    a2
    add.d            t0,      t0,    a2
    add.d            a5,      a5,    a2
    move             a4,      a7
    addi.d           a6,      a6,    -1
    blt              zero,    a6,    .LOOPY
    fld.d            f24,     sp,    0
    fld.d            f25,     sp,    8
    fld.d            f26,     sp,    16
    fld.d            f27,     sp,    24
    fld.d            f28,     sp,    32
    fld.d            f29,     sp,    40
    fld.d            f30,     sp,    48
    addi.d           sp,      sp,    56
endfunc_x264

/*
 * void pixel_avg_wxh(pixel *dst, intptr_t dst_stride, pixel *src1, intptr_t src1_stride,
 *                    pixel *src2, intptr_t src2_stride, int weight);
 */
.macro PIXEL_AVG w, h
function_x264 pixel_avg_\w\()x\h\()_lasx
    addi.d           t0,      a6,    -32
    addi.d           a7,      zero,  \h
    bne              t0,      zero,  x264_8_pixel_avg_weight_w\w\()_lasx
    b                x264_8_pixel_avg_w\w\()_lasx
endfunc_x264
.endm

PIXEL_AVG 16,  8
PIXEL_AVG  8, 16
PIXEL_AVG  8,  8
PIXEL_AVG  8,  4
PIXEL_AVG  4, 16
PIXEL_AVG  4,  8
PIXEL_AVG  4,  4
PIXEL_AVG  4,  2

function_x264 mc_weight_w20_noden_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.b       xr0,     a4,    36   // scale
.LOOP_WEIGHTW20_NODEN:
    xvld             xr3,     a2,    0
    xvldx            xr4,     a2,    a3
    xvmulwev.h.bu.b  xr7,     xr3,   xr0
    xvmulwev.h.bu.b  xr8,     xr4,   xr0
    xvmulwod.h.bu.b  xr3,     xr3,   xr0
    xvmulwod.h.bu.b  xr4,     xr4,   xr0
    xvadd.h          xr7,     xr7,   xr1
    xvadd.h          xr8,     xr8,   xr1
    xvadd.h          xr3,     xr3,   xr1
    xvadd.h          xr4,     xr4,   xr1
    xvssrarni.bu.h   xr8,     xr7,   0
    xvssrarni.bu.h   xr4,     xr3,   0
    xvilvl.b         xr3,     xr4,   xr8
    xvilvh.b         xr4,     xr4,   xr8
    vst              vr3,     a0,    0
    xvstelm.w        xr3,     a0,    16,   4
    add.d            a0,      a0,    a1
    vst              vr4,     a0,    0
    xvstelm.w        xr4,     a0,    16,   4
    alsl.d           a2,      a3,    a2,   1
    add.d            a0,      a0,    a1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW20_NODEN
endfunc_x264

function_x264 mc_weight_w16_noden_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.h       xr0,     a4,    36   // scale
.LOOP_WEIGHTW16_NODEN:
    vld              vr3,     a2,    0
    vldx             vr4,     a2,    a3
    vext2xv.hu.bu    xr3,     xr3
    vext2xv.hu.bu    xr4,     xr4
    xvmul.h          xr3,     xr3,   xr0
    xvmul.h          xr4,     xr4,   xr0
    xvadd.h          xr3,     xr3,   xr1
    xvadd.h          xr4,     xr4,   xr1
    xvssrarni.bu.h   xr4,     xr3,   0
    xvpermi.d        xr3,     xr4,   8
    xvpermi.d        xr4,     xr4,   13
    vst              vr3,     a0,    0
    vstx             vr4,     a0,    a1
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a0,      a1,    a0,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW16_NODEN
endfunc_x264

function_x264 mc_weight_w8_noden_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.h       xr0,     a4,    36   // scale
.LOOP_WEIGHTW8_NODEN:
    fld.d            f3,      a2,    0
    fldx.d           f4,      a2,    a3
    vilvl.d          vr3,     vr4,   vr3
    vext2xv.hu.bu    xr3,     xr3
    xvmul.h          xr3,     xr3,   xr0
    xvadd.h          xr3,     xr3,   xr1
    xvssrarni.bu.h   xr3,     xr3,   0
    xvstelm.d        xr3,     a0,    0,    0
    add.d            a0,      a0,    a1
    xvstelm.d        xr3,     a0,    0,    2
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW8_NODEN
endfunc_x264

function_x264 mc_weight_w4_noden_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.h       xr0,     a4,    36   // scale
.LOOP_WEIGHTW4_NODEN:
    fld.s            f3,      a2,    0
    fldx.s           f4,      a2,    a3
    vilvl.w          vr3,     vr4,   vr3
    vext2xv.hu.bu    xr3,     xr3
    xvmul.h          xr3,     xr3,   xr0
    xvadd.h          xr3,     xr3,   xr1
    xvssrarni.bu.h   xr3,     xr3,   0
    xvstelm.w        xr3,     a0,    0,    0
    add.d            a0,      a0,    a1
    xvstelm.w        xr3,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW4_NODEN
endfunc_x264

function_x264 mc_weight_w20_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.b       xr0,     a4,    36   // scale
    xvldrepl.h       xr2,     a4,    32   // denom
    xvsll.h          xr1,     xr1,   xr2
.LOOP_WEIGHTW20:
    xvld             xr3,     a2,    0
    xvldx            xr4,     a2,    a3
    xvmulwev.h.bu.b  xr7,     xr3,   xr0
    xvmulwev.h.bu.b  xr8,     xr4,   xr0
    xvmulwod.h.bu.b  xr3,     xr3,   xr0
    xvmulwod.h.bu.b  xr4,     xr4,   xr0
    xvsadd.h         xr7,     xr7,   xr1
    xvsadd.h         xr8,     xr8,   xr1
    xvsadd.h         xr3,     xr3,   xr1
    xvsadd.h         xr4,     xr4,   xr1
    xvssrarn.bu.h    xr7,     xr7,   xr2
    xvssrarn.bu.h    xr8,     xr8,   xr2
    xvssrarn.bu.h    xr3,     xr3,   xr2
    xvssrarn.bu.h    xr4,     xr4,   xr2
    xvilvl.b         xr3,     xr3,   xr7
    xvilvl.b         xr4,     xr4,   xr8
    vst              vr3,     a0,    0
    xvstelm.w        xr3,     a0,    16,   4
    add.d            a0,      a0,    a1
    vst              vr4,     a0,    0
    xvstelm.w        xr4,     a0,    16,   4
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW20
endfunc_x264

function_x264 mc_weight_w16_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.h       xr0,     a4,    36   // scale
    xvldrepl.h       xr2,     a4,    32   // denom
    xvsll.h          xr1,     xr1,   xr2
.LOOP_WEIGHTW16:
    vld              vr3,     a2,    0
    vldx             vr4,     a2,    a3
    vext2xv.hu.bu    xr3,     xr3
    vext2xv.hu.bu    xr4,     xr4
    xvmul.h          xr3,     xr3,   xr0
    xvmul.h          xr4,     xr4,   xr0
    xvsadd.h         xr3,     xr3,   xr1
    xvsadd.h         xr4,     xr4,   xr1
    xvssrarn.bu.h    xr3,     xr3,   xr2
    xvssrarn.bu.h    xr4,     xr4,   xr2
    xvpermi.d        xr3,     xr3,   8
    xvpermi.d        xr4,     xr4,   8
    vst              vr3,     a0,    0
    vstx             vr4,     a0,    a1
    alsl.d           a0,      a1,    a0,   1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW16
endfunc_x264

function_x264 mc_weight_w8_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.h       xr0,     a4,    36   // scale
    xvldrepl.h       xr2,     a4,    32   // denom
    xvsll.h          xr1,     xr1,   xr2
.LOOP_WEIGHTW8:
    fld.d            f3,      a2,    0
    fldx.d           f4,      a2,    a3
    vilvl.d          vr3,     vr4,   vr3
    vext2xv.hu.bu    xr3,     xr3
    xvmul.h          xr3,     xr3,   xr0
    xvsadd.h         xr3,     xr3,   xr1
    xvssrarn.bu.h    xr3,     xr3,   xr2
    xvstelm.d        xr3,     a0,    0,    0
    add.d            a0,      a0,    a1
    xvstelm.d        xr3,     a0,    0,    2
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW8
endfunc_x264

function_x264 mc_weight_w4_lasx
    xvldrepl.h       xr1,     a4,    40   // offset
    xvldrepl.h       xr0,     a4,    36   // scale
    xvldrepl.h       xr2,     a4,    32   // denom
    xvsll.h          xr1,     xr1,   xr2
.LOOP_WEIGHTW4:
    fld.s            f3,      a2,    0
    fldx.s           f4,      a2,    a3
    vilvl.w          vr3,     vr4,   vr3
    vext2xv.hu.bu    xr3,     xr3
    xvmul.h          xr3,     xr3,   xr0
    xvsadd.h         xr3,     xr3,   xr1
    xvssrarn.bu.h    xr3,     xr3,   xr2
    xvstelm.w        xr3,     a0,    0,    0
    add.d            a0,      a0,    a1
    xvstelm.w        xr3,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHTW4
endfunc_x264

/*
 * void x264_pixel_avg2_w4(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                         intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w4_lasx
.avg2w4_loop_2:
    addi.d           a5,      a5,    -2
    fld.s            f0,      a2,    0
    fld.s            f1,      a4,    0
    fldx.s           f2,      a2,    a3
    fldx.s           f3,      a4,    a3
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a3,    a4,   1
    vavgr.bu         vr0,     vr0,   vr1
    vavgr.bu         vr1,     vr2,   vr3
    fst.s            f0,      a0,    0
    fstx.s           f1,      a0,    a1
    alsl.d           a0,      a1,    a0,     1
    blt              zero,    a5,    .avg2w4_loop_2
endfunc_x264

/*
 * void x264_pixel_avg2_w8(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                         intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w8_lasx
.avg2w8_loop_2:
    addi.d           a5,      a5,    -2
    fld.d            f0,      a2,    0
    fld.d            f1,      a4,    0
    fldx.d           f2,      a2,    a3
    fldx.d           f3,      a4,    a3
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a3,    a4,   1
    vavgr.bu         vr0,     vr0,   vr1
    vavgr.bu         vr1,     vr2,   vr3
    fst.d            f0,      a0,    0
    fstx.d           f1,      a0,    a1
    alsl.d           a0,      a1,    a0,   1
    blt              zero,    a5,    .avg2w8_loop_2
endfunc_x264

/*
 * void x264_pixel_avg2_w16(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                          intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w16_lasx
.avg2w16_loop_2:
    addi.d           a5,      a5,    -2
    vld              vr0,     a2,    0
    vldx             vr1,     a2,    a3
    vld              vr2,     a4,    0
    vldx             vr3,     a4,    a3
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a3,    a4,   1
    vavgr.bu         vr0,     vr0,   vr2
    vavgr.bu         vr1,     vr1,   vr3
    vst              vr0,     a0,    0
    vstx             vr1,     a0,    a1
    alsl.d           a0,      a1,    a0,   1
    blt              zero,    a5,    .avg2w16_loop_2
endfunc_x264

/*
 * void x264_pixel_avg2_w20(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                          intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w20_lasx
.avg2w20_loop_2:
    addi.d           a5,      a5,    -2
    xvld             xr0,     a2,    0
    xvldx            xr1,     a2,    a3
    xvld             xr2,     a4,    0
    xvldx            xr3,     a4,    a3
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a3,    a4,   1
    xvavgr.bu        xr0,     xr0,   xr2
    xvavgr.bu        xr1,     xr1,   xr3
    vst              vr0,     a0,    0
    xvstelm.w        xr0,     a0,    16,    4
    add.d            a0,      a0,    a1
    vst              vr1,     a0,    0
    xvstelm.w        xr1,     a0,    16,    4
    add.d            a0,      a0,    a1
    blt              zero,    a5,    .avg2w20_loop_2
endfunc_x264

/*
 * void mc_copy_width16( uint8_t *p_dst, int32_t i_dst_stride,
 *                       uint8_t *p_src, int32_t i_src_stride,
 *                       int32_t i_height )
 */
function_x264 mc_copy_w16_lasx
    slli.d            t0,     a3,     1
    add.d             t1,     t0,     a3
    slli.d            t2,     a1,     1
    add.d             t3,     t2,     a1
.LOOP_COPYW16:
    vld               vr1,    a2,    0
    vldx              vr2,    a2,    a3
    vldx              vr3,    a2,    t0
    vldx              vr4,    a2,    t1

    vst               vr1,    a0,    0
    vstx              vr2,    a0,    a1
    vstx              vr3,    a0,    t2
    vstx              vr4,    a0,    t3
    alsl.d            a0,     a1,    a0,   2
    alsl.d            a2,     a3,    a2,   2
    addi.w            a4,     a4,    -4
    blt               zero,   a4,    .LOOP_COPYW16
endfunc_x264

/*
 * void mc_copy_w8( uint8_t *p_dst, intptr_t i_dst_stride,
 *                  uint8_t *p_src, intptr_t i_src_stride,
 *                  int32_t i_height )
 */
function_x264 mc_copy_w8_lasx
    slli.d            t0,     a3,     1
    add.d             t1,     t0,     a3
    slli.d            t2,     a1,     1
    add.d             t3,     t2,     a1
.LOOP_COPYW8:
    fld.d             f0,     a2,     0
    fldx.d            f1,     a2,     a3
    fldx.d            f2,     a2,     t0
    fldx.d            f3,     a2,     t1

    fst.d             f0,     a0,     0
    fstx.d            f1,     a0,     a1
    fstx.d            f2,     a0,     t2
    fstx.d            f3,     a0,     t3
    alsl.d            a0,     a1,     a0,   2
    alsl.d            a2,     a3,     a2,   2
    addi.w            a4,     a4,     -4
    blt               zero,   a4,     .LOOP_COPYW8
endfunc_x264

/*
 * void mc_copy_w4( uint8_t *p_dst, intptr_t i_dst_stride,
 *                  uint8_t *p_src, intptr_t i_src_stride,
 *                  int32_t i_height )
 */
function_x264 mc_copy_w4_lasx
    slli.d            t0,     a3,     1
    add.d             t1,     t0,     a3
    slli.d            t2,     a1,     1
    add.d             t3,     t2,     a1
.LOOP_COPYW4:
    fld.s             f0,     a2,     0
    fldx.s            f1,     a2,     a3
    fldx.s            f2,     a2,     t0
    fldx.s            f3,     a2,     t1

    fst.s             f0,     a0,     0
    fstx.s            f1,     a0,     a1
    fstx.s            f2,     a0,     t2
    fstx.s            f3,     a0,     t3
    alsl.d            a0,     a1,     a0,   2
    alsl.d            a2,     a3,     a2,   2
    addi.w            a4,     a4,     -4
    blt               zero,   a4,     .LOOP_COPYW4
endfunc_x264

/*
 * void memzero_aligned( void *p_dst, size_t n )
 */
function_x264 memzero_aligned_lasx
    xvxor.v          xr1,     xr1,    xr1
.memzero_loop:
    addi.d           a1,      a1,     -128
.rept 4
    xvst             xr1,     a0,     0
    addi.d           a0,      a0,     32
.endr
    blt              zero,    a1,     .memzero_loop
endfunc_x264

/*
 * void frame_init_lowres_core( pixel *src0, pixel *dst0, pixel *dsth,
 *                              pixel *dstv, pixel *dstc, intptr_t src_stride,
 *                              intptr_t dst_stride, int width, int height )
 */
function_x264 frame_init_lowres_core_lasx
    andi             t1,      a7,     15
    sub.w            t0,      a7,     t1
    slli.d           t2,      a5,     1
    ldptr.w          a7,      sp,     0  // use a7 as height variable

.height_loop:
    add.d            t4,      zero,   t0
    addi.d           t3,      a0,     0
    addi.d           t5,      a1,     0
    addi.d           t6,      a2,     0
    addi.d           t7,      a3,     0
    addi.d           t8,      a4,     0
.width16_loop:
    xvld             xr0,     t3,     0
    xvldx            xr1,     t3,     a5
    xvldx            xr2,     t3,     t2
    xvavgr.bu        xr3,     xr0,    xr1
    xvavgr.bu        xr4,     xr1,    xr2
    xvhaddw.hu.bu    xr5,     xr3,    xr3
    xvhaddw.hu.bu    xr6,     xr4,    xr4
    xvssrarni.bu.h   xr6,     xr5,    1
    xvpermi.d        xr7,     xr6,    0xd8
    vst              vr7,     t5,     0
    xvpermi.q        xr7,     xr7,    0x11
    vst              vr7,     t7,     0

    addi.d           t3,      t3,     1
    xvld             xr0,     t3,     0
    xvldx            xr1,     t3,     a5
    xvldx            xr2,     t3,     t2
    xvavgr.bu        xr3,     xr0,    xr1
    xvavgr.bu        xr4,     xr1,    xr2
    xvhaddw.hu.bu    xr5,     xr3,    xr3
    xvhaddw.hu.bu    xr6,     xr4,    xr4
    xvssrarni.bu.h   xr6,     xr5,    1
    xvpermi.d        xr7,     xr6,    0xd8
    vst              vr7,     t6,     0
    xvpermi.q        xr7,     xr7,    0x11
    vst              vr7,     t8,     0
    addi.d           t3,      t3,     31
    addi.d           t5,      t5,     16
    addi.d           t6,      t6,     16
    addi.d           t7,      t7,     16
    addi.d           t8,      t8,     16
    addi.w           t4,      t4,     -16
    blt              zero,    t4,     .width16_loop

    beqz             t1,      .width16_end
    vld              vr0,     t3,     0
    vldx             vr1,     t3,     a5
    vldx             vr2,     t3,     t2
    vavgr.bu         vr3,     vr0,    vr1
    vavgr.bu         vr4,     vr1,    vr2
    vhaddw.hu.bu     vr5,     vr3,    vr3
    vhaddw.hu.bu     vr6,     vr4,    vr4
    vssrarni.bu.h    vr6,     vr5,    1
    fst.d            f6,      t5,     0
    vstelm.d         vr6,     t7,     0,    1

    addi.d           t3,      t3,     1
    vld              vr0,     t3,     0
    vldx             vr1,     t3,     a5
    vldx             vr2,     t3,     t2
    vavgr.bu         vr3,     vr0,    vr1
    vavgr.bu         vr4,     vr1,    vr2
    vhaddw.hu.bu     vr5,     vr3,    vr3
    vhaddw.hu.bu     vr6,     vr4,    vr4
    vssrarni.bu.h    vr6,     vr5,    1
    fst.d            f6,      t6,     0
    vstelm.d         vr6,     t8,     0,    1

.width16_end:
    add.d            a0,      a0,     t2
    add.d            a1,      a1,     a6
    add.d            a2,      a2,     a6
    add.d            a3,      a3,     a6
    add.d            a4,      a4,     a6
    addi.w           a7,      a7,     -1
    blt              zero,    a7,     .height_loop
endfunc_x264

/*
 * void mc_chroma(uint8_t *p_dst_u, uint8_t *p_dst_v,
 *                intptr_t i_dst_stride,
 *                uint8_t *p_src, intptr_t i_src_stride,
 *                int32_t m_vx, int32_t m_vy,
 *                int32_t i_width, int32_t i_height)
 */

function_x264 mc_chroma_lsx
    MC_CHROMA_START
    andi             a5,      a5,     0x07    /* m_vx & 0x07 */
    andi             a6,      a6,     0x07    /* m_vy & 0x07 */
    li.d             t8,      8
    sub.d            t1,      t8,     a5     // 8-d8x
    sub.d            t2,      t8,     a6     // 8-d8y
    mul.d            t3,      t1,     t2     // CA
    mul.d            t4,      a5,     t2     // CB
    mul.d            t5,      t1,     a6     // CC
    mul.d            t6,      a5,     a6     // CD
    vreplgr2vr.b     vr0,     t3
    vreplgr2vr.b     vr1,     t4
    vreplgr2vr.b     vr2,     t5
    vreplgr2vr.b     vr3,     t6

    add.d            t0,      a3,     a4
    ldptr.w          t1,      sp,     0       /* i_height */
    move             t3,      t0
    addi.d           t4,      zero,   1
    addi.d           t5,      zero,   3
    addi.d           t6,      zero,   7
    bge              t6,      a7,     .ENDLOOP_W8
.LOOP_W8:
    vld              vr4,     a3,     0
    vld              vr5,     t0,     0
    vld              vr6,     a3,     2
    vld              vr7,     t0,     2
    vmulwev.h.bu     vr8,     vr4,    vr0
    vmulwod.h.bu     vr9,     vr4,    vr0
    vmulwev.h.bu     vr10,    vr5,    vr2
    vmulwod.h.bu     vr11,    vr5,    vr2
    vmaddwev.h.bu    vr8,     vr6,    vr1
    vmaddwod.h.bu    vr9,     vr6,    vr1
    vmaddwev.h.bu    vr10,    vr7,    vr3
    vmaddwod.h.bu    vr11,    vr7,    vr3
    vadd.h           vr12,    vr8,    vr10
    vadd.h           vr13,    vr9,    vr11
    vssrarni.bu.h    vr13,    vr12,   6
    vstelm.d         vr13,    a0,     0,   0
    vstelm.d         vr13,    a1,     0,   1

    add.d            a0,      a0,     a2
    add.d            a1,      a1,     a2
    addi.d           t1,      t1,     -1
    move             a3,      t3
    add.d            t3,      t3,     a4
    move             t0,      t3
    blt              zero,    t1,     .LOOP_W8
    b                .ENDLOOP_W2
.ENDLOOP_W8:
    bge              t5,      a7,     .ENDLOOP_W4
.LOOP_W4:
    vld              vr4,     a3,     0
    vld              vr5,     t0,     0
    vld              vr6,     a3,     2
    vld              vr7,     t0,     2
    vmulwev.h.bu     vr8,     vr4,    vr0
    vmulwod.h.bu     vr9,     vr4,    vr0
    vmulwev.h.bu     vr10,    vr5,    vr2
    vmulwod.h.bu     vr11,    vr5,    vr2
    vmaddwev.h.bu    vr8,     vr6,    vr1
    vmaddwod.h.bu    vr9,     vr6,    vr1
    vmaddwev.h.bu    vr10,    vr7,    vr3
    vmaddwod.h.bu    vr11,    vr7,    vr3
    vadd.h           vr12,    vr8,    vr10
    vadd.h           vr13,    vr9,    vr11
    vssrarni.bu.h    vr13,    vr12,   6
    vstelm.w         vr13,    a0,     0,   0
    vstelm.w         vr13,    a1,     0,   2

    add.d            a0,      a0,     a2
    add.d            a1,      a1,     a2
    move             a3,      t3
    add.d            t3,      t3,     a4
    move             t0,      t3
    addi.d           t1,      t1,     -1
    blt              zero,    t1,     .LOOP_W4
    b                .ENDLOOP_W2
.ENDLOOP_W4:
    bge              t4,      a7,     .ENDLOOP_W2
.LOOP_W2:
    vld              vr4,     a3,     0
    vld              vr5,     t0,     0
    vld              vr6,     a3,     2
    vld              vr7,     t0,     2
    vmulwev.h.bu     vr8,     vr4,    vr0
    vmulwod.h.bu     vr9,     vr4,    vr0
    vmulwev.h.bu     vr10,    vr5,    vr2
    vmulwod.h.bu     vr11,    vr5,    vr2
    vmaddwev.h.bu    vr8,     vr6,    vr1
    vmaddwod.h.bu    vr9,     vr6,    vr1
    vmaddwev.h.bu    vr10,    vr7,    vr3
    vmaddwod.h.bu    vr11,    vr7,    vr3
    vadd.h           vr12,    vr8,    vr10
    vadd.h           vr13,    vr9,    vr11
    vssrarni.bu.h    vr13,    vr12,   6
    vstelm.h         vr13,    a0,     0,   0
    vstelm.h         vr13,    a1,     0,   4

    add.d            a0,      a0,     a2
    add.d            a1,      a1,     a2
    move             a3,      t3
    add.d            t3,      t3,     a4
    move             t0,      t3
    addi.d           t1,      t1,     -1
    blt              zero,    t1,     .LOOP_W2
.ENDLOOP_W2:
endfunc_x264

function_x264 pixel_avg_weight_w4_lsx
    addi.d           t0,      zero,  64
    sub.d            t0,      t0,    a6
    vreplgr2vr.b     vr0,     a6
    vreplgr2vr.b     vr1,     t0
    vpackev.b        vr8,     vr1,   vr0
.LOOP_AVG_WEIGHT_W4:
    fld.s            f0,      a2,    0
    fldx.s           f1,      a2,    a3
    fld.s            f2,      a4,    0
    fldx.s           f3,      a4,    a5
    vilvl.w          vr0,     vr1,   vr0
    vilvl.w          vr2,     vr3,   vr2
    vilvl.b          vr0,     vr2,   vr0
    vmulwev.h.bu.b   vr1,     vr0,   vr8
    vmaddwod.h.bu.b  vr1,     vr0,   vr8
    vssrarni.bu.h    vr1,     vr1,   6
    fst.s            f1,      a0,    0
    add.d            a0,      a0,    a1
    vstelm.w         vr1,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a5,    a4,   1
    addi.w           a7,      a7,    -2
    bnez             a7,      .LOOP_AVG_WEIGHT_W4
endfunc_x264

function_x264 pixel_avg_w4_lsx
.LOOP_AVG_W4:
    fld.s            f0,      a2,    0
    fldx.s           f1,      a2,    a3
    fld.s            f4,      a4,    0
    fldx.s           f5,      a4,    a5
    vilvl.w          vr0,     vr1,   vr0
    vilvl.w          vr4,     vr5,   vr4
    vavgr.bu         vr0,     vr0,   vr4
    fst.s            f0,      a0,    0
    add.d            a0,      a0,    a1
    vstelm.w         vr0,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a5,    a4,   1
    addi.w           a7,      a7,    -2
    bnez             a7,      .LOOP_AVG_W4
endfunc_x264

function_x264 pixel_avg_weight_w8_lsx
    addi.d           t0,      zero,  64
    sub.d            t0,      t0,    a6
    slli.d           t5,      a1,    1
    add.d            t6,      a1,    t5
    add.d            t7,      a1,    t6
    vreplgr2vr.b     vr0,     a6
    vreplgr2vr.b     vr1,     t0
    vpackev.b        vr8,     vr1,   vr0
    PIXEL_AVG_START_W8
.LOOP_AVG_HEIGHT_W8:
    fld.d            f0,      a2,    0
    fldx.d           f1,      a2,    a3
    fldx.d           f2,      a2,    t0
    fldx.d           f3,      a2,    t1
    fld.d            f4,      a4,    0
    fldx.d           f5,      a4,    a5
    fldx.d           f6,      a4,    t3
    fldx.d           f7,      a4,    t4
    vilvl.b          vr0,     vr4,   vr0
    vilvl.b          vr1,     vr5,   vr1
    vilvl.b          vr2,     vr6,   vr2
    vilvl.b          vr3,     vr7,   vr3
    vmulwev.h.bu.b   vr4,     vr0,   vr8
    vmulwev.h.bu.b   vr5,     vr1,   vr8
    vmulwev.h.bu.b   vr6,     vr2,   vr8
    vmulwev.h.bu.b   vr7,     vr3,   vr8
    vmaddwod.h.bu.b  vr4,     vr0,   vr8
    vmaddwod.h.bu.b  vr5,     vr1,   vr8
    vmaddwod.h.bu.b  vr6,     vr2,   vr8
    vmaddwod.h.bu.b  vr7,     vr3,   vr8
    vssrarni.bu.h    vr4,     vr4,   6
    vssrarni.bu.h    vr5,     vr5,   6
    vssrarni.bu.h    vr6,     vr6,   6
    vssrarni.bu.h    vr7,     vr7,   6
    fst.d            f4,      a0,    0
    fstx.d           f5,      a0,    a1
    fstx.d           f6,      a0,    t5
    fstx.d           f7,      a0,    t6
    add.d            a0,      a0,    t7
    alsl.d           a2,      a3,    a2,   2
    alsl.d           a4,      a5,    a4,   2
    addi.w           a7,      a7,    -4
    bnez             a7,      .LOOP_AVG_HEIGHT_W8
endfunc_x264

function_x264 pixel_avg_w8_lsx
    PIXEL_AVG_START_W8
.LOOP_AVG_W8:
    fld.d            f0,      a2,    0
    fldx.d           f1,      a2,    a3
    fldx.d           f2,      a2,    t0
    fldx.d           f3,      a2,    t1
    fld.d            f4,      a4,    0
    fldx.d           f5,      a4,    a5
    fldx.d           f6,      a4,    t3
    fldx.d           f7,      a4,    t4
    vilvl.d          vr0,     vr1,   vr0
    vilvl.d          vr2,     vr3,   vr2
    vilvl.d          vr4,     vr5,   vr4
    vilvl.d          vr6,     vr7,   vr6
    vavgr.bu         vr0,     vr0,   vr4
    vavgr.bu         vr2,     vr2,   vr6
    fst.d            f0,      a0,    0
    add.d            a0,      a0,    a1
    vstelm.d         vr0,     a0,    0,    1
    fstx.d           f2,      a0,    a1
    alsl.d           a0,      a1,    a0,   1
    vstelm.d         vr2,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   2
    alsl.d           a4,      a5,    a4,   2
    addi.w           a7,      a7,    -4
    bnez             a7,      .LOOP_AVG_W8
endfunc_x264

function_x264 pixel_avg_weight_w16_lsx
    addi.d           t0,      zero,  64
    sub.d            t0,      t0,    a6
    vreplgr2vr.b     vr8,     a6
    vreplgr2vr.b     vr9,     t0
    PIXEL_AVG_START
.LOOP_AVG_HEIGHT_W16:
    LSX_LOADX_4 a2, a3, t0, t1, vr0, vr1, vr2, vr3
    LSX_LOADX_4 a4, a5, t3, t4, vr4, vr5, vr6, vr7

    vmulwev.h.bu.b   vr10,    vr0,   vr8
    vmulwev.h.bu.b   vr11,    vr1,   vr8
    vmulwev.h.bu.b   vr12,    vr2,   vr8
    vmulwev.h.bu.b   vr13,    vr3,   vr8
    vmulwod.h.bu.b   vr14,    vr0,   vr8
    vmulwod.h.bu.b   vr15,    vr1,   vr8
    vmulwod.h.bu.b   vr16,    vr2,   vr8
    vmulwod.h.bu.b   vr17,    vr3,   vr8
    vmaddwev.h.bu.b  vr10,    vr4,   vr9
    vmaddwev.h.bu.b  vr11,    vr5,   vr9
    vmaddwev.h.bu.b  vr12,    vr6,   vr9
    vmaddwev.h.bu.b  vr13,    vr7,   vr9
    vmaddwod.h.bu.b  vr14,    vr4,   vr9
    vmaddwod.h.bu.b  vr15,    vr5,   vr9
    vmaddwod.h.bu.b  vr16,    vr6,   vr9
    vmaddwod.h.bu.b  vr17,    vr7,   vr9
    vssrarni.bu.h    vr11,    vr10,  6
    vssrarni.bu.h    vr13,    vr12,  6
    vssrarni.bu.h    vr15,    vr14,  6
    vssrarni.bu.h    vr17,    vr16,  6
    vilvl.b          vr10,    vr15,  vr11
    vilvh.b          vr11,    vr15,  vr11
    vilvl.b          vr12,    vr17,  vr13
    vilvh.b          vr13,    vr17,  vr13

    vst              vr10,    a0,    0
    vstx             vr11,    a0,    a1
    vstx             vr12,    a0,    t6
    vstx             vr13,    a0,    t7
    add.d            a2,      a2,    t2
    add.d            a4,      a4,    t5
    add.d            a0,      a0,    t8
    addi.d           a7,      a7,    -4
    bnez             a7,      .LOOP_AVG_HEIGHT_W16
endfunc_x264

function_x264 pixel_avg_w16_lsx
    PIXEL_AVG_START
.LOOP_AVG_W16:
    vld              vr0,     a2,    0
    vldx             vr1,     a2,    a3
    vldx             vr2,     a2,    t0
    vldx             vr3,     a2,    t1
    vld              vr4,     a4,    0
    vldx             vr5,     a4,    a5
    vldx             vr6,     a4,    t3
    vldx             vr7,     a4,    t4
    vavgr.bu         vr0,     vr0,   vr4
    vavgr.bu         vr1,     vr1,   vr5
    vavgr.bu         vr2,     vr2,   vr6
    vavgr.bu         vr3,     vr3,   vr7
    vst              vr0,     a0,    0
    vstx             vr1,     a0,    a1
    vstx             vr2,     a0,    t6
    vstx             vr3,     a0,    t7
    add.d            a0,      a0,    t8
    add.d            a2,      a2,    t2
    add.d            a4,      a4,    t5

    vld              vr0,     a2,    0
    vldx             vr1,     a2,    a3
    vldx             vr2,     a2,    t0
    vldx             vr3,     a2,    t1
    vld              vr4,     a4,    0
    vldx             vr5,     a4,    a5
    vldx             vr6,     a4,    t3
    vldx             vr7,     a4,    t4
    vavgr.bu         vr0,     vr0,   vr4
    vavgr.bu         vr1,     vr1,   vr5
    vavgr.bu         vr2,     vr2,   vr6
    vavgr.bu         vr3,     vr3,   vr7
    vst              vr0,     a0,    0
    vstx             vr1,     a0,    a1
    vstx             vr2,     a0,    t6
    vstx             vr3,     a0,    t7
    add.d            a2,      a2,    t2
    add.d            a4,      a4,    t5
    add.d            a0,      a0,    t8
    addi.d           a7,      a7,    -8
    bnez             a7,      .LOOP_AVG_W16
endfunc_x264

/*
 * void pixel_avg_wxh(pixel *dst, intptr_t dst_stride, pixel *src1, intptr_t src1_stride,
 *                    pixel *src2, intptr_t src2_stride, int weight);
 */
.macro PIXEL_AVG_LSX w, h
function_x264 pixel_avg_\w\()x\h\()_lsx
    addi.d           t0,      a6,    -32
    addi.d           a7,      zero,  \h
    bne              t0,      zero,  x264_8_pixel_avg_weight_w\w\()_lsx
    b                x264_8_pixel_avg_w\w\()_lsx
endfunc_x264
.endm

PIXEL_AVG_LSX 16, 16
PIXEL_AVG_LSX 16,  8
PIXEL_AVG_LSX  8, 16
PIXEL_AVG_LSX  8,  8
PIXEL_AVG_LSX  8,  4
PIXEL_AVG_LSX  4, 16
PIXEL_AVG_LSX  4,  8
PIXEL_AVG_LSX  4,  4
PIXEL_AVG_LSX  4,  2

function_x264 mc_weight_w20_noden_lsx
    vldrepl.b        vr0,     a4,    36   // scale
    vldrepl.h        vr1,     a4,    40   // offset
.LOOP_WEIGHT_W20_NODEN:
    vld              vr3,     a2,    0
    vld              vr4,     a2,    16
    add.d            a2,      a2,    a3
    vld              vr5,     a2,    0
    vld              vr6,     a2,    16
    vilvl.w          vr4,     vr6,   vr4
    vmulwev.h.bu.b   vr7,     vr3,   vr0
    vmulwod.h.bu.b   vr8,     vr3,   vr0
    vmulwev.h.bu.b   vr9,     vr4,   vr0
    vmulwod.h.bu.b   vr10,    vr4,   vr0
    vmulwev.h.bu.b   vr11,    vr5,   vr0
    vmulwod.h.bu.b   vr12,    vr5,   vr0
    vadd.h           vr7,     vr7,   vr1
    vadd.h           vr8,     vr8,   vr1
    vadd.h           vr9,     vr9,   vr1
    vadd.h           vr10,    vr10,  vr1
    vadd.h           vr11,    vr11,  vr1
    vadd.h           vr12,    vr12,  vr1
    vssrani.bu.h     vr11,    vr7,   0
    vssrani.bu.h     vr12,    vr8,   0
    vssrani.bu.h     vr9,     vr9,   0
    vssrani.bu.h     vr10,    vr10,  0
    vilvl.b          vr7,     vr12,  vr11
    vilvl.b          vr9,     vr10,  vr9
    vilvh.b          vr11,    vr12,  vr11

    vst              vr7,     a0,     0
    vstelm.w         vr9,     a0,     16,    0
    add.d            a0,      a0,     a1
    vst              vr11,    a0,     0
    vstelm.w         vr9,     a0,     16,    1
    add.d            a0,      a0,     a1
    add.d            a2,      a2,     a3
    addi.w           a5,      a5,     -2
    blt              zero,    a5,     .LOOP_WEIGHT_W20_NODEN
endfunc_x264

function_x264 mc_weight_w16_noden_lsx
    vldrepl.b        vr0,     a4,    36   // scale
    vldrepl.h        vr1,     a4,    40   // offset
.LOOP_WEIGHT_W16_NODEN:
    vld              vr3,     a2,    0
    vldx             vr4,     a2,    a3
    vmulwev.h.bu.b   vr5,     vr3,   vr0
    vmulwod.h.bu.b   vr6,     vr3,   vr0
    vmulwev.h.bu.b   vr7,     vr4,   vr0
    vmulwod.h.bu.b   vr8,     vr4,   vr0
    vadd.h           vr5,     vr5,   vr1
    vadd.h           vr6,     vr6,   vr1
    vadd.h           vr7,     vr7,   vr1
    vadd.h           vr8,     vr8,   vr1
    vssrani.bu.h     vr7,     vr5,   0
    vssrani.bu.h     vr8,     vr6,   0
    vilvl.b          vr5,     vr8,   vr7
    vilvh.b          vr7,     vr8,   vr7
    vst              vr5,     a0,    0
    vstx             vr7,     a0,    a1
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a0,      a1,    a0,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHT_W16_NODEN
endfunc_x264

function_x264 mc_weight_w8_noden_lsx
    vldrepl.b        vr0,     a4,    36   // scale
    vldrepl.h        vr1,     a4,    40   // offset
.LOOP_WEIGHT_W8_NODEN:
    fld.d            f3,      a2,    0
    fldx.d           f4,      a2,    a3
    vilvl.d          vr3,     vr4,   vr3
    vmulwev.h.bu.b   vr5,     vr3,   vr0
    vmulwod.h.bu.b   vr6,     vr3,   vr0
    vadd.h           vr5,     vr5,   vr1
    vadd.h           vr6,     vr6,   vr1
    vssrani.bu.h     vr5,     vr5,   0
    vssrani.bu.h     vr6,     vr6,   0
    vilvl.b          vr7,     vr6,   vr5
    vstelm.d         vr7,     a0,    0,    0
    add.d            a0,      a0,    a1
    vstelm.d         vr7,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHT_W8_NODEN
endfunc_x264

function_x264 mc_weight_w4_noden_lsx
    vldrepl.h        vr0,     a4,    36   // scale
    vldrepl.h        vr1,     a4,    40   // offset
.LOOP_WEIGHT_W4_NODEN:
    fld.s            f3,      a2,    0
    fldx.s           f4,      a2,    a3
    vilvl.w          vr3,     vr4,   vr3
    vsllwil.hu.bu    vr3,     vr3,   0
    vmul.h           vr3,     vr3,   vr0
    vadd.h           vr3,     vr3,   vr1
    vssrani.bu.h     vr3,     vr3,   0
    vstelm.w         vr3,     a0,    0,    0
    add.d            a0,      a0,    a1
    vstelm.w         vr3,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHT_W4_NODEN
endfunc_x264

function_x264 mc_weight_w20_lsx
    vldrepl.h        vr1,     a4,    40   // offset
    vldrepl.b        vr0,     a4,    36   // scale
    vldrepl.h        vr2,     a4,    32   // denom
    vsll.h           vr1,     vr1,   vr2
.LOOP_WEIGHT_W20:
    vld              vr3,     a2,    0
    vld              vr4,     a2,    16
    add.d            a2,      a2,    a3
    vld              vr5,     a2,    0
    vld              vr6,     a2,    16
    vilvl.w          vr4,     vr6,   vr4

    vmulwev.h.bu.b   vr7,     vr3,   vr0
    vmulwod.h.bu.b   vr8,     vr3,   vr0
    vmulwev.h.bu.b   vr9,     vr4,   vr0
    vmulwod.h.bu.b   vr10,    vr4,   vr0
    vmulwev.h.bu.b   vr11,    vr5,   vr0
    vmulwod.h.bu.b   vr12,    vr5,   vr0
    vsadd.h          vr7,     vr7,   vr1
    vsadd.h          vr8,     vr8,   vr1
    vsadd.h          vr9,     vr9,   vr1
    vsadd.h          vr10,    vr10,  vr1
    vsadd.h          vr11,    vr11,  vr1
    vsadd.h          vr12,    vr12,  vr1
    vssrarn.bu.h     vr7,     vr7,   vr2
    vssrarn.bu.h     vr8,     vr8,   vr2
    vssrarn.bu.h     vr9,     vr9,   vr2
    vssrarn.bu.h     vr10,    vr10,  vr2
    vssrarn.bu.h     vr11,    vr11,  vr2
    vssrarn.bu.h     vr12,    vr12,  vr2
    vilvl.b          vr7,     vr8,   vr7
    vilvl.b          vr9,     vr10,  vr9
    vilvl.b          vr11,    vr12,  vr11

    vst              vr7,     a0,     0
    vstelm.w         vr9,     a0,     16,    0
    add.d            a0,      a0,     a1
    vst              vr11,    a0,     0
    vstelm.w         vr9,     a0,     16,    1
    add.d            a0,      a0,     a1
    add.d            a2,      a2,     a3
    addi.w           a5,      a5,     -2
    blt              zero,    a5,     .LOOP_WEIGHT_W20
endfunc_x264

function_x264 mc_weight_w16_lsx
    vldrepl.h        vr1,     a4,    40   // offset
    vldrepl.b        vr0,     a4,    36   // scale
    vldrepl.h        vr2,     a4,    32   // denom
    vsll.h           vr1,     vr1,   vr2
.LOOP_WEIGHT_W16:
    vld              vr3,     a2,    0
    vldx             vr4,     a2,    a3
    vmulwev.h.bu.b   vr5,     vr3,   vr0
    vmulwod.h.bu.b   vr6,     vr3,   vr0
    vmulwev.h.bu.b   vr7,     vr4,   vr0
    vmulwod.h.bu.b   vr8,     vr4,   vr0
    vsadd.h          vr5,     vr5,   vr1
    vsadd.h          vr6,     vr6,   vr1
    vsadd.h          vr7,     vr7,   vr1
    vsadd.h          vr8,     vr8,   vr1
    vssrarn.bu.h     vr5,     vr5,   vr2
    vssrarn.bu.h     vr6,     vr6,   vr2
    vssrarn.bu.h     vr7,     vr7,   vr2
    vssrarn.bu.h     vr8,     vr8,   vr2
    vilvl.b          vr5,     vr6,   vr5
    vilvl.b          vr7,     vr8,   vr7
    vst              vr5,     a0,    0
    vstx             vr7,     a0,    a1
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a0,      a1,    a0,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHT_W16
endfunc_x264

function_x264 mc_weight_w8_lsx
    vldrepl.h        vr1,     a4,    40   // offset
    vldrepl.b        vr0,     a4,    36   // scale
    vldrepl.h        vr2,     a4,    32   // denom
    vsll.h           vr1,     vr1,   vr2
.LOOP_WEIGHT_W8:
    fld.d            f3,      a2,    0
    fldx.d           f4,      a2,    a3
    vilvl.d          vr3,     vr4,   vr3
    vmulwev.h.bu.b   vr5,     vr3,   vr0
    vmulwod.h.bu.b   vr6,     vr3,   vr0
    vsadd.h          vr5,     vr5,   vr1
    vsadd.h          vr6,     vr6,   vr1
    vssrarn.bu.h     vr5,     vr5,   vr2
    vssrarn.bu.h     vr6,     vr6,   vr2
    vilvl.b          vr7,     vr6,   vr5
    vstelm.d         vr7,     a0,    0,    0
    add.d            a0,      a0,    a1
    vstelm.d         vr7,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHT_W8
endfunc_x264

function_x264 mc_weight_w4_lsx
    vldrepl.h        vr1,     a4,    40   // offset
    vldrepl.h        vr0,     a4,    36   // scale
    vldrepl.h        vr2,     a4,    32   // denom
    vsll.h           vr1,     vr1,   vr2
.LOOP_WEIGHT_W4:
    fld.s            f3,      a2,    0
    fldx.s           f4,      a2,    a3
    vilvl.w          vr3,     vr4,   vr3
    vsllwil.hu.bu    vr3,     vr3,   0
    vmul.h           vr3,     vr3,   vr0
    vsadd.h          vr3,     vr3,   vr1
    vssrarn.bu.h     vr3,     vr3,   vr2
    vstelm.w         vr3,     a0,    0,    0
    add.d            a0,      a0,    a1
    vstelm.w         vr3,     a0,    0,    1
    add.d            a0,      a0,    a1
    alsl.d           a2,      a3,    a2,   1
    addi.w           a5,      a5,    -2
    blt              zero,    a5,    .LOOP_WEIGHT_W4
endfunc_x264

/*
 * void x264_pixel_avg2_w4(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                         intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w4_lsx
.LOOP_AVG2_W4:
    addi.d           a5,      a5,    -2
    fld.s            f0,      a2,    0
    fld.s            f1,      a4,    0
    fldx.s           f2,      a2,    a3
    fldx.s           f3,      a4,    a3
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a3,    a4,   1
    vavgr.bu         vr0,     vr0,   vr1
    vavgr.bu         vr1,     vr2,   vr3
    fst.s            f0,      a0,    0
    fstx.s           f1,      a0,    a1
    alsl.d           a0,      a1,    a0,   1
    blt              zero,    a5,    .LOOP_AVG2_W4
endfunc_x264

/*
 * void x264_pixel_avg2_w8(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                         intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w8_lsx
.LOOP_AVG2_W8:
    addi.d           a5,      a5,    -2
    fld.d            f0,      a2,    0
    fld.d            f1,      a4,    0
    fldx.d           f2,      a2,    a3
    fldx.d           f3,      a4,    a3
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a3,    a4,   1
    vavgr.bu         vr0,     vr0,   vr1
    vavgr.bu         vr1,     vr2,   vr3
    fst.d            f0,      a0,    0
    fstx.d           f1,      a0,    a1
    alsl.d           a0,      a1,    a0,   1
    blt              zero,    a5,    .LOOP_AVG2_W8
endfunc_x264

/*
 * void x264_pixel_avg2_w16(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                          intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w16_lsx
.LOOP_AVG2_W16:
    addi.d           a5,      a5,    -2
    vld              vr0,     a2,    0
    vldx             vr1,     a2,    a3
    vld              vr2,     a4,    0
    vldx             vr3,     a4,    a3
    alsl.d           a2,      a3,    a2,   1
    alsl.d           a4,      a3,    a4,   1
    vavgr.bu         vr0,     vr0,   vr2
    vavgr.bu         vr1,     vr1,   vr3
    vst              vr0,     a0,    0
    vstx             vr1,     a0,    a1
    alsl.d           a0,      a1,    a0,   1
    blt              zero,    a5,    .LOOP_AVG2_W16
endfunc_x264

/*
 * void x264_pixel_avg2_w20(uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
 *                          intptr_t i_src_stride, uint8_t *src2, int i_height)
 */
function_x264 pixel_avg2_w20_lsx
.LOOP_AVG2_W20:
    addi.d           a5,      a5,    -2
    vld              vr0,     a2,    0
    vld              vr1,     a2,    16
    vld              vr2,     a4,    0
    vld              vr3,     a4,    16
    add.d            a2,      a2,    a3
    add.d            a4,      a4,    a3
    vld              vr4,     a2,    0
    vld              vr5,     a2,    16
    vld              vr6,     a4,    0
    vld              vr7,     a4,    16
    vavgr.bu         vr0,     vr0,   vr2
    vavgr.bu         vr1,     vr1,   vr3
    vavgr.bu         vr4,     vr4,   vr6
    vavgr.bu         vr5,     vr5,   vr7

    vst              vr0,     a0,    0
    vstelm.w         vr1,     a0,    16,   0
    add.d            a0,      a0,    a1
    vst              vr4,     a0,    0
    vstelm.w         vr5,     a0,    16,   0
    add.d            a2,      a2,    a3
    add.d            a4,      a4,    a3
    add.d            a0,      a0,    a1
    blt              zero,    a5,    .LOOP_AVG2_W20
endfunc_x264

/*
 * void mc_copy_width16( uint8_t *p_dst, int32_t i_dst_stride,
 *                       uint8_t *p_src, int32_t i_src_stride,
 *                       int32_t i_height )
 */
function_x264 mc_copy_w16_lsx
    slli.d            t0,     a3,     1
    add.d             t1,     t0,     a3
    slli.d            t2,     a1,     1
    add.d             t3,     t2,     a1
.LOOP_COPY_W16:
    vld               vr1,    a2,     0
    vldx              vr2,    a2,     a3
    vldx              vr3,    a2,     t0
    vldx              vr4,    a2,     t1

    vst               vr1,    a0,     0
    vstx              vr2,    a0,     a1
    vstx              vr3,    a0,     t2
    vstx              vr4,    a0,     t3
    alsl.d            a0,     a1,     a0,   2
    alsl.d            a2,     a3,     a2,   2
    addi.w            a4,     a4,     -4
    blt               zero,   a4,     .LOOP_COPY_W16
endfunc_x264

/*
 * void mc_copy_w8(uint8_t *p_dst, intptr_t i_dst_stride,
 *                 uint8_t *p_src, intptr_t i_src_stride,
 *                 int32_t i_height)
 */
function_x264 mc_copy_w8_lsx
    slli.d            t0,     a3,     1
    add.d             t1,     t0,     a3
    slli.d            t2,     a1,     1
    add.d             t3,     t2,     a1
.LOOP_COPY_W8:
    fld.d             f0,     a2,     0
    fldx.d            f1,     a2,     a3
    fldx.d            f2,     a2,     t0
    fldx.d            f3,     a2,     t1

    fst.d             f0,     a0,     0
    fstx.d            f1,     a0,     a1
    fstx.d            f2,     a0,     t2
    fstx.d            f3,     a0,     t3
    alsl.d            a0,     a1,     a0,   2
    alsl.d            a2,     a3,     a2,   2
    addi.w            a4,     a4,     -4
    blt               zero,   a4,     .LOOP_COPY_W8
endfunc_x264

/*
 * void mc_copy_w4(uint8_t *p_dst, intptr_t i_dst_stride,
 *                 uint8_t *p_src, intptr_t i_src_stride,
 *                 int32_t i_height)
 */
function_x264 mc_copy_w4_lsx
    slli.d            t0,     a3,     1
    add.d             t1,     t0,     a3
    slli.d            t2,     a1,     1
    add.d             t3,     t2,     a1
.LOOP_COPY_W4:
    fld.s             f0,     a2,     0
    fldx.s            f1,     a2,     a3
    fldx.s            f2,     a2,     t0
    fldx.s            f3,     a2,     t1

    fst.s             f0,     a0,     0
    fstx.s            f1,     a0,     a1
    fstx.s            f2,     a0,     t2
    fstx.s            f3,     a0,     t3
    alsl.d            a0,     a1,     a0,   2
    alsl.d            a2,     a3,     a2,   2
    addi.w            a4,     a4,     -4
    blt               zero,   a4,     .LOOP_COPY_W4
endfunc_x264

/*
 * void store_interleave_chroma(uint8_t *p_dst, intptr_t i_dst_stride,
 *                              uint8_t *p_src0, uint8_t *p_src1,
 *                              int32_t i_height)
 */
function_x264 store_interleave_chroma_lsx
.loop_interleave_chroma:
    fld.d             f0,     a2,    0
    fld.d             f1,     a3,    0
    addi.d            a2,     a2,    FDEC_STRIDE
    addi.d            a3,     a3,    FDEC_STRIDE
    vilvl.b           vr0,    vr1,   vr0
    vst               vr0,    a0,    0
    add.d             a0,     a0,    a1
    addi.w            a4,     a4,    -1
    blt               zero,   a4,    .loop_interleave_chroma
endfunc_x264

/*
 * void load_deinterleave_chroma_fenc(pixel *dst, pixel *src,
 *                                    intptr_t i_src, int height)
 */
function_x264 load_deinterleave_chroma_fenc_lsx
    addi.d            t0,     a0,     FENC_STRIDE/2
    andi              t1,     a3,     1
    sub.w             t2,     a3,     t1
.loop_deinterleave_fenc:
    vld               vr0,    a1,     0
    vldx              vr1,    a1,     a2
    vpickev.b         vr2,    vr1,    vr0
    vpickod.b         vr3,    vr1,    vr0
    fst.d             f2,     a0,     0
    fst.d             f3,     t0,     0
    vstelm.d          vr2,    a0,     FENC_STRIDE,   1
    vstelm.d          vr3,    t0,     FENC_STRIDE,   1
    addi.d            a0,     a0,     FENC_STRIDE * 2
    addi.d            t0,     t0,     FENC_STRIDE * 2
    alsl.d            a1,     a2,     a1,    1
    addi.w            t2,     t2,     -2
    blt               zero,   t2,     .loop_deinterleave_fenc

    beqz              t1,     .loop_deinterleave_fenc_end
    vld               vr0,    a1,     0
    vpickev.b         vr1,    vr0,    vr0
    vpickod.b         vr2,    vr0,    vr0
    fst.d             f1,     a0,     0
    fst.d             f2,     t0,     0
.loop_deinterleave_fenc_end:
endfunc_x264

/*
 * void load_deinterleave_chroma_fdec(pixel *dst, pixel *src,
 *                                    intptr_t i_src, int height)
 */
function_x264 load_deinterleave_chroma_fdec_lsx
    addi.d            t0,     a0,     FDEC_STRIDE/2
    andi              t1,     a3,     1
    sub.w             t2,     a3,     t1
.loop_deinterleave_fdec:
    vld               vr0,    a1,     0
    vldx              vr1,    a1,     a2
    vpickev.b         vr2,    vr1,    vr0
    vpickod.b         vr3,    vr1,    vr0
    fst.d             f2,     a0,     0
    fst.d             f3,     t0,     0
    vstelm.d          vr2,    a0,     FDEC_STRIDE,   1
    vstelm.d          vr3,    t0,     FDEC_STRIDE,   1
    addi.d            a0,     a0,     FDEC_STRIDE * 2
    addi.d            t0,     t0,     FDEC_STRIDE * 2
    alsl.d            a1,     a2,     a1,    1
    addi.w            t2,     t2,     -2
    blt               zero,   t2,     .loop_deinterleave_fdec

    beqz              t1,     .loop_deinterleave_fdec_end
    vld               vr0,    a1,     0
    vpickev.b         vr1,    vr0,    vr0
    vpickod.b         vr2,    vr0,    vr0
    fst.d             f1,     a0,     0
    fst.d             f2,     t0,     0
.loop_deinterleave_fdec_end:
endfunc_x264

/*
 * x264_plane_copy_interleave(pixel *dst,  intptr_t i_dst,
 *                            pixel *srcu, intptr_t i_srcu,
 *                            pixel *srcv, intptr_t i_srcv, int w, int h)
 */
function_x264 plane_copy_interleave_core_lsx
.loop_h:
    add.d             t0,     a0,     zero
    add.d             t2,     a2,     zero
    add.d             t4,     a4,     zero
    add.d             t6,     a6,     zero
.loop_copy_interleavew16:
    vld               vr0,    t2,     0
    vld               vr1,    t4,     0
    vilvl.b           vr2,    vr1,    vr0
    vilvh.b           vr3,    vr1,    vr0
    vst               vr2,    t0,     0
    vst               vr3,    t0,     16
    addi.d            t2,     t2,     16
    addi.d            t4,     t4,     16
    addi.d            t0,     t0,     32
    addi.w            t6,     t6,     -16
    blt               zero,   t6,     .loop_copy_interleavew16

    add.d             a2,     a2,     a3
    add.d             a4,     a4,     a5
    add.d             a0,     a0,     a1
    addi.w            a7,     a7,     -1
    blt               zero,   a7,     .loop_h
endfunc_x264

/*
 * void x264_plane_copy_deinterleave(pixel *dsta, intptr_t i_dsta,
 *                                   pixel *dstb, intptr_t i_dstb,
 *                                   pixel *src,  intptr_t i_src, int w, int h)
 */
function_x264 plane_copy_deinterleave_lsx
.LOOP_PLANE_COPY_H:
    add.d             t0,     a0,     zero
    add.d             t2,     a2,     zero
    add.d             t4,     a4,     zero
    add.d             t6,     a6,     zero
.LOOP_PLANE_COPY_W16:
    vld               vr0,    t4,     0
    vld               vr1,    t4,     16
    vpickev.b         vr2,    vr1,    vr0
    vpickod.b         vr3,    vr1,    vr0
    vst               vr2,    t0,     0
    vst               vr3,    t2,     0
    addi.d            t4,     t4,     32
    addi.d            t0,     t0,     16
    addi.d            t2,     t2,     16
    addi.w            t6,     t6,     -16
    blt               zero,   t6,     .LOOP_PLANE_COPY_W16

    add.d             a2,     a2,     a3
    add.d             a4,     a4,     a5
    add.d             a0,     a0,     a1
    addi.w            a7,     a7,     -1
    blt               zero,   a7,     .LOOP_PLANE_COPY_H
endfunc_x264

function_x264 plane_copy_deinterleave_lasx
.LOOP_PLANE_COPY_H_LASX:
    add.d             t0,     a0,     zero
    add.d             t2,     a2,     zero
    add.d             t4,     a4,     zero
    add.d             t6,     a6,     zero
.LOOP_PLANE_COPY_W32_LASX:
    xvld              xr0,    t4,     0
    xvld              xr1,    t4,     32
    xvpickev.b        xr2,    xr1,    xr0
    xvpickod.b        xr3,    xr1,    xr0
    xvpermi.d         xr2,    xr2,    0xd8
    xvpermi.d         xr3,    xr3,    0xd8
    xvst              xr2,    t0,     0
    xvst              xr3,    t2,     0
    addi.d            t4,     t4,     64
    addi.d            t0,     t0,     32
    addi.d            t2,     t2,     32
    addi.w            t6,     t6,     -32
    blt               zero,   t6,     .LOOP_PLANE_COPY_W32_LASX

    add.d             a2,     a2,     a3
    add.d             a4,     a4,     a5
    add.d             a0,     a0,     a1
    addi.w            a7,     a7,     -1
    blt               zero,   a7,     .LOOP_PLANE_COPY_H_LASX
endfunc_x264

/*
 * void prefetch_ref(uint8_t *pix, intptr_t stride, int32_t parity)
 */
function_x264 prefetch_ref_lsx
    addi.d            a2,     a2,     -1
    addi.d            a0,     a0,     64
    and               a2,     a2,     a1
    alsl.d            t1,     a2,     a0,   3
    alsl.d            a2,     a1,     a1,   1
    preld             0,      t1,     0
    add.d             t2,     t1,     a1
    preld             0,      t2,     0
    add.d             t2,     t2,     a1
    preld             0,      t2,     0
    add.d             t1,     t1,     a2
    preld             0,      t1,     0
    alsl.d            a0,     a1,     t2,   1
    preld             0,      a0,     0
    add.d             t1,     a0,     a1
    preld             0,      t1,     0
    add.d             t1,     t1,     a1
    preld             0,      t1,     0
    add.d             a0,     a0,     a2
    preld             0,      a0,     0
endfunc_x264

/*
 * void prefetch_fenc_422(uint8_t *pix_y, intptr_t stride_y,
 *                        uint8_t *pix_uv, intptr_t stride_uv,
 *                        int32_t mb_x)
 */
function_x264 prefetch_fenc_422_lsx
    andi              t0,     a4,     3
    mul.d             t0,     t0,     a1
    andi              a4,     a4,     6
    mul.d             t1,     a4,     a3
    addi.d            a0,     a0,     64
    addi.d            a2,     a2,     64
    alsl.d            a0,     t0,     a0,   2
    preld             0,      a0,     0
    add.d             t2,     a0,     a1
    preld             0,      t2,     0
    add.d             a0,     t2,     a1
    preld             0,      a0,     0
    add.d             a0,     a0,     a1
    preld             0,      a0,     0
    alsl.d            a2,     t1,     a2,   2
    preld             0,      a2,     0
    add.d             t3,     a2,     a3
    preld             0,      t3,     0
    add.d             a2,     t3,     a3
    preld             0,      a2,     0
    add.d             a2,     a2,     a3
    preld             0,      a2,     0
endfunc_x264

/*
 * void prefetch_fenc_420(uint8_t *pix_y, intptr_t stride_y,
 *                        uint8_t *pix_uv, intptr_t stride_uv,
 *                        int32_t mb_x)
 */
function_x264 prefetch_fenc_420_lsx
    andi             t0,      a4,     3
    mul.d            t0,      t0,     a1
    andi             a4,      a4,     6
    mul.d            t1,      a4,     a3
    addi.d           a0,      a0,     64
    addi.d           a2,      a2,     64
    alsl.d           a0,      t0,     a0,   2
    preld            0,       a0,     0
    add.d            t2,      a0,     a1
    preld            0,       t2,     0
    add.d            a0,      t2,     a1
    preld            0,       a0,     0
    add.d            a0,      a0,     a1
    preld            0,       a0,     0
    alsl.d           a2,      t1,     a2,   2
    preld            0,       a2,     0
    add.d            a2,      a2,     a3
    preld            0,       a2,     0
endfunc_x264

/*
 * void *memcpy_aligned(void *dst, const void *src, size_t n)
 */
function_x264 memcpy_aligned_lsx
    andi             t0,      a2,     16
    beqz             t0,      2f
    addi.d           a2,      a2,     -16
    vld              vr0,     a1,     0
    vst              vr0,     a0,     0
    addi.d           a1,      a1,     16
    addi.d           a0,      a0,     16
2:
    andi             t0,      a2,     32
    beqz             t0,      3f
    addi.d           a2,      a2,     -32
    vld              vr0,     a1,     0
    vld              vr1,     a1,     16
    vst              vr0,     a0,     0
    vst              vr1,     a0,     16
    addi.d           a1,      a1,     32
    addi.d           a0,      a0,     32
3:
    beqz             a2,      5f
4:
    addi.d           a2,      a2,     -64
    vld              vr0,     a1,     48
    vld              vr1,     a1,     32
    vld              vr2,     a1,     16
    vld              vr3,     a1,     0
    vst              vr0,     a0,     48
    vst              vr1,     a0,     32
    vst              vr2,     a0,     16
    vst              vr3,     a0,     0
    addi.d           a1,      a1,     64
    addi.d           a0,      a0,     64
    blt              zero,    a2,     4b
5:
endfunc_x264

/*
 * void memzero_aligned(void *p_dst, size_t n)
 */
function_x264 memzero_aligned_lsx
    vxor.v           vr1,     vr1,    vr1
.loop_memzero:
    addi.d           a1,      a1,     -128
    vst              vr1,     a0,     0
    vst              vr1,     a0,     16
    vst              vr1,     a0,     32
    vst              vr1,     a0,     48
    vst              vr1,     a0,     64
    vst              vr1,     a0,     80
    vst              vr1,     a0,     96
    vst              vr1,     a0,     112
    addi.d           a0,      a0,     128
    blt              zero,    a1,     .loop_memzero
endfunc_x264

.macro FILT_H_LSX s1, s2, s3
    vsub.h          \s1,     \s1,   \s2
    vsrai.h         \s1,     \s1,   2
    vsub.h          \s1,     \s1,   \s2
    vadd.h          \s1,     \s1,   \s3
    vsrai.h         \s1,     \s1,   2
    vadd.h          \s1,     \s1,   \s3
.endm

//s1: s1.0, s2: s2.0, s3: s3.0, s4: s1.1 s5: s2.1 s6: s3.1
.macro FILT_C_LSX s1, s2, s3, s4, s5, s6
    vaddi.bu         vr17,    vr23,  2   //vr24
    vaddi.bu         vr19,    vr26,  1   //vr27
    vaddi.bu         vr18,    vr26,  3   //vr29

    vshuf.b          vr1,     \s2,   \s4,  vr23
    vshuf.b          vr2,     \s2,   \s4,  vr17
    vshuf.b          vr3,     \s5,   \s2,  vr18
    vshuf.b          vr4,     \s5,   \s2,  vr19
    vadd.h           vr3,     vr2,   vr3

    vshuf.b          vr16,    \s5,   \s2,  vr23
    vshuf.b          vr17,    \s5,   \s2,  vr17
    vshuf.b          vr18,    \s3,   \s5,  vr18
    vshuf.b          vr19,    \s3,   \s5,  vr19
    vadd.h           vr18,    vr17,  vr18

    vmov             vr2,     \s5
    vmov             \s1,     \s3
    vmov             vr20,    \s3
    vmov             \s4,     \s6

    vaddi.bu         vr17,    vr26,  5   //vr30

    vshuf.b          \s3,     vr2,   \s2,  vr17
    vshuf.b          \s6,     vr20,  \s5,  vr17

    vadd.h           vr4,     vr4,   \s2
    vadd.h           \s3,     \s3,   vr1
    vadd.h           vr19,    vr19,  \s5
    vadd.h           \s6,     \s6,   vr16

    FILT_H_LSX \s3, vr3, vr4
    FILT_H_LSX \s6, vr18, vr19
.endm

.macro FILT_PACK_LSX s1, s2, s3
    vmulwev.w.h     vr16,    \s1,   \s3
    vmulwev.w.h     vr17,    \s2,   \s3
    vsrarni.h.w     vr17,    vr16,  15
    vmaxi.h         vr17,    vr17,  0
    vsat.hu         vr17,    vr17,  7
    vmulwod.w.h     vr18,    \s1,   \s3
    vmulwod.w.h     vr19,    \s2,   \s3
    vsrarni.h.w     vr19,    vr18,  15
    vmaxi.h         vr19,    vr19,  0
    vsat.hu         vr19,    vr19,  7
    vpackev.b       \s1,     vr19,  vr17
.endm

//s1: s1.0, s2: s2.0, s3: s3.0, s4: s4.0
//s5: s1.1, s6: s2.1, s7: s3.1, s8: s4.1

.macro DO_FILT_C_LSX s1, s2, s3, s4, s5, s6, s7, s8
    FILT_C_LSX \s1, \s2, \s3, \s5, \s6, \s7
    FILT_C_LSX \s2, \s1, \s4, \s6, \s5, \s8
    FILT_PACK_LSX \s3, \s4, vr15
    FILT_PACK_LSX \s7, \s8, vr15
    vilvl.d     vr16,    \s7,   \s3
    vilvh.d     vr17,    \s7,   \s3
    addi.d      t3,      a5,    16
    vstx        vr16,    a5,    a4
    vstx        vr17,    t3,    a4
.endm

.macro DO_FILT_H_LSX s1, s2, s3, s4, s5, s6
    vaddi.bu         vr16,    vr23,  2  //vr24
    vaddi.bu         vr17,    vr23,  3  //vr25
    vaddi.bu         vr18,    vr26,  1  //vr27
    vaddi.bu         vr19,    vr26,  2  //vr28
    vld              vr3,     t5,    0

    vshuf.b          vr1,     \s2,   \s4,  vr16
    vshuf.b          vr2,     \s2,   \s4,  vr17
    vshuf.b          vr4,     \s5,   \s2,  vr26
    vshuf.b          vr5,     \s5,   \s2,  vr18
    vshuf.b          vr6,     \s5,   \s2,  vr19

    vdp2.h.bu.b      vr16,    vr1,   vr12
    vdp2.h.bu.b      vr17,    vr2,   vr12
    vdp2.h.bu.b      vr18,    \s2,   vr14
    vdp2.h.bu.b      vr19,    vr4,   vr14
    vdp2.h.bu.b      vr20,    vr5,   vr0
    vdp2.h.bu.b      vr21,    vr6,   vr0
    vadd.h           vr1,     vr16,  vr18
    vadd.h           vr2,     vr17,  vr19
    vadd.h           vr1,     vr1,   vr20
    vadd.h           vr2,     vr2,   vr21
    FILT_PACK_LSX vr1, vr2, vr15
    vshuf.b          vr1,     vr1,   vr1,  vr3
    vstx             vr1,     a0,    a4

    vaddi.bu         vr16,    vr23,  2  //vr24
    vaddi.bu         vr17,    vr23,  3  //vr25
    vaddi.bu         vr18,    vr26,  1  //vr27
    vaddi.bu         vr19,    vr26,  2  //vr28

    vshuf.b          vr1,     \s5,   \s2,  vr16
    vshuf.b          vr2,     \s5,   \s2,  vr17
    vshuf.b          vr4,     \s3,   \s5,  vr26
    vshuf.b          vr5,     \s3,   \s5,  vr18
    vshuf.b          vr6,     \s3,   \s5,  vr19

    vdp2.h.bu.b      vr16,    vr1,   vr12
    vdp2.h.bu.b      vr17,    vr2,   vr12
    vdp2.h.bu.b      vr18,    \s5,   vr14
    vdp2.h.bu.b      vr19,    vr4,   vr14
    vdp2.h.bu.b      vr20,    vr5,   vr0
    vdp2.h.bu.b      vr21,    vr6,   vr0
    vadd.h           vr1,     vr16,  vr18
    vadd.h           vr2,     vr17,  vr19
    vadd.h           vr1,     vr1,   vr20
    vadd.h           vr2,     vr2,   vr21
    FILT_PACK_LSX vr1, vr2, vr15
    vshuf.b          vr1,     vr1,   vr1,  vr3
    addi.d           a0,      a0,    16
    vstx             vr1,     a0,    a4
    addi.d           a0,      a0,    -16

    vmov             \s1,     \s2
    vmov             \s2,     \s3
    vmov             \s4,     \s5
    vmov             \s5,     \s6
.endm

/* s3: temp, s4: UNUSED, s5: imm */
.macro DO_FILT_V0_LSX s1, s2, s3, s4, s5
    alsl.d           t1,      a2,    a1,  1  /* t1 = a1 + 2 * a2 */
    alsl.d           t2,      a2,    a3,  1  /* t2 = a3 + 2 * a2 */
    vld              vr1,     a3,    0
    vldx             vr2,     a3,    a2
    vld              \s3,     t2,    0
    vld              vr3,     a1,    0
    vldx             \s1,     a1,    a2
    vld              \s2,     t1,    0
    vilvh.b          vr16,    vr2,   vr1
    vilvl.b          vr17,    vr2,   vr1
    vilvh.b          vr18,    \s2,   \s1
    vilvl.b          vr19,    \s2,   \s1
    vilvh.b          vr20,    \s3,   vr3
    vilvl.b          vr21,    \s3,   vr3
    vdp2.h.bu.b      vr1,     vr17,  vr12
    vdp2.h.bu.b      vr4,     vr16,  vr12
    vdp2.h.bu.b      \s1,     vr19,  vr0
    vdp2.h.bu.b      vr2,     vr18,  vr0
    vdp2.h.bu.b      vr3,     vr21,  vr14
    vdp2.h.bu.b      \s2,     vr20,  vr14
    vadd.h           vr1,     vr1,   \s1
    vadd.h           vr4,     vr4,   vr2
    vadd.h           vr1,     vr1,   vr3
    vadd.h           vr4,     vr4,   \s2
    vmov             \s1,     vr1
    vmov             \s2,     vr4
    addi.d           a3,      a3,    16
    addi.d           a1,      a1,    16
    FILT_PACK_LSX  vr1,  vr4,  vr15
    addi.d           t3,      a4,    \s5
    vstx             vr1,     t0,    t3
.endm

.macro DO_FILT_V1_LSX s1, s2, s3, s4, s5
    vld              vr1,     a3,    0
    vldx             vr2,     a3,    a2
    vld              \s3,     t2,    16
    vld              vr3,     a1,    0
    vldx             \s1,     a1,    a2
    vld              \s2,     t1,    16
    vilvh.b          vr16,    vr2,   vr1
    vilvl.b          vr17,    vr2,   vr1
    vilvh.b          vr18,    \s2,   \s1
    vilvl.b          vr19,    \s2,   \s1
    vilvh.b          vr20,    \s3,   vr3
    vilvl.b          vr21,    \s3,   vr3
    vdp2.h.bu.b      vr1,     vr17,  vr12
    vdp2.h.bu.b      vr4,     vr16,  vr12
    vdp2.h.bu.b      \s1,     vr19,  vr0
    vdp2.h.bu.b      vr2,     vr18,  vr0
    vdp2.h.bu.b      vr3,     vr21,  vr14
    vdp2.h.bu.b      \s2,     vr20,  vr14
    vadd.h           vr1,     vr1,   \s1
    vadd.h           vr4,     vr4,   vr2
    vadd.h           vr1,     vr1,   vr3
    vadd.h           vr4,     vr4,   \s2
    vmov             \s1,     vr1
    vmov             \s2,     vr4
    addi.d           a3,      a3,    16
    addi.d           a1,      a1,    16
    FILT_PACK_LSX  vr1,  vr4,  vr15
    addi.d           t3,      a4,    \s5
    addi.d           t3,      t3,    16
    vstx             vr1,     t0,    t3
.endm

/*
 * void hpel_filter( uint8_t *dsth, uint8_t *dstv, uint8_t *dstc,
 *                   uint8_t *src, intptr_t stride, int width, int height )
 */
function_x264 hpel_filter_lsx
    addi.d           sp,      sp,    -64
    fst.d            f24,     sp,    0
    fst.d            f25,     sp,    8
    fst.d            f26,     sp,    16
    fst.d            f27,     sp,    24
    fst.d            f28,     sp,    32
    fst.d            f29,     sp,    40
    fst.d            f30,     sp,    48
    fst.d            f31,     sp,    56

    move             a7,      a3
    addi.d           a5,      a5,    -32
    move             t0,      a1
    andi             a7,      a7,    31
    sub.d            a3,      a3,    a7
    add.d            a0,      a0,    a5
    add.d            t0,      t0,    a5
    add.d            a7,      a7,    a5
    add.d            a5,      a5,    a2
    move             a2,      a4
    sub.d            a7,      zero,  a7
    add.d            a1,      a3,    a2
    sub.d            a3,      a3,    a2
    sub.d            a3,      a3,    a2
    move             a4,      a7
    la.local         t1,      filt_mul51
    vld              vr0,     t1,    0
    la.local         t2,      filt_mul15
    vld              vr12,    t2,    0
    la.local         t3,      filt_mul20
    vld              vr14,    t3,    0
    la.local         t4,      pw_1024
    vld              vr15,    t4,    0
    la.local         t5,      hpel_shuf
    la.local         t2,      shuf_12
    vld              vr23,    t2,    0
    la.local         t3,      shuf_1
    vld              vr26,    t3,    0
    vxor.v           vr9,     vr9,   vr9
    vxor.v           vr10,    vr10,  vr10
    vxor.v           vr11,    vr11,  vr11
    vxor.v           vr13,    vr13,  vr13
.LOOPY_LSX:
    DO_FILT_V0_LSX vr24, vr25, vr31, vr12, 0
    DO_FILT_V1_LSX vr8, vr7, vr22, vr12, 0
.LOOPX_LSX:
    DO_FILT_V0_LSX vr27, vr28, vr29, vr12, 32
    DO_FILT_V1_LSX vr6, vr5,  vr30, vr12, 32
.LSTX:
    vsrli.h          vr15,    vr15,  1
    DO_FILT_C_LSX vr9, vr24, vr8, vr27, vr10, vr25, vr7, vr28
    vadd.h           vr15,    vr15,  vr15
    vmov             vr8,     vr6
    vmov             vr7,     vr5

    DO_FILT_H_LSX vr11, vr31, vr29, vr13, vr22, vr30
    addi.d           a4,      a4,    32
    blt              a4,      zero,  .LOOPX_LSX
    addi.d           t1,      a4,    -32
    blt              t1,      zero,  .LSTX
    //setup regs for next y
    sub.d            a4,      a4,    a7
    sub.d            a4,      a4,    a2
    sub.d            a1,      a1,    a4
    sub.d            a3,      a3,    a4
    add.d            a0,      a0,    a2
    add.d            t0,      t0,    a2
    add.d            a5,      a5,    a2
    move             a4,      a7
    addi.d           a6,      a6,    -1
    blt              zero,    a6,    .LOOPY_LSX
    fld.d            f24,     sp,    0
    fld.d            f25,     sp,    8
    fld.d            f26,     sp,    16
    fld.d            f27,     sp,    24
    fld.d            f28,     sp,    32
    fld.d            f29,     sp,    40
    fld.d            f30,     sp,    48
    fld.d            f31,     sp,    56
    addi.d           sp,      sp,    64
endfunc_x264

/*
 * void frame_init_lowres_core(pixel *src0, pixel *dst0, pixel *dsth,
 *                             pixel *dstv, pixel *dstc, intptr_t src_stride,
 *                             intptr_t dst_stride, int width, int height)
 */
function_x264 frame_init_lowres_core_lsx
    addi.d           t0,      zero,   15
    addi.d           t1,      zero,   7
    addi.d           t2,      zero,   3
    addi.d           t3,      zero,   1
    ld.d             t4,      sp,     0
    addi.d           sp,      sp,     -16
    st.d             s0,      sp,     0
    st.d             s1,      sp,     8
    slli.d           s0,      a5,     1
.LOOPH:
    bge              zero,    t4,     .ENDLOOPH
    addi.d           t4,      t4,     -1
    add.d            t5,      a0,     a5
    add.d            t7,      t5,     a5
    move             t6,      a7
.LOOPW16:
    bge              t0,      t6,     .LOOPW8
    vld              vr0,     a0,     0
    vld              vr1,     t5,     0
    vld              vr2,     t7,     0
    vld              vr3,     a0,     1
    vld              vr4,     t5,     1
    vld              vr5,     t7,     1
    vld              vr6,     a0,     16
    vld              vr7,     t5,     16
    vld              vr8,     t7,     16
    vld              vr9,     a0,     17
    vld              vr10,    t5,     17
    vld              vr11,    t7,     17

    // Calculate dst0, dsth, dstv and dstc
    vavgr.bu         vr12,    vr0,    vr1
    vavgr.bu         vr13,    vr1,    vr2
    vavgr.bu         vr14,    vr3,    vr4
    vavgr.bu         vr15,    vr4,    vr5
    vavgr.bu         vr16,    vr6,    vr7
    vavgr.bu         vr17,    vr7,    vr8
    vavgr.bu         vr18,    vr9,    vr10
    vavgr.bu         vr19,    vr10,   vr11
    vhaddw.hu.bu     vr12,    vr12,   vr12
    vhaddw.hu.bu     vr13,    vr13,   vr13
    vhaddw.hu.bu     vr14,    vr14,   vr14
    vhaddw.hu.bu     vr15,    vr15,   vr15
    vhaddw.hu.bu     vr16,    vr16,   vr16
    vhaddw.hu.bu     vr17,    vr17,   vr17
    vhaddw.hu.bu     vr18,    vr18,   vr18
    vhaddw.hu.bu     vr19,    vr19,   vr19
    vssrarni.bu.h    vr13,    vr12,   1
    vssrarni.bu.h    vr15,    vr14,   1
    vssrarni.bu.h    vr17,    vr16,   1
    vssrarni.bu.h    vr19,    vr18,   1
    vilvl.d          vr12,    vr17,   vr13
    vilvl.d          vr14,    vr19,   vr15
    vilvh.d          vr13,    vr17,   vr13
    vilvh.d          vr15,    vr19,   vr15
    vst              vr12,    a1,     0
    vst              vr14,    a2,     0
    vst              vr13,    a3,     0
    vst              vr15,    a4,     0

    addi.d           a1,      a1,     16
    addi.d           a2,      a2,     16
    addi.d           a3,      a3,     16
    addi.d           a4,      a4,     16
    addi.d           a0,      a0,     32
    addi.d           t5,      t5,     32
    addi.d           t7,      t7,     32
    addi.d           t6,      t6,     -16
    b                .LOOPW16
.LOOPW8:
    bge              t1,      t6,     .LOOPW4
    vld              vr0,     a0,     0
    vld              vr1,     t5,     0
    vld              vr2,     t7,     0
    vld              vr3,     a0,     1
    vld              vr4,     t5,     1
    vld              vr5,     t7,     1

    // Calculate dst0, dsth, dstv and dstc
    vavgr.bu         vr12,    vr0,    vr1
    vavgr.bu         vr13,    vr1,    vr2
    vavgr.bu         vr14,    vr3,    vr4
    vavgr.bu         vr15,    vr4,    vr5
    vhaddw.hu.bu     vr12,    vr12,   vr12
    vhaddw.hu.bu     vr13,    vr13,   vr13
    vhaddw.hu.bu     vr14,    vr14,   vr14
    vhaddw.hu.bu     vr15,    vr15,   vr15
    vssrarni.bu.h    vr13,    vr12,   1
    vssrarni.bu.h    vr15,    vr14,   1
    vstelm.d         vr13,    a1,     0,   0
    vstelm.d         vr15,    a2,     0,   0
    vstelm.d         vr13,    a3,     0,   1
    vstelm.d         vr15,    a4,     0,   1

    addi.d           a1,      a1,     8
    addi.d           a2,      a2,     8
    addi.d           a3,      a3,     8
    addi.d           a4,      a4,     8
    addi.d           a0,      a0,     16
    addi.d           t5,      t5,     16
    addi.d           t7,      t7,     16
    addi.d           t6,      t6,     -8
    b                .LOOPW8
.LOOPW4:
    bge              t2,      t6,    .LOOPW2
    vld              vr0,     a0,    0
    vld              vr1,     t5,    0
    vld              vr2,     t7,    0
    vld              vr3,     a0,    1
    vld              vr4,     t5,    1
    vld              vr5,     t7,    1

    // Calculate dst0, dsth, dstv and dstc
    vavgr.bu         vr12,    vr0,   vr1
    vavgr.bu         vr13,    vr1,   vr2
    vavgr.bu         vr14,    vr3,   vr4
    vavgr.bu         vr15,    vr4,   vr5
    vhaddw.hu.bu     vr12,    vr12,  vr12
    vhaddw.hu.bu     vr13,    vr13,  vr13
    vhaddw.hu.bu     vr14,    vr14,  vr14
    vhaddw.hu.bu     vr15,    vr15,  vr15
    vssrarni.bu.h    vr13,    vr12,  1
    vssrarni.bu.h    vr15,    vr14,  1
    vstelm.w         vr13,    a1,    0,   0
    vstelm.w         vr15,    a2,    0,   0
    vstelm.w         vr13,    a3,    0,   2
    vstelm.w         vr15,    a4,    0,   2

    addi.d           a1,      a1,    4
    addi.d           a2,      a2,    4
    addi.d           a3,      a3,    4
    addi.d           a4,      a4,    4
    addi.d           a0,      a0,    8
    addi.d           t5,      t5,    8
    addi.d           t7,      t7,    8
    addi.d           t6,      t6,    -4
    b                .LOOPW4
.LOOPW2:
    bge              t3,      t6,    .LOOPW1
    vld              vr0,     a0,    0
    vld              vr1,     t5,    0
    vld              vr2,     t7,    0
    vld              vr3,     a0,    1
    vld              vr4,     t5,    1
    vld              vr5,     t7,    1

    // Calculate dst0, dsth, dstv and dstc
    vavgr.bu         vr12,    vr0,   vr1
    vavgr.bu         vr13,    vr1,   vr2
    vavgr.bu         vr14,    vr3,   vr4
    vavgr.bu         vr15,    vr4,   vr5
    vhaddw.hu.bu     vr12,    vr12,  vr12
    vhaddw.hu.bu     vr13,    vr13,  vr13
    vhaddw.hu.bu     vr14,    vr14,  vr14
    vhaddw.hu.bu     vr15,    vr15,  vr15
    vssrarni.bu.h    vr13,    vr12,  1
    vssrarni.bu.h    vr15,    vr14,  1
    vstelm.h         vr13,    a1,    0,   0
    vstelm.h         vr15,    a2,    0,   0
    vstelm.h         vr13,    a3,    0,   4
    vstelm.h         vr15,    a4,    0,   4

    addi.d           a1,      a1,    2
    addi.d           a2,      a2,    2
    addi.d           a3,      a3,    2
    addi.d           a4,      a4,    2
    addi.d           a0,      a0,    4
    addi.d           t5,      t5,    4
    addi.d           t7,      t7,    4
    addi.d           t6,      t6,    -2
    b                .LOOPW2
.LOOPW1:
    bge              zero,    t6,    .ENDLOOPW1
    vld              vr0,     a0,    0
    vld              vr1,     t5,    0
    vld              vr2,     t7,    0
    vld              vr3,     a0,    1
    vld              vr4,     t5,    1
    vld              vr5,     t7,    1

    // Calculate dst0, dsth, dstv and dstc
    vavgr.bu         vr12,    vr0,   vr1
    vavgr.bu         vr13,    vr1,   vr2
    vavgr.bu         vr14,    vr3,   vr4
    vavgr.bu         vr15,    vr4,   vr5
    vhaddw.hu.bu     vr12,    vr12,  vr12
    vhaddw.hu.bu     vr13,    vr13,  vr13
    vhaddw.hu.bu     vr14,    vr14,  vr14
    vhaddw.hu.bu     vr15,    vr15,  vr15
    vssrarni.bu.h    vr13,    vr12,  1
    vssrarni.bu.h    vr15,    vr14,  1
    vstelm.b         vr13,    a1,    0,   0
    vstelm.b         vr15,    a2,    0,   0
    vstelm.b         vr13,    a3,    0,   8
    vstelm.b         vr15,    a4,    0,   8
.ENDLOOPW1:
    sub.d            s1,      a7,    t6
    sub.d            a0,      a0,    s1
    sub.d            a0,      a0,    s1
    add.d            a0,      a0,    s0
    sub.d            a1,      a1,    s1
    add.d            a1,      a1,    a6
    sub.d            a2,      a2,    s1
    add.d            a2,      a2,    a6
    sub.d            a3,      a3,    s1
    add.d            a3,      a3,    a6
    sub.d            a4,      a4,    s1
    add.d            a4,      a4,    a6
    b                .LOOPH
.ENDLOOPH:
    ld.d             s0,      sp,    0
    ld.d             s1,      sp,    8
    addi.d           sp,      sp,    16
endfunc_x264
#endif /* !HIGH_BIT_DEPTH */
