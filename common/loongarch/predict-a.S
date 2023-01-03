/*****************************************************************************
 * predict-a.S: loongarch predict functions
 *****************************************************************************
 * Copyright (C) 2015-2018 x264 project
 * Copyright (C) 2022 Loongson Technology Corporation Limited
 *
 * Authors: gxw <guxiwei-hf@loongson.cn>
 *          Lu Wang <wanglu@loongson.cn>
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

/****************************************************************************
 * 4x4 prediction for intra luma block
 ****************************************************************************/
/* void x264_predict_4x4_v_c( pixel *src )
 */
function predict_4x4_v_lsx
    ld.wu         t0,    a0,    -FDEC_STRIDE
    st.w          t0,    a0,    0
    st.w          t0,    a0,    FDEC_STRIDE
    st.w          t0,    a0,    FDEC_STRIDE * 2
    st.w          t0,    a0,    FDEC_STRIDE * 3
endfunc

/* void x264_predict_4x4_h_c( pixel *src )
 */
function predict_4x4_h_lsx
    vldrepl.b     vr0,   a0,    -1
    vldrepl.b     vr1,   a0,    FDEC_STRIDE - 1
    vldrepl.b     vr2,   a0,    FDEC_STRIDE * 2 - 1
    vldrepl.b     vr3,   a0,    FDEC_STRIDE * 3 - 1
    fst.s         f0,    a0,    0
    fst.s         f1,    a0,    FDEC_STRIDE
    fst.s         f2,    a0,    FDEC_STRIDE * 2
    fst.s         f3,    a0,    FDEC_STRIDE * 3
endfunc

/* void x264_predict_4x4_dc_c( pixel *src )
 */
function predict_4x4_dc_lsx
    fld.s         f0,    a0,    -FDEC_STRIDE
    ld.bu         t0,    a0,    -1
    ld.bu         t1,    a0,    FDEC_STRIDE - 1
    ld.bu         t2,    a0,    FDEC_STRIDE * 2 - 1
    ld.bu         t3,    a0,    FDEC_STRIDE * 3 - 1

    vhaddw.hu.bu  vr1,   vr0,   vr0
    vhaddw.wu.hu  vr2,   vr1,   vr1
    vpickve2gr.w  t4,    vr2,   0
    add.w         t0,    t0,    t1
    add.w         t0,    t0,    t2
    add.w         t0,    t0,    t3
    add.w         t0,    t0,    t4
    addi.w        t0,    t0,    4
    srai.w        t0,    t0,    3

    vreplgr2vr.b  vr0,   t0
    vstelm.w      vr0,   a0,    0,                 0
    vstelm.w      vr0,   a0,    FDEC_STRIDE,       0
    vstelm.w      vr0,   a0,    FDEC_STRIDE * 2,   0
    vstelm.w      vr0,   a0,    FDEC_STRIDE * 3,   0
endfunc

/* void predict_4x4_dc_top_c( pixel *src )
 */
function predict_4x4_dc_top_lsx
    fld.s         f0,    a0,    -FDEC_STRIDE
    vhaddw.hu.bu  vr1,   vr0,   vr0
    vhaddw.wu.hu  vr2,   vr1,   vr1
    vsrari.w      vr2,   vr2,   2

    vreplvei.b    vr3,   vr2,   0
    fst.s         f3,    a0,    0
    fst.s         f3,    a0,    FDEC_STRIDE
    fst.s         f3,    a0,    FDEC_STRIDE * 2
    fst.s         f3,    a0,    FDEC_STRIDE * 3
endfunc

/* void predict_4x4_dc_left_c( pixel *src )
 */
function predict_4x4_dc_left_lsx
    ld.bu         t0,    a0,    -1
    ld.bu         t1,    a0,    FDEC_STRIDE - 1
    ld.bu         t2,    a0,    FDEC_STRIDE * 2 - 1
    ld.bu         t3,    a0,    FDEC_STRIDE * 3 - 1
    add.w         t0,    t0,    t1
    add.w         t0,    t0,    t2
    add.w         t0,    t0,    t3
    addi.w        t0,    t0,    2
    srai.w        t0,    t0,    2

    vreplgr2vr.b  vr3,   t0
    fst.s         f3,    a0,    0
    fst.s         f3,    a0,    FDEC_STRIDE
    fst.s         f3,    a0,    FDEC_STRIDE * 2
    fst.s         f3,    a0,    FDEC_STRIDE * 3
endfunc

/* void predict_4x4_dc_128_c( pixel *src )
 */
function predict_4x4_dc_128_lsx
    addi.w        t0,    zero,  1
    slli.w        t0,    t0,    BIT_DEPTH - 1

    vreplgr2vr.b  vr3,   t0
    fst.s         f3,    a0,    0
    fst.s         f3,    a0,    FDEC_STRIDE
    fst.s         f3,    a0,    FDEC_STRIDE * 2
    fst.s         f3,    a0,    FDEC_STRIDE * 3
endfunc

/* void predict_4x4_ddl_c( pixel *src )
 */
function predict_4x4_ddl_lsx
    fld.d           f0,    a0,       -FDEC_STRIDE

    vxor.v          vr10,  vr10,     vr10
    vilvl.b         vr0,   vr10,     vr0
    vbsrl.v         vr1,   vr0,      2
    vbsrl.v         vr2,   vr0,      4

    // t7
    vextrins.h      vr2,   vr0,      0x67

    vslli.h         vr1,   vr1,      1
    vadd.h          vr0,   vr0,      vr1
    vadd.h          vr2,   vr0,      vr2
    vssrarni.bu.h   vr3,   vr2,      2

    fst.s           f3,    a0,       0
    vbsrl.v         vr4,   vr3,      1
    fst.s           f4,    a0,       FDEC_STRIDE
    vbsrl.v         vr4,   vr4,      1
    fst.s           f4,    a0,       FDEC_STRIDE * 2
    vbsrl.v         vr4,   vr4,      1
    fst.s           f4,    a0,       FDEC_STRIDE * 3
endfunc

/****************************************************************************
 * 8x8 prediction for intra chroma block (4:2:0)
 ****************************************************************************/
