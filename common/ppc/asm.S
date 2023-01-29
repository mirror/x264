/*****************************************************************************
 * asm.S: ppc utility macros
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

#include "config.h"

#define GLUE(a, b) a ## b
#define JOIN(a, b) GLUE(a, b)

#ifdef PREFIX
#   define BASE _x264_
#else
#   define BASE x264_
#endif

#ifdef BIT_DEPTH
#   define EXTERN_ASM JOIN(JOIN(BASE, BIT_DEPTH), _)
#else
#   define EXTERN_ASM BASE
#endif

#define X264(s) JOIN(BASE, s)

.macro function name, align=5
    .macro endfunc
#ifdef WORDS_BIGENDIAN
    .size .EXTERN_ASM\name, .-.EXTERN_ASM\name
    .size EXTERN_ASM\name, .-.EXTERN_ASM\name
#else
    .size EXTERN_ASM\name, .-EXTERN_ASM\name
#endif
    .purgem endfunc
    .endm
.text
.globl    EXTERN_ASM\name
.type     EXTERN_ASM\name,@function
#ifdef WORDS_BIGENDIAN
.section  ".opd","aw"
.align    3
EXTERN_ASM\name:
.quad .EXTERN_ASM\name,.TOC.@tocbase,0
.previous
.align    \align
.EXTERN_ASM\name:
#else
.align    \align
EXTERN_ASM\name:
    addis 2,12,(.TOC.-EXTERN_ASM\name)@ha
    addi  2,2,(.TOC.-EXTERN_ASM\name)@l
.localentry	EXTERN_ASM\name, .-EXTERN_ASM\name
#endif
.endm

.macro data_byte_16  name, v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15
.data
.align    4
\name:
#ifdef WORDS_BIGENDIAN
    .byte \v0,\v1,\v2,\v3,\v4,\v5,\v6,\v7,\v8,\v9,\v10,\v11,\v12,\v13,\v14,\v15
#else
    .byte \v15,\v14,\v13,\v12,\v11,\v10,\v9,\v8,\v7,\v6,\v5,\v4,\v3,\v2,\v1,\v0
#endif
.endm

#define VSR(VR) 32+VR

#define FDEC_STRIDE 32
#define FENC_STRIDE 16

/*
   SWAP_BYTE_D_MASK must be initialized before calling LOAD_16_BYTE, STORE_16_BYTE, LOAD_4_BYTE_H, and STORE_4_BYTE_H
   SWAP_HALFWORD_D_MASK must be initialized before calling LOAD_8_HALFWORD and STOR_8_HALFWORD
*/

/* Initialize SWAP_BYTE_D_MASK
   Source: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
   Result: 7 6 5 4 3 2 1 0 15 14 13 12 11 10 9 8
*/
.macro SET_SWAP_BYTE_D_MASK   VRT,  VR,  GPR
#ifndef WORDS_BIGENDIAN
    li            \GPR,  0x00
    lvsl          \VRT,  0,  \GPR
    vspltisb      \VR,  0x07
    vxor          \VRT,  \VRT,  \VR
.set SWAP_BYTE_D_MASK,  \VRT
#endif
.endm

/* Initialize SWAP_HALFWORD_D_MASK
   Source: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
   Result: 6 7 4 5 2 3 0 1 14 15 12 13 10 11 8 9
*/
.macro SET_SWAP_HALFWORD_D_MASK   VRT,  VR,  GPR
#ifndef WORDS_BIGENDIAN
    li            \GPR,  0x00
    lvsl          \VRT,  0,  \GPR
    vspltisb      \VR,  0x06
    vxor          \VRT,  \VRT,  \VR
.set SWAP_HALFWORD_D_MASK,  \VRT
#endif
.endm

.macro LOAD_16_BYTE   VR, DATA, IDX
    lxvd2x        VSR(\VR),  \IDX,  \DATA
#ifndef WORDS_BIGENDIAN
    vperm         \VR,  \VR,  \VR,  SWAP_BYTE_D_MASK
#endif
.endm

.macro STORE_16_BYTE   VR, DATA, IDX
#ifndef WORDS_BIGENDIAN
    vperm          \VR,  \VR,  \VR,  SWAP_BYTE_D_MASK
#endif
    stxvd2x        VSR(\VR),  \IDX,  \DATA
.endm

.macro LOAD_8_HALFWORD   VR, DATA, IDX
    lxvd2x        VSR(\VR),  \IDX,  \DATA
#ifndef WORDS_BIGENDIAN
    vperm         \VR,  \VR,  \VR,  SWAP_HALFWORD_D_MASK
#endif
.endm

.macro STORE_8_HALFWORD   VR, DATA, IDX
#ifndef WORDS_BIGENDIAN
    vperm          \VR,  \VR,  \VR,  SWAP_HALFWORD_D_MASK
#endif
    stxvd2x        VSR(\VR),  \IDX,  \DATA
.endm

.macro LOAD_4_WORD   VR, DATA, IDX
    lxvw4x        VSR(\VR),  \IDX,  \DATA
.endm

.macro STORE_4_WORD   VR, DATA, IDX
    stxvw4x       VSR(\VR),  \IDX,  \DATA
.endm

.macro LOAD_8_BYTE_H   VR, DATA, IDX, GPR
#ifdef WORDS_BIGENDIAN
    lxsdx             VSR(\VR),  \IDX,  \DATA
#else
    ldbrx             \GPR,  \IDX,  \DATA
    mtvrd             \VR,  \GPR
