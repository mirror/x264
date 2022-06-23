/*****************************************************************************
 * predict.S: ppc intra prediction
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

function predict_4x4_ddr_altivec
    vxor        5,5,5
    vspltish    6,2
    subi        4,3,FDEC_STRIDE+1
    LOAD_8_BYTE_H 0,4,0,10
    lbz         5,1*FDEC_STRIDE(4)
    lbz         6,2*FDEC_STRIDE(4)
    mtvrwz      1,5
    mtvrwz      2,6
    vsplth      1,1,3
    vsplth      2,2,3
    lbz         7,3*FDEC_STRIDE(4)
    lbz         8,4*FDEC_STRIDE(4)
    vmrghb      0,5,0
    vsldoi      0,1,0,14
    mtvrwz      3,7
    mtvrwz      4,8
    vsplth      3,3,3
    vsplth      4,4,3
    vsldoi      0,2,0,14
    vsldoi      1,3,0,14
    vsldoi      2,4,1,14
    vadduhm     0,0,1
    vadduhm     1,1,2
    vadduhm     0,0,1
    vadduhm     0,0,6
    vsrh        0,0,6
    vpkuhum     0,0,5
    mfvrd       4,0
    rotldi      4,4,32
    rotldi      7,4,24
    rotldi      6,4,16
    rotldi      5,4,8
    REG_STORE_4_BYTE 7,3,0
    addi        3,3,FDEC_STRIDE
    REG_STORE_4_BYTE 6,3,0
    addi        3,3,FDEC_STRIDE
    REG_STORE_4_BYTE 5,3,0
    addi        3,3,FDEC_STRIDE
    REG_STORE_4_BYTE 4,3,0
    blr
endfunc

function predict_4x4_ddl_altivec
    subi        4,3,FDEC_STRIDE
    vxor        4,4,4
    vspltish    5,1
    LOAD_8_BYTE_H 0,4,0,10
    vmrghb      0,4,0
    vsplth      3,0,7
    vsldoi      1,0,0,2
    vsldoi      2,0,3,4
    vadduhm     0,0,2
    vsrh        0,0,5
    vavguh      0,0,1
    vpkuhum     0,0,4
    mfvrd       4,0
    rotldi      4,4,32
    rotldi      5,4,8
    rotldi      6,4,16
    rotldi      7,4,24
    REG_STORE_4_BYTE 4,3,0
    addi        3,3,FDEC_STRIDE
    REG_STORE_4_BYTE 5,3,0
    addi        3,3,FDEC_STRIDE
    REG_STORE_4_BYTE 6,3,0
    addi        3,3,FDEC_STRIDE
    REG_STORE_4_BYTE 7,3,0
    blr
endfunc

function predict_8x8_dc_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    vxor        2,2,2
    LOAD_16_BYTE 0,4,0
    vspltish    3,8
    addi        4,4,16
    vspltish    4,4
    LOAD_8_BYTE_H 1,4,0,10
    vsldoi      0,0,0,7
    xxmrghd     VSR(0),VSR(0),VSR(1)
    vsum4ubs    0,0,2
    vsumsws     0,0,2
    vsplth      0,0,7
    vadduhm     0,0,3
    vsrh        0,0,4
    vpkuhum     0,0,2
    mfvrd       5,0
    REG_STORE_8_BYTE 5,3,0
.rept 7
    addi        3,3,FDEC_STRIDE
    REG_STORE_8_BYTE 5,3,0
.endr
    blr
endfunc

function predict_8x8_h_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    LOAD_16_BYTE 16,4,0
    vspltb      0,16,14
    vspltb      1,16,13
    STORE_8_BYTE_H 0,3,0,10
    vspltb      2,16,12
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 1,3,0,10
    vspltb      3,16,11
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 2,3,0,10
    vspltb      4,16,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 3,3,0,10
    vspltb      5,16,9
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,10
    vspltb      6,16,8
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    vspltb      7,16,7
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 6,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 7,3,0,10
    blr
endfunc

function predict_8x8_v_ppc64
    ld          5,16(4)
    std         5,0*FDEC_STRIDE(3)
    std         5,1*FDEC_STRIDE(3)
    std         5,2*FDEC_STRIDE(3)
    std         5,3*FDEC_STRIDE(3)
    std         5,4*FDEC_STRIDE(3)
    std         5,5*FDEC_STRIDE(3)
    std         5,6*FDEC_STRIDE(3)
    std         5,7*FDEC_STRIDE(3)
    blr
endfunc

function predict_8x8_ddl_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    addi        4,4,16
    vxor        12,12,12
    vspltish    13,1
    vspltisb    3,0
    LOAD_16_BYTE 0,4,0
    vspltb      2,0,15
    vsldoi      4,3,0,15
    vsldoi      2,0,2,1
    vmrghb      10,12,4
    vmrglb      11,12,4
    vmrghb      8,12,2
    vmrglb      9,12,2
    vadduhm     10,10,8
    vadduhm     11,11,9
    vsrh        10,10,13
    vsrh        11,11,13
    vpkuhum     4,10,11
    vavgub      0,0,4
    vsldoi      1,0,0,1
    vsldoi      2,0,0,2
    STORE_8_BYTE_H 1,3,0,10
    vsldoi      3,0,0,3
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 2,3,0,10
    vsldoi      4,0,0,4
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 3,3,0,10
    vsldoi      5,0,0,5
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,10
    vsldoi      6,0,0,6
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    vsldoi      7,0,0,7
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 6,3,0,10
    vsldoi      0,0,0,8
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 7,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,10
    blr
endfunc

function predict_8x8_ddr_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    LOAD_16_BYTE 0,4,0
    vxor        12,12,12
    addi        4,4,16
    vspltish    13,1
    LOAD_16_BYTE 1,4,0
    vsldoi      2,0,1,7
    vsldoi      4,0,1,9
    vsldoi      3,0,1,8
    vmrghb      8,12,2
    vmrglb      9,12,2
    vmrghb      10,12,4
    vmrglb      11,12,4
    vadduhm     8,8,10
    vadduhm     9,9,11
    vsrh        8,8,13
    vsrh        9,9,13
    vpkuhum     2,8,9
    vavgub      7,3,2
    addi        3,3,7*FDEC_STRIDE
    vsldoi      6,7,7,1
    STORE_8_BYTE_H 7,3,0,10
    vsldoi      5,7,7,2
    addi        3,3,-FDEC_STRIDE
    STORE_8_BYTE_H 6,3,0,10
    vsldoi      4,7,7,3
    addi        3,3,-FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    vsldoi      3,7,7,4
    addi        3,3,-FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,10
    vsldoi      2,7,7,5
    addi        3,3,-FDEC_STRIDE
    STORE_8_BYTE_H 3,3,0,10
    vsldoi      1,7,7,6
    addi        3,3,-FDEC_STRIDE
    STORE_8_BYTE_H 2,3,0,10
    vsldoi      0,7,7,7
    addi        3,3,-FDEC_STRIDE
    STORE_8_BYTE_H 1,3,0,10
    addi        3,3,-FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,10
    blr
endfunc

function predict_8x8_vl_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    addi        4,4,16
    vxor        12,12,12
    vspltish    13,1
    LOAD_16_BYTE 0,4,0
    vsldoi      1,1,0,15
    vsldoi      2,0,2,1
    vmrghb      8,12,1
    vmrglb      9,12,1
    vmrghb      10,12,2
    vmrglb      11,12,2
    vadduhm     8,8,10
    vadduhm     9,9,11
    vsrh        8,8,13
    vsrh        9,9,13
    vpkuhum     1,8,9
    vavgub      3,0,2
    vavgub      0,0,1
    vsldoi      4,0,0,1
    STORE_8_BYTE_H 3,3,0,10
    vsldoi      5,3,3,1
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,10
    vsldoi      6,0,0,2
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    vsldoi      7,3,3,2
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 6,3,0,10
    vsldoi      4,0,0,3
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 7,3,0,10
    vsldoi      5,3,3,3
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,10
    vsldoi      6,0,0,4
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 6,3,0,10
    blr
endfunc

function predict_8x8_vr_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    VEC_LOAD_DATA 14,.even_byte_d_mask,9
    VEC_LOAD_DATA 15,.odd_byte_d_mask,8
    addi        4,4,8
    vxor        12,12,12
    vspltish    13,1
    LOAD_16_BYTE 2,4,0
    vsldoi      1,2,2,14
    vsldoi      0,2,2,15
    vmrghb      8,12,2
    vmrglb      9,12,2
    vmrghb      10,12,1
    vmrglb      11,12,1
    vadduhm     8,8,10
    vadduhm     9,9,11
    vsrh        8,8,13
    vsrh        9,9,13
    vpkuhum     3,8,9
    vavgub      2,2,0
    vavgub      0,0,3
    vsldoi      1,2,2,8
    vperm       2,0,0,14
    vperm       3,0,0,15
    vsldoi      0,0,0,8
    STORE_8_BYTE_H 1,3,0,9
    xxspltd     VSR(2),VSR(2),0
    xxspltd     VSR(3),VSR(3),0
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,10
    vsldoi      4,3,1,15
    vsldoi      5,2,0,15
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,9
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    vsldoi      6,3,1,14
    vsldoi      7,2,0,14
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 6,3,0,9
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 7,3,0,10
    vsldoi      1,3,1,13
    vsldoi      0,2,0,13
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 1,3,0,9
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,10
    blr
endfunc

function predict_8x8_hd_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    addi        4,4,7
    vxor        12,12,12
    vspltish    13,1
    LOAD_16_BYTE 1,4,0
    vsldoi      3,1,1,1
    vsldoi      2,1,1,2
    vavgub      4,1,3
    vmrghb      8,12,1
    vmrglb      9,12,1
    vmrghb      10,12,2
    vmrglb      11,12,2
    vadduhm     8,8,10
    vadduhm     9,9,11
    vsrh        8,8,13
    vsrh        9,9,13
    vpkuhum     1,8,9
    vavgub      0,1,3
    vmrghb      16,4,0
    xxspltd     VSR(17),VSR(16),1
    vsldoi      7,0,0,8
    xxspltd     VSR(16),VSR(16),0
    vsldoi      0,17,7,14
    vsldoi      1,17,7,12
    STORE_8_BYTE_H 0,3,0,10
    vsldoi      2,17,7,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 1,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 2,3,0,10
    vsldoi      3,16,17,14
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 17,3,0,10
    vsldoi      4,16,17,12
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 3,3,0,10
    vsldoi      5,16,17,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 16,3,0,10
    blr
endfunc

function predict_8x8_hu_altivec
    li          10,0
    addi        4,4,7
    lvsl        19,0,10
    vxor        12,12,12
    vspltisb    18,0x07
    vspltish    13,1
    vxor        19,19,18
    LOAD_8_BYTE_H 7,4,0,10
    vspltb      6,7,0
    vperm       7,7,7,19
    xxspltd     VSR(7),VSR(7),0
    vsldoi      4,7,6,10
    vsldoi      2,7,6,9
    vmrghb      8,12,7
    vmrglb      9,12,7
    vmrghb      10,12,4
    vmrglb      11,12,4
    vadduhm     8,8,10
    vadduhm     9,9,11
    vsrh        8,8,13
    vsrh        9,9,13
    vpkuhum     5,8,9
    vavgub      0,2,7
    vavgub      1,5,2
    vmrghb      16,0,1
    xxspltd     VSR(17),VSR(16),1
    xxspltd     VSR(16),VSR(16),0
    vsplth      18,17,3
    vsldoi      0,16,17,10
    vsldoi      1,16,17,12
    vsldoi      2,16,17,14
    STORE_8_BYTE_H 16,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 1,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 2,3,0,10
    vsldoi      4,17,18,10
    vsldoi      5,17,18,12
    vsldoi      6,17,18,14
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 17,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 4,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 5,3,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 6,3,0,10
    blr
endfunc

.macro pred8x8c_dc_end
    addi        4,3,2*FDEC_STRIDE
    addi        5,3,4*FDEC_STRIDE
    addi        6,3,6*FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,9
    STORE_8_BYTE_H 0,4,0,10
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,9
    addi        4,4,FDEC_STRIDE
    STORE_8_BYTE_H 0,4,0,10
    STORE_8_BYTE_H 1,5,0,9
    STORE_8_BYTE_H 1,6,0,10
    addi        5,5,FDEC_STRIDE
    STORE_8_BYTE_H 1,5,0,9
    addi        6,6,FDEC_STRIDE
    STORE_8_BYTE_H 1,6,0,10
    blr
.endm

function predict_8x8c_dc_top_altivec
    vxor        4,4,4
    subi        4,3,FDEC_STRIDE
    vspltish    5,2
    LOAD_8_BYTE_H 0,4,0,10
    vsum4ubs    0,0,4
    vadduhm     0,0,5
    vsrh        0,0,5
    vspltb      3,0,7
    vspltb      2,0,3
    vmrgew      0,2,3
    vmrgow      1,2,3
    pred8x8c_dc_end
endfunc

function predict_8x8c_dc_left_altivec
    lbz         5,0*FDEC_STRIDE-1(3)
    lbz         6,1*FDEC_STRIDE-1(3)
    lbz         7,2*FDEC_STRIDE-1(3)
    lbz         8,3*FDEC_STRIDE-1(3)
    add         5,5,6
    add         7,7,8
    lbz         10,4*FDEC_STRIDE-1(3)
    lbz         9,5*FDEC_STRIDE-1(3)
    lbz         6,6*FDEC_STRIDE-1(3)
    lbz         8,7*FDEC_STRIDE-1(3)
    add         10,10,9
    add         6,6,8
    add         5,5,7
    add         10,10,6
    addi        5,5,2
    addi        10,10,2
    srwi        5,5,2
    srwi        10,10,2
    mtvrwz      0,5
    mtvrwz      1,10
    vspltb      0,0,7
    vspltb      1,1,7
    pred8x8c_dc_end
endfunc

function predict_8x8c_dc_altivec
    VEC_LOAD_DATA 18,.even_byte_d_mask,9
    VEC_LOAD_DATA 19,.odd_byte_d_mask,10
    vxor        4,4,4
    vspltish    5,2
    vspltish    6,3
    vspltish    7,4
    lbz         4,0*FDEC_STRIDE-1(3)
    lbz         5,1*FDEC_STRIDE-1(3)
    lbz         6,2*FDEC_STRIDE-1(3)
    lbz         7,3*FDEC_STRIDE-1(3)
    add         4,4,5
    lbz         8,4*FDEC_STRIDE-1(3)
    lbz         9,5*FDEC_STRIDE-1(3)
    add         6,6,7
    lbz         10,6*FDEC_STRIDE-1(3)
    lbz         5,7*FDEC_STRIDE-1(3)
    add         8,8,9
    add         10,10,5
    slwi        4,4,16
    slwi        8,8,16
    subi        5,3,FDEC_STRIDE
    or          4,4,6
    or          8,8,10
    sldi        4,4,32
    LOAD_8_BYTE_H 0,5,0,9
    or          8,8,4
    mtvrd       1,8
    vsum4ubs    0,0,4
    vsum4shs    3,1,4
    vadduwm     1,0,3
    vmrgow      0,0,3
    vpkuwum     1,1,4
    vpkuwum     0,0,4
    vspltw      1,1,0
    vspltw      0,0,0
    vadduhm     3,1,7
    vadduhm     2,0,5
    vsrh        3,3,6
    vsrh        2,2,5
    vpkuhum     3,3,4
    vpkuhum     2,2,4
    vperm       0,3,2,18
    vperm       1,2,3,19
    pred8x8c_dc_end
endfunc

function predict_8x8c_h_altivec
    li          6,FDEC_STRIDE
.rept 3
    lbz         7,0*FDEC_STRIDE-1(3)
    lbz         8,1*FDEC_STRIDE-1(3)
    mtvrwz      0,7
    mtvrwz      1,8
    vspltb      0,0,7
    vspltb      1,1,7
    STORE_8_BYTE_H 0,3,0,9
    STORE_8_BYTE_H 1,3,6,10
    addi        3,3,2*FDEC_STRIDE
.endr
    lbz         7,0*FDEC_STRIDE-1(3)
    lbz         8,1*FDEC_STRIDE-1(3)
    mtvrwz      0,7
    mtvrwz      1,8
    vspltb      0,0,7
    vspltb      1,1,7
    STORE_8_BYTE_H 0,3,0,9
    STORE_8_BYTE_H 1,3,6,10
    blr
endfunc

function predict_8x8c_v_ppc64
    ld          4,-FDEC_STRIDE(3)
.irp c, 0,1,2,3,4,5,6,7
    std         4,\c*FDEC_STRIDE(3)
.endr
    blr
endfunc

.macro loadsum4 wd,  t1,  t2,  t3,  x,  idx
    lbz         \wd,(\idx+0)*FDEC_STRIDE-1(\x)
    lbz         \t1,(\idx+1)*FDEC_STRIDE-1(\x)
    lbz         \t2,(\idx+2)*FDEC_STRIDE-1(\x)
    lbz         \t3,(\idx+3)*FDEC_STRIDE-1(\x)
    add         \wd,\wd,\t1
    add         \t2,\t2,\t3
    add         \wd,\wd,\t2
.endm

function predict_8x16c_dc_altivec
    subi        10,3,FDEC_STRIDE
    vxor        7,7,7
    LOAD_8_BYTE_H 6,10,0,10
    loadsum4    4,5,6,7,3,0
    vspltish    8,4
    vspltish    9,3
    loadsum4    8,9,10,5,3,4
    vsum4ubs    6,6,7
    mtvrwz      12,4
    mtvrwz      13,8
    vsplth      10,6,1
    vsplth      11,6,3
    loadsum4    4,5,6,7,3,8
    vsplth      12,12,3
    vsplth      13,13,3
    loadsum4    8,9,10,5,3,12
    mtvrwz      14,4
    mtvrwz      15,8
    vsplth      14,14,3
    vsplth      15,15,3
    vsldoi      16,10,11,8
    vsldoi      17,12,11,8
    vsldoi      1,13,11,8
    vsldoi      2,14,11,8
    vsldoi      3,15,11,8
    vadduhm     0,16,17
    vadduhm     1,1,13
    vadduhm     2,2,14
    vadduhm     3,3,15
    vadduhm     0,0,8
    vadduhm     1,1,8
    vadduhm     2,2,8
    vadduhm     3,3,8
    vsrh        0,0,9
    vsrh        1,1,9
    vsrh        2,2,9
    vsrh        3,3,9
    vpkuhum     0,0,7
    vpkuhum     1,1,7
    vpkuhum     2,2,7
    vpkuhum     3,3,7
    li          4,4*FDEC_STRIDE
    li          5,8*FDEC_STRIDE
    li          6,12*FDEC_STRIDE
.rept 3
    STORE_8_BYTE_H 0,3,0,7
    STORE_8_BYTE_H 1,3,4,8
    STORE_8_BYTE_H 2,3,5,9
    STORE_8_BYTE_H 3,3,6,10
    addi        3,3,FDEC_STRIDE
.endr
    STORE_8_BYTE_H 0,3,0,7
    STORE_8_BYTE_H 1,3,4,8
    STORE_8_BYTE_H 2,3,5,9
    STORE_8_BYTE_H 3,3,6,10
    blr
endfunc

function predict_8x16c_dc_left_altivec
    lbz         4,0*FDEC_STRIDE-1(3)
    lbz         5,1*FDEC_STRIDE-1(3)
    lbz         6,2*FDEC_STRIDE-1(3)
    lbz         7,3*FDEC_STRIDE-1(3)
    add         4,4,5
    lbz         8,4*FDEC_STRIDE-1(3)
    add         6,6,7
    lbz         9,5*FDEC_STRIDE-1(3)
    add         4,4,6
    lbz         10,6*FDEC_STRIDE-1(3)
    lbz         5,7*FDEC_STRIDE-1(3)
    addi        4,4,2
    add         8,8,9
    srwi        4,4,2
    add         10,10,5
    mtvrwz      0,4
    lbz         4,8*FDEC_STRIDE-1(3)
    lbz         5,9*FDEC_STRIDE-1(3)
    add         8,8,10
    lbz         6,10*FDEC_STRIDE-1(3)
    lbz         7,11*FDEC_STRIDE-1(3)
    addi        8,8,2
    vspltb      0,0,7
    add         4,4,5
    srwi        8,8,2
    add         6,6,7
    mtvrwz      1,8
    lbz         8,12*FDEC_STRIDE-1(3)
    lbz         9,13*FDEC_STRIDE-1(3)
    add         4,4,6
    lbz         10,14*FDEC_STRIDE-1(3)
    lbz         5,15*FDEC_STRIDE-1(3)
    addi        4,4,2
    vspltb      1,1,7
    add         8,8,9
    srwi        4,4,2
    add         10,10,5
    mtvrwz      2,4
    STORE_8_BYTE_H 0,3,0,6
    add         8,8,10
    addi        3,3,FDEC_STRIDE
    vspltb      2,2,7
    STORE_8_BYTE_H 0,3,0,7
    addi        8,8,2
    addi        3,3,FDEC_STRIDE
    srwi        8,8,2
    STORE_8_BYTE_H 0,3,0,9
    mtvrwz      3,8
    addi        3,3,FDEC_STRIDE
    STORE_8_BYTE_H 0,3,0,10
    vspltb      3,3,7
    addi        3,3,FDEC_STRIDE
    li          4,1*FDEC_STRIDE
    li          5,2*FDEC_STRIDE
    li          6,3*FDEC_STRIDE
.irp  idx, 1, 2
    STORE_8_BYTE_H \idx,3,0,7
    STORE_8_BYTE_H \idx,3,4,8
    STORE_8_BYTE_H \idx,3,5,9
    STORE_8_BYTE_H \idx,3,6,10
    addi        3,3,4*FDEC_STRIDE
.endr
    STORE_8_BYTE_H 3,3,0,7
    STORE_8_BYTE_H 3,3,4,8
    STORE_8_BYTE_H 3,3,5,9
    STORE_8_BYTE_H 3,3,6,10
    blr
endfunc

function predict_8x16c_dc_top_altivec
    li          8,FDEC_STRIDE
    vxor        4,4,4
    subi        4,3,FDEC_STRIDE
    vspltish    5,2
    LOAD_8_BYTE_H 0,4,0,10
    vsum4ubs    0,0,4
    vadduhm     0,0,5
    vsrh        0,0,5
    vspltb      3,0,7
    vspltb      2,0,3
    vsldoi      0,2,3,12
.rept 7
    STORE_8_BYTE_H 0,3,0,9
    STORE_8_BYTE_H 0,3,8,10
    addi        3,3,2*FDEC_STRIDE
.endr
    STORE_8_BYTE_H 0,3,0,9
    STORE_8_BYTE_H 0,3,8,10
    blr
endfunc

function predict_8x16c_h_altivec
    li          4,1*FDEC_STRIDE
    li          5,2*FDEC_STRIDE
    li          6,3*FDEC_STRIDE
.rept 3
    lbz         7,0*FDEC_STRIDE-1(3)
    lbz         8,1*FDEC_STRIDE-1(3)
    lbz         9,2*FDEC_STRIDE-1(3)
    lbz         10,3*FDEC_STRIDE-1(3)
    mtvrwz      0,7
    mtvrwz      1,8
    mtvrwz      2,9
    mtvrwz      3,10
    vspltb      0,0,7
    vspltb      1,1,7
    vspltb      2,2,7
    vspltb      3,3,7
    STORE_8_BYTE_H 0,3,0,7
    STORE_8_BYTE_H 1,3,4,8
    STORE_8_BYTE_H 2,3,5,9
    STORE_8_BYTE_H 3,3,6,10
    addi        3,3,4*FDEC_STRIDE
.endr
    lbz         7,0*FDEC_STRIDE-1(3)
    lbz         8,1*FDEC_STRIDE-1(3)
    lbz         9,2*FDEC_STRIDE-1(3)
    lbz         10,3*FDEC_STRIDE-1(3)
    mtvrwz      0,7
    mtvrwz      1,8
    mtvrwz      2,9
    mtvrwz      3,10
    vspltb      0,0,7
    vspltb      1,1,7
    vspltb      2,2,7
    vspltb      3,3,7
    STORE_8_BYTE_H 0,3,0,7
    STORE_8_BYTE_H 1,3,4,8
    STORE_8_BYTE_H 2,3,5,9
    STORE_8_BYTE_H 3,3,6,10
    blr
endfunc

function predict_8x16c_v_ppc64
    ld          4,-FDEC_STRIDE(3)
.irp c, 0,2,4,6,8,10,12,14
    std         4,\c*FDEC_STRIDE(3)
    std         4,(\c+1)*FDEC_STRIDE(3)
.endr
    blr
endfunc

data_byte_16 .even_byte_d_mask 0x00, 0x02, 0x04, 0x06, 0x10, 0x12, 0x14, 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
data_byte_16 .odd_byte_d_mask  0x01, 0x03, 0x05, 0x07, 0x11, 0x13, 0x15, 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