/* void x264_predict_8x8c_p_lsx( pixel *src )
 */
const mula
.short 1, 2, 3, 4, 0, 0, 0, 0
endconst

const mulb
.short 0, 1, 2, 3, 4, 5, 6, 7
endconst

function predict_8x8c_p_lsx
    la.local      t0,    mula
    fld.d         f3,    t0,    0
    fld.s         f4,    a0,    4  - FDEC_STRIDE
    fld.s         f5,    a0,    -1 - FDEC_STRIDE
    vxor.v        vr0,   vr0,   vr0
    vilvl.b       vr4,   vr0,   vr4
    vilvl.b       vr5,   vr0,   vr5
    vshuf4i.h     vr5,   vr5,   0x1b
    vsub.h        vr4,   vr4,   vr5
    vmul.h        vr4,   vr4,   vr3
    vhaddw.w.h    vr4,   vr4,   vr4
    vhaddw.d.w    vr4,   vr4,   vr4
    vpickve2gr.w  t0,    vr4,   0       /* H */

    fld.s         f6,    a0,    FDEC_STRIDE * 4 - 1
    fld.s         f7,    a0,    FDEC_STRIDE * 5 - 1
    fld.s         f8,    a0,    FDEC_STRIDE * 6 - 1
    fld.s         f9,    a0,    FDEC_STRIDE * 7 - 1
    fld.s         f10,   a0,    FDEC_STRIDE * 2 - 1
    fld.s         f11,   a0,    FDEC_STRIDE - 1
    fld.s         f12,   a0,    -1
    fld.s         f13,   a0,    -1 - FDEC_STRIDE
    vilvl.b       vr6,   vr7,   vr6
    vilvl.b       vr9,   vr9,   vr8
    vilvl.h       vr6,   vr9,   vr6
    vilvl.b       vr10,  vr11,  vr10
    vilvl.b       vr12,  vr13,  vr12
    vilvl.h       vr10,  vr12,  vr10
    vilvl.b       vr6,   vr0,   vr6
    vilvl.b       vr10,  vr0,   vr10
    vsub.h        vr6,   vr6,   vr10
    vmul.h        vr6,   vr6,   vr3
    vhaddw.w.h    vr6,   vr6,   vr6
    vhaddw.d.w    vr6,   vr6,   vr6
    vpickve2gr.w  t1,    vr6,   0       /* V */

    ld.bu         t2,    a0,    FDEC_STRIDE * 7 - 1
    ld.bu         t3,    a0,    7 - FDEC_STRIDE
    add.w         t2,    t2,    t3
    slli.w        t2,    t2,    4       /* a */

    slli.w        t3,    t0,    4
    add.w         t0,    t0,    t3
    addi.w        t0,    t0,    16
    srai.w        t0,    t0,    5       /* b */

    slli.w        t3,    t1,    4
    add.w         t1,    t1,    t3
    addi.w        t1,    t1,    16
    srai.w        t1,    t1,    5       /* c */

    add.w         t3,    t0,    t1
    slli.w        t4,    t3,    1
    add.w         t4,    t4,    t3
    sub.w         t5,    t2,    t4
    addi.w        t5,    t5,    16      /* i00 */

    la.local      t3,    mulb
    vld           vr14,  t3,    0
    vreplgr2vr.h  vr12,  t0
    vmul.h        vr12,  vr12,  vr14

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    0
    add.w         t5,    t5,    t1

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    FDEC_STRIDE
    add.w         t5,    t5,    t1

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    FDEC_STRIDE * 2
    add.w         t5,    t5,    t1

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    FDEC_STRIDE * 3
    add.w         t5,    t5,    t1

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    FDEC_STRIDE * 4
    add.w         t5,    t5,    t1

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    FDEC_STRIDE * 5
    add.w         t5,    t5,    t1

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    FDEC_STRIDE * 6
    add.w         t5,    t5,    t1

    vreplgr2vr.h  vr14,  t5
    vadd.h        vr13,  vr12,  vr14
    vssrani.bu.h  vr15,  vr13,  5
    fst.d         f15,   a0,    FDEC_STRIDE * 7
endfunc

/* void x264_predict_8x8c_v_lsx( pixel *src )
 */
function predict_8x8c_v_lsx
    fld.d         f0,    a0,    -FDEC_STRIDE
    fst.d         f0,    a0,    0
    fst.d         f0,    a0,    FDEC_STRIDE
    fst.d         f0,    a0,    FDEC_STRIDE * 2
    fst.d         f0,    a0,    FDEC_STRIDE * 3
    fst.d         f0,    a0,    FDEC_STRIDE * 4
    fst.d         f0,    a0,    FDEC_STRIDE * 5
    fst.d         f0,    a0,    FDEC_STRIDE * 6
    fst.d         f0,    a0,    FDEC_STRIDE * 7
endfunc

/* void x264_predict_8x8c_h_lsx( pixel *src )
 */
function predict_8x8c_h_lsx
    vldrepl.b     vr0,   a0,    -1
    vldrepl.b     vr1,   a0,    FDEC_STRIDE - 1
    vldrepl.b     vr2,   a0,    FDEC_STRIDE * 2 - 1
    vldrepl.b     vr3,   a0,    FDEC_STRIDE * 3 - 1
    vldrepl.b     vr4,   a0,    FDEC_STRIDE * 4 - 1
    vldrepl.b     vr5,   a0,    FDEC_STRIDE * 5 - 1
    vldrepl.b     vr6,   a0,    FDEC_STRIDE * 6 - 1
    vldrepl.b     vr7,   a0,    FDEC_STRIDE * 7 - 1
    fst.d         f0,    a0,    0
    fst.d         f1,    a0,    FDEC_STRIDE
    fst.d         f2,    a0,    FDEC_STRIDE * 2
    fst.d         f3,    a0,    FDEC_STRIDE * 3
    fst.d         f4,    a0,    FDEC_STRIDE * 4
    fst.d         f5,    a0,    FDEC_STRIDE * 5
    fst.d         f6,    a0,    FDEC_STRIDE * 6
    fst.d         f7,    a0,    FDEC_STRIDE * 7
endfunc

/* void x264_predict_8x8c_dc_lsx( pixel *src )
 */
