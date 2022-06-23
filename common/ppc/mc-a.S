/*****************************************************************************
 * dct-a.S: ppc motion compensation
 *****************************************************************************
 * Copyright (C) 2003-2020 x264 project
 *
 * Authors: Mamone Tarsha <maamoun.tk@gmail.com>
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

// 0 < weight < 64
.macro weight_add_add dst, s1, s2, h=
    vadduhm     \dst, \s1, \s2
.endm

// weight > 64
.macro load_weights_add_sub
    neg         10,  10
.endm
.macro weight_add_sub dst, s1, s2, h=
    vsubuhm     \dst, \s1, \s2
.endm

// weight < 0
.macro load_weights_sub_add
    neg         9,  9
.endm
.macro weight_sub_add dst, s1, s2, h=
    vsubuhm     \dst, \s2, \s1
.endm

.macro avg_weight_w4 ext,  h
    mtvrwz      4,9
    mtvrwz      5,10
    vspltish    7,1
    vspltish    9,5
    SET_SWAP_BYTE_D_MASK 19,18,10
    vspltb      4,4,7
    vspltb      5,5,7
    li          10,\h>>1
    vslh        7,7,9
    vspltish    8,6
    mtctr       10
4:  // height loop
    LOAD_4_BYTE_H 0,5,0
    LOAD_4_BYTE_H 1,7,0
    add         5,5,6
    add         7,7,8
    LOAD_4_BYTE_H 2,5,0
    LOAD_4_BYTE_H 3,7,0
    vmrghw      0,0,2
    vmrghw      1,1,3
    vmrghb      10,0,1
    add         5,5,6
    add         7,7,8
    vmuleub     0,10,4
    vmuloub     1,10,5
    weight_\ext 0,0,1
    vadduhm     0,0,7
    vsrah       0,0,8
    vpkshus     0,0,0
    vsldoi      1,0,0,4
    STORE_4_BYTE_H 0,3,0
    add         3,3,4
    STORE_4_BYTE_H 1,3,0
    add         3,3,4
    bdnz        4b
.endm

.macro avg_weight_w8 ext,  h
    mtvrwz      8,9
    mtvrwz      9,10
    vspltish    11,1
    vspltish    13,5
    vspltb      8,8,7
    vspltb      9,9,7
    li          10,\h>>2
    vslh        11,11,13
    vspltish    12,6
    mtctr       10
4:  // height loop
    LOAD_8_BYTE_H 0,5,0,9
    LOAD_8_BYTE_H 1,7,0,10
    add         5,5,6
    add         7,7,8
    LOAD_8_BYTE_H 2,5,0,9
    LOAD_8_BYTE_H 3,7,0,10
    add         5,5,6
    add         7,7,8
    LOAD_8_BYTE_H 4,5,0,9
    LOAD_8_BYTE_H 5,7,0,10
    add         5,5,6
    add         7,7,8
    LOAD_8_BYTE_H 6,5,0,9
    LOAD_8_BYTE_H 7,7,0,10
    vmrghb      14,0,1
    vmrghb      15,2,3
    vmrghb      16,4,5
    vmrghb      17,6,7
    add         5,5,6
    add         7,7,8
    vmuleub     0,14,8
    vmuloub     1,14,9
    vmuleub     2,15,8
    vmuloub     3,15,9
    vmuleub     4,16,8
    vmuloub     5,16,9
    vmuleub     6,17,8
    vmuloub     7,17,9
    weight_\ext 0,0,1
    weight_\ext 2,2,3
    weight_\ext 4,4,5
    weight_\ext 6,6,7
    vadduhm     0,0,11
    vadduhm     2,2,11
    vadduhm     4,4,11
    vadduhm     6,6,11
    vsrah       0,0,12
    vsrah       2,2,12
    vsrah       4,4,12
    vsrah       6,6,12
    vpkshus     0,0,0
    vpkshus     2,2,2
    vpkshus     4,4,4
    vpkshus     6,6,6
    STORE_8_BYTE_H 0,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 2,3,0,10
    add         3,3,4
    STORE_8_BYTE_H 4,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 6,3,0,10
    add         3,3,4
    bdnz        4b
.endm

.macro avg_weight_w16 ext,  h
    mtvrwz      8,9
    mtvrwz      9,10
    vspltish    11,1
    vspltish    13,5
    SET_SWAP_BYTE_D_MASK 19,18,10
    vspltb      8,8,7
    vspltb      9,9,7
    li          10,\h>>1
    vslh        11,11,13
    vspltish    12,6
    mtctr       10
4:  // height loop
    LOAD_16_BYTE 0,5,0
    LOAD_16_BYTE 1,7,0
    add         5,5,6
    add         7,7,8
    LOAD_16_BYTE 2,5,0
    LOAD_16_BYTE 3,7,0
    vmrghb      14,0,1
    vmrglb      15,0,1
    vmrghb      16,2,3
    vmrglb      17,2,3
    add         5,5,6
    add         7,7,8
    vmuleub     0,14,8
    vmuloub     1,14,9
    vmuleub     2,15,8
    vmuloub     3,15,9
    vmuleub     4,16,8
    vmuloub     5,16,9
    vmuleub     6,17,8
    vmuloub     7,17,9
    weight_\ext 0,0,1
    weight_\ext 2,2,3
    weight_\ext 4,4,5
    weight_\ext 6,6,7
    vadduhm     0,0,11
    vadduhm     2,2,11
    vadduhm     4,4,11
    vadduhm     6,6,11
    vsrah       0,0,12
    vsrah       2,2,12
    vsrah       4,4,12
    vsrah       6,6,12
    vpkshus     0,0,2
    vpkshus     4,4,6
    STORE_16_BYTE 0,3,0
    add         3,3,4
    STORE_16_BYTE 4,3,0
    add         3,3,4
    bdnz        4b
.endm

.macro avg_w4 h
    SET_SWAP_BYTE_D_MASK 19,18,10
    li          10,\h>>1
    mtctr       10
4:  // height loop
    LOAD_4_BYTE_H 0,5,0
    LOAD_4_BYTE_H 1,7,0
    add         5,5,6
    add         7,7,8
    LOAD_4_BYTE_H 2,5,0
    LOAD_4_BYTE_H 3,7,0
    vavgub      0,0,1
    vavgub      2,2,3
    add         5,5,6
    add         7,7,8
    STORE_4_BYTE_H 0,3,0
    add         3,3,4
    STORE_4_BYTE_H 2,3,0
    add         3,3,4
    bdnz        4b
.endm

.macro avg_w8 h
    li          10,\h>>2
    mtctr       10
4:  // height loop
    LOAD_8_BYTE_H 0,5,0,9
    LOAD_8_BYTE_H 1,7,0,10
    add         5,5,6
    add         7,7,8
    LOAD_8_BYTE_H 2,5,0,9
    LOAD_8_BYTE_H 3,7,0,10
    add         5,5,6
    add         7,7,8
    LOAD_8_BYTE_H 4,5,0,9
    LOAD_8_BYTE_H 5,7,0,10
    add         5,5,6
    add         7,7,8
    LOAD_8_BYTE_H 6,5,0,9
    LOAD_8_BYTE_H 7,7,0,10
    vavgub      0,0,1
    vavgub      2,2,3
    vavgub      4,4,5
    vavgub      6,6,7
    add         5,5,6
    add         7,7,8
    STORE_8_BYTE_H 0,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 2,3,0,10
    add         3,3,4
    STORE_8_BYTE_H 4,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 6,3,0,10
    add         3,3,4
    bdnz        4b
.endm

.macro avg_w16 h
    SET_SWAP_BYTE_D_MASK 19,18,10
    li          10,\h>>1
    mtctr       10
4:  // height loop
    LOAD_16_BYTE 0,5,0
    LOAD_16_BYTE 1,7,0
    add         5,5,6
    add         7,7,8
    LOAD_16_BYTE 2,5,0
    LOAD_16_BYTE 3,7,0
    vavgub      0,0,1
    vavgub      2,2,3
    add         5,5,6
    add         7,7,8
    STORE_16_BYTE 0,3,0
    add         3,3,4
    STORE_16_BYTE 2,3,0
    add         3,3,4
    bdnz        4b
.endm

// void pixel_avg_weight( uint8_t *dst,  intptr_t dst_stride,
//                 uint8_t *src1, intptr_t src1_stride,
//                 uint8_t *src2, intptr_t src2_stride, int weight );
.macro AVGWH w h
function pixel_avg_weight_\w\()x\h\()_altivec
    cmpdi		9,32
    bne         1f
    avg_w\w \h                              // weight == 32
    blr
1:
    li          10,64
    subc.       10,10,9
    bge         2f
    load_weights_add_sub
    avg_weight_w\w add_sub,\h               // weight > 64
    blr
2:
    cmpdi		9,0
    bge         3f
    load_weights_sub_add
    avg_weight_w\w sub_add,\h               // weight < 0
    blr
3:
    avg_weight_w\w add_add,\h
    blr
endfunc
.endm

AVGWH  4, 2
AVGWH  4, 4
AVGWH  4, 8
AVGWH  4, 16
AVGWH  8, 4
AVGWH  8, 8
AVGWH  8, 16
AVGWH 16, 8
AVGWH 16, 16

function mc_weight_w4_nodenom_altivec
    WORD_DATA_SPLAT_BYTE 2,7,36,10
    WORD_DATA_SPLAT_HALFWORD 3,7,40,9
    srdi        8,8,1
    SET_SWAP_BYTE_D_MASK 19,18,10
    mtctr       8
1:  // height loop
    LOAD_4_BYTE_H 0,5,0
    add         5,5,6
    LOAD_4_BYTE_H 1,5,0
    vmrghw      0,0,1
    vmrghb      0,0,0
    add         5,5,6
    vmuleub     0,0,2
    vadduhm     0,0,3
    vpkshus     0,0,0
    vsldoi      1,0,0,4
    STORE_4_BYTE_H 0,3,0
    add         3,3,4
    STORE_4_BYTE_H 1,3,0
    add         3,3,4
    bdnz        1b
    blr
endfunc

function mc_weight_w8_nodenom_altivec
    WORD_DATA_SPLAT_BYTE 2,7,36,10
    srdi        8,8,1
    WORD_DATA_SPLAT_HALFWORD 3,7,40,9
    mtctr       8
1:  // height loop
    LOAD_8_BYTE_H 0,5,0,9
    add         5,5,6
    LOAD_8_BYTE_H 1,5,0,10
    vmrghb      5,0,1
    add         5,5,6
    vmuleub     0,5,2
    vmuloub     1,5,2
    vadduhm     0,0,3
    vadduhm     1,1,3
    vpkshus     0,0,0
    vpkshus     1,1,1
    STORE_8_BYTE_H 0,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 1,3,0,10
    add         3,3,4
    bdnz        1b
    blr
endfunc

function mc_weight_w16_nodenom_altivec
    WORD_DATA_SPLAT_BYTE 4,7,36,10
    WORD_DATA_SPLAT_HALFWORD 5,7,40,9
    srdi        8,8,1
    SET_SWAP_BYTE_D_MASK 19,18,10
    mtctr       8
1:  // height loop
    LOAD_16_BYTE 0,5,0
    add         5,5,6
    LOAD_16_BYTE 2,5,0
    vmrghb      7,0,2
    vmrglb      8,0,2
    add         5,5,6
    vmuleub     0,7,4
    vmuleub     1,8,4
    vmuloub     2,7,4
    vmuloub     3,8,4
    vadduhm     0,0,5
    vadduhm     1,1,5
    vadduhm     2,2,5
    vadduhm     3,3,5
    vpkshus     0,0,1
    vpkshus     2,2,3
    STORE_16_BYTE 0,3,0
    add         3,3,4
    STORE_16_BYTE 2,3,0
    add         3,3,4
    bdnz        1b
    blr
endfunc

function mc_weight_w16_nodenom_altivec_
    WORD_DATA_SPLAT_HALFWORD 6,7,36,10
    WORD_DATA_SPLAT_HALFWORD 7,7,40,9
    srdi        8,8,1
    SET_SWAP_BYTE_D_MASK 19,18,10
    vxor        8,8,8
    mtctr       8
1:  // height loop
    LOAD_16_BYTE 0,5,0
    add         5,5,6
    LOAD_16_BYTE 1,5,0
    vmrghb      2,8,0
    vmrglb      3,8,0
    vmrghb      4,8,1
    vmrglb      5,8,1
    vmladduhm   2,2,6,7
    vmladduhm   3,3,6,7
    vmladduhm   4,4,6,7
    vmladduhm   5,5,6,7
    add         5,5,6
    vpkshus     0,2,3
    vpkshus     1,4,5
    STORE_16_BYTE 0,3,0
    add         3,3,4
    STORE_16_BYTE 1,3,0
    add         3,3,4
    bdnz        1b
    blr
endfunc

function mc_weight_w20_nodenom_altivec
    WORD_DATA_SPLAT_BYTE 6,7,36,10
    WORD_DATA_SPLAT_HALFWORD 7,7,40,9
    srdi        8,8,1
    SET_SWAP_BYTE_D_MASK 19,18,10
    li          9,16
    mtctr       8
1:  // height loop
    LOAD_16_BYTE 0,5,0
    LOAD_4_BYTE_H 1,5,9
    add         5,5,6
    LOAD_16_BYTE 2,5,0
    LOAD_4_BYTE_H 3,5,9
    vmrghb      8,0,2
    vmrglb      9,0,2
    vmrghb      10,1,3
    add         5,5,6
    vmuleub     0,8,6
    vmuleub     1,9,6
    vmuleub     2,10,6
    vmuloub     3,8,6
    vmuloub     4,9,6
    vmuloub     5,10,6
    vadduhm     0,0,7
    vadduhm     1,1,7
    vadduhm     2,2,7
    vadduhm     3,3,7
    vadduhm     4,4,7
    vadduhm     5,5,7
    vpkshus     0,0,1
    vpkshus     2,2,2
    vpkshus     3,3,4
    vpkshus     5,5,5
    STORE_16_BYTE 0,3,0
    STORE_4_BYTE_H 2,3,9
    add         3,3,4
    STORE_16_BYTE 3,3,0
    STORE_4_BYTE_H 5,3,9
    add         3,3,4
    bdnz        1b
    blr
endfunc

.macro weight_simple name op
function mc_weight_w4_\name\()_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    srdi        8,8,1
    HALFWORD_DATA_SPLAT_BYTE 2,7,0,9
    mtctr       8
1:  // height loop
    LOAD_4_BYTE_H 0,5,0
    add         5,5,6
    LOAD_4_BYTE_H 1,5,0
    vmrghw      0,0,1
    add         5,5,6
    \op         0,0,2
    vsldoi      1,0,0,4
    STORE_4_BYTE_H 0,3,0
    add         3,3,4
    STORE_4_BYTE_H 1,3,0
    add         3,3,4
    bdnz        1b
    blr
endfunc

function mc_weight_w8_\name\()_altivec
    srdi        8,8,1
    HALFWORD_DATA_SPLAT_BYTE 2,7,0,10
    mtctr       8
1:  // height loop
    LOAD_8_BYTE_H 0,5,0,9
    add         5,5,6
    LOAD_8_BYTE_H 1,5,0,9
    xxmrghd     VSR(0),VSR(0),VSR(1)
    add         5,5,6
    \op         0,0,2
    xxspltd     VSR(1),VSR(0),1
    STORE_8_BYTE_H 0,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 1,3,0,9
    add         3,3,4
    bdnz        1b
    blr
endfunc

function mc_weight_w16_\name\()_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    srdi        8,8,1
    HALFWORD_DATA_SPLAT_BYTE 2,7,0,9
    mtctr       8
1:  // height loop
    LOAD_16_BYTE 0,5,0
    add         5,5,6
    LOAD_16_BYTE 1,5,0
    \op         0,0,2
    \op         1,1,2
    add         5,5,6
    STORE_16_BYTE 0,3,0
    add         3,3,4
    STORE_16_BYTE 1,3,0
    add         3,3,4
    bdnz        1b
    blr
endfunc

function mc_weight_w20_\name\()_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    srdi        8,8,1
    HALFWORD_DATA_SPLAT_BYTE 4,7,0,9
    li          9,16
    mtctr       8
1:  // height loop
    LOAD_16_BYTE 0,5,0
    LOAD_4_BYTE_H 1,5,9
    add         5,5,6
    LOAD_16_BYTE 2,5,0
    LOAD_4_BYTE_H 3,5,9
    \op         0,0,4
    \op         1,1,4
    \op         2,2,4
    \op         3,3,4
    add         5,5,6
    STORE_16_BYTE 0,3,0
    STORE_4_BYTE_H 1,3,9
    add         3,3,4
    STORE_16_BYTE 2,3,0
    STORE_4_BYTE_H 3,3,9
    add         3,3,4
    bdnz        1b
    blr
endfunc
.endm

weight_simple offsetadd, vaddubs
weight_simple offsetsub, vsububs

.macro integral4h p1, p2, zero
    xxspltd     VSR(\p1),VSR(\p1),0
    vsldoi      1,\p1,\p2,9
    vsldoi      2,\p1,\p2,10
    vsldoi      3,\p1,\p2,11
    vmrghb      0,\zero,\p1
    vmrghb      1,\zero,1
    vmrghb      2,\zero,2
    vmrghb      3,\zero,3
    vadduhm     0,0,1
    vadduhm     4,2,3
    vadduhm     0,0,4
    vadduhm     0,0,5
.endm

function integral_init4h_altivec
    sldi        7,5,1
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    LOAD_8_BYTE_H 6,4,0,9
    vxor        17,17,17
    addi        4,4,8
    sub         6,3,7
    LOAD_8_BYTE_H 7,4,0,10
    addi        4,4,8
1:
    subic.      5,5,16
    LOAD_8_HALFWORD 5,6,0
    integral4h  6,7,17
    addi        6,6,16
    LOAD_8_BYTE_H 6,4,0,9
    LOAD_8_HALFWORD 5,6,0
    addi        4,4,8
    STORE_8_HALFWORD 0,3,0
    addi        6,6,16
    integral4h  7,6,17
    addi        3,3,16
    LOAD_8_BYTE_H 7,4,0,10
    STORE_8_HALFWORD 0,3,0
    addi        4,4,8
    addi        3,3,16
    bgt         1b
    blr
endfunc

.macro integral8h p1, p2, s, zero
    xxspltd     VSR(\p1),VSR(\p1),0
    vsldoi      1,\p1,\p2,9
    vsldoi      2,\p1,\p2,10
    vsldoi      3,\p1,\p2,11
    vsldoi      4,\p1,\p2,12
    vsldoi      5,\p1,\p2,13
    vsldoi      6,\p1,\p2,14
    vsldoi      7,\p1,\p2,15
    vmrghb      0,\zero,\p1
    vmrghb      1,\zero,1
    vmrghb      2,\zero,2
    vmrghb      3,\zero,3
    vmrghb      4,\zero,4
    vmrghb      5,\zero,5
    vmrghb      6,\zero,6
    vmrghb      7,\zero,7
    vadduhm     0,0,1
    vadduhm     2,2,3
    vadduhm     4,4,5
    vadduhm     6,6,7
    vadduhm     0,0,2
    vadduhm     4,4,6
    vadduhm     0,0,\s
    vadduhm     0,0,4
.endm

function integral_init8h_altivec
    sldi        7,5,1
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    LOAD_8_BYTE_H 16,4,0,9
    vxor        15,15,15
    addi        4,4,8
    sub         6,3,7
    LOAD_8_BYTE_H 17,4,0,10
    addi        4,4,8
1:
    subic.      5,5,16
    LOAD_8_HALFWORD 18,6,0
    integral8h  16,17,18,15
    addi        6,6,16
    LOAD_8_BYTE_H 16,4,0,9
    LOAD_8_HALFWORD 18,6,0
    addi        4,4,8
    STORE_8_HALFWORD 0,3,0
    addi        6,6,16
    integral8h  17,16,18,15
    addi        3,3,16
    LOAD_8_BYTE_H 17,4,0,10
    STORE_8_HALFWORD 0,3,0
    addi        4,4,8
    addi        3,3,16
    bgt         1b
    blr
endfunc

function integral_init4v_altivec
    li          9,16
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    mr          6,3
    sldi        7,5,3
    sldi        8,5,4
    LOAD_8_HALFWORD 10,6,0
    subi        5,5,8
    LOAD_8_HALFWORD 11,6,9
    addi        6,6,32
    add         7,3,7
    add         8,3,8
    LOAD_8_HALFWORD 12,6,0
    LOAD_8_HALFWORD 16,8,0
    LOAD_8_HALFWORD 17,8,9
    addi        8,8,32
    LOAD_8_HALFWORD 18,8,0
    addi        6,6,16
    addi        8,8,16
1:
    subic.      5,5,16
    LOAD_8_HALFWORD 14,7,0
    LOAD_8_HALFWORD 15,7,9
    vsldoi      0,10,11,8
    vsldoi      1,11,12,8
    vsldoi      2,16,17,8
    vsldoi      3,17,18,8
    addi        7,7,32
    vsubuhm     14,14,10
    vsubuhm     15,15,11
    vadduhm     0,0,10
    vadduhm     1,1,11
    vadduhm     2,2,16
    vadduhm     3,3,17
    STORE_8_HALFWORD 14,4,0
    STORE_8_HALFWORD 15,4,9
    vmr         10,12
    vmr         16,18
    vsubuhm     0,2,0
    vsubuhm     1,3,1
    addi        4,4,32
    LOAD_8_HALFWORD 11,6,0
    LOAD_8_HALFWORD 12,6,9
    LOAD_8_HALFWORD 17,8,0
    LOAD_8_HALFWORD 18,8,9
    STORE_8_HALFWORD 0,3,0
    STORE_8_HALFWORD 1,3,9
    addi        6,6,32
    addi        8,8,32
    addi        3,3,32
    bgt         1b
    blr
endfunc

function integral_init8v_altivec
    li          9,16
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    sldi        5,4,4
    subi        4,4,8
    add         5,3,5
    andi.       6,4,16 - 1
    beq         1f
    subic.      4,4,8
    LOAD_8_HALFWORD 0,3,0
    LOAD_8_HALFWORD 2,5,0
    vsubuhm     4,2,0
    STORE_8_HALFWORD 4,3,0
    addi        5,5,16
    addi        3,3,16
    ble         2f
1:
    subic.      4,4,16
    LOAD_8_HALFWORD 0,3,0
    LOAD_8_HALFWORD 1,3,9
    LOAD_8_HALFWORD 2,5,0
    LOAD_8_HALFWORD 3,5,9
    vsubuhm     4,2,0
    vsubuhm     5,3,1
    STORE_8_HALFWORD 4,3,0
    STORE_8_HALFWORD 5,3,9
    addi        5,5,32
    addi        3,3,32
    bgt         1b
2:
    blr
endfunc

function mbtree_propagate_cost_altivec
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    vspltish    11,12
    lxsiwzx     VSR(10),0,8
    vslh        11,11,11
    vspltw      10,10,1
    addi        9,9,7
    vnot        11,11
    srdi        9,9,3
    vxor        12,12,12
    mtctr       9
1:
    LOAD_8_HALFWORD 0,4,0
    LOAD_8_HALFWORD 2,5,0
    LOAD_8_HALFWORD 4,6,0
    LOAD_8_HALFWORD 6,7,0
    vand        4,4,11
    vminuh      4,2,4
    vmrglh      1,12,0
    vmrglh      3,12,2   // propagate_denom
    vmrglh      5,12,4
    vmrglh      7,12,6
    vmrghh      0,12,0
    vmrghh      2,12,2   // propagate_denom
    vmrghh      4,12,4
    vmrghh      6,12,6
    addi        4,4,16
    addi        5,5,16
    addi        6,6,16
    addi        7,7,16
    vsubuwm     4,2,4     // propagate_num
    vsubuwm     5,3,5     // propagate_num
    vmulouh     6,2,6     // propagate_intra
    vmulouh     7,3,7     // propagate_intra
    vcfux       0,0,0
    vcfux       1,1,0
    vcfux       2,2,0
    vcfux       3,3,0
    vcfux       4,4,0
    vcfux       5,5,0
    vcfux       6,6,0
    vcfux       7,7,0
    vmaddfp     6,6,10,0  // propagate_amount
    vmaddfp     7,7,10,1  // propagate_amount
    xvmulsp     VSR(4),VSR(6),VSR(4)
    xvmulsp     VSR(5),VSR(7),VSR(5)
    xvdivsp     VSR(0),VSR(4),VSR(2)
    xvdivsp     VSR(1),VSR(5),VSR(3)
    vrfin       0,0
    vrfin       1,1
    vctsxs      0,0,0
    vctsxs      1,1,0
    vpkswss     0,0,1
    STORE_8_HALFWORD 0,3,0
    addi        3,3,16
    bdnz        1b
    blr
endfunc

.macro mbtree_propagate_list_internal_prologue
    subi        10,1,16
    stvx        31,0,10
    subi        10,10,16
    stvx        30,0,10
    subi        10,10,16
    stvx        29,0,10
    subi        10,10,16
    stvx        28,0,10
    subi        10,10,16
    stvx        27,0,10
    subi        10,10,16
    stvx        26,0,10
    subi        10,10,16
    stvx        25,0,10
    subi        10,10,16
    stvx        24,0,10
    subi        10,10,16
    stvx        23,0,10
    subi        10,10,16
    stvx        22,0,10
    subi        10,10,16
    stvx        21,0,10
    subi        10,10,16
    stvx        20,0,10
.endm

.macro mbtree_propagate_list_internal_epilogue
    subi        10,1,16
    lvx         31,0,10
    subi        10,10,16
    lvx         30,0,10
    subi        10,10,16
    lvx         29,0,10
    subi        10,10,16
    lvx         28,0,10
    subi        10,10,16
    lvx         27,0,10
    subi        10,10,16
    lvx         26,0,10
    subi        10,10,16
    lvx         25,0,10
    subi        10,10,16
    lvx         24,0,10
    subi        10,10,16
    lvx         23,0,10
    subi        10,10,16
    lvx         22,0,10
    subi        10,10,16
    lvx         21,0,10
    subi        10,10,16
    lvx         20,0,10
.endm

function mbtree_propagate_list_internal_altivec
    mbtree_propagate_list_internal_prologue
    SET_SWAP_HALFWORD_D_MASK 31,30,10
    VEC_LOAD_DATA 18,.even_half_mask,10
    VEC_LOAD_DATA 19,.odd_half_mask,10
    vxor        13,13,13
    mtvrwz      20,7               // bipred_weight
    vspltish    21,12
    li          10,0x00
    // 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    lvsl        22,10,10           // h->mb.i_mb_x,h->mb.i_mb_y
    vmrghb      22,13,22
    mtvrwz      30,8               // mb_y
    vslh        21,21,21           // 0xC000
    vsplth      30,30,3
    vspltish    23,4               // 4
    vmrghh      22,22,30
    vspltish    29,1
    vspltish    30,5
    vmrghh      23,23,13
    vslh        25,29,30           // 32
    vsplth      20,20,3
    vsubuhm     24,25,29           // 31
    vspltisw    30,5
    vspltisw    29,1
    vslw        26,29,30           // 1 << (6 - 1)
    vspltisw    27,6               // 6
    vspltish    28,5               // 5
    vspltisw    30,9
    addi        9,9,7
    vslw        29,29,30           // 1 << (10 - 1)
    srdi        9,9,3
    vspltisw    30,10              // 10
    li          10,16
    mtctr       9
1:
    LOAD_8_HALFWORD 0,4,0 // propagate_amount
    LOAD_8_HALFWORD 1,5,0 // lowres_cost
    vand        1,1,21
    vmrghh      2,0,0
    vmrglh      3,0,0
    vcmpequh    4,1,21
    vmuleuh     2,2,20
    vmuleuh     3,3,20
    addi        4,4,16
    addi        5,5,16
    vadduwm     2,2,26
    vadduwm     3,3,26
    vsrw        2,2,27
    vsrw        3,3,27
    vpkuwum     1,2,3
    vsel        0,0,1,4   // if( lists_used == 3 )
    //          propagate_amount = (propagate_amount * bipred_weight + 32) >> 6
    LOAD_8_HALFWORD 5,3,0
    LOAD_8_HALFWORD 6,3,10
    vsrah       7,5,28
    vsrah       8,6,28
    vadduhm     7,7,22
    vadduhm     22,22,23
    vadduhm     8,8,22
    vadduhm     22,22,23
    addi        3,3,32
    STORE_8_HALFWORD 7,6,0
    STORE_8_HALFWORD 8,6,10
    vand        5,5,24
    vand        6,6,24
    vperm       1,5,6,18  // x & 31
    vperm       2,5,6,19  // y & 31
    addi        6,6,32
    vsubuhm     3,25,1    // 32 - (x & 31)
    vsubuhm     4,25,2    // 32 - (y & 31)
    vmladduhm   14,1,2,13  // idx3weight = y*x;
    vmladduhm   15,3,2,13  // idx2weight = y*(32-x);
    vmladduhm   16,1,4,13  // idx1weight = (32-y)*x;
    vmladduhm   17,3,4,13  // idx0weight = (32-y)*(32-x);
    vmuleuh     5,14,0
    vmulouh     6,14,0
    vmuleuh     7,15,0
    vmulouh     8,15,0
    vmuleuh     9,16,0
    vmulouh     10,16,0
    vmuleuh     11,17,0
    vmulouh     12,17,0
    vadduwm     5,5,29
    vadduwm     6,6,29
    vadduwm     7,7,29
    vadduwm     8,8,29
    vadduwm     9,9,29
    vadduwm     10,10,29
    vadduwm     11,11,29
    vadduwm     12,12,29
    vsrw        5,5,30
    vsrw        6,6,30
    vsrw        7,7,30
    vsrw        8,8,30
    vsrw        9,9,30
    vsrw        10,10,30
    vsrw        11,11,30
    vsrw        12,12,30
    vpkuwum     5,5,7
    vpkuwum     6,6,8
    vpkuwum     9,9,11
    vpkuwum     10,10,12
    vmrghh      0,5,6
    vmrglh      1,5,6
    vmrghh      2,9,10
    vmrglh      3,9,10
    vmrghh      6,1,0
    vmrglh      7,1,0
    vmrghh      4,3,2
    vmrglh      5,3,2
    STORE_8_HALFWORD 4,6,0
    STORE_8_HALFWORD 5,6,10
    addi        6,6,32
    STORE_8_HALFWORD 6,6,0
    STORE_8_HALFWORD 7,6,10
    addi        6,6,32
    bdnz        1b
    mbtree_propagate_list_internal_epilogue
    blr
endfunc

data_byte_16 .even_half_mask 0x00, 0x01, 0x04, 0x05, 0x08, 0x09, 0x0C, 0x0D, 0x10, 0x11, 0x14, 0x15, 0x18, 0x19, 0x1C, 0x1D
data_byte_16 .odd_half_mask  0x02, 0x03, 0x06, 0x07, 0x0A, 0x0B, 0x0E, 0x0F, 0x12, 0x13, 0x16, 0x17, 0x1A, 0x1B, 0x1E, 0x1F
