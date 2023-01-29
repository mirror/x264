/*****************************************************************************
 * deblock.S: ppc deblocking
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

.macro h264_loop_filter_start
    cmpwi       cr7,5,0
    REG_LOAD_4_BYTE 8,7,0
    cmpwi       6,0
    crandc      eq,eq,4*cr7+eq
    mtvrwz      14,8
    slwi        9,8,16
    vsldoi      14,14,14,4
    and         9,9,8
    beq         1f
    slwi        10,9,8
    and.        10,10,9
    bge         2f
1:
    blr
2:
.endm

.macro h264_loop_filter_start_intra
    or.         7,5,6
    bne         1f
    blr
1:
    mtvrwz      11,5
    mtvrwz      12,6
    vspltb      11,11,7
    vspltb      12,12,7
.endm

.macro h264_loop_filter_chroma
    vxor        17,17,17
    mtvrwz      12,5
    vmaxub      6,16,0
    vminub      11,16,0
    vmrghb      13,17,0
    vmrglb      19,17,0
    vmaxub      8,18,16
    vminub      3,18,16
    vmrghb      1,17,16
    vmrglb      15,17,16
    vspltish    7,2
    vspltb      12,12,7
    vsububm     6,6,11
    vsubuhm     4,13,1
    vsubuhm     5,19,15
    vmrghb      14,14,14
    vsububm     8,8,3
    vslh        4,4,7
    vslh        5,5,7
    vmaxub      10,2,0
    vminub      9,2,0
    vmrghb      11,17,18
    vmrglb      3,17,18
    vsububm     10,10,9
    vadduhm     4,4,11
    vadduhm     5,5,3
    vcmpgtub    6,12,6
    vmrghb      7,17,2
    vmrglb      9,17,2
    vspltish    11,4
    vspltish    3,3
    vsubuhm     4,4,7
    vsubuhm     5,5,9
    mtvrwz      12,6
    vadduhm     4,4,11
    vadduhm     5,5,11
    vmrghh      14,14,14
    vspltb      12,12,7
    vsrh        4,4,3
    vsrh        5,5,3
    vpkuhum     4,4,5
    vcmpgtub    8,12,8
    vcmpgtub    10,12,10
    vminsb      4,4,14
    vsububm     7,17,14
    vand        6,6,8
    vmaxsb      4,4,7
    vand        6,6,10
    vand        4,4,6
    vupkhsb     11,4
    vupklsb     3,4
    vadduhm     1,1,11
    vadduhm     15,15,3
    vsubuhm     13,13,11
    vsubuhm     19,19,3
    vpkshus     16,1,15
    vpkshus     0,13,19
.endm

function deblock_v_chroma_altivec
    h264_loop_filter_start

    subi        9,1,16
    sldi        8,4,1
    stvx        31,0,9
    SET_SWAP_BYTE_D_MASK 31,19,10
    sub         3,3,8
    LOAD_16_BYTE 18,3,0
    add         3,3,4
    LOAD_16_BYTE 16,3,0
    add         3,3,4
    LOAD_16_BYTE 0,3,0
    add         3,3,4
    LOAD_16_BYTE 2,3,0

    h264_loop_filter_chroma

    sub         3,3,8
    STORE_16_BYTE 16,3,0
    add         3,3,4
    STORE_16_BYTE 0,3,0
    lvx         31,0,9

    blr
endfunc

.macro deblock_h_chroma
    LOAD_8_BYTE_H 18,3,0,9
    add         3,3,4
    LOAD_8_BYTE_H 16,3,0,10
    add         3,3,4
    LOAD_8_BYTE_H 0,3,0,9
    add         3,3,4
    LOAD_8_BYTE_H 2,3,0,10
    add         3,3,4
    LOAD_8_BYTE_H 8,3,0,9
    add         3,3,4
    LOAD_8_BYTE_H 6,3,0,10
    add         3,3,4
    LOAD_8_BYTE_H 10,3,0,9
    add         3,3,4
    LOAD_8_BYTE_H 12,3,0,10
    xxmrghd     VSR(18),VSR(18),VSR(8)
    xxmrghd     VSR(16),VSR(16),VSR(6)
    xxmrghd     VSR(0),VSR(0),VSR(10)
    xxmrghd     VSR(2),VSR(2),VSR(12)
    add         3,3,4

    TRANSPOSE_4x8_H 18,16,0,2,19,17,1,3,31,30

    h264_loop_filter_chroma

    TRANSPOSE_4x8_H 18,16,0,2,19,17,1,3,31,30

    sldi        10,4,3
    xxspltd     VSR(8),VSR(18),1
    xxspltd     VSR(6),VSR(16),1
    xxspltd     VSR(10),VSR(0),1
    xxspltd     VSR(12),VSR(2),1
    sub         3,3,10
    STORE_8_BYTE_H 18,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 16,3,0,10
    add         3,3,4
    STORE_8_BYTE_H 0,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 2,3,0,10
    add         3,3,4
    STORE_8_BYTE_H 8,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 6,3,0,10
    add         3,3,4
    STORE_8_BYTE_H 10,3,0,9
    add         3,3,4
    STORE_8_BYTE_H 12,3,0,10
.endm

function deblock_h_chroma_altivec
    h264_loop_filter_start
    subi        3,3,4
    subi        9,1,16
    stvx        31,0,9
    subi        9,9,16
    stvx        30,0,9
    VEC_LOAD_DATA 31,.trn_even_halfword_mask,10
    VEC_LOAD_DATA 30,.trn_odd_halfword_mask,9
    deblock_h_chroma
    subi        9,1,16
    lvx         31,0,9
    subi        9,9,16
    lvx         30,0,9
    blr
endfunc

function deblock_h_chroma_422_altivec
    h264_loop_filter_start
    add         7,3,4
    subi        9,1,16
    stvx        31,0,9
    subi        9,9,16
    stvx        30,0,9
    subi        3,3,4
    VEC_LOAD_DATA 31,.trn_even_halfword_mask,10
    VEC_LOAD_DATA 30,.trn_odd_halfword_mask,9
    add         4,4,4
    deblock_h_chroma
    mtvrwz      14,8
    subi        3,7,4
    vsldoi      14,14,14,4
    deblock_h_chroma
    subi        9,1,16
    lvx         31,0,9
    subi        9,9,16
    lvx         30,0,9
    blr
endfunc

.macro h264_loop_filter_chroma8
    vxor        15,15,15
    vspltish    9,2
    vspltish    13,4
    vspltish    10,3
    mtvrwz      0,5
    mtvrwz      2,6
    vmrghb      12,15,16
    vmrghb      11,15,17
    vmrghb      6,15,19
    vmrghb      14,14,14
    vmaxub      3,16,17
    vminub      7,16,17
    vmaxub      5,18,16
    vminub      8,18,16
    vsubuhm     4,11,12
    vsububm     3,3,7
    vmrghb      18,15,18
    vslh        4,4,9
    vspltb      0,0,7
    vspltb      2,2,7
    vadduhm     4,4,18
    vmaxub      9,19,17
    vminub      7,19,17
    vsububm     5,5,8
    vsubuhm     4,4,6
    vcmpgtub    3,0,3
    vadduhm     4,4,13
    vsububm     9,9,7
    vsrh        4,4,10
    vcmpgtub    5,2,5
    vpkuhum     4,4,15
    vcmpgtub    9,2,9
    vminsb      4,4,14
    vsububm     8,15,14
    vand        3,3,5
    vmaxsb      4,4,8
    vand        3,3,9
    vand        4,4,3
    vupkhsb     4,4
    vadduhm     12,12,4
    vsubuhm     11,11,4
    vpkshus     16,12,15
    vpkshus     17,11,15
.endm

function deblock_h_chroma_mbaff_altivec
    h264_loop_filter_start

    subi        7,3,4
    subi        3,3,2

    LOAD_8_BYTE_H 18,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 16,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 17,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 19,7,0,10

    VEC_LOAD_DATA 9,.trn_even_halfword_mask,9
    VEC_LOAD_DATA 8,.trn_odd_halfword_mask,10

    TRANSPOSE_4x4_H 18,16,17,19,10,11,12,13,9,8

    h264_loop_filter_chroma8

    mfvrd       7,16
    mfvrd       8,17
    li          6,2
    rotldi      9,7,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 7,3,0
    REG_STORE_2_BYTE 8,3,6

    blr
endfunc

.macro h264_loop_filter_chroma_intra width=16
    vxor        15,15,15
    vspltish    14,1
    vmaxub      8,16,17
    vminub      1,16,17
    vmaxub      9,18,16
    vminub      2,18,16
    vmaxub      10,19,17
    vminub      3,19,17
    vsububm     8,8,1
    vsububm     9,9,2
    vsububm     10,10,3
    vcmpgtub    8,11,8
    vcmpgtub    9,12,9
    vcmpgtub    10,12,10
    vand        8,8,9
    vand        8,8,10
    vmrghb      3,15,18
    vmrghb      13,15,19
    vmrghb      1,15,16
    vmrghb      2,15,17
    vslh        4,3,14
    vslh        6,13,14
.ifc \width, 16
    vmrglb      18,15,18
    vmrglb      19,15,19
    vmrglb      10,15,16
    vmrglb      12,15,17
    vslh        5,18,14
    vslh        7,19,14
    vadduhm     10,10,19
    vadduhm     12,12,18
.endif
    vadduhm     9,1,13
    vadduhm     11,2,3
    vspltish    14,2
    vadduhm     9,9,4
    vadduhm     11,11,6
.ifc \width, 16
    vadduhm     10,10,5
    vadduhm     12,12,7
    vadduhm     9,9,14
    vadduhm     11,11,14
    vadduhm     10,10,14
    vadduhm     12,12,14
    vsrh        9,9,14
    vsrh        11,11,14
    vsrh        10,10,14
    vsrh        12,12,14
    vpkuhus     9,9,10
    vpkuhus     11,11,12
.else
    vadduhm     9,9,14
    vadduhm     11,11,14
    vsrh        9,9,14
    vsrh        11,11,14
    vpkuhus     9,9,15
    vpkuhus     11,11,15
.endif
    vsel        16,16,9,8
    vsel        17,17,11,8
.endm

function deblock_v_chroma_intra_altivec
    h264_loop_filter_start_intra

    SET_SWAP_BYTE_D_MASK 0,15,10
    sldi        7,4,1
    sub         3,3,7
    LOAD_16_BYTE 18,3,0
    add         3,3,4
    LOAD_16_BYTE 16,3,0
    add         3,3,4
    LOAD_16_BYTE 17,3,0
    add         3,3,4
    LOAD_16_BYTE 19,3,0

    h264_loop_filter_chroma_intra

    sub         3,3,7
    STORE_16_BYTE 16,3,0
    add         3,3,4
    STORE_16_BYTE 17,3,0

    blr
endfunc

function deblock_h_chroma_intra_mbaff_altivec
    h264_loop_filter_start_intra

    subi        7,3,4
    subi        3,3,2
    LOAD_8_BYTE_H 18,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 16,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 17,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 19,7,0,10

    VEC_LOAD_DATA 9,.trn_even_halfword_mask,9
    VEC_LOAD_DATA 8,.trn_odd_halfword_mask,10

    TRANSPOSE_4x4_H 18,16,17,19,0,1,2,3,9,8

    h264_loop_filter_chroma_intra width=8

    mfvrd       7,16
    mfvrd       8,17
    li          6,2
    rotldi      9,7,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 7,3,0
    REG_STORE_2_BYTE 8,3,6

    blr
endfunc

function deblock_h_chroma_intra_altivec
    h264_loop_filter_start_intra

    subi        7,3,4
    subi        3,3,2
    LOAD_8_BYTE_H 18,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 16,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 17,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 19,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 8,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 6,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 7,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 9,7,0,10
    xxmrghd     VSR(18),VSR(18),VSR(8)
    xxmrghd     VSR(16),VSR(16),VSR(6)
    xxmrghd     VSR(17),VSR(17),VSR(7)
    xxmrghd     VSR(19),VSR(19),VSR(9)

    VEC_LOAD_DATA 5,.trn_even_halfword_mask,9
    VEC_LOAD_DATA 4,.trn_odd_halfword_mask,10

    TRANSPOSE_4x8_H 18,16,17,19,0,1,2,3,5,4

    h264_loop_filter_chroma_intra

    mfvrd       7,16
    mfvrd       8,17
    li          6,2
    rotldi      9,7,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    xxspltd     VSR(16),VSR(16),1
    xxspltd     VSR(17),VSR(17),1
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 7,3,0
    REG_STORE_2_BYTE 8,3,6
    add         3,3,4
    mfvrd       7,16
    mfvrd       8,17
    rotldi      9,7,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 7,3,0
    REG_STORE_2_BYTE 8,3,6

    blr
endfunc

function deblock_h_chroma_422_intra_altivec
    h264_loop_filter_start_intra

    subi        7,3,4
    subi        3,3,2
    LOAD_8_BYTE_H 18,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 16,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 17,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 19,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 8,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 6,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 7,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 9,7,0,10
    add         7,7,4
    xxmrghd     VSR(18),VSR(18),VSR(8)
    xxmrghd     VSR(16),VSR(16),VSR(6)
    xxmrghd     VSR(17),VSR(17),VSR(7)
    xxmrghd     VSR(19),VSR(19),VSR(9)

    VEC_LOAD_DATA 5,.trn_even_halfword_mask,9
    VEC_LOAD_DATA 4,.trn_odd_halfword_mask,10

    TRANSPOSE_4x8_H 18,16,17,19,0,1,2,3,5,4

    h264_loop_filter_chroma_intra

    mtvrwz      11,5
    mtvrwz      12,6
    vspltb      11,11,7
    vspltb      12,12,7

    mfvrd       5,16
    mfvrd       8,17
    li          6,2
    rotldi      9,5,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    xxspltd     VSR(16),VSR(16),1
    xxspltd     VSR(17),VSR(17),1
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 5,3,0
    REG_STORE_2_BYTE 8,3,6
    add         3,3,4
    mfvrd       5,16
    mfvrd       8,17
    rotldi      9,5,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 5,3,0
    REG_STORE_2_BYTE 8,3,6
    add         3,3,4

    LOAD_8_BYTE_H 18,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 16,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 17,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 19,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 8,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 6,7,0,10
    add         7,7,4
    LOAD_8_BYTE_H 7,7,0,9
    add         7,7,4
    LOAD_8_BYTE_H 9,7,0,10
    xxmrghd     VSR(18),VSR(18),VSR(8)
    xxmrghd     VSR(16),VSR(16),VSR(6)
    xxmrghd     VSR(17),VSR(17),VSR(7)
    xxmrghd     VSR(19),VSR(19),VSR(9)

    VEC_LOAD_DATA 5,.trn_even_halfword_mask,9
    VEC_LOAD_DATA 4,.trn_odd_halfword_mask,10

    TRANSPOSE_4x8_H 18,16,17,19,0,1,2,3,5,4

    h264_loop_filter_chroma_intra

    mfvrd       7,16
    mfvrd       8,17
    li          6,2
    rotldi      9,7,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    xxspltd     VSR(16),VSR(16),1
    xxspltd     VSR(17),VSR(17),1
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 7,3,0
    REG_STORE_2_BYTE 8,3,6
    add         3,3,4
    mfvrd       7,16
    mfvrd       8,17
    rotldi      9,7,16
    rotldi      10,8,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    rotldi      9,9,16
    rotldi      10,10,16
    REG_STORE_2_BYTE 9,3,0
    REG_STORE_2_BYTE 10,3,6
    add         3,3,4
    REG_STORE_2_BYTE 7,3,0
    REG_STORE_2_BYTE 8,3,6

    blr
endfunc

function deblock_strength_altivec
    vxor        9,9,9
    SET_SWAP_BYTE_D_MASK 8,19,10
    SET_SWAP_HALFWORD_D_MASK 7,18,9
    VEC_LOAD_DATA 17,.even_word_mask,10
    VEC_LOAD_DATA 16,.odd_word_mask,9
    slwi        7,7,8
    addi        6,6,32
    subi        7,7,(1<<8)-3
    vxor        5,5,5
    mtvrwz      6,7
    vspltish    10,8
    vsplth      6,6,3
    vxor        4,4,4
    li          9,16
    vrlh        6,6,10
bframe:
    LOAD_8_BYTE_H 14,4,0,10
    addi        4,4,8
    addi        5,5,16
    LOAD_16_BYTE 1,4,0
    LOAD_16_BYTE 2,4,9
    vsldoi      3,9,1,15
    vsldoi      0,9,2,15
    xxspltd     VSR(14),VSR(14),0
    vperm       11,1,2,17
    vperm       12,1,2,16
    vperm       13,3,0,17
    vperm       10,3,0,16
    vsldoi      11,14,12,12
    addi        4,4,32
    vxor        0,10,12
    vxor        1,11,12
    vor         4,4,0
    vor         5,5,1
    LOAD_8_HALFWORD 11,5,0
    LOAD_8_HALFWORD 19,5,9
    addi        5,5,32
    LOAD_8_HALFWORD 12,5,0
    LOAD_8_HALFWORD 18,5,9
    addi        5,5,32
    LOAD_8_HALFWORD 13,5,0
    vsldoi      19,19,12,12
    vsldoi      18,18,13,12
    vsubuhm     2,12,19
    LOAD_8_HALFWORD 19,5,9
    vsubuhm     3,13,18
    ABS_HALFWORD 0,2,9
    addi        5,5,32
    ABS_HALFWORD 1,3,9
    LOAD_8_HALFWORD 14,5,0
    vpkuhus     0,0,1
    LOAD_8_HALFWORD 18,5,9
    addi        5,5,32
    LOAD_8_HALFWORD 15,5,0
    vsldoi      19,19,14,12
    vsldoi      18,18,15,12
    vsubuhm     19,14,19
    ABS_HALFWORD 1,19,9
    vsubuhm     18,15,18
    addi        5,5,16
    ABS_HALFWORD 2,18,9
    vpkuhus     1,1,2
    vsububs     0,0,6
    vsububs     1,1,6
    vpkuhus     0,0,1
    vsubuhm     3,12,13
    vor         4,4,0
    vsubuhm     11,11,12
    vsubuhm     13,13,14
    vsubuhm     15,14,15
    ABS_HALFWORD 1,3,9
    ABS_HALFWORD 0,11,9
    ABS_HALFWORD 2,13,9
    ABS_HALFWORD 3,15,9
    vpkuhus     0,0,1
    vpkuhus     1,2,3
    vsububs     0,0,6
    vsububs     1,1,6
    vpkuhus     0,0,1
    subic.      8,8,1
    vor         5,5,0
    beq         bframe
    LOAD_8_BYTE_H 14,3,0,10
    addi        3,3,8
    vspltisb    6,1
    LOAD_16_BYTE 1,3,0
    vxor        0,0,0
    LOAD_16_BYTE 2,3,9
    vsldoi      3,0,1,15
    vsldoi      0,0,2,15
    xxspltd     VSR(14),VSR(14),0
    vperm       11,1,2,17
    vperm       12,1,2,16
    vperm       13,3,0,17
    vperm       10,3,0,16
    vsldoi      11,14,12,12
    VEC_LOAD_DATA 7,.transpose_table,10
    vor         0,10,12
    vor         1,11,12
    vminub      0,0,6
    vminub      1,1,6
    vminub      4,4,6
    vminub      5,5,6
    vaddubm     0,0,0
    vaddubm     1,1,1
    vmaxub      4,4,0
    vmaxub      5,5,1
    vperm       6,4,4,7
    STORE_16_BYTE 5,6,0
    addi        6,6,-32
    STORE_16_BYTE 6,6,0
    blr
endfunc

data_byte_16 .trn_even_halfword_mask 0x00, 0x01, 0x10, 0x11, 0x04, 0x05, 0x14, 0x15, 0x08, 0x09, 0x18, 0x19, 0x0C, 0x0D, 0x1C, 0x1D
data_byte_16 .trn_odd_halfword_mask  0x02, 0x03, 0x12, 0x13, 0x06, 0x07, 0x16, 0x17, 0x0A, 0x0B, 0x1A, 0x1B, 0x0E, 0x0F, 0x1E, 0x1F
data_byte_16 .even_word_mask 0x00, 0x01, 0x02, 0x03, 0x08, 0x09, 0x0A, 0x0B, 0x10, 0x11, 0x12, 0x13, 0x18, 0x19, 0x1A, 0x1B
data_byte_16 .odd_word_mask  0x04, 0x05, 0x06, 0x07, 0x0C, 0x0D, 0x0E, 0x0F, 0x14, 0x15, 0x16, 0x17, 0x1C, 0x1D, 0x1E, 0x1F
data_byte_16 .transpose_table 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15