function predict_8x8c_dc_lsx
    fld.s           f0,     a0,    -FDEC_STRIDE
    fld.s           f1,     a0,    4 - FDEC_STRIDE
    vhaddw.hu.bu    vr2,    vr0,   vr0
    vhaddw.wu.hu    vr2,    vr2,   vr2
    vhaddw.hu.bu    vr3,    vr1,   vr1
    vhaddw.wu.hu    vr3,    vr3,   vr3
    vpickve2gr.w    t0,     vr2,   0     /* s0 */
    vpickve2gr.w    t1,     vr3,   0     /* s1 */
    ld.bu           t2,     a0,    -1
    ld.bu           t3,     a0,    FDEC_STRIDE - 1
    ld.bu           t4,     a0,    FDEC_STRIDE * 2 - 1
    ld.bu           t5,     a0,    FDEC_STRIDE * 3 - 1
    add.w           t2,     t2,    t3
    add.w           t2,     t2,    t4
    add.w           t2,     t2,    t5    /* s2 */
    ld.bu           t3,     a0,    FDEC_STRIDE * 4 - 1
    ld.bu           t4,     a0,    FDEC_STRIDE * 5 - 1
    ld.bu           t5,     a0,    FDEC_STRIDE * 6 - 1
    ld.bu           t6,     a0,    FDEC_STRIDE * 7 - 1
    add.w           t3,     t3,    t4
    add.w           t3,     t3,    t5
    add.w           t3,     t3,    t6    /* s3 */

    add.w           t4,     t0,    t2
    addi.w          t4,     t4,    4
    srai.w          t4,     t4,    3     /* ( s0 + s2 + 4 ) >> 3 */
    addi.w          t5,     t1,    2
    srai.w          t5,     t5,    2     /* ( s1 + 2 ) >> 2 */
    addi.w          t6,     t3,    2
    srai.w          t6,     t6,    2     /* ( s3 + 2 ) >> 2 */
    add.w           t7,     t1,    t3
    addi.w          t7,     t7,    4
    srai.w          t7,     t7,    3     /* ( s1 + s3 + 4 ) >> 3 */
    vreplgr2vr.b    vr4,    t4
    vreplgr2vr.b    vr5,    t5
    vreplgr2vr.b    vr6,    t6
    vreplgr2vr.b    vr7,    t7
    vpackev.w       vr4,    vr5,   vr4
    vpackev.w       vr6,    vr7,   vr6

    fst.d           f4,     a0,    0
    fst.d           f4,     a0,    FDEC_STRIDE
    fst.d           f4,     a0,    FDEC_STRIDE * 2
    fst.d           f4,     a0,    FDEC_STRIDE * 3

    fst.d           f6,     a0,    FDEC_STRIDE * 4
    fst.d           f6,     a0,    FDEC_STRIDE * 5
    fst.d           f6,     a0,    FDEC_STRIDE * 6
    fst.d           f6,     a0,    FDEC_STRIDE * 7
endfunc

/* void x264_predict_8x8c_dc_128_lsx( pixel *src )
 */
function predict_8x8c_dc_128_lsx
    ori             t1,     t0,    1
    slli.d          t1,     t1,    BIT_DEPTH - 1
    vreplgr2vr.b    vr4,    t1
    fst.d           f4,     a0,    0
    fst.d           f4,     a0,    FDEC_STRIDE
    fst.d           f4,     a0,    FDEC_STRIDE * 2
    fst.d           f4,     a0,    FDEC_STRIDE * 3
    fst.d           f4,     a0,    FDEC_STRIDE * 4
    fst.d           f4,     a0,    FDEC_STRIDE * 5
    fst.d           f4,     a0,    FDEC_STRIDE * 6
    fst.d           f4,     a0,    FDEC_STRIDE * 7
endfunc

/* void x264_predict_8x8c_dc_top_lsx( pixel *src )
 */
function predict_8x8c_dc_top_lsx
    fld.s          f0,      a0,     -FDEC_STRIDE
    fld.s          f1,      a0,     4 - FDEC_STRIDE
    vhaddw.hu.bu   vr0,     vr0,    vr0
    vhaddw.wu.hu   vr0,     vr0,    vr0
    vhaddw.hu.bu   vr1,     vr1,    vr1
    vhaddw.wu.hu   vr1,     vr1,    vr1
    vpickve2gr.w   t0,      vr0,    0     /* dc0 */
    vpickve2gr.w   t1,      vr1,    0     /* dc1 */

    addi.w         t0,      t0,     2
    srai.w         t0,      t0,     2
    addi.w         t1,      t1,     2
    srai.w         t1,      t1,     2
    vreplgr2vr.b   vr4,     t0
    vreplgr2vr.b   vr5,     t1
    vpackev.w      vr4,     vr5,    vr4
    fst.d           f4,     a0,    0
    fst.d           f4,     a0,    FDEC_STRIDE
    fst.d           f4,     a0,    FDEC_STRIDE * 2
    fst.d           f4,     a0,    FDEC_STRIDE * 3
    fst.d           f4,     a0,    FDEC_STRIDE * 4
    fst.d           f4,     a0,    FDEC_STRIDE * 5
    fst.d           f4,     a0,    FDEC_STRIDE * 6
    fst.d           f4,     a0,    FDEC_STRIDE * 7
endfunc

/* void x264_predict_8x8c_dc_left_lsx( pixel *src )
 */
