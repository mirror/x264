/*****************************************************************************
 * pixel-a.S: ppc pixel metrics
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

.macro SSD_4 h, a0
    li          10,\h>>2
    SET_SWAP_BYTE_D_MASK 19,13,9
    vxor        \a0,\a0,\a0
    mtctr       10
1:
    LOAD_4_BYTE_H 0,3,0
    LOAD_4_BYTE_H 2,5,0
    add         3,3,4
    add         5,5,6
    LOAD_4_BYTE_H 1,3,0
    LOAD_4_BYTE_H 3,5,0
    add         3,3,4
    add         5,5,6
    LOAD_4_BYTE_H 4,3,0
    LOAD_4_BYTE_H 6,5,0
    add         3,3,4
    add         5,5,6
    LOAD_4_BYTE_H 5,3,0
    LOAD_4_BYTE_H 7,5,0
    vmrghw      0,0,1
    vmrghw      2,2,3
    vmrghw      4,4,5
    vmrghw      6,6,7
    xxmrghd     VSR(0),VSR(0),VSR(4)
    xxmrghd     VSR(2),VSR(2),VSR(6)
    add         3,3,4
    add         5,5,6
    vmaxub      4,0,2
    vminub      5,0,2
    vsububm     4,4,5
    vmsumubm    \a0,4,4,\a0
    bdnz        1b
.endm

.macro SSD_8 h, a0
    li          10,\h>>2
    vxor        \a0,\a0,\a0
    vxor        12,12,12
    mtctr       10
1:
    LOAD_8_BYTE_H 0,3,0,8
    LOAD_8_BYTE_H 2,5,0,9
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 1,3,0,8
    LOAD_8_BYTE_H 3,5,0,9
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 4,3,0,8
    LOAD_8_BYTE_H 6,5,0,9
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 5,3,0,8
    LOAD_8_BYTE_H 7,5,0,9
    xxmrghd     VSR(0),VSR(0),VSR(1)
    xxmrghd     VSR(2),VSR(2),VSR(3)
    xxmrghd     VSR(4),VSR(4),VSR(5)
    xxmrghd     VSR(6),VSR(6),VSR(7)
    vmaxub      8,0,2
    vminub      9,0,2
    vmaxub      10,4,6
    vminub      11,4,6
    add         3,3,4
    add         5,5,6
    vsububm     8,8,9
    vsububm     10,10,11
    vmsumubm    \a0,8,8,\a0
    vmsumubm    12,10,10,12
    bdnz        1b
    vadduwm     \a0,\a0,12
.endm

.macro SSD_16 h, a0
    li          10,\h>>1
    SET_SWAP_BYTE_D_MASK 19,13,9
    vxor        \a0,\a0,\a0
    vxor        12,12,12
    mtctr       10
1:
    LOAD_16_BYTE 0,3,0
    LOAD_16_BYTE 2,5,0
    add         3,3,4
    add         5,5,6
    LOAD_16_BYTE 1,3,0
    LOAD_16_BYTE 3,5,0
    vmaxub      4,0,2
    vminub      5,0,2
    vmaxub      6,1,3
    vminub      7,1,3
    add         3,3,4
    add         5,5,6
    vsububm     4,4,5
    vsububm     6,6,7
    vmsumubm    \a0,4,4,\a0
    vmsumubm    12,6,6,12
    bdnz        1b
    vadduwm     \a0,\a0,12
.endm

.macro SSD_FUNC w h
function pixel_ssd_\w\()x\h\()_altivec
    vxor        18,18,18
    SSD_\w      \h,17
    vsumsws     17,17,18
    xxspltd     VSR(17),VSR(17),1
    mfvrwz      3,17
    extsw       3,3
    blr
endfunc
.endm

SSD_FUNC   4, 4
SSD_FUNC   4, 8
SSD_FUNC   4, 16
SSD_FUNC   8, 4
SSD_FUNC   8, 8
SSD_FUNC   8, 16
SSD_FUNC  16, 8
SSD_FUNC  16, 16

.macro pixel_ssd_nv12_core_prologue
    std         31,-8(1)
    std         30,-16(1)
.endm

.macro pixel_ssd_nv12_core_epilogue
    ld          31,-8(1)
    ld          30,-16(1)
.endm

function pixel_ssd_nv12_core_altivec
    pixel_ssd_nv12_core_prologue
    SET_SWAP_BYTE_D_MASK 19,17,31
    VEC_LOAD_DATA 18,.even_byte_mask,30
    vxor        12,12,12
    vxor        13,13,13        // { ssd_u_0, ssd_u_1 }
    vxor        14,14,14        // { ssd_v_0, ssd_v_1 }
    vxor        16,16,16
    li          30,0
    li          31,16
    mtctr       8
1:
    subic.      8,7,16
    LOAD_16_BYTE 0,3,30
    LOAD_16_BYTE 1,5,30
    LOAD_16_BYTE 2,3,31
    LOAD_16_BYTE 3,5,31
    vperm       0,0,0,18
    vperm       1,1,1,18
    vperm       2,2,2,18
    vperm       3,3,3,18
    addi        30,30,32
    addi        31,31,32
    vmaxub      4,0,1
    vminub      5,0,1
    vmaxub      6,2,3
    vminub      7,2,3
    vsububm     4,4,5
    vsububm     6,6,7
    vmsumubm    15,4,4,12
    blt         4f
    beq         3f
2:
    vmsumubm    16,6,6,16
    subic.      8,8,16
    LOAD_16_BYTE 0,3,30
    LOAD_16_BYTE 1,5,30
    LOAD_16_BYTE 2,3,31
    LOAD_16_BYTE 3,5,31
    vperm       0,0,0,18
    vperm       1,1,1,18
    addi        30,30,32
    addi        31,31,32
    vmaxub      4,0,1
    vminub      5,0,1
    vsububm     4,4,5
    vmsumubm    15,4,4,15
    blt         4f
    vperm       2,2,2,18
    vperm       3,3,3,18
    vmaxub      6,2,3
    vminub      7,2,3
    vsububm     6,6,7
    bgt         2b
3:
    vmsumubm    16,6,6,16
4:
    vmrgew      8,12,15
    vmrgow      9,12,15
    vmrgew      10,12,16
    vmrgow      11,12,16
    vaddudm     13,13,8
    vaddudm     14,14,9
    vaddudm     13,13,10
    vaddudm     14,14,11
    add         3,3,4
    add         5,5,6
    li          30,0
    li          31,16
    vxor        16,16,16
    bdnz        1b
    xxspltd     VSR(0),VSR(13),1
    xxspltd     VSR(1),VSR(14),1
    vaddudm     2,13,14         // ssd_u_0 + ssd_u_1
    vaddudm     3,0,1           // ssd_v_0 + ssd_v_1
    mfvrd       30,2            // ssd_u
    mfvrd       31,3            // ssd_v
    std         30,0(9)
    std         31,0(10)
    pixel_ssd_nv12_core_epilogue
    blr
endfunc

function pixel_ssim_end4_altivec
    SET_SWAP_BYTE_D_MASK 19,18,9
    li          10,16
    vspltisw    15,6
    vspltisw    16,7
    LOAD_4_WORD 0,3,0
    LOAD_4_WORD 2,4,0
    LOAD_4_WORD 1,3,10
    LOAD_4_WORD 3,4,10
    lis         7,0x03
    li          6,416           // ssim_c1 = .01*.01*255*255*64
    ori         7,7,0x99bb      // ssim_c2 = .03*.03*255*255*64*63
    addi        3,3,32
    addi        4,4,32
    vadduwm     0,0,2
    vadduwm     1,1,3
    vadduwm     0,0,1
    LOAD_4_WORD 4,3,0
    LOAD_4_WORD 6,4,0
    LOAD_4_WORD 5,3,10
    LOAD_4_WORD 7,4,10
    addi        3,3,32
    addi        4,4,32
    vadduwm     4,4,6
    vadduwm     5,5,7
    vadduwm     1,1,4
    LOAD_4_WORD 8,3,0
    LOAD_4_WORD 9,4,0
    mtvrwz      17,6
    mtvrwz      18,7
    vadduwm     8,8,9
    vadduwm     4,4,5
    vadduwm     5,5,8
    addi        3,3,16
    addi        4,4,16
    vspltw      17,17,1
    vspltw      18,18,1
    TRANSPOSE_WORD 2,3,0,1
    TRANSPOSE_WORD 6,7,4,5
    TRANSPOSE_DOUBLEWORD 0,4,2,6
    TRANSPOSE_DOUBLEWORD 1,5,3,7
    vmuluwm     8,0,1
    vmuluwm     0,0,0
    vmuluwm     1,1,1
    vadduwm     0,0,1
    vslw        5,5,16
    vslw        4,4,15
    vadduwm     8,8,8
    vsubuwm     4,4,0
    vsubuwm     5,5,8
    vadduwm     0,0,17
    vadduwm     4,4,18
    vadduwm     8,8,17
    vadduwm     5,5,18
    vcfsx       0,0,0
    vcfsx       2,4,0
    vcfsx       1,8,0
    vcfsx       3,5,0
    xvmulsp     VSR(0),VSR(0),VSR(2)
    xvmulsp     VSR(1),VSR(1),VSR(3)
    xvdivsp     VSR(0),VSR(1),VSR(0)
    cmpwi       5,4
    beq         1f
    slwi        5,5,5
    vspltisw    10,-1
    mtvrwz      11,5
    xxspltd     VSR(11),VSR(11),0
    vsro        10,10,11
    vnot        10,10
    vand        0,0,10
1:
    xxspltd     VSR(1),VSR(0),1
    xvaddsp     VSR(0),VSR(0),VSR(1)
    vsldoi      1,0,0,4
    xvaddsp     1,VSR(0),VSR(1)
    xscvspdpn   1,1
    blr
endfunc

.macro pixel_var2_8 h
function pixel_var2_8x\h\()_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    li          8,16
    vxor        18,18,18
    LOAD_8_BYTE_H 1,4,0,9
    LOAD_8_BYTE_H 2,4,8,10
    LOAD_16_BYTE 0,3,0
    li          6,\h-1
    xxmrghd     VSR(1),VSR(1),VSR(2)
    vmaxub      3,0,1
    vminub      4,0,1
    addi        3,3,16
    addi        4,4,32
    vsububm     3,3,4
    vsum4ubs    15,0,18
    vsum4ubs    16,1,18
    vmsumubm    17,3,3,18
    mtctr       6
1:
    LOAD_8_BYTE_H 1,4,0,9
    LOAD_8_BYTE_H 2,4,8,10
    LOAD_16_BYTE 0,3,0
    xxmrghd     VSR(1),VSR(1),VSR(2)
    vmaxub      3,0,1
    vminub      4,0,1
    vsububm     3,3,4
    vsum4ubs    13,0,18
    vsum4ubs    14,1,18
    addi        3,3,16
    addi        4,4,32
    vmsumubm    17,3,3,17
    vadduwm     15,15,13
    vadduwm     16,16,14
    bdnz        1b
    vmrgew      12,18,17
    vsubuwm     16,15,16
    vadduwm     17,17,12
    vsum2sws    16,16,18
    xxspltd     VSR(15),VSR(17),1
    xxspltd     VSR(14),VSR(16),1
    mfvrwz      6,16
    mfvrwz      7,14
    mullw       6,6,6
    mullw       7,7,7
    mfvrwz      8,17
    mfvrwz      9,15
    sradi       6,6, 6 + (\h >> 4)
    sradi       7,7, 6 + (\h >> 4)
    sub         6,8,6
    sub         7,9,7
    stw         8,0(5)
    add         3,6,7
    stw         9,4(5)
    extsw       3,3
    blr
endfunc
.endm

pixel_var2_8  8
pixel_var2_8 16

function pixel_asd8_altivec
    vxor        18,18,18
    srdi        7,7,1
    subi        7,7,1
    LOAD_8_BYTE_H 0,3,0,9
    LOAD_8_BYTE_H 1,5,0,10
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 2,3,0,9
    LOAD_8_BYTE_H 3,5,0,10
    xxmrghd     VSR(0),VSR(0),VSR(2)
    xxmrghd     VSR(1),VSR(1),VSR(3)
    add         3,3,4
    add         5,5,6
    vsum4ubs    15,0,18
    vsum4ubs    16,1,18
    mtctr       7
1:
    LOAD_8_BYTE_H 0,3,0,9
    LOAD_8_BYTE_H 1,5,0,10
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 2,3,0,9
    LOAD_8_BYTE_H 3,5,0,10
    xxmrghd     VSR(0),VSR(0),VSR(2)
    xxmrghd     VSR(1),VSR(1),VSR(3)
    add         3,3,4
    add         5,5,6
    vsum4ubs    13,0,18
    vsum4ubs    14,1,18
    vadduwm     15,15,13
    vadduwm     16,16,14
    bdnz        1b
    vsubuwm     17,15,16
    xxspltd     VSR(18),VSR(17),1
    vadduwm     17,17,18
    vspltw      18,17,0
    vadduwm     17,17,18
    mfvrwz      8,17
    srawi       9,8,31
    xor         3,9,8
    subf        3,9,3
    extsw       3,3
    blr
endfunc

function pixel_vsad_altivec
    SET_SWAP_BYTE_D_MASK 19,18,10
    vxor        18,18,18
    LOAD_16_BYTE 0,3,0
    add         3,3,4
    subic.      5,5,2
    LOAD_16_BYTE 1,3,0
    vmaxub      2,0,1
    vminub      3,0,1
    add         3,3,4
    vsububm     2,2,3
    vsum4ubs    17,2,18
    ble         2f
1:
    subic.      5,5,2
    LOAD_16_BYTE 0,3,0
    vmaxub      2,1,0
    vminub      3,1,0
    add         3,3,4
    vsububm     2,2,3
    vsum4ubs    17,2,17
    blt         2f
    LOAD_16_BYTE 1,3,0
    vmaxub      2,0,1
    vminub      3,0,1
    add         3,3,4
    vsububm     2,2,3
    vsum4ubs    17,2,17
    bgt         1b
2:
    xxspltd     VSR(18),VSR(17),1
    vadduwm     17,17,18
    vspltw      18,17,0
    vadduwm     17,17,18
    mfvrwz      3,17
    extsw       3,3
    blr
endfunc

.macro load_diff_fly_8x8   zero
    LOAD_8_BYTE_H 0,3,0,9
    LOAD_8_BYTE_H 2,5,0,10
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 1,3,0,9
    LOAD_8_BYTE_H 3,5,0,10
    vmrghb      0,\zero,0
    vmrghb      2,\zero,2
    vmrghb      1,\zero,1
    vmrghb      3,\zero,3
    add         3,3,4
    add         5,5,6
    vsubuhm     0,0,2
    vsubuhm     1,1,3
    LOAD_8_BYTE_H 4,3,0,9
    LOAD_8_BYTE_H 6,5,0,10
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 5,3,0,9
    LOAD_8_BYTE_H 7,5,0,10
    vmrghb      4,\zero,4
    vmrghb      6,\zero,6
    vmrghb      5,\zero,5
    vmrghb      7,\zero,7
    add         3,3,4
    add         5,5,6
    vsubuhm     2,4,6
    vsubuhm     3,5,7
    LOAD_8_BYTE_H 8,3,0,9
    LOAD_8_BYTE_H 10,5,0,10
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 9,3,0,9
    LOAD_8_BYTE_H 11,5,0,10
    vmrghb      8,\zero,8
    vmrghb      10,\zero,10
    vmrghb      9,\zero,9
    vmrghb      11,\zero,11
    add         3,3,4
    add         5,5,6
    vsubuhm     4,8,10
    vsubuhm     5,9,11
    LOAD_8_BYTE_H 12,3,0,9
    LOAD_8_BYTE_H 14,5,0,10
    add         3,3,4
    add         5,5,6
    LOAD_8_BYTE_H 13,3,0,9
    LOAD_8_BYTE_H 15,5,0,10
    vmrghb      12,\zero,12
    vmrghb      14,\zero,14
    vmrghb      13,\zero,13
    vmrghb      15,\zero,15
    add         3,3,4
    add         5,5,6
    vsubuhm     6,12,14
    vsubuhm     7,13,15
    SUMSUB_AB_HALFWORD 8,9,0,1
    SUMSUB_AB_HALFWORD 10,11,2,3
.endm

.macro sa8d_satd_8x8_prologue satd=
.ifc \satd, satd
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
    vxor        25,25,25
.set sa8d_satd_8x8_zero,25
.else
    subi        10,1,16
    stvx        31,0,10
    subi        10,10,16
    stvx        30,0,10
    subi        10,10,16
    stvx        29,0,10
    subi        10,10,16
    stvx        28,0,10
    vxor        18,18,18
.set sa8d_satd_8x8_zero,18
.endif
    VEC_LOAD_DATA 31,.trn_even_halfword_mask,10
    VEC_LOAD_DATA 30,.trn_odd_halfword_mask,9
.endm

.macro sa8d_satd_8x8_epilogue satd=
.ifc \satd, satd
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
.else
    subi        10,1,16
    lvx         31,0,10
    subi        10,10,16
    lvx         30,0,10
    subi        10,10,16
    lvx         29,0,10
    subi        10,10,16
    lvx         28,0,10
.endif
.endm

.macro SUMSUB_ABCD_HALFWORD s1, d1, s2, d2, a, b, c, d
    SUMSUB_AB_HALFWORD \s1, \d1, \a, \b
    SUMSUB_AB_HALFWORD \s2, \d2, \c, \d
.endm

.macro HADAMARD4_V_HALFWORD r1, r2, r3, r4, t1, t2, t3, t4
    SUMSUB_ABCD_HALFWORD \t1, \t2, \t3, \t4, \r1, \r2, \r3, \r4
    SUMSUB_ABCD_HALFWORD \r1, \r3, \r2, \r4, \t1, \t3, \t2, \t4
.endm

.macro sa8d_satd_8x8 satd=
    load_diff_fly_8x8 sa8d_satd_8x8_zero
    SUMSUB_AB_HALFWORD 0,2,8,10
    SUMSUB_AB_HALFWORD 1,3,9,11
    HADAMARD4_V_HALFWORD 4,5,6,7,8,9,10,11
.ifc \satd, satd
    TRANSPOSE_HALFWORD 8,9,0,1,31,30
    TRANSPOSE_HALFWORD 10,11,2,3,31,30
    TRANSPOSE_HALFWORD 12,13,4,5,31,30
    TRANSPOSE_HALFWORD 14,15,6,7,31,30
    SUMSUB_AB_HALFWORD 16,17,8,9
    SUMSUB_AB_HALFWORD 18,19,10,11
    SUMSUB_AB_HALFWORD 8,9,12,13
    SUMSUB_AB_HALFWORD 10,11,14,15
    TRANSPOSE_WORD 12,14,16,18
    TRANSPOSE_WORD 13,15,17,19
    TRANSPOSE_WORD 16,18,8,10
    TRANSPOSE_WORD 17,19,9,11
    ABS_HALFWORD 8,12,sa8d_satd_8x8_zero
    ABS_HALFWORD 9,13,sa8d_satd_8x8_zero
    ABS_HALFWORD 10,14,sa8d_satd_8x8_zero
    ABS_HALFWORD 11,15,sa8d_satd_8x8_zero
    ABS_HALFWORD 12,16,sa8d_satd_8x8_zero
    ABS_HALFWORD 13,17,sa8d_satd_8x8_zero
    ABS_HALFWORD 14,18,sa8d_satd_8x8_zero
    ABS_HALFWORD 15,19,sa8d_satd_8x8_zero
    vmaxuh       8,8,10
    vmaxuh       9,9,11
    vmaxuh       12,12,14
    vmaxuh       13,13,15
    vadduhm      18,8,9
    vadduhm      19,12,13
.endif
    SUMSUB_AB_HALFWORD 8,0,0,4
    SUMSUB_AB_HALFWORD 9,1,1,5
    SUMSUB_AB_HALFWORD 10,2,2,6
    SUMSUB_AB_HALFWORD 11,3,3,7
    TRANSPOSE_HALFWORD 4,5,0,1,31,30
    TRANSPOSE_HALFWORD 12,13,8,9,31,30
    TRANSPOSE_HALFWORD 6,7,2,3,31,30
    TRANSPOSE_HALFWORD 14,15,10,11,31,30
    SUMSUB_AB_HALFWORD 10,11,4,5
    SUMSUB_AB_HALFWORD 16,17,12,13
    SUMSUB_AB_HALFWORD 8,9,6,7
    SUMSUB_AB_HALFWORD 12,13,14,15
    TRANSPOSE_WORD 4,6,10,8
    TRANSPOSE_WORD 5,7,11,9
    TRANSPOSE_WORD 0,2,16,12
    TRANSPOSE_WORD 1,3,17,13
    SUMSUB_AB_HALFWORD 8,10,4,6
    SUMSUB_AB_HALFWORD 9,11,5,7
    SUMSUB_AB_HALFWORD 12,14,0,2
    SUMSUB_AB_HALFWORD 13,15,1,3
    TRANSPOSE_DOUBLEWORD 0,4,8,12
    TRANSPOSE_DOUBLEWORD 1,5,9,13
    TRANSPOSE_DOUBLEWORD 2,6,10,14
    TRANSPOSE_DOUBLEWORD 3,7,11,15
    ABS_HALFWORD 8,0,sa8d_satd_8x8_zero
    ABS_HALFWORD 12,4,sa8d_satd_8x8_zero
    ABS_HALFWORD 9,1,sa8d_satd_8x8_zero
    ABS_HALFWORD 13,5,sa8d_satd_8x8_zero
    ABS_HALFWORD 10,2,sa8d_satd_8x8_zero
    ABS_HALFWORD 14,6,sa8d_satd_8x8_zero
    ABS_HALFWORD 11,3,sa8d_satd_8x8_zero
    ABS_HALFWORD 15,7,sa8d_satd_8x8_zero
    vmaxuh       8,8,12
    vmaxuh       9,9,13
    vmaxuh       10,10,14
    vmaxuh       11,11,15
    vadduhm      16,8,9
    vadduhm      17,10,11
.endm

function pixel_sa8d_8x8_altivec
    sa8d_satd_8x8_prologue
    sa8d_satd_8x8
    vadduhm     16,16,17
    vsum4shs    16,16,sa8d_satd_8x8_zero
    vsumsws     16,16,sa8d_satd_8x8_zero
    xxspltd     VSR(16),VSR(16),1
    mfvrwz      3,16
    addi        3,3,1
    srwi        3,3,1
    sa8d_satd_8x8_epilogue
    blr
endfunc

function pixel_sa8d_16x16_altivec
    sa8d_satd_8x8_prologue
    sa8d_satd_8x8
    vsum4shs    28,16,sa8d_satd_8x8_zero
    vsum4shs    29,17,sa8d_satd_8x8_zero
    sa8d_satd_8x8
    vsum4shs    16,16,sa8d_satd_8x8_zero
    vsum4shs    17,17,sa8d_satd_8x8_zero
    vadduwm     28,28,16
    vadduwm     29,29,17
    sldi        9,4,4
    sldi        10,6,4
    sub         3,3,9
    sub         5,5,10
    addi        3,3,8
    addi        5,5,8
    sa8d_satd_8x8
    vsum4shs    16,16,sa8d_satd_8x8_zero
    vsum4shs    17,17,sa8d_satd_8x8_zero
    vadduwm     28,28,16
    vadduwm     29,29,17
    sa8d_satd_8x8
    vsum4shs    16,16,sa8d_satd_8x8_zero
    vsum4shs    17,17,sa8d_satd_8x8_zero
    vadduwm     28,28,16
    vadduwm     29,29,17
    vadduwm     28,28,29
    vsumsws     28,28,sa8d_satd_8x8_zero
    xxspltd     VSR(28),VSR(28),1
    mfvrwz      3,28
    addi        3,3,1
    srwi        3,3,1
    sa8d_satd_8x8_epilogue
    blr
endfunc

function pixel_sa8d_satd_16x16_altivec
    sa8d_satd_8x8_prologue satd
    sa8d_satd_8x8 satd
    vsum4shs    28,16,sa8d_satd_8x8_zero
    vsum4shs    29,17,sa8d_satd_8x8_zero
    vsum4shs    26,18,sa8d_satd_8x8_zero
    vsum4shs    27,19,sa8d_satd_8x8_zero
    sa8d_satd_8x8 satd
    vsum4shs    16,16,sa8d_satd_8x8_zero
    vsum4shs    17,17,sa8d_satd_8x8_zero
    vsum4shs    18,18,sa8d_satd_8x8_zero
    vsum4shs    19,19,sa8d_satd_8x8_zero
    vadduwm     28,28,16
    vadduwm     29,29,17
    vadduwm     26,26,18
    vadduwm     27,27,19
    sldi        9,4,4
    sldi        10,6,4
    sub         3,3,9
    sub         5,5,10
    addi        3,3,8
    addi        5,5,8
    sa8d_satd_8x8 satd
    vsum4shs    16,16,sa8d_satd_8x8_zero
    vsum4shs    17,17,sa8d_satd_8x8_zero
    vsum4shs    18,18,sa8d_satd_8x8_zero
    vsum4shs    19,19,sa8d_satd_8x8_zero
    vadduwm     28,28,16
    vadduwm     29,29,17
    vadduwm     26,26,18
    vadduwm     27,27,19
    sa8d_satd_8x8 satd
    vsum4shs    16,16,sa8d_satd_8x8_zero
    vsum4shs    17,17,sa8d_satd_8x8_zero
    vsum4shs    18,18,sa8d_satd_8x8_zero
    vsum4shs    19,19,sa8d_satd_8x8_zero
    vadduwm     28,28,16
    vadduwm     29,29,17
    vadduwm     26,26,18
    vadduwm     27,27,19
    vadduwm     28,28,29                 // sa8d
    vadduwm     26,26,27                 // satd
    vsumsws     28,28,sa8d_satd_8x8_zero
    vsumsws     26,26,sa8d_satd_8x8_zero
    vavguw      28,28,sa8d_satd_8x8_zero
    xxspltd     VSR(28),VSR(28),1
    xxspltd     VSR(26),VSR(26),1
    mfvrwz      3,28
    mfvrwz      4,26
    sldi        4,4,32
    or          3,3,4
    sa8d_satd_8x8_epilogue satd
    blr
endfunc

data_byte_16 .even_byte_mask 0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E, 0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F
data_byte_16 .trn_even_halfword_mask 0x00, 0x01, 0x10, 0x11, 0x04, 0x05, 0x14, 0x15, 0x08, 0x09, 0x18, 0x19, 0x0C, 0x0D, 0x1C, 0x1D
data_byte_16 .trn_odd_halfword_mask  0x02, 0x03, 0x12, 0x13, 0x06, 0x07, 0x16, 0x17, 0x0A, 0x0B, 0x1A, 0x1B, 0x0E, 0x0F, 0x1E, 0x1F
