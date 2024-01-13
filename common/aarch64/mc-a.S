/*****************************************************************************
 * mc.S: aarch64 motion compensation
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *          Janne Grunau <janne-x264@jannau.net>
 *          Mans Rullgard <mans@mansr.com>
 *          Stefan Groenroos <stefan.gronroos@gmail.com>
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
#include "mc-a-common.S"

// note: prefetch stuff assumes 64-byte cacheline

// void prefetch_ref( uint8_t *pix, intptr_t stride, int parity )
function prefetch_ref_aarch64, export=1
    cmp         w2,  #1
    csel        x2,  xzr, x1, eq
    add         x0,  x0,  #64
    add         x0,  x0,  x2,  lsl #3

    lsl         x2,  x1,  #1
    add         x3,  x1,  x1,  lsl #1
    add         x4,  x0,  x1,  lsl #2

    prfm        pldl1strm, [x0]
    prfm        pldl1strm, [x0,  x1]
    prfm        pldl1strm, [x0,  x2]
    prfm        pldl1strm, [x0,  x3]
    prfm        pldl1strm, [x4]
    prfm        pldl1strm, [x4,  x1]
    prfm        pldl1strm, [x4,  x2]
    prfm        pldl1strm, [x4,  x3]
    ret
endfunc

// void prefetch_fenc( uint8_t *pix_y,  intptr_t stride_y,
//                     uint8_t *pix_uv, intptr_t stride_uv, int mb_x )
.macro prefetch_fenc sub
function prefetch_fenc_\sub\()_aarch64, export=1
    and         w6,  w5,  #3
    and         w7,  w5,  #3
    mul         x6,  x6,  x1
    mul         x7,  x7,  x3
    add         x0,  x0,  #64
    add         x2,  x2,  #64

    add         x0,  x0,  x6,  lsl #2
    add         x6,  x0,  x1,  lsl #1
    prfm        pldl1strm, [x0]
    prfm        pldl1strm, [x0,  x1]
    prfm        pldl1strm, [x6]
    prfm        pldl1strm, [x6, x1]

    add         x2,  x2,  x7,  lsl #1
    prfm        pldl1strm, [x2]
    prfm        pldl1strm, [x2,  x3]
.ifc \sub, 422
    add         x7,  x2,  x3,  lsl #1
    prfm        pldl1strm, [x7]
    prfm        pldl1strm, [x7,  x3]
.endif
    ret
endfunc
.endm

prefetch_fenc 420
prefetch_fenc 422

function mbtree_propagate_cost_neon, export=1
    ld1r        {v5.4s},  [x5]
8:
    subs        w6,  w6,  #8
    ld1         {v1.8h},  [x1], #16
    ld1         {v2.8h},  [x2], #16
    ld1         {v3.8h},  [x3], #16
    ld1         {v4.8h},  [x4], #16
    bic         v3.8h,  #0xc0, lsl #8
    umin        v3.8h,  v2.8h,  v3.8h
    umull       v20.4s, v2.4h,  v4.4h   // propagate_intra
    umull2      v21.4s, v2.8h,  v4.8h   // propagate_intra
    usubl       v22.4s, v2.4h,  v3.4h   // propagate_num
    usubl2      v23.4s, v2.8h,  v3.8h   // propagate_num
    uxtl        v26.4s, v2.4h           // propagate_denom
    uxtl2       v27.4s, v2.8h           // propagate_denom
    uxtl        v24.4s, v1.4h
    uxtl2       v25.4s, v1.8h
    ucvtf       v20.4s, v20.4s
    ucvtf       v21.4s, v21.4s
    ucvtf       v26.4s, v26.4s
    ucvtf       v27.4s, v27.4s
    ucvtf       v22.4s, v22.4s
    ucvtf       v23.4s, v23.4s
    frecpe      v28.4s, v26.4s
    frecpe      v29.4s, v27.4s
    ucvtf       v24.4s, v24.4s
    ucvtf       v25.4s, v25.4s
    frecps      v30.4s, v28.4s, v26.4s
    frecps      v31.4s, v29.4s, v27.4s
    fmla        v24.4s, v20.4s, v5.4s   // propagate_amount
    fmla        v25.4s, v21.4s, v5.4s   // propagate_amount
    fmul        v28.4s, v28.4s, v30.4s
    fmul        v29.4s, v29.4s, v31.4s
    fmul        v16.4s, v24.4s, v22.4s
    fmul        v17.4s, v25.4s, v23.4s
    fmul        v18.4s, v16.4s, v28.4s
    fmul        v19.4s, v17.4s, v29.4s
    fcvtns      v20.4s, v18.4s
    fcvtns      v21.4s, v19.4s
    sqxtn       v0.4h,  v20.4s
    sqxtn2      v0.8h,  v21.4s
    st1         {v0.8h},  [x0], #16
    b.gt        8b
    ret
endfunc

const pw_0to15, align=5
    .short 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
endconst

function mbtree_propagate_list_internal_neon, export=1
    movrel      x11,  pw_0to15
    dup         v31.8h,  w4             // bipred_weight
    movi        v30.8h,  #0xc0, lsl #8
    ld1         {v29.8h},  [x11] //h->mb.i_mb_x,h->mb.i_mb_y
    movi        v28.4s,  #4
    movi        v27.8h,  #31
    movi        v26.8h,  #32
    dup         v24.8h,  w5             // mb_y
    zip1        v29.8h,  v29.8h, v24.8h
8:
    subs        w6,  w6,  #8
    ld1         {v1.8h},  [x1], #16     // propagate_amount
    ld1         {v2.8h},  [x2], #16     // lowres_cost
    and         v2.16b, v2.16b, v30.16b
    cmeq        v25.8h, v2.8h,  v30.8h
    umull       v16.4s, v1.4h,  v31.4h
    umull2      v17.4s, v1.8h,  v31.8h
    rshrn       v16.4h, v16.4s, #6
    rshrn2      v16.8h, v17.4s, #6
    bsl         v25.16b, v16.16b, v1.16b // if( lists_used == 3 )
    //          propagate_amount = (propagate_amount * bipred_weight + 32) >> 6
    ld1         {v4.8h,v5.8h},  [x0],  #32
    sshr        v6.8h,  v4.8h,  #5
    sshr        v7.8h,  v5.8h,  #5
    add         v6.8h,  v6.8h,  v29.8h
    add         v29.8h, v29.8h, v28.8h
    add         v7.8h,  v7.8h,  v29.8h
    add         v29.8h, v29.8h, v28.8h
    st1         {v6.8h,v7.8h},  [x3],  #32
    and         v4.16b, v4.16b, v27.16b
    and         v5.16b, v5.16b, v27.16b
    uzp1        v6.8h,  v4.8h,  v5.8h   // x & 31
    uzp2        v7.8h,  v4.8h,  v5.8h   // y & 31
    sub         v4.8h,  v26.8h, v6.8h   // 32 - (x & 31)
    sub         v5.8h,  v26.8h, v7.8h   // 32 - (y & 31)
    mul         v19.8h, v6.8h,  v7.8h   // idx3weight = y*x;
    mul         v18.8h, v4.8h,  v7.8h   // idx2weight = y*(32-x);
    mul         v17.8h, v6.8h,  v5.8h   // idx1weight = (32-y)*x;
    mul         v16.8h, v4.8h,  v5.8h   // idx0weight = (32-y)*(32-x) ;
    umull       v6.4s,  v19.4h, v25.4h
    umull2      v7.4s,  v19.8h, v25.8h
    umull       v4.4s,  v18.4h, v25.4h
    umull2      v5.4s,  v18.8h, v25.8h
    umull       v2.4s,  v17.4h, v25.4h
    umull2      v3.4s,  v17.8h, v25.8h
    umull       v0.4s,  v16.4h, v25.4h
    umull2      v1.4s,  v16.8h, v25.8h
    rshrn       v19.4h, v6.4s,  #10
    rshrn2      v19.8h, v7.4s,  #10
    rshrn       v18.4h, v4.4s,  #10
    rshrn2      v18.8h, v5.4s,  #10
    rshrn       v17.4h, v2.4s,  #10
    rshrn2      v17.8h, v3.4s,  #10
    rshrn       v16.4h, v0.4s,  #10
    rshrn2      v16.8h, v1.4s,  #10
    zip1        v0.8h,  v16.8h, v17.8h
    zip2        v1.8h,  v16.8h, v17.8h
    zip1        v2.8h,  v18.8h, v19.8h
    zip2        v3.8h,  v18.8h, v19.8h
    st1         {v0.8h,v1.8h},  [x3], #32
    st1         {v2.8h,v3.8h},  [x3], #32
    b.ge        8b
    ret
endfunc

function memcpy_aligned_neon, export=1
    tst         x2,  #16
    b.eq        32f
    sub         x2,  x2,  #16
    ldr         q0,  [x1], #16
    str         q0,  [x0], #16
32:
    tst         x2,  #32
    b.eq        640f
    sub         x2,  x2,  #32
    ldp         q0,  q1,  [x1], #32
    stp         q0,  q1,  [x0], #32
640:
    cbz         x2,  1f
64:
    subs        x2,  x2,  #64
    ldp         q0,  q1,  [x1, #32]
    ldp         q2,  q3,  [x1], #64
    stp         q0,  q1,  [x0, #32]
    stp         q2,  q3,  [x0], #64
    b.gt        64b
1:
    ret
endfunc

function memzero_aligned_neon, export=1
    movi        v0.16b,  #0
    movi        v1.16b,  #0
1:
    subs        x1,  x1,  #128
    stp         q0,  q1,  [x0, #96]
    stp         q0,  q1,  [x0, #64]
    stp         q0,  q1,  [x0, #32]
    stp         q0,  q1,  [x0], 128
    b.gt        1b
    ret
endfunc

// void mbtree_fix8_pack( int16_t *dst, float *src, int count )
function mbtree_fix8_pack_neon, export=1
    subs        w3,  w2,  #8
    b.lt        2f
1:
    subs        w3,  w3,  #8
    ld1         {v0.4s,v1.4s}, [x1], #32
    fcvtzs      v0.4s,  v0.4s,  #8
    fcvtzs      v1.4s,  v1.4s,  #8
    sqxtn       v2.4h,  v0.4s
    sqxtn2      v2.8h,  v1.4s
    rev16       v3.16b, v2.16b
    st1         {v3.8h},  [x0], #16
    b.ge        1b
2:
    adds        w3,  w3,  #8
    b.eq        4f
3:
    subs        w3,  w3,  #1
    ldr         s0, [x1], #4
    fcvtzs      w4,  s0,  #8
    rev16       w5,  w4
    strh        w5, [x0], #2
    b.gt        3b
4:
    ret
endfunc

// void mbtree_fix8_unpack( float *dst, int16_t *src, int count )
function mbtree_fix8_unpack_neon, export=1
    subs        w3,  w2,  #8
    b.lt        2f
1:
    subs        w3,  w3,  #8
    ld1         {v0.8h}, [x1], #16
    rev16       v1.16b, v0.16b
    sxtl        v2.4s,  v1.4h
    sxtl2       v3.4s,  v1.8h
    scvtf       v4.4s,  v2.4s,  #8
    scvtf       v5.4s,  v3.4s,  #8
    st1         {v4.4s,v5.4s}, [x0], #32
    b.ge        1b
2:
    adds        w3,  w3,  #8
    b.eq        4f
3:
    subs        w3,  w3,  #1
    ldrh        w4, [x1], #2
    rev16       w5,  w4
    sxth        w6,  w5
    scvtf       s0,  w6,  #8
    str         s0, [x0], #4
    b.gt        3b
4:
    ret
endfunc

#if BIT_DEPTH == 8

// void pixel_avg( uint8_t *dst,  intptr_t dst_stride,
//                 uint8_t *src1, intptr_t src1_stride,
//                 uint8_t *src2, intptr_t src2_stride, int weight );
.macro AVGH w h
function pixel_avg_\w\()x\h\()_neon, export=1
    mov         w10, #64
    cmp         w6,  #32
    mov         w9, #\h
    b.eq        pixel_avg_w\w\()_neon
    subs        w7,  w10,  w6
    b.lt        pixel_avg_weight_w\w\()_add_sub_neon     // weight > 64
    cmp         w6,  #0
    b.ge        pixel_avg_weight_w\w\()_add_add_neon
    b           pixel_avg_weight_w\w\()_sub_add_neon     // weight < 0
endfunc
.endm

AVGH  4, 2
AVGH  4, 4
AVGH  4, 8
AVGH  4, 16
AVGH  8, 4
AVGH  8, 8
AVGH  8, 16
AVGH 16, 8
AVGH 16, 16

// 0 < weight < 64
.macro weight_add_add dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s1, v30.16b
    umlal2      \dst, \s2, v31.16b
.else
    umull       \dst, \s1, v30.8b
    umlal       \dst, \s2, v31.8b
.endif
.endm

// weight > 64
.macro weight_add_sub dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s1, v30.16b
    umlsl2      \dst, \s2, v31.16b
.else
    umull       \dst, \s1, v30.8b
    umlsl       \dst, \s2, v31.8b
.endif
.endm

// weight < 0
.macro weight_sub_add dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s2, v31.16b
    umlsl2      \dst, \s1, v30.16b
.else
    umull       \dst, \s2, v31.8b
    umlsl       \dst, \s1, v30.8b
.endif
.endm

.macro AVG_WEIGHT ext
function pixel_avg_weight_w4_\ext\()_neon
    load_weights_\ext
    dup         v30.8b, w6
    dup         v31.8b, w7
1:  // height loop
    subs        w9,  w9,  #2
    ld1         {v0.s}[0], [x2], x3
    ld1         {v1.s}[0], [x4], x5
    weight_\ext v4.8h,  v0.8b,  v1.8b
    ld1         {v2.s}[0], [x2], x3
    ld1         {v3.s}[0], [x4], x5
    sqrshrun    v0.8b,  v4.8h,  #6
    weight_\ext v5.8h,  v2.8b,  v3.8b
    st1         {v0.s}[0], [x0], x1
    sqrshrun    v1.8b,  v5.8h,  #6
    st1         {v1.s}[0], [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_weight_w8_\ext\()_neon
    load_weights_\ext
    dup         v30.8b, w6
    dup         v31.8b, w7
1:  // height loop
    subs        w9,  w9,  #4
    ld1         {v0.8b}, [x2], x3
    ld1         {v1.8b}, [x4], x5
    weight_\ext v16.8h, v0.8b,  v1.8b
    ld1         {v2.8b}, [x2], x3
    ld1         {v3.8b}, [x4], x5
    weight_\ext v17.8h, v2.8b,  v3.8b
    ld1         {v4.8b}, [x2], x3
    ld1         {v5.8b}, [x4], x5
    weight_\ext v18.8h, v4.8b,  v5.8b
    ld1         {v6.8b}, [x2], x3
    ld1         {v7.8b}, [x4], x5
    weight_\ext v19.8h, v6.8b,  v7.8b
    sqrshrun    v0.8b,  v16.8h, #6
    sqrshrun    v1.8b,  v17.8h, #6
    sqrshrun    v2.8b,  v18.8h, #6
    sqrshrun    v3.8b,  v19.8h, #6
    st1         {v0.8b}, [x0], x1
    st1         {v1.8b}, [x0], x1
    st1         {v2.8b}, [x0], x1
    st1         {v3.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_weight_w16_\ext\()_neon
    load_weights_\ext
    dup         v30.16b, w6
    dup         v31.16b, w7
1:  // height loop
    subs        w9,  w9,  #2
    ld1         {v0.16b}, [x2], x3
    ld1         {v1.16b}, [x4], x5
    weight_\ext v16.8h, v0.8b,  v1.8b
    weight_\ext v17.8h, v0.16b, v1.16b, 2
    ld1         {v2.16b}, [x2], x3
    ld1         {v3.16b}, [x4], x5
    weight_\ext v18.8h, v2.8b,  v3.8b
    weight_\ext v19.8h, v2.16b, v3.16b, 2
    sqrshrun    v0.8b,  v16.8h, #6
    sqrshrun    v1.8b,  v18.8h, #6
    sqrshrun2   v0.16b, v17.8h, #6
    sqrshrun2   v1.16b, v19.8h, #6
    st1         {v0.16b}, [x0], x1
    st1         {v1.16b}, [x0], x1
    b.gt        1b
    ret
endfunc
.endm

AVG_WEIGHT add_add
AVG_WEIGHT add_sub
AVG_WEIGHT sub_add

function pixel_avg_w8_neon
1:  subs        w9,  w9,  #4
    ld1         {v0.8b}, [x2], x3
    ld1         {v1.8b}, [x4], x5
    ld1         {v2.8b}, [x2], x3
    urhadd      v0.8b,  v0.8b,  v1.8b
    ld1         {v3.8b}, [x4], x5
    st1         {v0.8b}, [x0], x1
    ld1         {v4.8b}, [x2], x3
    urhadd      v1.8b,  v2.8b,  v3.8b
    ld1         {v5.8b}, [x4], x5
    st1         {v1.8b}, [x0], x1
    ld1         {v6.8b}, [x2], x3
    ld1         {v7.8b}, [x4], x5
    urhadd      v2.8b,  v4.8b,  v5.8b
    urhadd      v3.8b,  v6.8b,  v7.8b
    st1         {v2.8b}, [x0], x1
    st1         {v3.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_w16_neon
1:  subs        w9,  w9,  #4
    ld1         {v0.16b}, [x2], x3
    ld1         {v1.16b}, [x4], x5
    ld1         {v2.16b}, [x2], x3
    urhadd      v0.16b, v0.16b, v1.16b
    ld1         {v3.16b}, [x4], x5
    st1         {v0.16b}, [x0], x1
    ld1         {v4.16b}, [x2], x3
    urhadd      v1.16b, v2.16b, v3.16b
    ld1         {v5.16b}, [x4], x5
    st1         {v1.16b}, [x0], x1
    ld1         {v6.16b}, [x2], x3
    ld1         {v7.16b}, [x4], x5
    urhadd      v2.16b, v4.16b, v5.16b
    urhadd      v3.16b, v6.16b, v7.16b
    st1         {v2.16b}, [x0], x1
    st1         {v3.16b}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg2_w4_neon, export=1
1:
    subs        w5,  w5,  #2
    ld1         {v0.s}[0],  [x2], x3
    ld1         {v2.s}[0],  [x4], x3
    urhadd      v0.8b,  v0.8b,  v2.8b
    ld1         {v1.s}[0],  [x2], x3
    ld1         {v3.s}[0],  [x4], x3
    urhadd      v1.8b,  v1.8b,  v3.8b
    st1         {v0.s}[0], [x0], x1
    st1         {v1.s}[0], [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg2_w8_neon, export=1
1:
    subs        w5,  w5,  #2
    ld1         {v0.8b}, [x2], x3
    ld1         {v2.8b}, [x4], x3
    urhadd      v0.8b,  v0.8b,  v2.8b
    ld1         {v1.8b}, [x2], x3
    ld1         {v3.8b}, [x4], x3
    urhadd      v1.8b,  v1.8b,  v3.8b
    st1         {v0.8b}, [x0], x1
    st1         {v1.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg2_w16_neon, export=1
1:
    subs        w5,  w5,  #2
    ld1         {v0.16b}, [x2], x3
    ld1         {v2.16b}, [x4], x3
    urhadd      v0.16b, v0.16b, v2.16b
    ld1         {v1.16b}, [x2], x3
    ld1         {v3.16b}, [x4], x3
    urhadd      v1.16b, v1.16b, v3.16b
    st1         {v0.16b}, [x0], x1
    st1         {v1.16b}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg2_w20_neon, export=1
    sub         x1,  x1,  #16
1:
    subs        w5,  w5,  #2
    ld1         {v0.16b,v1.16b}, [x2], x3
    ld1         {v2.16b,v3.16b}, [x4], x3
    urhadd      v0.16b, v0.16b, v2.16b
    urhadd      v1.8b,  v1.8b,  v3.8b
    ld1         {v4.16b,v5.16b}, [x2], x3
    ld1         {v6.16b,v7.16b}, [x4], x3
    urhadd      v4.16b, v4.16b, v6.16b
    urhadd      v5.8b,  v5.8b,  v7.8b
    st1         {v0.16b},  [x0], #16
    st1         {v1.s}[0], [x0], x1
    st1         {v4.16b},  [x0], #16
    st1         {v5.s}[0], [x0], x1
    b.gt        1b
    ret
endfunc

.macro weight_prologue type
    mov         w9,  w5                 // height
.ifc \type, full
    ldr         w12, [x4, #32]          // denom
.endif
    ldp         w4,  w5,  [x4, #32+4]   // scale, offset
    dup         v0.16b, w4
    dup         v1.8h,  w5
.ifc \type, full
    neg         w12, w12
    dup         v2.8h,  w12
.endif
.endm

// void mc_weight( uint8_t *src, intptr_t src_stride, uint8_t *dst,
//                 intptr_t dst_stride, const x264_weight_t *weight, int h )
function mc_weight_w20_neon, export=1
    weight_prologue full
    sub         x1,  x1,  #16
1:
    subs        w9,  w9,  #2
    ld1         {v16.8b,v17.8b,v18.8b}, [x2], x3
    ld1         {v19.8b,v20.8b,v21.8b}, [x2], x3
    umull       v22.8h, v16.8b, v0.8b
    umull       v23.8h, v17.8b, v0.8b
    zip1        v18.2s, v18.2s, v21.2s
    umull       v25.8h, v19.8b, v0.8b
    umull       v26.8h, v20.8b, v0.8b
    umull       v24.8h, v18.8b, v0.8b
    srshl       v22.8h, v22.8h, v2.8h
    srshl       v23.8h, v23.8h, v2.8h
    srshl       v24.8h, v24.8h, v2.8h
    srshl       v25.8h, v25.8h, v2.8h
    srshl       v26.8h, v26.8h, v2.8h
    add         v22.8h, v22.8h, v1.8h
    add         v23.8h, v23.8h, v1.8h
    add         v24.8h, v24.8h, v1.8h
    add         v25.8h, v25.8h, v1.8h
    add         v26.8h, v26.8h, v1.8h
    sqxtun      v4.8b,  v22.8h
    sqxtun2     v4.16b, v23.8h
    sqxtun      v6.8b,  v24.8h
    sqxtun      v5.8b,  v25.8h
    sqxtun2     v5.16b, v26.8h
    st1         {v4.16b},  [x0], #16
    st1         {v6.s}[0], [x0], x1
    st1         {v5.16b},  [x0], #16
    st1         {v6.s}[1], [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w16_neon, export=1
    weight_prologue full
weight16_loop:
1:
    subs        w9,  w9,  #2
    ld1         {v4.16b}, [x2], x3
    ld1         {v5.16b}, [x2], x3
    umull       v22.8h, v4.8b,  v0.8b
    umull2      v23.8h, v4.16b, v0.16b
    umull       v24.8h, v5.8b,  v0.8b
    umull2      v25.8h, v5.16b, v0.16b
    srshl       v22.8h, v22.8h, v2.8h
    srshl       v23.8h, v23.8h, v2.8h
    srshl       v24.8h, v24.8h, v2.8h
    srshl       v25.8h, v25.8h, v2.8h
    add         v22.8h, v22.8h, v1.8h
    add         v23.8h, v23.8h, v1.8h
    add         v24.8h, v24.8h, v1.8h
    add         v25.8h, v25.8h, v1.8h
    sqxtun      v4.8b,  v22.8h
    sqxtun2     v4.16b, v23.8h
    sqxtun      v5.8b,  v24.8h
    sqxtun2     v5.16b, v25.8h
    st1         {v4.16b}, [x0], x1
    st1         {v5.16b}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w8_neon, export=1
    weight_prologue full
1:
    subs        w9,  w9,  #2
    ld1         {v16.8b}, [x2], x3
    ld1         {v17.8b}, [x2], x3
    umull       v4.8h,  v16.8b, v0.8b
    umull       v5.8h,  v17.8b, v0.8b
    srshl       v4.8h,  v4.8h,  v2.8h
    srshl       v5.8h,  v5.8h,  v2.8h
    add         v4.8h,  v4.8h,  v1.8h
    add         v5.8h,  v5.8h,  v1.8h
    sqxtun      v16.8b, v4.8h
    sqxtun      v17.8b, v5.8h
    st1         {v16.8b}, [x0], x1
    st1         {v17.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w4_neon, export=1
    weight_prologue full
1:
    subs        w9,  w9,  #2
    ld1         {v16.s}[0], [x2], x3
    ld1         {v16.s}[1], [x2], x3
    umull       v4.8h,  v16.8b, v0.8b
    srshl       v4.8h,  v4.8h,  v2.8h
    add         v4.8h,  v4.8h,  v1.8h
    sqxtun      v16.8b, v4.8h
    st1         {v16.s}[0], [x0], x1
    st1         {v16.s}[1], [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w20_nodenom_neon, export=1
    weight_prologue nodenom
    sub         x1,  x1,  #16
1:
    subs        w9,  w9,  #2
    ld1         {v16.8b,v17.8b,v18.8b}, [x2], x3
    mov         v27.16b, v1.16b
    mov         v28.16b, v1.16b
    ld1         {v19.8b,v20.8b,v21.8b}, [x2], x3
    mov         v31.16b, v1.16b
    mov         v29.16b, v1.16b
    mov         v30.16b, v1.16b
    zip1        v18.2s, v18.2s, v21.2s
    umlal       v27.8h, v16.8b, v0.8b
    umlal       v28.8h, v17.8b, v0.8b
    umlal       v31.8h, v18.8b, v0.8b
    umlal       v29.8h, v19.8b, v0.8b
    umlal       v30.8h, v20.8b, v0.8b
    sqxtun      v4.8b,  v27.8h
    sqxtun2     v4.16b, v28.8h
    sqxtun      v5.8b,  v29.8h
    sqxtun2     v5.16b, v30.8h
    sqxtun      v6.8b,  v31.8h
    st1         {v4.16b},  [x0], #16
    st1         {v6.s}[0], [x0], x1
    st1         {v5.16b},  [x0], #16
    st1         {v6.s}[1], [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w16_nodenom_neon, export=1
    weight_prologue nodenom
1:
    subs        w9,  w9,  #2
    ld1         {v6.16b},  [x2], x3
    mov         v27.16b, v1.16b
    mov         v28.16b, v1.16b
    ld1         {v7.16b},  [x2], x3
    mov         v29.16b, v1.16b
    mov         v30.16b, v1.16b
    umlal       v27.8h, v6.8b,  v0.8b
    umlal2      v28.8h, v6.16b, v0.16b
    umlal       v29.8h, v7.8b,  v0.8b
    umlal2      v30.8h, v7.16b, v0.16b
    sqxtun      v4.8b,  v27.8h
    sqxtun2     v4.16b, v28.8h
    sqxtun      v5.8b,  v29.8h
    sqxtun2     v5.16b, v30.8h
    st1         {v4.16b},  [x0], x1
    st1         {v5.16b},  [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w8_nodenom_neon, export=1
    weight_prologue nodenom
1:
    subs        w9,  w9,  #2
    ld1         {v16.8b}, [x2], x3
    mov         v27.16b, v1.16b
    ld1         {v17.8b}, [x2], x3
    mov         v29.16b, v1.16b
    umlal       v27.8h, v16.8b, v0.8b
    umlal       v29.8h, v17.8b, v0.8b
    sqxtun      v4.8b,  v27.8h
    sqxtun      v5.8b,  v29.8h
    st1         {v4.8b},  [x0], x1
    st1         {v5.8b},  [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w4_nodenom_neon, export=1
    weight_prologue nodenom
1:
    subs        w9,  w9,  #2
    ld1         {v16.s}[0], [x2], x3
    ld1         {v16.s}[1], [x2], x3
    mov         v27.16b, v1.16b
    umlal       v27.8h, v16.8b, v0.8b
    sqxtun      v4.8b,  v27.8h
    st1         {v4.s}[0],  [x0], x1
    st1         {v4.s}[1],  [x0], x1
    b.gt        1b
    ret
endfunc

.macro weight_simple_prologue
    ldr         w6,  [x4]               // offset
    dup         v1.16b,  w6
.endm

.macro weight_simple name op
function mc_weight_w20_\name\()_neon, export=1
    weight_simple_prologue
1:
    subs        w5,  w5,  #2
    ldr         s18, [x2, #16]
    ld1         {v16.16b}, [x2], x3
    ldr         s19, [x2, #16]
    ld1         {v17.16b}, [x2], x3
    \op         v18.8b,  v18.8b,  v1.8b
    \op         v16.16b, v16.16b, v1.16b
    \op         v19.8b,  v19.8b,  v1.8b
    \op         v17.16b, v17.16b, v1.16b
    str         s18, [x0, #16]
    st1         {v16.16b}, [x0], x1
    str         s19, [x0, #16]
    st1         {v17.16b}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w16_\name\()_neon, export=1
    weight_simple_prologue
1:
    subs        w5,  w5,  #2
    ld1         {v16.16b}, [x2], x3
    ld1         {v17.16b}, [x2], x3
    \op         v16.16b, v16.16b, v1.16b
    \op         v17.16b, v17.16b, v1.16b
    st1         {v16.16b}, [x0], x1
    st1         {v17.16b}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w8_\name\()_neon, export=1
    weight_simple_prologue
1:
    subs        w5,  w5,  #2
    ld1         {v16.8b}, [x2], x3
    ld1         {v17.8b}, [x2], x3
    \op         v16.8b, v16.8b, v1.8b
    \op         v17.8b, v17.8b, v1.8b
    st1         {v16.8b}, [x0], x1
    st1         {v17.8b}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w4_\name\()_neon, export=1
    weight_simple_prologue
1:
    subs        w5,  w5,  #2
    ld1         {v16.s}[0], [x2], x3
    ld1         {v16.s}[1], [x2], x3
    \op         v16.8b, v16.8b, v1.8b
    st1         {v16.s}[0], [x0], x1
    st1         {v16.s}[1], [x0], x1
    b.gt        1b
    ret
endfunc
.endm

weight_simple offsetadd, uqadd
weight_simple offsetsub, uqsub


// void mc_copy( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride, int height )
function mc_copy_w4_neon, export=1
1:
    subs        w4,  w4,  #4
    ld1         {v0.s}[0],  [x2],  x3
    ld1         {v1.s}[0],  [x2],  x3
    ld1         {v2.s}[0],  [x2],  x3
    ld1         {v3.s}[0],  [x2],  x3
    st1         {v0.s}[0],  [x0],  x1
    st1         {v1.s}[0],  [x0],  x1
    st1         {v2.s}[0],  [x0],  x1
    st1         {v3.s}[0],  [x0],  x1
    b.gt        1b
    ret
endfunc

function mc_copy_w8_neon, export=1
1:  subs        w4,  w4,  #4
    ld1         {v0.8b},  [x2],  x3
    ld1         {v1.8b},  [x2],  x3
    ld1         {v2.8b},  [x2],  x3
    ld1         {v3.8b},  [x2],  x3
    st1         {v0.8b},  [x0],  x1
    st1         {v1.8b},  [x0],  x1
    st1         {v2.8b},  [x0],  x1
    st1         {v3.8b},  [x0],  x1
    b.gt        1b
    ret
endfunc

function mc_copy_w16_neon, export=1
1:  subs        w4,  w4,  #4
    ld1         {v0.16b}, [x2],  x3
    ld1         {v1.16b}, [x2],  x3
    ld1         {v2.16b}, [x2],  x3
    ld1         {v3.16b}, [x2],  x3
    st1         {v0.16b}, [x0],  x1
    st1         {v1.16b}, [x0],  x1
    st1         {v2.16b}, [x0],  x1
    st1         {v3.16b}, [x0],  x1
    b.gt        1b
    ret
endfunc

// void mc_chroma( uint8_t *dst_u, uint8_t *dst_v,
//                 intptr_t i_dst_stride,
//                 uint8_t *src, intptr_t i_src_stride,
//                 int dx, int dy, int i_width, int i_height );
function mc_chroma_neon, export=1
    ldr         w15, [sp]               // height
    sbfx        x12, x6,  #3,  #29      // asr(3) and sign extend
    sbfx        x11, x5,  #3,  #29      // asr(3) and sign extend
    cmp         w7,  #4
    mul         x12, x12, x4
    add         x3,  x3,  x11, lsl #1

    and         w5,  w5,  #7
    and         w6,  w6,  #7

    add         x3,  x3,  x12

    //pld             [x3]
    //pld             [x3, x4]

    b.gt        mc_chroma_w8_neon
    b.eq        mc_chroma_w4_neon
endfunc

.macro CHROMA_MC_START r00, r01, r10, r11
    mul         w12, w5,  w6            // cD = d8x    *d8y
    lsl         w13, w5,  #3
    add         w9,  w12,  #64
    lsl         w14, w6,  #3
    tst         w12, w12
    sub         w9,  w9,  w13
    sub         w10, w13, w12           // cB = d8x    *(8-d8y);
    sub         w11, w14, w12           // cC = (8-d8x)*d8y
    sub         w9,  w9,  w14           // cA = (8-d8x)*(8-d8y);
.endm

.macro CHROMA_MC width, vsize
function mc_chroma_w\width\()_neon
// since the element size varies, there's a different index for the 2nd store
.if \width == 4
    .set idx2, 1
.else
    .set idx2, 2
.endif
    CHROMA_MC_START
    b.eq        2f

    ld2         {v28.8b,v29.8b}, [x3], x4
    dup         v0.8b,  w9               // cA
    dup         v1.8b,  w10              // cB

    ext         v6.8b, v28.8b, v6.8b,  #1
    ext         v7.8b, v29.8b, v7.8b,  #1

    ld2         {v30.8b,v31.8b}, [x3], x4
    dup         v2.8b,  w11              // cC
    dup         v3.8b,  w12              // cD

    ext         v22.8b, v30.8b, v22.8b,  #1
    ext         v23.8b, v31.8b, v23.8b,  #1

    trn1        v0.2s,  v0.2s,  v1.2s
    trn1        v2.2s,  v2.2s,  v3.2s

    trn1        v4.2s,  v28.2s, v6.2s
    trn1        v5.2s,  v29.2s, v7.2s
    trn1        v20.2s, v30.2s, v22.2s
    trn1        v21.2s, v31.2s, v23.2s
1:  // height loop, interpolate xy
    subs        w15, w15, #2
    umull       v16.8h, v4.8b,  v0.8b
    umlal       v16.8h, v20.8b, v2.8b
    umull       v17.8h, v5.8b,  v0.8b
    umlal       v17.8h, v21.8b, v2.8b

    ld2         {v28.8b,v29.8b}, [x3], x4
    transpose   v24.2d, v25.2d, v16.2d, v17.2d

    ext         v6.8b, v28.8b, v6.8b,  #1
    ext         v7.8b, v29.8b, v7.8b,  #1

    trn1        v4.2s,  v28.2s, v6.2s
    trn1        v5.2s,  v29.2s, v7.2s

    add         v16.8h, v24.8h, v25.8h

    umull       v18.8h, v20.8b, v0.8b
    umlal       v18.8h, v4.8b,  v2.8b
    umull       v19.8h, v21.8b, v0.8b
    umlal       v19.8h, v5.8b,  v2.8b

    ld2         {v30.8b,v31.8b}, [x3], x4
    transpose   v26.2d, v27.2d, v18.2d, v19.2d

    ext         v22.8b, v30.8b, v22.8b,  #1
    ext         v23.8b, v31.8b, v23.8b,  #1
    trn1        v20.2s, v30.2s, v22.2s
    trn1        v21.2s, v31.2s, v23.2s

    add         v17.8h, v26.8h, v27.8h

    rshrn       v16.8b, v16.8h, #6
    rshrn       v17.8b, v17.8h, #6

    //pld         [x3]
    //pld         [x3, x4]

    st1         {v16.\vsize}[0],    [x0], x2
    st1         {v16.\vsize}[idx2], [x1], x2
    st1         {v17.\vsize}[0],    [x0], x2
    st1         {v17.\vsize}[idx2], [x1], x2
    b.gt        1b

    ret
2:  // dx or dy are 0
    tst         w11, w11
    add         w10, w10,  w11
    dup         v0.8b,  w9
    dup         v1.8b,  w10

    b.eq        4f

    ld1         {v4.8b}, [x3], x4
    ld1         {v6.8b}, [x3], x4
3:  // vertical interpolation loop
    subs        w15, w15, #2
    umull       v16.8h, v4.8b,  v0.8b
    ld1         {v4.8b}, [x3], x4
    umlal       v16.8h, v6.8b,  v1.8b
    umull       v17.8h, v6.8b,  v0.8b
    ld1         {v6.8b}, [x3], x4
    umlal       v17.8h, v4.8b,  v1.8b

    rshrn       v20.8b, v16.8h, #6      // uvuvuvuv
    rshrn       v21.8b, v17.8h, #6      // uvuvuvuv

    uzp1        v16.8b, v20.8b, v21.8b  // d16=uuuu|uuuu, d17=vvvv|vvvv
    uzp2        v17.8b, v20.8b, v21.8b  // d16=uuuu|uuuu, d17=vvvv|vvvv

    //pld         [x3]
    //pld         [x3, x4]

    st1         {v16.\vsize}[0],    [x0], x2
    st1         {v16.\vsize}[idx2], [x0], x2
    st1         {v17.\vsize}[0],    [x1], x2
    st1         {v17.\vsize}[idx2], [x1], x2
    b.gt        3b

    ret

4:  // dy is 0
    ld1         {v4.8b,v5.8b}, [x3], x4
    ld1         {v6.8b,v7.8b}, [x3], x4

    ext         v5.8b,  v4.8b,  v5.8b,  #2
    ext         v7.8b,  v6.8b,  v7.8b,  #2
5:  // horizontal interpolation loop
    subs        w15, w15, #2
    umull       v16.8h, v4.8b,  v0.8b
    umlal       v16.8h, v5.8b,  v1.8b
    umull       v17.8h, v6.8b,  v0.8b
    umlal       v17.8h, v7.8b,  v1.8b

    ld1         {v4.8b,v5.8b}, [x3], x4
    ld1         {v6.8b,v7.8b}, [x3], x4
    rshrn       v20.8b, v16.8h, #6
    rshrn       v21.8b, v17.8h, #6
    ext         v5.8b,  v4.8b,  v5.8b,  #2
    ext         v7.8b,  v6.8b,  v7.8b,  #2
    uzp1        v16.8b, v20.8b, v21.8b  // d16=uuuu|uuuu, d17=vvvv|vvvv
    uzp2        v17.8b, v20.8b, v21.8b  // d16=uuuu|uuuu, d17=vvvv|vvvv

    //pld         [x3]
    //pld         [x3, x4]

    st1         {v16.\vsize}[0],    [x0], x2
    st1         {v16.\vsize}[idx2], [x0], x2
    st1         {v17.\vsize}[0],    [x1], x2
    st1         {v17.\vsize}[idx2], [x1], x2
    b.gt        5b

    ret
endfunc
.endm

    CHROMA_MC   2, h
    CHROMA_MC   4, s

function mc_chroma_w8_neon
    CHROMA_MC_START
    b.eq        2f
    ld2         {v4.16b,v5.16b}, [x3], x4
    ld2         {v20.16b,v21.16b}, [x3], x4
    dup         v0.8b, w9               // cA
    dup         v1.8b, w10              // cB

    ext         v6.16b, v4.16b, v4.16b, #1
    ext         v7.16b, v5.16b, v5.16b, #1

    dup         v2.8b, w11              // cC
    dup         v3.8b, w12              // cD

    ext         v22.16b, v20.16b, v20.16b, #1
    ext         v23.16b, v21.16b, v21.16b, #1

1:  // height loop, interpolate xy
    subs        w15, w15, #2
    umull       v16.8h, v4.8b,  v0.8b
    umlal       v16.8h, v6.8b,  v1.8b
    umlal       v16.8h, v20.8b, v2.8b
    umlal       v16.8h, v22.8b, v3.8b

    umull       v17.8h, v5.8b,  v0.8b
    umlal       v17.8h, v7.8b,  v1.8b
    umlal       v17.8h, v21.8b, v2.8b
    umlal       v17.8h, v23.8b, v3.8b

    ld2         {v4.16b,v5.16b}, [x3], x4

    ext         v6.16b, v4.16b, v4.16b, #1
    ext         v7.16b, v5.16b, v5.16b, #1

    umull       v18.8h, v20.8b, v0.8b
    umlal       v18.8h, v22.8b, v1.8b
    umlal       v18.8h, v4.8b,  v2.8b
    umlal       v18.8h, v6.8b,  v3.8b

    umull       v19.8h, v21.8b, v0.8b
    umlal       v19.8h, v23.8b, v1.8b
    umlal       v19.8h, v5.8b,  v2.8b
    umlal       v19.8h, v7.8b,  v3.8b

    ld2         {v20.16b,v21.16b}, [x3], x4

    rshrn       v16.8b, v16.8h, #6
    rshrn       v17.8b, v17.8h, #6
    rshrn       v18.8b, v18.8h, #6
    rshrn       v19.8b, v19.8h, #6

    ext         v22.16b, v20.16b, v20.16b, #1
    ext         v23.16b, v21.16b, v21.16b, #1

    //pld         [x3]
    //pld         [x3, x4]

    st1         {v16.8b}, [x0], x2
    st1         {v17.8b}, [x1], x2
    st1         {v18.8b}, [x0], x2
    st1         {v19.8b}, [x1], x2
    b.gt        1b

    ret
2:  // dx or dy are 0
    tst         w11, w11
    add         w10, w10, w11
    dup         v0.8b, w9
    dup         v1.8b, w10

    b.eq        4f

    ld2         {v4.8b,v5.8b}, [x3], x4
    ld2         {v6.8b,v7.8b}, [x3], x4
3:  // vertical interpolation loop
    subs        w15, w15, #2
    umull       v16.8h, v4.8b,  v0.8b //U
    umlal       v16.8h, v6.8b,  v1.8b
    umull       v17.8h, v5.8b,  v0.8b //V
    umlal       v17.8h, v7.8b,  v1.8b

    ld2         {v4.8b,v5.8b}, [x3], x4

    umull       v18.8h, v6.8b,  v0.8b
    umlal       v18.8h, v4.8b,  v1.8b
    umull       v19.8h, v7.8b,  v0.8b
    umlal       v19.8h, v5.8b,  v1.8b

    ld2         {v6.8b,v7.8b}, [x3], x4

    rshrn       v16.8b, v16.8h, #6
    rshrn       v17.8b, v17.8h, #6
    rshrn       v18.8b, v18.8h, #6
    rshrn       v19.8b, v19.8h, #6

    //pld         [x3]
    //pld         [x3, x4]

    st1         {v16.8b}, [x0], x2
    st1         {v17.8b}, [x1], x2
    st1         {v18.8b}, [x0], x2
    st1         {v19.8b}, [x1], x2
    b.gt        3b

    ret
4:  // dy is 0
    ld2         {v4.16b,v5.16b}, [x3], x4
    ext         v6.16b, v4.16b, v4.16b, #1
    ext         v7.16b, v5.16b, v5.16b, #1
    ld2         {v20.16b,v21.16b}, [x3], x4
    ext         v22.16b, v20.16b, v20.16b, #1
    ext         v23.16b, v21.16b, v21.16b, #1
5:  // horizontal interpolation loop
    subs        w15, w15, #2
    umull       v16.8h, v4.8b,  v0.8b //U
    umlal       v16.8h, v6.8b,  v1.8b
    umull       v17.8h, v5.8b,  v0.8b //V
    umlal       v17.8h, v7.8b,  v1.8b

    ld2         {v4.16b,v5.16b}, [x3], x4

    umull       v18.8h, v20.8b, v0.8b
    umlal       v18.8h, v22.8b, v1.8b
    umull       v19.8h, v21.8b, v0.8b
    umlal       v19.8h, v23.8b, v1.8b

    ld2         {v20.16b,v21.16b}, [x3], x4

    rshrn       v16.8b, v16.8h, #6
    rshrn       v17.8b, v17.8h, #6
    rshrn       v18.8b, v18.8h, #6
    rshrn       v19.8b, v19.8h, #6

    ext         v6.16b, v4.16b, v4.16b, #1
    ext         v7.16b, v5.16b, v5.16b, #1
    ext         v22.16b, v20.16b, v20.16b, #1
    ext         v23.16b, v21.16b, v21.16b, #1

    //pld         [x3]
    //pld         [x3, x4]

    st1         {v16.8b}, [x0], x2
    st1         {v17.8b}, [x1], x2
    st1         {v18.8b}, [x0], x2
    st1         {v19.8b}, [x1], x2
    b.gt        5b

    ret
endfunc

// void hpel_filter( pixel *dsth, pixel *dstv, pixel *dstc, pixel *src,
//                   intptr_t stride, int width, int height, int16_t *buf )
function hpel_filter_neon, export=1
    ubfm        x9,  x3,  #0,  #3
    add         w15, w5,  w9
    sub         x13, x3,  x9            // align src
    sub         x10, x0,  x9
    sub         x11, x1,  x9
    sub         x12, x2,  x9
    movi        v30.16b,  #5
    movi        v31.16b,  #20
1:  // line start
    mov         x3,  x13
    mov         x2,  x12
    mov         x1,  x11
    mov         x0,  x10
    add         x7,  x3,  #16           // src pointer next 16b for horiz filter
    mov         x5,  x15                // restore width
    sub         x3,  x3,  x4,  lsl #1   // src - 2*stride
    ld1         {v28.16b}, [x7], #16    // src[16:31]

    add         x9,  x3,  x5            // holds src - 2*stride + width

    ld1         {v16.16b}, [x3], x4     // src-2*stride[0:15]
    ld1         {v17.16b}, [x3], x4     // src-1*stride[0:15]
    ld1         {v18.16b}, [x3], x4     // src+0*stride[0:15]
    ld1         {v19.16b}, [x3], x4     // src+1*stride[0:15]
    ld1         {v20.16b}, [x3], x4     // src+2*stride[0:15]
    ld1         {v21.16b}, [x3], x4     // src+3*stride[0:15]

    ext         v22.16b, v7.16b,  v18.16b, #14
    uaddl       v1.8h,   v16.8b,  v21.8b
    ext         v26.16b, v18.16b, v28.16b, #3
    umlsl       v1.8h,   v17.8b,  v30.8b
    ext         v23.16b, v7.16b,  v18.16b, #15
    umlal       v1.8h,   v18.8b,  v31.8b
    ext         v24.16b, v18.16b, v28.16b, #1
    umlal       v1.8h,   v19.8b,  v31.8b
    ext         v25.16b, v18.16b, v28.16b, #2
    umlsl       v1.8h,   v20.8b,  v30.8b
2:  // next 16 pixel of line
    subs        x5,  x5,  #16
    sub         x3,  x9,  x5            // src - 2*stride += 16

    uaddl       v4.8h,  v22.8b,  v26.8b
    uaddl2      v5.8h,  v22.16b, v26.16b
    sqrshrun    v6.8b,  v1.8h,   #5
    umlsl       v4.8h,  v23.8b,  v30.8b
    umlsl2      v5.8h,  v23.16b, v30.16b
    umlal       v4.8h,  v18.8b,  v31.8b
    umlal2      v5.8h,  v18.16b, v31.16b
    umlal       v4.8h,  v24.8b,  v31.8b
    umlal2      v5.8h,  v24.16b, v31.16b
    umlsl       v4.8h,  v25.8b,  v30.8b
    umlsl2      v5.8h,  v25.16b, v30.16b

    uaddl2      v2.8h,  v16.16b, v21.16b
    sqrshrun    v4.8b,  v4.8h,   #5
    mov         v7.16b, v18.16b
    sqrshrun2   v4.16b, v5.8h,   #5

    umlsl2      v2.8h,  v17.16b, v30.16b
    ld1         {v16.16b}, [x3],  x4    // src-2*stride[0:15]
    umlal2      v2.8h,  v18.16b, v31.16b
    ld1         {v17.16b}, [x3],  x4    // src-1*stride[0:15]
    umlal2      v2.8h,  v19.16b, v31.16b
    ld1         {v18.16b}, [x3],  x4    // src+0*stride[0:15]
    umlsl2      v2.8h,  v20.16b, v30.16b
    ld1         {v19.16b}, [x3],  x4    // src+1*stride[0:15]
    st1         {v4.16b},  [x0],  #16
    sqrshrun2   v6.16b, v2.8h,   #5
    ld1         {v20.16b}, [x3],  x4    // src+2*stride[0:15]
    ld1         {v21.16b}, [x3],  x4    // src+3*stride[0:15]

    ext         v22.16b, v0.16b, v1.16b, #12
    ext         v26.16b, v1.16b, v2.16b, #6
    ext         v23.16b, v0.16b, v1.16b, #14
    st1         {v6.16b},  [x1],  #16
    uaddl       v3.8h,   v16.8b, v21.8b
    ext         v25.16b, v1.16b, v2.16b, #4
    umlsl       v3.8h,   v17.8b, v30.8b
    ext         v24.16b, v1.16b, v2.16b, #2

    umlal       v3.8h,  v18.8b, v31.8b
    add         v4.8h,  v22.8h, v26.8h
    umlal       v3.8h,  v19.8b, v31.8b
    add         v5.8h,  v23.8h, v25.8h
    umlsl       v3.8h,  v20.8b, v30.8b
    add         v6.8h,  v24.8h, v1.8h

    ext         v22.16b, v1.16b, v2.16b, #12
    ext         v26.16b, v2.16b, v3.16b, #6
    ext         v23.16b, v1.16b, v2.16b, #14
    ext         v25.16b, v2.16b, v3.16b, #4
    ext         v24.16b, v2.16b, v3.16b, #2

    add         v22.8h, v22.8h, v26.8h
    add         v23.8h, v23.8h, v25.8h
    add         v24.8h, v24.8h, v2.8h

    sub         v4.8h,  v4.8h,  v5.8h   // a-b
    sub         v5.8h,  v5.8h,  v6.8h   // b-c

    sub         v22.8h, v22.8h, v23.8h  // a-b
    sub         v23.8h, v23.8h, v24.8h  // b-c

    sshr        v4.8h,  v4.8h,  #2      // (a-b)/4
    sshr        v22.8h, v22.8h, #2      // (a-b)/4
    sub         v4.8h,  v4.8h,  v5.8h   // (a-b)/4-b+c
    sub         v22.8h, v22.8h, v23.8h  // (a-b)/4-b+c
    sshr        v4.8h,  v4.8h,  #2      // ((a-b)/4-b+c)/4
    sshr        v22.8h, v22.8h, #2      // ((a-b)/4-b+c)/4
    add         v4.8h,  v4.8h,  v6.8h   // ((a-b)/4-b+c)/4+c = (a-5*b+20*c)/16
    add         v22.8h, v22.8h, v24.8h  // ((a-b)/4-b+c)/4+c = (a-5*b+20*c)/16

    sqrshrun    v4.8b,   v4.8h,   #6
    ld1         {v28.16b}, [x7],   #16  // src[16:31]
    mov         v0.16b,  v2.16b
    ext         v23.16b, v7.16b,  v18.16b, #15
    sqrshrun2   v4.16b,  v22.8h,  #6
    mov         v1.16b,  v3.16b
    ext         v22.16b, v7.16b,  v18.16b, #14
    ext         v24.16b, v18.16b, v28.16b, #1
    ext         v25.16b, v18.16b, v28.16b, #2
    ext         v26.16b, v18.16b, v28.16b, #3

    st1         {v4.16b}, [x2], #16
    b.gt        2b

    subs        w6,  w6,  #1
    add         x10,  x10,  x4
    add         x11,  x11,  x4
    add         x12,  x12,  x4
    add         x13,  x13,  x4
    b.gt        1b

    ret
endfunc

// frame_init_lowres_core( uint8_t *src0, uint8_t *dst0, uint8_t *dsth,
//                         uint8_t *dstv, uint8_t *dstc, intptr_t src_stride,
//                         intptr_t dst_stride, int width, int height )
function frame_init_lowres_core_neon, export=1
    ldr         w8,  [sp]
    sub         x10, x6,  w7, uxtw      // dst_stride - width
    and         x10, x10, #~15

1:
    mov         w9,  w7                 // width
    mov         x11, x0                 // src0
    add         x12, x0,  x5            // src1 = src0 + src_stride
    add         x13, x0,  x5,  lsl #1   // src2 = src1 + src_stride

    ld2         {v0.16b,v1.16b}, [x11], #32
    ld2         {v2.16b,v3.16b}, [x12], #32
    ld2         {v4.16b,v5.16b}, [x13], #32

    urhadd      v20.16b, v0.16b,  v2.16b    // s0[2x]   + s1[2x]
    urhadd      v22.16b, v2.16b,  v4.16b    // s1[2x]   + s2[2x]
2:
    subs        w9,  w9,  #16
    urhadd      v21.16b, v1.16b,  v3.16b    // s0[2x+1] + s1[2x+1]
    urhadd      v23.16b, v3.16b,  v5.16b    // s1[2x+1] + s2[2x+1]

    ld2         {v0.16b,v1.16b}, [x11], #32
    ld2         {v2.16b,v3.16b}, [x12], #32
    ld2         {v4.16b,v5.16b}, [x13], #32
    urhadd      v30.16b, v0.16b,  v2.16b    // loop: s0[2x]   + s1[2x]
    urhadd      v31.16b, v2.16b,  v4.16b    // loop: s1[2x]   + s2[2x]
    ext         v24.16b, v20.16b, v30.16b, #1   // s0[2x+2] + s1[2x+2]
    ext         v25.16b, v22.16b, v31.16b, #1   // s1[2x+2] + s2[2x+2]

    urhadd      v16.16b, v20.16b, v21.16b
    urhadd      v18.16b, v22.16b, v23.16b
    urhadd      v17.16b, v21.16b, v24.16b
    urhadd      v19.16b, v23.16b, v25.16b

    st1         {v16.16b},   [x1],  #16
    st1         {v18.16b},   [x3],  #16
    st1         {v17.16b},   [x2],  #16
    st1         {v19.16b},   [x4],  #16
    b.le        3f

    subs        w9,  w9,  #16
    urhadd      v21.16b, v1.16b,  v3.16b    // s0[2x+1] + s1[2x+1]
    urhadd      v23.16b, v3.16b,  v5.16b    // s1[2x+1] + s2[2x+1]

    ld2         {v0.16b,v1.16b}, [x11], #32
    ld2         {v2.16b,v3.16b}, [x12], #32
    ld2         {v4.16b,v5.16b}, [x13], #32
    urhadd      v20.16b, v0.16b,  v2.16b    // loop: s0[2x]   + s1[2x]
    urhadd      v22.16b, v2.16b,  v4.16b    // loop: s1[2x]   + s2[2x]
    ext         v24.16b, v30.16b, v20.16b, #1   // s0[2x+2] + s1[2x+2]
    ext         v25.16b, v31.16b, v22.16b, #1   // s1[2x+2] + s2[2x+2]

    urhadd      v16.16b, v30.16b, v21.16b
    urhadd      v18.16b, v31.16b, v23.16b
    urhadd      v17.16b, v21.16b, v24.16b
    urhadd      v19.16b, v23.16b, v25.16b

    st1         {v16.16b},   [x1],  #16
    st1         {v18.16b},   [x3],  #16
    st1         {v17.16b},   [x2],  #16
    st1         {v19.16b},   [x4],  #16
    b.gt        2b
3:
    subs        w8,  w8,  #1
    add         x0,  x0,  x5,  lsl #1
    add         x1,  x1,  x10
    add         x2,  x2,  x10
    add         x3,  x3,  x10
    add         x4,  x4,  x10
    b.gt        1b

    ret
endfunc

function load_deinterleave_chroma_fenc_neon, export=1
    mov         x4,  #FENC_STRIDE/2
    b           load_deinterleave_chroma
endfunc

function load_deinterleave_chroma_fdec_neon, export=1
    mov         x4,  #FDEC_STRIDE/2
load_deinterleave_chroma:
    ld2         {v0.8b,v1.8b}, [x1], x2
    ld2         {v2.8b,v3.8b}, [x1], x2
    subs        w3,  w3,  #2
    st1         {v0.8b}, [x0], x4
    st1         {v1.8b}, [x0], x4
    st1         {v2.8b}, [x0], x4
    st1         {v3.8b}, [x0], x4
    b.gt        load_deinterleave_chroma

    ret
endfunc

function plane_copy_core_neon, export=1
    add         w8,  w4,  #15 // 32-bit write clears the upper 32-bit the register
    and         w4,  w8,  #~15
    // safe use of the full reg since negative width makes no sense
    sub         x1,  x1,  x4
    sub         x3,  x3,  x4
1:
    mov         w8,  w4
16:
    tst         w8,  #16
    b.eq        32f
    subs        w8,  w8,  #16
    ldr         q0,  [x2], #16
    str         q0,  [x0], #16
    b.eq        0f
32:
    subs        w8,  w8,  #32
    ldp         q0,  q1,  [x2], #32
    stp         q0,  q1,  [x0], #32
    b.gt        32b
0:
    subs        w5,  w5,  #1
    add         x2,  x2,  x3
    add         x0,  x0,  x1
    b.gt        1b

    ret
endfunc

function plane_copy_swap_core_neon, export=1
    lsl         w4,  w4,  #1
    sub         x1,  x1,  x4
    sub         x3,  x3,  x4
1:
    mov         w8,  w4
    tbz         w4,  #4,  32f
    subs        w8,  w8,  #16
    ld1         {v0.16b}, [x2], #16
    rev16       v0.16b, v0.16b
    st1         {v0.16b}, [x0], #16
    b.eq        0f
32:
    subs        w8,  w8,  #32
    ld1         {v0.16b,v1.16b}, [x2], #32
    rev16       v0.16b, v0.16b
    rev16       v1.16b, v1.16b
    st1         {v0.16b,v1.16b}, [x0], #32
    b.gt        32b
0:
    subs        w5,  w5,  #1
    add         x2,  x2,  x3
    add         x0,  x0,  x1
    b.gt        1b

    ret
endfunc

function plane_copy_deinterleave_neon, export=1
    add         w9,  w6,  #15
    and         w9,  w9,  #0xfffffff0
    sub         x1,  x1,  x9
    sub         x3,  x3,  x9
    sub         x5,  x5,  x9, lsl #1
1:
    ld2         {v0.16b,v1.16b}, [x4], #32
    subs        w9,  w9,  #16
    st1         {v0.16b}, [x0],  #16
    st1         {v1.16b}, [x2],  #16
    b.gt        1b

    add         x4,  x4,  x5
    subs        w7,  w7,  #1
    add         x0,  x0,  x1
    add         x2,  x2,  x3
    mov         w9,  w6
    b.gt        1b

    ret
endfunc

.macro deinterleave_rgb
    subs            x11, x11, #8
    st1             {v0.8b},    [x0], #8
    st1             {v1.8b},    [x2], #8
    st1             {v2.8b},    [x4], #8
    b.gt            1b

    subs            w10, w10, #1
    add             x0,  x0,  x1
    add             x2,  x2,  x3
    add             x4,  x4,  x5
    add             x6,  x6,  x7
    mov             x11, x9
    b.gt            1b
.endm

function plane_copy_deinterleave_rgb_neon, export=1
#if SYS_MACOSX
    ldr             w8,  [sp]
    ldp             w9,  w10, [sp, #4]
#else
    ldr             x8,  [sp]
    ldp             x9,  x10, [sp, #8]
#endif
    cmp             w8,  #3
    uxtw            x9,  w9
    add             x11, x9,  #7
    and             x11, x11, #~7
    sub             x1,  x1,  x11
    sub             x3,  x3,  x11
    sub             x5,  x5,  x11
    b.ne            4f
    sub             x7,  x7,  x11, lsl #1
    sub             x7,  x7,  x11
1:
    ld3             {v0.8b,v1.8b,v2.8b}, [x6], #24
    deinterleave_rgb

    ret
4:
    sub             x7,  x7,  x11, lsl #2
1:
    ld4             {v0.8b,v1.8b,v2.8b,v3.8b}, [x6], #32
    deinterleave_rgb

    ret
endfunc

function plane_copy_interleave_core_neon, export=1
    add         w9,  w6,  #15
    and         w9,  w9,  #0xfffffff0
    sub         x1,  x1,  x9,  lsl #1
    sub         x3,  x3,  x9
    sub         x5,  x5,  x9
1:
    ld1         {v0.16b}, [x2],  #16
    ld1         {v1.16b}, [x4],  #16
    subs        w9,  w9,  #16
    st2         {v0.16b,v1.16b}, [x0],  #32
    b.gt        1b

    subs        w7,  w7,  #1
    add         x0,  x0,  x1
    add         x2,  x2,  x3
    add         x4,  x4,  x5
    mov         w9,  w6
    b.gt        1b

    ret
endfunc

function store_interleave_chroma_neon, export=1
    mov         x5,  #FDEC_STRIDE
1:
    ld1         {v0.8b}, [x2], x5
    ld1         {v1.8b}, [x3], x5
    ld1         {v2.8b}, [x2], x5
    ld1         {v3.8b}, [x3], x5
    subs        w4,  w4,  #2
    zip1        v4.16b,  v0.16b,  v1.16b
    zip1        v5.16b,  v2.16b,  v3.16b
    st1         {v4.16b}, [x0], x1
    st1         {v5.16b}, [x0], x1
    b.gt        1b

    ret
endfunc

.macro integral4h p1, p2
    ext         v1.8b,  \p1\().8b,  \p2\().8b,  #1
    ext         v2.8b,  \p1\().8b,  \p2\().8b,  #2
    ext         v3.8b,  \p1\().8b,  \p2\().8b,  #3
    uaddl       v0.8h,  \p1\().8b,  v1.8b
    uaddl       v4.8h,  v2.8b,  v3.8b
    add         v0.8h,  v0.8h,  v4.8h
    add         v0.8h,  v0.8h,  v5.8h
.endm

function integral_init4h_neon, export=1
    sub         x3,  x0,  x2, lsl #1
    ld1         {v6.8b,v7.8b}, [x1], #16
1:
    subs        x2,  x2,  #16
    ld1         {v5.8h},  [x3], #16
    integral4h  v6, v7
    ld1         {v6.8b},  [x1], #8
    ld1         {v5.8h},  [x3], #16
    st1         {v0.8h},  [x0], #16
    integral4h  v7, v6
    ld1         {v7.8b},  [x1], #8
    st1         {v0.8h},  [x0], #16
    b.gt        1b
    ret
endfunc

.macro integral8h p1, p2, s
    ext         v1.8b,  \p1\().8b,  \p2\().8b,  #1
    ext         v2.8b,  \p1\().8b,  \p2\().8b,  #2
    ext         v3.8b,  \p1\().8b,  \p2\().8b,  #3
    ext         v4.8b,  \p1\().8b,  \p2\().8b,  #4
    ext         v5.8b,  \p1\().8b,  \p2\().8b,  #5
    ext         v6.8b,  \p1\().8b,  \p2\().8b,  #6
    ext         v7.8b,  \p1\().8b,  \p2\().8b,  #7
    uaddl       v0.8h,  \p1\().8b,  v1.8b
    uaddl       v2.8h,  v2.8b,  v3.8b
    uaddl       v4.8h,  v4.8b,  v5.8b
    uaddl       v6.8h,  v6.8b,  v7.8b
    add         v0.8h,  v0.8h,  v2.8h
    add         v4.8h,  v4.8h,  v6.8h
    add         v0.8h,  v0.8h,  v4.8h
    add         v0.8h,  v0.8h,  \s\().8h
.endm

function integral_init8h_neon, export=1
    sub         x3,  x0,  x2, lsl #1
    ld1         {v16.8b,v17.8b}, [x1], #16
1:
    subs        x2,  x2,  #16
    ld1         {v18.8h}, [x3], #16
    integral8h  v16, v17, v18
    ld1         {v16.8b}, [x1], #8
    ld1         {v18.8h}, [x3], #16
    st1         {v0.8h},  [x0], #16
    integral8h  v17, v16, v18
    ld1         {v17.8b}, [x1], #8
    st1         {v0.8h},  [x0], #16
    b.gt        1b
    ret
endfunc

function integral_init4v_neon, export=1
    mov         x3,  x0
    add         x4,  x0,  x2,  lsl #3
    add         x8,  x0,  x2,  lsl #4
    sub         x2,  x2,  #8
    ld1         {v20.8h,v21.8h,v22.8h}, [x3], #48
    ld1         {v16.8h,v17.8h,v18.8h}, [x8], #48
1:
    subs        x2,  x2,  #16
    ld1         {v24.8h,v25.8h}, [x4], #32
    ext         v0.16b,  v20.16b, v21.16b, #8
    ext         v1.16b,  v21.16b, v22.16b, #8
    ext         v2.16b,  v16.16b, v17.16b, #8
    ext         v3.16b,  v17.16b, v18.16b, #8
    sub         v24.8h,  v24.8h,  v20.8h
    sub         v25.8h,  v25.8h,  v21.8h
    add         v0.8h,   v0.8h,   v20.8h
    add         v1.8h,   v1.8h,   v21.8h
    add         v2.8h,   v2.8h,   v16.8h
    add         v3.8h,   v3.8h,   v17.8h
    st1         {v24.8h},  [x1], #16
    st1         {v25.8h},  [x1], #16
    mov         v20.16b,  v22.16b
    mov         v16.16b,  v18.16b
    sub         v0.8h,   v2.8h,   v0.8h
    sub         v1.8h,   v3.8h,   v1.8h
    ld1         {v21.8h,v22.8h}, [x3], #32
    ld1         {v17.8h,v18.8h}, [x8], #32
    st1         {v0.8h},  [x0], #16
    st1         {v1.8h},  [x0], #16
    b.gt        1b
2:
    ret
endfunc

function integral_init8v_neon, export=1
    add         x2,  x0,  x1,  lsl #4
    sub         x1,  x1,  #8
    ands        x3,  x1,  #16 - 1
    b.eq        1f
    subs        x1,  x1,  #8
    ld1         {v0.8h}, [x0]
    ld1         {v2.8h}, [x2], #16
    sub         v4.8h,  v2.8h,  v0.8h
    st1         {v4.8h},  [x0], #16
    b.le        2f
1:
    subs        x1,  x1,  #16
    ld1         {v0.8h,v1.8h}, [x0]
    ld1         {v2.8h,v3.8h}, [x2], #32
    sub         v4.8h,  v2.8h,  v0.8h
    sub         v5.8h,  v3.8h,  v1.8h
    st1         {v4.8h},  [x0], #16
    st1         {v5.8h},  [x0], #16
    b.gt        1b
2:
    ret
endfunc

#else // BIT_DEPTH == 8

// void pixel_avg( pixel *dst,  intptr_t dst_stride,
//                 pixel *src1, intptr_t src1_stride,
//                 pixel *src2, intptr_t src2_stride, int weight );
.macro AVGH w h
function pixel_avg_\w\()x\h\()_neon, export=1
    mov         w10, #64
    cmp         w6, #32
    mov         w9, #\h
    b.eq        pixel_avg_w\w\()_neon
    subs        w7, w10, w6
    b.lt        pixel_avg_weight_w\w\()_add_sub_neon     // weight > 64
    cmp         w6, #0
    b.ge        pixel_avg_weight_w\w\()_add_add_neon
    b           pixel_avg_weight_w\w\()_sub_add_neon     // weight < 0
endfunc
.endm

AVGH  4, 2
AVGH  4, 4
AVGH  4, 8
AVGH  4, 16
AVGH  8, 4
AVGH  8, 8
AVGH  8, 16
AVGH 16, 8
AVGH 16, 16

// 0 < weight < 64
.macro load_weights_add_add
    mov         w6, w6
.endm
.macro weight_add_add dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s1, v30.8h
    umlal2      \dst, \s2, v31.8h
.else
    umull       \dst, \s1, v30.4h
    umlal       \dst, \s2, v31.4h
.endif
.endm

// weight > 64
.macro load_weights_add_sub
    neg         w7, w7
.endm
.macro weight_add_sub dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s1, v30.8h
    umlsl2      \dst, \s2, v31.8h
.else
    umull       \dst, \s1, v30.4h
    umlsl       \dst, \s2, v31.4h
.endif
.endm

// weight < 0
.macro load_weights_sub_add
    neg         w6, w6
.endm
.macro weight_sub_add dst, s1, s2, h=
.ifc \h, 2
    umull2      \dst, \s2, v31.8h
    umlsl2      \dst, \s1, v30.8h
.else
    umull       \dst, \s2, v31.4h
    umlsl       \dst, \s1, v30.4h
.endif
.endm

.macro AVG_WEIGHT ext
function pixel_avg_weight_w4_\ext\()_neon
    load_weights_\ext
    dup         v30.8h, w6
    dup         v31.8h, w7
    lsl         x3, x3, #1
    lsl         x5, x5, #1
    lsl         x1, x1, #1
1:  // height loop
    subs        w9, w9, #2
    ld1         {v0.d}[0], [x2], x3
    ld1         {v1.d}[0], [x4], x5
    weight_\ext v4.4s, v0.4h, v1.4h
    ld1         {v2.d}[0], [x2], x3
    ld1         {v3.d}[0], [x4], x5

    mvni        v28.8h, #0xfc, lsl #8

    sqrshrun    v4.4h, v4.4s, #6
    weight_\ext v5.4s, v2.4h, v3.4h
    smin        v4.4h, v4.4h, v28.4h
    sqrshrun    v5.4h, v5.4s, #6

    st1         {v4.d}[0], [x0], x1

    smin        v5.4h, v5.4h, v28.4h

    st1         {v5.d}[0], [x0], x1

    b.gt        1b
    ret
endfunc

function pixel_avg_weight_w8_\ext\()_neon
    load_weights_\ext
    dup         v30.8h, w6
    dup         v31.8h, w7
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    lsl         x5, x5, #1
1:  // height loop
    subs        w9, w9, #4
    ld1         {v0.8h}, [x2], x3
    ld1         {v1.8h}, [x4], x5
    weight_\ext v16.4s, v0.4h, v1.4h
    weight_\ext v17.4s, v0.8h, v1.8h, 2
    ld1         {v2.8h}, [x2], x3
    ld1         {v3.8h}, [x4], x5
    weight_\ext v18.4s, v2.4h, v3.4h
    weight_\ext v19.4s, v2.8h, v3.8h, 2
    ld1         {v4.8h}, [x2], x3
    ld1         {v5.8h}, [x4], x5
    weight_\ext v20.4s, v4.4h, v5.4h
    weight_\ext v21.4s, v4.8h, v5.8h, 2
    ld1         {v6.8h}, [x2], x3
    ld1         {v7.8h}, [x4], x5
    weight_\ext v22.4s, v6.4h, v7.4h
    weight_\ext v23.4s, v6.8h, v7.8h, 2

    mvni        v28.8h, #0xfc, lsl #8

    sqrshrun    v0.4h, v16.4s, #6
    sqrshrun    v2.4h, v18.4s, #6
    sqrshrun    v4.4h, v20.4s, #6
    sqrshrun2   v0.8h, v17.4s, #6
    sqrshrun    v6.4h, v22.4s, #6
    sqrshrun2   v2.8h, v19.4s, #6
    sqrshrun2   v4.8h, v21.4s, #6
    smin        v0.8h, v0.8h, v28.8h
    smin        v2.8h, v2.8h, v28.8h
    sqrshrun2   v6.8h, v23.4s, #6
    smin        v4.8h, v4.8h, v28.8h
    smin        v6.8h, v6.8h, v28.8h

    st1         {v0.8h}, [x0], x1
    st1         {v2.8h}, [x0], x1
    st1         {v4.8h}, [x0], x1
    st1         {v6.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_weight_w16_\ext\()_neon
    load_weights_\ext
    dup         v30.8h, w6
    dup         v31.8h, w7
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    lsl         x5, x5, #1
1:  // height loop
    subs        w9, w9, #2

    ld1         {v0.8h, v1.8h}, [x2], x3
    ld1         {v2.8h, v3.8h}, [x4], x5
    ld1         {v4.8h, v5.8h}, [x2], x3
    ld1         {v6.8h, v7.8h}, [x4], x5

    weight_\ext v16.4s, v0.4h, v2.4h
    weight_\ext v17.4s, v0.8h, v2.8h, 2
    weight_\ext v18.4s, v1.4h, v3.4h
    weight_\ext v19.4s, v1.8h, v3.8h, 2
    weight_\ext v20.4s, v4.4h, v6.4h
    weight_\ext v21.4s, v4.8h, v6.8h, 2
    weight_\ext v22.4s, v5.4h, v7.4h
    weight_\ext v23.4s, v5.8h, v7.8h, 2

    mvni        v28.8h, #0xfc, lsl #8

    sqrshrun    v0.4h, v16.4s, #6
    sqrshrun    v1.4h, v18.4s, #6
    sqrshrun    v2.4h, v20.4s, #6
    sqrshrun2   v0.8h, v17.4s, #6
    sqrshrun2   v1.8h, v19.4s, #6
    sqrshrun2   v2.8h, v21.4s, #6
    smin        v0.8h, v0.8h, v28.8h
    smin        v1.8h, v1.8h, v28.8h
    sqrshrun    v3.4h, v22.4s, #6
    smin        v2.8h, v2.8h, v28.8h
    sqrshrun2   v3.8h, v23.4s, #6
    smin        v3.8h, v3.8h, v28.8h

    st1         {v0.8h, v1.8h}, [x0], x1
    st1         {v2.8h, v3.8h}, [x0], x1
    b.gt        1b
    ret
endfunc
.endm

AVG_WEIGHT add_add
AVG_WEIGHT add_sub
AVG_WEIGHT sub_add

function pixel_avg_w4_neon
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    lsl         x5, x5, #1

1:  subs        w9, w9, #2
    ld1         {v0.d}[0], [x2], x3
    ld1         {v2.d}[0], [x4], x5
    ld1         {v0.d}[1], [x2], x3
    ld1         {v2.d}[1], [x4], x5
    urhadd      v0.8h, v0.8h, v2.8h
    st1         {v0.d}[0], [x0], x1
    st1         {v0.d}[1], [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_w8_neon
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    lsl         x5, x5, #1
1:  subs        w9, w9, #4
    ld1         {v0.8h}, [x2], x3
    ld1         {v1.8h}, [x4], x5
    ld1         {v2.8h}, [x2], x3
    urhadd      v0.8h, v0.8h, v1.8h
    ld1         {v3.8h}, [x4], x5
    st1         {v0.8h}, [x0], x1
    ld1         {v4.8h}, [x2], x3
    urhadd      v1.8h, v2.8h, v3.8h
    ld1         {v5.8h}, [x4], x5
    st1         {v1.8h}, [x0], x1
    ld1         {v6.8h}, [x2], x3
    ld1         {v7.8h}, [x4], x5
    urhadd      v2.8h, v4.8h, v5.8h
    urhadd      v3.8h, v6.8h, v7.8h
    st1         {v2.8h}, [x0], x1
    st1         {v3.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg_w16_neon
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    lsl         x5, x5, #1

1:  subs       w9, w9, #4

    ld1         {v0.8h, v1.8h}, [x2], x3
    ld1         {v2.8h, v3.8h}, [x4], x5
    ld1         {v4.8h, v5.8h}, [x2], x3
    urhadd      v0.8h, v0.8h, v2.8h
    urhadd      v1.8h, v1.8h, v3.8h
    ld1         {v6.8h, v7.8h}, [x4], x5
    ld1         {v20.8h, v21.8h}, [x2], x3
    st1         {v0.8h, v1.8h}, [x0], x1
    urhadd      v4.8h, v4.8h, v6.8h
    urhadd      v5.8h, v5.8h, v7.8h
    ld1         {v22.8h, v23.8h}, [x4], x5
    ld1         {v24.8h, v25.8h}, [x2], x3
    st1         {v4.8h, v5.8h}, [x0], x1
    ld1         {v26.8h, v27.8h}, [x4], x5
    urhadd      v20.8h, v20.8h, v22.8h
    urhadd      v21.8h, v21.8h, v23.8h
    urhadd      v24.8h, v24.8h, v26.8h
    urhadd      v25.8h, v25.8h, v27.8h
    st1         {v20.8h, v21.8h}, [x0], x1
    st1         {v24.8h, v25.8h}, [x0], x1

    b.gt        1b
    ret
endfunc

function pixel_avg2_w4_neon, export=1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w5, w5, #2
    ld1         {v0.4h}, [x2], x3
    ld1         {v2.4h}, [x4], x3
    ld1         {v1.4h}, [x2], x3
    ld1         {v3.4h}, [x4], x3
    urhadd      v0.4h, v0.4h, v2.4h
    urhadd      v1.4h, v1.4h, v3.4h

    st1         {v0.4h}, [x0], x1
    st1         {v1.4h}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg2_w8_neon, export=1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w5, w5, #2
    ld1         {v0.8h}, [x2], x3
    ld1         {v2.8h}, [x4], x3
    ld1         {v1.8h}, [x2], x3
    ld1         {v3.8h}, [x4], x3
    urhadd      v0.8h, v0.8h, v2.8h
    urhadd      v1.8h, v1.8h, v3.8h

    st1         {v0.8h}, [x0], x1
    st1         {v1.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg2_w16_neon, export=1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w5, w5, #2
    ld1         {v0.8h, v1.8h}, [x2], x3
    ld1         {v2.8h, v3.8h}, [x4], x3
    ld1         {v4.8h, v5.8h}, [x2], x3
    ld1         {v6.8h, v7.8h}, [x4], x3
    urhadd      v0.8h, v0.8h, v2.8h
    urhadd      v1.8h, v1.8h, v3.8h
    urhadd      v4.8h, v4.8h, v6.8h
    urhadd      v5.8h, v5.8h, v7.8h

    st1         {v0.8h, v1.8h}, [x0], x1
    st1         {v4.8h, v5.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function pixel_avg2_w20_neon, export=1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    sub         x1, x1, #32
1:
    subs        w5, w5, #2

    ld1         {v0.8h, v1.8h, v2.8h}, [x2], x3
    ld1         {v3.8h, v4.8h, v5.8h}, [x4], x3
    ld1         {v20.8h, v21.8h, v22.8h}, [x2], x3
    ld1         {v23.8h, v24.8h, v25.8h}, [x4], x3

    urhadd      v0.8h, v0.8h, v3.8h
    urhadd      v1.8h, v1.8h, v4.8h
    urhadd      v2.4h, v2.4h, v5.4h
    urhadd      v20.8h, v20.8h, v23.8h
    urhadd      v21.8h, v21.8h, v24.8h
    urhadd      v22.4h, v22.4h, v25.4h

    st1         {v0.8h, v1.8h}, [x0], #32
    st1         {v2.4h}, [x0], x1
    st1         {v20.8h, v21.8h}, [x0], #32
    st1         {v22.4h}, [x0], x1
    b.gt        1b
    ret
endfunc

// void mc_copy( pixel *dst, intptr_t dst_stride, pixel *src, intptr_t src_stride, int height )
function mc_copy_w4_neon, export=1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w4, w4, #4
    ld1         {v0.d}[0], [x2], x3
    ld1         {v1.d}[0], [x2], x3
    ld1         {v2.d}[0], [x2], x3
    ld1         {v3.d}[0], [x2], x3
    st1         {v0.d}[0], [x0], x1
    st1         {v1.d}[0], [x0], x1
    st1         {v2.d}[0], [x0], x1
    st1         {v3.d}[0], [x0], x1
    b.gt        1b
    ret
endfunc

function mc_copy_w8_neon, export=1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:  subs        w4, w4, #4
    ld1         {v0.8h}, [x2], x3
    ld1         {v1.8h}, [x2], x3
    ld1         {v2.8h}, [x2], x3
    ld1         {v3.8h}, [x2], x3
    st1         {v0.8h}, [x0], x1
    st1         {v1.8h}, [x0], x1
    st1         {v2.8h}, [x0], x1
    st1         {v3.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_copy_w16_neon, export=1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:  subs        w4, w4, #4
    ld1         {v0.8h, v1.8h}, [x2], x3
    ld1         {v2.8h, v3.8h}, [x2], x3
    ld1         {v4.8h, v5.8h}, [x2], x3
    ld1         {v6.8h, v7.8h}, [x2], x3
    st1         {v0.8h, v1.8h}, [x0], x1
    st1         {v2.8h, v3.8h}, [x0], x1
    st1         {v4.8h, v5.8h}, [x0], x1
    st1         {v6.8h, v7.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

.macro weight_prologue type
    mov         w9, w5                  // height
.ifc \type, full
    ldr         w12, [x4, #32]          // denom
.endif
    ldp         w4, w5, [x4, #32+4]     // scale, offset
    dup         v0.8h, w4
    lsl         w5, w5, #2
    dup         v1.4s, w5
.ifc \type, full
    neg         w12, w12
    dup         v2.4s, w12
.endif
.endm

// void mc_weight( pixel *src, intptr_t src_stride, pixel *dst,
//                 intptr_t dst_stride, const x264_weight_t *weight, int h )
function mc_weight_w20_neon, export=1
    weight_prologue full
    lsl         x3, x3, #1
    lsl         x1, x1, #1
    sub         x1, x1, #32
1:
    subs        w9, w9, #2
    ld1         {v16.8h, v17.8h, v18.8h}, [x2], x3
    ld1         {v19.8h, v20.8h, v21.8h}, [x2], x3

    umull       v22.4s, v16.4h, v0.4h
    umull2      v23.4s, v16.8h, v0.8h
    umull       v24.4s, v17.4h, v0.4h
    umull2      v25.4s, v17.8h, v0.8h
    umull       v26.4s, v18.4h, v0.4h
    umull       v27.4s, v21.4h, v0.4h

    srshl       v22.4s, v22.4s, v2.4s
    srshl       v23.4s, v23.4s, v2.4s
    srshl       v24.4s, v24.4s, v2.4s
    srshl       v25.4s, v25.4s, v2.4s
    srshl       v26.4s, v26.4s, v2.4s
    srshl       v27.4s, v27.4s, v2.4s
    add         v22.4s, v22.4s, v1.4s
    add         v23.4s, v23.4s, v1.4s
    add         v24.4s, v24.4s, v1.4s
    add         v25.4s, v25.4s, v1.4s
    add         v26.4s, v26.4s, v1.4s
    add         v27.4s, v27.4s, v1.4s

    sqxtun      v22.4h, v22.4s
    sqxtun2     v22.8h, v23.4s
    sqxtun      v23.4h, v24.4s
    sqxtun2     v23.8h, v25.4s
    sqxtun      v24.4h, v26.4s
    sqxtun2     v24.8h, v27.4s

    umull       v16.4s, v19.4h, v0.4h
    umull2      v17.4s, v19.8h, v0.8h
    umull       v18.4s, v20.4h, v0.4h
    umull2      v19.4s, v20.8h, v0.8h

    srshl       v16.4s, v16.4s, v2.4s
    srshl       v17.4s, v17.4s, v2.4s
    srshl       v18.4s, v18.4s, v2.4s
    srshl       v19.4s, v19.4s, v2.4s
    add         v16.4s, v16.4s, v1.4s
    add         v17.4s, v17.4s, v1.4s
    add         v18.4s, v18.4s, v1.4s
    add         v19.4s, v19.4s, v1.4s

    sqxtun      v16.4h, v16.4s
    sqxtun2     v16.8h, v17.4s
    sqxtun      v17.4h, v18.4s
    sqxtun2     v17.8h, v19.4s

    mvni        v31.8h, #0xfc, lsl #8

    umin        v22.8h, v22.8h, v31.8h
    umin        v23.8h, v23.8h, v31.8h
    umin        v24.8h, v24.8h, v31.8h
    umin        v16.8h, v16.8h, v31.8h
    umin        v17.8h, v17.8h, v31.8h

    st1         {v22.8h, v23.8h}, [x0], #32
    st1         {v24.d}[0], [x0], x1
    st1         {v16.8h, v17.8h}, [x0], #32
    st1         {v24.d}[1], [x0], x1

    b.gt        1b
    ret
endfunc

function mc_weight_w16_neon, export=1
    weight_prologue full
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w9, w9, #2
    ld1         {v4.8h, v5.8h}, [x2], x3
    ld1         {v6.8h, v7.8h}, [x2], x3

    umull       v22.4s, v4.4h, v0.4h
    umull2      v23.4s, v4.8h, v0.8h
    umull       v24.4s, v5.4h, v0.4h
    umull2      v25.4s, v5.8h, v0.8h

    srshl       v22.4s, v22.4s, v2.4s
    srshl       v23.4s, v23.4s, v2.4s
    srshl       v24.4s, v24.4s, v2.4s
    srshl       v25.4s, v25.4s, v2.4s

    add         v22.4s, v22.4s, v1.4s
    add         v23.4s, v23.4s, v1.4s
    add         v24.4s, v24.4s, v1.4s
    add         v25.4s, v25.4s, v1.4s

    sqxtun      v22.4h, v22.4s
    sqxtun2     v22.8h, v23.4s
    sqxtun      v23.4h, v24.4s
    sqxtun2     v23.8h, v25.4s

    umull       v26.4s, v6.4h, v0.4h
    umull2      v27.4s, v6.8h, v0.8h
    umull       v28.4s, v7.4h, v0.4h
    umull2      v29.4s, v7.8h, v0.8h

    srshl       v26.4s, v26.4s, v2.4s
    srshl       v27.4s, v27.4s, v2.4s
    srshl       v28.4s, v28.4s, v2.4s
    srshl       v29.4s, v29.4s, v2.4s

    add         v26.4s, v26.4s, v1.4s
    add         v27.4s, v27.4s, v1.4s
    add         v28.4s, v28.4s, v1.4s
    add         v29.4s, v29.4s, v1.4s

    sqxtun      v26.4h, v26.4s
    sqxtun2     v26.8h, v27.4s
    sqxtun      v27.4h, v28.4s
    sqxtun2     v27.8h, v29.4s

    mvni        v31.8h, 0xfc, lsl #8

    umin        v22.8h, v22.8h, v31.8h
    umin        v23.8h, v23.8h, v31.8h
    umin        v26.8h, v26.8h, v31.8h
    umin        v27.8h, v27.8h, v31.8h

    st1         {v22.8h, v23.8h}, [x0], x1
    st1         {v26.8h, v27.8h}, [x0], x1

    b.gt        1b
    ret
endfunc

function mc_weight_w8_neon, export=1
    weight_prologue full
    lsl         x3, x3, #1
    lsl         x1, x1, #1
1:
    subs        w9, w9, #2
    ld1         {v16.8h}, [x2], x3
    ld1         {v17.8h}, [x2], x3

    umull       v4.4s, v16.4h, v0.4h
    umull2      v5.4s, v16.8h, v0.8h
    umull       v6.4s, v17.4h, v0.4h
    umull2      v7.4s, v17.8h, v0.8h

    srshl       v4.4s, v4.4s, v2.4s
    srshl       v5.4s, v5.4s, v2.4s
    srshl       v6.4s, v6.4s, v2.4s
    srshl       v7.4s, v7.4s, v2.4s

    add         v4.4s, v4.4s, v1.4s
    add         v5.4s, v5.4s, v1.4s
    add         v6.4s, v6.4s, v1.4s
    add         v7.4s, v7.4s, v1.4s

    sqxtun      v16.4h, v4.4s
    sqxtun2     v16.8h, v5.4s
    sqxtun      v17.4h, v6.4s
    sqxtun2     v17.8h, v7.4s

    mvni        v28.8h, #0xfc, lsl #8

    umin        v16.8h, v16.8h, v28.8h
    umin        v17.8h, v17.8h, v28.8h

    st1         {v16.8h}, [x0], x1
    st1         {v17.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w4_neon, export=1
    weight_prologue full
    lsl         x3, x3, #1
    lsl         x1, x1, #1
1:
    subs        w9, w9, #2
    ld1         {v16.d}[0], [x2], x3
    ld1         {v16.d}[1], [x2], x3
    umull       v4.4s, v16.4h, v0.4h
    umull2      v5.4s, v16.8h, v0.8h
    srshl       v4.4s, v4.4s, v2.4s
    srshl       v5.4s, v5.4s, v2.4s
    add         v4.4s, v4.4s, v1.4s
    add         v5.4s, v5.4s, v1.4s

    sqxtun      v16.4h, v4.4s
    sqxtun2     v16.8h, v5.4s

    mvni        v28.8h, #0xfc, lsl #8

    umin        v16.8h, v16.8h, v28.8h

    st1         {v16.d}[0], [x0], x1
    st1         {v16.d}[1], [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w20_nodenom_neon, export=1
    weight_prologue nodenom
    lsl         x3, x3, #1
    lsl         x1, x1, #1
    sub         x1, x1, #32
1:
    subs        w9, w9, #2
    ld1         {v16.8h, v17.8h, v18.8h}, [x2], x3
    mov         v20.16b, v1.16b
    mov         v21.16b, v1.16b
    mov         v22.16b, v1.16b
    mov         v23.16b, v1.16b
    mov         v24.16b, v1.16b
    mov         v25.16b, v1.16b
    ld1         {v2.8h, v3.8h, v4.8h}, [x2], x3
    mov         v26.16b, v1.16b
    mov         v27.16b, v1.16b
    mov         v28.16b, v1.16b
    mov         v29.16b, v1.16b

    umlal       v20.4s, v16.4h, v0.4h
    umlal2      v21.4s, v16.8h, v0.8h
    umlal       v22.4s, v17.4h, v0.4h
    umlal2      v23.4s, v17.8h, v0.8h
    umlal       v24.4s, v18.4h, v0.4h
    umlal       v25.4s, v4.4h, v0.4h
    umlal       v26.4s, v2.4h, v0.4h
    umlal2      v27.4s, v2.8h, v0.8h
    umlal       v28.4s, v3.4h, v0.4h
    umlal2      v29.4s, v3.8h, v0.8h

    sqxtun      v2.4h, v20.4s
    sqxtun2     v2.8h, v21.4s
    sqxtun      v3.4h, v22.4s
    sqxtun2     v3.8h, v23.4s
    sqxtun      v4.4h, v24.4s
    sqxtun2     v4.8h, v25.4s
    sqxtun      v5.4h, v26.4s
    sqxtun2     v5.8h, v27.4s
    sqxtun      v6.4h, v28.4s
    sqxtun2     v6.8h, v29.4s

    mvni        v31.8h, 0xfc, lsl #8

    umin        v2.8h, v2.8h, v31.8h
    umin        v3.8h, v3.8h, v31.8h
    umin        v4.8h, v4.8h, v31.8h
    umin        v5.8h, v5.8h, v31.8h
    umin        v6.8h, v6.8h, v31.8h

    st1         {v2.8h, v3.8h}, [x0], #32
    st1         {v4.d}[0], [x0], x1
    st1         {v5.8h, v6.8h}, [x0], #32
    st1         {v4.d}[1], [x0], x1

    b.gt        1b
    ret
endfunc

function mc_weight_w16_nodenom_neon, export=1
    weight_prologue nodenom
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w9, w9, #2
    ld1         {v2.8h, v3.8h}, [x2], x3
    mov         v27.16b, v1.16b
    mov         v28.16b, v1.16b
    mov         v29.16b, v1.16b
    mov         v30.16b, v1.16b
    ld1         {v4.8h, v5.8h}, [x2], x3
    mov         v20.16b, v1.16b
    mov         v21.16b, v1.16b
    mov         v22.16b, v1.16b
    mov         v23.16b, v1.16b

    umlal       v27.4s, v2.4h, v0.4h
    umlal2      v28.4s, v2.8h, v0.8h
    umlal       v29.4s, v3.4h, v0.4h
    umlal2      v30.4s, v3.8h, v0.8h

    umlal       v20.4s, v4.4h, v0.4h
    umlal2      v21.4s, v4.8h, v0.8h
    umlal       v22.4s, v5.4h, v0.4h
    umlal2      v23.4s, v5.8h, v0.8h

    sqxtun      v2.4h, v27.4s
    sqxtun2     v2.8h, v28.4s
    sqxtun      v3.4h, v29.4s
    sqxtun2     v3.8h, v30.4s

    sqxtun      v4.4h, v20.4s
    sqxtun2     v4.8h, v21.4s
    sqxtun      v5.4h, v22.4s
    sqxtun2     v5.8h, v23.4s

    mvni        v31.8h, 0xfc, lsl #8

    umin        v2.8h, v2.8h, v31.8h
    umin        v3.8h, v3.8h, v31.8h
    umin        v4.8h, v4.8h, v31.8h
    umin        v5.8h, v5.8h, v31.8h

    st1         {v2.8h, v3.8h}, [x0], x1
    st1         {v4.8h, v5.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w8_nodenom_neon, export=1
    weight_prologue nodenom
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w9, w9, #2
    ld1         {v16.8h}, [x2], x3
    mov         v27.16b, v1.16b
    ld1         {v17.8h}, [x2], x3
    mov         v28.16b, v1.16b
    mov         v29.16b, v1.16b
    mov         v30.16b, v1.16b

    umlal       v27.4s, v16.4h, v0.4h
    umlal2      v28.4s, v16.8h, v0.8h
    umlal       v29.4s, v17.4h, v0.4h
    umlal2      v30.4s, v17.8h, v0.8h

    sqxtun      v4.4h, v27.4s
    sqxtun2     v4.8h, v28.4s
    sqxtun      v5.4h, v29.4s
    sqxtun2     v5.8h, v30.4s

    mvni        v31.8h, 0xfc, lsl #8

    umin        v4.8h, v4.8h, v31.8h
    umin        v5.8h, v5.8h, v31.8h

    st1         {v4.8h}, [x0], x1
    st1         {v5.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w4_nodenom_neon, export=1
    weight_prologue nodenom
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w9, w9, #2
    ld1         {v16.d}[0], [x2], x3
    ld1         {v16.d}[1], [x2], x3
    mov         v27.16b, v1.16b
    mov         v28.16b, v1.16b
    umlal       v27.4s, v16.4h, v0.4h
    umlal2      v28.4s, v16.8h, v0.8h

    sqxtun      v4.4h, v27.4s
    sqxtun2     v4.8h, v28.4s

    mvni        v31.8h, 0xfc, lsl #8

    umin        v4.8h, v4.8h, v31.8h

    st1         {v4.d}[0], [x0], x1
    st1         {v4.d}[1], [x0], x1
    b.gt        1b
    ret
endfunc

.macro weight_simple_prologue
    ldr         w6, [x4]               // offset
    lsl         w6, w6, #2
    dup         v1.8h, w6
.endm

.macro weight_simple name op
function mc_weight_w20_\name\()_neon, export=1
    weight_simple_prologue
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    sub         x1, x1, #32
1:
    subs        w5, w5, #2
    ld1         {v2.8h, v3.8h, v4.8h}, [x2], x3
    ld1         {v5.8h, v6.8h, v7.8h}, [x2], x3

    zip1        v4.2d, v4.2d, v7.2d

    \op         v2.8h, v2.8h, v1.8h
    \op         v3.8h, v3.8h, v1.8h
    \op         v4.8h, v4.8h, v1.8h
    \op         v5.8h, v5.8h, v1.8h
    \op         v6.8h, v6.8h, v1.8h

    mvni        v31.8h, #0xfc, lsl #8

    umin        v2.8h, v2.8h, v28.8h
    umin        v3.8h, v3.8h, v28.8h
    umin        v4.8h, v4.8h, v28.8h
    umin        v5.8h, v5.8h, v28.8h
    umin        v6.8h, v6.8h, v28.8h

    st1         {v2.8h, v3.8h}, [x0], #32
    st1         {v4.d}[0], [x0], x1
    st1         {v5.8h, v6.8h}, [x0], #32
    st1         {v4.d}[1], [x0], x1

    b.gt        1b
    ret
endfunc

function mc_weight_w16_\name\()_neon, export=1
    weight_simple_prologue
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w5, w5, #2
    ld1         {v16.8h, v17.8h}, [x2], x3
    ld1         {v18.8h, v19.8h}, [x2], x3

    \op         v16.8h, v16.8h, v1.8h
    \op         v17.8h, v17.8h, v1.8h
    \op         v18.8h, v18.8h, v1.8h
    \op         v19.8h, v19.8h, v1.8h

    mvni        v28.8h, #0xfc, lsl #8

    umin        v16.8h, v16.8h, v28.8h
    umin        v17.8h, v17.8h, v28.8h
    umin        v18.8h, v18.8h, v28.8h
    umin        v19.8h, v19.8h, v28.8h

    st1         {v16.8h, v17.8h}, [x0], x1
    st1         {v18.8h, v19.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w8_\name\()_neon, export=1
    weight_simple_prologue
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w5, w5, #2
    ld1         {v16.8h}, [x2], x3
    ld1         {v17.8h}, [x2], x3
    \op         v16.8h, v16.8h, v1.8h
    \op         v17.8h, v17.8h, v1.8h

    mvni        v28.8h, 0xfc, lsl #8

    umin        v16.8h, v16.8h, v28.8h
    umin        v17.8h, v17.8h, v28.8h

    st1         {v16.8h}, [x0], x1
    st1         {v17.8h}, [x0], x1
    b.gt        1b
    ret
endfunc

function mc_weight_w4_\name\()_neon, export=1
    weight_simple_prologue
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    subs        w5, w5, #2
    ld1         {v16.d}[0], [x2], x3
    ld1         {v16.d}[1], [x2], x3
    \op         v16.8h, v16.8h, v1.8h
    mvni        v28.8h, 0xfc, lsl #8

    umin        v16.8h, v16.8h, v28.8h

    st1         {v16.d}[0], [x0], x1
    st1         {v16.d}[1], [x0], x1
    b.gt        1b
    ret
endfunc
.endm

weight_simple offsetadd, uqadd
weight_simple offsetsub, uqsub

// void mc_chroma( pixel *dst_u, pixel *dst_v,
//                 intptr_t i_dst_stride,
//                 pixel *src, intptr_t i_src_stride,
//                 int dx, int dy, int i_width, int i_height );
function mc_chroma_neon, export=1
    ldr         w15, [sp]               // height
    sbfx        x12, x6, #3, #29        // asr(3) and sign extend
    sbfx        x11, x5, #3, #29        // asr(3) and sign extend
    cmp         w7, #4
    lsl         x4, x4, #1
    mul         x12, x12, x4
    add         x3, x3, x11, lsl #2

    and         w5, w5, #7
    and         w6, w6, #7

    add         x3, x3, x12

    b.gt        mc_chroma_w8_neon
    b.eq        mc_chroma_w4_neon
endfunc

.macro CHROMA_MC_START r00, r01, r10, r11
    mul         w12, w5, w6             // cD = d8x    *d8y
    lsl         w13, w5, #3
    add         w9, w12, #64
    lsl         w14, w6, #3
    tst         w12, w12
    sub         w9, w9, w13
    sub         w10, w13, w12           // cB = d8x    *(8-d8y);
    sub         w11, w14, w12           // cC = (8-d8x)*d8y
    sub         w9, w9, w14             // cA = (8-d8x)*(8-d8y);
.endm

.macro CHROMA_MC width, vsize
function mc_chroma_w\width\()_neon
    lsl         x2, x2, #1
// since the element size varies, there's a different index for the 2nd store
.if \width == 4
    .set idx2, 1
.else
    .set idx2, 2
.endif
    CHROMA_MC_START
    b.eq        2f

    ld2         {v28.8h, v29.8h}, [x3], x4
    dup         v0.8h, w9               // cA
    dup         v1.8h, w10              // cB

    ext         v6.16b, v28.16b, v28.16b, #2
    ext         v7.16b, v29.16b, v29.16b, #2

    ld2         {v30.8h, v31.8h}, [x3], x4
    dup         v2.8h, w11              // cC
    dup         v3.8h, w12              // cD

    ext         v22.16b, v30.16b, v30.16b, #2
    ext         v23.16b, v31.16b, v31.16b, #2

    trn1        v0.2d, v0.2d, v1.2d
    trn1        v2.2d, v2.2d, v3.2d

    trn1        v4.2d, v28.2d, v6.2d
    trn1        v5.2d, v29.2d, v7.2d
    trn1        v20.2d, v30.2d, v22.2d
    trn1        v21.2d, v31.2d, v23.2d
1:  // height loop, interpolate xy
    subs        w15, w15, #2

    mul         v16.8h, v4.8h, v0.8h
    mul         v17.8h, v5.8h, v0.8h
    mla         v16.8h, v20.8h, v2.8h
    mla         v17.8h, v21.8h, v2.8h

    ld2         {v28.8h, v29.8h}, [x3], x4
    transpose   v24.2d, v25.2d, v16.2d, v17.2d

    ext         v6.16b, v28.16b, v28.16b, #2
    ext         v7.16b, v29.16b, v29.16b, #2
    trn1        v4.2d, v28.2d, v6.2d
    trn1        v5.2d, v29.2d, v7.2d

    add         v16.8h, v24.8h, v25.8h
    urshr       v16.8h, v16.8h, #6

    mul         v18.8h, v20.8h, v0.8h
    mul         v19.8h, v21.8h, v0.8h
    mla         v18.8h, v4.8h, v2.8h
    mla         v19.8h, v5.8h, v2.8h

    ld2         {v30.8h, v31.8h}, [x3], x4

    transpose   v26.2d, v27.2d, v18.2d, v19.2d
    add         v18.8h, v26.8h, v27.8h
    urshr       v18.8h, v18.8h, #6

    ext         v22.16b, v30.16b, v30.16b, #2
    ext         v23.16b, v31.16b, v31.16b, #2
    trn1        v20.2d, v30.2d, v22.2d
    trn1        v21.2d, v31.2d, v23.2d

    st1         {v16.\vsize}[0], [x0], x2
    st1         {v16.\vsize}[idx2], [x1], x2
    st1         {v18.\vsize}[0], [x0], x2
    st1         {v18.\vsize}[idx2], [x1], x2
    b.gt        1b

    ret
2:  // dx or dy are 0
    tst         w11, w11
    add         w10, w10, w11
    dup         v0.8h, w9
    dup         v1.8h, w10

    b.eq        4f

    ld1         {v4.8h}, [x3], x4
    ld1         {v6.8h}, [x3], x4
3:  // vertical interpolation loop
    subs        w15, w15, #2

    mul         v16.8h, v4.8h, v0.8h
    mla         v16.8h, v6.8h, v1.8h
    ld1         {v4.8h}, [x3], x4
    mul         v17.8h, v6.8h, v0.8h
    mla         v17.8h, v4.8h, v1.8h
    ld1         {v6.8h}, [x3], x4

    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    uzp1        v18.8h, v16.8h, v17.8h  // d16=uuuu|uuuu, d17=vvvv|vvvv
    uzp2        v19.8h, v16.8h, v17.8h  // d16=uuuu|uuuu, d17=vvvv|vvvv

    st1         {v18.\vsize}[0], [x0], x2
    st1         {v18.\vsize}[idx2], [x0], x2
    st1         {v19.\vsize}[0], [x1], x2
    st1         {v19.\vsize}[idx2], [x1], x2
    b.gt        3b

    ret

4:  // dy is 0
    ld1         {v4.8h, v5.8h}, [x3], x4
    ld1         {v6.8h, v7.8h}, [x3], x4

    ext         v5.16b, v4.16b, v5.16b, #4
    ext         v7.16b, v6.16b, v7.16b, #4
5:  // horizontal interpolation loop
    subs        w15, w15, #2

    mul         v16.8h, v4.8h, v0.8h
    mla         v16.8h, v5.8h, v1.8h
    mul         v17.8h, v6.8h, v0.8h
    mla         v17.8h, v7.8h, v1.8h

    ld1         {v4.8h, v5.8h}, [x3], x4
    ld1         {v6.8h, v7.8h}, [x3], x4

    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    ext         v5.16b, v4.16b, v5.16b, #4
    ext         v7.16b, v6.16b, v7.16b, #4
    uzp1        v18.8h, v16.8h, v17.8h  // d16=uuuu|uuuu, d17=vvvv|vvvv
    uzp2        v19.8h, v16.8h, v17.8h  // d16=uuuu|uuuu, d17=vvvv|vvvv

    st1         {v18.\vsize}[0], [x0], x2
    st1         {v18.\vsize}[idx2], [x0], x2
    st1         {v19.\vsize}[0], [x1], x2
    st1         {v19.\vsize}[idx2], [x1], x2
    b.gt        5b

    ret
endfunc
.endm

    CHROMA_MC   2, s
    CHROMA_MC   4, d

function mc_chroma_w8_neon
    lsl         x2, x2, #1
    CHROMA_MC_START

    b.eq        2f
    sub         x4, x4, #32
    ld2         {v4.8h, v5.8h}, [x3], #32
    ld2         {v6.8h, v7.8h}, [x3], x4

    ld2         {v20.8h, v21.8h}, [x3], #32
    ld2         {v22.8h, v23.8h}, [x3], x4

    dup         v0.8h, w9               // cA
    dup         v1.8h, w10              // cB

    ext         v24.16b, v4.16b, v6.16b, #2
    ext         v26.16b, v6.16b, v4.16b, #2
    ext         v28.16b, v20.16b, v22.16b, #2
    ext         v30.16b, v22.16b, v20.16b, #2

    ext         v25.16b, v5.16b, v7.16b, #2
    ext         v27.16b, v7.16b, v5.16b, #2
    ext         v29.16b, v21.16b, v23.16b, #2
    ext         v31.16b, v23.16b, v21.16b, #2

    dup         v2.8h, w11              // cC
    dup         v3.8h, w12              // cD

1:  // height loop, interpolate xy
    subs        w15, w15, #2

    mul         v16.8h, v4.8h, v0.8h
    mul         v17.8h, v5.8h, v0.8h
    mla         v16.8h, v24.8h, v1.8h
    mla         v17.8h, v25.8h, v1.8h
    mla         v16.8h, v20.8h, v2.8h
    mla         v17.8h, v21.8h, v2.8h
    mla         v16.8h, v28.8h, v3.8h
    mla         v17.8h, v29.8h, v3.8h

    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    st1         {v16.8h}, [x0], x2
    st1         {v17.8h}, [x1], x2

    ld2         {v4.8h, v5.8h}, [x3], #32
    ld2         {v6.8h, v7.8h}, [x3], x4

    mul         v16.8h, v20.8h, v0.8h
    mul         v17.8h, v21.8h, v0.8h
    ext         v24.16b, v4.16b, v6.16b, #2
    ext         v26.16b, v6.16b, v4.16b, #2
    mla         v16.8h, v28.8h, v1.8h
    mla         v17.8h, v29.8h, v1.8h
    ext         v25.16b, v5.16b, v7.16b, #2
    ext         v27.16b, v7.16b, v5.16b, #2
    mla         v16.8h, v4.8h, v2.8h
    mla         v17.8h, v5.8h, v2.8h
    mla         v16.8h, v24.8h, v3.8h
    mla         v17.8h, v25.8h, v3.8h

    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    ld2         {v20.8h, v21.8h}, [x3], #32
    ld2         {v22.8h, v23.8h}, [x3], x4
    ext         v28.16b, v20.16b, v22.16b, #2
    ext         v30.16b, v22.16b, v20.16b, #2
    ext         v29.16b, v21.16b, v23.16b, #2
    ext         v31.16b, v23.16b, v21.16b, #2

    st1         {v16.8h}, [x0], x2
    st1         {v17.8h}, [x1], x2
    b.gt        1b

    ret
2:  // dx or dy are 0
    tst         w11, w11
    add         w10, w10, w11
    dup         v0.8h, w9
    dup         v1.8h, w10

    b.eq        4f

    ld2         {v4.8h, v5.8h}, [x3], x4
    ld2         {v6.8h, v7.8h}, [x3], x4
3:  // vertical interpolation loop
    subs        w15, w15, #2

    mul         v16.8h, v4.8h, v0.8h
    mul         v17.8h, v5.8h, v0.8h
    mla         v16.8h, v6.8h, v1.8h
    mla         v17.8h, v7.8h, v1.8h
    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    st1         {v16.8h}, [x0], x2
    st1         {v17.8h}, [x1], x2

    ld2         {v4.8h, v5.8h}, [x3], x4

    mul         v16.8h, v6.8h, v0.8h
    mul         v17.8h, v7.8h, v0.8h
    ld2         {v6.8h, v7.8h}, [x3], x4
    mla         v16.8h, v4.8h, v1.8h
    mla         v17.8h, v5.8h, v1.8h
    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    st1         {v16.8h}, [x0], x2
    st1         {v17.8h}, [x1], x2
    b.gt        3b

    ret
4:  // dy is 0
    sub         x4, x4, #32

    ld2         {v4.8h, v5.8h}, [x3], #32
    ld2         {v6.8h, v7.8h}, [x3], x4
    ext         v24.16b, v4.16b, v6.16b, #2
    ext         v26.16b, v6.16b, v4.16b, #2
    ld2         {v20.8h, v21.8h}, [x3], #32
    ld2         {v22.8h, v23.8h}, [x3], x4
    ext         v28.16b, v20.16b, v22.16b, #2
    ext         v30.16b, v22.16b, v20.16b, #2

    ext         v25.16b, v5.16b, v7.16b, #2
    ext         v27.16b, v7.16b, v5.16b, #2
    ext         v29.16b, v21.16b, v23.16b, #2
    ext         v31.16b, v23.16b, v21.16b, #2

5:  // horizontal interpolation loop
    subs        w15, w15, #2

    mul         v16.8h, v4.8h, v0.8h
    mul         v17.8h, v5.8h, v0.8h
    mla         v16.8h, v24.8h, v1.8h
    mla         v17.8h, v25.8h, v1.8h

    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    st1         {v16.8h}, [x0], x2
    st1         {v17.8h}, [x1], x2

    mul         v16.8h, v20.8h, v0.8h
    mul         v17.8h, v21.8h, v0.8h
    ld2         {v4.8h, v5.8h}, [x3], #32
    ld2         {v6.8h, v7.8h}, [x3], x4
    mla         v16.8h, v28.8h, v1.8h
    mla         v17.8h, v29.8h, v1.8h
    ld2         {v20.8h,v21.8h}, [x3], #32
    ld2         {v22.8h,v23.8h}, [x3], x4

    urshr       v16.8h, v16.8h, #6
    urshr       v17.8h, v17.8h, #6

    ext         v24.16b, v4.16b, v6.16b, #2
    ext         v26.16b, v6.16b, v4.16b, #2
    ext         v28.16b, v20.16b, v22.16b, #2
    ext         v30.16b, v22.16b, v20.16b, #2
    ext         v29.16b, v21.16b, v23.16b, #2
    ext         v31.16b, v23.16b, v21.16b, #2
    ext         v25.16b, v5.16b, v7.16b, #2
    ext         v27.16b, v7.16b, v5.16b, #2

    st1         {v16.8h}, [x0], x2
    st1         {v17.8h}, [x1], x2
    b.gt        5b

    ret
endfunc

.macro integral4h p1, p2
    ext         v1.16b, \p1\().16b, \p2\().16b, #2
    ext         v2.16b, \p1\().16b, \p2\().16b, #4
    ext         v3.16b, \p1\().16b, \p2\().16b, #6
    add         v0.8h, \p1\().8h, v1.8h
    add         v4.8h, v2.8h, v3.8h
    add         v0.8h, v0.8h, v4.8h
    add         v0.8h, v0.8h, v5.8h
.endm

function integral_init4h_neon, export=1
    sub         x3, x0, x2, lsl #1
    lsl         x2, x2, #1
    ld1         {v6.8h,v7.8h}, [x1], #32
1:
    subs        x2, x2, #32
    ld1         {v5.8h}, [x3], #16
    integral4h  v6, v7
    ld1         {v6.8h}, [x1], #16
    ld1         {v5.8h}, [x3], #16
    st1         {v0.8h}, [x0], #16
    integral4h  v7, v6
    ld1         {v7.8h}, [x1], #16
    st1         {v0.8h}, [x0], #16
    b.gt        1b
    ret
endfunc

.macro integral8h p1, p2, s
    ext         v1.16b, \p1\().16b, \p2\().16b, #2
    ext         v2.16b, \p1\().16b, \p2\().16b, #4
    ext         v3.16b, \p1\().16b, \p2\().16b, #6
    ext         v4.16b, \p1\().16b, \p2\().16b, #8
    ext         v5.16b, \p1\().16b, \p2\().16b, #10
    ext         v6.16b, \p1\().16b, \p2\().16b, #12
    ext         v7.16b, \p1\().16b, \p2\().16b, #14
    add         v0.8h, \p1\().8h, v1.8h
    add         v2.8h, v2.8h, v3.8h
    add         v4.8h, v4.8h, v5.8h
    add         v6.8h, v6.8h, v7.8h
    add         v0.8h, v0.8h, v2.8h
    add         v4.8h, v4.8h, v6.8h
    add         v0.8h, v0.8h, v4.8h
    add         v0.8h, v0.8h, \s\().8h
.endm

function integral_init8h_neon, export=1
    sub         x3, x0, x2, lsl #1
    lsl         x2, x2, #1

    ld1         {v16.8h, v17.8h}, [x1], #32
1:
    subs        x2, x2, #32
    ld1         {v18.8h}, [x3], #16
    integral8h  v16, v17, v18
    ld1         {v16.8h}, [x1], #16
    ld1         {v18.8h}, [x3], #16
    st1         {v0.8h}, [x0], #16
    integral8h  v17, v16, v18
    ld1         {v17.8h}, [x1], #16
    st1         {v0.8h},  [x0], #16
    b.gt        1b
    ret
endfunc

function integral_init4v_neon, export=1
    mov         x3, x0
    add         x4, x0, x2, lsl #3
    add         x8, x0, x2, lsl #4
    lsl         x2, x2, #1
    sub         x2, x2, #16
    ld1         {v20.8h, v21.8h, v22.8h}, [x3], #48
    ld1         {v16.8h, v17.8h, v18.8h}, [x8], #48
1:
    subs        x2, x2, #32
    ld1         {v24.8h, v25.8h}, [x4], #32
    ext         v0.16b, v20.16b, v21.16b, #8
    ext         v1.16b, v21.16b, v22.16b, #8
    ext         v2.16b, v16.16b, v17.16b, #8
    ext         v3.16b, v17.16b, v18.16b, #8
    sub         v24.8h, v24.8h, v20.8h
    sub         v25.8h, v25.8h, v21.8h
    add         v0.8h, v0.8h, v20.8h
    add         v1.8h, v1.8h, v21.8h
    add         v2.8h, v2.8h, v16.8h
    add         v3.8h, v3.8h, v17.8h
    st1         {v24.8h}, [x1], #16
    st1         {v25.8h}, [x1], #16
    mov         v20.16b, v22.16b
    mov         v16.16b, v18.16b
    sub         v0.8h, v2.8h, v0.8h
    sub         v1.8h, v3.8h, v1.8h
    ld1         {v21.8h, v22.8h}, [x3], #32
    ld1         {v17.8h, v18.8h}, [x8], #32
    st1         {v0.8h}, [x0], #16
    st1         {v1.8h}, [x0], #16
    b.gt        1b
2:
    ret
endfunc

function integral_init8v_neon, export=1
    add         x2, x0, x1, lsl #4
    sub         x1, x1, #8
    ands        x3, x1, #16 - 1
    b.eq        1f
    subs        x1, x1, #8
    ld1         {v0.8h}, [x0]
    ld1         {v2.8h}, [x2], #16
    sub         v4.8h, v2.8h, v0.8h
    st1         {v4.8h}, [x0], #16
    b.le        2f
1:
    subs        x1, x1, #16
    ld1         {v0.8h,v1.8h}, [x0]
    ld1         {v2.8h,v3.8h}, [x2], #32
    sub         v4.8h, v2.8h, v0.8h
    sub         v5.8h, v3.8h, v1.8h
    st1         {v4.8h}, [x0], #16
    st1         {v5.8h}, [x0], #16
    b.gt        1b
2:
    ret
endfunc

// frame_init_lowres_core( pixel *src0, pixel *dst0, pixel *dsth,
//                         pixel *dstv, pixel *dstc, intptr_t src_stride,
//                         intptr_t dst_stride, int width, int height )
function frame_init_lowres_core_neon, export=1
    ldr         w8, [sp]
    lsl         x5, x5, #1
    sub         x10, x6, w7, uxtw       // dst_stride - width
    lsl         x10, x10, #1
    and         x10, x10, #~31

    stp         d8, d9, [sp, #-0x40]!
    stp         d10, d11, [sp, #0x10]
    stp         d12, d13, [sp, #0x20]
    stp         d14, d15, [sp, #0x30]

1:
    mov         w9, w7                  // width
    mov         x11, x0                 // src0
    add         x12, x0, x5             // src1 = src0 + src_stride
    add         x13, x0, x5, lsl #1     // src2 = src1 + src_stride

    ld2         {v0.8h, v1.8h}, [x11], #32
    ld2         {v2.8h, v3.8h}, [x11], #32
    ld2         {v4.8h, v5.8h}, [x12], #32
    ld2         {v6.8h, v7.8h}, [x12], #32
    ld2         {v28.8h, v29.8h}, [x13], #32
    ld2         {v30.8h, v31.8h}, [x13], #32

    urhadd      v20.8h, v0.8h, v4.8h
    urhadd      v21.8h, v2.8h, v6.8h
    urhadd      v22.8h, v4.8h, v28.8h
    urhadd      v23.8h, v6.8h, v30.8h
2:
    subs        w9, w9, #16

    urhadd      v24.8h, v1.8h, v5.8h
    urhadd      v25.8h, v3.8h, v7.8h
    urhadd      v26.8h, v5.8h, v29.8h
    urhadd      v27.8h, v7.8h, v31.8h

    ld2         {v0.8h, v1.8h}, [x11], #32
    ld2         {v2.8h, v3.8h}, [x11], #32
    ld2         {v4.8h, v5.8h}, [x12], #32
    ld2         {v6.8h, v7.8h}, [x12], #32
    ld2         {v28.8h, v29.8h}, [x13], #32
    ld2         {v30.8h, v31.8h}, [x13], #32

    urhadd      v16.8h, v0.8h, v4.8h
    urhadd      v17.8h, v2.8h, v6.8h
    urhadd      v18.8h, v4.8h, v28.8h
    urhadd      v19.8h, v6.8h, v30.8h

    ext         v8.16b, v20.16b, v21.16b, #2
    ext         v9.16b, v21.16b, v16.16b, #2
    ext         v10.16b, v22.16b, v23.16b, #2
    ext         v11.16b, v23.16b, v18.16b, #2

    urhadd      v12.8h, v20.8h, v24.8h
    urhadd      v8.8h, v24.8h, v8.8h

    urhadd      v24.8h, v21.8h, v25.8h
    urhadd      v22.8h, v22.8h, v26.8h
    urhadd      v10.8h, v26.8h, v10.8h
    urhadd      v26.8h, v23.8h, v27.8h
    urhadd      v9.8h, v25.8h, v9.8h
    urhadd      v11.8h, v27.8h, v11.8h

    st1         {v12.8h}, [x1], #16
    st1         {v24.8h}, [x1], #16
    st1         {v22.8h}, [x3], #16
    st1         {v26.8h}, [x3], #16
    st1         {v8.8h, v9.8h}, [x2], #32
    st1         {v10.8h, v11.8h}, [x4], #32

    b.le        3f

    subs        w9,  w9,  #16

    urhadd      v24.8h, v1.8h, v5.8h
    urhadd      v25.8h, v3.8h, v7.8h
    urhadd      v26.8h, v5.8h, v29.8h
    urhadd      v27.8h, v7.8h, v31.8h

    ld2         {v0.8h, v1.8h}, [x11], #32
    ld2         {v2.8h, v3.8h}, [x11], #32
    ld2         {v4.8h, v5.8h}, [x12], #32
    ld2         {v6.8h, v7.8h}, [x12], #32
    ld2         {v28.8h, v29.8h}, [x13], #32
    ld2         {v30.8h, v31.8h}, [x13], #32

    urhadd      v20.8h, v0.8h, v4.8h
    urhadd      v21.8h, v2.8h, v6.8h
    urhadd      v22.8h, v4.8h, v28.8h
    urhadd      v23.8h, v6.8h, v30.8h

    ext         v8.16b, v16.16b, v17.16b, #2
    ext         v9.16b, v17.16b, v20.16b, #2
    ext         v10.16b, v18.16b, v19.16b, #2
    ext         v11.16b, v19.16b, v22.16b, #2

    urhadd      v12.8h, v16.8h, v24.8h
    urhadd      v13.8h, v17.8h, v25.8h

    urhadd      v14.8h, v18.8h, v26.8h
    urhadd      v15.8h, v19.8h, v27.8h

    urhadd      v16.8h, v24.8h, v8.8h
    urhadd      v17.8h, v25.8h, v9.8h

    urhadd      v18.8h, v26.8h, v10.8h
    urhadd      v19.8h, v27.8h, v11.8h

    st1         {v12.8h, v13.8h}, [x1], #32
    st1         {v14.8h, v15.8h}, [x3], #32
    st1         {v16.8h, v17.8h}, [x2], #32
    st1         {v18.8h, v19.8h}, [x4], #32
    b.gt        2b
3:
    subs        w8, w8, #1
    add         x0, x0, x5, lsl #1
    add         x1, x1, x10
    add         x2, x2, x10
    add         x3, x3, x10
    add         x4, x4, x10
    b.gt        1b

    ldp         d8, d9, [sp]
    ldp         d10, d11, [sp, #0x10]
    ldp         d12, d13, [sp, #0x20]
    ldp         d14, d15, [sp, #0x30]

    add         sp, sp, #0x40

    ret
endfunc

function load_deinterleave_chroma_fenc_neon, export=1
    mov         x4, #FENC_STRIDE/2
    lsl         x4, x4, #1
    lsl         x2, x2, #1
    b           load_deinterleave_chroma
endfunc

function load_deinterleave_chroma_fdec_neon, export=1
    mov         x4, #FDEC_STRIDE/2
    lsl         x4, x4, #1
    lsl         x2, x2, #1
load_deinterleave_chroma:
    ld2         {v0.8h, v1.8h}, [x1], x2
    ld2         {v2.8h, v3.8h}, [x1], x2
    subs        w3, w3, #2
    st1         {v0.8h}, [x0], x4
    st1         {v1.8h}, [x0], x4
    st1         {v2.8h}, [x0], x4
    st1         {v3.8h}, [x0], x4
    b.gt        load_deinterleave_chroma

    ret
endfunc

function store_interleave_chroma_neon, export=1
    mov         x5, #FDEC_STRIDE
    lsl         x5, x5, #1
    lsl         x1, x1, #1
1:
    ld1         {v0.8h}, [x2], x5
    ld1         {v1.8h}, [x3], x5
    ld1         {v2.8h}, [x2], x5
    ld1         {v3.8h}, [x3], x5
    subs        w4, w4, #2
    zip1        v4.8h, v0.8h, v1.8h
    zip1        v6.8h, v2.8h, v3.8h
    zip2        v5.8h, v0.8h, v1.8h
    zip2        v7.8h, v2.8h, v3.8h

    st1         {v4.8h, v5.8h}, [x0], x1
    st1         {v6.8h, v7.8h}, [x0], x1
    b.gt        1b

    ret
endfunc

function plane_copy_core_neon, export=1
    add         w8, w4, #31 // 32-bit write clears the upper 32-bit the register
    and         w4, w8, #~31
    // safe use of the full reg since negative width makes no sense
    sub         x1, x1, x4
    sub         x3, x3, x4
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    mov         w8, w4
16:
    tst         w8, #16
    b.eq        32f
    subs        w8, w8, #16
    ldp         q0, q1, [x2], #32
    stp         q0, q1, [x0], #32
    b.eq        0f
32:
    subs        w8, w8, #32
    ldp         q0, q1, [x2], #32
    ldp         q2, q3, [x2], #32
    stp         q0, q1, [x0], #32
    stp         q2, q3, [x0], #32
    b.gt        32b
0:
    subs        w5, w5, #1
    add         x2, x2, x3
    add         x0, x0, x1
    b.gt        1b

    ret
endfunc

function plane_copy_swap_core_neon, export=1
    lsl         w4, w4, #1
    add         w8, w4, #31 // 32-bit write clears the upper 32-bit the register
    and         w4, w8, #~31
    sub         x1, x1, x4
    sub         x3, x3, x4
    lsl         x1, x1, #1
    lsl         x3, x3, #1
1:
    mov         w8, w4
    tbz         w4, #4, 32f
    subs        w8, w8, #16
    ld1         {v0.8h, v1.8h}, [x2], #32
    rev32       v0.8h, v0.8h
    rev32       v1.8h, v1.8h
    st1         {v0.8h, v1.8h}, [x0], #32
    b.eq        0f
32:
    subs        w8, w8, #32
    ld1         {v0.8h ,v1.8h, v2.8h, v3.8h}, [x2], #64
    rev32       v20.8h, v0.8h
    rev32       v21.8h, v1.8h
    rev32       v22.8h, v2.8h
    rev32       v23.8h, v3.8h
    st1         {v20.8h, v21.8h, v22.8h, v23.8h}, [x0], #64
    b.gt        32b
0:
    subs        w5, w5, #1
    add         x2, x2, x3
    add         x0, x0, x1
    b.gt        1b

    ret
endfunc

function plane_copy_deinterleave_neon, export=1
    add         w9, w6, #15
    and         w9, w9, #~15
    sub         x1, x1, x9
    sub         x3, x3, x9
    sub         x5, x5, x9, lsl #1
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    lsl         x5, x5, #1
1:
    ld2         {v0.8h, v1.8h}, [x4], #32
    ld2         {v2.8h, v3.8h}, [x4], #32
    subs        w9, w9, #16
    st1         {v0.8h}, [x0], #16
    st1         {v2.8h}, [x0], #16
    st1         {v1.8h}, [x2], #16
    st1         {v3.8h}, [x2], #16
    b.gt        1b

    add         x4, x4, x5
    subs        w7, w7, #1
    add         x0, x0, x1
    add         x2, x2, x3
    mov         w9, w6
    b.gt        1b

    ret
endfunc

function plane_copy_interleave_core_neon, export=1
    add         w9, w6, #15
    and         w9, w9, #0xfffffff0
    sub         x1, x1, x9,  lsl #1
    sub         x3, x3, x9
    sub         x5, x5, x9
    lsl         x1, x1, #1
    lsl         x3, x3, #1
    lsl         x5, x5, #1
1:
    ld1         {v0.8h}, [x2], #16
    ld1         {v1.8h}, [x4], #16
    ld1         {v2.8h}, [x2], #16
    ld1         {v3.8h}, [x4], #16
    subs        w9, w9, #16
    st2         {v0.8h, v1.8h}, [x0], #32
    st2         {v2.8h, v3.8h}, [x0], #32
    b.gt        1b

    subs        w7, w7, #1
    add         x0, x0, x1
    add         x2, x2, x3
    add         x4, x4, x5
    mov         w9, w6
    b.gt        1b

    ret
endfunc

.macro deinterleave_rgb
    subs            x11, x11, #8
    st1             {v0.8h}, [x0], #16
    st1             {v1.8h}, [x2], #16
    st1             {v2.8h}, [x4], #16
    b.gt            1b

    subs            w10, w10, #1
    add             x0, x0, x1
    add             x2, x2, x3
    add             x4, x4, x5
    add             x6, x6, x7
    mov             x11, x9
    b.gt            1b
.endm

function plane_copy_deinterleave_rgb_neon, export=1
#if SYS_MACOSX
    ldr             w8, [sp]
    ldp             w9, w10, [sp, #4]
#else
    ldr             x8, [sp]
    ldp             x9, x10, [sp, #8]
#endif
    cmp             w8, #3
    uxtw            x9, w9
    add             x11, x9, #7
    and             x11, x11, #~7
    sub             x1, x1, x11
    sub             x3, x3, x11
    sub             x5, x5, x11
    lsl             x1, x1, #1
    lsl             x3, x3, #1
    lsl             x5, x5, #1
    b.ne            4f
    sub             x7, x7, x11, lsl #1
    sub             x7, x7, x11
    lsl             x7, x7, #1
1:
    ld3             {v0.8h, v1.8h, v2.8h}, [x6], #48
    deinterleave_rgb

    ret
4:
    sub             x7, x7, x11, lsl #2
    lsl             x7, x7, #1
1:
    ld4             {v0.8h, v1.8h, v2.8h, v3.8h}, [x6], #64
    deinterleave_rgb

    ret
endfunc

// void hpel_filter( pixel *dsth, pixel *dstv, pixel *dstc, pixel *src,
//                   intptr_t stride, int width, int height, int16_t *buf )
function hpel_filter_neon, export=1
    lsl         x5, x5, #1
    ubfm        x9, x3, #3, #7
    add         w15, w5, w9
    sub         x13, x3, x9                 // align src
    sub         x10, x0, x9
    sub         x11, x1, x9
    sub         x12, x2, x9
    movi        v30.8h, #5
    movi        v31.8h, #20

    lsl         x4, x4, #1
    stp         d8, d9, [sp, #-0x40]!
    stp         d10, d11, [sp, #0x10]
    stp         d12, d13, [sp, #0x20]
    stp         d14, d15, [sp, #0x30]

    str         q0, [sp, #-0x50]!

1:  // line start
    mov         x3, x13
    mov         x2, x12
    mov         x1, x11
    mov         x0, x10
    add         x7, x3, #32                 // src pointer next 16b for horiz filter
    mov         x5, x15                     // restore width
    sub         x3, x3, x4, lsl #1          // src - 2*stride
    ld1         {v28.8h, v29.8h}, [x7], #32 // src[16:31]
    add         x9, x3, x5                  // holds src - 2*stride + width

    ld1         {v8.8h, v9.8h}, [x3], x4    // src-2*stride[0:15]
    ld1         {v10.8h, v11.8h}, [x3], x4  // src-1*stride[0:15]
    ld1         {v12.8h, v13.8h}, [x3], x4  // src-0*stride[0:15]
    ld1         {v14.8h, v15.8h}, [x3], x4  // src+1*stride[0:15]
    ld1         {v16.8h, v17.8h}, [x3], x4  // src+2*stride[0:15]
    ld1         {v18.8h, v19.8h}, [x3], x4  // src+3*stride[0:15]

    ext         v22.16b, v7.16b, v12.16b, #12
    ext         v23.16b, v12.16b, v13.16b, #12
    uaddl       v1.4s, v8.4h, v18.4h
    uaddl2      v20.4s, v8.8h, v18.8h
    ext         v24.16b, v12.16b, v13.16b, #6
    ext         v25.16b, v13.16b, v28.16b, #6
    umlsl       v1.4s, v10.4h, v30.4h
    umlsl2      v20.4s, v10.8h, v30.8h
    ext         v26.16b, v7.16b, v12.16b, #14
    ext         v27.16b, v12.16b, v13.16b, #14
    umlal       v1.4s, v12.4h, v31.4h
    umlal2      v20.4s, v12.8h, v31.8h
    ext         v3.16b, v12.16b, v13.16b, #2
    ext         v4.16b, v13.16b, v28.16b, #2
    umlal       v1.4s, v14.4h, v31.4h
    umlal2      v20.4s, v14.8h, v31.8h
    ext         v21.16b, v12.16b, v13.16b, #4
    ext         v5.16b, v13.16b, v28.16b, #4
    umlsl       v1.4s, v16.4h, v30.4h
    umlsl2      v20.4s, v16.8h, v30.8h

2:  // next 16 pixel of line
    subs        x5, x5, #32
    sub         x3, x9, x5                  // src - 2*stride += 16

    uaddl       v8.4s, v22.4h, v24.4h
    uaddl2      v22.4s, v22.8h, v24.8h
    uaddl       v10.4s, v23.4h, v25.4h
    uaddl2      v23.4s, v23.8h, v25.8h

    umlsl       v8.4s, v26.4h, v30.4h
    umlsl2      v22.4s, v26.8h, v30.8h
    umlsl       v10.4s, v27.4h, v30.4h
    umlsl2      v23.4s, v27.8h, v30.8h

    umlal       v8.4s, v12.4h, v31.4h
    umlal2      v22.4s, v12.8h, v31.8h
    umlal       v10.4s, v13.4h, v31.4h
    umlal2      v23.4s, v13.8h, v31.8h

    umlal       v8.4s, v3.4h, v31.4h
    umlal2      v22.4s, v3.8h, v31.8h
    umlal       v10.4s, v4.4h, v31.4h
    umlal2      v23.4s, v4.8h, v31.8h

    umlsl       v8.4s, v21.4h, v30.4h
    umlsl2      v22.4s, v21.8h, v30.8h
    umlsl       v10.4s, v5.4h, v30.4h
    umlsl2      v23.4s, v5.8h, v30.8h

    uaddl       v5.4s, v9.4h, v19.4h
    uaddl2      v2.4s, v9.8h, v19.8h

    sqrshrun    v8.4h, v8.4s, #5
    sqrshrun2   v8.8h, v22.4s, #5
    sqrshrun    v10.4h, v10.4s, #5
    sqrshrun2   v10.8h, v23.4s, #5

    mov         v6.16b, v12.16b
    mov         v7.16b, v13.16b

    mvni        v23.8h, #0xfc, lsl #8

    umin        v8.8h, v8.8h, v23.8h
    umin        v10.8h, v10.8h, v23.8h

    st1         {v8.8h}, [x0], #16
    st1         {v10.8h}, [x0], #16

    umlsl       v5.4s, v11.4h, v30.4h
    umlsl2      v2.4s, v11.8h, v30.8h

    ld1         {v8.8h, v9.8h}, [x3], x4
    umlal       v5.4s, v13.4h, v31.4h
    umlal2      v2.4s, v13.8h, v31.8h
    ld1         {v10.8h, v11.8h}, [x3], x4
    umlal       v5.4s, v15.4h, v31.4h
    umlal2      v2.4s, v15.8h, v31.8h
    ld1         {v12.8h, v13.8h}, [x3], x4
    umlsl       v5.4s, v17.4h, v30.4h
    umlsl2      v2.4s, v17.8h, v30.8h
    ld1         {v14.8h, v15.8h}, [x3], x4

    sqrshrun    v4.4h, v5.4s, #5
    sqrshrun2   v4.8h, v2.4s, #5
    sqrshrun    v18.4h, v1.4s, #5
    sqrshrun2   v18.8h, v20.4s, #5

    mvni        v17.8h, #0xfc, lsl #8

    smin        v4.8h, v4.8h, v17.8h
    smin        v18.8h, v18.8h, v17.8h

    st1         {v18.8h}, [x1], #16
    st1         {v4.8h}, [x1], #16

    ld1         {v16.8h, v17.8h}, [x3], x4          // src+2*stride[0:15]
    ld1         {v18.8h, v19.8h}, [x3], x4          // src+3*stride[0:15]

    str         q9, [sp, #0x10]
    str         q15, [sp, #0x20]
    str         q17, [sp, #0x30]
    str         q19, [sp, #0x40]

    ldr         q28, [sp]

    ext         v22.16b, v28.16b, v1.16b, #8
    ext         v9.16b, v1.16b, v20.16b, #8
    ext         v26.16b, v1.16b, v20.16b, #12
    ext         v17.16b, v20.16b, v5.16b, #12
    ext         v23.16b, v28.16b, v1.16b, #12
    ext         v19.16b, v1.16b, v20.16b, #12

    uaddl       v3.4s, v8.4h, v18.4h
    uaddl2      v15.4s, v8.8h, v18.8h
    umlsl       v3.4s, v10.4h, v30.4h
    umlsl2      v15.4s, v10.8h, v30.8h
    umlal       v3.4s, v12.4h, v31.4h
    umlal2      v15.4s, v12.8h, v31.8h
    umlal       v3.4s, v14.4h, v31.4h
    umlal2      v15.4s, v14.8h, v31.8h
    umlsl       v3.4s, v16.4h, v30.4h
    umlsl2      v15.4s, v16.8h, v30.8h

    add         v4.4s, v22.4s, v26.4s
    add         v26.4s, v9.4s, v17.4s

    ext         v25.16b, v1.16b, v20.16b, #8
    ext         v22.16b, v20.16b, v5.16b, #8
    ext         v24.16b, v1.16b, v20.16b, #4
    ext         v9.16b, v20.16b, v5.16b, #4

    add         v31.4s, v23.4s, v25.4s
    add         v19.4s, v19.4s, v22.4s
    add         v6.4s, v24.4s, v1.4s
    add         v17.4s, v9.4s, v20.4s
    sub         v4.4s, v4.4s, v31.4s                // a-b
    sub         v26.4s, v26.4s, v19.4s              // a-b
    sub         v31.4s, v31.4s, v6.4s               // b-c
    sub         v19.4s, v19.4s, v17.4s              // b-c

    ext         v22.16b, v20.16b, v5.16b, #8
    ext         v9.16b, v5.16b, v2.16b, #8
    ext         v24.16b, v5.16b, v2.16b, #12
    ext         v28.16b, v2.16b, v3.16b, #12
    ext         v23.16b, v20.16b, v5.16b, #12
    ext         v30.16b, v5.16b, v2.16b, #12
    ext         v25.16b, v5.16b, v2.16b, #8
    ext         v29.16b, v2.16b, v3.16b, #8

    add         v22.4s, v22.4s, v24.4s
    add         v9.4s, v9.4s, v28.4s
    add         v23.4s, v23.4s, v25.4s
    add         v29.4s, v29.4s, v30.4s

    ext         v24.16b, v5.16b, v2.16b, #4
    ext         v28.16b, v2.16b, v3.16b, #4

    add         v24.4s, v24.4s, v5.4s
    add         v28.4s, v28.4s, v2.4s

    sub         v22.4s, v22.4s, v23.4s
    sub         v9.4s, v9.4s, v29.4s
    sub         v23.4s, v23.4s, v24.4s
    sub         v29.4s, v29.4s, v28.4s

    sshr        v4.4s, v4.4s, #2
    sshr        v0.4s, v26.4s, #2
    sshr        v22.4s, v22.4s, #2
    sshr        v9.4s, v9.4s, #2

    sub         v4.4s, v4.4s, v31.4s
    sub         v0.4s, v0.4s, v19.4s
    sub         v22.4s, v22.4s, v23.4s
    sub         v9.4s, v9.4s, v29.4s

    sshr        v4.4s, v4.4s, #2
    sshr        v0.4s, v0.4s, #2
    sshr        v22.4s, v22.4s, #2
    sshr        v9.4s, v9.4s, #2

    add         v4.4s, v4.4s, v6.4s
    add         v0.4s, v0.4s, v17.4s
    add         v22.4s, v22.4s, v24.4s
    add         v9.4s, v9.4s, v28.4s

    str         q2, [sp]

    sqrshrun    v4.4h, v4.4s, #6
    sqrshrun2   v4.8h, v0.4s, #6
    sqrshrun    v22.4h, v22.4s, #6
    sqrshrun2   v22.8h, v9.4s, #6

    mov         v0.16b, v5.16b

    ld1         {v28.8h, v29.8h}, [x7], #32          // src[16:31]

    ldr         q9, [sp, #0x10]
    ldr         q17, [sp, #0x30]
    ldr         q19, [sp, #0x40]

    ext         v26.16b, v7.16b, v12.16b, #14
    ext         v27.16b, v12.16b, v13.16b, #14

    mvni        v25.8h, 0xfc, lsl #8

    smin        v22.8h, v22.8h, v25.8h
    smin        v4.8h, v4.8h, v25.8h

    st1         {v4.8h}, [x2], #16
    st1         {v22.8h}, [x2], #16

    mov         v1.16b, v3.16b
    mov         v20.16b, v15.16b

    ldr         q15, [sp, #0x20]

    ext         v22.16b, v7.16b, v12.16b, #12
    ext         v23.16b, v12.16b, v13.16b, #12
    ext         v3.16b, v12.16b, v13.16b, #2
    ext         v4.16b, v13.16b, v28.16b, #2
    ext         v21.16b, v12.16b, v13.16b, #4
    ext         v5.16b, v13.16b, v28.16b, #4
    ext         v24.16b, v12.16b, v13.16b, #6
    ext         v25.16b, v13.16b, v28.16b, #6

    movi        v30.8h, #5
    movi        v31.8h, #20

    b.gt        2b

    subs        w6, w6, #1
    add         x10, x10, x4
    add         x11, x11, x4
    add         x12, x12, x4
    add         x13, x13, x4
    b.gt        1b

    add         sp, sp, #0x50

    ldp         d8, d9, [sp]
    ldp         d10, d11, [sp, #0x10]
    ldp         d12, d13, [sp, #0x20]
    ldp         d14, d15, [sp, #0x30]
    add         sp, sp, #0x40

    ret
endfunc

#endif