function predict_8x8c_dc_left_lsx
    ld.bu          t0,      a0,      -1
    ld.bu          t1,      a0,      FDEC_STRIDE - 1
    ld.bu          t2,      a0,      FDEC_STRIDE * 2 - 1
    ld.bu          t3,      a0,      FDEC_STRIDE * 3 - 1
    add.w          t0,      t0,      t1
    add.w          t0,      t0,      t2
    add.w          t0,      t0,      t3
    ld.bu          t1,      a0,      FDEC_STRIDE * 4 - 1
    ld.bu          t2,      a0,      FDEC_STRIDE * 5 - 1
    ld.bu          t3,      a0,      FDEC_STRIDE * 6 - 1
    ld.bu          t4,      a0,      FDEC_STRIDE * 7 - 1
    add.w          t1,      t1,      t2
    add.w          t1,      t1,      t3
    add.w          t1,      t1,      t4
    addi.w         t0,      t0,      2
    srai.w         t0,      t0,      2
    addi.w         t1,      t1,      2
    srai.w         t1,      t1,      2
    vreplgr2vr.b   vr4,     t0       /* ( dc0 + 2 ) >> 2 */
    vreplgr2vr.b   vr5,     t1       /* ( dc1 + 2 ) >> 2 */
    fst.d          f4,      a0,      0
    fst.d          f4,      a0,      FDEC_STRIDE
    fst.d          f4,      a0,      FDEC_STRIDE * 2
    fst.d          f4,      a0,      FDEC_STRIDE * 3
    fst.d          f5,      a0,      FDEC_STRIDE * 4
    fst.d          f5,      a0,      FDEC_STRIDE * 5
    fst.d          f5,      a0,      FDEC_STRIDE * 6
    fst.d          f5,      a0,      FDEC_STRIDE * 7
endfunc

/****************************************************************************
 * 8x8 prediction for intra luma block
 ****************************************************************************/
/* void predict_8x8_v_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_v_lsx
    fld.d           f0,     a1,    16
    fst.d           f0,     a0,    0
    fst.d           f0,     a0,    FDEC_STRIDE
    fst.d           f0,     a0,    FDEC_STRIDE * 2
    fst.d           f0,     a0,    FDEC_STRIDE * 3
    fst.d           f0,     a0,    FDEC_STRIDE * 4
    fst.d           f0,     a0,    FDEC_STRIDE * 5
    fst.d           f0,     a0,    FDEC_STRIDE * 6
    fst.d           f0,     a0,    FDEC_STRIDE * 7
endfunc

/* void predict_8x8_h_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_h_lasx
    fld.d           f0,     a1,    7
    xvinsve0.w      xr0,    xr0,   5
    xvrepl128vei.b  xr4,    xr0,   7
    xvrepl128vei.b  xr3,    xr0,   6
    xvrepl128vei.b  xr2,    xr0,   5
    xvrepl128vei.b  xr1,    xr0,   4

    fst.d           f4,     a0,    0
    fst.d           f3,     a0,    FDEC_STRIDE
    fst.d           f2,     a0,    FDEC_STRIDE * 2
    fst.d           f1,     a0,    FDEC_STRIDE * 3

    xvstelm.d       xr4,    a0,    FDEC_STRIDE * 4,     2
    xvstelm.d       xr3,    a0,    FDEC_STRIDE * 5,     2
    xvstelm.d       xr2,    a0,    FDEC_STRIDE * 6,     2
    xvstelm.d       xr1,    a0,    FDEC_STRIDE * 7,     2
endfunc

/* void predict_8x8_dc_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_dc_lsx
    fld.d           f0,     a1,    7
    fld.d           f1,     a1,    16
    vilvl.d         vr0,    vr1,   vr0
    vhaddw.hu.bu    vr1,    vr0,   vr0
    vhaddw.wu.hu    vr2,    vr1,   vr1
    vhaddw.du.wu    vr3,    vr2,   vr2
    vhaddw.qu.du    vr4,    vr3,   vr3
    vsrari.w        vr4,    vr4,   4

    vreplvei.b      vr5,    vr4,   0
    fst.d           f5,     a0,    0
    fst.d           f5,     a0,    FDEC_STRIDE
    fst.d           f5,     a0,    FDEC_STRIDE * 2
    fst.d           f5,     a0,    FDEC_STRIDE * 3
    fst.d           f5,     a0,    FDEC_STRIDE * 4
    fst.d           f5,     a0,    FDEC_STRIDE * 5
    fst.d           f5,     a0,    FDEC_STRIDE * 6
    fst.d           f5,     a0,    FDEC_STRIDE * 7
endfunc

/* void predict_8x8_dc_left_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_dc_left_lsx
    fld.d           f0,     a1,    7
    vhaddw.hu.bu    vr1,    vr0,   vr0
    vhaddw.wu.hu    vr2,    vr1,   vr1
    vhaddw.du.wu    vr3,    vr2,   vr2
    vsrari.w        vr3,    vr3,   3

    vreplvei.b      vr5,    vr3,   0
    fst.d           f5,     a0,    0
    fst.d           f5,     a0,    FDEC_STRIDE
    fst.d           f5,     a0,    FDEC_STRIDE * 2
    fst.d           f5,     a0,    FDEC_STRIDE * 3
    fst.d           f5,     a0,    FDEC_STRIDE * 4
    fst.d           f5,     a0,    FDEC_STRIDE * 5
    fst.d           f5,     a0,    FDEC_STRIDE * 6
    fst.d           f5,     a0,    FDEC_STRIDE * 7
endfunc

/* void predict_8x8_dc_top_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_dc_top_lsx
    fld.d           f0,     a1,    16
    vhaddw.hu.bu    vr1,    vr0,   vr0
    vhaddw.wu.hu    vr2,    vr1,   vr1
    vhaddw.du.wu    vr3,    vr2,   vr2
    vsrari.w        vr3,    vr3,   3

    vreplvei.b      vr5,    vr3,   0
    fst.d           f5,     a0,    0
    fst.d           f5,     a0,    FDEC_STRIDE
    fst.d           f5,     a0,    FDEC_STRIDE * 2
    fst.d           f5,     a0,    FDEC_STRIDE * 3
    fst.d           f5,     a0,    FDEC_STRIDE * 4
    fst.d           f5,     a0,    FDEC_STRIDE * 5
    fst.d           f5,     a0,    FDEC_STRIDE * 6
    fst.d           f5,     a0,    FDEC_STRIDE * 7
endfunc

/* void predict_8x8_dc_128_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_dc_128_lsx
    addi.w          t0,     zero,  1
    slli.d          t1,     t0,    (BIT_DEPTH-1)
    vreplgr2vr.b    vr5,    t1
    fst.d           f5,     a0,    0
    fst.d           f5,     a0,    FDEC_STRIDE
    fst.d           f5,     a0,    FDEC_STRIDE * 2
    fst.d           f5,     a0,    FDEC_STRIDE * 3
    fst.d           f5,     a0,    FDEC_STRIDE * 4
    fst.d           f5,     a0,    FDEC_STRIDE * 5
    fst.d           f5,     a0,    FDEC_STRIDE * 6
    fst.d           f5,     a0,    FDEC_STRIDE * 7
endfunc

/* void predict_8x8_ddl_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_ddl_lasx
    vld             vr1,    a1,    16
    vbsrl.v         vr2,    vr1,   1
    vbsrl.v         vr3,    vr1,   2

    vextrins.b      vr3,    vr1,   0xef
    vext2xv.hu.bu   xr5,    xr1
    vext2xv.hu.bu   xr6,    xr2
    vext2xv.hu.bu   xr7,    xr3

    xvslli.h        xr6,    xr6,   1
    xvadd.h         xr8,    xr5,   xr6
    xvadd.h         xr9,    xr8,   xr7
    xvssrarni.bu.h  xr9,    xr9,   2
    xvpermi.d       xr9,    xr9,   0x08

    vstelm.d        vr9,    a0,    0,                 0
    vbsrl.v         vr10,   vr9,   1
    vstelm.d        vr10,   a0,    FDEC_STRIDE,       0
    vbsrl.v         vr10,   vr9,   2
    vstelm.d        vr10,   a0,    FDEC_STRIDE * 2,   0
    vbsrl.v         vr10,   vr9,   3
    vstelm.d        vr10,   a0,    FDEC_STRIDE * 3,   0

    vbsrl.v         vr10,   vr9,   4
    vstelm.d        vr10,   a0,    FDEC_STRIDE * 4,  0
    vbsrl.v         vr10,   vr9,   5
    vstelm.d        vr10,   a0,    FDEC_STRIDE * 5,   0
    vbsrl.v         vr10,   vr9,   6
    vstelm.d        vr10,   a0,    FDEC_STRIDE * 6,   0
    vbsrl.v         vr10,   vr9,   7
    vstelm.d        vr10,   a0,    FDEC_STRIDE * 7,   0
endfunc

/* void predict_8x8_ddr_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_ddr_lasx
    vld             vr1,    a1,    7
    vbsrl.v         vr2,    vr1,   1
    vbsrl.v         vr3,    vr1,   2

    // edge[23]
    ld.bu           t0,     a1,    23
    vinsgr2vr.b     vr3,    t0,    0xe

    vext2xv.hu.bu   xr1,    xr1
    vext2xv.hu.bu   xr2,    xr2
    vext2xv.hu.bu   xr3,    xr3
    xvslli.h        xr2,    xr2,   1
    xvadd.h         xr4,    xr1,   xr2
    xvadd.h         xr5,    xr4,   xr3
    xvssrarni.bu.h  xr5,    xr5,   2
    xvpermi.d       xr6,    xr5,   0x08

    vbsrl.v         vr7,    vr6,   7
    vstelm.d        vr7,    a0,    0,                  0
    vbsrl.v         vr7,    vr6,   6
    vstelm.d        vr7,    a0,    FDEC_STRIDE,        0
    vbsrl.v         vr7,    vr6,   5
    vstelm.d        vr7,    a0,    FDEC_STRIDE * 2,    0
    vbsrl.v         vr7,    vr6,   4
    vstelm.d        vr7,    a0,    FDEC_STRIDE * 3,    0

    vbsrl.v         vr7,    vr6,   3
    vstelm.d        vr7,    a0,    FDEC_STRIDE * 4,    0
    vbsrl.v         vr7,    vr6,   2
    vstelm.d        vr7,    a0,    FDEC_STRIDE * 5,    0
    vbsrl.v         vr7,    vr6,   1
    vstelm.d        vr7,    a0,    FDEC_STRIDE * 6,    0
    vstelm.d        vr6,    a0,    FDEC_STRIDE * 7,    0
endfunc

/* void predict_8x8_vr_c( pixel *src, pixel edge[36] )
 */
