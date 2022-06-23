/*****************************************************************************
 * dct-a.S: ppc transform and zigzag
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

function dct4x4dc_altivec
    SET_SWAP_HALFWORD_D_MASK 19,16,10
    li          4,16
    vxor        8,8,8
    LOAD_8_HALFWORD 0,3,0
    LOAD_8_HALFWORD 2,3,4
    VEC_LOAD_DATA 18,.trn_even_halfword_mask,9
    xxspltd  VSR(1),VSR(0),1
    xxspltd  VSR(3),VSR(2),1
    VEC_LOAD_DATA 17,.trn_odd_halfword_mask,8
    SUMSUB_AB_HALFWORD 4,5,0,1
    SUMSUB_AB_HALFWORD 6,7,2,3
    SUMSUB_AB_HALFWORD 0,2,4,6
    SUMSUB_AB_HALFWORD 3,1,5,7
    TRANSPOSE_HALFWORD 4,6,0,2,18,17
    TRANSPOSE_HALFWORD 5,7,1,3,18,17
    SUMSUB_AB_HALFWORD 0,2,4,6
    SUMSUB_AB_HALFWORD 1,3,5,7
    TRANSPOSE_WORD 4,5,0,1
    TRANSPOSE_WORD 6,7,2,3
    vsubuhm     9,8,5
    vsubuhm     10,8,7
    vavgsh      0,4,5
    vavgsh      1,4,9
    vavgsh      2,6,10
    vavgsh      3,6,7
    xxmrghd     VSR(0),VSR(0),VSR(1)
    xxmrghd     VSR(2),VSR(2),VSR(3)
    STORE_8_HALFWORD 0,3,0
    STORE_8_HALFWORD 2,3,4
    blr
endfunc

function idct4x4dc_altivec
    SET_SWAP_HALFWORD_D_MASK 19,16,10
    li          4,16
    LOAD_8_HALFWORD 0,3,0
    LOAD_8_HALFWORD 2,3,4
    VEC_LOAD_DATA 18,.trn_even_halfword_mask,9
    xxspltd  VSR(1),VSR(0),1
    xxspltd  VSR(3),VSR(2),1
    VEC_LOAD_DATA 17,.trn_odd_halfword_mask,8
    SUMSUB_AB_HALFWORD 4,5,0,1
    SUMSUB_AB_HALFWORD 6,7,2,3
    SUMSUB_AB_HALFWORD 0,2,4,6
    SUMSUB_AB_HALFWORD 3,1,5,7
    TRANSPOSE_HALFWORD 4,6,0,2,18,17
    TRANSPOSE_HALFWORD 5,7,1,3,18,17
    SUMSUB_AB_HALFWORD 0,2,4,6
    SUMSUB_AB_HALFWORD 1,3,5,7
    TRANSPOSE_WORD 4,5,0,1
    TRANSPOSE_WORD 6,7,2,3
    SUMSUB_AB_HALFWORD 0,1,4,5
    SUMSUB_AB_HALFWORD 3,2,6,7
    xxmrghd     VSR(0),VSR(0),VSR(1)
    xxmrghd     VSR(2),VSR(2),VSR(3)
    STORE_8_HALFWORD 0,3,0
    STORE_8_HALFWORD 2,3,4
    blr
endfunc

.macro sub4x4x2_dct_dc, dst, t0, t1, t2, t3, t4, t5, t6, t7, z
    LOAD_8_BYTE_H \t0,4,0,9
    addi        4,4,FENC_STRIDE
    LOAD_8_BYTE_H \t1,5,0,10
    addi        5,5,FDEC_STRIDE
    LOAD_8_BYTE_H \t2,4,0,9
    addi        4,4,FENC_STRIDE
    vmrghb      \t0,\z,\t0
    vmrghb      \t1,\z,\t1
    LOAD_8_BYTE_H \t3,5,0,10
    addi        5,5,FDEC_STRIDE
    vsubuhm     \t0,\t0,\t1
    LOAD_8_BYTE_H \t4,4,0,9
    addi        4,4,FENC_STRIDE
    vmrghb      \t2,\z,\t2
    vmrghb      \t3,\z,\t3
    LOAD_8_BYTE_H \t5,5,0,10
    addi        5,5,FDEC_STRIDE
    vsubuhm     \t1,\t2,\t3
    LOAD_8_BYTE_H \t6,4,0,9
    vadduhm     \dst,\t0,\t1
    addi        4,4,FENC_STRIDE
    vmrghb      \t4,\z,\t4
    vmrghb      \t5,\z,\t5
    LOAD_8_BYTE_H \t7,5,0,10
    vsubuhm     \t2,\t4,\t5
    addi        5,5,FDEC_STRIDE
    vmrghb      \t6,\z,\t6
    vmrghb      \t7,\z,\t7
    vsubuhm     \t3,\t6,\t7
    vadduhm     \dst,\dst,\t2
    vadduhm     \dst,\dst,\t3
.endm

function sub8x16_dct_dc_altivec
    vxor        19,19,19
    sub4x4x2_dct_dc  0,4,5,6,7,8,9,10,11,19
    sub4x4x2_dct_dc  1,12,13,14,15,16,17,18,4,19
    sub4x4x2_dct_dc  2,4,5,6,7,8,9,10,11,19
    sub4x4x2_dct_dc  3,12,13,14,15,16,17,18,4,19
    SET_SWAP_HALFWORD_D_MASK 8,5,10

    vsum4shs    4,0,19
    vsum4shs    5,1,19
    vsum4shs    6,2,19
    vsum4shs    7,3,19
    vpkuwum     4,4,6
    vpkuwum     5,5,7

    TRANSPOSE_WORD 2,3,4,5
    SUMSUB_AB_HALFWORD 0,1,2,3

    TRANSPOSE_WORD 2,3,0,1
    SUMSUB_AB_HALFWORD 0,1,2,3

    TRANSPOSE_DOUBLEWORD 2,3,0,1
    SUMSUB_AB_HALFWORD 0,1,2,3

    xxmrghd     VSR(2),VSR(0),VSR(1)
    xxmrgld     VSR(3),VSR(1),VSR(0)

    vsum4shs    2,2,19
    vsum4shs    3,3,19
    vpkuwum     0,2,3
    
    STORE_8_HALFWORD 0,3,0
    blr
endfunc

.macro zigzag_sub_4x4 f ac
function zigzag_sub_4x4\ac\()_\f\()_altivec
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    VEC_LOAD_DATA 16,sub4x4_\f,7
    li          8,1*FDEC_STRIDE
    li          9,2*FDEC_STRIDE
    li          10,3*FDEC_STRIDE
    REG_LOAD_4_BYTE 7,5,0
    REG_LOAD_4_BYTE 8,5,8
    REG_LOAD_4_BYTE 9,5,9
    REG_LOAD_4_BYTE 10,5,10
    vxor        8,8,8
    mtvrwz      0,7
    mtvrwz      1,8
    mtvrwz      2,9
    mtvrwz      3,10
    vmrgow      0,0,1
    vmrgow      2,2,3
    li          8,1*FENC_STRIDE
    li          9,2*FENC_STRIDE
    li          10,3*FENC_STRIDE
    REG_LOAD_4_BYTE 7,4,0
    REG_LOAD_4_BYTE 8,4,8
    REG_LOAD_4_BYTE 9,4,9
    REG_LOAD_4_BYTE 10,4,10
    xxmrghd     VSR(0),VSR(0),VSR(2)
    mtvrwz      4,7
    mtvrwz      5,8
    mtvrwz      6,9
    mtvrwz      7,10
    vmrgow      4,4,5
    vmrgow      6,6,7
    xxmrghd     VSR(4),VSR(4),VSR(6)
    vperm       3,0,0,16
    vperm       2,4,4,16
    REG_STORE_4_BYTE 7,5,0
    vmrghb      11,8,3
    vmrghb      9,8,2
    vmrglb      12,8,3
    vmrglb      10,8,2
    addi        5,5,FDEC_STRIDE
    vsubuhm     4,9,11
.ifc \ac, ac
    mfvrd       7,4
    vsldoi      4,4,8,2
    srdi        7,7,48
    vsldoi      4,8,4,14
    sth         7,0(6)
.endif
    vsubuhm     5,10,12
    REG_STORE_4_BYTE 8,5,0
    vor         6,4,5
    addi        5,5,FDEC_STRIDE
    xxspltd     VSR(9),VSR(6),1
    vor         6,6,9
    REG_STORE_4_BYTE 9,5,0
    vmrgow      10,6,8
    addi        5,5,FDEC_STRIDE
    vor         6,6,10
    REG_STORE_4_BYTE 10,5,0
    mfvrd       7,6
    STORE_8_HALFWORD 4,3,0
    srdi        8,7,48
    rldicl      9,7,32,48
    addi        3,3,16
    or          8,8,9
    li          5,0
    li          4,1
    STORE_8_HALFWORD 5,3,0
    cmplwi      8,0
    iseleq      3,5,4
    blr
endfunc
.endm

zigzag_sub_4x4 field
zigzag_sub_4x4 field, ac
zigzag_sub_4x4 frame
zigzag_sub_4x4 frame, ac

data_byte_16 sub4x4_frame 0, 1, 4, 8, 5, 2, 3, 6, 9, 12, 13, 10, 7, 11, 14, 15
data_byte_16 sub4x4_field 0, 4, 1, 8, 12, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15
data_byte_16 .trn_even_halfword_mask 0x00, 0x01, 0x10, 0x11, 0x04, 0x05, 0x14, 0x15, 0x08, 0x09, 0x18, 0x19, 0x0C, 0x0D, 0x1C, 0x1D
data_byte_16 .trn_odd_halfword_mask  0x02, 0x03, 0x12, 0x13, 0x06, 0x07, 0x16, 0x17, 0x0A, 0x0B, 0x1A, 0x1B, 0x0E, 0x0F, 0x1E, 0x1F
