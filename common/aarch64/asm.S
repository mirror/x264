/*****************************************************************************
 * asm.S: AArch64 utility macros
 *****************************************************************************
 * Copyright (C) 2008-2014 x264 project
 *
 * Authors: Mans Rullgard <mans@mansr.com>
 *          David Conrad <lessen42@gmail.com>
 *          Janne Grunau <janne-x264@jannau.net>
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

#ifdef PREFIX
#   define EXTERN_ASM _
#else
#   define EXTERN_ASM
#endif

#ifdef __ELF__
#   define ELF
#else
#   define ELF  #
#endif

#ifdef __MACH__
#   define MACH
#else
#   define MACH #
#endif

#if HAVE_AS_FUNC
#   define FUNC
#else
#   define FUNC #
#endif

.macro  function name, export=0, align=2
    .macro endfunc
ELF     .size   \name, . - \name
FUNC    .endfunc
        .purgem endfunc
    .endm
        .text
        .align          \align
    .if \export
        .global EXTERN_ASM\name
ELF     .type   EXTERN_ASM\name, %function
FUNC    .func   EXTERN_ASM\name
EXTERN_ASM\name:
    .else
ELF     .type   \name, %function
FUNC    .func   \name
\name:
    .endif
.endm

.macro  const   name, align=2
    .macro endconst
ELF     .size   \name, . - \name
        .purgem endconst
    .endm
ELF     .section        .rodata
MACH    .const_data
        .align          \align
\name:
.endm

.macro  movrel rd, val
#if defined(PIC) && defined(__APPLE__)
        adrp            \rd, \val@PAGE
        add             \rd, \rd, \val@PAGEOFF
#elif defined(PIC)
        adrp            \rd, \val
        add             \rd, \rd, :lo12:\val
#else
        ldr             \rd, =\val
#endif
.endm

#define GLUE(a, b) a ## b
#define JOIN(a, b) GLUE(a, b)
#define X(s) JOIN(EXTERN_ASM, s)