function predict_8x8_vr_lasx
    vld             vr0,    a1,    8
    vbsrl.v         vr1,    vr0,   1
    vbsrl.v         vr2,    vr0,   2

    vext2xv.hu.bu   xr5,    xr0
    vext2xv.hu.bu   xr6,    xr1
    vext2xv.hu.bu   xr7,    xr2

    xvadd.h         xr10,   xr5,   xr6
    xvadd.h         xr11,   xr10,  xr6
    xvadd.h         xr12,   xr11,  xr7
    xvssrarni.bu.h  xr12,   xr12,  2
    xvssrarni.bu.h  xr10,   xr10,  1
    xvpermi.d       xr13,   xr12,  0x08
    xvpermi.d       xr14,   xr10,  0x08

    vbsrl.v         vr15,   vr13,  6
    vstelm.d        vr15,   a0,    FDEC_STRIDE,       0
    vbsll.v         vr15,   vr15,  1
    vextrins.b      vr15,   vr13,  0x04
    vstelm.d        vr15,   a0,    FDEC_STRIDE * 3,   0
    vbsll.v         vr15,   vr15,  1
    vextrins.b      vr15,   vr13,  0x02
    vstelm.d        vr15,   a0,    FDEC_STRIDE * 5,   0
    vbsll.v         vr15,   vr15,  1
    vextrins.b      vr15,   vr13,  0x00
    vstelm.d        vr15,   a0,    FDEC_STRIDE * 7,   0

    vbsrl.v         vr16,   vr14,  7
    vstelm.d        vr16,   a0,    0,                 0
    vbsll.v         vr16,   vr16,  1
    vextrins.b      vr16,   vr13,  0x05
    vstelm.d        vr16,   a0,    FDEC_STRIDE * 2,   0
    vbsll.v         vr16,   vr16,  1
    vextrins.b      vr16,   vr13,  0x03
    vstelm.d        vr16,   a0,    FDEC_STRIDE * 4,   0
    vbsll.v         vr16,   vr16,  1
    vextrins.b      vr16,   vr13,  0x01
    vstelm.d        vr16,   a0,    FDEC_STRIDE * 6,   0
endfunc

/* void predict_8x8_vl_c( pixel *src, pixel edge[36] );
 */
