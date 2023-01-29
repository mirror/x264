/*****************************************************************************
 * quant.S: ppc quantization and level-run
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

.macro decimate_score_1x size
function decimate_score\size\()_altivec
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    vxor        5,5,5
    LOAD_8_HALFWORD 0,3,0
    addi        3,3,16
    vspltish    6,4
    LOAD_8_HALFWORD 1,3,0
    vspltisb    3,0x01
    vpkshss     0,0,1
    ABS_BYTE    2,0,5
    vcmpequb    4,0,5
    vcmpgtub    3,2,3
    vsrh        4,4,6
    vsrh        3,3,6
    vpkuhum     4,4,5
    vpkuhum     3,3,5
    mfvrd       5,3
    mfvrd       4,4
    cmpldi      5,0
    bne         9f
    not.        4,4
    li          3,0
    beq         0f
.ifc \size, 15
    sldi        4,4,1
.endif
    LOAD_DATA_ADDRESS 7,X264(decimate_table4)
1:
    cntlzd      5,4
    sldi        4,4,4
    srdi        6,5,2
    sld.        4,4,5
    lbzx        8,6,7
    add         3,3,8
    bne         1b
    blr
9:
    li          3,9
0:
    blr
endfunc
.endm

decimate_score_1x 15
decimate_score_1x 16

function decimate_score64_altivec
    li          10,0
    lvsl        11,0,10
    vspltisb    9,0x07
    vxor        11,11,9
    SET_SWAP_HALFWORD_D_MASK 15,18,10
    LOAD_8_HALFWORD 0,3,0
    addi        3,3,16
    vxor        13,13,13
    LOAD_8_HALFWORD 1,3,0
    addi        3,3,16
    VEC_LOAD_DATA 14,.mask64,10
    LOAD_8_HALFWORD 2,3,0
    addi        3,3,16
    vspltish    12,4
    LOAD_8_HALFWORD 3,3,0
    addi        3,3,16
    vspltisb    10,0x01
    LOAD_8_HALFWORD 4,3,0
    addi        3,3,16
    LOAD_8_HALFWORD 5,3,0
    addi        3,3,16
    LOAD_8_HALFWORD 6,3,0
    addi        3,3,16
    LOAD_8_HALFWORD 7,3,0
    vpkshss     16,1,0
    vpkshss     17,3,2
    vpkshss     18,5,4
    vpkshss     19,7,6
    ABS_BYTE    4,16,13
    ABS_BYTE    5,17,13
    ABS_BYTE    6,18,13
    ABS_BYTE    7,19,13
    vcmpequb    0,16,13
    vcmpequb    1,17,13
    vcmpequb    2,18,13
    vcmpequb    3,19,13
    vmaxub      4,4,5
    vmaxub      6,6,7
    vand        0,0,14
    vand        1,1,14
    vand        2,2,14
    vand        3,3,14
    vmaxub      4,4,6
    vsum4ubs    16,0,13
    vsum4ubs    17,1,13
    vsum4ubs    18,2,13
    vsum4ubs    19,3,13
    vcmpgtub    4,4,10
    vpkuwum     17,17,16
    vpkuwum     19,19,18
    vsrh        4,4,12
    vsum4shs    17,17,13
    vsum4shs    19,19,13
    vpkuwum     19,19,17
    vpkuhum     4,4,13
    vpkuhum     0,19,13
    vperm       0,0,0,11
    mfvrd       5,4
    mfvrd       4,0
    cmpldi      5,0
    bne         9f
    not.        4,4
    li          3,0
    beq         0f
    LOAD_DATA_ADDRESS 6,X264(decimate_table8)
1:
    cntlzd      5,4
    lbzx        7,5,6
    sld         4,4,5
    add         3,3,7
    sldi.       4,4,1
    bne         1b
    extsw       3,3
    blr
9:
    li          3,9
0:
    blr
endfunc

#ifndef WORDS_BIGENDIAN
function coeff_last4_ppc64
    ld          5,0(3)
    li          7,3
    cntlzd      6,5
    srwi        6,6,4
    subf        6,6,7
    extsw       3,6
    blr
endfunc

function coeff_last8_ppc64
    ld          6,8(3)
    li          7,7
    cntlzd      5,6
    cmplwi      5,64
    bne         1f
    ld          6,0(3)
    subi        7,7,4
    cntlzd      5,6
1:
    srwi        5,5,4
    subf        5,5,7
    extsw       3,5
    blr
endfunc
#endif

.macro COEFF_LAST_1x size
function coeff_last\size\()_altivec
    li          10,0
    lvsl        17,0,10
    vspltisb    16,0x0F
    vxor        17,17,16
    SET_SWAP_HALFWORD_D_MASK 19,18,10
.if \size == 15
    subi        3,3,2
.endif
    vxor        2,2,2
    vspltish    3,4
    LOAD_8_HALFWORD 0,3,0
    addi        3,3,16
    LOAD_8_HALFWORD 1,3,0
    vpkuhus     0,0,1
    vcmpgtub    0,0,2
    vperm       0,0,0,17
    vsrh        0,0,3
    vpkuhum     0,0,2
    mfvrd       4,0
    li          6,\size - 1
    cntlzd      5,4
    srwi        5,5,2
    subf        5,5,6
    extsw       3,5
    blr
endfunc
.endm

COEFF_LAST_1x 15
COEFF_LAST_1x 16

function coeff_last64_altivec
    vspltisb    15,0x03
    vspltisb    16,0x07
    li          10,0
    lvsl        14,0,10
    vxor        15,15,14
    vxor        16,16,14
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    LOAD_8_HALFWORD 0,3,0
    addi        3,3,16
    vspltish    18,8
    LOAD_8_HALFWORD 1,3,0
    addi        3,3,16
    vspltish    17,1
    LOAD_8_HALFWORD 2,3,0
    addi        3,3,16
    vxor        8,8,8
    LOAD_8_HALFWORD 3,3,0
    addi        3,3,16
    vpkuhus     0,0,1
    LOAD_8_HALFWORD 4,3,0
    addi        3,3,16
    vspltish    9,4
    LOAD_8_HALFWORD 5,3,0
    addi        3,3,16
    vpkuhus     1,2,3
    LOAD_8_HALFWORD 6,3,0
    addi        3,3,16
    vspltisw    10,2
    LOAD_8_HALFWORD 7,3,0
    vpkuhus     2,4,5
    vpkuhus     3,6,7
    vcmpgtub    0,0,8
    vcmpgtub    1,1,8
    vcmpgtub    2,2,8
    vcmpgtub    3,3,8
    vrlh        0,0,18
    vrlh        1,1,18
    vrlh        2,2,18
    vrlh        3,3,18
    vsrh        0,0,9
    vsrh        1,1,9
    vsrh        2,2,9
    vsrh        3,3,9
    vpkuhum     0,0,1
    vpkuhum     1,2,3
    vperm       0,0,0,15
    vperm       1,1,1,15
    vclzw       0,0
    vclzw       1,1
    vsrw        0,0,10
    vsrw        1,1,10
    vpkuwum     0,0,1
    vsubuhm     0,18,0
    vslh        0,17,0
    vsrh        0,0,17
    vpkuhum     0,0,8
    vperm       0,0,0,16
    mfvrd       5,0
    li          6,63
    cntlzd      5,5
    subf        5,5,6
    extsw       3,5
    blr
endfunc

.macro coeff_level_run_start size
    li          10,~15
    addi        6,4,16
    li          7,0
    li          8,0
    li          9,1
    and         6,6,10
    li          10,\size - 1
.endm

.macro coeff_level_run shift
    std         31,-8(1)
    std         30,-16(1)
    std         29,-24(1)
    std         28,-32(1)
    cntlzd      30,5
    srwi        31,30,\shift
    li          28,~((1 << \shift) - 1)
    sub.        10,10,31
    stw         10,0(4)
1:
    sldi        31,10,1
    lhzx        31,31,3
    sth         31,0(6)
    addi        7,7,1
    slw         29,9,10
    addi        6,6,2
    or          8,8,29
    ble         2f
    addi        30,30,1 << \shift
    subi        10,10,1
    and         30,30,28
    sld         5,5,30
    cntlzd      30,5
    srwi        31,30,\shift
    sub.        10,10,31
    bge         1b
2:
    stw         8,4(4)
    extsw       3,7
    ld          31,-8(1)
    ld          30,-16(1)
    ld          29,-24(1)
    ld          28,-32(1)
.endm

#ifndef WORDS_BIGENDIAN
function coeff_level_run4_ppc64
    ld          5,0(3)

    coeff_level_run_start 4

    coeff_level_run 4

    blr
endfunc
#endif

.macro X264_COEFF_LEVEL_RUN size
function coeff_level_run\size\()_altivec
    SET_SWAP_HALFWORD_D_MASK 19,18,10
    vxor        2,2,2
.if \size == 15
    subi        3,3,2
.endif
.if \size < 15
    li          10,0
    lvsl        17,0,10
    vspltisb    16,0x07
    vxor        17,17,16
    LOAD_8_HALFWORD 0,3,0
    vpkuhus     0,0,2
    vcmpgtub    0,0,2
    vperm       0,0,0,17
.else
    li          9,16
    li          10,0
    lvsl        17,0,10
    vspltisb    16,0x0F
    vxor        17,17,16
    LOAD_8_HALFWORD 0,3,0
    vspltish    3,4
    LOAD_8_HALFWORD 1,3,9
    vpkuhus     0,0,1
    vcmpgtub    0,0,2
    vperm       0,0,0,17
    vsrh        0,0,3
    vpkuhum     0,0,2
.endif
    mfvrd       5,0
.if \size == 15
    addi        3,3,2
.endif

    coeff_level_run_start \size

    coeff_level_run (4 - (\size + 1) / 8)

    blr
endfunc
.endm

X264_COEFF_LEVEL_RUN 8
X264_COEFF_LEVEL_RUN 15
X264_COEFF_LEVEL_RUN 16

function denoise_dct_altivec
    SET_SWAP_HALFWORD_D_MASK 9,18,10
    vxor        8,8,8
1:
    li          9,0
    li          10,0
    subic.      6,6,16
    LOAD_8_HALFWORD 0,3,9
    LOAD_4_WORD 4,4,10
    addi        10,10,16
    addi        9,9,16
    LOAD_4_WORD 5,4,10
    addi        10,10,16
    LOAD_8_HALFWORD 1,3,9
    LOAD_4_WORD 6,4,10
    addi        10,10,16
    LOAD_4_WORD 7,4,10
    ABS_HALFWORD 16,0,8
    ABS_HALFWORD 17,1,8
    LOAD_8_HALFWORD 2,5,0
    vmrghh      12,8,16
    vmrglh      13,8,16
    vmrghh      14,8,17
    vmrglh      15,8,17
    addi        5,5,16
    vcmpgtsh    18,8,0
    vcmpgtsh    19,8,1
    LOAD_8_HALFWORD 3,5,0
    vadduwm     4,4,12
    vadduwm     5,5,13
    addi        5,5,16
    vsubuhs     10,16,2
    vsubuhs     11,17,3
    vadduwm     6,6,14
    vadduwm     7,7,15
    vsubuhm     12,8,10
    vsubuhm     13,8,11
    vsel        18,10,12,18
    vsel        19,11,13,19
    STORE_4_WORD 4,4,0
    addi        4,4,16
    STORE_8_HALFWORD 18,3,0
    STORE_4_WORD 5,4,0
    addi        4,4,16
    addi        3,3,16
    STORE_4_WORD 6,4,0
    addi        4,4,16
    STORE_8_HALFWORD 19,3,0
    STORE_4_WORD 7,4,0
    addi        3,3,16
    addi        4,4,16
    bgt         1b
    blr
endfunc

data_byte_16 .mask64 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01, 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
