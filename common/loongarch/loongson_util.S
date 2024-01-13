/*****************************************************************************
 * loongson_util.S: loongson utility macros
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Shiyou Yin <yinshiyou-hf@loongson.cn>
 *          Xiwei Gu <guxiwei-hf@loongson.cn>
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

#define GLUE(a, b) a ## b
#define JOIN(a, b) GLUE(a, b)

/* Set prefix as needed. */
#define  ASM_REF  JOIN(JOIN(x264_, BIT_DEPTH), _)

#define FENC_STRIDE      16
#define FDEC_STRIDE      32

.macro function_x264 name, align=DEFAULT_ALIGN
.macro endfunc_x264
    jirl    $r0, $r1, 0x0
    .size ASM_REF\name, . - ASM_REF\name
    .purgem endfunc_x264
.endm
.text ;
.align \align ;
.globl ASM_REF\name ;
.type  ASM_REF\name, @function ;
ASM_REF\name: ;
.endm