function predict_8x8_vl_lasx
    vld             vr0,    a1,    16
    vbsrl.v         vr1,    vr0,   1
    vbsrl.v         vr2,    vr0,   2

    vext2xv.hu.bu   xr0,    xr0
    vext2xv.hu.bu   xr1,    xr1
    vext2xv.hu.bu   xr2,    xr2

    xvadd.h         xr3,    xr0,   xr1
    xvadd.h         xr4,    xr3,   xr1
    xvadd.h         xr5,    xr4,   xr2
    xvssrarni.bu.h  xr3,    xr3,   1
    xvssrarni.bu.h  xr5,    xr5,   2
    xvpermi.d       xr6,    xr3,   0x8
    xvpermi.d       xr7,    xr5,   0x8

    vstelm.d        vr6,    a0,    0,                  0
    vstelm.d        vr7,    a0,    FDEC_STRIDE,        0
    vbsrl.v         vr8,    vr6,   1
    vstelm.d        vr8,    a0,    FDEC_STRIDE * 2,    0
    vbsrl.v         vr9,    vr7,   1
    vstelm.d        vr9,    a0,    FDEC_STRIDE * 3,    0

    vbsrl.v         vr8,    vr8,   1
    vstelm.d        vr8,    a0,    FDEC_STRIDE * 4,    0
    vbsrl.v         vr9,    vr9,   1
    vstelm.d        vr9,    a0,    FDEC_STRIDE * 5,    0
    vbsrl.v         vr8,    vr8,   1
    vstelm.d        vr8,    a0,    FDEC_STRIDE * 6,    0
    vbsrl.v         vr9,    vr9,   1
    vstelm.d        vr9,    a0,    FDEC_STRIDE * 7,    0
endfunc

/****************************************************************************
 * 16x16 prediction for intra luma block
 ****************************************************************************/
/* void x264_predict_16x16_dc_lsx( pixel *src )
 */
function predict_16x16_dc_lsx
    ld.bu          t4,      a0,      -1
    ld.bu          t5,      a0,      FDEC_STRIDE - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 2 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 3 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 4 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 5 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 6 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 7 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 8 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 9 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 10 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 11 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 12 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 13 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 14 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 15 - 1
    add.d          t4,      t4,      t5

    vld            vr4,     a0,      -FDEC_STRIDE
    vhaddw.hu.bu   vr4,     vr4,     vr4
    vhaddw.wu.hu   vr4,     vr4,     vr4
    vhaddw.du.wu   vr4,     vr4,     vr4
    vhaddw.qu.du   vr4,     vr4,     vr4
    vpickve2gr.wu  t5,      vr4,     0
    add.d          t4,      t4,      t5

    addi.d         t5,      t4,      16
    srai.w         t5,      t5,      5
    vreplgr2vr.b   vr5,     t5

    vst            vr5,     a0,      0
    vst            vr5,     a0,      FDEC_STRIDE
    vst            vr5,     a0,      FDEC_STRIDE * 2
    vst            vr5,     a0,      FDEC_STRIDE * 3
    vst            vr5,     a0,      FDEC_STRIDE * 4
    vst            vr5,     a0,      FDEC_STRIDE * 5
    vst            vr5,     a0,      FDEC_STRIDE * 6
    vst            vr5,     a0,      FDEC_STRIDE * 7

    vst            vr5,     a0,      FDEC_STRIDE * 8
    vst            vr5,     a0,      FDEC_STRIDE * 9
    vst            vr5,     a0,      FDEC_STRIDE * 10
    vst            vr5,     a0,      FDEC_STRIDE * 11
    vst            vr5,     a0,      FDEC_STRIDE * 12
    vst            vr5,     a0,      FDEC_STRIDE * 13
    vst            vr5,     a0,      FDEC_STRIDE * 14
    vst            vr5,     a0,      FDEC_STRIDE * 15
endfunc

/* void x264_predict_16x16_dc_left_lsx( pixel *src )
 */
function predict_16x16_dc_left_lsx
    ld.bu          t4,      a0,      -1
    ld.bu          t5,      a0,      FDEC_STRIDE - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 2 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 3 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 4 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 5 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 6 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 7 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 8 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 9 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 10 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 11 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 12 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 13 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 14 - 1
    add.d          t4,      t4,      t5
    ld.bu          t5,      a0,      FDEC_STRIDE * 15 - 1
    add.d          t4,      t4,      t5

    addi.d         t5,      t4,      8
    srai.w         t5,      t5,      4
    vreplgr2vr.b   vr5,     t5

    vst            vr5,     a0,      0
    vst            vr5,     a0,      FDEC_STRIDE
    vst            vr5,     a0,      FDEC_STRIDE * 2
    vst            vr5,     a0,      FDEC_STRIDE * 3
    vst            vr5,     a0,      FDEC_STRIDE * 4
    vst            vr5,     a0,      FDEC_STRIDE * 5
    vst            vr5,     a0,      FDEC_STRIDE * 6
    vst            vr5,     a0,      FDEC_STRIDE * 7

    vst            vr5,     a0,      FDEC_STRIDE * 8
    vst            vr5,     a0,      FDEC_STRIDE * 9
    vst            vr5,     a0,      FDEC_STRIDE * 10
    vst            vr5,     a0,      FDEC_STRIDE * 11
    vst            vr5,     a0,      FDEC_STRIDE * 12
    vst            vr5,     a0,      FDEC_STRIDE * 13
    vst            vr5,     a0,      FDEC_STRIDE * 14
    vst            vr5,     a0,      FDEC_STRIDE * 15
endfunc

/* void x264_predict_16x16_dc_top_lsx( pixel *src )
 */