#endif
.endm

.macro STORE_8_BYTE_H   VR, DATA, IDX, GPR
#ifdef WORDS_BIGENDIAN
    stxsdx            VSR(\VR),  \IDX,  \DATA
#else
    mfvrd             \GPR,  \VR
    stdbrx            \GPR,  \IDX,  \DATA
#endif
.endm

.macro LOAD_4_BYTE_H   VR, DATA, IDX
    lxsiwzx           VSR(\VR),  \IDX,  \DATA
#ifndef WORDS_BIGENDIAN
    vperm             \VR,  \VR,  \VR,  SWAP_BYTE_D_MASK
#else
    vsldoi            \VR,\VR,\VR,4
#endif
.endm

.macro STORE_4_BYTE_H   VR, DATA, IDX
#ifndef WORDS_BIGENDIAN
    vperm             \VR,  \VR,  \VR,  SWAP_BYTE_D_MASK
#else
    vsldoi            \VR,\VR,\VR,12
#endif
    stxsiwx           VSR(\VR),  \IDX,  \DATA
.endm

.macro REG_STORE_8_BYTE   GPR, DATA, IDX
#ifdef WORDS_BIGENDIAN
    stdx              \GPR,  \IDX,  \DATA
#else
    stdbrx            \GPR,  \IDX,  \DATA
#endif
.endm

.macro REG_LOAD_4_BYTE   GPR, DATA, IDX
#ifdef WORDS_BIGENDIAN
    lwzx              \GPR,  \IDX,  \DATA
#else
    lwbrx             \GPR,  \IDX,  \DATA
#endif
.endm

.macro REG_STORE_4_BYTE   GPR, DATA, IDX
#ifdef WORDS_BIGENDIAN
    stwx              \GPR,  \IDX,  \DATA
#else
    stwbrx            \GPR,  \IDX,  \DATA
#endif
.endm

.macro REG_STORE_2_BYTE   GPR, DATA, IDX
#ifdef WORDS_BIGENDIAN
    sthx              \GPR,  \IDX,  \DATA
#else
    sthbrx            \GPR,  \IDX,  \DATA
#endif
.endm

.macro VEC_LOAD_DATA   VR, DATA, GPR
    addis         \GPR,2,\DATA@got@ha
    ld            \GPR,\DATA@got@l(\GPR)
    lvx           \VR,0,\GPR
.endm

.macro LOAD_DATA_ADDRESS   GPR, DATA
    addis         \GPR,2,\DATA@got@ha
    ld            \GPR,\DATA@got@l(\GPR)
.endm

.macro HALFWORD_DATA_SPLAT_BYTE   VR, DATA, IDX, GPR
    lhz               \GPR,  \IDX(\DATA)
    mtvrwz            \VR,  \GPR
    vspltb            \VR,  \VR,  7
.endm

.macro WORD_DATA_SPLAT_BYTE   VR, DATA, IDX, GPR
    lwz               \GPR,  \IDX(\DATA)
    mtvrwz            \VR,  \GPR
    vspltb            \VR,  \VR,  7
.endm

.macro WORD_DATA_SPLAT_HALFWORD   VR, DATA, IDX, GPR
    lwz               \GPR,  \IDX(\DATA)
    mtvrwz            \VR,  \GPR
    vsplth            \VR,  \VR,  3
.endm

.macro TRANSPOSE_HALFWORD t1, t2, s1, s2, m1, m2
    vperm       \t1,  \s1,  \s2,  \m1
    vperm       \t2,  \s1,  \s2,  \m2
.endm

.macro TRANSPOSE_WORD t1, t2, s1, s2
    vmrgew      \t1,  \s1,  \s2
    vmrgow      \t2,  \s1,  \s2
.endm

.macro TRANSPOSE_DOUBLEWORD t1, t2, s1, s2
    xxmrghd     VSR(\t1),  VSR(\s1),  VSR(\s2)
    xxmrgld     VSR(\t2),  VSR(\s1),  VSR(\s2)
.endm

.macro TRANSPOSE_4x4_H v0, v1, v2, v3, t0, t1, t2, t3, m0, m1
    TRANSPOSE_WORD       \t0,  \t2,  \v0,  \v2
    TRANSPOSE_WORD       \t1,  \t3,  \v1,  \v3
    TRANSPOSE_HALFWORD   \v0,  \v1,  \t0,  \t1,  \m0,  \m1
    TRANSPOSE_HALFWORD   \v2,  \v3,  \t2,  \t3,  \m0,  \m1
.endm

.macro TRANSPOSE_4x8_H v0, v1, v2, v3, t0, t1, t2, t3, m0, m1
    TRANSPOSE_WORD       \t0,  \t2,  \v0,  \v2
    TRANSPOSE_WORD       \t1,  \t3,  \v1,  \v3
    TRANSPOSE_HALFWORD   \v0,  \v1,  \t0,  \t1,  \m0,  \m1
    TRANSPOSE_HALFWORD   \v2,  \v3,  \t2,  \t3,  \m0,  \m1
.endm

.macro SUMSUB_AB_HALFWORD sum, sub, a, b
    vadduhm    \sum,  \a,  \b
    vsubuhm    \sub,  \a,  \b
.endm

.macro ABS_HALFWORD a, b, zero
    vsubuhm     \a, \zero, \b
    vmaxsh      \a, \b, \a
.endm

.macro ABS_BYTE a, b, zero
    vsububm     \a, \zero, \b
    vmaxsb      \a, \b, \a
.endm
