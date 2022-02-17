/*****************************************************************************
 * mc-c.c: loongarch motion compensation
 *****************************************************************************
 * Copyright (C) 2015-2018 x264 project
 * Copyright (C) 2020 Loongson Technology Corporation Limited
 *
 * Authors: zhou peng <zhoupeng@loongson.cn>
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

#include "common/common.h"
#include "loongson_intrinsics.h"
#include "mc.h"

#if !HIGH_BIT_DEPTH

static const uint8_t pu_luma_mask_arr[16 * 6] =
{
    0, 5, 1, 6, 2, 7, 3, 8, 4, 9, 5, 10, 6, 11, 7, 12,
    0, 5, 1, 6, 2, 7, 3, 8, 4, 9, 5, 10, 6, 11, 7, 12,
    1, 4, 2, 5, 3, 6, 4, 7, 5, 8, 6, 9, 7, 10, 8, 11,
    1, 4, 2, 5, 3, 6, 4, 7, 5, 8, 6, 9, 7, 10, 8, 11,
    2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10,
    2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10
};

static const uint8_t pu_chroma_mask_arr[16 * 2] =
{
    0, 2, 2, 4, 4, 6, 6, 8, 16, 18, 18, 20, 20, 22, 22, 24,
    0, 2, 2, 4, 4, 6, 6, 8, 16, 18, 18, 20, 20, 22, 22, 24
};

static const uint8_t pu_chroma_mask_arr1[16 * 2] =
{
    0, 2, 2, 4, 4, 6, 6, 8, 8, 10, 10, 12, 12, 14, 14, 16,
    0, 2, 2, 4, 4, 6, 6, 8, 8, 10, 10, 12, 12, 14, 14, 16
};

static const uint8_t pu_core_mask_arr[16 * 2] =
{
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
};

static void mc_weight_w20_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                                const x264_weight_t *weight, int height )
{
    int i_denom = weight->i_denom, i_scale = weight->i_scale, i_offset = weight->i_offset;
    int zero = 0, i_4 = 4, src_stride2, src_stride3, src_stride4;

    i_offset <<= i_denom;


    __asm__ volatile(
    "slli.d           %[src_stride2],   %[src_stride],        1                      \n\t"
    "add.d            %[src_stride3],   %[src_stride2],       %[src_stride]          \n\t"
    "slli.d           %[src_stride4],   %[src_stride2],       1                      \n\t"
    "xvreplgr2vr.h    $xr2,             %[i_denom]                                   \n\t"
    "xvreplgr2vr.b    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "xvld             $xr3,             %[src],               0                      \n\t"
    "xvldx            $xr4,             %[src],               %[src_stride]          \n\t"
    "xvldx            $xr5,             %[src],               %[src_stride2]         \n\t"
    "xvldx            $xr6,             %[src],               %[src_stride3]         \n\t"
    "xvmulwev.h.bu.b  $xr7,             $xr3,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr8,             $xr4,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr9,             $xr5,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr10,            $xr6,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr4,             $xr4,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr5,             $xr5,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr6,             $xr6,                 $xr0                   \n\t"
    "xvsadd.h         $xr7,             $xr7,                 $xr1                   \n\t"
    "xvsadd.h         $xr8,             $xr8,                 $xr1                   \n\t"
    "xvsadd.h         $xr9,             $xr9,                 $xr1                   \n\t"
    "xvsadd.h         $xr10,            $xr10,                $xr1                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvsadd.h         $xr5,             $xr5,                 $xr1                   \n\t"
    "xvsadd.h         $xr6,             $xr6,                 $xr1                   \n\t"
    "xvmaxi.h         $xr7,             $xr7,                 0                      \n\t"
    "xvmaxi.h         $xr8,             $xr8,                 0                      \n\t"
    "xvmaxi.h         $xr9,             $xr9,                 0                      \n\t"
    "xvmaxi.h         $xr10,            $xr10,                0                      \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvmaxi.h         $xr5,             $xr5,                 0                      \n\t"
    "xvmaxi.h         $xr6,             $xr6,                 0                      \n\t"
    "xvssrlrn.bu.h    $xr7,             $xr7,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr8,             $xr8,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr9,             $xr9,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr10,            $xr10,                $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr3,             $xr3,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr4,             $xr4,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr5,             $xr5,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr6,             $xr6,                 $xr2                   \n\t"
    "xvilvl.b         $xr3,             $xr3,                 $xr7                   \n\t"
    "xvilvl.b         $xr4,             $xr4,                 $xr8                   \n\t"
    "xvilvl.b         $xr5,             $xr5,                 $xr9                   \n\t"
    "xvilvl.b         $xr6,             $xr6,                 $xr10                  \n\t"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr3,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr4,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr4,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr5,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr5,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr6,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr6,             %[dst],               16,          4         \n\t"
    "add.d            %[src],           %[src],               %[src_stride4]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "xvld             $xr3,             %[src],               0                      \n\t"
    "xvldx            $xr4,             %[src],               %[src_stride]          \n\t"
    "xvmulwev.h.bu.b  $xr7,             $xr3,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr8,             $xr4,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr4,             $xr4,                 $xr0                   \n\t"
    "xvsadd.h         $xr7,             $xr7,                 $xr1                   \n\t"
    "xvsadd.h         $xr8,             $xr8,                 $xr1                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvmaxi.h         $xr7,             $xr7,                 0                      \n\t"
    "xvmaxi.h         $xr8,             $xr8,                 0                      \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvssrlrn.bu.h    $xr7,             $xr7,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr8,             $xr8,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr3,             $xr3,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr4,             $xr4,                 $xr2                   \n\t"
    "xvilvl.b         $xr3,             $xr3,                 $xr7                   \n\t"
    "xvilvl.b         $xr4,             $xr4,                 $xr8                   \n\t"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr3,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr4,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr4,             %[dst],               16,          4         \n\t"
    "add.d            %[src],           %[src],               %[src_stride2]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2),
      [src_stride3]"=&r"(src_stride3), [src_stride4]"=&r"(src_stride4)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride), [i_4]"r"(i_4),
      [zero]"r"(zero), [i_denom]"r"(i_denom), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale)
    : "memory"
    );
}

static void mc_weight_w16_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                                const x264_weight_t *weight, int height )
{
    int i_denom = weight->i_denom, i_scale = weight->i_scale, i_offset = weight->i_offset, i_4 = 4;
    int zero = 0, src_stride2, src_stride3, src_stride4, dst_stride2, dst_stride3, dst_stride4;

    i_offset <<= i_denom;

    __asm__ volatile(
    "slli.d           %[src_stride2],   %[src_stride],        1                      \n\t"
    "add.d            %[src_stride3],   %[src_stride2],       %[src_stride]          \n\t"
    "slli.d           %[src_stride4],   %[src_stride2],       1                      \n\t"
    "slli.d           %[dst_stride2],   %[dst_stride],        1                      \n\t"
    "add.d            %[dst_stride3],   %[dst_stride2],       %[dst_stride]          \n\t"
    "slli.d           %[dst_stride4],   %[dst_stride2],       1                      \n\t"
    "xvreplgr2vr.h    $xr2,             %[i_denom]                                   \n\t"
    "xvreplgr2vr.h    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vldx             $vr5,             %[src],               %[src_stride2]         \n\t"
    "vldx             $vr6,             %[src],               %[src_stride3]         \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "vext2xv.hu.bu    $xr4,             $xr4                                         \n\t"
    "vext2xv.hu.bu    $xr5,             $xr5                                         \n\t"
    "vext2xv.hu.bu    $xr6,             $xr6                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmul.h          $xr4,             $xr4,                 $xr0                   \n\t"
    "xvmul.h          $xr5,             $xr5,                 $xr0                   \n\t"
    "xvmul.h          $xr6,             $xr6,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvsadd.h         $xr5,             $xr5,                 $xr1                   \n\t"
    "xvsadd.h         $xr6,             $xr6,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvmaxi.h         $xr5,             $xr5,                 0                      \n\t"
    "xvmaxi.h         $xr6,             $xr6,                 0                      \n\t"
    "xvssrlrn.bu.h    $xr3,             $xr3,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr4,             $xr4,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr5,             $xr5,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr6,             $xr6,                 $xr2                   \n\t"
    "xvpermi.d        $xr3,             $xr3,                 8                      \n\n"
    "xvpermi.d        $xr4,             $xr4,                 8                      \n\n"
    "xvpermi.d        $xr5,             $xr5,                 8                      \n\n"
    "xvpermi.d        $xr6,             $xr6,                 8                      \n\n"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "vstx             $vr4,             %[dst],               %[dst_stride]          \n\t"
    "vstx             $vr5,             %[dst],               %[dst_stride2]         \n\t"
    "vstx             $vr6,             %[dst],               %[dst_stride3]         \n\t"
    "add.d            %[src],           %[src],               %[src_stride4]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride4]         \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "vext2xv.hu.bu    $xr4,             $xr4                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmul.h          $xr4,             $xr4,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvssrlrn.bu.h    $xr3,             $xr3,                 $xr2                   \n\t"
    "xvssrlrn.bu.h    $xr4,             $xr4,                 $xr2                   \n\t"
    "xvpermi.d        $xr3,             $xr3,                 8                      \n\n"
    "xvpermi.d        $xr4,             $xr4,                 8                      \n\n"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "vstx             $vr4,             %[dst],               %[dst_stride]          \n\t"
    "add.d            %[src],           %[src],               %[src_stride2]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride2]         \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2),
      [src_stride3]"=&r"(src_stride3), [src_stride4]"=&r"(src_stride4), [dst_stride2]"=&r"(dst_stride2),
      [dst_stride3]"=&r"(dst_stride3), [dst_stride4]"=&r"(dst_stride4)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride), [i_4]"r"(i_4),
      [zero]"r"(zero), [i_denom]"r"(i_denom), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale)
    : "memory"
    );
}

static void mc_weight_w8_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                               const x264_weight_t *weight, int height )
{
    int i_4 = 4;
    int i_denom = weight->i_denom, i_scale = weight->i_scale, i_offset = weight->i_offset;
    int zero = 0, src_stride2, src_stride3, src_stride4;

    i_offset <<= i_denom;
    i_offset += (1 << ( i_denom -1 ));

    __asm__ volatile(
    "slli.d           %[src_stride2],   %[src_stride],        1                      \n\t"
    "add.d            %[src_stride3],   %[src_stride2],       %[src_stride]          \n\t"
    "slli.d           %[src_stride4],   %[src_stride2],       1                      \n\t"
    "xvreplgr2vr.h    $xr2,             %[i_denom]                                   \n\t"
    "xvreplgr2vr.h    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vldx             $vr5,             %[src],               %[src_stride2]         \n\t"
    "vldx             $vr6,             %[src],               %[src_stride3]         \n\t"
    "add.d            %[src],           %[src],               %[src_stride4]         \n\t"
    "vilvl.d          $vr3,             $vr4,                 $vr3                   \n\t"
    "vilvl.d          $vr4,             $vr6,                 $vr5                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "vext2xv.hu.bu    $xr4,             $xr4                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmul.h          $xr4,             $xr4,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvssrln.bu.h     $xr3,             $xr3,                 $xr2                   \n\t"
    "xvssrln.bu.h     $xr4,             $xr4,                 $xr2                   \n\t"
    "xvstelm.d        $xr3,             %[dst],               0,            0        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr3,             %[dst],               0,            2        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr4,             %[dst],               0,            0        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr4,             %[dst],               0,            2        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vilvl.d          $vr3,             $vr4,                 $vr3                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvssrln.bu.h     $xr3,             $xr3,                 $xr2                   \n\t"
    "xvstelm.d        $xr3,             %[dst],               0,           0         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr3,             %[dst],               0,           2         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "add.d            %[src],           %[src],               %[src_stride2]         \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2),
      [src_stride3]"=&r"(src_stride3), [src_stride4]"=&r"(src_stride4)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride), [i_4]"r"(i_4),
      [zero]"r"(zero), [i_denom]"r"(i_denom), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale)
    : "memory"
    );
}

static void mc_weight_w4_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                               const x264_weight_t *weight, int height )
{
    int i_denom = weight->i_denom, i_scale = weight->i_scale, i_offset = weight->i_offset;
    int zero = 0, i_4 = 4;

    i_offset <<= i_denom;
    i_offset += (1 << ( i_denom -1 ));

    __asm__ volatile(
    "xvreplgr2vr.h    $xr2,             %[i_denom]                                   \n\t"
    "xvreplgr2vr.h    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "vldrepl.w        $vr3,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr4,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr5,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr6,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vilvl.w          $vr3,             $vr4,                 $vr3                   \n\t"
    "vilvl.w          $vr4,             $vr6,                 $vr5                   \n\t"
    "vilvl.d          $vr3,             $vr4,                 $vr3                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvssrln.bu.h     $xr3,             $xr3,                 $xr2                   \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           0         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           1         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           5         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "vldrepl.w        $vr3,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr4,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vilvl.w          $vr3,             $vr4,                 $vr3                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvssrln.bu.h     $xr3,             $xr3,                 $xr2                   \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           0         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           1         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride), [i_4]"r"(i_4),
      [zero]"r"(zero), [i_denom]"r"(i_denom), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale)
    : "memory"
    );
}

static void mc_weight_w4_noden_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                                     const x264_weight_t *weight, int height )
{
    int i_scale = weight->i_scale, i_offset = weight->i_offset;
    int zero = 0, i_4 = 4;

    __asm__ volatile(
    "xvreplgr2vr.h    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "vldrepl.w        $vr3,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr4,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr5,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr6,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vilvl.w          $vr3,             $vr4,                 $vr3                   \n\t"
    "vilvl.w          $vr4,             $vr6,                 $vr5                   \n\t"
    "vilvl.d          $vr3,             $vr4,                 $vr3                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvssrlni.bu.h    $xr3,             $xr3,                 0                      \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           0         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           1         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           5         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "vldrepl.w        $vr3,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vldrepl.w        $vr4,             %[src],               0                      \n\t"
    "add.d            %[src],           %[src],               %[src_stride]          \n\t"
    "vilvl.w          $vr3,             $vr4,                 $vr3                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvssrlni.bu.h    $xr3,             $xr3,                 0                      \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           0         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.w        $xr3,             %[dst],               0,           1         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride),
      [zero]"r"(zero), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale), [i_4]"r"(i_4)
    : "memory"
    );
}

static void mc_weight_w8_noden_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                                     const x264_weight_t *weight, int height )
{
    int i_4 = 4;
    int i_scale = weight->i_scale, i_offset = weight->i_offset;
    int zero = 0, src_stride2, src_stride3, src_stride4;

    __asm__ volatile(
    "slli.d           %[src_stride2],   %[src_stride],        1                      \n\t"
    "add.d            %[src_stride3],   %[src_stride2],       %[src_stride]          \n\t"
    "slli.d           %[src_stride4],   %[src_stride2],       1                      \n\t"
    "xvreplgr2vr.h    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vldx             $vr5,             %[src],               %[src_stride2]         \n\t"
    "vldx             $vr6,             %[src],               %[src_stride3]         \n\t"
    "add.d            %[src],           %[src],               %[src_stride4]         \n\t"
    "vilvl.d          $vr3,             $vr4,                 $vr3                   \n\t"
    "vilvl.d          $vr4,             $vr6,                 $vr5                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "vext2xv.hu.bu    $xr4,             $xr4                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmul.h          $xr4,             $xr4,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvssrlni.bu.h    $xr4,             $xr3,                 0                      \n\t"
    "xvstelm.d        $xr4,             %[dst],               0,            0        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr4,             %[dst],               0,            2        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr4,             %[dst],               0,            1        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr4,             %[dst],               0,            3        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vilvl.d          $vr3,             $vr4,                 $vr3                   \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvssrlni.bu.h    $xr3,             $xr3,                 0                      \n\t"
    "xvstelm.d        $xr3,             %[dst],               0,            0        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "xvstelm.d        $xr3,             %[dst],               0,            2        \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "add.d            %[src],           %[src],               %[src_stride2]         \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2),
      [src_stride3]"=&r"(src_stride3), [src_stride4]"=&r"(src_stride4)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride),
      [zero]"r"(zero), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale), [i_4]"r"(i_4)
    : "memory"
    );
}

static void mc_weight_w16_noden_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                                      const x264_weight_t *weight, int height )
{
    int i_4 = 4;
    int i_scale = weight->i_scale, i_offset = weight->i_offset;
    int zero = 0, src_stride2, src_stride3, src_stride4, dst_stride2, dst_stride3, dst_stride4;

    __asm__ volatile(
    "slli.d           %[src_stride2],   %[src_stride],        1                      \n\t"
    "add.d            %[src_stride3],   %[src_stride2],       %[src_stride]          \n\t"
    "slli.d           %[src_stride4],   %[src_stride2],       1                      \n\t"
    "slli.d           %[dst_stride2],   %[dst_stride],        1                      \n\t"
    "add.d            %[dst_stride3],   %[dst_stride2],       %[dst_stride]          \n\t"
    "slli.d           %[dst_stride4],   %[dst_stride2],       1                      \n\t"
    "xvreplgr2vr.h    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vldx             $vr5,             %[src],               %[src_stride2]         \n\t"
    "vldx             $vr6,             %[src],               %[src_stride3]         \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "vext2xv.hu.bu    $xr4,             $xr4                                         \n\t"
    "vext2xv.hu.bu    $xr5,             $xr5                                         \n\t"
    "vext2xv.hu.bu    $xr6,             $xr6                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmul.h          $xr4,             $xr4,                 $xr0                   \n\t"
    "xvmul.h          $xr5,             $xr5,                 $xr0                   \n\t"
    "xvmul.h          $xr6,             $xr6,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvsadd.h         $xr5,             $xr5,                 $xr1                   \n\t"
    "xvsadd.h         $xr6,             $xr6,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvmaxi.h         $xr5,             $xr5,                 0                      \n\t"
    "xvmaxi.h         $xr6,             $xr6,                 0                      \n\t"
    "xvssrlni.bu.h    $xr4,             $xr3,                 0                      \n\t"
    "xvssrlni.bu.h    $xr6,             $xr5,                 0                      \n\t"
    "xvpermi.d        $xr3,             $xr4,                 8                      \n\t"
    "xvpermi.d        $xr4,             $xr4,                 13                     \n\t"
    "xvpermi.d        $xr5,             $xr6,                 8                      \n\t"
    "xvpermi.d        $xr6,             $xr6,                 13                     \n\t"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "vstx             $vr4,             %[dst],               %[dst_stride]          \n\t"
    "vstx             $vr5,             %[dst],               %[dst_stride2]         \n\t"
    "vstx             $vr6,             %[dst],               %[dst_stride3]         \n\t"
    "add.d            %[src],           %[src],               %[src_stride4]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride4]         \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "vld              $vr3,             %[src],               0                      \n\t"
    "vldx             $vr4,             %[src],               %[src_stride]          \n\t"
    "vext2xv.hu.bu    $xr3,             $xr3                                         \n\t"
    "vext2xv.hu.bu    $xr4,             $xr4                                         \n\t"
    "xvmul.h          $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmul.h          $xr4,             $xr4,                 $xr0                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvssrlni.bu.h    $xr4,             $xr3,                 0                      \n\t"
    "xvpermi.d        $xr3,             $xr4,                 8                      \n\t"
    "xvpermi.d        $xr4,             $xr4,                 13                     \n\t"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "vstx             $vr4,             %[dst],               %[dst_stride]          \n\t"
    "add.d            %[src],           %[src],               %[src_stride2]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride2]         \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2),
      [src_stride3]"=&r"(src_stride3), [src_stride4]"=&r"(src_stride4), [dst_stride2]"=&r"(dst_stride2),
      [dst_stride3]"=&r"(dst_stride3), [dst_stride4]"=&r"(dst_stride4)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride),
      [zero]"r"(zero), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale), [i_4]"r"(i_4)
    : "memory"
    );
}

static void mc_weight_w20_noden_lasx( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride,
                                      const x264_weight_t *weight, int height )
{
    int i_scale = weight->i_scale, i_offset = weight->i_offset;
    int zero = 0, i_4 = 4, src_stride2, src_stride3, src_stride4;

    __asm__ volatile(
    "slli.d           %[src_stride2],   %[src_stride],        1                      \n\t"
    "add.d            %[src_stride3],   %[src_stride2],       %[src_stride]          \n\t"
    "slli.d           %[src_stride4],   %[src_stride2],       1                      \n\t"
    "xvreplgr2vr.b    $xr0,             %[i_scale]                                   \n\t"
    "xvreplgr2vr.h    $xr1,             %[i_offset]                                  \n\t"
    "1:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -4                     \n\t"
    "xvld             $xr3,             %[src],               0                      \n\t"
    "xvldx            $xr4,             %[src],               %[src_stride]          \n\t"
    "xvldx            $xr5,             %[src],               %[src_stride2]         \n\t"
    "xvldx            $xr6,             %[src],               %[src_stride3]         \n\t"
    "xvmulwev.h.bu.b  $xr7,             $xr3,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr8,             $xr4,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr9,             $xr5,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr10,            $xr6,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr4,             $xr4,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr5,             $xr5,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr6,             $xr6,                 $xr0                   \n\t"
    "xvsadd.h         $xr7,             $xr7,                 $xr1                   \n\t"
    "xvsadd.h         $xr8,             $xr8,                 $xr1                   \n\t"
    "xvsadd.h         $xr9,             $xr9,                 $xr1                   \n\t"
    "xvsadd.h         $xr10,            $xr10,                $xr1                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvsadd.h         $xr5,             $xr5,                 $xr1                   \n\t"
    "xvsadd.h         $xr6,             $xr6,                 $xr1                   \n\t"
    "xvmaxi.h         $xr7,             $xr7,                 0                      \n\t"
    "xvmaxi.h         $xr8,             $xr8,                 0                      \n\t"
    "xvmaxi.h         $xr9,             $xr9,                 0                      \n\t"
    "xvmaxi.h         $xr10,            $xr10,                0                      \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvmaxi.h         $xr5,             $xr5,                 0                      \n\t"
    "xvmaxi.h         $xr6,             $xr6,                 0                      \n\t"
    "xvssrlni.bu.h    $xr8,             $xr7,                 0                      \n\t"
    "xvssrlni.bu.h    $xr10,            $xr9,                 0                      \n\t"
    "xvssrlni.bu.h    $xr4,             $xr3,                 0                      \n\t"
    "xvssrlni.bu.h    $xr6,             $xr5,                 0                      \n\t"
    "xvilvl.b         $xr3,             $xr4,                 $xr8                   \n\t"
    "xvilvh.b         $xr4,             $xr4,                 $xr8                   \n\t"
    "xvilvl.b         $xr5,             $xr6,                 $xr10                  \n\t"
    "xvilvh.b         $xr6,             $xr6,                 $xr10                  \n\t"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr3,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr4,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr4,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr5,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr5,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr6,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr6,             %[dst],               16,          4         \n\t"
    "add.d            %[src],           %[src],               %[src_stride4]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "bge              %[height],        %[i_4],               1b                     \n\t"
    "beqz             %[height],        3f                                           \n\t"
    "2:                                                                              \n\t"
    "addi.d           %[height],        %[height],            -2                     \n\t"
    "xvld             $xr3,             %[src],               0                      \n\t"
    "xvldx            $xr4,             %[src],               %[src_stride]          \n\t"
    "xvmulwev.h.bu.b  $xr7,             $xr3,                 $xr0                   \n\t"
    "xvmulwev.h.bu.b  $xr8,             $xr4,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr3,             $xr3,                 $xr0                   \n\t"
    "xvmulwod.h.bu.b  $xr4,             $xr4,                 $xr0                   \n\t"
    "xvsadd.h         $xr7,             $xr7,                 $xr1                   \n\t"
    "xvsadd.h         $xr8,             $xr8,                 $xr1                   \n\t"
    "xvsadd.h         $xr3,             $xr3,                 $xr1                   \n\t"
    "xvsadd.h         $xr4,             $xr4,                 $xr1                   \n\t"
    "xvmaxi.h         $xr7,             $xr7,                 0                      \n\t"
    "xvmaxi.h         $xr8,             $xr8,                 0                      \n\t"
    "xvmaxi.h         $xr3,             $xr3,                 0                      \n\t"
    "xvmaxi.h         $xr4,             $xr4,                 0                      \n\t"
    "xvssrlni.bu.h    $xr8,             $xr7,                 0                      \n\t"
    "xvssrlni.bu.h    $xr4,             $xr3,                 0                      \n\t"
    "xvilvl.b         $xr3,             $xr4,                 $xr8                   \n\t"
    "xvilvh.b         $xr4,             $xr4,                 $xr8                   \n\t"
    "vst              $vr3,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr3,             %[dst],               16,          4         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "vst              $vr4,             %[dst],               0                      \n\t"
    "xvstelm.w        $xr4,             %[dst],               16,          4         \n\t"
    "add.d            %[src],           %[src],               %[src_stride2]         \n\t"
    "add.d            %[dst],           %[dst],               %[dst_stride]          \n\t"
    "blt              %[zero],          %[height],            2b                     \n\t"
    "3:                                                                              \n\t"
    : [height]"+&r"(height), [src]"+&r"(src), [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2),
      [src_stride3]"=&r"(src_stride3), [src_stride4]"=&r"(src_stride4)
    : [dst_stride]"r"((int64_t) dst_stride), [src_stride]"r"((int64_t) src_stride),
      [zero]"r"(zero), [i_4]"r"(i_4), [i_offset]"r"(i_offset), [i_scale]"r"(i_scale)
    : "memory"
    );
}

#define MC_WEIGHT(func)                                                                                             \
static void (* mc##func##_wtab_lasx[6])( uint8_t *, intptr_t, uint8_t *, intptr_t, const x264_weight_t *, int ) =   \
{                                                                                                                   \
    mc_weight_w4##func##_lasx,                                                                                 \
    mc_weight_w4##func##_lasx,                                                                                 \
    mc_weight_w8##func##_lasx,                                                                                 \
    mc_weight_w16##func##_lasx,                                                                                \
    mc_weight_w16##func##_lasx,                                                                                \
    mc_weight_w20##func##_lasx,                                                                                \
};

#if !HIGH_BIT_DEPTH
MC_WEIGHT()
MC_WEIGHT(_noden)
#endif

static void weight_cache_lasx( x264_t *h, x264_weight_t *w )
{
    if ( w->i_denom >= 1)
    {
        w->weightfn = mc_wtab_lasx;
    }
    else
        w->weightfn = mc_noden_wtab_lasx;
}

static weight_fn_t mc_weight_wtab_lasx[6] =
{
    mc_weight_w4_lasx,
    mc_weight_w4_lasx,
    mc_weight_w8_lasx,
    mc_weight_w16_lasx,
    mc_weight_w16_lasx,
    mc_weight_w20_lasx,
};

static void avc_biwgt_opscale_4x2_nw_lasx( uint8_t *p_src1,
                                           int32_t i_src1_stride,
                                           uint8_t *p_src2,
                                           int32_t i_src2_stride,
                                           uint8_t *p_dst, int32_t i_dst_stride,
                                           int32_t i_log2_denom,
                                           int32_t i_src1_weight,
                                           int32_t i_src2_weight )
{
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2;
    __m256i denom;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

    src0 = __lasx_xvldrepl_w( p_src1, 0 );
    p_src1 += i_src1_stride;
    src1 = __lasx_xvldrepl_w( p_src1, 0 );
    src2 = __lasx_xvpackev_w( src1, src0 );

    src0 = __lasx_xvldrepl_w( p_src2, 0 );
    p_src2 += i_src2_stride;
    src1 = __lasx_xvldrepl_w( p_src2, 0 );
    src0 = __lasx_xvpackev_w( src1, src0 );

    src0 = __lasx_xvilvl_b( src0, src2 );

    src0 = __lasx_xvdp2_h_bu( src0, wgt );
    src0 = __lasx_xvmaxi_h( src0, 0 );
    src0 = __lasx_xvssrln_bu_h(src0, denom);

    __lasx_xvstelm_w(src0, p_dst, 0, 0);
    __lasx_xvstelm_w(src0, p_dst + i_dst_stride, 0, 1);
}

static void avc_biwgt_opscale_4x4multiple_nw_lasx( uint8_t *p_src1,
                                                   int32_t i_src1_stride,
                                                   uint8_t *p_src2,
                                                   int32_t i_src2_stride,
                                                   uint8_t *p_dst,
                                                   int32_t i_dst_stride,
                                                   int32_t i_height,
                                                   int32_t i_log2_denom,
                                                   int32_t i_src1_weight,
                                                   int32_t i_src2_weight )
{
    uint8_t u_cnt;
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2, src3, tmp0;
    __m256i denom;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_dst_stride_x4 = i_dst_stride << 2;
    int32_t i_dst_stride_x3 = i_dst_stride_x2 + i_dst_stride;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

    for( u_cnt = ( i_height >> 2 ); u_cnt--; )
    {
        src0 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src1 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src2 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src3 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src0 = __lasx_xvpackev_w( src1, src0 );
        src1 = __lasx_xvpackev_w( src3, src2 );
        tmp0 = __lasx_xvpermi_q( src0, src1, 0x02 );

        src0 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src1 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src2 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src3 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src0 = __lasx_xvpackev_w( src1, src0 );
        src1 = __lasx_xvpackev_w( src3, src2 );
        src0 = __lasx_xvpermi_q( src0, src1, 0x02 );

        src0 = __lasx_xvilvl_b( src0, tmp0 );

        src0 = __lasx_xvdp2_h_bu( src0, wgt );
        src0 = __lasx_xvmaxi_h( src0, 0 );
        src0 = __lasx_xvssrln_bu_h(src0, denom);

        __lasx_xvstelm_w(src0, p_dst, 0, 0);
        __lasx_xvstelm_w(src0, p_dst + i_dst_stride, 0, 1);
        __lasx_xvstelm_w(src0, p_dst + i_dst_stride_x2, 0, 4);
        __lasx_xvstelm_w(src0, p_dst + i_dst_stride_x3, 0, 5);
        p_dst += i_dst_stride_x4;
    }
}

static void avc_biwgt_opscale_4width_nw_lasx( uint8_t *p_src1,
                                              int32_t i_src1_stride,
                                              uint8_t *p_src2,
                                              int32_t i_src2_stride,
                                              uint8_t *p_dst,
                                              int32_t i_dst_stride,
                                              int32_t i_height,
                                              int32_t i_log2_denom,
                                              int32_t i_src1_weight,
                                              int32_t i_src2_weight )
{
    if( 2 == i_height )
    {
        avc_biwgt_opscale_4x2_nw_lasx( p_src1, i_src1_stride,
                                       p_src2, i_src2_stride,
                                       p_dst, i_dst_stride,
                                       i_log2_denom, i_src1_weight,
                                       i_src2_weight );
    }
    else
    {
        avc_biwgt_opscale_4x4multiple_nw_lasx( p_src1, i_src1_stride,
                                               p_src2, i_src2_stride,
                                               p_dst, i_dst_stride,
                                               i_height, i_log2_denom,
                                               i_src1_weight,
                                               i_src2_weight );
    }
}

static void avc_biwgt_opscale_8width_nw_lasx( uint8_t *p_src1,
                                              int32_t i_src1_stride,
                                              uint8_t *p_src2,
                                              int32_t i_src2_stride,
                                              uint8_t *p_dst,
                                              int32_t i_dst_stride,
                                              int32_t i_height,
                                              int32_t i_log2_denom,
                                              int32_t i_src1_weight,
                                              int32_t i_src2_weight )
{
    uint8_t u_cnt;
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2, src3;
    __m256i denom;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

#define BIWGT_OPSCALE_8W_NW                              \
    src0 = __lasx_xvldrepl_d( p_src1, 0 );               \
    p_src1 += i_src1_stride;                             \
    src1 = __lasx_xvldrepl_d( p_src1, 0 );               \
    p_src1 += i_src1_stride;                             \
                                                         \
    src2 = __lasx_xvldrepl_d( p_src2, 0 );               \
    p_src2 += i_src2_stride;                             \
    src3 = __lasx_xvldrepl_d( p_src2, 0 );               \
    p_src2 += i_src2_stride;                             \
                                                         \
    src0 = __lasx_xvpermi_q( src0, src1, 0x02 );         \
    src1 = __lasx_xvpermi_q( src2, src3, 0x02 );         \
    src0 = __lasx_xvilvl_b( src1, src0 );                \
                                                         \
    src0 = __lasx_xvdp2_h_bu( src0, wgt );               \
    src0 = __lasx_xvmaxi_h( src0, 0 );                   \
    src0 = __lasx_xvssrln_bu_h(src0, denom);             \
                                                         \
    __lasx_xvstelm_d(src0, p_dst, 0, 0);                 \
    __lasx_xvstelm_d(src0, p_dst + i_dst_stride, 0, 2);  \
    p_dst += i_dst_stride_x2;                            \

    for( u_cnt = ( i_height >> 2 ); u_cnt--; )
    {
        BIWGT_OPSCALE_8W_NW;
        BIWGT_OPSCALE_8W_NW;
    }

#undef BIWGT_OPSCALE_8W_NW

}
static void avc_biwgt_opscale_16width_nw_lasx( uint8_t *p_src1,
                                               int32_t i_src1_stride,
                                               uint8_t *p_src2,
                                               int32_t i_src2_stride,
                                               uint8_t *p_dst,
                                               int32_t i_dst_stride,
                                               int32_t i_height,
                                               int32_t i_log2_denom,
                                               int32_t i_src1_weight,
                                               int32_t i_src2_weight )
{
    uint8_t u_cnt;
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i denom;
    int32_t i_src1_stride_x2 = i_src1_stride << 1;
    int32_t i_src1_stride_x4 = i_src1_stride << 2;
    int32_t i_src2_stride_x2 = i_src2_stride << 1;
    int32_t i_src2_stride_x4 = i_src2_stride << 2;
    int32_t i_src1_stride_x3 = i_src1_stride_x2 + i_src1_stride;
    int32_t i_src2_stride_x3 = i_src2_stride_x2 + i_src2_stride;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

#define BIWGT_OPSCALE_16W_NW( srcA, srcB )       \
    srcA = __lasx_xvpermi_d( srcA, 0x50 );       \
    srcB = __lasx_xvpermi_d( srcB, 0x50 );       \
    srcA = __lasx_xvilvl_b( srcB, srcA );        \
                                                 \
    srcA = __lasx_xvdp2_h_b( srcA, wgt );        \
    srcA = __lasx_xvmaxi_h( srcA, 0 );           \
    srcA = __lasx_xvssrln_bu_h(srcA, denom);     \
                                                 \
    __lasx_xvstelm_d(srcA, p_dst, 0, 0);         \
    __lasx_xvstelm_d(srcA, p_dst + 8, 0, 2);     \
    p_dst += i_dst_stride;

    for( u_cnt = ( i_height >> 2 ); u_cnt--; )
    {
        DUP4_ARG2( __lasx_xvldx, p_src1, 0, p_src1, i_src1_stride, p_src1,
                   i_src1_stride_x2, p_src1, i_src1_stride_x3, src0, src1, src2, src3 );
        p_src1 += i_src1_stride_x4;

        DUP4_ARG2( __lasx_xvldx, p_src2, 0, p_src2, i_src2_stride, p_src2,
                   i_src2_stride_x2, p_src2, i_src2_stride_x3, src4, src5, src6, src7 );
        p_src2 += i_src2_stride_x4;

        BIWGT_OPSCALE_16W_NW( src0, src4 );
        BIWGT_OPSCALE_16W_NW( src1, src5 );
        BIWGT_OPSCALE_16W_NW( src2, src6 );
        BIWGT_OPSCALE_16W_NW( src3, src7 );
    }

#undef BIWGT_OPSCALE_16W_NW

}

static void avc_biwgt_opscale_4x2_lasx( uint8_t *p_src1,
                                        int32_t i_src1_stride,
                                        uint8_t *p_src2,
                                        int32_t i_src2_stride,
                                        uint8_t *p_dst, int32_t i_dst_stride,
                                        int32_t i_log2_denom,
                                        int32_t i_src1_weight,
                                        int32_t i_src2_weight,
                                        int32_t i_offset_in )
{
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2;
    __m256i denom, offset;

    i_offset_in = ( ( i_offset_in + 1 ) | 1 ) << i_log2_denom;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );
    offset = __lasx_xvreplgr2vr_h( i_offset_in );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

    src0 = __lasx_xvldrepl_w( p_src1, 0 );
    p_src1 += i_src1_stride;
    src1 = __lasx_xvldrepl_w( p_src1, 0 );
    src2 = __lasx_xvpackev_w( src1, src0 );

    src0 = __lasx_xvldrepl_w( p_src2, 0 );
    p_src2 += i_src2_stride;
    src1 = __lasx_xvldrepl_w( p_src2, 0 );
    src0 = __lasx_xvpackev_w( src1, src0 );

    src0 = __lasx_xvilvl_b( src0, src2 );

    src0 = __lasx_xvdp2_h_bu( src0, wgt );
    src0 = __lasx_xvsadd_h( src0, offset );
    src0 = __lasx_xvmaxi_h( src0, 0 );
    src0 = __lasx_xvssrln_bu_h(src0, denom);

    __lasx_xvstelm_w(src0, p_dst, 0, 0);
    __lasx_xvstelm_w(src0, p_dst + i_dst_stride, 0, 1);
}

static void avc_biwgt_opscale_4x4multiple_lasx( uint8_t *p_src1,
                                                int32_t i_src1_stride,
                                                uint8_t *p_src2,
                                                int32_t i_src2_stride,
                                                uint8_t *p_dst,
                                                int32_t i_dst_stride,
                                                int32_t i_height,
                                                int32_t i_log2_denom,
                                                int32_t i_src1_weight,
                                                int32_t i_src2_weight,
                                                int32_t i_offset_in )
{
    uint8_t u_cnt;
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2, src3, tmp0;
    __m256i denom, offset;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_dst_stride_x4 = i_dst_stride << 2;
    int32_t i_dst_stride_x3 = i_dst_stride_x2 + i_dst_stride;

    i_offset_in = ( ( i_offset_in + 1 ) | 1 ) << i_log2_denom;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );
    offset = __lasx_xvreplgr2vr_h( i_offset_in );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

    for( u_cnt = ( i_height >> 2 ); u_cnt--; )
    {
        src0 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src1 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src2 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src3 = __lasx_xvldrepl_w( p_src1, 0 );
        p_src1 += i_src1_stride;
        src0 = __lasx_xvpackev_w( src1, src0 );
        src1 = __lasx_xvpackev_w( src3, src2 );
        tmp0 = __lasx_xvpermi_q( src0, src1, 0x02 );

        src0 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src1 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src2 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src3 = __lasx_xvldrepl_w( p_src2, 0 );
        p_src2 += i_src2_stride;
        src0 = __lasx_xvpackev_w( src1, src0 );
        src1 = __lasx_xvpackev_w( src3, src2 );
        src0 = __lasx_xvpermi_q( src0, src1, 0x02 );

        src0 = __lasx_xvilvl_b( src0, tmp0 );

        src0 = __lasx_xvdp2_h_bu( src0, wgt );
        src0 = __lasx_xvsadd_h( src0, offset );
        src0 = __lasx_xvmaxi_h( src0, 0 );
        src0 = __lasx_xvssrln_bu_h(src0, denom);

        __lasx_xvstelm_w(src0, p_dst, 0, 0);
        __lasx_xvstelm_w(src0, p_dst + i_dst_stride, 0, 1);
        __lasx_xvstelm_w(src0, p_dst + i_dst_stride_x2, 0, 4);
        __lasx_xvstelm_w(src0, p_dst + i_dst_stride_x3, 0, 5);
        p_dst += i_dst_stride_x4;
    }
}

static void avc_biwgt_opscale_4width_lasx( uint8_t *p_src1,
                                           int32_t i_src1_stride,
                                           uint8_t *p_src2,
                                           int32_t i_src2_stride,
                                           uint8_t *p_dst,
                                           int32_t i_dst_stride,
                                           int32_t i_height,
                                           int32_t i_log2_denom,
                                           int32_t i_src1_weight,
                                           int32_t i_src2_weight,
                                           int32_t i_offset_in )
{
    if( 2 == i_height )
    {
        avc_biwgt_opscale_4x2_lasx( p_src1, i_src1_stride,
                                    p_src2, i_src2_stride,
                                    p_dst, i_dst_stride,
                                    i_log2_denom, i_src1_weight,
                                    i_src2_weight, i_offset_in );
    }
    else
    {
        avc_biwgt_opscale_4x4multiple_lasx( p_src1, i_src1_stride,
                                            p_src2, i_src2_stride,
                                            p_dst, i_dst_stride,
                                            i_height, i_log2_denom,
                                            i_src1_weight,
                                            i_src2_weight, i_offset_in );
    }
}

static void avc_biwgt_opscale_8width_lasx( uint8_t *p_src1,
                                           int32_t i_src1_stride,
                                           uint8_t *p_src2,
                                           int32_t i_src2_stride,
                                           uint8_t *p_dst,
                                           int32_t i_dst_stride,
                                           int32_t i_height,
                                           int32_t i_log2_denom,
                                           int32_t i_src1_weight,
                                           int32_t i_src2_weight,
                                           int32_t i_offset_in )
{
    uint8_t u_cnt;
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2, src3;
    __m256i denom, offset;
    int32_t i_dst_stride_x2 = ( i_dst_stride << 1 );

    i_offset_in = ( ( i_offset_in + 1 ) | 1 ) << i_log2_denom;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );
    offset = __lasx_xvreplgr2vr_h( i_offset_in );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

#define BIWGT_OPSCALE_8W                                 \
    src0 = __lasx_xvldrepl_d( p_src1, 0 );               \
    p_src1 += i_src1_stride;                             \
    src1 = __lasx_xvldrepl_d( p_src1, 0 );               \
    p_src1 += i_src1_stride;                             \
                                                         \
    src2 = __lasx_xvldrepl_d( p_src2, 0 );               \
    p_src2 += i_src2_stride;                             \
    src3 = __lasx_xvldrepl_d( p_src2, 0 );               \
    p_src2 += i_src2_stride;                             \
                                                         \
    src0 = __lasx_xvpermi_q( src0, src1, 0x02 );         \
    src1 = __lasx_xvpermi_q( src2, src3, 0x02 );         \
    src0 = __lasx_xvilvl_b( src1, src0 );                \
                                                         \
    src0 = __lasx_xvdp2_h_bu( src0, wgt );               \
    src0 = __lasx_xvsadd_h( src0, offset );              \
    src0 = __lasx_xvmaxi_h( src0, 0 );                   \
    src0 = __lasx_xvssrln_bu_h(src0, denom);             \
                                                         \
    __lasx_xvstelm_d(src0, p_dst, 0, 0);                 \
    __lasx_xvstelm_d(src0, p_dst + i_dst_stride, 0, 2);  \
    p_dst += i_dst_stride_x2;

    for( u_cnt = ( i_height >> 2 ); u_cnt--; )
    {
        BIWGT_OPSCALE_8W;
        BIWGT_OPSCALE_8W;
    }

#undef BIWGT_OPSCALE_8W

}

static void avc_biwgt_opscale_16width_lasx( uint8_t *p_src1,
                                            int32_t i_src1_stride,
                                            uint8_t *p_src2,
                                            int32_t i_src2_stride,
                                            uint8_t *p_dst,
                                            int32_t i_dst_stride,
                                            int32_t i_height,
                                            int32_t i_log2_denom,
                                            int32_t i_src1_weight,
                                            int32_t i_src2_weight,
                                            int32_t i_offset_in )
{
    uint8_t u_cnt;
    __m256i src1_wgt, src2_wgt, wgt;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i denom, offset;
    int32_t i_src1_stride_x2 = i_src1_stride << 1;
    int32_t i_src1_stride_x4 = i_src1_stride << 2;
    int32_t i_src2_stride_x2 = i_src2_stride << 1;
    int32_t i_src2_stride_x4 = i_src2_stride << 2;
    int32_t i_src1_stride_x3 = i_src1_stride_x2 + i_src1_stride;
    int32_t i_src2_stride_x3 = i_src2_stride_x2 + i_src2_stride;

    i_offset_in = ( ( i_offset_in + 1 ) | 1 ) << i_log2_denom;

    src1_wgt = __lasx_xvreplgr2vr_b( i_src1_weight );
    src2_wgt = __lasx_xvreplgr2vr_b( i_src2_weight );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom + 1 );
    offset = __lasx_xvreplgr2vr_h( i_offset_in );

    wgt = __lasx_xvpackev_b( src2_wgt, src1_wgt );

#define BIWGT_OPSCALE_16W( srcA, srcB )          \
    srcA = __lasx_xvpermi_d( srcA, 0x50 );       \
    srcB = __lasx_xvpermi_d( srcB, 0x50 );       \
    srcA = __lasx_xvilvl_b( srcB, srcA );        \
                                                 \
    srcA = __lasx_xvdp2_h_bu( srcA, wgt );       \
    srcA = __lasx_xvsadd_h( srcA, offset );      \
    srcA = __lasx_xvmaxi_h( srcA, 0 );           \
    srcA = __lasx_xvssrln_bu_h(srcA, denom);     \
                                                 \
    __lasx_xvstelm_d(srcA, p_dst, 0, 0);         \
    __lasx_xvstelm_d(srcA, p_dst + 8, 0, 2);     \
    p_dst += i_dst_stride;

    for( u_cnt = ( i_height >> 2 ); u_cnt--; )
    {
        DUP4_ARG2( __lasx_xvldx, p_src1, 0, p_src1, i_src1_stride, p_src1,
                   i_src1_stride_x2, p_src1, i_src1_stride_x3, src0, src1, src2, src3 );
        p_src1 += i_src1_stride_x4;

        DUP4_ARG2( __lasx_xvldx, p_src2, 0, p_src2, i_src2_stride, p_src2,
                   i_src2_stride_x2, p_src2, i_src2_stride_x3, src4, src5, src6, src7 );
        p_src2 += i_src2_stride_x4;

        BIWGT_OPSCALE_16W( src0, src4 );
        BIWGT_OPSCALE_16W( src1, src5 );
        BIWGT_OPSCALE_16W( src2, src6 );
        BIWGT_OPSCALE_16W( src3, src7 );
    }

#undef BIWGT_OPSCALE_16W

}

static void avg_src_width4_lasx( uint8_t *p_src1, int32_t i_src1_stride,
                                 uint8_t *p_src2, int32_t i_src2_stride,
                                 uint8_t *p_dst, int32_t i_dst_stride,
                                 int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1;
    __m256i dst0, dst1;
    int32_t i_src1_stride_x2 = i_src1_stride << 1;
    int32_t i_src2_stride_x2 = i_src2_stride << 1;

    for( i_cnt = ( i_height >> 1 ); i_cnt--; )
    {
        DUP2_ARG2(__lasx_xvldx, p_src1, 0, p_src1, i_src1_stride, src0, src1);
        p_src1 += i_src1_stride_x2;
        DUP2_ARG2(__lasx_xvldx, p_src2, 0, p_src2, i_src2_stride, dst0, dst1);
        p_src2 += i_src2_stride_x2;

        DUP2_ARG2( __lasx_xvavgr_bu, src0, dst0, src1, dst1, dst0, dst1 );
        __lasx_xvstelm_w( dst0, p_dst, 0, 0 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_w( dst1, p_dst, 0, 0 );
        p_dst += i_dst_stride;
    }
}

static void avg_src_width8_lasx( uint8_t *p_src1, int32_t i_src1_stride,
                                 uint8_t *p_src2, int32_t i_src2_stride,
                                 uint8_t *p_dst, int32_t i_dst_stride,
                                 int32_t i_height )
{
    int32_t i_cnt = i_height >> 2;
    int32_t i_src1_stride_x2, i_src1_stride_x3, i_src1_stride_x4;
    int32_t i_src2_stride_x2, i_src2_stride_x3, i_src2_stride_x4;

    __asm__ volatile(
    "slli.w    %[src1_stride2],  %[src1_stride1],  1                    \n\t"
    "add.w     %[src1_stride3],  %[src1_stride2],  %[src1_stride1]      \n\t"
    "slli.w    %[src1_stride4],  %[src1_stride1],  2                    \n\t"
    "slli.w    %[src2_stride2],  %[src2_stride1],  1                    \n\t"
    "add.w     %[src2_stride3],  %[src2_stride2],  %[src2_stride1]      \n\t"
    "slli.w    %[src2_stride4],  %[src2_stride1],  2                    \n\t"
    "beqz      %[cnt],           2f                                     \n\t"
    "1:                                                                 \n\t"
    "addi.w    %[cnt],           %[cnt],           -1                   \n\t"
    "vld       $vr0,             %[src1],          0                    \n\t"
    "vldx      $vr1,             %[src1],          %[src1_stride1]      \n\t"
    "vldx      $vr2,             %[src1],          %[src1_stride2]      \n\t"
    "vldx      $vr3,             %[src1],          %[src1_stride3]      \n\t"
    "vld       $vr4,             %[src2],          0                    \n\t"
    "vldx      $vr5,             %[src2],          %[src2_stride1]      \n\t"
    "vldx      $vr6,             %[src2],          %[src2_stride2]      \n\t"
    "vldx      $vr7,             %[src2],          %[src2_stride3]      \n\t"
    "vavgr.bu  $vr0,             $vr0,             $vr4                 \n\t"
    "vavgr.bu  $vr1,             $vr1,             $vr5                 \n\t"
    "vavgr.bu  $vr2,             $vr2,             $vr6                 \n\t"
    "vavgr.bu  $vr3,             $vr3,             $vr7                 \n\t"
    "vstelm.d  $vr0,             %[dst],           0,              0    \n\t"
    "add.d     %[dst],           %[dst],           %[dst_stride1]       \n\t"
    "vstelm.d  $vr1,             %[dst],           0,              0    \n\t"
    "add.d     %[dst],           %[dst],           %[dst_stride1]       \n\t"
    "vstelm.d  $vr2,             %[dst],           0,              0    \n\t"
    "add.d     %[dst],           %[dst],           %[dst_stride1]       \n\t"
    "vstelm.d  $vr3,             %[dst],           0,              0    \n\t"
    "add.d     %[dst],           %[dst],           %[dst_stride1]       \n\t"
    "add.d     %[src1],          %[src1],          %[src1_stride4]      \n\t"
    "add.d     %[src2],          %[src2],          %[src2_stride4]      \n\t"
    "bnez      %[cnt],           1b                                     \n\t"
    "2:                                                                 \n\t"
     : [src1]"+&r"(p_src1),
       [src2]"+&r"(p_src2),
       [src1_stride2]"=&r"(i_src1_stride_x2),
       [src1_stride3]"=&r"(i_src1_stride_x3),
       [src1_stride4]"=&r"(i_src1_stride_x4),
       [src2_stride2]"=&r"(i_src2_stride_x2),
       [src2_stride3]"=&r"(i_src2_stride_x3),
       [src2_stride4]"=&r"(i_src2_stride_x4),
       [dst]"+&r"(p_dst), [cnt]"+&r"(i_cnt)
     : [src1_stride1]"r"(i_src1_stride),
       [src2_stride1]"r"(i_src2_stride),
       [dst_stride1]"r"(i_dst_stride)
     : "memory"
    );
}

static void avg_src_width16_lasx( uint8_t *p_src1, int32_t i_src1_stride,
                                  uint8_t *p_src2, int32_t i_src2_stride,
                                  uint8_t *p_dst, int32_t i_dst_stride,
                                  int32_t i_height )
{
    int32_t i_cnt = i_height >> 3;
    int32_t i_src1_stride_x2, i_src1_stride_x3, i_src1_stride_x4;
    int32_t i_src2_stride_x2, i_src2_stride_x3, i_src2_stride_x4;
    int32_t i_dst_stride_x2, i_dst_stride_x3, i_dst_stride_x4;

    __asm__ volatile(
    "slli.w    %[src1_stride2],  %[src1_stride1],  1                    \n\t"
    "add.w     %[src1_stride3],  %[src1_stride2],  %[src1_stride1]      \n\t"
    "slli.w    %[src1_stride4],  %[src1_stride1],  2                    \n\t"
    "slli.w    %[src2_stride2],  %[src2_stride1],  1                    \n\t"
    "add.w     %[src2_stride3],  %[src2_stride2],  %[src2_stride1]      \n\t"
    "slli.w    %[src2_stride4],  %[src2_stride1],  2                    \n\t"
    "slli.w    %[dst_stride2],   %[dst_stride1],   1                    \n\t"
    "add.w     %[dst_stride3],   %[dst_stride2],   %[dst_stride1]       \n\t"
    "slli.w    %[dst_stride4],   %[dst_stride1],   2                    \n\t"
    "beqz      %[cnt],           2f                                     \n\t"
    "1:                                                                 \n\t"
    "addi.w    %[cnt],           %[cnt],           -1                   \n\t"
    "vld       $vr0,             %[src1],          0                    \n\t"
    "vldx      $vr1,             %[src1],          %[src1_stride1]      \n\t"
    "vldx      $vr2,             %[src1],          %[src1_stride2]      \n\t"
    "vldx      $vr3,             %[src1],          %[src1_stride3]      \n\t"
    "vld       $vr4,             %[src2],          0                    \n\t"
    "vldx      $vr5,             %[src2],          %[src2_stride1]      \n\t"
    "vldx      $vr6,             %[src2],          %[src2_stride2]      \n\t"
    "vldx      $vr7,             %[src2],          %[src2_stride3]      \n\t"
    "vavgr.bu  $vr0,             $vr0,             $vr4                 \n\t"
    "vavgr.bu  $vr1,             $vr1,             $vr5                 \n\t"
    "vavgr.bu  $vr2,             $vr2,             $vr6                 \n\t"
    "vavgr.bu  $vr3,             $vr3,             $vr7                 \n\t"
    "vst       $vr0,             %[dst],           0                    \n\t"
    "vstx      $vr1,             %[dst],           %[dst_stride1]       \n\t"
    "vstx      $vr2,             %[dst],           %[dst_stride2]       \n\t"
    "vstx      $vr3,             %[dst],           %[dst_stride3]       \n\t"
    "add.d     %[dst],           %[dst],           %[dst_stride4]       \n\t"
    "add.d     %[src1],          %[src1],          %[src1_stride4]      \n\t"
    "add.d     %[src2],          %[src2],          %[src2_stride4]      \n\t"

    "vld       $vr0,             %[src1],          0                    \n\t"
    "vldx      $vr1,             %[src1],          %[src1_stride1]      \n\t"
    "vldx      $vr2,             %[src1],          %[src1_stride2]      \n\t"
    "vldx      $vr3,             %[src1],          %[src1_stride3]      \n\t"
    "vld       $vr4,             %[src2],          0                    \n\t"
    "vldx      $vr5,             %[src2],          %[src2_stride1]      \n\t"
    "vldx      $vr6,             %[src2],          %[src2_stride2]      \n\t"
    "vldx      $vr7,             %[src2],          %[src2_stride3]      \n\t"
    "vavgr.bu  $vr0,             $vr0,             $vr4                 \n\t"
    "vavgr.bu  $vr1,             $vr1,             $vr5                 \n\t"
    "vavgr.bu  $vr2,             $vr2,             $vr6                 \n\t"
    "vavgr.bu  $vr3,             $vr3,             $vr7                 \n\t"
    "vst       $vr0,             %[dst],           0                    \n\t"
    "vstx      $vr1,             %[dst],           %[dst_stride1]       \n\t"
    "vstx      $vr2,             %[dst],           %[dst_stride2]       \n\t"
    "vstx      $vr3,             %[dst],           %[dst_stride3]       \n\t"
    "add.d     %[dst],           %[dst],           %[dst_stride4]       \n\t"
    "add.d     %[src1],          %[src1],          %[src1_stride4]      \n\t"
    "add.d     %[src2],          %[src2],          %[src2_stride4]      \n\t"

    "bnez      %[cnt],           1b                                     \n\t"
    "2:                                                                 \n\t"
     : [src1]"+&r"(p_src1),
       [src2]"+&r"(p_src2),
       [src1_stride2]"=&r"(i_src1_stride_x2),
       [src1_stride3]"=&r"(i_src1_stride_x3),
       [src1_stride4]"=&r"(i_src1_stride_x4),
       [src2_stride2]"=&r"(i_src2_stride_x2),
       [src2_stride3]"=&r"(i_src2_stride_x3),
       [src2_stride4]"=&r"(i_src2_stride_x4),
       [dst_stride2]"=&r"(i_dst_stride_x2),
       [dst_stride3]"=&r"(i_dst_stride_x3),
       [dst_stride4]"=&r"(i_dst_stride_x4),
       [dst]"+&r"(p_dst), [cnt]"+&r"(i_cnt)
     : [src1_stride1]"r"(i_src1_stride),
       [src2_stride1]"r"(i_src2_stride),
       [dst_stride1]"r"(i_dst_stride)
     : "memory"
    );
}

static void *x264_memcpy_aligned_lasx(void *dst, const void *src, size_t n)
{
    int64_t zero = 0, d;

    __asm__ volatile(
    "andi      %[d],            %[n],              16                   \n\t"
    "beqz      %[d],            2f                                      \n\t"
    "addi.d    %[n],            %[n],              -16                  \n\t"
    "vld       $vr0,            %[src],            0                    \n\t"
    "vst       $vr0,            %[dst],            0                    \n\t"
    "addi.d    %[src],          %[src],            16                   \n\t"
    "addi.d    %[dst],          %[dst],            16                   \n\t"
    "2:                                                                 \n\t"
    "andi      %[d],            %[n],              32                   \n\t"
    "beqz      %[d],            3f                                      \n\t"
    "addi.d    %[n],            %[n],              -32                  \n\t"
    "xvld      $xr0,            %[src],            0                    \n\t"
    "xvst      $xr0,            %[dst],            0                    \n\t"
    "addi.d    %[src],          %[src],            32                   \n\t"
    "addi.d    %[dst],          %[dst],            32                   \n\t"
    "3:                                                                 \n\t"
    "beqz      %[n],            5f                                      \n\t"
    "4:                                                                 \n\t"
    "addi.d    %[n],            %[n],              -64                  \n\t"
    "xvld      $xr0,            %[src],            32                   \n\t"
    "xvld      $xr1,            %[src],            0                    \n\t"
    "xvst      $xr0,            %[dst],            32                   \n\t"
    "xvst      $xr1,            %[dst],            0                    \n\t"
    "addi.d    %[src],          %[src],            64                   \n\t"
    "addi.d    %[dst],          %[dst],            64                   \n\t"
    "blt       %[zero],         %[n],              4b                   \n\t"
    "5:                                                                 \n\t"
    : [dst]"+&r"(dst), [src]"+&r"(src), [n]"+&r"(n),
      [d]"=&r"(d)
    : [zero]"r"(zero)
    : "memory"
    );
    return NULL;
}

static void pixel_avg_16x16_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                  uint8_t *p_pix2, intptr_t pix2_stride,
                                  uint8_t *p_pix3, intptr_t pix3_stride,
                                  int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width16_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                              p_pix1, pix1_stride, 16 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_16width_nw_lasx( p_pix2, pix2_stride,
                                           p_pix3, pix3_stride,
                                           p_pix1, pix1_stride,
                                           16, 5, i_weight,
                                           ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_16width_lasx( p_pix2, pix2_stride,
                                        p_pix3, pix3_stride,
                                        p_pix1, pix1_stride,
                                        16, 5, i_weight,
                                        ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_16x8_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                 uint8_t *p_pix2, intptr_t pix2_stride,
                                 uint8_t *p_pix3, intptr_t pix3_stride,
                                 int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width16_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                              p_pix1, pix1_stride, 8 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_16width_nw_lasx( p_pix2, pix2_stride,
                                           p_pix3, pix3_stride,
                                           p_pix1, pix1_stride,
                                           8, 5, i_weight,
                                           ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_16width_lasx( p_pix2, pix2_stride,
                                        p_pix3, pix3_stride,
                                        p_pix1, pix1_stride,
                                        8, 5, i_weight,
                                        ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_8x16_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                 uint8_t *p_pix2, intptr_t pix2_stride,
                                 uint8_t *p_pix3, intptr_t pix3_stride,
                                 int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width8_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                             p_pix1, pix1_stride, 16 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_8width_nw_lasx( p_pix2, pix2_stride,
                                          p_pix3, pix3_stride,
                                          p_pix1, pix1_stride, 16, 5, i_weight,
                                          ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_8width_lasx( p_pix2, pix2_stride,
                                       p_pix3, pix3_stride,
                                       p_pix1, pix1_stride, 16, 5, i_weight,
                                       ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_8x8_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                uint8_t *p_pix2, intptr_t pix2_stride,
                                uint8_t *p_pix3, intptr_t pix3_stride,
                                int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width8_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                             p_pix1, pix1_stride, 8 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_8width_nw_lasx( p_pix2, pix2_stride,
                                          p_pix3, pix3_stride,
                                          p_pix1, pix1_stride, 8, 5, i_weight,
                                          ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_8width_lasx( p_pix2, pix2_stride,
                                       p_pix3, pix3_stride,
                                       p_pix1, pix1_stride, 8, 5, i_weight,
                                       ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_8x4_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                uint8_t *p_pix2, intptr_t pix2_stride,
                                uint8_t *p_pix3, intptr_t pix3_stride,
                                int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width8_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                             p_pix1, pix1_stride, 4 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_8width_nw_lasx( p_pix2, pix2_stride,
                                          p_pix3, pix3_stride,
                                          p_pix1, pix1_stride, 4, 5, i_weight,
                                          ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_8width_lasx( p_pix2, pix2_stride,
                                       p_pix3, pix3_stride,
                                       p_pix1, pix1_stride, 4, 5, i_weight,
                                       ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_4x16_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                 uint8_t *p_pix2, intptr_t pix2_stride,
                                 uint8_t *p_pix3, intptr_t pix3_stride,
                                 int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width4_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                             p_pix1, pix1_stride, 16 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_4width_nw_lasx( p_pix2, pix2_stride,
                                          p_pix3, pix3_stride,
                                          p_pix1, pix1_stride, 16, 5, i_weight,
                                          ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_4width_lasx( p_pix2, pix2_stride,
                                       p_pix3, pix3_stride,
                                       p_pix1, pix1_stride, 16, 5, i_weight,
                                       ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_4x8_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                uint8_t *p_pix2, intptr_t pix2_stride,
                                uint8_t *p_pix3, intptr_t pix3_stride,
                                int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width4_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                             p_pix1, pix1_stride, 8 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_4width_nw_lasx( p_pix2, pix2_stride,
                                          p_pix3, pix3_stride,
                                          p_pix1, pix1_stride, 8, 5, i_weight,
                                          ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_4width_lasx( p_pix2, pix2_stride,
                                       p_pix3, pix3_stride,
                                       p_pix1, pix1_stride, 8, 5, i_weight,
                                       ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_4x4_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                uint8_t *p_pix2, intptr_t pix2_stride,
                                uint8_t *p_pix3, intptr_t pix3_stride,
                                int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width4_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                             p_pix1, pix1_stride, 4 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_4width_nw_lasx( p_pix2, pix2_stride,
                                          p_pix3, pix3_stride,
                                          p_pix1, pix1_stride, 4, 5, i_weight,
                                          ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_4width_lasx( p_pix2, pix2_stride,
                                       p_pix3, pix3_stride,
                                       p_pix1, pix1_stride, 4, 5, i_weight,
                                       ( 64 - i_weight ), 0 );
    }
}

static void pixel_avg_4x2_lasx( uint8_t *p_pix1, intptr_t pix1_stride,
                                uint8_t *p_pix2, intptr_t pix2_stride,
                                uint8_t *p_pix3, intptr_t pix3_stride,
                                int32_t i_weight )
{
    if( 32 == i_weight )
    {
        avg_src_width4_lasx( p_pix2, pix2_stride, p_pix3, pix3_stride,
                             p_pix1, pix1_stride, 2 );
    }
    else if( i_weight < 0 || i_weight > 63 )
    {
        avc_biwgt_opscale_4x2_nw_lasx( p_pix2, pix2_stride,
                                       p_pix3, pix3_stride,
                                       p_pix1, pix1_stride, 5, i_weight,
                                       ( 64 - i_weight ) );
    }
    else
    {
        avc_biwgt_opscale_4x2_lasx( p_pix2, pix2_stride,
                                    p_pix3, pix3_stride,
                                    p_pix1, pix1_stride, 5, i_weight,
                                    ( 64 - i_weight ), 0 );
    }
}

static inline void avg_src_width16_no_align_lasx( uint8_t *p_src1,
                                                  int32_t i_src1_stride,
                                                  uint8_t *p_src2,
                                                  int32_t i_src2_stride,
                                                  uint8_t *p_dst,
                                                  int32_t i_dst_stride,
                                                  int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1;

    for( i_cnt = i_height; i_cnt--; )
    {
        src0 = __lasx_xvld( p_src1, 0 );
        p_src1 += i_src1_stride;
        src1 = __lasx_xvld( p_src2, 0 );
        p_src2 += i_src2_stride;

        src0 = __lasx_xvavgr_bu( src0, src1 );
        __lasx_xvstelm_d( src0, p_dst, 0, 0 );
        __lasx_xvstelm_d( src0, p_dst, 0, 1 );
        p_dst += i_dst_stride;
    }
}

static inline void avg_src_width20_no_align_lasx( uint8_t *p_src1,
                                                  int32_t i_src1_stride,
                                                  uint8_t *p_src2,
                                                  int32_t i_src2_stride,
                                                  uint8_t *p_dst,
                                                  int32_t i_dst_stride,
                                                  int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1;

    for( i_cnt = i_height; i_cnt--; )
    {
        src0 = __lasx_xvld( p_src1, 0 );
        p_src1 += i_src1_stride;
        src1 = __lasx_xvld( p_src2, 0 );
        p_src2 += i_src2_stride;

        src0 = __lasx_xvavgr_bu( src0, src1 );
        __lasx_xvstelm_d( src0, p_dst, 0, 0 );
        __lasx_xvstelm_d( src0, p_dst, 8, 1 );
        __lasx_xvstelm_w( src0, p_dst, 16, 4 );
        p_dst += i_dst_stride;
    }
}

static inline void avg_src_width12_no_align_lasx( uint8_t *p_src1,
                                                  int32_t i_src1_stride,
                                                  uint8_t *p_src2,
                                                  int32_t i_src2_stride,
                                                  uint8_t *p_dst,
                                                  int32_t i_dst_stride,
                                                  int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1;

    for( i_cnt = i_height; i_cnt--; )
    {
        src0 = __lasx_xvld( p_src1, 0 );
        p_src1 += i_src1_stride;
        src1 = __lasx_xvld( p_src2, 0 );
        p_src2 += i_src2_stride;

        src0 = __lasx_xvavgr_bu( src0, src1 );
        __lasx_xvstelm_d( src0, p_dst, 0, 0 );
        __lasx_xvstelm_w( src0, p_dst, 8, 2 );
        p_dst += i_dst_stride;
    }
}

static inline void avg_src_width8_no_align_lasx( uint8_t *p_src1,
                                                 int32_t i_src1_stride,
                                                 uint8_t *p_src2,
                                                 int32_t i_src2_stride,
                                                 uint8_t *p_dst,
                                                 int32_t i_dst_stride,
                                                 int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1;

    for( i_cnt = i_height; i_cnt--; )
    {
        src0 = __lasx_xvld( p_src1, 0 );
        p_src1 += i_src1_stride;
        src1 = __lasx_xvld( p_src2, 0 );
        p_src2 += i_src2_stride;

        src0 = __lasx_xvavgr_bu( src0, src1 );
        __lasx_xvstelm_d( src0, p_dst, 0, 0 );
        p_dst += i_dst_stride;
    }
}

static inline void avg_src_width4_no_align_lasx( uint8_t *p_src1,
                                                 int32_t i_src1_stride,
                                                 uint8_t *p_src2,
                                                 int32_t i_src2_stride,
                                                 uint8_t *p_dst,
                                                 int32_t i_dst_stride,
                                                 int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1;

    for( i_cnt = i_height; i_cnt--; )
    {
        src0 = __lasx_xvld( p_src1, 0 );
        p_src1 += i_src1_stride;
        src1 = __lasx_xvld( p_src2, 0 );
        p_src2 += i_src2_stride;

        src0 = __lasx_xvavgr_bu( src0, src1 );
        __lasx_xvstelm_w( src0, p_dst, 0, 0 );
        p_dst += i_dst_stride;
    }
}

static inline void mc_weight_w16_no_align_lasx( uint8_t *p_dst,
                                                intptr_t i_dst_stride,
                                                uint8_t *p_src,
                                                intptr_t i_src_stride,
                                                const x264_weight_t *pWeight,
                                                int32_t i_height )
{
    int32_t i_log2_denom = pWeight->i_denom;
    int32_t i_offset = pWeight->i_offset;
    int32_t i_weight = pWeight->i_scale;
    uint8_t u_cnt;
    __m256i zero = __lasx_xvldi( 0 );
    __m256i src;
    __m256i wgt, denom, offset;

    i_offset <<= ( i_log2_denom );

    if( i_log2_denom )
    {
        i_offset += ( 1 << ( i_log2_denom - 1 ) );
    }

    wgt =  __lasx_xvreplgr2vr_h( i_weight );
    offset = __lasx_xvreplgr2vr_h( i_offset );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom );

    for( u_cnt = i_height; u_cnt--; )
    {
        src = __lasx_xvld( p_src, 0 );
        p_src += i_src_stride;

        src = __lasx_xvpermi_d( src, 0x50 );
        src = __lasx_xvilvl_b( zero, src );

        src = __lasx_xvmul_h( src, wgt );
        src = __lasx_xvsadd_h( src, offset );
        src = __lasx_xvmaxi_h( src, 0 );
        src = __lasx_xvssrln_bu_h(src, denom);

        __lasx_xvstelm_d( src, p_dst, 0, 0 );
        __lasx_xvstelm_d( src, p_dst, 8, 2 );
        p_dst += i_dst_stride;
    }
}

static inline void mc_weight_w8_no_align_lasx( uint8_t *p_dst,
                                               intptr_t i_dst_stride,
                                               uint8_t *p_src,
                                               intptr_t i_src_stride,
                                               const x264_weight_t *pWeight,
                                               int32_t i_height )
{
    int32_t i_log2_denom = pWeight->i_denom;
    int32_t i_offset = pWeight->i_offset;
    int32_t i_weight = pWeight->i_scale;
    uint8_t u_cnt;
    __m256i zero = __lasx_xvldi( 0 );
    __m256i src;
    __m256i wgt, denom, offset;

    i_offset <<= ( i_log2_denom );

    if( i_log2_denom )
    {
        i_offset += ( 1 << ( i_log2_denom - 1 ) );
    }

    wgt =  __lasx_xvreplgr2vr_h( i_weight );
    offset = __lasx_xvreplgr2vr_h( i_offset );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom );

    for( u_cnt = i_height; u_cnt--; )
    {
        src = __lasx_xvldrepl_d( p_src, 0 );
        p_src += i_src_stride;

        src = __lasx_xvilvl_b( zero, src );

        src = __lasx_xvmul_h( src, wgt );
        src = __lasx_xvsadd_h( src, offset );
        src = __lasx_xvmaxi_h( src, 0 );
        src = __lasx_xvssrln_bu_h(src, denom);

        __lasx_xvstelm_d( src, p_dst, 0, 0 );
        p_dst += i_dst_stride;
    }
}

static inline void mc_weight_w4_no_align_lasx( uint8_t *p_dst,
                                               intptr_t i_dst_stride,
                                               uint8_t *p_src,
                                               intptr_t i_src_stride,
                                               const x264_weight_t *pWeight,
                                               int32_t i_height )
{
    int32_t i_log2_denom = pWeight->i_denom;
    int32_t i_offset = pWeight->i_offset;
    int32_t i_weight = pWeight->i_scale;
    uint8_t u_cnt;
    __m256i zero = __lasx_xvldi( 0 );
    __m256i src;
    __m256i wgt, denom, offset;

    i_offset <<= ( i_log2_denom );

    if( i_log2_denom )
    {
        i_offset += ( 1 << ( i_log2_denom - 1 ) );
    }

    wgt =  __lasx_xvreplgr2vr_h( i_weight );
    offset = __lasx_xvreplgr2vr_h( i_offset );
    denom = __lasx_xvreplgr2vr_h( i_log2_denom );

    for( u_cnt = i_height; u_cnt--; )
    {
        src = __lasx_xvldrepl_w( p_src, 0 );
        p_src += i_src_stride;

        src = __lasx_xvilvl_b( zero, src );

        src = __lasx_xvmul_h( src, wgt );
        src = __lasx_xvsadd_h( src, offset );
        src = __lasx_xvmaxi_h( src, 0 );
        src = __lasx_xvssrln_bu_h(src, denom);

        __lasx_xvstelm_w( src, p_dst, 0, 0 );
        p_dst += i_dst_stride;
    }
}

static inline void mc_weight_w20_no_align_lasx( uint8_t *p_dst,
                                                intptr_t i_dst_stride,
                                                uint8_t *p_src,
                                                intptr_t i_src_stride,
                                                const x264_weight_t *pWeight,
                                                int32_t i_height )
{
    mc_weight_w16_no_align_lasx( p_dst, i_dst_stride,
                                 p_src, i_src_stride,
                                 pWeight, i_height );
    mc_weight_w4_no_align_lasx( p_dst + 16, i_dst_stride,
                                p_src + 16, i_src_stride,
                                pWeight, i_height );
}

void x264_pixel_avg2_w4_lasx (uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
                              intptr_t i_src_stride, uint8_t *src2, int i_height)
{
    int64_t zero = 2, i_4 = 4;

    __asm__ volatile(
    "1:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -4                     \n\t"
    "vldrepl.w      $vr0,             %[src1],              0                      \n\t"
    "vldrepl.w      $vr1,             %[src2],              0                      \n\t"
    "add.d          %[src1],          %[src1],              %[i_src_stride]        \n\t"
    "add.d          %[src2],          %[src2],              %[i_src_stride]        \n\t"
    "vldrepl.w      $vr2,             %[src1],              0                      \n\t"
    "vldrepl.w      $vr3,             %[src2],              0                      \n\t"
    "add.d          %[src1],          %[src1],              %[i_src_stride]        \n\t"
    "add.d          %[src2],          %[src2],              %[i_src_stride]        \n\t"
    "vldrepl.w      $vr4,             %[src1],              0                      \n\t"
    "vldrepl.w      $vr5,             %[src2],              0                      \n\t"
    "add.d          %[src1],          %[src1],              %[i_src_stride]        \n\t"
    "add.d          %[src2],          %[src2],              %[i_src_stride]        \n\t"
    "vldrepl.w      $vr6,             %[src1],              0                      \n\t"
    "vldrepl.w      $vr7,             %[src2],              0                      \n\t"
    "add.d          %[src1],          %[src1],              %[i_src_stride]        \n\t"
    "add.d          %[src2],          %[src2],              %[i_src_stride]        \n\t"
    "vavgr.bu       $vr0,             $vr0,                 $vr1                   \n\t"
    "vavgr.bu       $vr1,             $vr2,                 $vr3                   \n\t"
    "vavgr.bu       $vr2,             $vr4,                 $vr5                   \n\t"
    "vavgr.bu       $vr3,             $vr6,                 $vr7                   \n\t"
    "vstelm.w       $vr0,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.w       $vr1,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.w       $vr2,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.w       $vr3,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "bge            %[i_height],      %[i_4],               1b                     \n\t"
    "beqz           %[i_height],      3f                                           \n\t"
    "2:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -2                     \n\t"
    "vldrepl.w      $vr0,             %[src1],              0                      \n\t"
    "vldrepl.w      $vr1,             %[src2],              0                      \n\t"
    "add.d          %[src1],          %[src1],              %[i_src_stride]        \n\t"
    "add.d          %[src2],          %[src2],              %[i_src_stride]        \n\t"
    "vldrepl.w      $vr2,             %[src1],              0                      \n\t"
    "vldrepl.w      $vr3,             %[src2],              0                      \n\t"
    "add.d          %[src1],          %[src1],              %[i_src_stride]        \n\t"
    "add.d          %[src2],          %[src2],              %[i_src_stride]        \n\t"
    "vavgr.bu       $vr0,             $vr0,                 $vr1                   \n\t"
    "vavgr.bu       $vr1,             $vr2,                 $vr3                   \n\t"
    "vstelm.w       $vr0,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.w       $vr1,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "blt            %[zero],          %[i_height],          2b                     \n\t"
    "3:                                                                            \n\t"
    : [i_height]"+&r"(i_height), [src1]"+&r"(src1), [src2]"+&r"(src2),
      [dst]"+&r"(dst)
    : [i_dst_stride]"r"((int64_t) i_dst_stride), [i_src_stride]"r"((int64_t) i_src_stride),
      [zero]"r"(zero), [i_4]"r"(i_4)
    : "memory"
    );
}

void x264_pixel_avg2_w8_lasx (uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
                              intptr_t i_src_stride, uint8_t *src2, int i_height)
{
    int64_t zero = 0, i_4 = 4, src_stride2, src_stride3, src_stride4;

    __asm__ volatile(
    "slli.d         %[src_stride2],   %[i_src_stride],      1                      \n\t"
    "add.d          %[src_stride3],   %[src_stride2],       %[i_src_stride]        \n\t"
    "slli.d         %[src_stride4],   %[src_stride2],       1                      \n\t"
    "1:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -4                     \n\t"
    "vld            $vr0,             %[src1],              0                      \n\t"
    "vld            $vr1,             %[src2],              0                      \n\t"
    "vldx           $vr2,             %[src1],              %[i_src_stride]        \n\t"
    "vldx           $vr3,             %[src2],              %[i_src_stride]        \n\t"
    "vldx           $vr4,             %[src1],              %[src_stride2]         \n\t"
    "vldx           $vr5,             %[src2],              %[src_stride2]         \n\t"
    "vldx           $vr6,             %[src1],              %[src_stride3]         \n\t"
    "vldx           $vr7,             %[src2],              %[src_stride3]         \n\t"
    "add.d          %[src1],          %[src1],              %[src_stride4]         \n\t"
    "add.d          %[src2],          %[src2],              %[src_stride4]         \n\t"
    "vavgr.bu       $vr0,             $vr0,                 $vr1                   \n\t"
    "vavgr.bu       $vr1,             $vr2,                 $vr3                   \n\t"
    "vavgr.bu       $vr2,             $vr4,                 $vr5                   \n\t"
    "vavgr.bu       $vr3,             $vr6,                 $vr7                   \n\t"
    "vstelm.d       $vr0,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.d       $vr1,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.d       $vr2,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.d       $vr3,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "bge            %[i_height],      %[i_4],               1b                     \n\t"
    "beqz           %[i_height],      3f                                           \n\t"
    "2:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -2                     \n\t"
    "vld            $vr0,             %[src1],              0                      \n\t"
    "vld            $vr1,             %[src2],              0                      \n\t"
    "vldx           $vr2,             %[src1],              %[i_src_stride]        \n\t"
    "vldx           $vr3,             %[src2],              %[i_src_stride]        \n\t"
    "add.d          %[src1],          %[src1],              %[src_stride2]         \n\t"
    "add.d          %[src2],          %[src2],              %[src_stride2]         \n\t"
    "vavgr.bu       $vr0,             $vr0,                 $vr1                   \n\t"
    "vavgr.bu       $vr1,             $vr2,                 $vr3                   \n\t"
    "vstelm.d       $vr0,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vstelm.d       $vr1,             %[dst],               0,           0         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "blt            %[zero],          %[i_height],          2b                     \n\t"
    "3:                                                                            \n\t"
    : [i_height]"+&r"(i_height), [src1]"+&r"(src1), [src2]"+&r"(src2),
      [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2), [src_stride3]"=&r"(src_stride3),
      [src_stride4]"=&r"(src_stride4)
    : [i_dst_stride]"r"((int64_t) i_dst_stride), [i_src_stride]"r"((int64_t) i_src_stride),
      [zero]"r"(zero), [i_4]"r"(i_4)
    : "memory"
    );
}

void x264_pixel_avg2_w16_lasx (uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
                               intptr_t i_src_stride, uint8_t *src2, int i_height)
{
    int64_t src_stride2, dst_stride2, dst_stride3, src_stride3, src_stride4, dst_stride4;
    int64_t zero = 0, i_4 = 4;

    __asm__ volatile(
    "slli.d         %[src_stride2],   %[i_src_stride],      1                      \n\t"
    "slli.d         %[dst_stride2],   %[i_dst_stride],      1                      \n\t"
    "add.d          %[src_stride3],   %[src_stride2],       %[i_src_stride]        \n\t"
    "add.d          %[dst_stride3],   %[dst_stride2],       %[i_dst_stride]        \n\t"
    "slli.d         %[src_stride4],   %[src_stride2],       1                      \n\t"
    "slli.d         %[dst_stride4],   %[dst_stride2],       1                      \n\t"
    "1:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -4                     \n\t"
    "vld            $vr0,             %[src1],              0                      \n\t"
    "vldx           $vr1,             %[src1],              %[i_src_stride]        \n\t"
    "vldx           $vr2,             %[src1],              %[src_stride2]         \n\t"
    "vldx           $vr3,             %[src1],              %[src_stride3]         \n\t"
    "vld            $vr4,             %[src2],              0                      \n\t"
    "vldx           $vr5,             %[src2],              %[i_src_stride]        \n\t"
    "vldx           $vr6,             %[src2],              %[src_stride2]         \n\t"
    "vldx           $vr7,             %[src2],              %[src_stride3]         \n\t"
    "vavgr.bu       $vr0,             $vr0,                 $vr4                   \n\t"
    "vavgr.bu       $vr1,             $vr1,                 $vr5                   \n\t"
    "vavgr.bu       $vr2,             $vr2,                 $vr6                   \n\t"
    "vavgr.bu       $vr3,             $vr3,                 $vr7                   \n\t"
    "add.d          %[src1],          %[src1],              %[src_stride4]         \n\t"
    "add.d          %[src2],          %[src2],              %[src_stride4]         \n\t"
    "vst            $vr0,             %[dst],               0                      \n\t"
    "vstx           $vr1,             %[dst],               %[i_dst_stride]        \n\t"
    "vstx           $vr2,             %[dst],               %[dst_stride2]         \n\t"
    "vstx           $vr3,             %[dst],               %[dst_stride3]         \n\t"
    "add.d          %[dst],           %[dst],               %[dst_stride4]         \n\t"
    "bge            %[i_height],      %[i_4],               1b                     \n\t"
    "beqz           %[i_height],      3f                                           \n\t"
    "2:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -2                     \n\t"
    "vld            $vr0,             %[src1],              0                      \n\t"
    "vldx           $vr1,             %[src1],              %[i_src_stride]        \n\t"
    "vld            $vr2,             %[src2],              0                      \n\t"
    "vldx           $vr3,             %[src2],              %[i_src_stride]        \n\t"
    "add.d          %[src1],          %[src1],              %[src_stride2]         \n\t"
    "add.d          %[src2],          %[src2],              %[src_stride2]         \n\t"
    "vavgr.bu       $vr0,             $vr0,                 $vr2                   \n\t"
    "vavgr.bu       $vr1,             $vr1,                 $vr3                   \n\t"
    "vst            $vr0,             %[dst],               0                      \n\t"
    "vstx           $vr1,             %[dst],               %[i_dst_stride]        \n\t"
    "add.d          %[dst],           %[dst],               %[dst_stride2]         \n\t"
    "blt            %[zero],          %[i_height],          2b                     \n\t"
    "3:                                                                            \n\t"
    : [i_height]"+&r"(i_height), [src1]"+&r"(src1), [src2]"+&r"(src2),
      [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2), [dst_stride2]"=&r"(dst_stride2),
      [src_stride3]"=&r"(src_stride3), [dst_stride3]"=&r"(dst_stride3),
      [src_stride4]"=&r"(src_stride4), [dst_stride4]"=&r"(dst_stride4)
    : [i_dst_stride]"r"((int64_t) i_dst_stride), [i_src_stride]"r"((int64_t) i_src_stride),
      [zero]"r"(zero), [i_4]"r"(i_4)
    : "memory"
    );
}

void x264_pixel_avg2_w20_lasx (uint8_t *dst, intptr_t i_dst_stride, uint8_t *src1,
                               intptr_t i_src_stride, uint8_t *src2, int i_height)
{
    int64_t zero = 0, i_4 = 4;
    int64_t src_stride2, src_stride3, src_stride4;

    __asm__ volatile(
    "slli.d         %[src_stride2],   %[i_src_stride],      1                      \n\t"
    "add.d          %[src_stride3],   %[src_stride2],       %[i_src_stride]        \n\t"
    "slli.d         %[src_stride4],   %[src_stride2],       1                      \n\t"
    "1:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -4                     \n\t"
    "xvld           $xr0,             %[src1],              0                      \n\t"
    "xvldx          $xr1,             %[src1],              %[i_src_stride]        \n\t"
    "xvldx          $xr2,             %[src1],              %[src_stride2]         \n\t"
    "xvldx          $xr3,             %[src1],              %[src_stride3]         \n\t"
    "xvld           $xr4,             %[src2],              0                      \n\t"
    "xvldx          $xr5,             %[src2],              %[i_src_stride]        \n\t"
    "xvldx          $xr6,             %[src2],              %[src_stride2]         \n\t"
    "xvldx          $xr7,             %[src2],              %[src_stride3]         \n\t"
    "add.d          %[src1],          %[src1],              %[src_stride4]         \n\t"
    "add.d          %[src2],          %[src2],              %[src_stride4]         \n\t"

    "xvavgr.bu      $xr0,             $xr0,                 $xr4                   \n\t"
    "xvavgr.bu      $xr1,             $xr1,                 $xr5                   \n\t"
    "xvavgr.bu      $xr2,             $xr2,                 $xr6                   \n\t"
    "xvavgr.bu      $xr3,             $xr3,                 $xr7                   \n\t"
    "vst            $vr0,             %[dst],               0                      \n\t"
    "xvstelm.w      $xr0,             %[dst],               16,          4         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vst            $vr1,             %[dst],               0                      \n\t"
    "xvstelm.w      $xr1,             %[dst],               16,          4         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vst            $vr2,             %[dst],               0                      \n\t"
    "xvstelm.w      $xr2,             %[dst],               16,          4         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vst            $vr3,             %[dst],               0                      \n\t"
    "xvstelm.w      $xr3,             %[dst],               16,          4         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "bge            %[i_height],      %[i_4],          1b                     \n\t"
    "beqz           %[i_height],      3f                                           \n\t"
    "2:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -2                     \n\t"
    "xvld           $xr0,             %[src1],              0                      \n\t"
    "xvldx          $xr1,             %[src1],              %[i_src_stride]        \n\t"
    "xvld           $xr2,             %[src2],              0                      \n\t"
    "xvldx          $xr3,             %[src2],              %[i_src_stride]        \n\t"
    "add.d          %[src1],          %[src1],              %[src_stride2]         \n\t"
    "add.d          %[src2],          %[src2],              %[src_stride2]         \n\t"
    "xvavgr.bu      $xr0,             $xr0,                 $xr2                   \n\t"
    "xvavgr.bu      $xr1,             $xr1,                 $xr3                   \n\t"
    "vst            $vr0,             %[dst],               0                      \n\t"
    "xvstelm.w      $xr0,             %[dst],               16,          4         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "vst            $vr1,             %[dst],               0                      \n\t"
    "xvstelm.w      $xr1,             %[dst],               16,          4         \n\t"
    "add.d          %[dst],           %[dst],               %[i_dst_stride]        \n\t"
    "blt            %[zero],          %[i_height],          2b                     \n\t"
    "3:                                                                            \n\t"
    : [i_height]"+&r"(i_height), [src1]"+&r"(src1), [src2]"+&r"(src2),
      [dst]"+&r"(dst), [src_stride2]"=&r"(src_stride2),
      [src_stride3]"=&r"(src_stride3), [src_stride4]"=&r"(src_stride4)
    : [i_dst_stride]"r"((int64_t) i_dst_stride), [i_src_stride]"r"((int64_t) i_src_stride),
      [zero]"r"(zero), [i_4]"r"(i_4)
    : "memory"
    );
}

static void (* const pixel_avg_wtab_lasx[6])(uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int ) =
{
    NULL,
    x264_pixel_avg2_w4_lasx,
    x264_pixel_avg2_w8_lasx,
    x264_pixel_avg2_w16_lasx,
    x264_pixel_avg2_w16_lasx,
    x264_pixel_avg2_w20_lasx,
};

static uint8_t *get_ref_lasx( uint8_t *p_dst, intptr_t *p_dst_stride,
                              uint8_t *p_src[4], intptr_t i_src_stride,
                              int32_t m_vx, int32_t m_vy,
                              int32_t i_width, int32_t i_height,
                              const x264_weight_t *pWeight )
{
    int32_t i_qpel_idx;
    int32_t i_offset;
    uint8_t *p_src1;
    int32_t r_vy = m_vy & 3;
    int32_t r_vx = m_vx & 3;
    int32_t width = i_width >> 2;

    i_qpel_idx = ( r_vy << 2 ) + r_vx;
    i_offset = ( m_vy >> 2 ) * i_src_stride + ( m_vx >> 2 );
    p_src1 = p_src[x264_hpel_ref0[i_qpel_idx]] + i_offset +
           ( 3 == r_vy ) * i_src_stride;

    if( i_qpel_idx & 5 )
    {
        uint8_t *p_src2 = p_src[x264_hpel_ref1[i_qpel_idx]] +
                          i_offset + ( 3 == r_vx );
        pixel_avg_wtab_lasx[width](
                p_dst, *p_dst_stride, p_src1, i_src_stride,
                p_src2, i_height );

        if( pWeight->weightfn )
        {
            pWeight->weightfn[width](p_dst, *p_dst_stride, p_dst, *p_dst_stride, pWeight, i_height);
        }
        return p_dst;
    }
    else if ( pWeight->weightfn )
    {
        pWeight->weightfn[width]( p_dst, *p_dst_stride, p_src1, i_src_stride, pWeight, i_height );
        return p_dst;
    }
    else
    {
        *p_dst_stride = i_src_stride;
        return p_src1;
    }
}

static void avc_interleaved_chroma_hv_2x2_lasx( uint8_t *p_src,
                                                int32_t i_src_stride,
                                                uint8_t *p_dst_u,
                                                uint8_t *p_dst_v,
                                                int32_t i_dst_stride,
                                                uint32_t u_coef_hor0,
                                                uint32_t u_coef_hor1,
                                                uint32_t u_coef_ver0,
                                                uint32_t u_coef_ver1 )
{
    __m256i src0, src1, src2, src3, src4;
    __m256i mask, mask1;

    __m256i coeff_hz_vec0 = __lasx_xvreplgr2vr_b( u_coef_hor0 );
    __m256i coeff_hz_vec1 = __lasx_xvreplgr2vr_b( u_coef_hor1 );
    __m256i coeff_hz_vec = __lasx_xvilvl_b( coeff_hz_vec0, coeff_hz_vec1 );
    __m256i coeff_vt_vec0 = __lasx_xvreplgr2vr_h( u_coef_ver0 );
    __m256i coeff_vt_vec1 = __lasx_xvreplgr2vr_h( u_coef_ver1 );

    mask = __lasx_xvld(pu_chroma_mask_arr, 0);
    mask1 = __lasx_xvaddi_bu(mask, 1);

    src0 = __lasx_xvld( p_src, 0);
    src1 = __lasx_xvldx( p_src, i_src_stride);
    src2 = __lasx_xvldx( p_src, (i_src_stride << 1));

    DUP2_ARG3( __lasx_xvshuf_b, src1, src0, mask1, src2, src1, mask1, src3, src4 );
    DUP2_ARG3( __lasx_xvshuf_b, src1, src0, mask, src2, src1, mask, src0, src1 );

    src0 = __lasx_xvpermi_q( src0, src3, 0x02 );
    src1 = __lasx_xvpermi_q( src1, src4, 0x02 );
    DUP2_ARG2( __lasx_xvdp2_h_bu, src0, coeff_hz_vec, src1, coeff_hz_vec, src0, src1);
    src0 = __lasx_xvmul_h( src0, coeff_vt_vec1 );
    src0 = __lasx_xvmadd_h( src0, src1, coeff_vt_vec0 );
    src0 = __lasx_xvssrlrni_bu_h(src0, src0, 6);
    __lasx_xvstelm_h( src0, p_dst_u, 0, 0 );
    __lasx_xvstelm_h( src0, p_dst_u + i_dst_stride, 0, 2 );
    __lasx_xvstelm_h( src0, p_dst_v, 0, 8 );
    __lasx_xvstelm_h( src0, p_dst_v + i_dst_stride, 0, 10 );
}

static void avc_interleaved_chroma_hv_2x4_lasx( uint8_t *p_src,
                                                int32_t i_src_stride,
                                                uint8_t *p_dst_u,
                                                uint8_t *p_dst_v,
                                                int32_t i_dst_stride,
                                                uint32_t u_coef_hor0,
                                                uint32_t u_coef_hor1,
                                                uint32_t u_coef_ver0,
                                                uint32_t u_coef_ver1 )
{
    int32_t src_stride2 = i_src_stride << 1;
    int32_t src_stride3 = i_src_stride + src_stride2;
    int32_t src_stride4 = src_stride2 << 1;
    int32_t dst_stride2 = i_dst_stride << 1;
    int32_t dst_stride3 = i_dst_stride + dst_stride2;
    int32_t dst_stride4 = dst_stride2 << 1;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7, src8;
    __m256i mask, mask1;

    __m256i coeff_hz_vec0 = __lasx_xvreplgr2vr_b( u_coef_hor0 );
    __m256i coeff_hz_vec1 = __lasx_xvreplgr2vr_b( u_coef_hor1 );
    __m256i coeff_hz_vec = __lasx_xvilvl_b( coeff_hz_vec0, coeff_hz_vec1 );
    __m256i coeff_vt_vec0 = __lasx_xvreplgr2vr_h( u_coef_ver0 );
    __m256i coeff_vt_vec1 = __lasx_xvreplgr2vr_h( u_coef_ver1 );

    mask = __lasx_xvld( pu_chroma_mask_arr, 0);
    mask1 = __lasx_xvaddi_bu(mask, 1);

    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvldx( p_src, i_src_stride);
    src2 = __lasx_xvldx( p_src, src_stride2);
    src3 = __lasx_xvldx( p_src, src_stride3);
    src4 = __lasx_xvldx( p_src, src_stride4);

    DUP4_ARG3( __lasx_xvshuf_b, src1, src0, mask1, src2, src1, mask1, src3, src2,
               mask1, src4, src3, mask1, src5, src6, src7, src8 );
    DUP4_ARG3( __lasx_xvshuf_b, src1, src0, mask, src2, src1, mask, src3, src2, mask,
               src4, src3, mask, src0, src1, src2, src3 );

    src0 = __lasx_xvpermi_q( src0, src2, 0x02 );
    src1 = __lasx_xvpermi_q( src1, src3, 0x02 );
    DUP2_ARG2(__lasx_xvdp2_h_bu, src0, coeff_hz_vec, src1, coeff_hz_vec, src0, src1);
    src0 = __lasx_xvmul_h( src0, coeff_vt_vec1 );
    src0 = __lasx_xvmadd_h( src0, src1, coeff_vt_vec0 );
    src0 = __lasx_xvssrlrni_bu_h(src0, src0, 6);
    __lasx_xvstelm_h(src0, p_dst_u, 0, 0);
    __lasx_xvstelm_h(src0, p_dst_u + i_dst_stride, 0, 2);
    __lasx_xvstelm_h(src0, p_dst_u + dst_stride2, 0, 8);
    __lasx_xvstelm_h(src0, p_dst_u + dst_stride3, 0, 10);
    p_dst_u += dst_stride4;

    src0 = __lasx_xvpermi_q( src5, src7, 0x02 );
    src1 = __lasx_xvpermi_q( src6, src8, 0x02 );
    DUP2_ARG2(__lasx_xvdp2_h_bu, src0, coeff_hz_vec, src1, coeff_hz_vec, src0, src1);
    src0 = __lasx_xvmul_h( src0, coeff_vt_vec1 );
    src0 = __lasx_xvmadd_h( src0, src1, coeff_vt_vec0 );
    src0 = __lasx_xvssrlrni_bu_h(src0, src0, 6);
    __lasx_xvstelm_h(src0, p_dst_v, 0, 0);
    __lasx_xvstelm_h(src0, p_dst_v + i_dst_stride, 0, 2);
    __lasx_xvstelm_h(src0, p_dst_v + dst_stride2, 0, 8);
    __lasx_xvstelm_h(src0, p_dst_v + dst_stride3, 0, 10);
    p_dst_v += dst_stride4;
}

static void avc_interleaved_chroma_hv_2w_lasx( uint8_t *p_src,
                                               int32_t i_src_stride,
                                               uint8_t *p_dst_u,
                                               uint8_t *p_dst_v,
                                               int32_t i_dst_stride,
                                               uint32_t u_coef_hor0,
                                               uint32_t u_coef_hor1,
                                               uint32_t u_coef_ver0,
                                               uint32_t u_coef_ver1,
                                               int32_t i_height )
{
    if( 2 == i_height )
    {
        avc_interleaved_chroma_hv_2x2_lasx( p_src, i_src_stride,
                                            p_dst_u, p_dst_v, i_dst_stride,
                                            u_coef_hor0, u_coef_hor1,
                                            u_coef_ver0, u_coef_ver1 );
    }
    else if( 4 == i_height )
    {
        avc_interleaved_chroma_hv_2x4_lasx( p_src, i_src_stride,
                                            p_dst_u, p_dst_v, i_dst_stride,
                                            u_coef_hor0, u_coef_hor1,
                                            u_coef_ver0, u_coef_ver1 );
    }
}

static void avc_interleaved_chroma_hv_4x2_lasx( uint8_t *p_src,
                                                int32_t i_src_stride,
                                                uint8_t *p_dst_u,
                                                uint8_t *p_dst_v,
                                                int32_t i_dst_stride,
                                                uint32_t u_coef_hor0,
                                                uint32_t u_coef_hor1,
                                                uint32_t u_coef_ver0,
                                                uint32_t u_coef_ver1 )
{
    __m256i src0, src1, src2, src3, src4;
    __m256i mask, mask1;

    __m256i coeff_hz_vec0 = __lasx_xvreplgr2vr_b( u_coef_hor0 );
    __m256i coeff_hz_vec1 = __lasx_xvreplgr2vr_b( u_coef_hor1 );
    __m256i coeff_hz_vec = __lasx_xvilvl_b( coeff_hz_vec0, coeff_hz_vec1 );
    __m256i coeff_vt_vec0 = __lasx_xvreplgr2vr_h( u_coef_ver0 );
    __m256i coeff_vt_vec1 = __lasx_xvreplgr2vr_h( u_coef_ver1 );

    mask = __lasx_xvld( pu_chroma_mask_arr, 0 );
    mask1 = __lasx_xvaddi_bu(mask, 1);

    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvldx( p_src, i_src_stride);
    src2 = __lasx_xvldx( p_src, (i_src_stride << 1));

    DUP2_ARG3( __lasx_xvshuf_b, src1, src0, mask1, src2, src1, mask1, src3, src4 );
    DUP2_ARG3( __lasx_xvshuf_b, src1, src0, mask, src2, src1, mask, src0, src1 );

    src0 = __lasx_xvpermi_q( src0, src3, 0x02 );
    src1 = __lasx_xvpermi_q( src1, src4, 0x02 );
    DUP2_ARG2( __lasx_xvdp2_h_bu, src0, coeff_hz_vec, src1, coeff_hz_vec, src0, src1);
    src0 = __lasx_xvmul_h( src0, coeff_vt_vec1 );
    src0 = __lasx_xvmadd_h( src0, src1, coeff_vt_vec0 );
    src0 = __lasx_xvssrlrni_bu_h(src0, src0, 6);
    __lasx_xvstelm_w( src0, p_dst_u, 0, 0 );
    __lasx_xvstelm_w( src0, p_dst_u + i_dst_stride, 0, 1 );
    __lasx_xvstelm_w( src0, p_dst_v, 0, 4 );
    __lasx_xvstelm_w( src0, p_dst_v + i_dst_stride, 0,  5 );
}

static void avc_interleaved_chroma_hv_4x4mul_lasx( uint8_t *p_src,
                                                   int32_t i_src_stride,
                                                   uint8_t *p_dst_u,
                                                   uint8_t *p_dst_v,
                                                   int32_t i_dst_stride,
                                                   uint32_t u_coef_hor0,
                                                   uint32_t u_coef_hor1,
                                                   uint32_t u_coef_ver0,
                                                   uint32_t u_coef_ver1,
                                                   int32_t i_height )
{
    uint32_t u_row;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7, src8;
    __m256i mask, mask1;
    int32_t src_stride2 = i_src_stride << 1;
    int32_t dst_stride2 = i_dst_stride << 1;
    int32_t src_stride3 = i_src_stride + src_stride2;
    int32_t dst_stride3 = i_dst_stride + dst_stride2;
    int32_t src_stride4 = src_stride2 << 1;
    int32_t dst_stride4 = dst_stride2 << 1;
    __m256i coeff_hz_vec0, coeff_hz_vec1;
    __m256i coeff_hz_vec;
    __m256i coeff_vt_vec0, coeff_vt_vec1;

    coeff_hz_vec0 = __lasx_xvreplgr2vr_b( u_coef_hor0 );
    coeff_hz_vec1 = __lasx_xvreplgr2vr_b( u_coef_hor1 );
    coeff_hz_vec = __lasx_xvilvl_b( coeff_hz_vec0, coeff_hz_vec1 );
    coeff_vt_vec0 = __lasx_xvreplgr2vr_h( u_coef_ver0 );
    coeff_vt_vec1 = __lasx_xvreplgr2vr_h( u_coef_ver1 );

    mask = __lasx_xvld( pu_chroma_mask_arr, 0 );
    mask1 = __lasx_xvaddi_bu(mask, 1);

    src0 = __lasx_xvld( p_src, 0 );

    for( u_row = ( i_height >> 2 ); u_row--; )
    {
        src1 = __lasx_xvldx(p_src, i_src_stride);
        src2 = __lasx_xvldx(p_src, src_stride2);
        src3 = __lasx_xvldx(p_src, src_stride3);
        src4 = __lasx_xvldx(p_src, src_stride4);
        p_src += src_stride4;

        DUP4_ARG3( __lasx_xvshuf_b, src1, src0, mask1, src2, src1, mask1, src3, src2,
                   mask1, src4, src3, mask1, src5, src6, src7, src8 );
        DUP4_ARG3( __lasx_xvshuf_b, src1, src0, mask, src2, src1, mask, src3, src2,
                   mask, src4, src3, mask, src0, src1, src2, src3 );

        src0 = __lasx_xvpermi_q( src0, src2, 0x02 );
        src1 = __lasx_xvpermi_q( src1, src3, 0x02 );
        DUP2_ARG2( __lasx_xvdp2_h_bu, src0, coeff_hz_vec, src1, coeff_hz_vec, src0, src1);
        src0 = __lasx_xvmul_h( src0, coeff_vt_vec1 );
        src0 = __lasx_xvmadd_h( src0, src1, coeff_vt_vec0 );
        src0 = __lasx_xvssrlrni_bu_h(src0, src0, 6);
        __lasx_xvstelm_w(src0, p_dst_u, 0, 0);
        __lasx_xvstelm_w(src0, p_dst_u + i_dst_stride, 0, 1);
        __lasx_xvstelm_w(src0, p_dst_u + dst_stride2, 0, 4);
        __lasx_xvstelm_w(src0, p_dst_u + dst_stride3, 0, 5);
        p_dst_u += dst_stride4;

        src0 = __lasx_xvpermi_q( src5, src7, 0x02 );
        src1 = __lasx_xvpermi_q( src6, src8, 0x02 );
        DUP2_ARG2( __lasx_xvdp2_h_bu, src0, coeff_hz_vec, src1, coeff_hz_vec, src0, src1);
        src0 = __lasx_xvmul_h( src0, coeff_vt_vec1 );
        src0 = __lasx_xvmadd_h( src0, src1, coeff_vt_vec0 );
        src0 = __lasx_xvssrlrni_bu_h(src0, src0, 6);
        __lasx_xvstelm_w(src0, p_dst_v, 0, 0);
        __lasx_xvstelm_w(src0, p_dst_v + i_dst_stride, 0, 1);
        __lasx_xvstelm_w(src0, p_dst_v + dst_stride2, 0, 4);
        __lasx_xvstelm_w(src0, p_dst_v + dst_stride3, 0, 5);
        p_dst_v += dst_stride4;

        src0 = src4;
    }
}

static void avc_interleaved_chroma_hv_4w_lasx( uint8_t *p_src,
                                               int32_t i_src_stride,
                                               uint8_t *p_dst_u,
                                               uint8_t *p_dst_v,
                                               int32_t i_dst_stride,
                                               uint32_t u_coef_hor0,
                                               uint32_t u_coef_hor1,
                                               uint32_t u_coef_ver0,
                                               uint32_t u_coef_ver1,
                                               int32_t i_height )
{
    if( 2 == i_height )
    {
        avc_interleaved_chroma_hv_4x2_lasx( p_src, i_src_stride,
                                            p_dst_u, p_dst_v, i_dst_stride,
                                            u_coef_hor0, u_coef_hor1,
                                            u_coef_ver0, u_coef_ver1 );
    }
    else
    {
        avc_interleaved_chroma_hv_4x4mul_lasx( p_src, i_src_stride,
                                               p_dst_u, p_dst_v, i_dst_stride,
                                               u_coef_hor0, u_coef_hor1,
                                               u_coef_ver0, u_coef_ver1,
                                               i_height );
    }
}

static void avc_interleaved_chroma_hv_8w_lasx( uint8_t *p_src,
                                               int32_t i_src_stride,
                                               uint8_t *p_dst_u,
                                               uint8_t *p_dst_v,
                                               int32_t i_dst_stride,
                                               uint32_t u_coef_hor0,
                                               uint32_t u_coef_hor1,
                                               uint32_t u_coef_ver0,
                                               uint32_t u_coef_ver1,
                                               int32_t i_height )
{
    uint32_t u_row;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7, src8;
    __m256i mask, mask1;
    __m256i coeff_hz_vec0, coeff_hz_vec1;
    __m256i coeff_hz_vec;
    __m256i coeff_vt_vec0, coeff_vt_vec1;
    __m256i tmp0, tmp1, tmp2, tmp3;
    __m256i head_u, head_v;

    int32_t src_stride2 = i_src_stride << 1;
    int32_t dst_stride2 = i_dst_stride << 1;
    int32_t src_stride3 = i_src_stride + src_stride2;
    int32_t dst_stride3 = i_dst_stride + dst_stride2;
    int32_t src_stride4 = src_stride2 << 1;
    int32_t dst_stride4 = dst_stride2 << 1;

    coeff_hz_vec0 = __lasx_xvreplgr2vr_b( u_coef_hor0 );
    coeff_hz_vec1 = __lasx_xvreplgr2vr_b( u_coef_hor1 );
    coeff_hz_vec = __lasx_xvilvl_b( coeff_hz_vec0, coeff_hz_vec1 );
    coeff_vt_vec0 = __lasx_xvreplgr2vr_h( u_coef_ver0 );
    coeff_vt_vec1 = __lasx_xvreplgr2vr_h( u_coef_ver1 );

    mask = __lasx_xvld( pu_chroma_mask_arr1, 0 );
    mask1 = __lasx_xvaddi_bu(mask, 1);

    src0 = __lasx_xvld( p_src, 0 );
    tmp0 = __lasx_xvpermi_q( src0, src0, 0x11 );
    DUP2_ARG3( __lasx_xvshuf_b, tmp0, src0, mask, tmp0, src0, mask1, head_u, head_v );
    DUP2_ARG2( __lasx_xvdp2_h_bu, head_u, coeff_hz_vec, head_v, coeff_hz_vec,
               head_u, head_v );

    for( u_row = ( i_height >> 2 ); u_row--; )
    {
        src1 = __lasx_xvldx(p_src, i_src_stride);
        src2 = __lasx_xvldx(p_src, src_stride2);
        src3 = __lasx_xvldx(p_src, src_stride3);
        src4 = __lasx_xvldx(p_src, src_stride4);
        p_src += src_stride4;
        src5 = __lasx_xvpermi_q( src1, src2, 0x02 );
        src6 = __lasx_xvpermi_q( src1, src2, 0x13 );
        src7 = __lasx_xvpermi_q( src3, src4, 0x02 );
        src8 = __lasx_xvpermi_q( src3, src4, 0x13 );

        DUP2_ARG3( __lasx_xvshuf_b, src6, src5, mask, src8, src7, mask, tmp0, tmp1 );
        DUP2_ARG2( __lasx_xvdp2_h_bu, tmp0, coeff_hz_vec, tmp1, coeff_hz_vec, tmp0, tmp1);
        tmp2 = __lasx_xvpermi_q( head_u, tmp0, 0x02 );
        tmp3 = __lasx_xvpermi_q( tmp0, tmp1, 0x03 );
        head_u = __lasx_xvpermi_q( tmp1, tmp1, 0x11 );

        tmp0 = __lasx_xvmul_h( tmp0, coeff_vt_vec0 );
        tmp1 = __lasx_xvmul_h( tmp1, coeff_vt_vec0 );
        tmp0 = __lasx_xvmadd_h( tmp0, tmp2, coeff_vt_vec1 );
        tmp1 = __lasx_xvmadd_h( tmp1, tmp3, coeff_vt_vec1 );

        tmp0 = __lasx_xvssrlrni_bu_h(tmp1, tmp0, 6);

        __lasx_xvstelm_d(tmp0, p_dst_u, 0, 0);
        __lasx_xvstelm_d(tmp0, p_dst_u + i_dst_stride, 0, 2);
        __lasx_xvstelm_d(tmp0, p_dst_u + dst_stride2, 0, 1);
        __lasx_xvstelm_d(tmp0, p_dst_u + dst_stride3, 0, 3);
        p_dst_u += dst_stride4;

        DUP2_ARG3( __lasx_xvshuf_b, src6, src5, mask1, src8, src7, mask1, tmp0, tmp1 );
        DUP2_ARG2( __lasx_xvdp2_h_bu, tmp0, coeff_hz_vec, tmp1, coeff_hz_vec, tmp0, tmp1);
        tmp2 = __lasx_xvpermi_q( head_v, tmp0, 0x02 );
        tmp3 = __lasx_xvpermi_q( tmp0, tmp1, 0x03 );
        head_v = __lasx_xvpermi_q( tmp1, tmp1, 0x11 );

        tmp0 = __lasx_xvmul_h( tmp0, coeff_vt_vec0 );
        tmp1 = __lasx_xvmul_h( tmp1, coeff_vt_vec0 );
        tmp0 = __lasx_xvmadd_h( tmp0, tmp2, coeff_vt_vec1 );
        tmp1 = __lasx_xvmadd_h( tmp1, tmp3, coeff_vt_vec1 );

        tmp0 = __lasx_xvssrlrni_bu_h(tmp1, tmp0, 6);
        __lasx_xvstelm_d(tmp0, p_dst_v, 0, 0);
        __lasx_xvstelm_d(tmp0, p_dst_v + i_dst_stride, 0, 2);
        __lasx_xvstelm_d(tmp0, p_dst_v + dst_stride2, 0, 1);
        __lasx_xvstelm_d(tmp0, p_dst_v + dst_stride3, 0, 3);
        p_dst_v += dst_stride4;
    }
}

static void mc_chroma_lasx( uint8_t *p_dst_u, uint8_t *p_dst_v,
                            intptr_t i_dst_stride,
                            uint8_t *p_src, intptr_t i_src_stride,
                            int32_t m_vx, int32_t m_vy,
                            int32_t i_width, int32_t i_height )
{
    int32_t i_d8x = m_vx & 0x07;
    int32_t i_d8y = m_vy & 0x07;
    int32_t i_coeff_horiz1 = ( 8 - i_d8x );
    int32_t i_coeff_vert1 = ( 8 - i_d8y );
    int32_t i_coeff_horiz0 = i_d8x;
    int32_t i_coeff_vert0 = i_d8y;

    p_src += ( m_vy >> 3 ) * i_src_stride + ( m_vx >> 3 ) * 2;

    if( 4 == i_width )
    {
        avc_interleaved_chroma_hv_4w_lasx( p_src, i_src_stride,
                                           p_dst_u, p_dst_v, i_dst_stride,
                                           i_coeff_horiz0, i_coeff_horiz1,
                                           i_coeff_vert0, i_coeff_vert1,
                                           i_height );
    }
    else if( 8 == i_width )
    {
        avc_interleaved_chroma_hv_8w_lasx( p_src, i_src_stride,
                                           p_dst_u, p_dst_v, i_dst_stride,
                                           i_coeff_horiz0, i_coeff_horiz1,
                                           i_coeff_vert0, i_coeff_vert1,
                                           i_height );
    }
    else if( 2 == i_width )
    {
        avc_interleaved_chroma_hv_2w_lasx( p_src, i_src_stride,
                                           p_dst_u, p_dst_v, i_dst_stride,
                                           i_coeff_horiz0, i_coeff_horiz1,
                                           i_coeff_vert0, i_coeff_vert1,
                                           i_height );
    }
}

static void copy_width4_lasx( uint8_t *p_src, int32_t i_src_stride,
                              uint8_t *p_dst, int32_t i_dst_stride,
                              int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1;

    for( i_cnt = ( i_height >> 1 ); i_cnt--;  )
    {
        src0 = __lasx_xvldrepl_w( p_src, 0 );
        p_src += i_src_stride;
        src1 = __lasx_xvldrepl_w( p_src, 0 );
        p_src += i_src_stride;

        __lasx_xvstelm_w( src0, p_dst, 0, 0 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_w( src1, p_dst, 0, 0 );
        p_dst += i_dst_stride;
    }
}

static void copy_width8_lasx( uint8_t *p_src, int32_t i_src_stride,
                              uint8_t *p_dst, int32_t i_dst_stride,
                              int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1, src2, src3;

#define COPY_W8_H4                                  \
    src0 = __lasx_xvldrepl_d( p_src, 0 );           \
    p_src += i_src_stride;                          \
    src1 = __lasx_xvldrepl_d( p_src, 0 );           \
    p_src += i_src_stride;                          \
    src2 = __lasx_xvldrepl_d( p_src, 0 );           \
    p_src += i_src_stride;                          \
    src3 = __lasx_xvldrepl_d( p_src, 0 );           \
    p_src += i_src_stride;                          \
                                                    \
    __lasx_xvstelm_d( src0, p_dst, 0, 0 );          \
    p_dst += i_dst_stride;                          \
    __lasx_xvstelm_d( src1, p_dst, 0, 0 );          \
    p_dst += i_dst_stride;                          \
    __lasx_xvstelm_d( src2, p_dst, 0, 0 );          \
    p_dst += i_dst_stride;                          \
    __lasx_xvstelm_d( src3, p_dst, 0, 0 );          \
    p_dst += i_dst_stride;

    if( 0 == i_height % 12 )
    {
        for( i_cnt = i_height; 0 < i_cnt; i_cnt -= 12 )
        {
            COPY_W8_H4;
            COPY_W8_H4;
            COPY_W8_H4;
        }
    }
    else if( 0 == ( i_height & 7 ) )
    {
        for( i_cnt = ( i_height >> 3 ); i_cnt--; )
        {
            COPY_W8_H4;
            COPY_W8_H4;
        }
    }
    else if( 0 == ( i_height & 3 ) )
    {
        for( i_cnt = ( i_height >> 2 ); i_cnt--; )
        {
            COPY_W8_H4;
        }
    }

#undef COPY_W8_H4

}

static void copy_width16_lasx( uint8_t *p_src, int32_t i_src_stride,
                               uint8_t *p_dst, int32_t i_dst_stride,
                               int32_t i_height )
{
    int32_t i_cnt;
    __m256i src0, src1, src2, src3;

#define COPY_W16_H4                                 \
    src0 = __lasx_xvld(p_src, 0);                   \
    p_src += i_src_stride;                          \
    src1 = __lasx_xvld(p_src, 0);                   \
    p_src += i_src_stride;                          \
    src2 = __lasx_xvld(p_src, 0);                   \
    p_src += i_src_stride;                          \
    src3 = __lasx_xvld(p_src, 0);                   \
    p_src += i_src_stride;                          \
                                                    \
    __lasx_xvstelm_d( src0, p_dst, 0, 0 );          \
    __lasx_xvstelm_d( src0, p_dst, 8, 1 );          \
    p_dst += i_dst_stride;                          \
    __lasx_xvstelm_d( src1, p_dst, 0, 0 );          \
    __lasx_xvstelm_d( src1, p_dst, 8, 1 );          \
    p_dst += i_dst_stride;                          \
    __lasx_xvstelm_d( src2, p_dst, 0, 0 );          \
    __lasx_xvstelm_d( src2, p_dst, 8, 1 );          \
    p_dst += i_dst_stride;                          \
    __lasx_xvstelm_d( src3, p_dst, 0, 0 );          \
    __lasx_xvstelm_d( src3, p_dst, 8, 1 );          \
    p_dst += i_dst_stride;

    if( 0 == i_height % 12 )
    {
        for( i_cnt = i_height; 0 < i_cnt; i_cnt -= 12 )
        {
            COPY_W16_H4;
            COPY_W16_H4;
            COPY_W16_H4;
        }
    }
    else if( 0 == ( i_height & 7 ) )
    {
        for( i_cnt = ( i_height >> 3 ); i_cnt--; )
        {
            COPY_W16_H4;
            COPY_W16_H4;
        }
    }
    else if( 0 == ( i_height & 3 ) )
    {
        for( i_cnt = ( i_height >> 2 ); i_cnt--; )
        {
            COPY_W16_H4;
        }
    }

#undef COPY_W16_H4

}

static void mc_copy_w16_lasx( uint8_t *p_dst, intptr_t i_dst_stride,
                              uint8_t *p_src, intptr_t i_src_stride,
                              int32_t i_height )
{
    copy_width16_lasx( p_src, i_src_stride, p_dst, i_dst_stride, i_height );
}

static void mc_copy_w8_lasx( uint8_t *p_dst, intptr_t i_dst_stride,
                             uint8_t *p_src, intptr_t i_src_stride,
                             int32_t i_height )
{
    copy_width8_lasx( p_src, i_src_stride, p_dst, i_dst_stride, i_height );
}

static void mc_copy_w4_lasx( uint8_t *p_dst, intptr_t i_dst_stride,
                             uint8_t *p_src, intptr_t i_src_stride,
                             int32_t i_height )
{
    copy_width4_lasx( p_src, i_src_stride, p_dst, i_dst_stride, i_height );
}

static void mc_luma_lasx( uint8_t *p_dst, intptr_t i_dst_stride,
                          uint8_t *p_src[4], intptr_t i_src_stride,
                          int32_t m_vx, int32_t m_vy,
                          int32_t i_width, int32_t i_height,
                          const x264_weight_t *pWeight )
{
    int32_t  i_qpel_idx;
    int32_t  i_offset;
    uint8_t  *p_src1;

    i_qpel_idx = ( ( m_vy & 3 ) << 2 ) + ( m_vx & 3 );
    i_offset = ( m_vy >> 2 ) * i_src_stride + ( m_vx >> 2 );
    p_src1 = p_src[x264_hpel_ref0[i_qpel_idx]] + i_offset +
             ( 3 == ( m_vy & 3 ) ) * i_src_stride;

    if( i_qpel_idx & 5 )
    {
        uint8_t *p_src2 = p_src[x264_hpel_ref1[i_qpel_idx]] +
                          i_offset + ( 3 == ( m_vx & 3 ) );

        pixel_avg_wtab_lasx[i_width >> 2](
                p_dst, i_dst_stride, p_src1, i_src_stride,
                p_src2, i_height );

        if( pWeight->weightfn )
        {
            pWeight->weightfn[i_width>>2]( p_dst, i_dst_stride, p_dst, i_dst_stride, pWeight, i_height );
        }
    }
    else if( pWeight->weightfn )
    {
        pWeight->weightfn[i_width>>2]( p_dst, i_dst_stride, p_src1, i_src_stride, pWeight, i_height );
    }
    else
    {
        if( 16 == i_width )
        {
            copy_width16_lasx( p_src1, i_src_stride, p_dst, i_dst_stride,
                               i_height );
        }
        else if( 8 == i_width )
        {
            copy_width8_lasx( p_src1, i_src_stride, p_dst, i_dst_stride,
                              i_height );
        }
        else if( 4 == i_width )
        {
            copy_width4_lasx( p_src1, i_src_stride, p_dst, i_dst_stride,
                              i_height );
        }
    }
}

static void avc_luma_vt_16w_lasx( uint8_t *p_src, int32_t i_src_stride,
                                  uint8_t *p_dst, int32_t i_dst_stride,
                                  int32_t i_height )
{
    uint32_t u_loop_cnt, u_h4w;
    const int16_t i_filt_const0 = 0xfb01;
    const int16_t i_filt_const1 = 0x1414;
    const int16_t i_filt_const2 = 0x1fb;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7, src8;
    __m256i src10_h, src32_h, src54_h, src76_h;
    __m256i src21_h, src43_h, src65_h, src87_h;
    __m256i src10_l, src32_l, src54_l, src76_l;
    __m256i src21_l, src43_l, src65_l, src87_l;
    __m256i out10_h, out32_h, out10_l, out32_l;
    __m256i res10_h, res32_h, res10_l, res32_l;
    __m256i tmp10_h, tmp32_h, tmp10_l, tmp32_l;
    __m256i filt0, filt1, filt2;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_src_stride_x4 = i_src_stride << 2;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;

    u_h4w = i_height % 4;
    filt0 = __lasx_xvreplgr2vr_h( i_filt_const0 );
    filt1 = __lasx_xvreplgr2vr_h( i_filt_const1 );
    filt2 = __lasx_xvreplgr2vr_h( i_filt_const2 );

    src0 = __lasx_xvld( p_src, 0 );
    p_src += i_src_stride;
    DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2,
               p_src, i_src_stride_x3, src1, src2, src3, src4 );
    p_src += i_src_stride_x4;

    src0 = __lasx_xvxori_b( src0, 128 );
    DUP4_ARG2( __lasx_xvxori_b, src1, 128, src2, 128, src3, 128, src4, 128,
               src1, src2, src3, src4 );

    src10_l = __lasx_xvilvl_b( src1, src0 );
    src10_h = __lasx_xvilvh_b( src1, src0 );
    src21_l = __lasx_xvilvl_b( src2, src1 );
    src21_h = __lasx_xvilvh_b( src2, src1 );
    src32_l = __lasx_xvilvl_b( src3, src2 );
    src32_h = __lasx_xvilvh_b( src3, src2 );
    src43_l = __lasx_xvilvl_b( src4, src3 );
    src43_h = __lasx_xvilvh_b( src4, src3 );
    res10_h = __lasx_xvpermi_q( src21_h, src10_h, 0x20 );
    res32_h = __lasx_xvpermi_q( src43_h, src32_h, 0x20 );
    res10_l = __lasx_xvpermi_q( src21_l, src10_l, 0x20 );
    res32_l = __lasx_xvpermi_q( src43_l, src32_l, 0x20 );

    for( u_loop_cnt = ( i_height >> 2 ); u_loop_cnt--; )
    {
        DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2,
                   p_src, i_src_stride_x3, src5, src6, src7, src8 );
        p_src += i_src_stride_x4;

        DUP4_ARG2( __lasx_xvxori_b, src5, 128, src6, 128, src7, 128, src8, 128, src5,
                   src6, src7, src8 );
        src54_l = __lasx_xvilvl_b( src5, src4 );
        src54_h = __lasx_xvilvh_b( src5, src4 );
        src65_l = __lasx_xvilvl_b( src6, src5 );
        src65_h = __lasx_xvilvh_b( src6, src5 );
        src76_l = __lasx_xvilvl_b( src7, src6 );
        src76_h = __lasx_xvilvh_b( src7, src6 );
        src87_l = __lasx_xvilvl_b( src8, src7 );
        src87_h = __lasx_xvilvh_b( src8, src7 );
        tmp10_h = __lasx_xvpermi_q( src65_h, src54_h, 0x20 );
        tmp32_h = __lasx_xvpermi_q( src87_h, src76_h, 0x20 );
        tmp10_l = __lasx_xvpermi_q( src65_l, src54_l, 0x20 );
        tmp32_l = __lasx_xvpermi_q( src87_l, src76_l, 0x20 );

        out10_h = __lasx_xvdp2_h_b( res10_h, filt0 );
        out10_h = __lasx_xvdp2add_h_b( out10_h, res32_h, filt1 );
        out10_h = __lasx_xvdp2add_h_b( out10_h, tmp10_h, filt2 );


        out32_h = __lasx_xvdp2_h_b( res32_h, filt0 );
        out32_h = __lasx_xvdp2add_h_b( out32_h, tmp10_h, filt1 );
        out32_h = __lasx_xvdp2add_h_b( out32_h, tmp32_h, filt2 );

        out10_l = __lasx_xvdp2_h_b( res10_l, filt0 );
        out10_l = __lasx_xvdp2add_h_b( out10_l, res32_l, filt1 );
        out10_l = __lasx_xvdp2add_h_b( out10_l, tmp10_l, filt2 );

        out32_l = __lasx_xvdp2_h_b( res32_l, filt0 );
        out32_l = __lasx_xvdp2add_h_b( out32_l, tmp10_l, filt1 );
        out32_l = __lasx_xvdp2add_h_b( out32_l, tmp32_l, filt2 );

        out10_l = __lasx_xvssrarni_b_h(out10_h, out10_l, 5);
        out32_l = __lasx_xvssrarni_b_h(out32_h, out32_l, 5);
        DUP2_ARG2( __lasx_xvxori_b, out10_l, 128, out32_l, 128, out10_l, out32_l );

        __lasx_xvstelm_d( out10_l, p_dst, 0, 0 );
        __lasx_xvstelm_d( out10_l, p_dst, 8, 1 );
        __lasx_xvstelm_d( out10_l, p_dst + i_dst_stride, 0, 2 );
        __lasx_xvstelm_d( out10_l, p_dst + i_dst_stride, 8, 3 );
        p_dst += i_dst_stride_x2;
        __lasx_xvstelm_d( out32_l, p_dst, 0, 0 );
        __lasx_xvstelm_d( out32_l, p_dst, 8, 1 );
        __lasx_xvstelm_d( out32_l, p_dst + i_dst_stride, 0, 2 );
        __lasx_xvstelm_d( out32_l, p_dst + i_dst_stride, 8, 3 );
        p_dst += i_dst_stride_x2;

        res10_h = tmp10_h;
        res32_h = tmp32_h;
        res10_l = tmp10_l;
        res32_l = tmp32_l;
        src4 = src8;
    }

    for( u_loop_cnt = u_h4w; u_loop_cnt--; )
    {
        src5 = __lasx_xvld( p_src, 0 );
        p_src += i_src_stride;
        src5 = __lasx_xvxori_b( src5, 128 );
        src54_h = __lasx_xvilvl_b( src5, src4 );
        src54_l = __lasx_xvilvh_b( src5, src4 );
        out10_h = __lasx_xvdp2_h_b( src10_h, filt0 );
        out10_h = __lasx_xvdp2add_h_b( out10_h, src32_h, filt1 );
        out10_h = __lasx_xvdp2add_h_b( out10_h, src54_h, filt2 );

        out10_l = __lasx_xvdp2_h_b( src10_l, filt0 );
        out10_l = __lasx_xvdp2add_h_b( out10_l, src32_l, filt1 );
        out10_l = __lasx_xvdp2add_h_b( out10_l, src54_l, filt2 );
        out10_l = __lasx_xvssrarni_b_h(out10_h, out10_l, 5);
        out10_l = __lasx_xvxori_b( out10_l, 128 );
        __lasx_xvstelm_d( out10_l, p_dst, 0, 0 );
        __lasx_xvstelm_d( out10_l, p_dst, 8, 1 );
        p_dst += i_dst_stride;

        src10_h = src21_h;
        src32_h = src43_h;
        src10_l = src21_l;
        src32_l = src43_l;

        src4 = src5;
    }
}

#define LASX_HORZ_FILTER_SH( in, mask0, mask1, mask2 )         \
( {                                                            \
    __m256i out0_m;                                            \
    __m256i tmp0_m, tmp1_m;                                    \
                                                               \
    tmp0_m = __lasx_xvshuf_b(in, in, mask0);                   \
    out0_m = __lasx_xvhaddw_h_b( tmp0_m, tmp0_m );             \
                                                               \
    tmp0_m = __lasx_xvshuf_b(in, in, mask1);                   \
    out0_m = __lasx_xvdp2add_h_b( out0_m, minus5b, tmp0_m );   \
                                                               \
    tmp1_m = __lasx_xvshuf_b(in, in, mask2);                   \
    out0_m = __lasx_xvdp2add_h_b( out0_m, plus20b, tmp1_m );   \
                                                               \
    out0_m;                                                    \
} )

#define LASX_CALC_DPADD_H_6PIX_2COEFF_SH( in0, in1, in2, in3, in4, in5 )   \
( {                                                                        \
    __m256i tmp0_m, tmp1_m;                                                \
    __m256i out0_m, out1_m, out2_m, out3_m;                                \
                                                                           \
    tmp0_m = __lasx_xvilvh_h( in5, in0 );                                  \
    tmp1_m = __lasx_xvilvl_h( in5, in0 );                                  \
                                                                           \
    tmp0_m = __lasx_xvhaddw_w_h( tmp0_m, tmp0_m );                         \
    tmp1_m = __lasx_xvhaddw_w_h( tmp1_m, tmp1_m );                         \
                                                                           \
    out0_m = __lasx_xvilvh_h( in1, in4 );                                  \
    out1_m = __lasx_xvilvl_h( in1, in4 );                                  \
    DUP2_ARG3( __lasx_xvdp2add_w_h, tmp0_m, out0_m, minus5h, tmp1_m,       \
               out1_m, minus5h, tmp0_m, tmp1_m );                          \
    out2_m = __lasx_xvilvh_h( in2, in3 );                                  \
    out3_m = __lasx_xvilvl_h( in2, in3 );                                  \
    DUP2_ARG3( __lasx_xvdp2add_w_h, tmp0_m, out2_m, plus20h, tmp1_m,       \
               out3_m, plus20h, tmp0_m, tmp1_m );                          \
                                                                           \
    out0_m = __lasx_xvssrarni_h_w(tmp0_m, tmp1_m, 10);                     \
    out0_m = __lasx_xvsat_h(out0_m, 7);                                    \
                                                                           \
    out0_m;                                                                \
} )

static void avc_luma_mid_16w_lasx( uint8_t *p_src, int32_t i_src_stride,
                                   uint8_t *p_dst, int32_t i_dst_stride,
                                   int32_t i_height )
{
    uint32_t u_loop_cnt, u_h4w;
    int32_t minus = -5, plus = 20;
    __m256i src0, src1, src2, src3, src4;
    __m256i src5, src6, src7, src8;
    __m256i mask0, mask1, mask2;
    __m256i dst0, dst1, dst2, dst3;
    __m256i out0, out1;
    __m256i minus5b, plus20b, minus5h, plus20h;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_src_stride_x4 = i_src_stride << 2;
    int32_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;

    minus5b = __lasx_xvreplgr2vr_b( minus );
    plus20b = __lasx_xvreplgr2vr_b( plus );
    minus5h = __lasx_xvreplgr2vr_h( minus );
    plus20h = __lasx_xvreplgr2vr_h( plus );

    u_h4w = i_height & 3;
    mask0 = __lasx_xvld( pu_luma_mask_arr, 0 );
    mask1 = __lasx_xvld( &pu_luma_mask_arr[32], 0 );
    mask2 = __lasx_xvld( &pu_luma_mask_arr[64], 0 );

    src0 = __lasx_xvld( p_src, 0 );
    p_src += i_src_stride;
    DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2,
               p_src, i_src_stride_x3, src1, src2, src3, src4 );
    p_src += i_src_stride_x4;
    src0 = __lasx_xvpermi_d( src0, 0x94);
    src1 = __lasx_xvpermi_d( src1, 0x94);
    src2 = __lasx_xvpermi_d( src2, 0x94);
    src3 = __lasx_xvpermi_d( src3, 0x94);
    src4 = __lasx_xvpermi_d( src4, 0x94);

    src0 = __lasx_xvxori_b( src0, 128 );
    DUP4_ARG2( __lasx_xvxori_b, src1, 128, src2, 128, src3, 128, src4, 128, src1, src2,
               src3, src4 );

    src0 = LASX_HORZ_FILTER_SH( src0, mask0, mask1, mask2 );
    src1 = LASX_HORZ_FILTER_SH( src1, mask0, mask1, mask2 );
    src2 = LASX_HORZ_FILTER_SH( src2, mask0, mask1, mask2 );
    src3 = LASX_HORZ_FILTER_SH( src3, mask0, mask1, mask2 );
    src4 = LASX_HORZ_FILTER_SH( src4, mask0, mask1, mask2 );

    for( u_loop_cnt = ( i_height >> 2 ); u_loop_cnt--; )
    {
        DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src,
                   i_src_stride_x2, p_src, i_src_stride_x3, src5, src6, src7, src8 );
        p_src += i_src_stride_x4;
        src5 = __lasx_xvpermi_d( src5, 0x94);
        src6 = __lasx_xvpermi_d( src6, 0x94);
        src7 = __lasx_xvpermi_d( src7, 0x94);
        src8 = __lasx_xvpermi_d( src8, 0x94);

        DUP4_ARG2( __lasx_xvxori_b, src5, 128, src6, 128, src7, 128, src8, 128,
                   src5, src6, src7, src8 );

        src5 = LASX_HORZ_FILTER_SH( src5, mask0, mask1, mask2 );
        src6 = LASX_HORZ_FILTER_SH( src6, mask0, mask1, mask2 );
        src7 = LASX_HORZ_FILTER_SH( src7, mask0, mask1, mask2 );
        src8 = LASX_HORZ_FILTER_SH( src8, mask0, mask1, mask2 );
        dst0 = LASX_CALC_DPADD_H_6PIX_2COEFF_SH( src0, src1, src2,
                                                 src3, src4, src5 );
        dst1 = LASX_CALC_DPADD_H_6PIX_2COEFF_SH( src1, src2, src3,
                                                 src4, src5, src6 );
        dst2 = LASX_CALC_DPADD_H_6PIX_2COEFF_SH( src2, src3, src4,
                                                 src5, src6, src7 );
        dst3 = LASX_CALC_DPADD_H_6PIX_2COEFF_SH( src3, src4, src5,
                                                 src6, src7, src8 );
        out0 = __lasx_xvpickev_b( dst1, dst0 );
        out1 = __lasx_xvpickev_b( dst3, dst2 );
        DUP2_ARG2( __lasx_xvxori_b, out0, 128, out1, 128, out0, out1 );
        __lasx_xvstelm_d( out0, p_dst, 0, 0 );
        __lasx_xvstelm_d( out0, p_dst, 8, 2 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( out0, p_dst, 0, 1 );
        __lasx_xvstelm_d( out0, p_dst, 8, 3 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( out1, p_dst, 0, 0 );
        __lasx_xvstelm_d( out1, p_dst, 8, 2 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( out1, p_dst, 0, 1 );
        __lasx_xvstelm_d( out1, p_dst, 8, 3 );
        p_dst += i_dst_stride;

        src3 = src7;
        src1 = src5;
        src5 = src4;
        src4 = src8;
        src2 = src6;
        src0 = src5;
    }

    for( u_loop_cnt = u_h4w; u_loop_cnt--; )
    {
        src5 = __lasx_xvld( p_src, 0 );
        p_src += i_src_stride;
        src5 = __lasx_xvpermi_d( src5, 0x94);
        src5 = __lasx_xvxori_b( src5, 128 );

        src5 = LASX_HORZ_FILTER_SH( src5, mask0, mask1, mask2 );
        dst0 = LASX_CALC_DPADD_H_6PIX_2COEFF_SH( src0, src1,
                                                 src2, src3,
                                                 src4, src5 );

        out0 = __lasx_xvpickev_b( dst0, dst0 );
        out0 = __lasx_xvxori_b( out0, 128 );
        __lasx_xvstelm_d( out0, p_dst, 0, 0);
        __lasx_xvstelm_d( out0, p_dst, 8, 2);
        p_dst += i_dst_stride;

        src0 = src1;
        src1 = src2;
        src2 = src3;
        src3 = src4;
        src4 = src5;
    }
}

static void avc_luma_hz_16w_lasx( uint8_t *p_src, int32_t i_src_stride,
                                  uint8_t *p_dst, int32_t i_dst_stride,
                                  int32_t i_height )
{
    uint32_t u_loop_cnt, u_h4w;
    int32_t minus = -5, plus = 20;
    __m256i src0, src1, src2, src3;
    __m256i mask0, mask1, mask2;
    __m256i minus5b, plus20b;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_src_stride_x4 = i_src_stride << 2;
    int32_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;

    minus5b = __lasx_xvreplgr2vr_b( minus );
    plus20b = __lasx_xvreplgr2vr_b( plus );

    u_h4w = i_height & 3;
    mask0 = __lasx_xvld( pu_luma_mask_arr, 0 );
    mask1 = __lasx_xvld( &pu_luma_mask_arr[32], 0 );
    mask2 = __lasx_xvld( &pu_luma_mask_arr[64], 0 );

    for( u_loop_cnt = ( i_height >> 2 ); u_loop_cnt--; )
    {
        DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2,
                   p_src, i_src_stride_x3, src0, src1, src2, src3 );
        p_src += i_src_stride_x4;
        src0 = __lasx_xvpermi_d( src0, 0x94);
        src1 = __lasx_xvpermi_d( src1, 0x94);
        src2 = __lasx_xvpermi_d( src2, 0x94);
        src3 = __lasx_xvpermi_d( src3, 0x94);

        DUP4_ARG2( __lasx_xvxori_b, src0, 128, src1, 128, src2, 128, src3, 128,
                   src0, src1, src2, src3 );

        src0 = LASX_HORZ_FILTER_SH( src0, mask0, mask1, mask2 );
        src1 = LASX_HORZ_FILTER_SH( src1, mask0, mask1, mask2 );
        src2 = LASX_HORZ_FILTER_SH( src2, mask0, mask1, mask2 );
        src3 = LASX_HORZ_FILTER_SH( src3, mask0, mask1, mask2 );

        src0 = __lasx_xvssrarni_b_h(src1, src0, 5);
        src1 = __lasx_xvssrarni_b_h(src3, src2, 5);
        DUP2_ARG2( __lasx_xvxori_b, src0, 128, src1, 128, src0, src1);
        __lasx_xvstelm_d( src0, p_dst, 0, 0 );
        __lasx_xvstelm_d( src0, p_dst, 8, 2 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( src0, p_dst, 0, 1);
        __lasx_xvstelm_d( src0, p_dst, 8, 3);
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( src1, p_dst, 0, 0 );
        __lasx_xvstelm_d( src1, p_dst, 8, 2 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( src1, p_dst, 0, 1 );
        __lasx_xvstelm_d( src1, p_dst, 8, 3 );
        p_dst += i_dst_stride;
    }

    for( u_loop_cnt = u_h4w; u_loop_cnt--; )
    {
        src0 = __lasx_xvld( p_src, 0 );
        p_src += i_src_stride;
        src0 = __lasx_xvpermi_d( src0, 0x94);

        src0 = __lasx_xvxori_b( src0, 128 );
        src0 = LASX_HORZ_FILTER_SH( src0, mask0, mask1, mask2 );
        src0 = __lasx_xvssrarni_b_h(src0, src0, 5);
        src0 = __lasx_xvxori_b( src0, 128 );
        __lasx_xvstelm_d( src0, p_dst, 0, 0 );
        __lasx_xvstelm_d( src0, p_dst, 8, 2 );
        p_dst += i_dst_stride;
    }
}

static void hpel_filter_lasx( uint8_t *p_dsth, uint8_t *p_dst_v,
                              uint8_t *p_dstc, uint8_t *p_src,
                              intptr_t i_stride, int32_t i_width,
                              int32_t i_height, int16_t *p_buf )
{
    for( int32_t i = 0; i < ( i_width >> 4 ); i++ )
    {
        avc_luma_vt_16w_lasx( p_src - 2 - ( 2 * i_stride ), i_stride,
                              p_dst_v - 2, i_stride, i_height );
        avc_luma_mid_16w_lasx( p_src - 2 - ( 2 * i_stride ) , i_stride,
                               p_dstc, i_stride, i_height );
        avc_luma_hz_16w_lasx( p_src - 2, i_stride, p_dsth, i_stride, i_height );

        p_src += 16;
        p_dst_v += 16;
        p_dsth += 16;
        p_dstc += 16;
    }
}

static inline void core_frame_init_lowres_core_lasx( uint8_t *p_src,
                                              int32_t i_src_stride,
                                              uint8_t *p_dst0,
                                              uint8_t *p_dst1,
                                              uint8_t *p_dst2,
                                              uint8_t *p_dst3,
                                              int32_t i_dst_stride,
                                              int32_t i_width,
                                              int32_t i_height )
{
    int32_t i_loop_width, i_loop_height, i_w16_mul;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7, src8;
    __m256i sld1_vec0, sld1_vec1, sld1_vec2, sld1_vec3, sld1_vec4, sld1_vec5;
    __m256i pckev_vec0, pckev_vec1, pckev_vec2;
    __m256i pckod_vec0, pckod_vec1, pckod_vec2;
    __m256i tmp0, tmp1, tmp2, tmp3;
    __m256i mask;

    mask = __lasx_xvld( pu_core_mask_arr, 0 );

    i_w16_mul = i_width - i_width % 16;
    for( i_loop_height = i_height; i_loop_height--; )
    {
        src0  = __lasx_xvld( p_src, 0 );
        DUP2_ARG2( __lasx_xvldx, p_src, i_src_stride, p_src, i_src_stride_x2, src1, src2 );
        p_src += 16;
        for( i_loop_width = 0; i_loop_width < ( i_w16_mul >> 4 ); i_loop_width++ )
        {
            src3  = __lasx_xvld( p_src, 0 );
            DUP2_ARG2( __lasx_xvldx, p_src, i_src_stride, p_src, i_src_stride_x2, src4, src5 );
            src6 = __lasx_xvpermi_q( src3, src3, 0x11 );
            src7 = __lasx_xvpermi_q( src4, src4, 0x11 );
            src8 = __lasx_xvpermi_q( src5, src5, 0x11 );
            p_src += 32;

            pckev_vec0 = __lasx_xvpickev_b( src3, src0 );
            pckod_vec0 = __lasx_xvpickod_b( src3, src0 );
            pckev_vec1 = __lasx_xvpickev_b( src4, src1 );
            pckod_vec1 = __lasx_xvpickod_b( src4, src1 );
            pckev_vec2 = __lasx_xvpickev_b( src5, src2 );
            pckod_vec2 = __lasx_xvpickod_b( src5, src2 );
            DUP4_ARG2( __lasx_xvavgr_bu, pckev_vec1, pckev_vec0, pckod_vec1, pckod_vec0,
                       pckev_vec2, pckev_vec1, pckod_vec2, pckod_vec1, tmp0, tmp1, tmp2,
                       tmp3 );
            DUP2_ARG2( __lasx_xvavgr_bu, tmp1, tmp0, tmp3, tmp2, tmp0, tmp1 );
            __lasx_xvstelm_d( tmp0, p_dst0, 0, 0 );
            __lasx_xvstelm_d( tmp0, p_dst0, 8, 1 );
            __lasx_xvstelm_d( tmp1, p_dst2, 0, 0 );
            __lasx_xvstelm_d( tmp1, p_dst2, 8, 1 );

            DUP2_ARG3( __lasx_xvshuf_b, src3, src0, mask, src4, src1,
                       mask, sld1_vec0, sld1_vec1 );
            DUP2_ARG3( __lasx_xvshuf_b, src5, src2, mask, src6, src3,
                       mask, sld1_vec2, sld1_vec3 );
            DUP2_ARG3( __lasx_xvshuf_b, src7, src4, mask, src8, src5,
                       mask, sld1_vec4, sld1_vec5 );
            pckev_vec0 = __lasx_xvpickod_b( sld1_vec3, sld1_vec0 );
            pckev_vec1 = __lasx_xvpickod_b( sld1_vec4, sld1_vec1 );
            pckev_vec2 = __lasx_xvpickod_b( sld1_vec5, sld1_vec2 );
            DUP4_ARG2( __lasx_xvavgr_bu, pckev_vec1, pckev_vec0, pckod_vec1, pckod_vec0,
                       pckev_vec2, pckev_vec1, pckod_vec2, pckod_vec1, tmp0, tmp1, tmp2,
                       tmp3 );
            DUP2_ARG2( __lasx_xvavgr_bu, tmp1, tmp0, tmp3, tmp2, tmp0, tmp1 );
            __lasx_xvstelm_d( tmp0, p_dst1, 0, 0 );
            __lasx_xvstelm_d( tmp0, p_dst1, 8, 1 );
            __lasx_xvstelm_d( tmp1, p_dst3, 0, 0 );
            __lasx_xvstelm_d( tmp1, p_dst3, 8, 1 );

            src0 = src6;
            src1 = src7;
            src2 = src8;
            p_dst0 += 16;
            p_dst1 += 16;
            p_dst2 += 16;
            p_dst3 += 16;
        }

        for( i_loop_width = i_w16_mul; i_loop_width < i_width;
             i_loop_width += 8 )
        {
            src3  = __lasx_xvld( p_src, 0 );
            DUP2_ARG2( __lasx_xvldx, p_src, i_src_stride, p_src, i_src_stride_x2, src4, src5 );
            p_src += 16;

            pckev_vec0 = __lasx_xvpickev_b( src3, src0 );
            pckod_vec0 = __lasx_xvpickod_b( src3, src0 );
            pckev_vec1 = __lasx_xvpickev_b( src4, src1 );
            pckod_vec1 = __lasx_xvpickod_b( src4, src1 );
            pckev_vec2 = __lasx_xvpickev_b( src5, src2 );
            pckod_vec2 = __lasx_xvpickod_b( src5, src2 );
            DUP4_ARG2( __lasx_xvhsubw_hu_bu, pckev_vec1, pckev_vec0, pckod_vec1,
                       pckod_vec0, pckev_vec2, pckev_vec1, pckod_vec2, pckod_vec1,
                       tmp0, tmp1, tmp2, tmp3 );
            DUP2_ARG2( __lasx_xvhsubw_hu_bu, tmp1, tmp0, tmp3, tmp2, tmp0, tmp1 );
            __lasx_xvstelm_d( tmp0, p_dst0, 0, 0 );
            __lasx_xvstelm_d( tmp1, p_dst2, 0, 0 );

            DUP2_ARG3( __lasx_xvshuf_b, src3, src0, src4, src1, mask,
                       mask, sld1_vec0, sld1_vec1 );
            DUP2_ARG3( __lasx_xvshuf_b, src5, src2, src3, src3, mask,
                       mask, sld1_vec2, sld1_vec3 );
            DUP2_ARG3( __lasx_xvshuf_b, src4, src4, src5, src5, mask,
                       mask, sld1_vec4, sld1_vec5 );
            pckev_vec0 = __lasx_xvpickod_b( sld1_vec3, sld1_vec0 );
            pckev_vec1 = __lasx_xvpickod_b( sld1_vec4, sld1_vec1 );
            pckev_vec2 = __lasx_xvpickod_b( sld1_vec5, sld1_vec2 );
            DUP4_ARG2( __lasx_xvhsubw_hu_bu, pckev_vec1, pckev_vec0, pckod_vec1,
                       pckod_vec0, pckev_vec2, pckev_vec1, pckod_vec2, pckod_vec1,
                       tmp0, tmp1, tmp2, tmp3 );
            DUP2_ARG2( __lasx_xvhsubw_hu_bu, tmp1, tmp0, tmp3, tmp2, tmp0, tmp1 );
            __lasx_xvstelm_d( tmp0, p_dst1, 0, 0 );
            __lasx_xvstelm_d( tmp1, p_dst3, 0, 0 );
            p_dst0 += 8;
            p_dst1 += 8;
            p_dst2 += 8;
            p_dst3 += 8;
        }

        p_src += ( ( i_src_stride << 1 ) - ( ( i_width << 1 ) + 16 ) );
        p_dst0 += ( i_dst_stride - i_width );
        p_dst1 += ( i_dst_stride - i_width );
        p_dst2 += ( i_dst_stride - i_width );
        p_dst3 += ( i_dst_stride - i_width );
    }
}

static void frame_init_lowres_core_lasx( uint8_t *p_src, uint8_t *p_dst0,
                                         uint8_t *p_dst1, uint8_t *p_dst2,
                                         uint8_t *p_dst3, intptr_t i_src_stride,
                                         intptr_t i_dst_stride, int32_t i_width,
                                         int32_t i_height )
{
    core_frame_init_lowres_core_lasx( p_src, i_src_stride, p_dst0,
                                      p_dst1, p_dst2, p_dst3,
                                      i_dst_stride, i_width, i_height );
}
static void core_plane_copy_deinterleave_lasx( uint8_t *p_src,
                                               int32_t i_src_stride,
                                               uint8_t *p_dst0,
                                               int32_t dst0_stride,
                                               uint8_t *p_dst1,
                                               int32_t dst1_stride,
                                               int32_t i_width,
                                               int32_t i_height )
{
    int32_t i_loop_width, i_loop_height;
    int32_t i_w_mul4, i_w_mul16, i_w_mul32, i_h4w;
    __m256i in0, in1, in2, in3, in4, in5, in6, in7;
    __m256i vec_pckev0, vec_pckev1, vec_pckev2, vec_pckev3;
    __m256i vec_pckev4, vec_pckev5, vec_pckev6, vec_pckev7;
    __m256i vec_pckod0, vec_pckod1, vec_pckod2, vec_pckod3;
    __m256i vec_pckod4, vec_pckod5, vec_pckod6, vec_pckod7;
    uint8_t *p_dst, *p_dstA, *p_dstB, *p_srcA;
    int32_t dst0_stride_x2 = dst0_stride << 1;
    int32_t dst0_stride_x3 = dst0_stride_x2 + dst0_stride;
    int32_t dst0_stride_x4 = dst0_stride << 2;
    int32_t dst0_stride_x5 = dst0_stride_x4 + dst0_stride;
    int32_t dst0_stride_x6 = dst0_stride_x4 + dst0_stride_x2;
    int32_t dst0_stride_x7 = dst0_stride_x4 + dst0_stride_x3;
    int32_t dst1_stride_x2 = dst1_stride << 1;
    int32_t dst1_stride_x3 = dst1_stride_x2 + dst1_stride;
    int32_t dst1_stride_x4 = dst1_stride << 2;
    int32_t dst1_stride_x5 = dst1_stride_x4 + dst1_stride;
    int32_t dst1_stride_x6 = dst1_stride_x4 + dst1_stride_x2;
    int32_t dst1_stride_x7 = dst1_stride_x4 + dst1_stride_x3;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;
    int32_t i_src_stride_x4 = i_src_stride << 2;
    int32_t i_src_stride_x5 = i_src_stride_x4 + i_src_stride;
    int32_t i_src_stride_x6 = i_src_stride_x4 + i_src_stride_x2;
    int32_t i_src_stride_x7 = i_src_stride_x4 + i_src_stride_x3;

    i_w_mul32 = i_width - ( i_width & 31 );
    i_w_mul16 = i_width - ( i_width & 15 );
    i_w_mul4 = i_width - ( i_width & 3 );
    i_h4w = i_height - ( i_height & 7 );

    for( i_loop_height = ( i_h4w >> 3 ); i_loop_height--; )
    {
        for( i_loop_width = ( i_w_mul32 >> 5 ); i_loop_width--; )
        {
            DUP4_ARG2(__lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src,
                      i_src_stride_x2, p_src, i_src_stride_x3, in0, in1, in2, in3);
            DUP4_ARG2(__lasx_xvldx, p_src, i_src_stride_x4, p_src, i_src_stride_x5, p_src,
                      i_src_stride_x6, p_src, i_src_stride_x7, in4, in5, in6, in7);
            p_src += 32;
            DUP4_ARG2( __lasx_xvpickev_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckev0, vec_pckev1, vec_pckev2, vec_pckev3 );
            DUP4_ARG2( __lasx_xvpickod_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckod0, vec_pckod1, vec_pckod2, vec_pckod3 );

            DUP4_ARG2(__lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src,
                      i_src_stride_x2, p_src, i_src_stride_x3, in0, in1, in2, in3);
            DUP4_ARG2(__lasx_xvldx, p_src, i_src_stride_x4, p_src, i_src_stride_x5, p_src,
                      i_src_stride_x6, p_src, i_src_stride_x7, in4, in5, in6, in7);
            p_src += 32;
            DUP4_ARG2( __lasx_xvpickev_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckev4, vec_pckev5, vec_pckev6, vec_pckev7 );
            DUP4_ARG2( __lasx_xvpickod_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckod4, vec_pckod5, vec_pckod6, vec_pckod7 );

            in0 = __lasx_xvpermi_q( vec_pckev0, vec_pckev4, 0x02 );
            in1 = __lasx_xvpermi_q( vec_pckev0, vec_pckev4, 0x13 );
            in2 = __lasx_xvpermi_q( vec_pckev1, vec_pckev5, 0x02 );
            in3 = __lasx_xvpermi_q( vec_pckev1, vec_pckev5, 0x13 );
            in4 = __lasx_xvpermi_q( vec_pckev2, vec_pckev6, 0x02 );
            in5 = __lasx_xvpermi_q( vec_pckev2, vec_pckev6, 0x13 );
            in6 = __lasx_xvpermi_q( vec_pckev3, vec_pckev7, 0x02 );
            in7 = __lasx_xvpermi_q( vec_pckev3, vec_pckev7, 0x13 );

            DUP4_ARG2( __lasx_xvilvl_d, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckev0, vec_pckev1, vec_pckev2, vec_pckev3 );
            DUP4_ARG2( __lasx_xvilvh_d, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckev4, vec_pckev5, vec_pckev6, vec_pckev7 );

            __lasx_xvst( vec_pckev0, p_dst0, 0 );
            __lasx_xvstx( vec_pckev4, p_dst0, dst0_stride );
            __lasx_xvstx( vec_pckev1, p_dst0, dst0_stride_x2 );
            __lasx_xvstx( vec_pckev5, p_dst0, dst0_stride_x3 );
            __lasx_xvstx( vec_pckev2, p_dst0, dst0_stride_x4 );
            __lasx_xvstx( vec_pckev6, p_dst0, dst0_stride_x5 );
            __lasx_xvstx( vec_pckev3, p_dst0, dst0_stride_x6 );
            __lasx_xvstx( vec_pckev7, p_dst0, dst0_stride_x7 );

            in0 = __lasx_xvpermi_q( vec_pckod0, vec_pckod4, 0x02 );
            in1 = __lasx_xvpermi_q( vec_pckod0, vec_pckod4, 0x13 );
            in2 = __lasx_xvpermi_q( vec_pckod1, vec_pckod5, 0x02 );
            in3 = __lasx_xvpermi_q( vec_pckod1, vec_pckod5, 0x13 );
            in4 = __lasx_xvpermi_q( vec_pckod2, vec_pckod6, 0x02 );
            in5 = __lasx_xvpermi_q( vec_pckod2, vec_pckod6, 0x13 );
            in6 = __lasx_xvpermi_q( vec_pckod3, vec_pckod7, 0x02 );
            in7 = __lasx_xvpermi_q( vec_pckod3, vec_pckod7, 0x13 );

            DUP4_ARG2( __lasx_xvilvl_d, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckod0, vec_pckod1, vec_pckod2, vec_pckod3 );
            DUP4_ARG2( __lasx_xvilvh_d, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckod4, vec_pckod5, vec_pckod6, vec_pckod7 );

            __lasx_xvst( vec_pckod0, p_dst1, 0 );
            __lasx_xvstx( vec_pckod4, p_dst1, dst1_stride );
            __lasx_xvstx( vec_pckod1, p_dst1, dst1_stride_x2 );
            __lasx_xvstx( vec_pckod5, p_dst1, dst1_stride_x3 );
            __lasx_xvstx( vec_pckod2, p_dst1, dst1_stride_x4 );
            __lasx_xvstx( vec_pckod6, p_dst1, dst1_stride_x5 );
            __lasx_xvstx( vec_pckod3, p_dst1, dst1_stride_x6 );
            __lasx_xvstx( vec_pckod7, p_dst1, dst1_stride_x7 );

            p_dst0 += 32;
            p_dst1 += 32;
        }

        for( i_loop_width = ( ( i_width & 31 ) >> 4 ); i_loop_width--; )
        {
            DUP4_ARG2(__lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src,
                      i_src_stride_x2, p_src, i_src_stride_x3, in0, in1, in2, in3);
            DUP4_ARG2(__lasx_xvldx, p_src, i_src_stride_x4, p_src, i_src_stride_x5, p_src,
                      i_src_stride_x6, p_src, i_src_stride_x7, in4, in5, in6, in7);
            p_src += 32;
            DUP4_ARG2( __lasx_xvpickev_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckev0, vec_pckev1, vec_pckev2, vec_pckev3 );
            DUP4_ARG2( __lasx_xvpickod_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckod0, vec_pckod1, vec_pckod2, vec_pckod3 );

            __lasx_xvstelm_d( vec_pckev0, p_dst0, 0, 0 );
            __lasx_xvstelm_d( vec_pckev0, p_dst0, 8, 2 );
            p_dst = p_dst0 + dst0_stride;
            __lasx_xvstelm_d( vec_pckev0, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckev0, p_dst, 8, 3 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckev1, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckev1, p_dst, 8, 2 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckev1, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckev1, p_dst, 8, 3 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckev2, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckev2, p_dst, 8, 2 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckev2, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckev2, p_dst, 8, 3 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckev3, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckev3, p_dst, 8, 2 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckev3, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckev3, p_dst, 8, 3 );

            __lasx_xvstelm_d( vec_pckod0, p_dst1, 0, 0 );
            __lasx_xvstelm_d( vec_pckod0, p_dst1, 8, 2 );
            p_dst = p_dst1 + dst0_stride;
            __lasx_xvstelm_d( vec_pckod0, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckod0, p_dst, 8, 3 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckod1, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckod1, p_dst, 8, 2 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckod1, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckod1, p_dst, 8, 3 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckod2, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckod2, p_dst, 8, 2 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckod2, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckod2, p_dst, 8, 3 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckod3, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckod3, p_dst, 8, 2 );
            p_dst = p_dst + dst0_stride;
            __lasx_xvstelm_d( vec_pckod3, p_dst, 0, 1 );
            __lasx_xvstelm_d( vec_pckod3, p_dst, 8, 3 );

            p_dst0 += 16;
            p_dst1 += 16;
        }

        for( i_loop_width = ( ( i_width & 15 ) >> 3 ); i_loop_width--; )
        {
            DUP4_ARG2(__lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src,
                      i_src_stride_x2, p_src, i_src_stride_x3, in0, in1, in2, in3);
            DUP4_ARG2(__lasx_xvldx, p_src, i_src_stride_x4, p_src, i_src_stride_x5, p_src,
                      i_src_stride_x6, p_src, i_src_stride_x7, in4, in5, in6, in7);
            p_src += 16;
            DUP4_ARG2( __lasx_xvpickev_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckev0, vec_pckev1, vec_pckev2, vec_pckev3 );
            DUP4_ARG2( __lasx_xvpickod_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckod0, vec_pckod1, vec_pckod2, vec_pckod3 );

            __lasx_xvstelm_d( vec_pckev0, p_dst0, 0, 0 );
            __lasx_xvstelm_d( vec_pckev0, p_dst0 + dst0_stride, 0, 1 );
            p_dst = p_dst0 + dst0_stride_x2;
            __lasx_xvstelm_d( vec_pckev1, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckev1, p_dst + dst0_stride, 0, 1 );
            p_dst = p_dst + dst0_stride_x2;
            __lasx_xvstelm_d( vec_pckev2, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckev2, p_dst + dst0_stride, 0, 1 );
            p_dst = p_dst + dst0_stride_x2;
            __lasx_xvstelm_d( vec_pckev3, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckev3, p_dst + dst0_stride, 0, 1 );

            __lasx_xvstelm_d( vec_pckod0, p_dst1, 0, 0 );
            __lasx_xvstelm_d( vec_pckod0, p_dst1 + dst0_stride, 0, 1 );
            p_dst = p_dst1 + dst1_stride_x2;
            __lasx_xvstelm_d( vec_pckod1, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckod1, p_dst + dst0_stride, 0, 1 );
            p_dst = p_dst + dst1_stride_x2;
            __lasx_xvstelm_d( vec_pckod2, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckod2, p_dst + dst0_stride, 0, 1 );
            p_dst = p_dst + dst1_stride_x2;
            __lasx_xvstelm_d( vec_pckod3, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_pckod3, p_dst + dst0_stride, 0, 1 );

            p_dst0 += 8;
            p_dst1 += 8;
        }


        for( i_loop_width = ( ( i_width & 7 ) >> 2 ); i_loop_width--; )
        {
            DUP4_ARG2(__lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src,
                      i_src_stride_x2, p_src, i_src_stride_x3, in0, in1, in2, in3);
            DUP4_ARG2(__lasx_xvldx, p_src, i_src_stride_x4, p_src, i_src_stride_x5, p_src,
                      i_src_stride_x6, p_src, i_src_stride_x7, in4, in5, in6, in7);
            p_src += 8;
            DUP4_ARG2( __lasx_xvpickev_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckev0, vec_pckev1, vec_pckev2, vec_pckev3 );
            DUP4_ARG2( __lasx_xvpickod_b, in1, in0, in3, in2, in5, in4, in7, in6,
                       vec_pckod0, vec_pckod1, vec_pckod2, vec_pckod3 );

            __lasx_xvstelm_w( vec_pckev0, p_dst0, 0, 0 );
            __lasx_xvstelm_w( vec_pckev0, p_dst0 + dst0_stride, 0, 2 );
            p_dst = p_dst0 + dst0_stride_x2;
            __lasx_xvstelm_w( vec_pckev1, p_dst, 0, 0 );
            __lasx_xvstelm_w( vec_pckev1, p_dst + dst0_stride, 0, 2 );
            p_dst = p_dst + dst0_stride_x2;
            __lasx_xvstelm_w( vec_pckev2, p_dst, 0, 0 );
            __lasx_xvstelm_w( vec_pckev2, p_dst + dst0_stride, 0, 2 );
            p_dst = p_dst + dst0_stride_x2;
            __lasx_xvstelm_w( vec_pckev3, p_dst, 0, 0 );
            __lasx_xvstelm_w( vec_pckev3, p_dst + dst0_stride, 0, 2 );

            __lasx_xvstelm_w( vec_pckod0, p_dst1, 0, 0 );
            __lasx_xvstelm_w( vec_pckod0, p_dst1 + dst0_stride, 0, 2 );
            p_dst = p_dst1 + dst1_stride_x2;
            __lasx_xvstelm_w( vec_pckod1, p_dst, 0, 0 );
            __lasx_xvstelm_w( vec_pckod1, p_dst + dst0_stride, 0, 2 );
            p_dst = p_dst + dst1_stride_x2;
            __lasx_xvstelm_w( vec_pckod2, p_dst, 0, 0 );
            __lasx_xvstelm_w( vec_pckod2, p_dst + dst0_stride, 0, 2 );
            p_dst = p_dst + dst1_stride_x2;
            __lasx_xvstelm_w( vec_pckod3, p_dst, 0, 0 );
            __lasx_xvstelm_w( vec_pckod3, p_dst + dst0_stride, 0, 2 );

            p_dst0 += 4;
            p_dst1 += 4;
        }

        for( i_loop_width = i_w_mul4; i_loop_width < i_width; i_loop_width++ )
        {
            p_dst0[0] = p_src[0];
            p_dst1[0] = p_src[1];

            p_dstA = p_dst0 + dst0_stride;
            p_dstB = p_dst1 + dst1_stride;
            p_srcA = p_src + i_src_stride;
            p_dstA[0] = p_srcA[0];
            p_dstB[0] = p_srcA[1];

            p_dstA += dst0_stride;
            p_dstB += dst1_stride;
            p_srcA += i_src_stride;
            p_dstA[0] = p_srcA[0];
            p_dstB[0] = p_srcA[1];

            p_dstA += dst0_stride;
            p_dstB += dst1_stride;
            p_srcA += i_src_stride;
            p_dstA[0] = p_srcA[0];
            p_dstB[0] = p_srcA[1];

            p_dstA += dst0_stride;
            p_dstB += dst1_stride;
            p_srcA += i_src_stride;
            p_dstA[0] = p_srcA[0];
            p_dstB[0] = p_srcA[1];

            p_dstA += dst0_stride;
            p_dstB += dst1_stride;
            p_srcA += i_src_stride;
            p_dstA[0] = p_srcA[0];
            p_dstB[0] = p_srcA[1];

            p_dstA += dst0_stride;
            p_dstB += dst1_stride;
            p_srcA += i_src_stride;
            p_dstA[0] = p_srcA[0];
            p_dstB[0] = p_srcA[1];

            p_dstA += dst0_stride;
            p_dstB += dst1_stride;
            p_srcA += i_src_stride;
            p_dstA[0] = p_srcA[0];
            p_dstB[0] = p_srcA[1];

            p_dst0 += 1;
            p_dst1 += 1;
            p_src += 2;
        }

        p_src += ( ( i_src_stride << 3 ) - ( i_width << 1 ) );
        p_dst0 += ( ( dst0_stride << 3 ) - i_width );
        p_dst1 += ( ( dst1_stride << 3) - i_width );
    }

    for( i_loop_height = i_h4w; i_loop_height < i_height; i_loop_height++ )
    {
        for( i_loop_width = ( i_w_mul16 >> 4 ); i_loop_width--; )
        {
            in0 = __lasx_xvld( p_src, 0 );
            p_src += 32;
            vec_pckev0 = __lasx_xvpickev_b( in0, in0 );
            vec_pckod0 = __lasx_xvpickod_b( in0, in0 );
            __lasx_xvstelm_d( vec_pckev0, p_dst0, 0, 0 );
            __lasx_xvstelm_d( vec_pckev0, p_dst0, 8, 2 );
            __lasx_xvstelm_d( vec_pckod0, p_dst1, 0, 0 );
            __lasx_xvstelm_d( vec_pckod0, p_dst1, 8, 2 );
            p_dst0 += 16;
            p_dst1 += 16;
        }

        for( i_loop_width = ( ( i_width & 15 ) >> 3 ); i_loop_width--; )
        {
            in0 = __lasx_xvld( p_src, 0 );
            p_src += 16;
            vec_pckev0 = __lasx_xvpickev_b( in0, in0 );
            vec_pckod0 = __lasx_xvpickod_b( in0, in0 );
            __lasx_xvstelm_d( vec_pckev0, p_dst0, 0, 0 );
            __lasx_xvstelm_d( vec_pckod0, p_dst1, 0, 0 );
            p_dst0 += 8;
            p_dst1 += 8;
        }

        for( i_loop_width = ( ( i_width & 7 ) >> 2 ); i_loop_width--; )
        {
            in0 = __lasx_xvld( p_src, 0 );
            p_src += 8;
            vec_pckev0 = __lasx_xvpickev_b( in0, in0 );
            vec_pckod0 = __lasx_xvpickod_b( in0, in0 );
            __lasx_xvstelm_w( vec_pckev0, p_dst0, 0, 0 );
            __lasx_xvstelm_w( vec_pckod0, p_dst1, 0, 0 );
            p_dst0 += 4;
            p_dst1 += 4;
        }

        for( i_loop_width = i_w_mul4; i_loop_width < i_width; i_loop_width++ )
        {
            p_dst0[0] = p_src[0];
            p_dst1[0] = p_src[1];
            p_dst0 += 1;
            p_dst1 += 1;
            p_src += 2;
        }

        p_src += ( ( i_src_stride ) - ( i_width << 1 ) );
        p_dst0 += ( ( dst0_stride ) - i_width );
        p_dst1 += ( ( dst1_stride ) - i_width );
    }
}

static void core_plane_copy_interleave_lasx( uint8_t *p_src0,
                                             int32_t i_src0_stride,
                                             uint8_t *p_src1,
                                             int32_t i_src1_stride,
                                             uint8_t *p_dst,
                                             int32_t i_dst_stride,
                                             int32_t i_width, int32_t i_height )
{
    int32_t i_loop_width, i_loop_height, i_w_mul8, i_h4w;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i vec_ilv_l0, vec_ilv_l1, vec_ilv_l2, vec_ilv_l3;
    __m256i vec_ilv_h0, vec_ilv_h1, vec_ilv_h2, vec_ilv_h3;
    uint8_t *p_dst_t, *p_srcA, *p_srcB;
    int32_t i_src0_stride_x2 = i_src0_stride << 1;
    int32_t i_src1_stride_x2 = i_src1_stride << 1;
    int32_t i_src0_stride_x3 = i_src0_stride_x2 + i_src0_stride;
    int32_t i_src1_stride_x3 = i_src1_stride_x2 + i_src1_stride;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_dst_stride_x3 = i_dst_stride_x2 + i_dst_stride;

    i_w_mul8 = i_width - ( i_width & 7 );
    i_h4w = i_height - ( i_height & 3 );

    for( i_loop_height = ( i_h4w >> 2 ); i_loop_height--; )
    {
        for( i_loop_width = ( i_width >> 5 ); i_loop_width--; )
        {
            DUP4_ARG2(__lasx_xvldx, p_src0, 0, p_src0, i_src0_stride, p_src0,
                      i_src0_stride_x2, p_src0, i_src0_stride_x3, src0, src1, src2, src3);
            DUP4_ARG2(__lasx_xvldx, p_src1, 0, p_src1, i_src1_stride, p_src1,
                      i_src1_stride_x2, p_src1, i_src1_stride_x3, src4, src5, src6, src7);

            DUP4_ARG2( __lasx_xvilvl_b, src4, src0, src5, src1, src6, src2, src7, src3,
                       vec_ilv_l0, vec_ilv_l1, vec_ilv_l2, vec_ilv_l3 );
            DUP4_ARG2( __lasx_xvilvh_b, src4, src0, src5, src1, src6, src2, src7, src3,
                       vec_ilv_h0, vec_ilv_h1, vec_ilv_h2, vec_ilv_h3 );

            src0 = __lasx_xvpermi_q( vec_ilv_l0, vec_ilv_h0, 0x02 );
            src1 = __lasx_xvpermi_q( vec_ilv_l1, vec_ilv_h1, 0x02 );
            src2 = __lasx_xvpermi_q( vec_ilv_l2, vec_ilv_h2, 0x02 );
            src3 = __lasx_xvpermi_q( vec_ilv_l3, vec_ilv_h3, 0x02 );

            src4 = __lasx_xvpermi_q( vec_ilv_l0, vec_ilv_h0, 0x13 );
            src5 = __lasx_xvpermi_q( vec_ilv_l1, vec_ilv_h1, 0x13 );
            src6 = __lasx_xvpermi_q( vec_ilv_l2, vec_ilv_h2, 0x13 );
            src7 = __lasx_xvpermi_q( vec_ilv_l3, vec_ilv_h3, 0x13 );

            __lasx_xvst( src0, p_dst, 0 );
            __lasx_xvstx( src1, p_dst, i_dst_stride );
            __lasx_xvstx( src2, p_dst, i_dst_stride_x2 );
            __lasx_xvstx( src3, p_dst, i_dst_stride_x3 );
            __lasx_xvst( src4, p_dst, 32 );
            __lasx_xvstx( src5, p_dst, 32 + i_dst_stride );
            __lasx_xvstx( src6, p_dst, 32 + i_dst_stride_x2 );
            __lasx_xvstx( src7, p_dst, 32 + i_dst_stride_x3 );

            p_src0 += 32;
            p_src1 += 32;
            p_dst += 64;
        }

        for( i_loop_width = ( ( i_width & 31 ) >> 4 ); i_loop_width--; )
        {
            DUP4_ARG2(__lasx_xvldx, p_src0, 0, p_src0, i_src0_stride, p_src0,
                      i_src0_stride_x2, p_src0, i_src0_stride_x3, src0, src1, src2, src3);
            DUP4_ARG2(__lasx_xvldx, p_src1, 0, p_src1, i_src1_stride, p_src1,
                      i_src1_stride_x2, p_src1, i_src1_stride_x3, src4, src5, src6, src7);
            DUP4_ARG2(__lasx_xvilvl_b, src4, src0, src5, src1, src6, src2, src7, src3,
                      vec_ilv_l0, vec_ilv_l1, vec_ilv_l2, vec_ilv_l3 );
            DUP4_ARG2(__lasx_xvilvh_b, src4, src0, src5, src1, src6, src2, src7, src3,
                      vec_ilv_h0, vec_ilv_h1, vec_ilv_h2, vec_ilv_h3 );

            vec_ilv_l0 = __lasx_xvpermi_q( vec_ilv_l0, vec_ilv_h0, 0x02 );
            vec_ilv_l1 = __lasx_xvpermi_q( vec_ilv_l1, vec_ilv_h1, 0x02 );
            vec_ilv_l2 = __lasx_xvpermi_q( vec_ilv_l2, vec_ilv_h2, 0x02 );
            vec_ilv_l3 = __lasx_xvpermi_q( vec_ilv_l3, vec_ilv_h3, 0x02 );

            __lasx_xvst( vec_ilv_l0, p_dst, 0 );
            __lasx_xvstx( vec_ilv_l1, p_dst, i_dst_stride );
            __lasx_xvstx( vec_ilv_l2, p_dst, i_dst_stride_x2 );
            __lasx_xvstx( vec_ilv_l3, p_dst, i_dst_stride_x3 );

            p_src0 += 16;
            p_src1 += 16;
            p_dst += 32;
        }

        for( i_loop_width = ( i_width & 15 ) >> 3; i_loop_width--; )
        {
            DUP4_ARG2(__lasx_xvldx, p_src0, 0, p_src0, i_src0_stride, p_src0,
                      i_src0_stride_x2, p_src0, i_src0_stride_x3, src0, src1, src2, src3);
            DUP4_ARG2(__lasx_xvldx, p_src1, 0, p_src1, i_src1_stride, p_src1,
                      i_src1_stride_x2, p_src1, i_src1_stride_x3, src4, src5, src6, src7);
            DUP4_ARG2(__lasx_xvilvl_b, src4, src0, src5, src1, src6, src2, src7, src3,
                      vec_ilv_l0, vec_ilv_l1, vec_ilv_l2, vec_ilv_l3 );

            __lasx_xvstelm_d( vec_ilv_l0, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_ilv_l0, p_dst, 8, 1 );
            p_dst_t = p_dst + i_dst_stride;
            __lasx_xvstelm_d( vec_ilv_l1, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_ilv_l1, p_dst, 8, 1 );
            p_dst_t = p_dst_t + i_dst_stride;
            __lasx_xvstelm_d( vec_ilv_l2, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_ilv_l2, p_dst, 8, 1 );
            p_dst_t = p_dst_t + i_dst_stride;
            __lasx_xvstelm_d( vec_ilv_l3, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_ilv_l3, p_dst, 8, 1 );

            p_src0 += 8;
            p_src1 += 8;
            p_dst += 16;
        }

        for( i_loop_width = i_w_mul8; i_loop_width < i_width; i_loop_width++ )
        {
            p_dst[0] = p_src0[0];
            p_dst[1] = p_src1[0];

            p_dst_t = p_dst + i_dst_stride;
            p_srcA = p_src0 + i_src0_stride;
            p_srcB = p_src1 + i_src1_stride;
            p_dst_t[0] = p_srcA[0];
            p_dst_t[1] = p_srcB[0];

            p_dst_t += i_dst_stride;
            p_srcA += i_src0_stride;
            p_srcB += i_src1_stride;
            p_dst_t[0] = p_srcA[0];
            p_dst_t[1] = p_srcB[0];

            p_dst_t += i_dst_stride;
            p_srcA += i_src0_stride;
            p_srcB += i_src1_stride;
            p_dst_t[0] = p_srcA[0];
            p_dst_t[1] = p_srcB[0];

            p_src0 += 1;
            p_src1 += 1;
            p_dst += 2;
        }

        p_src0 += ( ( i_src0_stride << 2 ) - i_width );
        p_src1 += ( ( i_src1_stride << 2 ) - i_width );
        p_dst += ( ( i_dst_stride << 2 ) - ( i_width << 1 ) );
    }

    for( i_loop_height = i_h4w; i_loop_height < i_height; i_loop_height++ )
    {
        for( i_loop_width = ( i_width >> 5 ); i_loop_width--; )
        {
            src0 = __lasx_xvld( p_src0, 0 );
            src4 = __lasx_xvld( p_src1, 0 );
            vec_ilv_h0 = __lasx_xvilvl_b( src4, src0 );
            vec_ilv_l0 = __lasx_xvilvh_b( src4, src0 );

            src0 = __lasx_xvpermi_q( vec_ilv_l0, vec_ilv_h0, 0x02 );
            src1 = __lasx_xvpermi_q( vec_ilv_l0, vec_ilv_h0, 0x13 );
            __lasx_xvst( src0, p_dst, 0 );
            __lasx_xvst( src0, p_dst, 32 );

            p_src0 += 32;
            p_src1 += 32;
            p_dst += 64;
        }

        for( i_loop_width = ( ( i_width &  31 )  >> 4 ); i_loop_width--; )
        {
            src0 = __lasx_xvld( p_src0, 0 );
            src4 = __lasx_xvld( p_src1, 0 );
            vec_ilv_h0 = __lasx_xvilvl_b( src4, src0 );
            vec_ilv_l0 = __lasx_xvilvh_b( src4, src0 );

            vec_ilv_l0 = __lasx_xvpermi_q( vec_ilv_l0, vec_ilv_h0, 0x02 );
            __lasx_xvst( vec_ilv_l0, p_dst, 0 );

            p_src0 += 16;
            p_src1 += 16;
            p_dst += 32;
        }

        for( i_loop_width = ( i_width & 15 ) >> 3; i_loop_width--; )
        {
            src0 = __lasx_xvld( p_src0, 0 );
            src4 = __lasx_xvld( p_src1, 0 );
            vec_ilv_l0 = __lasx_xvilvl_b( src4, src0 );
            __lasx_xvstelm_d( vec_ilv_l0, p_dst, 0, 0 );
            __lasx_xvstelm_d( vec_ilv_l0, p_dst, 8, 1 );

            p_src0 += 8;
            p_src1 += 8;
            p_dst += 16;
        }

        for( i_loop_width = i_w_mul8; i_loop_width < i_width; i_loop_width++ )
        {
            p_dst[0] = p_src0[0];
            p_dst[1] = p_src1[0];
            p_src0 += 1;
            p_src1 += 1;
            p_dst += 2;
        }

        p_src0 += ( i_src0_stride - i_width );
        p_src1 += ( i_src1_stride - i_width );
        p_dst += ( i_dst_stride - ( i_width << 1 ) );
    }
}

static void core_store_interleave_chroma_lasx( uint8_t *p_src0,
                                               int32_t i_src0_stride,
                                               uint8_t *p_src1,
                                               int32_t i_src1_stride,
                                               uint8_t *p_dst,
                                               int32_t i_dst_stride,
                                               int32_t i_height )
{
    int32_t i_loop_height, i_h4w;
    __m256i in0, in1, in2, in3, in4, in5, in6, in7;
    __m256i tmp0, tmp1, tmp2, tmp3;
    int32_t i_src0_stride_x2 = i_src0_stride << 1;
    int32_t i_src1_stride_x2 = i_src1_stride << 1;
    int32_t i_src0_stride_x4 = i_src0_stride << 2;
    int32_t i_src1_stride_x4 = i_src1_stride << 2;
    int32_t i_src0_stride_x3 = i_src0_stride_x2 + i_src0_stride;
    int32_t i_src1_stride_x3 = i_src1_stride_x2 + i_src1_stride;

    i_h4w = i_height & 3;
    for( i_loop_height = ( i_height >> 2 ); i_loop_height--; )
    {
        DUP4_ARG2( __lasx_xvldx, p_src0, 0, p_src0, i_src0_stride, p_src0,
                   i_src0_stride_x2, p_src0, i_src0_stride_x3, in0, in1, in2, in3 );
        p_src0 += i_src0_stride_x4;
        DUP4_ARG2( __lasx_xvldx, p_src1, 0, p_src1, i_src1_stride, p_src1,
                   i_src1_stride_x2, p_src1, i_src1_stride_x3, in4, in5, in6, in7 );
        p_src1 += i_src1_stride_x4;
        DUP4_ARG2( __lasx_xvilvl_b, in4, in0, in5, in1, in6, in2, in7, in3,
                   tmp0, tmp1, tmp2, tmp3 );

        __lasx_xvstelm_d( tmp0, p_dst, 0, 0 );
        __lasx_xvstelm_d( tmp0, p_dst, 8, 1 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( tmp1, p_dst, 0, 0 );
        __lasx_xvstelm_d( tmp1, p_dst, 8, 1 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( tmp2, p_dst, 0, 0 );
        __lasx_xvstelm_d( tmp2, p_dst, 8, 1 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( tmp3, p_dst, 0, 0 );
        __lasx_xvstelm_d( tmp3, p_dst, 8, 1 );
        p_dst += i_dst_stride;
    }

    for( i_loop_height = i_h4w; i_loop_height--; )
    {
        in0 = __lasx_xvld( p_src0, 0 );
        p_src0 += i_src0_stride;
        in1 = __lasx_xvld( p_src1, 0 );
        p_src1 += i_src1_stride;

        tmp0 = __lasx_xvilvl_b( in1, in0 );

        __lasx_xvstelm_d( tmp0, p_dst, 0, 0 );
        __lasx_xvstelm_d( tmp0, p_dst, 8, 1 );
        p_dst += i_dst_stride;
    }
}

static void plane_copy_deinterleave_lasx( uint8_t *p_dst0,
                                          intptr_t i_dst_stride0,
                                          uint8_t *p_dst1,
                                          intptr_t i_dst_stride1,
                                          uint8_t *p_src, intptr_t i_src_stride,
                                          int32_t i_width, int32_t i_height )
{
    core_plane_copy_deinterleave_lasx( p_src, i_src_stride,
                                       p_dst0, i_dst_stride0,
                                       p_dst1, i_dst_stride1,
                                       i_width, i_height );
}

static void load_deinterleave_chroma_fenc_lasx( uint8_t *p_dst, uint8_t *p_src,
                                                intptr_t i_src_stride,
                                                int32_t i_height )
{
    core_plane_copy_deinterleave_lasx( p_src, i_src_stride, p_dst, FENC_STRIDE,
                                       ( p_dst + ( FENC_STRIDE / 2 ) ),
                                       FENC_STRIDE, 8, i_height );
}

static void plane_copy_interleave_lasx( uint8_t *p_dst, intptr_t i_dst_stride,
                                       uint8_t *p_src0, intptr_t i_src_stride0,
                                       uint8_t *p_src1, intptr_t i_src_stride1,
                                       int32_t i_width, int32_t i_height )
{
    core_plane_copy_interleave_lasx( p_src0, i_src_stride0,
                                     p_src1, i_src_stride1,
                                     p_dst, i_dst_stride,
                                     i_width, i_height );
}

static void load_deinterleave_chroma_fdec_lasx( uint8_t *p_dst, uint8_t *p_src,
                                                intptr_t i_src_stride,
                                                int32_t i_height )
{
    core_plane_copy_deinterleave_lasx( p_src, i_src_stride, p_dst, FDEC_STRIDE,
                                       ( p_dst + ( FDEC_STRIDE / 2 ) ),
                                       FDEC_STRIDE, 8, i_height );
}

static void store_interleave_chroma_lasx( uint8_t *p_dst, intptr_t i_dst_stride,
                                          uint8_t *p_src0, uint8_t *p_src1,
                                          int32_t i_height )
{
    core_store_interleave_chroma_lasx( p_src0, FDEC_STRIDE, p_src1, FDEC_STRIDE,
                                       p_dst, i_dst_stride, i_height );
}

static void memzero_aligned_lasx( void *p_dst, size_t n )
{
    uint32_t i_tot32 = n >> 5;
    uint32_t i_remain = n - ( i_tot32 << 5 );
    int8_t i_cnt;
    __m256i zero = __lasx_xvldi( 0 );

    for ( i_cnt = i_tot32; i_cnt--; )
    {
        __lasx_xvst( zero, p_dst, 0 );
        p_dst += 32;
    }

    if( i_remain )
    {
        memset( p_dst, 0, i_remain );
    }
}

static void prefetch_ref_lasx( uint8_t *pix, intptr_t stride, int32_t parity )
{
    int32_t tmp = 0;
    uint8_t *pix_tmp = pix, *pix_tmp2 = pix;

    __asm__ volatile(
    "addi.d    %[parity],    %[parity],      -1                   \n\t"
    "addi.d    %[pix],       %[pix],         64                   \n\t"
    "and       %[parity],    %[parity],      %[stride]            \n\t"
    "slli.d    %[tmp],       %[parity],      3                    \n\t"
    "add.d     %[pix_tmp],   %[pix],         %[tmp]               \n\t"
    "slli.d    %[tmp],       %[stride],      1                    \n\t"
    "add.d     %[parity],    %[stride],      %[tmp]               \n\t"
    "preld     0,            %[pix_tmp],     0                    \n\t"
    "add.d     %[pix_tmp2],  %[pix_tmp],     %[stride]            \n\t"
    "preld     0,            %[pix_tmp2],    0                    \n\t"
    "add.d     %[pix_tmp2],  %[pix_tmp2],    %[stride]            \n\t"
    "preld     0,            %[pix_tmp2],    0                    \n\t"
    "add.d     %[pix_tmp],   %[pix_tmp],     %[parity]            \n\t"
    "preld     0,            %[pix_tmp],     0                    \n\t"
    "add.d     %[pix],       %[pix_tmp2],    %[tmp]               \n\t"
    "preld     0,            %[pix],         0                    \n\t"
    "add.d     %[pix_tmp],   %[pix],         %[stride]            \n\t"
    "preld     0,            %[pix_tmp],     0                    \n\t"
    "add.d     %[pix_tmp],   %[pix_tmp],     %[stride]            \n\t"
    "preld     0,            %[pix_tmp],     0                    \n\t"
    "add.d     %[pix],       %[pix],         %[parity]            \n\t"
    "preld     0,            %[pix],         0                    \n\t"
     : [tmp]"+&r"(tmp), [pix_tmp]"+&r"(pix_tmp),
       [pix_tmp2]"+&r"(pix_tmp2), [pix]"+&r"(pix),
       [parity]"+&r"(parity)
     : [stride]"r"(stride)
     :
    );
}

static void prefetch_fenc_422_lasx( uint8_t *pix_y, intptr_t stride_y,
                                    uint8_t *pix_uv, intptr_t stride_uv,
                                    int32_t mb_x )
{
    int64_t num1 = 0;
    int64_t num2 = 0;
    uint8_t *y_tmp = pix_y, *uv_tmp = pix_uv;

    __asm__ volatile(
    "andi      %[num1],      %[mb_x],         3                  \n\t"
    "mul.d     %[num1],      %[num1],         %[stride_y]        \n\t"
    "andi      %[mb_x],      %[mb_x],         6                  \n\t"
    "mul.d     %[num2],      %[mb_x],         %[stride_uv]       \n\t"
    "addi.d    %[pix_y],     %[pix_y],        64                 \n\t"
    "addi.d    %[pix_uv],    %[pix_uv],       64                 \n\t"
    "slli.d    %[num1],      %[num1],         2                  \n\t"
    "add.d     %[pix_y],     %[pix_y],        %[num1]            \n\t"
    "preld     0,            %[pix_y],        0                  \n\t"
    "add.d     %[y_tmp],     %[pix_y],        %[stride_y]        \n\t"
    "preld     0,            %[y_tmp],        0                  \n\t"
    "add.d     %[pix_y],     %[y_tmp],        %[stride_y]        \n\t"
    "preld     0,            %[pix_y],        0                  \n\t"
    "slli.d    %[num2],      %[num2],         2                  \n\t"
    "add.d     %[pix_y],     %[pix_y],        %[stride_y]        \n\t"
    "preld     0,            %[pix_y],        0                  \n\t"
    "add.d     %[pix_uv],    %[pix_uv],       %[num2]            \n\t"
    "preld     0,            %[pix_uv],       0                  \n\t"
    "add.d     %[uv_tmp],    %[pix_uv],       %[stride_uv]       \n\t"
    "preld     0,            %[uv_tmp],       0                  \n\t"
    "add.d     %[pix_uv],    %[uv_tmp],       %[stride_uv]       \n\t"
    "preld     0,            %[pix_uv],       0                  \n\t"
    "add.d     %[pix_uv],    %[pix_uv],       %[stride_uv]       \n\t"
    "preld     0,            %[pix_uv],       0                  \n\t"
     : [y_tmp]"+&r"(y_tmp),
       [uv_tmp]"+&r"(uv_tmp),
       [num2]"+&r"(num2),
       [num1]"+&r"(num1),
       [mb_x]"+&r"(mb_x),
       [pix_y]"+&r"(pix_y),
       [pix_uv]"+&r"(pix_uv)
     : [stride_y]"r"(stride_y), [stride_uv]"r"(stride_uv)
     :
    );
}

static void prefetch_fenc_420_lasx( uint8_t *pix_y, intptr_t stride_y,
                                    uint8_t *pix_uv, intptr_t stride_uv,
                                    int32_t mb_x )
{
    int64_t num1 = 0;
    int64_t num2 = 0;
    uint8_t *y_tmp = pix_y;

    __asm__ volatile(
    "andi      %[num1],      %[mb_x],         3                  \n\t"
    "mul.d     %[num1],      %[num1],         %[stride_y]        \n\t"
    "andi      %[mb_x],      %[mb_x],         6                  \n\t"
    "mul.d     %[num2],      %[mb_x],         %[stride_uv]       \n\t"
    "addi.d    %[pix_y],     %[pix_y],        64                 \n\t"
    "addi.d    %[pix_uv],    %[pix_uv],       64                 \n\t"
    "slli.d    %[num1],      %[num1],         2                  \n\t"
    "add.d     %[pix_y],     %[pix_y],        %[num1]            \n\t"
    "preld     0,            %[pix_y],        0                  \n\t"
    "add.d     %[y_tmp],     %[pix_y],        %[stride_y]        \n\t"
    "preld     0,            %[y_tmp],        0                  \n\t"
    "add.d     %[pix_y],     %[y_tmp],        %[stride_y]        \n\t"
    "preld     0,            %[pix_y],        0                  \n\t"
    "slli.d    %[num2],      %[num2],         2                  \n\t"
    "add.d     %[pix_y],     %[pix_y],        %[stride_y]        \n\t"
    "preld     0,            %[pix_y],        0                  \n\t"
    "add.d     %[pix_uv],    %[pix_uv],       %[num2]            \n\t"
    "preld     0,            %[pix_uv],       0                  \n\t"
    "add.d     %[pix_uv],    %[pix_uv],       %[stride_uv]       \n\t"
    "preld     0,            %[pix_uv],       0                  \n\t"
     : [y_tmp]"+&r"(y_tmp),
       [num2]"+&r"(num2),
       [num1]"+&r"(num1),
       [mb_x]"+&r"(mb_x),
       [pix_y]"+&r"(pix_y),
       [pix_uv]"+&r"(pix_uv)
     : [stride_y]"r"(stride_y), [stride_uv]"r"(stride_uv)
     :
    );
}

#endif // !HIGH_BIT_DEPTH

void x264_mc_init_loongarch( int32_t cpu, x264_mc_functions_t *pf  )
{
#if !HIGH_BIT_DEPTH
    if( cpu & X264_CPU_LASX )
    {
        pf->mc_luma = mc_luma_lasx;
        pf->mc_chroma = mc_chroma_lasx;
        pf->get_ref = get_ref_lasx;

        pf->avg[PIXEL_16x16]= pixel_avg_16x16_lasx;
        pf->avg[PIXEL_16x8] = pixel_avg_16x8_lasx;
        pf->avg[PIXEL_8x16] = pixel_avg_8x16_lasx;
        pf->avg[PIXEL_8x8] = pixel_avg_8x8_lasx;
        pf->avg[PIXEL_8x4] = pixel_avg_8x4_lasx;
        pf->avg[PIXEL_4x16] = pixel_avg_4x16_lasx;
        pf->avg[PIXEL_4x8] = pixel_avg_4x8_lasx;
        pf->avg[PIXEL_4x4] = pixel_avg_4x4_lasx;
        pf->avg[PIXEL_4x2] = pixel_avg_4x2_lasx;

        pf->weight = mc_weight_wtab_lasx;
        pf->offsetadd = mc_weight_wtab_lasx;
        pf->offsetsub = mc_weight_wtab_lasx;
        pf->weight_cache = weight_cache_lasx;

        pf->copy_16x16_unaligned = mc_copy_w16_lasx;
        pf->copy[PIXEL_16x16] = mc_copy_w16_lasx;
        pf->copy[PIXEL_8x8] = mc_copy_w8_lasx;
        pf->copy[PIXEL_4x4] = mc_copy_w4_lasx;

        pf->store_interleave_chroma = store_interleave_chroma_lasx;
        pf->load_deinterleave_chroma_fenc = load_deinterleave_chroma_fenc_lasx;
        pf->load_deinterleave_chroma_fdec = load_deinterleave_chroma_fdec_lasx;

        pf->plane_copy_interleave = plane_copy_interleave_lasx;
        pf->plane_copy_deinterleave = plane_copy_deinterleave_lasx;
        pf->plane_copy_deinterleave_yuyv = plane_copy_deinterleave_lasx;

        pf->hpel_filter = hpel_filter_lasx;
        pf->memcpy_aligned = x264_memcpy_aligned_lasx;
        pf->memzero_aligned = memzero_aligned_lasx;
        pf->frame_init_lowres_core = frame_init_lowres_core_lasx;

        pf->prefetch_fenc_420 = prefetch_fenc_420_lasx;
        pf->prefetch_fenc_422 = prefetch_fenc_422_lasx;
        pf->prefetch_ref  = prefetch_ref_lasx;
    }
#endif // !HIGH_BIT_DEPTH
}