function predict_16x16_dc_top_lsx
    vld            vr4,     a0,      -FDEC_STRIDE
    vhaddw.hu.bu   vr4,     vr4,     vr4
    vhaddw.wu.hu   vr4,     vr4,     vr4
    vhaddw.du.wu   vr4,     vr4,     vr4
    vhaddw.qu.du   vr4,     vr4,     vr4
    vpickve2gr.wu  t5,      vr4,     0

    addi.d         t5,      t5,      8
    srai.w         t5,      t5,      4
    vreplgr2vr.b   vr5,     t5

    vst            vr5,     a0,      0
    vst            vr5,     a0,      FDEC_STRIDE
    vst            vr5,     a0,      FDEC_STRIDE * 2
    vst            vr5,     a0,      FDEC_STRIDE * 3
    vst            vr5,     a0,      FDEC_STRIDE * 4
    vst            vr5,     a0,      FDEC_STRIDE * 5
    vst            vr5,     a0,      FDEC_STRIDE * 6
    vst            vr5,     a0,      FDEC_STRIDE * 7

    vst            vr5,     a0,      FDEC_STRIDE * 8
    vst            vr5,     a0,      FDEC_STRIDE * 9
    vst            vr5,     a0,      FDEC_STRIDE * 10
    vst            vr5,     a0,      FDEC_STRIDE * 11
    vst            vr5,     a0,      FDEC_STRIDE * 12
    vst            vr5,     a0,      FDEC_STRIDE * 13
    vst            vr5,     a0,      FDEC_STRIDE * 14
    vst            vr5,     a0,      FDEC_STRIDE * 15
endfunc

/* void x264_predict_16x16_dc_128_lsx( pixel *src )
 */
function predict_16x16_dc_128_lsx
    ori            t1,      t0,      1
    slli.d         t1,      t1,      BIT_DEPTH - 1
    vreplgr2vr.b   vr5,     t1

    vst            vr5,     a0,      0
    vst            vr5,     a0,      FDEC_STRIDE
    vst            vr5,     a0,      FDEC_STRIDE * 2
    vst            vr5,     a0,      FDEC_STRIDE * 3
    vst            vr5,     a0,      FDEC_STRIDE * 4
    vst            vr5,     a0,      FDEC_STRIDE * 5
    vst            vr5,     a0,      FDEC_STRIDE * 6
    vst            vr5,     a0,      FDEC_STRIDE * 7

    vst            vr5,     a0,      FDEC_STRIDE * 8
    vst            vr5,     a0,      FDEC_STRIDE * 9
    vst            vr5,     a0,      FDEC_STRIDE * 10
    vst            vr5,     a0,      FDEC_STRIDE * 11
    vst            vr5,     a0,      FDEC_STRIDE * 12
    vst            vr5,     a0,      FDEC_STRIDE * 13
    vst            vr5,     a0,      FDEC_STRIDE * 14
    vst            vr5,     a0,      FDEC_STRIDE * 15
endfunc

/* void x264_predict_16x16_h_lsx( pixel *src )
 */
function predict_16x16_h_lsx
    ld.bu           t0,    a0,    -1
    ld.bu           t1,    a0,    FDEC_STRIDE - 1
    ld.bu           t2,    a0,    FDEC_STRIDE * 2 - 1
    ld.bu           t3,    a0,    FDEC_STRIDE * 3 - 1
    ld.bu           t4,    a0,    FDEC_STRIDE * 4 - 1
    ld.bu           t5,    a0,    FDEC_STRIDE * 5 - 1
    ld.bu           t6,    a0,    FDEC_STRIDE * 6 - 1
    ld.bu           t7,    a0,    FDEC_STRIDE * 7 - 1
    vreplgr2vr.b    vr0,   t0
    vreplgr2vr.b    vr1,   t1
    vreplgr2vr.b    vr2,   t2
    vreplgr2vr.b    vr3,   t3
    vreplgr2vr.b    vr4,   t4
    vreplgr2vr.b    vr5,   t5
    vreplgr2vr.b    vr6,   t6
    vreplgr2vr.b    vr7,   t7
    vst             vr0,   a0,    0
    vst             vr1,   a0,    FDEC_STRIDE
    vst             vr2,   a0,    FDEC_STRIDE * 2
    vst             vr3,   a0,    FDEC_STRIDE * 3
    vst             vr4,   a0,    FDEC_STRIDE * 4
    vst             vr5,   a0,    FDEC_STRIDE * 5
    vst             vr6,   a0,    FDEC_STRIDE * 6
    vst             vr7,   a0,    FDEC_STRIDE * 7

    ld.bu           t0,    a0,    FDEC_STRIDE * 8 - 1
    ld.bu           t1,    a0,    FDEC_STRIDE * 9 - 1
    ld.bu           t2,    a0,    FDEC_STRIDE * 10 - 1
    ld.bu           t3,    a0,    FDEC_STRIDE * 11 - 1
    ld.bu           t4,    a0,    FDEC_STRIDE * 12 - 1
    ld.bu           t5,    a0,    FDEC_STRIDE * 13 - 1
    ld.bu           t6,    a0,    FDEC_STRIDE * 14 - 1
    ld.bu           t7,    a0,    FDEC_STRIDE * 15 - 1
    vreplgr2vr.b    vr0,   t0
    vreplgr2vr.b    vr1,   t1
    vreplgr2vr.b    vr2,   t2
    vreplgr2vr.b    vr3,   t3
    vreplgr2vr.b    vr4,   t4
    vreplgr2vr.b    vr5,   t5
    vreplgr2vr.b    vr6,   t6
    vreplgr2vr.b    vr7,   t7
    vst             vr0,   a0,    FDEC_STRIDE * 8
    vst             vr1,   a0,    FDEC_STRIDE * 9
    vst             vr2,   a0,    FDEC_STRIDE * 10
    vst             vr3,   a0,    FDEC_STRIDE * 11
    vst             vr4,   a0,    FDEC_STRIDE * 12
    vst             vr5,   a0,    FDEC_STRIDE * 13
    vst             vr6,   a0,    FDEC_STRIDE * 14
    vst             vr7,   a0,    FDEC_STRIDE * 15
endfunc

/* void x264_predict_16x16_v_lsx( pixel *src )
 */
function predict_16x16_v_lsx
    fld.d          f4,      a0,      -FDEC_STRIDE
    fld.d          f5,      a0,      4 - FDEC_STRIDE
    fld.d          f6,      a0,      8 - FDEC_STRIDE
    fld.d          f7,      a0,      12 - FDEC_STRIDE
    vilvl.w        vr4,     vr5,     vr4
    vilvl.w        vr6,     vr7,     vr6
    vilvl.d        vr4,     vr6,     vr4

    vst            vr4,     a0,      0
    vst            vr4,     a0,      FDEC_STRIDE
    vst            vr4,     a0,      FDEC_STRIDE * 2
    vst            vr4,     a0,      FDEC_STRIDE * 3
    vst            vr4,     a0,      FDEC_STRIDE * 4
    vst            vr4,     a0,      FDEC_STRIDE * 5
    vst            vr4,     a0,      FDEC_STRIDE * 6
    vst            vr4,     a0,      FDEC_STRIDE * 7

    vst            vr4,     a0,      FDEC_STRIDE * 8
    vst            vr4,     a0,      FDEC_STRIDE * 9
    vst            vr4,     a0,      FDEC_STRIDE * 10
    vst            vr4,     a0,      FDEC_STRIDE * 11
    vst            vr4,     a0,      FDEC_STRIDE * 12
    vst            vr4,     a0,      FDEC_STRIDE * 13
    vst            vr4,     a0,      FDEC_STRIDE * 14
    vst            vr4,     a0,      FDEC_STRIDE * 15
endfunc

/* void x264_predict_16x16_p_lasx( pixel *src )
 */
const mulc
.short 1, 2, 3, 4, 5, 6, 7, 8
endconst

const muld
.short 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
endconst

function predict_16x16_p_lasx
    la.local      t0,    mulc
    vld           vr3,   t0,    0
    fld.d         f4,    a0,    8  - FDEC_STRIDE
    fld.d         f5,    a0,    -1 - FDEC_STRIDE
    vxor.v        vr0,   vr0,   vr0
    vilvl.b       vr4,   vr0,   vr4
    vilvl.b       vr5,   vr0,   vr5
    vshuf4i.h     vr5,   vr5,   0x1b
    vbsll.v       vr6,   vr5,   8
    vpackod.d     vr5,   vr6,   vr5
    vsub.h        vr4,   vr4,   vr5
    vmul.h        vr4,   vr4,   vr3
    vhaddw.w.h    vr4,   vr4,   vr4
    vhaddw.d.w    vr4,   vr4,   vr4
    vhaddw.q.d    vr4,   vr4,   vr4
    vpickve2gr.w  t0,    vr4,   0       /* H */

    fld.d         f6,    a0,    FDEC_STRIDE * 8 - 1
    fld.d         f7,    a0,    FDEC_STRIDE * 9  - 1
    fld.d         f8,    a0,    FDEC_STRIDE * 10 - 1
    fld.d         f9,    a0,    FDEC_STRIDE * 11 - 1
    fld.d         f10,   a0,    FDEC_STRIDE * 12 - 1
    fld.d         f11,   a0,    FDEC_STRIDE * 13 - 1
    fld.d         f12,   a0,    FDEC_STRIDE * 14 - 1
    fld.d         f13,   a0,    FDEC_STRIDE * 15 - 1
    vilvl.b       vr6,   vr7,   vr6
    vilvl.b       vr8,   vr9,   vr8
    vilvl.b       vr10,  vr11,  vr10
    vilvl.b       vr12,  vr13,  vr12
    vilvl.h       vr6,   vr8,   vr6
    vilvl.h       vr10,  vr12,  vr10
    vilvl.w       vr6,   vr10,  vr6

    fld.d         f7,    a0,    FDEC_STRIDE * 6 - 1
    fld.d         f8,    a0,    FDEC_STRIDE * 5 - 1
    fld.d         f9,    a0,    FDEC_STRIDE * 4 - 1
    fld.d         f10,   a0,    FDEC_STRIDE * 3 - 1
    fld.d         f11,   a0,    FDEC_STRIDE * 2 - 1
    fld.d         f12,   a0,    FDEC_STRIDE - 1
    fld.d         f13,   a0,    -1
    fld.d         f14,   a0,    -FDEC_STRIDE - 1
    vilvl.b       vr7,   vr8,   vr7
    vilvl.b       vr9,   vr10,  vr9
    vilvl.b       vr11,  vr12,  vr11
    vilvl.b       vr13,  vr14,  vr13
    vilvl.h       vr7,   vr9,   vr7
    vilvl.h       vr11,  vr13,  vr11
    vilvl.w       vr7,   vr11,  vr7

    vilvl.b       vr6,   vr0,   vr6
    vilvl.b       vr7,   vr0,   vr7
    vsub.h        vr6,   vr6,   vr7
    vmul.h        vr6,   vr6,   vr3
    vhaddw.w.h    vr6,   vr6,   vr6
    vhaddw.d.w    vr6,   vr6,   vr6
    vhaddw.q.d    vr6,   vr6,   vr6
    vpickve2gr.w  t1,    vr6,   0       /* V */

    ld.bu         t2,    a0,    FDEC_STRIDE * 15 - 1
    ld.bu         t3,    a0,    15 - FDEC_STRIDE
    add.w         t2,    t2,    t3
    slli.w        t2,    t2,    4       /* a */

    slli.w        t3,    t0,    2
    add.w         t0,    t0,    t3
    addi.w        t0,    t0,    32
    srai.w        t0,    t0,    6       /* b */

    slli.w        t3,    t1,    2
    add.w         t1,    t1,    t3
    addi.w        t1,    t1,    32
    srai.w        t1,    t1,    6       /* c */

    add.w         t3,    t0,    t1
    slli.w        t4,    t3,    3
    sub.w         t4,    t4,    t3
    sub.w         t5,    t2,    t4
    addi.w        t5,    t5,    16      /* i00 */

    la.local      t3,    muld
    xvld          xr14,  t3,    0
    xvreplgr2vr.h xr12,  t0
    xvmul.h       xr12,  xr12,  xr14

.rept 16
    xvreplgr2vr.h xr14,  t5
    xvadd.h       xr13,  xr12,  xr14
    xvssrani.bu.h xr15,  xr13,  5
    xvstelm.d     xr15,  a0,    0,    0
    xvstelm.d     xr15,  a0,    8,    2
    addi.d        a0,    a0,    FDEC_STRIDE
    add.w         t5,    t5,    t1
.endr
endfunc
#endif /* !HIGH_BIT_DEPT H */
