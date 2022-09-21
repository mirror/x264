/*****************************************************************************
 * pixel-c.c: loongarch pixel metrics
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
#include "pixel.h"
#include "predict.h"

#if !HIGH_BIT_DEPTH

#define LASX_LOAD_4(p_src, _stride, _stride2, _stride3, _src0, _src1, _src2, _src3)      \
{                                                                                        \
    _src0 = __lasx_xvld(p_src, 0);                                                       \
    _src1 = __lasx_xvldx(p_src, _stride);                                                \
    _src2 = __lasx_xvldx(p_src, _stride2);                                               \
    _src3 = __lasx_xvldx(p_src, _stride3);                                               \
}

static inline int32_t pixel_satd_4width_lasx( uint8_t *p_src, int32_t i_src_stride,
                                              uint8_t *p_ref, int32_t i_ref_stride,
                                              uint8_t i_height )
{
    int32_t cnt;
    uint32_t u_sum, sum1, sum2;
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i diff0, diff1, diff2, diff3;
    __m256i tmp0, tmp1;
    __m256i sum = __lasx_xvldi(0);
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;
    int32_t i_ref_stride_x3 = i_ref_stride_x2 + i_ref_stride;
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;

    for( cnt = i_height >> 3; cnt--; )
    {
        LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                     src0, src1, src2, src3 );
        p_src += i_src_stride_x4;
        LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                     diff0, diff1, diff2, diff3 );
        p_src += i_src_stride_x4;
        src0 = __lasx_xvilvl_w(src1, src0);
        src1 = __lasx_xvilvl_w(src3, src2);
        src2 = __lasx_xvilvl_w(diff1, diff0);
        src3 = __lasx_xvilvl_w(diff3, diff2);
        src0 = __lasx_xvpermi_q(src0, src2, 0x02);
        src1 = __lasx_xvpermi_q(src1, src3, 0x02);
        src0 = __lasx_xvilvl_d(src1, src0);


        LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                     ref0, ref1, ref2, ref3 );
        p_ref += i_ref_stride_x4;
        LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                     diff0, diff1, diff2, diff3 );
        p_ref += i_ref_stride_x4;
        ref0 = __lasx_xvilvl_w(ref1, ref0);
        ref1 = __lasx_xvilvl_w(ref3, ref2);
        ref2 = __lasx_xvilvl_w(diff1, diff0);
        ref3 = __lasx_xvilvl_w(diff3, diff2);
        ref0 = __lasx_xvpermi_q(ref0, ref2, 0x02);
        ref1 = __lasx_xvpermi_q(ref1, ref3, 0x02);
        ref0 = __lasx_xvilvl_d(ref1, ref0);

        diff0 = __lasx_xvsubwev_h_bu(src0, ref0);
        diff1 = __lasx_xvsubwod_h_bu(src0, ref0);

        tmp0 = __lasx_xvadd_h(diff0, diff1);
        tmp1 = __lasx_xvsub_h(diff0, diff1);

        diff0 = __lasx_xvpackev_h(tmp1, tmp0);
        diff1 = __lasx_xvpackod_h(tmp1, tmp0);

        tmp0 = __lasx_xvadd_h(diff0, diff1);
        tmp1 = __lasx_xvsub_h(diff0, diff1);

        diff0 = __lasx_xvpackev_w(tmp1, tmp0);
        diff1 = __lasx_xvpackod_w(tmp1, tmp0);

        tmp0 = __lasx_xvadd_h(diff0, diff1);
        tmp1 = __lasx_xvsub_h(diff0, diff1);

        diff0 = __lasx_xvpackev_d(tmp1, tmp0);
        diff1 = __lasx_xvpackod_d(tmp1, tmp0);

        tmp0 = __lasx_xvadd_h(diff0, diff1);
        tmp1 = __lasx_xvsub_h(diff0, diff1);

        diff0 = __lasx_xvpackev_d(tmp1, tmp0);
        diff1 = __lasx_xvpackod_d(tmp1, tmp0);

        diff0 = __lasx_xvadda_h(diff0, diff1);
        sum = __lasx_xvadd_h(sum, diff0);
    }
    sum = __lasx_xvhaddw_wu_hu( sum, sum );
    sum = __lasx_xvhaddw_du_wu( sum, sum );
    sum = __lasx_xvhaddw_qu_du( sum, sum );
    sum1 = __lasx_xvpickve2gr_wu(sum, 0);
    sum2 = __lasx_xvpickve2gr_wu(sum, 4);
    u_sum = sum1 + sum2;

    return ( u_sum >> 1 );
}

int32_t x264_pixel_satd_4x4_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 )
{
    uint32_t sum;
    intptr_t i_stride_2 = i_stride << 1;
    intptr_t i_stride2_2 = i_stride2 << 1;
    intptr_t i_stride_3 = i_stride_2 + i_stride;
    intptr_t i_stride2_3 = i_stride2_2 + i_stride2;
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i diff0, diff1, tmp0, tmp1;

    src0 = __lasx_xvld(p_pix1, 0);
    src1 = __lasx_xvldx(p_pix1, i_stride);
    src2 = __lasx_xvldx(p_pix1, i_stride_2);
    src3 = __lasx_xvldx(p_pix1, i_stride_3);
    ref0 = __lasx_xvld(p_pix2, 0);
    ref1 = __lasx_xvldx(p_pix2, i_stride2);
    ref2 = __lasx_xvldx(p_pix2, i_stride2_2);
    ref3 = __lasx_xvldx(p_pix2, i_stride2_3);

    src0 = __lasx_xvilvl_w(src1, src0);
    src1 = __lasx_xvilvl_w(src3, src2);
    ref0 = __lasx_xvilvl_w(ref1, ref0);
    ref1 = __lasx_xvilvl_w(ref3, ref2);
    src0 = __lasx_xvilvl_d(src1, src0);
    ref0 = __lasx_xvilvl_d(ref1, ref0);

    diff0 = __lasx_xvsubwev_h_bu(src0, ref0);
    diff1 = __lasx_xvsubwod_h_bu(src0, ref0);
    tmp0  = __lasx_xvadd_h(diff0, diff1);
    tmp1  = __lasx_xvsub_h(diff0, diff1);
    diff0 = __lasx_xvpackev_h(tmp1, tmp0);
    diff1 = __lasx_xvpackod_h(tmp1, tmp0);
    tmp0  = __lasx_xvadd_h(diff0, diff1);
    tmp1  = __lasx_xvsub_h(diff0, diff1);
    diff0 = __lasx_xvpackev_w(tmp1, tmp0);
    diff1 = __lasx_xvpackod_w(tmp1, tmp0);
    tmp0  = __lasx_xvadd_h(diff0, diff1);
    tmp1  = __lasx_xvsub_h(diff0, diff1);
    diff0 = __lasx_xvpackev_d(tmp1, tmp0);
    diff1 = __lasx_xvpackod_d(tmp1, tmp0);
    tmp0  = __lasx_xvadd_h(diff0, diff1);
    tmp1  = __lasx_xvsub_h(diff0, diff1);
    diff0 = __lasx_xvpackev_d(tmp1, tmp0);
    diff1 = __lasx_xvpackod_d(tmp1, tmp0);
    diff0 = __lasx_xvadda_h(diff0, diff1);
    diff0 = __lasx_xvhaddw_wu_hu( diff0, diff0 );
    diff0 = __lasx_xvhaddw_du_wu( diff0, diff0 );
    diff0 = __lasx_xvhaddw_qu_du( diff0, diff0 );
    sum   = __lasx_xvpickve2gr_wu(diff0, 0);
    return ( sum >> 1 );
}

static inline int32_t pixel_satd_8width_lasx( uint8_t *p_pix1, int32_t i_stride,
                                              uint8_t *p_pix2, int32_t i_stride2,
                                              uint8_t i_height )
{
    int32_t sum, i_8 = 8;
    uint32_t sum1, sum2;
    int64_t stride_2, stride_3, stride_4, stride2_2, stride2_3, stride2_4;

     __asm__ volatile (
    "slli.d         %[stride_2],      %[i_stride],          1                      \n\t"
    "slli.d         %[stride2_2],     %[i_stride2],         1                      \n\t"
    "add.d          %[stride_3],      %[i_stride],          %[stride_2]            \n\t"
    "add.d          %[stride2_3],     %[i_stride2],         %[stride2_2]           \n\t"
    "slli.d         %[stride_4],      %[stride_2],          1                      \n\t"
    "slli.d         %[stride2_4],     %[stride2_2],         1                      \n\t"
    "xvldi          $xr16,            0                                            \n\t"
    "1:                                                                            \n\t"
    "addi.d         %[i_height],      %[i_height],          -8                     \n\t"
    "vld            $vr0,             %[p_pix1],            0                      \n\t"
    "vldx           $vr1,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr2,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr3,             %[p_pix1],            %[stride_3]            \n\t"
    "add.d          %[p_pix1],        %[p_pix1],            %[stride_4]            \n\t"
    "vld            $vr4,             %[p_pix1],            0                      \n\t"
    "vldx           $vr5,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr6,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr7,             %[p_pix1],            %[stride_3]            \n\t"
    "add.d          %[p_pix1],        %[p_pix1],            %[stride_4]            \n\t"
    "vld            $vr8,             %[p_pix2],            0                      \n\t"
    "vldx           $vr9,             %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr10,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr11,            %[p_pix2],            %[stride2_3]           \n\t"
    "add.d          %[p_pix2],        %[p_pix2],            %[stride2_4]           \n\t"
    "vld            $vr12,            %[p_pix2],            0                      \n\t"
    "vldx           $vr13,            %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr14,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr15,            %[p_pix2],            %[stride2_3]           \n\t"
    "add.d          %[p_pix2],        %[p_pix2],            %[stride2_4]           \n\t"
    "vilvl.d        $vr0,             $vr1,                 $vr0                   \n\t"
    "vilvl.d        $vr1,             $vr3,                 $vr2                   \n\t"
    "vilvl.d        $vr2,             $vr5,                 $vr4                   \n\t"
    "vilvl.d        $vr3,             $vr7,                 $vr6                   \n\t"
    "xvpermi.q      $xr0,             $xr2,                 2                      \n\t"
    "xvpermi.q      $xr1,             $xr3,                 2                      \n\t"
    "vilvl.d        $vr2,             $vr9,                 $vr8                   \n\t"
    "vilvl.d        $vr3,             $vr11,                $vr10                  \n\t"
    "vilvl.d        $vr4,             $vr13,                $vr12                  \n\t"
    "vilvl.d        $vr5,             $vr15,                $vr14                  \n\t"
    "xvpermi.q      $xr2,             $xr4,                 2                      \n\t"
    "xvpermi.q      $xr3,             $xr5,                 2                      \n\t"
    "xvsubwev.h.bu  $xr4,             $xr0,                 $xr2                   \n\t"
    "xvsubwod.h.bu  $xr5,             $xr0,                 $xr2                   \n\t"
    "xvsubwev.h.bu  $xr6,             $xr1,                 $xr3                   \n\t"
    "xvsubwod.h.bu  $xr7,             $xr1,                 $xr3                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvpackev.h     $xr4,             $xr1,                 $xr0                   \n\t"
    "xvpackod.h     $xr5,             $xr1,                 $xr0                   \n\t"
    "xvpackev.h     $xr6,             $xr3,                 $xr2                   \n\t"
    "xvpackod.h     $xr7,             $xr3,                 $xr2                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvilvl.h       $xr4,             $xr1,                 $xr0                   \n\t"
    "xvilvh.h       $xr5,             $xr1,                 $xr0                   \n\t"
    "xvilvl.h       $xr6,             $xr3,                 $xr2                   \n\t"
    "xvilvh.h       $xr7,             $xr3,                 $xr2                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr0,                 $xr2                   \n\t"
    "xvadd.h        $xr5,             $xr1,                 $xr3                   \n\t"
    "xvsub.h        $xr6,             $xr0,                 $xr2                   \n\t"
    "xvsub.h        $xr7,             $xr1,                 $xr3                   \n\t"
    "xvadda.h       $xr0,             $xr4,                 $xr5                   \n\t"
    "xvadda.h       $xr1,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr0,             $xr0,                 $xr1                   \n\t"
    "xvadd.h        $xr16,            $xr16,                $xr0                   \n\t"
    "bge            %[i_height],      %[i_8],               1b                     \n\t"
    "2:                                                                            \n\t"
    "xvhaddw.wu.hu  $xr16,            $xr16,                $xr16                  \n\t"
    "xvhaddw.du.wu  $xr16,            $xr16,                $xr16                  \n\t"
    "xvhaddw.qu.du  $xr16,            $xr16,                $xr16                  \n\t"
    "xvpickve2gr.wu %[sum1],          $xr16,                0                      \n\t"
    "xvpickve2gr.wu %[sum2],          $xr16,                4                      \n\t"
    "add.w          %[sum],           %[sum1],              %[sum2]                \n\t"
    : [stride_2]"=&r"(stride_2), [stride_3]"=&r"(stride_3), [stride_4]"=&r"(stride_4),
      [stride2_2]"=&r"(stride2_2), [stride2_3]"=&r"(stride2_3), [stride2_4]"=&r"(stride2_4),
      [sum1]"=&r"(sum1), [sum2]"=&r"(sum2), [sum]"=&r"(sum), [p_pix1]"+&r"(p_pix1), [p_pix2]"+&r"(p_pix2),
      [i_height]"+&r"(i_height)
    : [i_stride]"r"(i_stride), [i_stride2]"r"(i_stride2), [i_8]"r"(i_8)
    : "memory"
    );

    return ( sum >> 1 );
}

int32_t x264_pixel_satd_4x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 )
{
    return pixel_satd_4width_lasx( p_pix1, i_stride, p_pix2, i_stride2, 8 );
}

int32_t x264_pixel_satd_4x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 )
{
    return pixel_satd_4width_lasx( p_pix1, i_stride, p_pix2, i_stride2, 16 );
}

int32_t x264_pixel_satd_8x4_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 )
{
    uint32_t u_sum = 0, sum1, sum2;
    intptr_t i_stride_2 = i_stride << 1;
    intptr_t i_stride2_2 = i_stride2 << 1;
    intptr_t i_stride_3 = i_stride_2 + i_stride;
    intptr_t i_stride2_3 = i_stride2_2 + i_stride2;
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i dif0, dif1;
    __m256i tmp0, tmp1;

    LASX_LOAD_4(p_pix1, i_stride, i_stride_2, i_stride_3, src0, src1, src2, src3);
    LASX_LOAD_4(p_pix2, i_stride2, i_stride2_2, i_stride2_3, ref0, ref1, ref2, ref3);

    src0 = __lasx_xvilvl_d(src1, src0);
    src1 = __lasx_xvilvl_d(src3, src2);
    ref0 = __lasx_xvilvl_d(ref1, ref0);
    ref1 = __lasx_xvilvl_d(ref3, ref2);
    src0 = __lasx_xvpermi_q(src0, src1, 2);
    ref0 = __lasx_xvpermi_q(ref0, ref1, 2);
    dif0 = __lasx_xvsubwev_h_bu(src0, ref0);
    dif1 = __lasx_xvsubwod_h_bu(src0, ref0);
    tmp0 = __lasx_xvadd_h(dif0, dif1);
    tmp1 = __lasx_xvsub_h(dif0, dif1);
    dif0 = __lasx_xvpackev_h(tmp1, tmp0);
    dif1 = __lasx_xvpackod_h(tmp1, tmp0);
    tmp0 = __lasx_xvadd_h(dif0, dif1);
    tmp1 = __lasx_xvsub_h(dif0, dif1);
    dif0 = __lasx_xvpackev_d(tmp1, tmp0);
    dif1 = __lasx_xvpackod_d(tmp1, tmp0);
    tmp0 = __lasx_xvadd_h(dif0, dif1);
    tmp1 = __lasx_xvsub_h(dif0, dif1);
    dif0 = __lasx_xvpermi_q(tmp0, tmp1, 0x02);
    dif1 = __lasx_xvpermi_q(tmp0, tmp1, 0x13);
    tmp0 = __lasx_xvadd_h(dif0, dif1);
    tmp1 = __lasx_xvsub_h(dif0, dif1);
    dif0 = __lasx_xvpackev_d(tmp1, tmp0);
    dif1 = __lasx_xvpackod_d(tmp1, tmp0);
    dif0 = __lasx_xvadda_h(dif0, dif1);
    dif0 = __lasx_xvhaddw_wu_hu(dif0, dif0);
    dif0 = __lasx_xvhaddw_du_wu(dif0, dif0);
    dif0 = __lasx_xvhaddw_qu_du(dif0, dif0);
    sum1 = __lasx_xvpickve2gr_wu(dif0, 0);
    sum2 = __lasx_xvpickve2gr_wu(dif0, 4);
    u_sum = sum1 + sum2;

    return ( u_sum >> 1 );
}

int32_t x264_pixel_satd_8x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 )
{
    uint32_t sum;
    uint32_t sum1, sum2;
    int64_t stride_2, stride_3, stride_4, stride2_2, stride2_3, stride2_4;
    uint8_t *pix1, *pix2;

    __asm__ volatile (
    "slli.d         %[stride_2],      %[i_stride],          1                      \n\t"
    "slli.d         %[stride2_2],     %[i_stride2],         1                      \n\t"
    "add.d          %[stride_3],      %[i_stride],          %[stride_2]            \n\t"
    "add.d          %[stride2_3],     %[i_stride2],         %[stride2_2]           \n\t"
    "slli.d         %[stride_4],      %[stride_2],          1                      \n\t"
    "slli.d         %[stride2_4],     %[stride2_2],         1                      \n\t"
    "add.d          %[pix1],          %[p_pix1],            %[stride_4]            \n\t"
    "add.d          %[pix2],          %[p_pix2],            %[stride2_4]           \n\t"
    "vld            $vr0,             %[p_pix1],            0                      \n\t"
    "vldx           $vr1,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr2,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr3,             %[p_pix1],            %[stride_3]            \n\t"
    "vld            $vr4,             %[pix1],              0                      \n\t"
    "vldx           $vr5,             %[pix1],              %[i_stride]            \n\t"
    "vldx           $vr6,             %[pix1],              %[stride_2]            \n\t"
    "vldx           $vr7,             %[pix1],              %[stride_3]            \n\t"
    "vld            $vr8,             %[p_pix2],            0                      \n\t"
    "vldx           $vr9,             %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr10,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr11,            %[p_pix2],            %[stride2_3]           \n\t"
    "vld            $vr12,            %[pix2],              0                      \n\t"
    "vldx           $vr13,            %[pix2],              %[i_stride2]           \n\t"
    "vldx           $vr14,            %[pix2],              %[stride2_2]           \n\t"
    "vldx           $vr15,            %[pix2],              %[stride2_3]           \n\t"
    "vilvl.d        $vr0,             $vr1,                 $vr0                   \n\t"
    "vilvl.d        $vr1,             $vr3,                 $vr2                   \n\t"
    "vilvl.d        $vr2,             $vr5,                 $vr4                   \n\t"
    "vilvl.d        $vr3,             $vr7,                 $vr6                   \n\t"
    "xvpermi.q      $xr0,             $xr2,                 2                      \n\t"
    "xvpermi.q      $xr1,             $xr3,                 2                      \n\t"
    "vilvl.d        $vr2,             $vr9,                 $vr8                   \n\t"
    "vilvl.d        $vr3,             $vr11,                $vr10                  \n\t"
    "vilvl.d        $vr4,             $vr13,                $vr12                  \n\t"
    "vilvl.d        $vr5,             $vr15,                $vr14                  \n\t"
    "xvpermi.q      $xr2,             $xr4,                 2                      \n\t"
    "xvpermi.q      $xr3,             $xr5,                 2                      \n\t"
    "xvsubwev.h.bu  $xr4,             $xr0,                 $xr2                   \n\t"
    "xvsubwod.h.bu  $xr5,             $xr0,                 $xr2                   \n\t"
    "xvsubwev.h.bu  $xr6,             $xr1,                 $xr3                   \n\t"
    "xvsubwod.h.bu  $xr7,             $xr1,                 $xr3                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvpackev.h     $xr4,             $xr1,                 $xr0                   \n\t"
    "xvpackod.h     $xr5,             $xr1,                 $xr0                   \n\t"
    "xvpackev.h     $xr6,             $xr3,                 $xr2                   \n\t"
    "xvpackod.h     $xr7,             $xr3,                 $xr2                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvilvl.h       $xr4,             $xr1,                 $xr0                   \n\t"
    "xvilvh.h       $xr5,             $xr1,                 $xr0                   \n\t"
    "xvilvl.h       $xr6,             $xr3,                 $xr2                   \n\t"
    "xvilvh.h       $xr7,             $xr3,                 $xr2                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr0,                 $xr2                   \n\t"
    "xvadd.h        $xr5,             $xr1,                 $xr3                   \n\t"
    "xvsub.h        $xr6,             $xr0,                 $xr2                   \n\t"
    "xvsub.h        $xr7,             $xr1,                 $xr3                   \n\t"
    "xvadda.h       $xr0,             $xr4,                 $xr5                   \n\t"
    "xvadda.h       $xr1,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr0,             $xr0,                 $xr1                   \n\t"
    "xvhaddw.wu.hu  $xr0,             $xr0,                 $xr0                   \n\t"
    "xvhaddw.du.wu  $xr0,             $xr0,                 $xr0                   \n\t"
    "xvhaddw.qu.du  $xr0,             $xr0,                 $xr0                   \n\t"
    "xvpickve2gr.wu %[sum1],          $xr0,                 0                      \n\t"
    "xvpickve2gr.wu %[sum2],          $xr0,                 4                      \n\t"
    "add.w          %[sum],           %[sum1],              %[sum2]                \n\t"
    : [stride_2]"=&r"(stride_2), [stride_3]"=&r"(stride_3), [stride_4]"=&r"(stride_4),
      [stride2_2]"=&r"(stride2_2), [stride2_3]"=&r"(stride2_3), [stride2_4]"=&r"(stride2_4),
      [pix1]"=&r"(pix1), [pix2]"=&r"(pix2), [sum1]"=&r"(sum1), [sum2]"=&r"(sum2), [sum]"=&r"(sum)
    : [i_stride]"r"(i_stride), [i_stride2]"r"(i_stride2), [p_pix1]"r"(p_pix1), [p_pix2]"r"(p_pix2)
    : "memory"
    );

    return ( sum >> 1 );
}

int32_t x264_pixel_satd_8x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 )
{
    return pixel_satd_8width_lasx( p_pix1, i_stride, p_pix2, i_stride2, 16 );
}

int32_t x264_pixel_satd_16x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 )
{
    int32_t sum;
    uint32_t sum1, sum2;
    int64_t stride_2, stride_3, stride_4, stride2_2, stride2_3, stride2_4;

    __asm__ volatile (
    "slli.d         %[stride_2],      %[i_stride],          1                      \n\t"
    "slli.d         %[stride2_2],     %[i_stride2],         1                      \n\t"
    "add.d          %[stride_3],      %[i_stride],          %[stride_2]            \n\t"
    "add.d          %[stride2_3],     %[i_stride2],         %[stride2_2]           \n\t"
    "slli.d         %[stride_4],      %[stride_2],          1                      \n\t"
    "slli.d         %[stride2_4],     %[stride2_2],         1                      \n\t"
    "vld            $vr0,             %[p_pix1],            0                      \n\t"
    "vldx           $vr1,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr2,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr3,             %[p_pix1],            %[stride_3]            \n\t"
    "add.d          %[p_pix1],        %[p_pix1],            %[stride_4]            \n\t"
    "vld            $vr4,             %[p_pix1],            0                      \n\t"
    "vldx           $vr5,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr6,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr7,             %[p_pix1],            %[stride_3]            \n\t"
    "vld            $vr8,             %[p_pix2],            0                      \n\t"
    "vldx           $vr9,             %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr10,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr11,            %[p_pix2],            %[stride2_3]           \n\t"
    "add.d          %[p_pix2],        %[p_pix2],            %[stride2_4]           \n\t"
    "vld            $vr12,            %[p_pix2],            0                      \n\t"
    "vldx           $vr13,            %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr14,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr15,            %[p_pix2],            %[stride2_3]           \n\t"
    "xvpermi.q      $xr0,             $xr4,                 2                      \n\t"
    "xvpermi.q      $xr1,             $xr5,                 2                      \n\t"
    "xvpermi.q      $xr2,             $xr6,                 2                      \n\t"
    "xvpermi.q      $xr3,             $xr7,                 2                      \n\t"
    "xvpermi.q      $xr8,             $xr12,                2                      \n\t"
    "xvpermi.q      $xr9,             $xr13,                2                      \n\t"
    "xvpermi.q      $xr10,            $xr14,                2                      \n\t"
    "xvpermi.q      $xr11,            $xr15,                2                      \n\t"
    "xvsubwev.h.bu  $xr4,             $xr0,                 $xr8                   \n\t"
    "xvsubwod.h.bu  $xr5,             $xr0,                 $xr8                   \n\t"
    "xvsubwev.h.bu  $xr6,             $xr1,                 $xr9                   \n\t"
    "xvsubwod.h.bu  $xr7,             $xr1,                 $xr9                   \n\t"
    "xvsubwev.h.bu  $xr8,             $xr2,                 $xr10                  \n\t"
    "xvsubwod.h.bu  $xr9,             $xr2,                 $xr10                  \n\t"
    "xvsubwev.h.bu  $xr12,            $xr3,                 $xr11                  \n\t"
    "xvsubwod.h.bu  $xr13,            $xr3,                 $xr11                  \n\t"

    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr12,                $xr13                  \n\t"
    "xvsub.h        $xr7,             $xr12,                $xr13                  \n\t"

    "xvpackev.h     $xr8,             $xr5,                 $xr4                   \n\t"
    "xvpackod.h     $xr9,             $xr5,                 $xr4                   \n\t"
    "xvpackev.h     $xr10,            $xr7,                 $xr6                   \n\t"
    "xvpackod.h     $xr11,            $xr7,                 $xr6                   \n\t"
    "xvpackev.h     $xr4,             $xr1,                 $xr0                   \n\t"
    "xvpackod.h     $xr5,             $xr1,                 $xr0                   \n\t"
    "xvpackev.h     $xr6,             $xr3,                 $xr2                   \n\t"
    "xvpackod.h     $xr7,             $xr3,                 $xr2                   \n\t"

    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr10,                $xr11                  \n\t"
    "xvsub.h        $xr7,             $xr10,                $xr11                  \n\t"

    "xvilvl.h       $xr8,             $xr1,                 $xr0                   \n\t"
    "xvilvl.h       $xr9,             $xr3,                 $xr2                   \n\t"
    "xvilvl.h       $xr10,            $xr5,                 $xr4                   \n\t"
    "xvilvl.h       $xr11,            $xr7,                 $xr6                   \n\t"
    "xvilvh.h       $xr0,             $xr1,                 $xr0                   \n\t"
    "xvilvh.h       $xr1,             $xr3,                 $xr2                   \n\t"
    "xvilvh.h       $xr2,             $xr5,                 $xr4                   \n\t"
    "xvilvh.h       $xr3,             $xr7,                 $xr6                   \n\t"


    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr10,                $xr11                  \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr7,             $xr10,                $xr11                  \n\t"
    "xvadd.h        $xr8,             $xr4,                 $xr6                   \n\t"
    "xvadd.h        $xr9,             $xr5,                 $xr7                   \n\t"
    "xvsub.h        $xr10,            $xr4,                 $xr6                   \n\t"
    "xvsub.h        $xr11,            $xr5,                 $xr7                   \n\t"

    "xvadd.h        $xr4,             $xr0,                 $xr1                   \n\t"
    "xvadd.h        $xr6,             $xr2,                 $xr3                   \n\t"
    "xvsub.h        $xr5,             $xr0,                 $xr1                   \n\t"
    "xvsub.h        $xr7,             $xr2,                 $xr3                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr6                   \n\t"
    "xvadd.h        $xr1,             $xr5,                 $xr7                   \n\t"
    "xvsub.h        $xr2,             $xr4,                 $xr6                   \n\t"
    "xvsub.h        $xr3,             $xr5,                 $xr7                   \n\t"

    "xvadda.h       $xr8,             $xr8,                 $xr9                   \n\t"
    "xvadda.h       $xr9,             $xr10,                $xr11                  \n\t"
    "xvadda.h       $xr0,             $xr0,                 $xr1                   \n\t"
    "xvadda.h       $xr1,             $xr2,                 $xr3                   \n\t"

    "xvadd.h        $xr8,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr0,             $xr0,                 $xr1                   \n\t"
    "xvadd.h        $xr16,            $xr0,                 $xr8                   \n\t"
    "xvhaddw.wu.hu  $xr16,            $xr16,                $xr16                  \n\t"
    "xvhaddw.du.wu  $xr16,            $xr16,                $xr16                  \n\t"
    "xvhaddw.qu.du  $xr16,            $xr16,                $xr16                  \n\t"
    "xvpickve2gr.wu %[sum1],          $xr16,                0                      \n\t"
    "xvpickve2gr.wu %[sum2],          $xr16,                4                      \n\t"
    "add.w          %[sum],           %[sum1],              %[sum2]                \n\t"
    : [stride_2]"=&r"(stride_2), [stride_3]"=&r"(stride_3), [stride_4]"=&r"(stride_4),
      [stride2_2]"=&r"(stride2_2), [stride2_3]"=&r"(stride2_3), [stride2_4]"=&r"(stride2_4),
      [sum1]"=&r"(sum1), [sum2]"=&r"(sum2), [sum]"=&r"(sum), [p_pix1]"+&r"(p_pix1), [p_pix2]"+&r"(p_pix2)
    : [i_stride]"r"(i_stride), [i_stride2]"r"(i_stride2)
    : "memory"
    );

    return ( sum >> 1 );
}

int32_t x264_pixel_satd_16x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                    uint8_t *p_pix2, intptr_t i_stride2 )
{
    int32_t sum;
    uint32_t sum1, sum2;
    int64_t stride_2, stride_3, stride_4, stride2_2, stride2_3, stride2_4;

    __asm__ volatile (
    "slli.d         %[stride_2],      %[i_stride],          1                      \n\t"
    "slli.d         %[stride2_2],     %[i_stride2],         1                      \n\t"
    "add.d          %[stride_3],      %[i_stride],          %[stride_2]            \n\t"
    "add.d          %[stride2_3],     %[i_stride2],         %[stride2_2]           \n\t"
    "slli.d         %[stride_4],      %[stride_2],          1                      \n\t"
    "slli.d         %[stride2_4],     %[stride2_2],         1                      \n\t"
    "vld            $vr0,             %[p_pix1],            0                      \n\t"
    "vldx           $vr1,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr2,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr3,             %[p_pix1],            %[stride_3]            \n\t"
    "add.d          %[p_pix1],        %[p_pix1],            %[stride_4]            \n\t"
    "vld            $vr4,             %[p_pix1],            0                      \n\t"
    "vldx           $vr5,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr6,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr7,             %[p_pix1],            %[stride_3]            \n\t"
    "add.d          %[p_pix1],        %[p_pix1],            %[stride_4]            \n\t"
    "vld            $vr8,             %[p_pix2],            0                      \n\t"
    "vldx           $vr9,             %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr10,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr11,            %[p_pix2],            %[stride2_3]           \n\t"
    "add.d          %[p_pix2],        %[p_pix2],            %[stride2_4]           \n\t"
    "vld            $vr12,            %[p_pix2],            0                      \n\t"
    "vldx           $vr13,            %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr14,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr15,            %[p_pix2],            %[stride2_3]           \n\t"
    "add.d          %[p_pix2],        %[p_pix2],            %[stride2_4]           \n\t"
    "xvpermi.q      $xr0,             $xr4,                 2                      \n\t"
    "xvpermi.q      $xr1,             $xr5,                 2                      \n\t"
    "xvpermi.q      $xr2,             $xr6,                 2                      \n\t"
    "xvpermi.q      $xr3,             $xr7,                 2                      \n\t"
    "xvpermi.q      $xr8,             $xr12,                2                      \n\t"
    "xvpermi.q      $xr9,             $xr13,                2                      \n\t"
    "xvpermi.q      $xr10,            $xr14,                2                      \n\t"
    "xvpermi.q      $xr11,            $xr15,                2                      \n\t"
    "xvsubwev.h.bu  $xr4,             $xr0,                 $xr8                   \n\t"
    "xvsubwod.h.bu  $xr5,             $xr0,                 $xr8                   \n\t"
    "xvsubwev.h.bu  $xr6,             $xr1,                 $xr9                   \n\t"
    "xvsubwod.h.bu  $xr7,             $xr1,                 $xr9                   \n\t"
    "xvsubwev.h.bu  $xr8,             $xr2,                 $xr10                  \n\t"
    "xvsubwod.h.bu  $xr9,             $xr2,                 $xr10                  \n\t"
    "xvsubwev.h.bu  $xr12,            $xr3,                 $xr11                  \n\t"
    "xvsubwod.h.bu  $xr13,            $xr3,                 $xr11                  \n\t"

    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr12,                $xr13                  \n\t"
    "xvsub.h        $xr7,             $xr12,                $xr13                  \n\t"

    "xvpackev.h     $xr8,             $xr5,                 $xr4                   \n\t"
    "xvpackod.h     $xr9,             $xr5,                 $xr4                   \n\t"
    "xvpackev.h     $xr10,            $xr7,                 $xr6                   \n\t"
    "xvpackod.h     $xr11,            $xr7,                 $xr6                   \n\t"
    "xvpackev.h     $xr4,             $xr1,                 $xr0                   \n\t"
    "xvpackod.h     $xr5,             $xr1,                 $xr0                   \n\t"
    "xvpackev.h     $xr6,             $xr3,                 $xr2                   \n\t"
    "xvpackod.h     $xr7,             $xr3,                 $xr2                   \n\t"

    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr10,                $xr11                  \n\t"
    "xvsub.h        $xr7,             $xr10,                $xr11                  \n\t"

    "xvilvl.h       $xr8,             $xr1,                 $xr0                   \n\t"
    "xvilvl.h       $xr9,             $xr3,                 $xr2                   \n\t"
    "xvilvl.h       $xr10,            $xr5,                 $xr4                   \n\t"
    "xvilvl.h       $xr11,            $xr7,                 $xr6                   \n\t"
    "xvilvh.h       $xr0,             $xr1,                 $xr0                   \n\t"
    "xvilvh.h       $xr1,             $xr3,                 $xr2                   \n\t"
    "xvilvh.h       $xr2,             $xr5,                 $xr4                   \n\t"
    "xvilvh.h       $xr3,             $xr7,                 $xr6                   \n\t"

    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr10,                $xr11                  \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr7,             $xr10,                $xr11                  \n\t"
    "xvadd.h        $xr8,             $xr4,                 $xr6                   \n\t"
    "xvadd.h        $xr9,             $xr5,                 $xr7                   \n\t"
    "xvsub.h        $xr10,            $xr4,                 $xr6                   \n\t"
    "xvsub.h        $xr11,            $xr5,                 $xr7                   \n\t"

    "xvadd.h        $xr4,             $xr0,                 $xr1                   \n\t"
    "xvadd.h        $xr6,             $xr2,                 $xr3                   \n\t"
    "xvsub.h        $xr5,             $xr0,                 $xr1                   \n\t"
    "xvsub.h        $xr7,             $xr2,                 $xr3                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr6                   \n\t"
    "xvadd.h        $xr1,             $xr5,                 $xr7                   \n\t"
    "xvsub.h        $xr2,             $xr4,                 $xr6                   \n\t"
    "xvsub.h        $xr3,             $xr5,                 $xr7                   \n\t"

    "xvadda.h       $xr8,             $xr8,                 $xr9                   \n\t"
    "xvadda.h       $xr9,             $xr10,                $xr11                  \n\t"
    "xvadda.h       $xr0,             $xr0,                 $xr1                   \n\t"
    "xvadda.h       $xr1,             $xr2,                 $xr3                   \n\t"

    "xvadd.h        $xr8,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr0,             $xr0,                 $xr1                   \n\t"
    "xvadd.h        $xr16,            $xr0,                 $xr8                   \n\t"

    "vld            $vr0,             %[p_pix1],            0                      \n\t"
    "vldx           $vr1,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr2,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr3,             %[p_pix1],            %[stride_3]            \n\t"
    "add.d          %[p_pix1],        %[p_pix1],            %[stride_4]            \n\t"
    "vld            $vr4,             %[p_pix1],            0                      \n\t"
    "vldx           $vr5,             %[p_pix1],            %[i_stride]            \n\t"
    "vldx           $vr6,             %[p_pix1],            %[stride_2]            \n\t"
    "vldx           $vr7,             %[p_pix1],            %[stride_3]            \n\t"
    "vld            $vr8,             %[p_pix2],            0                      \n\t"
    "vldx           $vr9,             %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr10,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr11,            %[p_pix2],            %[stride2_3]           \n\t"
    "add.d          %[p_pix2],        %[p_pix2],            %[stride2_4]           \n\t"
    "vld            $vr12,            %[p_pix2],            0                      \n\t"
    "vldx           $vr13,            %[p_pix2],            %[i_stride2]           \n\t"
    "vldx           $vr14,            %[p_pix2],            %[stride2_2]           \n\t"
    "vldx           $vr15,            %[p_pix2],            %[stride2_3]           \n\t"
    "xvpermi.q      $xr0,             $xr4,                 2                      \n\t"
    "xvpermi.q      $xr1,             $xr5,                 2                      \n\t"
    "xvpermi.q      $xr2,             $xr6,                 2                      \n\t"
    "xvpermi.q      $xr3,             $xr7,                 2                      \n\t"
    "xvpermi.q      $xr8,             $xr12,                2                      \n\t"
    "xvpermi.q      $xr9,             $xr13,                2                      \n\t"
    "xvpermi.q      $xr10,            $xr14,                2                      \n\t"
    "xvpermi.q      $xr11,            $xr15,                2                      \n\t"
    "xvsubwev.h.bu  $xr4,             $xr0,                 $xr8                   \n\t"
    "xvsubwod.h.bu  $xr5,             $xr0,                 $xr8                   \n\t"
    "xvsubwev.h.bu  $xr6,             $xr1,                 $xr9                   \n\t"
    "xvsubwod.h.bu  $xr7,             $xr1,                 $xr9                   \n\t"
    "xvsubwev.h.bu  $xr8,             $xr2,                 $xr10                  \n\t"
    "xvsubwod.h.bu  $xr9,             $xr2,                 $xr10                  \n\t"
    "xvsubwev.h.bu  $xr12,            $xr3,                 $xr11                  \n\t"
    "xvsubwod.h.bu  $xr13,            $xr3,                 $xr11                  \n\t"

    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr12,                $xr13                  \n\t"
    "xvsub.h        $xr7,             $xr12,                $xr13                  \n\t"

    "xvpackev.h     $xr8,             $xr5,                 $xr4                   \n\t"
    "xvpackod.h     $xr9,             $xr5,                 $xr4                   \n\t"
    "xvpackev.h     $xr10,            $xr7,                 $xr6                   \n\t"
    "xvpackod.h     $xr11,            $xr7,                 $xr6                   \n\t"
    "xvpackev.h     $xr4,             $xr1,                 $xr0                   \n\t"
    "xvpackod.h     $xr5,             $xr1,                 $xr0                   \n\t"
    "xvpackev.h     $xr6,             $xr3,                 $xr2                   \n\t"
    "xvpackod.h     $xr7,             $xr3,                 $xr2                   \n\t"

    "xvadd.h        $xr0,             $xr4,                 $xr5                   \n\t"
    "xvsub.h        $xr1,             $xr4,                 $xr5                   \n\t"
    "xvadd.h        $xr2,             $xr6,                 $xr7                   \n\t"
    "xvsub.h        $xr3,             $xr6,                 $xr7                   \n\t"
    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr10,                $xr11                  \n\t"
    "xvsub.h        $xr7,             $xr10,                $xr11                  \n\t"

    "xvilvl.h       $xr8,             $xr1,                 $xr0                   \n\t"
    "xvilvl.h       $xr9,             $xr3,                 $xr2                   \n\t"
    "xvilvl.h       $xr10,            $xr5,                 $xr4                   \n\t"
    "xvilvl.h       $xr11,            $xr7,                 $xr6                   \n\t"
    "xvilvh.h       $xr0,             $xr1,                 $xr0                   \n\t"
    "xvilvh.h       $xr1,             $xr3,                 $xr2                   \n\t"
    "xvilvh.h       $xr2,             $xr5,                 $xr4                   \n\t"
    "xvilvh.h       $xr3,             $xr7,                 $xr6                   \n\t"

    "xvadd.h        $xr4,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr6,             $xr10,                $xr11                  \n\t"
    "xvsub.h        $xr5,             $xr8,                 $xr9                   \n\t"
    "xvsub.h        $xr7,             $xr10,                $xr11                  \n\t"
    "xvadd.h        $xr8,             $xr4,                 $xr6                   \n\t"
    "xvadd.h        $xr9,             $xr5,                 $xr7                   \n\t"
    "xvsub.h        $xr10,            $xr4,                 $xr6                   \n\t"
    "xvsub.h        $xr11,            $xr5,                 $xr7                   \n\t"

    "xvadd.h        $xr4,             $xr0,                 $xr1                   \n\t"
    "xvadd.h        $xr6,             $xr2,                 $xr3                   \n\t"
    "xvsub.h        $xr5,             $xr0,                 $xr1                   \n\t"
    "xvsub.h        $xr7,             $xr2,                 $xr3                   \n\t"
    "xvadd.h        $xr0,             $xr4,                 $xr6                   \n\t"
    "xvadd.h        $xr1,             $xr5,                 $xr7                   \n\t"
    "xvsub.h        $xr2,             $xr4,                 $xr6                   \n\t"
    "xvsub.h        $xr3,             $xr5,                 $xr7                   \n\t"

    "xvadda.h       $xr8,             $xr8,                 $xr9                   \n\t"
    "xvadda.h       $xr9,             $xr10,                $xr11                  \n\t"
    "xvadda.h       $xr0,             $xr0,                 $xr1                   \n\t"
    "xvadda.h       $xr1,             $xr2,                 $xr3                   \n\t"

    "xvadd.h        $xr8,             $xr8,                 $xr9                   \n\t"
    "xvadd.h        $xr0,             $xr0,                 $xr1                   \n\t"
    "xvadd.h        $xr16,            $xr16,                $xr8                   \n\t"
    "xvadd.h        $xr16,            $xr16,                $xr0                   \n\t"

    "xvhaddw.wu.hu  $xr16,            $xr16,                $xr16                  \n\t"
    "xvhaddw.du.wu  $xr16,            $xr16,                $xr16                  \n\t"
    "xvhaddw.qu.du  $xr16,            $xr16,                $xr16                  \n\t"
    "xvpickve2gr.wu %[sum1],          $xr16,                0                      \n\t"
    "xvpickve2gr.wu %[sum2],          $xr16,                4                      \n\t"
    "add.w          %[sum],           %[sum1],              %[sum2]                \n\t"
    : [stride_2]"=&r"(stride_2), [stride_3]"=&r"(stride_3), [stride_4]"=&r"(stride_4),
      [stride2_2]"=&r"(stride2_2), [stride2_3]"=&r"(stride2_3), [stride2_4]"=&r"(stride2_4),
      [sum1]"=&r"(sum1), [sum2]"=&r"(sum2), [sum]"=&r"(sum), [p_pix1]"+&r"(p_pix1), [p_pix2]"+&r"(p_pix2)
    : [i_stride]"r"(i_stride), [i_stride2]"r"(i_stride2)
    : "memory"
    );

    return ( sum >> 1 );
}

#define SAD_LOAD                                                        \
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;             \
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;             \
    __m256i diff;                                                       \
    __m256i sad0 = __lasx_xvldi( 0 );                                   \
    __m256i sad1 = __lasx_xvldi( 0 );                                   \
    __m256i sad2 = __lasx_xvldi( 0 );                                   \
    __m256i sad3 = __lasx_xvldi( 0 );                                   \
    int32_t i_src_stride_x2 = FENC_STRIDE << 1;                         \
    int32_t i_ref_stride_x2 = i_ref_stride << 1;                        \
    int32_t i_src_stride_x3 = i_src_stride_x2 + FENC_STRIDE;            \
    int32_t i_ref_stride_x3 = i_ref_stride_x2 + i_ref_stride;           \
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;                     \
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;                     \

#define LOAD_REF_DATA_16W( p_ref, sad)                                        \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,       \
                 ref0, ref1, ref2, ref3 );                                    \
    p_ref += i_ref_stride_x4;                                                 \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,       \
                 ref4, ref5, ref6, ref7 );                                    \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                              \
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );                              \
    ref2 = __lasx_xvpermi_q( ref4, ref5, 0x20 );                              \
    ref3 = __lasx_xvpermi_q( ref6, ref7, 0x20 );                              \
    diff = __lasx_xvabsd_bu( src0, ref0 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \
    diff = __lasx_xvabsd_bu( src1, ref1 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \
    diff = __lasx_xvabsd_bu( src2, ref2 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \
    diff = __lasx_xvabsd_bu( src3, ref3 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \

#define ST_REF_DATA(sad)                                  \
    sad = __lasx_xvhaddw_wu_hu(sad, sad);                 \
    sad = __lasx_xvhaddw_du_wu(sad, sad);                 \
    sad = __lasx_xvhaddw_qu_du(sad, sad);                 \

void x264_pixel_sad_x4_16x16_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                   uint8_t *p_ref1, uint8_t *p_ref2,
                                   uint8_t *p_ref3, intptr_t i_ref_stride,
                                   int32_t p_sad_array[4] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    LOAD_REF_DATA_16W( p_ref0, sad0 );
    LOAD_REF_DATA_16W( p_ref1, sad1 );
    LOAD_REF_DATA_16W( p_ref2, sad2 );
    LOAD_REF_DATA_16W( p_ref3, sad3 );

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);

    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    p_ref0 += i_ref_stride_x4;
    p_ref1 += i_ref_stride_x4;
    p_ref2 += i_ref_stride_x4;
    p_ref3 += i_ref_stride_x4;

    LOAD_REF_DATA_16W( p_ref0, sad0 );
    LOAD_REF_DATA_16W( p_ref1, sad1 );
    LOAD_REF_DATA_16W( p_ref2, sad2 );
    LOAD_REF_DATA_16W( p_ref3, sad3 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
    ST_REF_DATA(sad3);
    p_sad_array[3] = __lasx_xvpickve2gr_wu(sad3, 0) + __lasx_xvpickve2gr_wu(sad3, 4);
}

void x264_pixel_sad_x4_16x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  uint8_t *p_ref3, intptr_t i_ref_stride,
                                  int32_t p_sad_array[4] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);

    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    LOAD_REF_DATA_16W( p_ref0, sad0 );
    LOAD_REF_DATA_16W( p_ref1, sad1 );
    LOAD_REF_DATA_16W( p_ref2, sad2 );
    LOAD_REF_DATA_16W( p_ref3, sad3 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
    ST_REF_DATA(sad3);
    p_sad_array[3] = __lasx_xvpickve2gr_wu(sad3, 0) + __lasx_xvpickve2gr_wu(sad3, 4);
}

#undef LOAD_REF_DATA_16W

#define LOAD_REF_DATA_8W( p_ref, sad)                                             \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,           \
                 ref0, ref1, ref2, ref3 );                                        \
    p_ref += i_ref_stride_x4;                                                     \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,           \
                 ref4, ref5, ref6, ref7 );                                        \
    ref0 = __lasx_xvilvl_d( ref1, ref0 );                                         \
    ref1 = __lasx_xvilvl_d( ref3, ref2 );                                         \
    ref2 = __lasx_xvilvl_d( ref5, ref4 );                                         \
    ref3 = __lasx_xvilvl_d( ref7, ref6 );                                         \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                                  \
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );                                  \
    diff = __lasx_xvabsd_bu( src0, ref0 );                                        \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                    \
    sad  = __lasx_xvadd_h( sad, diff );                                           \
    diff = __lasx_xvabsd_bu( src1, ref1 );                                        \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                    \
    sad  = __lasx_xvadd_h( sad, diff );

void x264_pixel_sad_x4_8x16_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  uint8_t *p_ref3, intptr_t i_ref_stride,
                                  int32_t p_sad_array[4] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;

    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LOAD_REF_DATA_8W( p_ref0, sad0 );
    LOAD_REF_DATA_8W( p_ref1, sad1 );
    LOAD_REF_DATA_8W( p_ref2, sad2 );
    LOAD_REF_DATA_8W( p_ref3, sad3 );

    p_ref0 += i_ref_stride_x4;
    p_ref1 += i_ref_stride_x4;
    p_ref2 += i_ref_stride_x4;
    p_ref3 += i_ref_stride_x4;

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);

    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LOAD_REF_DATA_8W( p_ref0, sad0 );
    LOAD_REF_DATA_8W( p_ref1, sad1 );
    LOAD_REF_DATA_8W( p_ref2, sad2 );
    LOAD_REF_DATA_8W( p_ref3, sad3 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
    ST_REF_DATA(sad3);
    p_sad_array[3] = __lasx_xvpickve2gr_wu(sad3, 0) + __lasx_xvpickve2gr_wu(sad3, 4);
}

void x264_pixel_sad_x4_8x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;

    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LOAD_REF_DATA_8W( p_ref0, sad0 );
    LOAD_REF_DATA_8W( p_ref1, sad1 );
    LOAD_REF_DATA_8W( p_ref2, sad2 );
    LOAD_REF_DATA_8W( p_ref3, sad3 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
    ST_REF_DATA(sad3);
    p_sad_array[3] = __lasx_xvpickve2gr_wu(sad3, 0) + __lasx_xvpickve2gr_wu(sad3, 4);
}

#undef SAD_LOAD
#undef LOAD_REF_DATA_8W
#undef ST_REF_DATA

void x264_pixel_sad_x4_8x4_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] )
{
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i diff;
    __m256i sad0, sad1, sad2, sad3;
    intptr_t i_src_stride_x2 = FENC_STRIDE << 1;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_src_stride_x3 = FENC_STRIDE + i_src_stride_x2;
    intptr_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );

#define LOAD_REF_DATA_8W_4H( p_ref, sad)                                \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3, \
                 ref0, ref1, ref2, ref3 );                              \
    ref0 = __lasx_xvilvl_d( ref1, ref0 );                               \
    ref1 = __lasx_xvilvl_d( ref3, ref2 );                               \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                        \
    diff = __lasx_xvabsd_bu( src0, ref0 );                              \
    sad = __lasx_xvhaddw_hu_bu( diff, diff );                           \
    sad = __lasx_xvhaddw_wu_hu( sad, sad );                             \
    sad = __lasx_xvhaddw_du_wu( sad, sad );                             \
    sad = __lasx_xvhaddw_qu_du( sad, sad );                             \

    LOAD_REF_DATA_8W_4H( p_ref0, sad0 );
    LOAD_REF_DATA_8W_4H( p_ref1, sad1 );
    LOAD_REF_DATA_8W_4H( p_ref2, sad2 );
    LOAD_REF_DATA_8W_4H( p_ref3, sad3 );

#undef LOAD_REF_DATA_8W_4H

    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
    p_sad_array[3] = __lasx_xvpickve2gr_wu(sad3, 0) + __lasx_xvpickve2gr_wu(sad3, 4);
}

void x264_pixel_sad_x4_4x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] )
{
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff;
    __m256i sad0, sad1, sad2, sad3;
    intptr_t i_src_stride_x2 = FENC_STRIDE << 1;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_src_stride_x3 = FENC_STRIDE + i_src_stride_x2;
    intptr_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;
    intptr_t i_src_stride_x4 = i_src_stride_x2 << 1;
    intptr_t i_ref_stride_x4 = i_ref_stride_x2 << 1;

    src0 = __lasx_xvld( p_src, 0);
    src1 = __lasx_xvld( p_src, FENC_STRIDE);
    src2 = __lasx_xvldx( p_src, i_src_stride_x2);
    src3 = __lasx_xvldx( p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld( p_src, 0);
    src5 = __lasx_xvld( p_src, FENC_STRIDE);
    src6 = __lasx_xvldx( p_src, i_src_stride_x2);
    src7 = __lasx_xvldx( p_src, i_src_stride_x3);
    src0 = __lasx_xvilvl_w( src1, src0 );
    src1 = __lasx_xvilvl_w( src3, src2 );
    src2 = __lasx_xvilvl_w( src5, src4 );
    src3 = __lasx_xvilvl_w( src7, src6 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );

#define LOAD_REF_DATA_4W_8H( p_ref, sad) \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,       \
                 ref0, ref1, ref2, ref3 );                                    \
    p_ref += i_ref_stride_x4;                                                 \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,       \
                 ref4, ref5, ref6, ref7 );                                    \
    ref0 = __lasx_xvilvl_w( ref1, ref0 );                                     \
    ref1 = __lasx_xvilvl_w( ref3, ref2 );                                     \
    ref2 = __lasx_xvilvl_w( ref5, ref4 );                                     \
    ref3 = __lasx_xvilvl_w( ref7, ref6 );                                     \
    ref0 = __lasx_xvilvl_d( ref1, ref0 );                                     \
    ref1 = __lasx_xvilvl_d( ref3, ref2 );                                     \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                              \
    diff = __lasx_xvabsd_bu( src0, ref0 );                                    \
    sad = __lasx_xvhaddw_hu_bu( diff, diff );                                 \
    sad = __lasx_xvhaddw_wu_hu( sad, sad );                                   \
    sad = __lasx_xvhaddw_du_wu( sad, sad );                                   \
    sad = __lasx_xvhaddw_qu_du( sad, sad );                                   \

    LOAD_REF_DATA_4W_8H( p_ref0, sad0 );
    LOAD_REF_DATA_4W_8H( p_ref1, sad1 );
    LOAD_REF_DATA_4W_8H( p_ref2, sad2 );
    LOAD_REF_DATA_4W_8H( p_ref3, sad3 );

#undef LOAD_REF_DATA_4W_8H

    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
    p_sad_array[3] = __lasx_xvpickve2gr_wu(sad3, 0) + __lasx_xvpickve2gr_wu(sad3, 4);
}

void x264_pixel_sad_x4_4x4_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] )
{
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff;
    intptr_t i_src_stride_x2 = FENC_STRIDE << 1;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_src_stride_x3 = FENC_STRIDE + i_src_stride_x2;
    intptr_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;

    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvld( p_src, FENC_STRIDE );
    src2 = __lasx_xvldx( p_src, i_src_stride_x2 );
    src3 = __lasx_xvldx( p_src, i_src_stride_x3 );
    src0 = __lasx_xvilvl_w( src1, src0 );
    src1 = __lasx_xvilvl_w( src3, src2 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src0 = __lasx_xvpermi_q(src0, src0, 0x00);

#define LOAD_REF_DATA_4W_4H( p0, p1 )                                    \
    LASX_LOAD_4( p0, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,     \
                 ref0, ref1, ref2, ref3 );                               \
    LASX_LOAD_4( p1, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,     \
                 ref4, ref5, ref6, ref7 );                               \
    ref0 = __lasx_xvilvl_w( ref1, ref0 );                                \
    ref1 = __lasx_xvilvl_w( ref3, ref2 );                                \
    ref0 = __lasx_xvilvl_d( ref1, ref0 );                                \
    ref2 = __lasx_xvilvl_w( ref5, ref4 );                                \
    ref3 = __lasx_xvilvl_w( ref7, ref6 );                                \
    ref1 = __lasx_xvilvl_d( ref3, ref2 );                                \
    ref0 = __lasx_xvpermi_q(ref0, ref1, 0x02);                           \
    diff = __lasx_xvabsd_bu( src0, ref0 );                               \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                           \
    diff = __lasx_xvhaddw_wu_hu( diff, diff );                           \
    diff = __lasx_xvhaddw_du_wu( diff, diff );                           \
    diff = __lasx_xvhaddw_qu_du( diff, diff );                           \

    LOAD_REF_DATA_4W_4H( p_ref0, p_ref1 );
    p_sad_array[0] = __lasx_xvpickve2gr_wu(diff, 0);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(diff, 4);
    LOAD_REF_DATA_4W_4H( p_ref2, p_ref3 );
    p_sad_array[2] = __lasx_xvpickve2gr_wu(diff, 0);
    p_sad_array[3] = __lasx_xvpickve2gr_wu(diff, 4);

#undef LOAD_REF_DATA_4W_4H

}

#define SAD_LOAD                                                              \
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;                   \
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;                   \
    __m256i diff;                                                             \
    __m256i sad0 = __lasx_xvldi(0);                                           \
    __m256i sad1 = __lasx_xvldi(0);                                           \
    __m256i sad2 = __lasx_xvldi(0);                                           \
    int32_t i_src_stride_x2 = FENC_STRIDE << 1;                               \
    int32_t i_ref_stride_x2 = i_ref_stride << 1;                              \
    int32_t i_src_stride_x3 = FENC_STRIDE + i_src_stride_x2;                  \
    int32_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;                 \
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;                           \
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;


#define LOAD_REF_DATA_16W( p_ref, sad)                                        \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,       \
                 ref0, ref1, ref2, ref3 );                                    \
    p_ref += i_ref_stride_x4;                                                 \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,       \
                 ref4, ref5, ref6, ref7 );                                    \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                              \
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );                              \
    ref2 = __lasx_xvpermi_q( ref4, ref5, 0x20 );                              \
    ref3 = __lasx_xvpermi_q( ref6, ref7, 0x20 );                              \
    diff = __lasx_xvabsd_bu( src0, ref0 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \
    diff = __lasx_xvabsd_bu( src1, ref1 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \
    diff = __lasx_xvabsd_bu( src2, ref2 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \
    diff = __lasx_xvabsd_bu( src3, ref3 );                                    \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                \
    sad  = __lasx_xvadd_h(sad, diff);                                         \


#define ST_REF_DATA(sad)                                  \
    sad = __lasx_xvhaddw_wu_hu(sad, sad);                 \
    sad = __lasx_xvhaddw_du_wu(sad, sad);                 \
    sad = __lasx_xvhaddw_qu_du(sad, sad);                 \

void x264_pixel_sad_x3_16x16_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                   uint8_t *p_ref1, uint8_t *p_ref2,
                                   intptr_t i_ref_stride,
                                   int32_t p_sad_array[3] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    LOAD_REF_DATA_16W( p_ref0, sad0 );
    LOAD_REF_DATA_16W( p_ref1, sad1 );
    LOAD_REF_DATA_16W( p_ref2, sad2 );

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );
    p_ref0 += i_ref_stride_x4;
    p_ref1 += i_ref_stride_x4;
    p_ref2 += i_ref_stride_x4;

    LOAD_REF_DATA_16W( p_ref0, sad0 );
    LOAD_REF_DATA_16W( p_ref1, sad1 );
    LOAD_REF_DATA_16W( p_ref2, sad2 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
}

void x264_pixel_sad_x3_16x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  intptr_t i_ref_stride,
                                  int32_t p_sad_array[3] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    LOAD_REF_DATA_16W( p_ref0, sad0 );
    LOAD_REF_DATA_16W( p_ref1, sad1 );
    LOAD_REF_DATA_16W( p_ref2, sad2 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
}

#undef LOAD_REF_DATA_16W

#define LOAD_REF_DATA_8W( p_ref, sad)                                          \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,        \
                 ref0, ref1, ref2, ref3 );                                     \
    p_ref += i_ref_stride_x4;                                                  \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,        \
                 ref4, ref5, ref6, ref7 );                                     \
    ref0 = __lasx_xvilvl_d( ref1, ref0 );                                      \
    ref1 = __lasx_xvilvl_d( ref3, ref2 );                                      \
    ref2 = __lasx_xvilvl_d( ref5, ref4 );                                      \
    ref3 = __lasx_xvilvl_d( ref7, ref6 );                                      \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                               \
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );                               \
    diff = __lasx_xvabsd_bu( src0, ref0 );                                     \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                 \
    sad  = __lasx_xvadd_h(sad, diff);                                          \
    diff = __lasx_xvabsd_bu( src1, ref1 );                                     \
    diff = __lasx_xvhaddw_hu_bu( diff, diff );                                 \
    sad  = __lasx_xvadd_h(sad, diff);                                          \

void x264_pixel_sad_x3_8x16_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  intptr_t i_ref_stride,
                                  int32_t p_sad_array[3] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LOAD_REF_DATA_8W( p_ref0, sad0 );
    LOAD_REF_DATA_8W( p_ref1, sad1 );
    LOAD_REF_DATA_8W( p_ref2, sad2 );

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    p_ref0 += i_ref_stride_x4;
    p_ref1 += i_ref_stride_x4;
    p_ref2 += i_ref_stride_x4;

    LOAD_REF_DATA_8W( p_ref0, sad0 );
    LOAD_REF_DATA_8W( p_ref1, sad1 );
    LOAD_REF_DATA_8W( p_ref2, sad2 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
}

void x264_pixel_sad_x3_8x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 intptr_t i_ref_stride,
                                 int32_t p_sad_array[3] )
{
    SAD_LOAD

    src0 = __lasx_xvld(p_src, 0);
    src1 = __lasx_xvld(p_src, FENC_STRIDE);
    src2 = __lasx_xvldx(p_src, i_src_stride_x2);
    src3 = __lasx_xvldx(p_src, i_src_stride_x3);
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld(p_src, 0);
    src5 = __lasx_xvld(p_src, FENC_STRIDE);
    src6 = __lasx_xvldx(p_src, i_src_stride_x2);
    src7 = __lasx_xvldx(p_src, i_src_stride_x3);
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LOAD_REF_DATA_8W( p_ref0, sad0 );
    LOAD_REF_DATA_8W( p_ref1, sad1 );
    LOAD_REF_DATA_8W( p_ref2, sad2 );

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);
}

#undef SAD_LOAD
#undef LOAD_REF_DATA_8W

void x264_pixel_sad_x3_8x4_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 intptr_t i_ref_stride,
                                 int32_t p_sad_array[3] )
{
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i diff;
    __m256i sad0, sad1, sad2;
    intptr_t i_src_stride_x2 = FENC_STRIDE << 1;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_src_stride_x3 = i_src_stride_x2 + FENC_STRIDE;
    intptr_t i_ref_stride_x3 = i_ref_stride_x2 + i_ref_stride;

    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvld( p_src, FENC_STRIDE );
    src2 = __lasx_xvldx( p_src, i_src_stride_x2 );
    src3 = __lasx_xvldx( p_src, i_src_stride_x3 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );

#define LOAD_REF_DATA_8W_4H( p_ref, sad)                                \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3, \
                 ref0, ref1, ref2, ref3 );                              \
    ref0 = __lasx_xvilvl_d( ref1, ref0 );                               \
    ref1 = __lasx_xvilvl_d( ref3, ref2 );                               \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                        \
    diff = __lasx_xvabsd_bu( src0, ref0 );                              \
    sad = __lasx_xvhaddw_hu_bu( diff, diff );

    LOAD_REF_DATA_8W_4H( p_ref0, sad0 );
    LOAD_REF_DATA_8W_4H( p_ref1, sad1 );
    LOAD_REF_DATA_8W_4H( p_ref2, sad2 );

#undef LOAD_REF_DATA_8W_4H

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);

#undef ST_REF_DATA

}

void x264_pixel_sad_x3_4x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 intptr_t i_ref_stride,
                                 int32_t p_sad_array[3] )
{
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff;
    __m256i sad0 = __lasx_xvldi( 0 );
    __m256i sad1 = __lasx_xvldi( 0 );
    __m256i sad2 = __lasx_xvldi( 0 );
    intptr_t i_src_stride_x2 = FENC_STRIDE << 1;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_src_stride_x3 = i_src_stride_x2 + FENC_STRIDE;
    intptr_t i_ref_stride_x3 = i_ref_stride_x2 + i_ref_stride;
    intptr_t i_src_stride_x4 = i_src_stride_x2 << 1;
    intptr_t i_ref_stride_x4 = i_ref_stride_x2 << 1;

    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvld( p_src, FENC_STRIDE );
    src2 = __lasx_xvldx( p_src, i_src_stride_x2 );
    src3 = __lasx_xvldx( p_src, i_src_stride_x3 );
    p_src += i_src_stride_x4;
    src4 = __lasx_xvld( p_src, 0 );
    src5 = __lasx_xvld( p_src, FENC_STRIDE );
    src6 = __lasx_xvldx( p_src, i_src_stride_x2 );
    src7 = __lasx_xvldx( p_src, i_src_stride_x3 );
    src0 = __lasx_xvilvl_w( src1, src0 );
    src1 = __lasx_xvilvl_w( src3, src2 );
    src2 = __lasx_xvilvl_w( src5, src4 );
    src3 = __lasx_xvilvl_w( src7, src6 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );

#define LOAD_REF_DATA_4W_8H( p_ref, sad)                                       \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,        \
                 ref0, ref1, ref2, ref3 );                                     \
    p_ref += i_ref_stride_x4;                                                  \
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,        \
                 ref4, ref5, ref6, ref7 );                                     \
    ref0 = __lasx_xvilvl_w( ref1, ref0 );                                      \
    ref1 = __lasx_xvilvl_w( ref3, ref2 );                                      \
    ref2 = __lasx_xvilvl_w( ref5, ref4 );                                      \
    ref3 = __lasx_xvilvl_w( ref7, ref6 );                                      \
    ref0 = __lasx_xvilvl_d( ref1, ref0 );                                      \
    ref1 = __lasx_xvilvl_d( ref3, ref2 );                                      \
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );                               \
    diff = __lasx_xvabsd_bu( src0, ref0 );                                     \
    sad = __lasx_xvhaddw_hu_bu( diff, diff );

    LOAD_REF_DATA_4W_8H( p_ref0, sad0 );
    LOAD_REF_DATA_4W_8H( p_ref1, sad1 );
    LOAD_REF_DATA_4W_8H( p_ref2, sad2 );

#undef LOAD_REF_DATA_4W_8H

#define ST_REF_DATA(sad)                                  \
    sad = __lasx_xvhaddw_wu_hu(sad, sad);                 \
    sad = __lasx_xvhaddw_du_wu(sad, sad);                 \
    sad = __lasx_xvhaddw_qu_du(sad, sad);                 \

    ST_REF_DATA(sad0);
    p_sad_array[0] = __lasx_xvpickve2gr_wu(sad0, 0) + __lasx_xvpickve2gr_wu(sad0, 4);
    ST_REF_DATA(sad1);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(sad1, 0) + __lasx_xvpickve2gr_wu(sad1, 4);
    ST_REF_DATA(sad2);
    p_sad_array[2] = __lasx_xvpickve2gr_wu(sad2, 0) + __lasx_xvpickve2gr_wu(sad2, 4);

#undef ST_REF_DATA

}

void x264_pixel_sad_x3_4x4_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 intptr_t i_ref_stride,
                                 int32_t p_sad_array[3] )
{
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff;
    intptr_t i_src_stride_x2 = FENC_STRIDE << 1;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_src_stride_x3 = i_src_stride_x2 + FENC_STRIDE;
    intptr_t i_ref_stride_x3 = i_ref_stride_x2 + i_ref_stride;

    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvld( p_src, FENC_STRIDE );
    src2 = __lasx_xvldx( p_src, i_src_stride_x2 );
    src3 = __lasx_xvldx( p_src, i_src_stride_x3 );
    src0 = __lasx_xvilvl_w( src1, src0 );
    src1 = __lasx_xvilvl_w( src3, src2 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src0 = __lasx_xvpermi_q(src0, src0, 0x00);

    LASX_LOAD_4( p_ref0, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    LASX_LOAD_4( p_ref1, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref4, ref5, ref6, ref7 );
    ref0 = __lasx_xvilvl_w( ref1, ref0 );
    ref1 = __lasx_xvilvl_w( ref3, ref2 );
    ref0 = __lasx_xvilvl_d( ref1, ref0 );
    ref2 = __lasx_xvilvl_w( ref5, ref4 );
    ref3 = __lasx_xvilvl_w( ref7, ref6 );
    ref1 = __lasx_xvilvl_d( ref3, ref2 );
    ref0 = __lasx_xvpermi_q(ref0, ref1, 0x02);
    diff = __lasx_xvabsd_bu( src0, ref0 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvhaddw_wu_hu( diff, diff );
    diff = __lasx_xvhaddw_du_wu( diff, diff );
    diff = __lasx_xvhaddw_qu_du( diff, diff );

    p_sad_array[0] = __lasx_xvpickve2gr_wu(diff, 0);
    p_sad_array[1] = __lasx_xvpickve2gr_wu(diff, 4);
    LASX_LOAD_4( p_ref2, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    ref0 = __lasx_xvilvl_w( ref1, ref0 );
    ref1 = __lasx_xvilvl_w( ref3, ref2 );
    ref0 = __lasx_xvilvl_d( ref1, ref0 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvhaddw_wu_hu( diff, diff );
    diff = __lasx_xvhaddw_du_wu( diff, diff );
    diff = __lasx_xvhaddw_qu_du( diff, diff );
    p_sad_array[2] = __lasx_xvpickve2gr_wu(diff, 0);

}

static inline uint32_t sad_4width_lasx( uint8_t *p_src, int32_t i_src_stride,
                                        uint8_t *p_ref, int32_t i_ref_stride,
                                        int32_t i_height )
{
    int32_t i_ht_cnt;
    uint32_t result;
    uint8_t * p_src2;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff;
    __m256i sad = __lasx_xvldi( 0 );
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride + i_src_stride_x2;
    int32_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;
    int32_t i_src_stride_x8 = i_src_stride << 3;

    for( i_ht_cnt = ( i_height >> 3 ); i_ht_cnt--; )
    {
        src0 = __lasx_xvld( p_src, 0 );
        src1 = __lasx_xvldx( p_src, i_src_stride );
        src2 = __lasx_xvldx( p_src, i_src_stride_x2 );
        src3 = __lasx_xvldx( p_src, i_src_stride_x3 );
        p_src2 = p_src + i_src_stride_x4;
        src4 = __lasx_xvld( p_src2, 0 );
        src5 = __lasx_xvldx( p_src2, i_src_stride );
        src6 = __lasx_xvldx( p_src2, i_src_stride_x2 );
        src7 = __lasx_xvldx( p_src2, i_src_stride_x3 );
        p_src += i_src_stride_x8;
        src0 = __lasx_xvilvl_w( src1, src0 );
        src1 = __lasx_xvilvl_w( src3, src2 );
        src2 = __lasx_xvilvl_w( src5, src4 );
        src3 = __lasx_xvilvl_w( src7, src6 );
        src0 = __lasx_xvilvl_d( src1, src0 );
        src1 = __lasx_xvilvl_d( src3, src2 );
        src0 = __lasx_xvpermi_q( src0, src1, 0x20 );

        LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                     ref0, ref1, ref2, ref3 );
        p_ref += i_ref_stride_x4;
        LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                     ref4, ref5, ref6, ref7 );
        p_ref += i_ref_stride_x4;
        ref0 = __lasx_xvilvl_w( ref1, ref0 );
        ref1 = __lasx_xvilvl_w( ref3, ref2 );
        ref2 = __lasx_xvilvl_w( ref5, ref4 );
        ref3 = __lasx_xvilvl_w( ref7, ref6 );
        ref0 = __lasx_xvilvl_d( ref1, ref0 );
        ref1 = __lasx_xvilvl_d( ref3, ref2 );
        ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
        diff = __lasx_xvabsd_bu( src0, ref0 );
        diff = __lasx_xvhaddw_hu_bu( diff, diff );
        sad  = __lasx_xvadd_h( sad, diff );
    }
    sad = __lasx_xvhaddw_wu_hu(sad, sad);
    sad = __lasx_xvhaddw_du_wu(sad, sad);
    sad = __lasx_xvhaddw_qu_du(sad, sad);
    result = __lasx_xvpickve2gr_wu(sad, 0) + __lasx_xvpickve2gr_wu(sad, 4);

    return ( result );
}

int32_t x264_pixel_sad_16x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                   uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t result;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff, sad;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride + i_src_stride_x2;
    int32_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;

    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src4, src5, src6, src7 );
    p_src += i_src_stride_x4;
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref4, ref5, ref6, ref7 );
    p_ref += i_ref_stride_x4;
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );
    ref2 = __lasx_xvpermi_q( ref4, ref5, 0x20 );
    ref3 = __lasx_xvpermi_q( ref6, ref7, 0x20 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    sad  = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvabsd_bu( src1, ref1 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src2, ref2 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src3, ref3 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);

    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src4, src5, src6, src7 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref4, ref5, ref6, ref7 );
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );
    ref2 = __lasx_xvpermi_q( ref4, ref5, 0x20 );
    ref3 = __lasx_xvpermi_q( ref6, ref7, 0x20 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src1, ref1 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src2, ref2 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src3, ref3 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);

    sad = __lasx_xvhaddw_wu_hu(sad, sad);
    sad = __lasx_xvhaddw_du_wu(sad, sad);
    sad = __lasx_xvhaddw_qu_du(sad, sad);
    result = __lasx_xvpickve2gr_wu(sad, 0) + __lasx_xvpickve2gr_wu(sad, 4);
    return result;
}

int32_t x264_pixel_sad_16x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t result;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff, sad;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride + i_src_stride_x2;
    int32_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;

    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src4, src5, src6, src7 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );
    src2 = __lasx_xvpermi_q( src4, src5, 0x20 );
    src3 = __lasx_xvpermi_q( src6, src7, 0x20 );

    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref4, ref5, ref6, ref7 );
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );
    ref2 = __lasx_xvpermi_q( ref4, ref5, 0x20 );
    ref3 = __lasx_xvpermi_q( ref6, ref7, 0x20 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    sad  = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvabsd_bu( src1, ref1 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src2, ref2 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src3, ref3 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    sad = __lasx_xvhaddw_wu_hu(sad, sad);
    sad = __lasx_xvhaddw_du_wu(sad, sad);
    sad = __lasx_xvhaddw_qu_du(sad, sad);
    result = __lasx_xvpickve2gr_wu(sad, 0) + __lasx_xvpickve2gr_wu(sad, 4);

    return ( result );
}

int32_t x264_pixel_sad_8x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t result;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff, sad;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride + i_src_stride_x2;
    int32_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;

    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src4, src5, src6, src7 );
    p_src += i_src_stride_x4;
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref4, ref5, ref6, ref7 );
    p_ref += i_ref_stride_x4;
    ref0 = __lasx_xvilvl_d( ref1, ref0 );
    ref1 = __lasx_xvilvl_d( ref3, ref2 );
    ref2 = __lasx_xvilvl_d( ref5, ref4 );
    ref3 = __lasx_xvilvl_d( ref7, ref6 );
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    sad  = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvabsd_bu( src1, ref1 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);

    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src4, src5, src6, src7 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref4, ref5, ref6, ref7 );
    ref0 = __lasx_xvilvl_d( ref1, ref0 );
    ref1 = __lasx_xvilvl_d( ref3, ref2 );
    ref2 = __lasx_xvilvl_d( ref5, ref4 );
    ref3 = __lasx_xvilvl_d( ref7, ref6 );
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    diff = __lasx_xvabsd_bu( src1, ref1 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);

    sad = __lasx_xvhaddw_wu_hu(sad, sad);
    sad = __lasx_xvhaddw_du_wu(sad, sad);
    sad = __lasx_xvhaddw_qu_du(sad, sad);
    result = __lasx_xvpickve2gr_wu(sad, 0) + __lasx_xvpickve2gr_wu(sad, 4);

    return ( result );
}

int32_t x264_pixel_sad_8x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t result;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff, sad;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride + i_src_stride_x2;
    int32_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;
    int32_t i_src_stride_x4 = i_src_stride_x2 << 1;
    int32_t i_ref_stride_x4 = i_ref_stride_x2 << 1;

    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    LASX_LOAD_4( p_src, i_src_stride, i_src_stride_x2, i_src_stride_x3,
                 src4, src5, src6, src7 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src2 = __lasx_xvilvl_d( src5, src4 );
    src3 = __lasx_xvilvl_d( src7, src6 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );
    src1 = __lasx_xvpermi_q( src2, src3, 0x20 );

    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    LASX_LOAD_4( p_ref, i_ref_stride, i_ref_stride_x2, i_ref_stride_x3,
                 ref4, ref5, ref6, ref7 );
    ref0 = __lasx_xvilvl_d( ref1, ref0 );
    ref1 = __lasx_xvilvl_d( ref3, ref2 );
    ref2 = __lasx_xvilvl_d( ref5, ref4 );
    ref3 = __lasx_xvilvl_d( ref7, ref6 );
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
    ref1 = __lasx_xvpermi_q( ref2, ref3, 0x20 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    sad  = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvabsd_bu( src1, ref1 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    sad  = __lasx_xvadd_h(sad, diff);
    sad = __lasx_xvhaddw_wu_hu(sad, sad);
    sad = __lasx_xvhaddw_du_wu(sad, sad);
    sad = __lasx_xvhaddw_qu_du(sad, sad);
    result = __lasx_xvpickve2gr_wu(sad, 0) + __lasx_xvpickve2gr_wu(sad, 4);

    return ( result );
}

int32_t x264_pixel_sad_8x4_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i diff;
    int32_t result;
    intptr_t i_src_stride_x2 = i_src_stride << 1;
    intptr_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;

    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvldx( p_src, i_src_stride );
    src2 = __lasx_xvldx( p_src, i_src_stride_x2 );
    src3 = __lasx_xvldx( p_src, i_src_stride_x3 );
    src0 = __lasx_xvilvl_d( src1, src0 );
    src1 = __lasx_xvilvl_d( src3, src2 );
    src0 = __lasx_xvpermi_q( src0, src1, 0x20 );

    ref0 = __lasx_xvld( p_ref, 0 );
    ref1 = __lasx_xvldx( p_ref, i_ref_stride );
    ref2 = __lasx_xvldx( p_ref, i_ref_stride_x2 );
    ref3 = __lasx_xvldx( p_ref, i_ref_stride_x3 );
    ref0 = __lasx_xvilvl_d( ref1, ref0 );
    ref1 = __lasx_xvilvl_d( ref3, ref2 );
    ref0 = __lasx_xvpermi_q( ref0, ref1, 0x20 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvhaddw_wu_hu( diff, diff );
    diff = __lasx_xvhaddw_du_wu( diff, diff );
    diff = __lasx_xvhaddw_qu_du( diff, diff );
    result = __lasx_xvpickve2gr_wu(diff, 0) + __lasx_xvpickve2gr_wu(diff, 4);
    return ( result );
}

int32_t x264_pixel_sad_4x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride )
{
    return sad_4width_lasx( p_src, i_src_stride, p_ref, i_ref_stride, 16 );
}

int32_t x264_pixel_sad_4x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    return sad_4width_lasx( p_src, i_src_stride, p_ref, i_ref_stride, 8 );
}

int32_t __attribute__ ((noinline)) x264_pixel_sad_4x4_lasx(
                                 uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i diff;
    int32_t result;
    intptr_t i_src_stride_x2 = i_src_stride << 1;
    intptr_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;
    intptr_t i_ref_stride_x2 = i_ref_stride << 1;
    intptr_t i_ref_stride_x3 = i_ref_stride + i_ref_stride_x2;

    src0 = __lasx_xvld( p_src, 0);
    src1 = __lasx_xvldx( p_src, i_src_stride );
    src2 = __lasx_xvldx( p_src, i_src_stride_x2 );
    src3 = __lasx_xvldx( p_src, i_src_stride_x3 );
    src0 = __lasx_xvilvl_w( src1, src0 );
    src1 = __lasx_xvilvl_w( src3, src2 );
    src0 = __lasx_xvilvl_d( src1, src0 );

    ref0 = __lasx_xvld( p_ref, 0 );
    ref1 = __lasx_xvldx( p_ref, i_ref_stride );
    ref2 = __lasx_xvldx( p_ref, i_ref_stride_x2 );
    ref3 = __lasx_xvldx( p_ref, i_ref_stride_x3 );
    ref0 = __lasx_xvilvl_w( ref1, ref0 );
    ref1 = __lasx_xvilvl_w( ref3, ref2 );
    ref0 = __lasx_xvilvl_d( ref1, ref0 );
    diff = __lasx_xvabsd_bu( src0, ref0 );
    diff = __lasx_xvhaddw_hu_bu( diff, diff );
    diff = __lasx_xvhaddw_wu_hu( diff, diff );
    diff = __lasx_xvhaddw_du_wu( diff, diff );
    diff = __lasx_xvhaddw_qu_du( diff, diff );
    result = __lasx_xvpickve2gr_w(diff, 0);

    return ( result );
}

static inline uint64_t pixel_hadamard_ac_8x8_lasx( uint8_t *p_pix,
                                                   int32_t i_stride )
{
    uint32_t u_sum4 = 0, u_sum8 = 0, u_dc;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i diff0, diff1, diff2, diff3;
    __m256i sub0, sub1, sub2, sub3;
    __m256i temp0, temp1, temp2, temp3;
    int32_t i_stride2 = i_stride << 1;
    int32_t i_stride3 = i_stride2 + i_stride;
    int32_t i_stride4 = i_stride2 << 1;
    v16i16  dc;

    LASX_LOAD_4(p_pix, i_stride, i_stride2, i_stride3, src0, src1, src2, src3);
    p_pix += i_stride4;
    LASX_LOAD_4(p_pix, i_stride, i_stride2, i_stride3, src4, src5, src6, src7);

    diff0 = __lasx_xvilvl_d(src1, src0);
    diff1 = __lasx_xvilvl_d(src3, src2);
    diff2 = __lasx_xvilvl_d(src5, src4);
    diff3 = __lasx_xvilvl_d(src7, src6);
    diff0 = __lasx_xvpermi_q(diff0, diff2, 0x02);
    diff1 = __lasx_xvpermi_q(diff1, diff3, 0x02);
    diff2 = __lasx_xvpickev_b(diff1, diff0);
    diff3 = __lasx_xvpickod_b(diff1, diff0);
    temp0 = __lasx_xvaddwev_h_bu(diff2, diff3);
    temp1 = __lasx_xvaddwod_h_bu(diff2, diff3);
    temp2 = __lasx_xvsubwev_h_bu(diff2, diff3);
    temp3 = __lasx_xvsubwod_h_bu(diff2, diff3);

    diff0 = __lasx_xvadd_h(temp0, temp1);
    diff1 = __lasx_xvadd_h(temp2, temp3);
    diff2 = __lasx_xvsub_h(temp0, temp1);
    diff3 = __lasx_xvsub_h(temp2, temp3);

    temp0 = __lasx_xvilvl_h(diff1, diff0);
    temp1 = __lasx_xvilvh_h(diff1, diff0);
    temp2 = __lasx_xvilvl_h(diff3, diff2);
    temp3 = __lasx_xvilvh_h(diff3, diff2);

    diff0 = __lasx_xvilvl_w(temp2, temp0);
    diff1 = __lasx_xvilvh_w(temp2, temp0);
    diff2 = __lasx_xvilvl_w(temp3, temp1);
    diff3 = __lasx_xvilvh_w(temp3, temp1);

    temp0 = __lasx_xvadd_h(diff0, diff1);
    temp2 = __lasx_xvadd_h(diff2, diff3);
    temp1 = __lasx_xvsub_h(diff0, diff1);
    temp3 = __lasx_xvsub_h(diff2, diff3);

    diff0 = __lasx_xvadd_h(temp0, temp2);
    diff1 = __lasx_xvadd_h(temp1, temp3);
    diff2 = __lasx_xvsub_h(temp0, temp2);
    diff3 = __lasx_xvsub_h(temp1, temp3);

    dc = (v16i16)diff0;
    u_dc = (uint16_t)(dc[0] + dc[4] + dc[8] + dc[12]);

    sub0 = __lasx_xvadda_h(diff0, diff1);
    sub1 = __lasx_xvadda_h(diff2, diff3);

    sub0 = __lasx_xvadd_h(sub0, sub1);
    sub1 = __lasx_xvpermi_d(sub0, 0x4E);
    sub0 = __lasx_xvadd_h(sub0, sub1);
    sub0 = __lasx_xvhaddw_wu_hu(sub0, sub0);
    sub0 = __lasx_xvhaddw_du_wu(sub0, sub0);
    sub0 = __lasx_xvhaddw_qu_du(sub0, sub0);
    u_sum4 = __lasx_xvpickve2gr_wu(sub0, 0);

    temp0 = __lasx_xvpackev_h(diff1, diff0);
    temp1 = __lasx_xvpackev_h(diff3, diff2);
    temp2 = __lasx_xvpackod_h(diff1, diff0);
    temp3 = __lasx_xvpackod_h(diff3, diff2);

    sub0 = __lasx_xvilvl_d(temp1, temp0);
    sub1 = __lasx_xvilvh_d(temp1, temp0);
    sub2 = __lasx_xvilvl_d(temp3, temp2);
    sub3 = __lasx_xvilvh_d(temp3, temp2);

    diff0 = __lasx_xvpermi_q(sub0, sub2, 0x02);
    diff1 = __lasx_xvpermi_q(sub1, sub2, 0x12);
    diff2 = __lasx_xvpermi_q(sub0, sub3, 0x03);
    diff3 = __lasx_xvpermi_q(sub1, sub3, 0x13);

    temp0 = __lasx_xvadd_h(diff0, diff1);
    temp1 = __lasx_xvsub_h(diff0, diff1);
    temp2 = __lasx_xvadd_h(diff2, diff3);
    temp3 = __lasx_xvsub_h(diff2, diff3);

    diff0 = __lasx_xvadd_h(temp0, temp2);
    diff1 = __lasx_xvadd_h(temp1, temp3);
    diff2 = __lasx_xvsub_h(temp0, temp2);
    diff3 = __lasx_xvsub_h(temp1, temp3);

    sub0 = __lasx_xvadda_h(diff0, diff1);
    sub1 = __lasx_xvadda_h(diff2, diff3);
    sub0 = __lasx_xvadd_h(sub0, sub1);
    sub1 = __lasx_xvpermi_d(sub0, 0x4E);
    sub0 = __lasx_xvadd_h(sub0, sub1);
    sub0 = __lasx_xvhaddw_wu_hu(sub0, sub0);
    sub0 = __lasx_xvhaddw_du_wu(sub0, sub0);
    sub0 = __lasx_xvhaddw_qu_du(sub0, sub0);
    u_sum8 = __lasx_xvpickve2gr_wu(sub0, 0);

    u_sum4 = u_sum4 - u_dc;
    u_sum8 = u_sum8 - u_dc;

    return ((uint64_t) u_sum8 << 32) + u_sum4;
}

static inline uint64_t pixel_hadamard_ac_16x8_lasx( uint8_t *p_pix,
                                                    int32_t i_stride )
{
    uint32_t u_sum4 = 0, u_sum8 = 0, u_dc;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i diff0, diff1, diff2, diff3, diff4, diff5, diff6, diff7;
    __m256i sub0, sub1, sub2, sub3, sub4, sub5, sub6, sub7;
    int32_t i_stride2 = i_stride << 1;
    int32_t i_stride3 = i_stride2 + i_stride;
    int32_t i_stride4 = i_stride2 << 1;
    v16i16  dc;

    LASX_LOAD_4(p_pix, i_stride, i_stride2, i_stride3, src0, src1, src2, src3);
    p_pix += i_stride4;
    LASX_LOAD_4(p_pix, i_stride, i_stride2, i_stride3, src4, src5, src6, src7);

    diff0 = __lasx_xvpermi_q(src0, src4, 0x02);
    diff1 = __lasx_xvpermi_q(src1, src5, 0x02);
    diff2 = __lasx_xvpermi_q(src2, src6, 0x02);
    diff3 = __lasx_xvpermi_q(src3, src7, 0x02);

    diff4 = __lasx_xvpickev_b(diff1, diff0);
    diff5 = __lasx_xvpickod_b(diff1, diff0);
    diff6 = __lasx_xvpickev_b(diff3, diff2);
    diff7 = __lasx_xvpickod_b(diff3, diff2);

    src0 = __lasx_xvaddwev_h_bu(diff4, diff5);
    src1 = __lasx_xvaddwod_h_bu(diff4, diff5);
    src2 = __lasx_xvsubwev_h_bu(diff4, diff5);
    src3 = __lasx_xvsubwod_h_bu(diff4, diff5);
    src4 = __lasx_xvaddwev_h_bu(diff6, diff7);
    src5 = __lasx_xvaddwod_h_bu(diff6, diff7);
    src6 = __lasx_xvsubwev_h_bu(diff6, diff7);
    src7 = __lasx_xvsubwod_h_bu(diff6, diff7);

    diff0 = __lasx_xvadd_h(src0, src1);
    diff1 = __lasx_xvadd_h(src2, src3);
    diff2 = __lasx_xvsub_h(src0, src1);
    diff3 = __lasx_xvsub_h(src2, src3);
    diff4 = __lasx_xvadd_h(src4, src5);
    diff5 = __lasx_xvadd_h(src6, src7);
    diff6 = __lasx_xvsub_h(src4, src5);
    diff7 = __lasx_xvsub_h(src6, src7);

    src0 = __lasx_xvilvl_h(diff1, diff0);
    src1 = __lasx_xvilvh_h(diff1, diff0);
    src2 = __lasx_xvilvl_h(diff3, diff2);
    src3 = __lasx_xvilvh_h(diff3, diff2);

    src4 = __lasx_xvilvl_h(diff5, diff4);
    src5 = __lasx_xvilvh_h(diff5, diff4);
    src6 = __lasx_xvilvl_h(diff7, diff6);
    src7 = __lasx_xvilvh_h(diff7, diff6);

    diff0 = __lasx_xvilvl_w(src2, src0);
    diff1 = __lasx_xvilvh_w(src2, src0);
    diff2 = __lasx_xvilvl_w(src3, src1);
    diff3 = __lasx_xvilvh_w(src3, src1);

    diff4 = __lasx_xvilvl_w(src6, src4);
    diff5 = __lasx_xvilvh_w(src6, src4);
    diff6 = __lasx_xvilvl_w(src7, src5);
    diff7 = __lasx_xvilvh_w(src7, src5);

    src0 = __lasx_xvadd_h(diff0, diff2);
    src4 = __lasx_xvadd_h(diff1, diff3);
    src2 = __lasx_xvadd_h(diff4, diff6);
    src6 = __lasx_xvadd_h(diff5, diff7);
    src1 = __lasx_xvsub_h(diff0, diff2);
    src5 = __lasx_xvsub_h(diff1, diff3);
    src3 = __lasx_xvsub_h(diff4, diff6);
    src7 = __lasx_xvsub_h(diff5, diff7);

    diff0 = __lasx_xvadd_h(src0, src2);
    diff1 = __lasx_xvadd_h(src1, src3);
    diff2 = __lasx_xvsub_h(src0, src2);
    diff3 = __lasx_xvsub_h(src1, src3);
    diff4 = __lasx_xvadd_h(src4, src6);
    diff5 = __lasx_xvadd_h(src5, src7);
    diff6 = __lasx_xvsub_h(src4, src6);
    diff7 = __lasx_xvsub_h(src5, src7);

    dc = (v16i16)diff0;
    u_dc = (uint16_t)(dc[0] + dc[4] + dc[8] + dc[12]);
    dc = (v16i16)diff4;
    u_dc += (uint16_t)(dc[0] + dc[4] + dc[8] + dc[12]);

    sub0 = __lasx_xvadda_h(diff0, diff1);
    sub1 = __lasx_xvadda_h(diff2, diff3);
    sub2 = __lasx_xvadda_h(diff4, diff5);
    sub3 = __lasx_xvadda_h(diff6, diff7);
    sub0 = __lasx_xvadd_h(sub0, sub1);
    sub0 = __lasx_xvadd_h(sub0, sub2);
    sub0 = __lasx_xvadd_h(sub0, sub3);
    sub0 = __lasx_xvhaddw_wu_hu(sub0, sub0);
    sub0 = __lasx_xvhaddw_du_wu(sub0, sub0);
    sub0 = __lasx_xvhaddw_qu_du(sub0, sub0);
    u_sum4 = __lasx_xvpickve2gr_wu(sub0, 0) + __lasx_xvpickve2gr_wu(sub0, 4);

    sub0 = __lasx_xvpackev_h(diff1, diff0);
    sub1 = __lasx_xvpackod_h(diff1, diff0);
    sub2 = __lasx_xvpackev_h(diff3, diff2);
    sub3 = __lasx_xvpackod_h(diff3, diff2);
    sub4 = __lasx_xvpackev_h(diff5, diff4);
    sub5 = __lasx_xvpackod_h(diff5, diff4);
    sub6 = __lasx_xvpackev_h(diff7, diff6);
    sub7 = __lasx_xvpackod_h(diff7, diff6);

    src0 = __lasx_xvilvl_d(sub2, sub0);
    src1 = __lasx_xvilvh_d(sub2, sub0);
    src2 = __lasx_xvilvl_d(sub3, sub1);
    src3 = __lasx_xvilvh_d(sub3, sub1);
    src4 = __lasx_xvilvl_d(sub6, sub4);
    src5 = __lasx_xvilvh_d(sub6, sub4);
    src6 = __lasx_xvilvl_d(sub7, sub5);
    src7 = __lasx_xvilvh_d(sub7, sub5);

    diff0 = __lasx_xvpermi_q(src0, src4, 0x02);
    diff1 = __lasx_xvpermi_q(src1, src5, 0x02);
    diff2 = __lasx_xvpermi_q(src0, src4, 0x13);
    diff3 = __lasx_xvpermi_q(src1, src5, 0x13);
    diff4 = __lasx_xvpermi_q(src2, src6, 0x02);
    diff5 = __lasx_xvpermi_q(src2, src6, 0x13);
    diff6 = __lasx_xvpermi_q(src3, src7, 0x02);
    diff7 = __lasx_xvpermi_q(src3, src7, 0x13);

    src0 = __lasx_xvadd_h(diff0, diff1);
    src1 = __lasx_xvsub_h(diff0, diff1);
    src2 = __lasx_xvadd_h(diff2, diff3);
    src3 = __lasx_xvsub_h(diff2, diff3);
    src4 = __lasx_xvadd_h(diff4, diff5);
    src5 = __lasx_xvsub_h(diff4, diff5);
    src6 = __lasx_xvadd_h(diff6, diff7);
    src7 = __lasx_xvsub_h(diff6, diff7);

    diff0 = __lasx_xvadd_h(src0, src2);
    diff1 = __lasx_xvadd_h(src1, src3);
    diff2 = __lasx_xvsub_h(src0, src2);
    diff3 = __lasx_xvsub_h(src1, src3);
    diff4 = __lasx_xvadd_h(src4, src6);
    diff5 = __lasx_xvadd_h(src5, src7);
    diff6 = __lasx_xvsub_h(src4, src6);
    diff7 = __lasx_xvsub_h(src5, src7);

    sub0 = __lasx_xvadda_h(diff0, diff1);
    sub1 = __lasx_xvadda_h(diff2, diff3);
    sub2 = __lasx_xvadda_h(diff4, diff5);
    sub3 = __lasx_xvadda_h(diff6, diff7);

    sub0 = __lasx_xvadd_h(sub0, sub1);
    sub0 = __lasx_xvadd_h(sub0, sub2);
    sub0 = __lasx_xvadd_h(sub0, sub3);

    sub0 = __lasx_xvhaddw_wu_hu(sub0, sub0);
    sub0 = __lasx_xvhaddw_du_wu(sub0, sub0);
    sub0 = __lasx_xvhaddw_qu_du(sub0, sub0);
    u_sum8 = __lasx_xvpickve2gr_wu(sub0, 0) + __lasx_xvpickve2gr_wu(sub0, 4);
    u_sum4 = u_sum4 - u_dc;
    u_sum8 = u_sum8 - u_dc;
    return ((uint64_t) u_sum8 << 32) + u_sum4;
}

uint64_t x264_pixel_hadamard_ac_8x8_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = pixel_hadamard_ac_8x8_lasx( p_pix, i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_8x16_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = pixel_hadamard_ac_8x8_lasx( p_pix, i_stride );
    u_sum += pixel_hadamard_ac_8x8_lasx( p_pix + ( i_stride << 3 ), i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_16x8_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = pixel_hadamard_ac_16x8_lasx( p_pix, i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_16x16_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = pixel_hadamard_ac_16x8_lasx( p_pix, i_stride );
    u_sum += pixel_hadamard_ac_16x8_lasx( p_pix + ( i_stride << 3 ), i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

static int32_t sa8d_8x8_lasx( uint8_t *p_src, int32_t i_src_stride,
                              uint8_t *p_ref, int32_t i_ref_stride )
{
    uint32_t u_sum = 0;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;
    int32_t i_src_stride_x4 = i_src_stride << 2;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_ref_stride_x3 = i_ref_stride_x2 + i_ref_stride;
    int32_t i_ref_stride_x4 = i_ref_stride << 2;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff0, diff1, diff2, diff3, diff4, diff5, diff6, diff7;
    __m256i temp0, temp1, temp2, temp3;
    v4u64 out;

    DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2, p_src,
               i_src_stride_x3, src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2, p_src,
               i_src_stride_x3, src4, src5, src6, src7 );
    DUP4_ARG2( __lasx_xvldx, p_ref, 0, p_ref, i_ref_stride, p_ref, i_ref_stride_x2,
               p_ref, i_ref_stride_x3, ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    DUP4_ARG2( __lasx_xvldx, p_ref, 0, p_ref, i_ref_stride, p_ref, i_ref_stride_x2,
               p_ref, i_ref_stride_x3, ref4, ref5, ref6, ref7 );

    DUP4_ARG2( __lasx_xvilvl_b, src0, ref0, src1, ref1, src2, ref2, src3, ref3,
               src0, src1, src2, src3 );
    DUP4_ARG2( __lasx_xvilvl_b, src4, ref4, src5, ref5, src6, ref6, src7, ref7,
               src4, src5, src6, src7 );
    DUP4_ARG2( __lasx_xvhsubw_hu_bu, src0, src0, src1, src1, src2, src2, src3, src3,
               src0, src1, src2, src3 );
    DUP4_ARG2( __lasx_xvhsubw_hu_bu, src4, src4, src5, src5, src6, src6, src7, src7,
               src4, src5, src6, src7 );
    LASX_TRANSPOSE8x8_H( src0, src1, src2, src3,
                         src4, src5, src6, src7,
                         src0, src1, src2, src3,
                         src4, src5, src6, src7 );
    LASX_BUTTERFLY_4_H( src0, src2, src3, src1, diff0, diff1, diff4, diff5 );
    LASX_BUTTERFLY_4_H( src4, src6, src7, src5, diff2, diff3, diff7, diff6 );
    LASX_BUTTERFLY_4_H( diff0, diff2, diff3, diff1, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff0, diff1, diff3, diff2 );
    LASX_BUTTERFLY_4_H( diff4, diff6, diff7, diff5, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff4, diff5, diff7, diff6 );
    LASX_TRANSPOSE8x8_H( diff0, diff1, diff2, diff3,
                         diff4, diff5, diff6, diff7,
                         diff0, diff1, diff2, diff3,
                         diff4, diff5, diff6, diff7 );
    LASX_BUTTERFLY_4_H( diff0, diff2, diff3, diff1, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff0, diff1, diff3, diff2 );
    LASX_BUTTERFLY_4_H( diff4, diff6, diff7, diff5, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff4, diff5, diff7, diff6 );

    temp0 = __lasx_xvadd_h( diff0, diff4 );
    temp1 = __lasx_xvadd_h( diff1, diff5 );
    temp2 = __lasx_xvadd_h( diff2, diff6 );
    temp3 = __lasx_xvadd_h( diff3, diff7 );

    diff0 = __lasx_xvabsd_h( diff0, diff4 );
    diff1 = __lasx_xvabsd_h( diff1, diff5 );
    diff2 = __lasx_xvabsd_h( diff2, diff6 );
    diff3 = __lasx_xvabsd_h( diff3, diff7 );
    diff0 = __lasx_xvadda_h( diff0, temp0 );
    diff1 = __lasx_xvadda_h( diff1, temp1 );
    diff2 = __lasx_xvadda_h( diff2, temp2 );
    diff3 = __lasx_xvadda_h( diff3, temp3 );

    diff0 = __lasx_xvadd_h( diff0, diff1 );
    diff0 = __lasx_xvadd_h( diff0, diff2 );
    diff0 = __lasx_xvadd_h( diff0, diff3 );

    diff0 = __lasx_xvhaddw_wu_hu( diff0, diff0 );
    out = ( v4u64 ) __lasx_xvhaddw_du_wu( diff0, diff0 );
    u_sum = out[0] + out[1];

    return u_sum;
}

static int32_t sa8d_8x16_lasx( uint8_t *p_src, int32_t i_src_stride,
                               uint8_t *p_ref, int32_t i_ref_stride )
{
    uint32_t u_sum = 0;
    int32_t i_src_stride_x2 = i_src_stride << 1;
    int32_t i_src_stride_x3 = i_src_stride_x2 + i_src_stride;
    int32_t i_src_stride_x4 = i_src_stride << 2;
    int32_t i_ref_stride_x2 = i_ref_stride << 1;
    int32_t i_ref_stride_x3 = i_ref_stride_x2 + i_ref_stride;
    int32_t i_ref_stride_x4 = i_ref_stride << 2;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i diff0, diff1, diff2, diff3, diff4, diff5, diff6, diff7;
    __m256i temp0, temp1, temp2, temp3;

    DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2, p_src,
               i_src_stride_x3, src0, src1, src2, src3 );
    p_src += i_src_stride_x4;
    DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_src_stride, p_src, i_src_stride_x2, p_src,
               i_src_stride_x3, src4, src5, src6, src7 );
    src0 = __lasx_xvpermi_d(src0, 0x50);
    src1 = __lasx_xvpermi_d(src1, 0x50);
    src2 = __lasx_xvpermi_d(src2, 0x50);
    src3 = __lasx_xvpermi_d(src3, 0x50);
    src4 = __lasx_xvpermi_d(src4, 0x50);
    src5 = __lasx_xvpermi_d(src5, 0x50);
    src6 = __lasx_xvpermi_d(src6, 0x50);
    src7 = __lasx_xvpermi_d(src7, 0x50);

    DUP4_ARG2( __lasx_xvldx, p_ref, 0, p_ref, i_ref_stride, p_ref, i_ref_stride_x2,
               p_ref, i_ref_stride_x3, ref0, ref1, ref2, ref3 );
    p_ref += i_ref_stride_x4;
    DUP4_ARG2( __lasx_xvldx, p_ref, 0, p_ref, i_ref_stride, p_ref, i_ref_stride_x2,
               p_ref, i_ref_stride_x3, ref4, ref5, ref6, ref7 );
    ref0 = __lasx_xvpermi_d(ref0, 0x50);
    ref1 = __lasx_xvpermi_d(ref1, 0x50);
    ref2 = __lasx_xvpermi_d(ref2, 0x50);
    ref3 = __lasx_xvpermi_d(ref3, 0x50);
    ref4 = __lasx_xvpermi_d(ref4, 0x50);
    ref5 = __lasx_xvpermi_d(ref5, 0x50);
    ref6 = __lasx_xvpermi_d(ref6, 0x50);
    ref7 = __lasx_xvpermi_d(ref7, 0x50);

    DUP4_ARG2( __lasx_xvilvl_b, src0, ref0, src1, ref1, src2, ref2, src3, ref3,
               src0, src1, src2, src3 );
    DUP4_ARG2( __lasx_xvilvl_b, src4, ref4, src5, ref5, src6, ref6, src7, ref7,
               src4, src5, src6, src7 );
    DUP4_ARG2( __lasx_xvhsubw_hu_bu, src0, src0, src1, src1, src2, src2, src3, src3,
               src0, src1, src2, src3 );
    DUP4_ARG2( __lasx_xvhsubw_hu_bu, src4, src4, src5, src5, src6, src6, src7, src7,
               src4, src5, src6, src7 );
    LASX_TRANSPOSE8x8_H( src0, src1, src2, src3,
                         src4, src5, src6, src7,
                         src0, src1, src2, src3,
                         src4, src5, src6, src7 );
    LASX_BUTTERFLY_4_H( src0, src2, src3, src1, diff0, diff1, diff4, diff5 );
    LASX_BUTTERFLY_4_H( src4, src6, src7, src5, diff2, diff3, diff7, diff6 );
    LASX_BUTTERFLY_4_H( diff0, diff2, diff3, diff1, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff0, diff1, diff3, diff2 );
    LASX_BUTTERFLY_4_H( diff4, diff6, diff7, diff5, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff4, diff5, diff7, diff6 );
    LASX_TRANSPOSE8x8_H( diff0, diff1, diff2, diff3,
                         diff4, diff5, diff6, diff7,
                         diff0, diff1, diff2, diff3,
                         diff4, diff5, diff6, diff7 );
    LASX_BUTTERFLY_4_H( diff0, diff2, diff3, diff1, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff0, diff1, diff3, diff2 );
    LASX_BUTTERFLY_4_H( diff4, diff6, diff7, diff5, temp0, temp2, temp3, temp1 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp3, temp2, diff4, diff5, diff7, diff6 );

    temp0 = __lasx_xvadd_h( diff0, diff4 );
    temp1 = __lasx_xvadd_h( diff1, diff5 );
    temp2 = __lasx_xvadd_h( diff2, diff6 );
    temp3 = __lasx_xvadd_h( diff3, diff7 );

    diff0 = __lasx_xvabsd_h( diff0, diff4 );
    diff1 = __lasx_xvabsd_h( diff1, diff5 );
    diff2 = __lasx_xvabsd_h( diff2, diff6 );
    diff3 = __lasx_xvabsd_h( diff3, diff7 );
    diff0 = __lasx_xvadda_h( diff0, temp0 );
    diff1 = __lasx_xvadda_h( diff1, temp1 );
    diff2 = __lasx_xvadda_h( diff2, temp2 );
    diff3 = __lasx_xvadda_h( diff3, temp3 );

    diff0 = __lasx_xvadd_h( diff0, diff1 );
    diff0 = __lasx_xvadd_h( diff0, diff2 );
    diff0 = __lasx_xvadd_h( diff0, diff3 );

    u_sum = LASX_HADD_UH_U32( diff0 );

    return u_sum;
}

int32_t x264_pixel_sa8d_8x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 )
{
    int32_t i32Sum = sa8d_8x8_lasx( p_pix1, i_stride, p_pix2, i_stride2 );

    return ( i32Sum + 2 ) >> 2;
}

int32_t x264_pixel_sa8d_16x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                    uint8_t *p_pix2, intptr_t i_stride2 )
{
    int32_t i32Sum = sa8d_8x16_lasx( p_pix1, i_stride, p_pix2, i_stride2 ) +
                     sa8d_8x16_lasx( p_pix1 + 8 * i_stride, i_stride,
                                     p_pix2 + 8 * i_stride2, i_stride2 );

    return ( i32Sum + 2 ) >> 2;
}

void x264_intra_sa8d_x3_8x8_lasx( uint8_t *p_enc, uint8_t p_edge[36],
                                  int32_t p_sad_array[3] )
{
    ALIGNED_ARRAY_16( uint8_t, pix, [8 * FDEC_STRIDE] );

    x264_intra_predict_v_8x8_lasx( pix, p_edge );
    p_sad_array[0] = x264_pixel_sa8d_8x8_lasx( pix, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_intra_predict_h_8x8_lasx( pix, p_edge );
    p_sad_array[1] = x264_pixel_sa8d_8x8_lasx( pix, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_intra_predict_dc_8x8_lasx( pix, p_edge );
    p_sad_array[2] = x264_pixel_sa8d_8x8_lasx( pix, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );
}

void x264_intra_satd_x3_4x4_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                  int32_t p_sad_array[3] )
{
    x264_intra_predict_vert_4x4_lasx( p_dec );
    p_sad_array[0] = x264_pixel_satd_4x4_lasx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_intra_predict_hor_4x4_lasx( p_dec );
    p_sad_array[1] = x264_pixel_satd_4x4_lasx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_intra_predict_dc_4x4_lasx( p_dec );
    p_sad_array[2] = x264_pixel_satd_4x4_lasx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );
}

void x264_intra_satd_x3_16x16_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                    int32_t p_sad_array[3] )
{
    x264_intra_predict_vert_16x16_lasx( p_dec );
    p_sad_array[0] = x264_pixel_satd_16x16_lasx( p_dec, FDEC_STRIDE,
                                                 p_enc, FENC_STRIDE );

    x264_intra_predict_hor_16x16_lasx( p_dec );
    p_sad_array[1] = x264_pixel_satd_16x16_lasx( p_dec, FDEC_STRIDE,
                                                 p_enc, FENC_STRIDE );

    x264_intra_predict_dc_16x16_lasx( p_dec );
    p_sad_array[2] = x264_pixel_satd_16x16_lasx( p_dec, FDEC_STRIDE,
                                                 p_enc, FENC_STRIDE );
}

void x264_intra_satd_x3_8x8c_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                   int32_t p_sad_array[3] )
{
    x264_intra_predict_dc_4blk_8x8_lasx( p_dec );
    p_sad_array[0] = x264_pixel_satd_8x8_lasx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_intra_predict_hor_8x8_lasx( p_dec );
    p_sad_array[1] = x264_pixel_satd_8x8_lasx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_intra_predict_vert_8x8_lasx( p_dec );
    p_sad_array[2] = x264_pixel_satd_8x8_lasx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_4x4_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                 int32_t p_sad_array[3] )
{
    x264_intra_predict_vert_4x4_lasx( p_dec );
    p_sad_array[0] = x264_pixel_sad_4x4_lasx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_intra_predict_hor_4x4_lasx( p_dec );
    p_sad_array[1] = x264_pixel_sad_4x4_lasx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_intra_predict_dc_4x4_lasx( p_dec );
    p_sad_array[2] = x264_pixel_sad_4x4_lasx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_16x16_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                   int32_t p_sad_array[3] )
{
    x264_intra_predict_vert_16x16_lasx( p_dec );
    p_sad_array[0] = x264_pixel_sad_16x16_lasx( p_dec, FDEC_STRIDE,
                                                p_enc, FENC_STRIDE );

    x264_intra_predict_hor_16x16_lasx( p_dec );
    p_sad_array[1] = x264_pixel_sad_16x16_lasx( p_dec, FDEC_STRIDE,
                                                p_enc, FENC_STRIDE );

    x264_intra_predict_dc_16x16_lasx( p_dec );
    p_sad_array[2] = x264_pixel_sad_16x16_lasx( p_dec, FDEC_STRIDE,
                                                p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_8x8_lasx( uint8_t *p_enc, uint8_t p_edge[36],
                                 int32_t p_sad_array[3] )
{
    ALIGNED_ARRAY_16( uint8_t, pix, [8 * FDEC_STRIDE] );

    x264_intra_predict_v_8x8_lasx( pix, p_edge );
    p_sad_array[0] = x264_pixel_sad_8x8_lasx( pix, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_intra_predict_h_8x8_lasx( pix, p_edge );
    p_sad_array[1] = x264_pixel_sad_8x8_lasx( pix, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_intra_predict_dc_8x8_lasx( pix, p_edge );
    p_sad_array[2] = x264_pixel_sad_8x8_lasx( pix, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_8x8c_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                  int32_t p_sad_array[3] )
{
    x264_intra_predict_dc_4blk_8x8_lasx( p_dec );
    p_sad_array[0] = x264_pixel_sad_8x8_lasx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_intra_predict_hor_8x8_lasx( p_dec );
    p_sad_array[1] = x264_pixel_sad_8x8_lasx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_intra_predict_vert_8x8_lasx( p_dec );
    p_sad_array[2] = x264_pixel_sad_8x8_lasx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );
}

#define SSD_LOAD_8(_p_src, _stride, _stride2, _stride3, _stride4,                  \
                   _src0, _src1, _src2, _src3, _src4, _src5, _src6, _src7)         \
{                                                                                  \
    _src0 = __lasx_xvld(_p_src, 0);                                                \
    _src1 = __lasx_xvldx(_p_src, _stride);                                         \
    _src2 = __lasx_xvldx(_p_src, _stride2);                                        \
    _src3 = __lasx_xvldx(_p_src, _stride3);                                        \
    _p_src += _stride4;                                                            \
    _src4 = __lasx_xvld(_p_src, 0);                                                \
    _src5 = __lasx_xvldx(_p_src, _stride);                                         \
    _src6 = __lasx_xvldx(_p_src, _stride2);                                        \
    _src7 = __lasx_xvldx(_p_src, _stride3);                                        \
}

#define SSD_INSERT_8(_src0, _src1, _src2, _src3, _src4, _src5, _src6, _src7,       \
                     _ref0, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7)       \
{                                                                                  \
    _src0 = __lasx_xvpermi_q(_src0, _src1, 0x02);                                  \
    _src2 = __lasx_xvpermi_q(_src2, _src3, 0x02);                                  \
    _src4 = __lasx_xvpermi_q(_src4, _src5, 0x02);                                  \
    _src6 = __lasx_xvpermi_q(_src6, _src7, 0x02);                                  \
                                                                                   \
    _ref0 = __lasx_xvpermi_q(_ref0, _ref1, 0x02);                                  \
    _ref2 = __lasx_xvpermi_q(_ref2, _ref3, 0x02);                                  \
    _ref4 = __lasx_xvpermi_q(_ref4, _ref5, 0x02);                                  \
    _ref6 = __lasx_xvpermi_q(_ref6, _ref7, 0x02);                                  \
}

#define SSD_SUB_8(_src0, _src1, _src2, _src3, _src4, _src5, _src6, _src7,          \
                  _ref0, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7)          \
{                                                                                  \
    _src1 = __lasx_xvsubwev_h_bu(_src0, _ref0);                                    \
    _ref1 = __lasx_xvsubwod_h_bu(_src0, _ref0);                                    \
    _src3 = __lasx_xvsubwev_h_bu(_src2, _ref2);                                    \
    _ref3 = __lasx_xvsubwod_h_bu(_src2, _ref2);                                    \
    _src5 = __lasx_xvsubwev_h_bu(_src4, _ref4);                                    \
    _ref5 = __lasx_xvsubwod_h_bu(_src4, _ref4);                                    \
    _src7 = __lasx_xvsubwev_h_bu(_src6, _ref6);                                    \
    _ref7 = __lasx_xvsubwod_h_bu(_src6, _ref6);                                    \
}


int32_t x264_pixel_ssd_16x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                   uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    intptr_t src_stride2 = i_src_stride << 1;
    intptr_t ref_stride2 = i_ref_stride << 1;
    intptr_t src_stride3 = i_src_stride + src_stride2;
    intptr_t ref_stride3 = i_ref_stride + ref_stride2;
    intptr_t src_stride4 = src_stride2 << 1;
    intptr_t ref_stride4 = ref_stride2 << 1;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i src8, src9, src10, src11, src12, src13, src14, src15;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15;

    SSD_LOAD_8(p_src, i_src_stride, src_stride2, src_stride3, src_stride4,
               src0, src1, src2, src3, src4, src5, src6, src7);
    p_src += src_stride4;
    SSD_LOAD_8(p_src, i_src_stride, src_stride2, src_stride3, src_stride4,
               src8, src9, src10, src11, src12, src13, src14, src15);

    SSD_LOAD_8(p_ref, i_ref_stride, ref_stride2, ref_stride3, ref_stride4,
               ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);
    p_ref += ref_stride4;
    SSD_LOAD_8(p_ref, i_ref_stride, ref_stride2, ref_stride3, ref_stride4,
               ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15);

    SSD_INSERT_8(src0, src1, src2, src3, src4, src5, src6, src7,
                 ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);
    SSD_INSERT_8(src8, src9, src10, src11, src12, src13, src14, src15,
                 ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15);

    SSD_SUB_8(src0, src1, src2, src3, src4, src5, src6, src7,
              ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);
    SSD_SUB_8(src8, src9, src10, src11, src12, src13, src14, src15,
              ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15);

    src0 = __lasx_xvmulwev_w_h(src1, src1);
    src0 = __lasx_xvmaddwod_w_h(src0, src1, src1);
    src0 = __lasx_xvmaddwev_w_h(src0, ref1, ref1);
    src0 = __lasx_xvmaddwod_w_h(src0, ref1, ref1);
    src0 = __lasx_xvmaddwev_w_h(src0, src3, src3);
    src0 = __lasx_xvmaddwod_w_h(src0, src3, src3);
    src0 = __lasx_xvmaddwev_w_h(src0, ref3, ref3);
    src0 = __lasx_xvmaddwod_w_h(src0, ref3, ref3);
    src0 = __lasx_xvmaddwev_w_h(src0, src5, src5);
    src0 = __lasx_xvmaddwod_w_h(src0, src5, src5);
    src0 = __lasx_xvmaddwev_w_h(src0, ref5, ref5);
    src0 = __lasx_xvmaddwod_w_h(src0, ref5, ref5);
    src0 = __lasx_xvmaddwev_w_h(src0, src7, src7);
    src0 = __lasx_xvmaddwod_w_h(src0, src7, src7);
    src0 = __lasx_xvmaddwev_w_h(src0, ref7, ref7);
    src0 = __lasx_xvmaddwod_w_h(src0, ref7, ref7);

    src0 = __lasx_xvmaddwev_w_h(src0, src9, src9);
    src0 = __lasx_xvmaddwod_w_h(src0, src9, src9);
    src0 = __lasx_xvmaddwev_w_h(src0, ref9, ref9);
    src0 = __lasx_xvmaddwod_w_h(src0, ref9, ref9);
    src0 = __lasx_xvmaddwev_w_h(src0, src11, src11);
    src0 = __lasx_xvmaddwod_w_h(src0, src11, src11);
    src0 = __lasx_xvmaddwev_w_h(src0, ref11, ref11);
    src0 = __lasx_xvmaddwod_w_h(src0, ref11, ref11);
    src0 = __lasx_xvmaddwev_w_h(src0, src13, src13);
    src0 = __lasx_xvmaddwod_w_h(src0, src13, src13);
    src0 = __lasx_xvmaddwev_w_h(src0, ref13, ref13);
    src0 = __lasx_xvmaddwod_w_h(src0, ref13, ref13);
    src0 = __lasx_xvmaddwev_w_h(src0, src15, src15);
    src0 = __lasx_xvmaddwod_w_h(src0, src15, src15);
    src0 = __lasx_xvmaddwev_w_h(src0, ref15, ref15);
    src0 = __lasx_xvmaddwod_w_h(src0, ref15, ref15);

    ref0 = __lasx_xvhaddw_d_w(src0, src0);
    ref0 = __lasx_xvhaddw_q_d(ref0, ref0);
    u_ssd = __lasx_xvpickve2gr_w(ref0, 0) + __lasx_xvpickve2gr_w(ref0, 4);

    return u_ssd;
}

int32_t x264_pixel_ssd_16x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    intptr_t src_stride2 = i_src_stride << 1;
    intptr_t ref_stride2 = i_ref_stride << 1;
    intptr_t src_stride3 = i_src_stride + src_stride2;
    intptr_t ref_stride3 = i_ref_stride + ref_stride2;
    intptr_t src_stride4 = src_stride2 << 1;
    intptr_t ref_stride4 = ref_stride2 << 1;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;

    SSD_LOAD_8(p_src, i_src_stride, src_stride2, src_stride3, src_stride4,
               src0, src1, src2, src3, src4, src5, src6, src7);

    SSD_LOAD_8(p_ref, i_ref_stride, ref_stride2, ref_stride3, ref_stride4,
               ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);

    SSD_INSERT_8(src0, src1, src2, src3, src4, src5, src6, src7,
                 ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);

    SSD_SUB_8(src0, src1, src2, src3, src4, src5, src6, src7,
              ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);

    src0 = __lasx_xvmulwev_w_h(src1, src1);
    src0 = __lasx_xvmaddwod_w_h(src0, src1, src1);
    src0 = __lasx_xvmaddwev_w_h(src0, ref1, ref1);
    src0 = __lasx_xvmaddwod_w_h(src0, ref1, ref1);
    src0 = __lasx_xvmaddwev_w_h(src0, src3, src3);
    src0 = __lasx_xvmaddwod_w_h(src0, src3, src3);
    src0 = __lasx_xvmaddwev_w_h(src0, ref3, ref3);
    src0 = __lasx_xvmaddwod_w_h(src0, ref3, ref3);
    src0 = __lasx_xvmaddwev_w_h(src0, src5, src5);
    src0 = __lasx_xvmaddwod_w_h(src0, src5, src5);
    src0 = __lasx_xvmaddwev_w_h(src0, ref5, ref5);
    src0 = __lasx_xvmaddwod_w_h(src0, ref5, ref5);
    src0 = __lasx_xvmaddwev_w_h(src0, src7, src7);
    src0 = __lasx_xvmaddwod_w_h(src0, src7, src7);
    src0 = __lasx_xvmaddwev_w_h(src0, ref7, ref7);
    src0 = __lasx_xvmaddwod_w_h(src0, ref7, ref7);

    ref0 = __lasx_xvhaddw_d_w(src0, src0);
    ref0 = __lasx_xvhaddw_q_d(ref0, ref0);
    u_ssd = __lasx_xvpickve2gr_w(ref0, 0) + __lasx_xvpickve2gr_w(ref0, 4);

    return u_ssd;
}

#undef SSD_LOAD_8
#undef SSD_INSERT_8
#undef SSD_SUB_8

#define SSD_LOAD_8(_p_src, _src_stride, _src0, _src1, _src2,                       \
                   _src3, _src4, _src5, _src6, _src7)                              \
{                                                                                  \
    _src0 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src1 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src2 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src3 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src4 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src5 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src6 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src7 = __lasx_xvldrepl_d(_p_src, 0 );                                         \
}

#define SSD_INSERT_8(_src0, _src1, _src2, _src3, _src4, _src5, _src6, _src7,       \
                     _ref0, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7)       \
{                                                                                  \
    _src0 = __lasx_xvilvl_b(_src0, _ref0);                                         \
    _src1 = __lasx_xvilvl_b(_src1, _ref1);                                         \
    _src2 = __lasx_xvilvl_b(_src2, _ref2);                                         \
    _src3 = __lasx_xvilvl_b(_src3, _ref3);                                         \
    _src4 = __lasx_xvilvl_b(_src4, _ref4);                                         \
    _src5 = __lasx_xvilvl_b(_src5, _ref5);                                         \
    _src6 = __lasx_xvilvl_b(_src6, _ref6);                                         \
    _src7 = __lasx_xvilvl_b(_src7, _ref7);                                         \
}

int32_t x264_pixel_ssd_8x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i src8, src9, src10, src11, src12, src13, src14, src15;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15;

    SSD_LOAD_8(p_src, i_src_stride, src0, src1, src2, src3,
               src4, src5, src6, src7);
    p_src += i_src_stride;
    SSD_LOAD_8(p_src, i_src_stride, src8, src9, src10, src11,
               src12, src13, src14, src15);
    SSD_LOAD_8(p_ref, i_ref_stride, ref0, ref1, ref2, ref3,
               ref4, ref5, ref6, ref7);
    p_ref += i_ref_stride;
    SSD_LOAD_8(p_ref, i_ref_stride, ref8, ref9, ref10, ref11,
               ref12, ref13, ref14, ref15);

    SSD_INSERT_8(src0, src1, src2, src3, src4, src5, src6, src7,
                 ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);
    SSD_INSERT_8(src8, src9, src10, src11, src12, src13, src14, src15,
                 ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15);

    src0 = __lasx_xvpermi_q(src0, src1, 0x02);
    src2 = __lasx_xvpermi_q(src2, src3, 0x02);
    src4 = __lasx_xvpermi_q(src4, src5, 0x02);
    src6 = __lasx_xvpermi_q(src6, src7, 0x02);
    src8 = __lasx_xvpermi_q(src8, src9, 0x02);
    src10 = __lasx_xvpermi_q(src10, src11, 0x02);
    src12 = __lasx_xvpermi_q(src12, src13, 0x02);
    src14 = __lasx_xvpermi_q(src14, src15, 0x02);
    ref0 = __lasx_xvhsubw_hu_bu(src0, src0);
    ref2 = __lasx_xvhsubw_hu_bu(src2, src2);
    ref4 = __lasx_xvhsubw_hu_bu(src4, src4);
    ref6 = __lasx_xvhsubw_hu_bu(src6, src6);
    ref8 = __lasx_xvhsubw_hu_bu(src8, src8);
    ref10 = __lasx_xvhsubw_hu_bu(src10, src10);
    ref12 = __lasx_xvhsubw_hu_bu(src12, src12);
    ref14 = __lasx_xvhsubw_hu_bu(src14, src14);
    src0 = __lasx_xvmulwev_w_h(ref0, ref0);
    src0 = __lasx_xvmaddwod_w_h(src0, ref0, ref0);
    src0 = __lasx_xvmaddwev_w_h(src0, ref2, ref2);
    src0 = __lasx_xvmaddwod_w_h(src0, ref2, ref2);
    src0 = __lasx_xvmaddwev_w_h(src0, ref4, ref4);
    src0 = __lasx_xvmaddwod_w_h(src0, ref4, ref4);
    src0 = __lasx_xvmaddwev_w_h(src0, ref6, ref6);
    src0 = __lasx_xvmaddwod_w_h(src0, ref6, ref6);
    src0 = __lasx_xvmaddwev_w_h(src0, ref8, ref8);
    src0 = __lasx_xvmaddwod_w_h(src0, ref8, ref8);
    src0 = __lasx_xvmaddwev_w_h(src0, ref10, ref10);
    src0 = __lasx_xvmaddwod_w_h(src0, ref10, ref10);
    src0 = __lasx_xvmaddwev_w_h(src0, ref12, ref12);
    src0 = __lasx_xvmaddwod_w_h(src0, ref12, ref12);
    src0 = __lasx_xvmaddwev_w_h(src0, ref14, ref14);
    src0 = __lasx_xvmaddwod_w_h(src0, ref14, ref14);
    ref0 = __lasx_xvhaddw_d_w(src0, src0);
    ref0 = __lasx_xvhaddw_q_d(ref0, ref0);
    u_ssd = __lasx_xvpickve2gr_w(ref0, 0) + __lasx_xvpickve2gr_w(ref0, 4);

    return u_ssd;
}

int32_t x264_pixel_ssd_8x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;

    SSD_LOAD_8(p_src, i_src_stride, src0, src1, src2, src3,
               src4, src5, src6, src7);
    SSD_LOAD_8(p_ref, i_ref_stride, ref0, ref1, ref2, ref3,
               ref4, ref5, ref6, ref7);

    SSD_INSERT_8(src0, src1, src2, src3, src4, src5, src6, src7,
                 ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);

    src0 = __lasx_xvpermi_q(src0, src1, 0x02);
    src2 = __lasx_xvpermi_q(src2, src3, 0x02);
    src4 = __lasx_xvpermi_q(src4, src5, 0x02);
    src6 = __lasx_xvpermi_q(src6, src7, 0x02);

    ref0 = __lasx_xvhsubw_hu_bu(src0, src0);
    ref2 = __lasx_xvhsubw_hu_bu(src2, src2);
    ref4 = __lasx_xvhsubw_hu_bu(src4, src4);
    ref6 = __lasx_xvhsubw_hu_bu(src6, src6);
    src0 = __lasx_xvmulwev_w_h(ref0, ref0);
    src0 = __lasx_xvmaddwod_w_h(src0, ref0, ref0);
    src0 = __lasx_xvmaddwev_w_h(src0, ref2, ref2);
    src0 = __lasx_xvmaddwod_w_h(src0, ref2, ref2);
    src0 = __lasx_xvmaddwev_w_h(src0, ref4, ref4);
    src0 = __lasx_xvmaddwod_w_h(src0, ref4, ref4);
    src0 = __lasx_xvmaddwev_w_h(src0, ref6, ref6);
    src0 = __lasx_xvmaddwod_w_h(src0, ref6, ref6);
    ref0 = __lasx_xvhaddw_d_w(src0, src0);
    ref0 = __lasx_xvhaddw_q_d(ref0, ref0);
    u_ssd = __lasx_xvpickve2gr_w(ref0, 0) + __lasx_xvpickve2gr_w(ref0, 4);

    return u_ssd;
}

int32_t x264_pixel_ssd_8x4_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;

    src0 = __lasx_xvldrepl_d( p_src, 0 );
    p_src += i_src_stride;
    src1 = __lasx_xvldrepl_d( p_src, 0 );
    p_src += i_src_stride;
    src2 = __lasx_xvldrepl_d( p_src, 0 );
    p_src += i_src_stride;
    src3 = __lasx_xvldrepl_d( p_src, 0 );

    ref0 = __lasx_xvldrepl_d( p_ref, 0 );
    p_ref += i_ref_stride;
    ref1 = __lasx_xvldrepl_d( p_ref, 0 );
    p_ref += i_ref_stride;
    ref2 = __lasx_xvldrepl_d( p_ref, 0 );
    p_ref += i_ref_stride;
    ref3 = __lasx_xvldrepl_d( p_ref, 0 );

    src0 = __lasx_xvilvl_b(src0, ref0);
    src1 = __lasx_xvilvl_b(src1, ref1);
    src2 = __lasx_xvilvl_b(src2, ref2);
    src3 = __lasx_xvilvl_b(src3, ref3);
    src0 = __lasx_xvpermi_q(src0, src1, 0x02);
    src2 = __lasx_xvpermi_q(src2, src3, 0x02);
    ref0 = __lasx_xvhsubw_hu_bu(src0, src0);
    ref2 = __lasx_xvhsubw_hu_bu(src2, src2);
    src0 = __lasx_xvmulwev_w_h(ref0, ref0);
    src0 = __lasx_xvmaddwod_w_h(src0, ref0, ref0);
    src0 = __lasx_xvmaddwev_w_h(src0, ref2, ref2);
    src0 = __lasx_xvmaddwod_w_h(src0, ref2, ref2);
    ref0 = __lasx_xvhaddw_d_w(src0, src0);
    ref0 = __lasx_xvhaddw_q_d(ref0, ref0);
    u_ssd = __lasx_xvpickve2gr_w(ref0, 0) + __lasx_xvpickve2gr_w(ref0, 4);

    return u_ssd;
}

#undef SSD_LOAD_8

#define SSD_LOAD_8(_p_src, _src_stride, _src0, _src1, _src2,                       \
                   _src3, _src4, _src5, _src6, _src7)                              \
{                                                                                  \
    _src0 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src1 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src2 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src3 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src4 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src5 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src6 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
    _p_src += _src_stride;                                                         \
    _src7 = __lasx_xvldrepl_w(_p_src, 0 );                                         \
}

int32_t x264_pixel_ssd_4x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i src8, src9, src10, src11, src12, src13, src14, src15;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;
    __m256i ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15;

    SSD_LOAD_8(p_src, i_src_stride, src0, src1, src2, src3,
               src4, src5, src6, src7);
    p_src += i_src_stride;
    SSD_LOAD_8(p_src, i_src_stride, src8, src9, src10, src11,
               src12, src13, src14, src15);
    SSD_LOAD_8(p_ref, i_ref_stride, ref0, ref1, ref2, ref3,
               ref4, ref5, ref6, ref7);
    p_ref += i_ref_stride;
    SSD_LOAD_8(p_ref, i_ref_stride, ref8, ref9, ref10, ref11,
               ref12, ref13, ref14, ref15);

    SSD_INSERT_8(src0, src1, src2, src3, src4, src5, src6, src7,
                 ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);
    SSD_INSERT_8(src8, src9, src10, src11, src12, src13, src14, src15,
                 ref8, ref9, ref10, ref11, ref12, ref13, ref14, ref15);

    src0 = __lasx_xvilvl_d(src1, src0);
    src2 = __lasx_xvilvl_d(src3, src2);
    src4 = __lasx_xvilvl_d(src5, src4);
    src6 = __lasx_xvilvl_d(src7, src6);
    src0 = __lasx_xvpermi_q(src0, src2, 0x02);
    src4 = __lasx_xvpermi_q(src4, src6, 0x02);

    src1 = __lasx_xvilvl_d(src9, src8);
    src3 = __lasx_xvilvl_d(src11, src10);
    src5 = __lasx_xvilvl_d(src13, src12);
    src7 = __lasx_xvilvl_d(src15, src14);
    src1 = __lasx_xvpermi_q(src1, src3, 0x02);
    src5 = __lasx_xvpermi_q(src5, src7, 0x02);

    ref0 = __lasx_xvhsubw_hu_bu(src0, src0);
    ref4 = __lasx_xvhsubw_hu_bu(src4, src4);
    src0 = __lasx_xvmulwev_w_h(ref0, ref0);
    ref0 = __lasx_xvmaddwod_w_h(src0, ref0, ref0);
    src4 = __lasx_xvmaddwev_w_h(ref0, ref4, ref4);
    ref4 = __lasx_xvmaddwod_w_h(src4, ref4, ref4);

    ref1 = __lasx_xvhsubw_hu_bu(src1, src1);
    ref5 = __lasx_xvhsubw_hu_bu(src5, src5);
    src1 = __lasx_xvmaddwev_w_h(ref4, ref1, ref1);
    src1 = __lasx_xvmaddwod_w_h(src1, ref1, ref1);
    src1 = __lasx_xvmaddwev_w_h(src1, ref5, ref5);
    src1 = __lasx_xvmaddwod_w_h(src1, ref5, ref5);
    ref4 = __lasx_xvhaddw_d_w(src1, src1);
    ref4 = __lasx_xvhaddw_q_d(ref4, ref4);
    u_ssd = __lasx_xvpickve2gr_w(ref4, 0) + __lasx_xvpickve2gr_w(ref4, 4);

    return u_ssd;
}

int32_t x264_pixel_ssd_4x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7;

    SSD_LOAD_8(p_src, i_src_stride, src0, src1, src2, src3,
               src4, src5, src6, src7);
    SSD_LOAD_8(p_ref, i_ref_stride, ref0, ref1, ref2, ref3,
               ref4, ref5, ref6, ref7);

    SSD_INSERT_8(src0, src1, src2, src3, src4, src5, src6, src7,
                 ref0, ref1, ref2, ref3, ref4, ref5, ref6, ref7);

    src0 = __lasx_xvilvl_d(src1, src0);
    src2 = __lasx_xvilvl_d(src3, src2);
    src4 = __lasx_xvilvl_d(src5, src4);
    src6 = __lasx_xvilvl_d(src7, src6);
    src0 = __lasx_xvpermi_q(src0, src2, 0x02);
    src4 = __lasx_xvpermi_q(src4, src6, 0x02);

    ref0 = __lasx_xvhsubw_hu_bu(src0, src0);
    ref4 = __lasx_xvhsubw_hu_bu(src4, src4);
    src0 = __lasx_xvmulwev_w_h(ref0, ref0);
    src0 = __lasx_xvmaddwod_w_h(src0, ref0, ref0);
    src0 = __lasx_xvmaddwev_w_h(src0, ref4, ref4);
    src0 = __lasx_xvmaddwod_w_h(src0, ref4, ref4);
    ref4 = __lasx_xvhaddw_d_w(src0, src0);
    ref4 = __lasx_xvhaddw_q_d(ref4, ref4);
    u_ssd = __lasx_xvpickve2gr_w(ref4, 0) + __lasx_xvpickve2gr_w(ref4, 4);

    return u_ssd;
}

int32_t x264_pixel_ssd_4x4_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride )
{
    uint32_t u_ssd;
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;

    src0 = __lasx_xvldrepl_w( p_src, 0 );
    p_src += i_src_stride;
    src1 = __lasx_xvldrepl_w( p_src, 0 );
    p_src += i_src_stride;
    src2 = __lasx_xvldrepl_w( p_src, 0 );
    p_src += i_src_stride;
    src3 = __lasx_xvldrepl_w( p_src, 0 );

    ref0 = __lasx_xvldrepl_w( p_ref, 0 );
    p_ref += i_ref_stride;
    ref1 = __lasx_xvldrepl_w( p_ref, 0 );
    p_ref += i_ref_stride;
    ref2 = __lasx_xvldrepl_w( p_ref, 0 );
    p_ref += i_ref_stride;
    ref3 = __lasx_xvldrepl_w( p_ref, 0 );

    src0 = __lasx_xvilvl_b(src0, ref0);
    src1 = __lasx_xvilvl_b(src1, ref1);
    src2 = __lasx_xvilvl_b(src2, ref2);
    src3 = __lasx_xvilvl_b(src3, ref3);
    src0 = __lasx_xvilvl_d(src1, src0);
    src2 = __lasx_xvilvl_d(src3, src2);
    src0 = __lasx_xvpermi_q(src0, src2, 0x02);
    ref0 = __lasx_xvhsubw_hu_bu(src0, src0);
    src0 = __lasx_xvmulwev_w_h(ref0, ref0);
    src0 = __lasx_xvmaddwod_w_h(src0, ref0, ref0);
    ref0 = __lasx_xvhaddw_d_w(src0, src0);
    ref0 = __lasx_xvhaddw_q_d(ref0, ref0);
    u_ssd = __lasx_xvpickve2gr_w(ref0, 0) + __lasx_xvpickve2gr_w(ref0, 4);

    return u_ssd;
}
#undef SSD_LOAD_8
#undef SSD_INSERT_8

#define LASX_CALC_MSE_AVG_B( src, ref, var, sub )                          \
{                                                                          \
    __m256i src_l0_m, src_l1_m;                                            \
    __m256i res_l0_m, res_l1_m;                                            \
                                                                           \
    src_l1_m = __lasx_xvilvl_b( src, ref );                                \
    src_l0_m = __lasx_xvilvh_b( src, ref );                                \
    DUP2_ARG2( __lasx_xvhsubw_hu_bu, src_l0_m, src_l0_m, src_l1_m,         \
               src_l1_m, res_l0_m, res_l1_m );                             \
    DUP2_ARG3( __lasx_xvdp2add_w_h, var, res_l0_m, res_l0_m,               \
               var, res_l1_m, res_l1_m, var, var );                        \
                                                                           \
    res_l0_m = __lasx_xvadd_h( res_l0_m, res_l1_m );                       \
    sub = __lasx_xvadd_h( sub, res_l0_m );                                 \
}

#define VARIANCE_WxH( sse, diff, shift )                                \
    ( ( sse ) - ( ( ( uint32_t )( diff ) * ( diff ) ) >> ( shift ) ) )

static inline uint32_t sse_diff_8width_lasx( uint8_t *p_src,
                                             int32_t i_src_stride,
                                             uint8_t *p_ref,
                                             int32_t i_ref_stride,
                                             int32_t i_height,
                                             int32_t *p_diff )
{
    int32_t i_ht_cnt;
    uint32_t u_sse;
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i avg = __lasx_xvldi( 0 );
    __m256i var = __lasx_xvldi( 0 );

    for( i_ht_cnt = ( i_height >> 2 ); i_ht_cnt--; )
    {
        src0 = __lasx_xvldrepl_d( p_src, 0 );
        p_src += i_src_stride;
        src1 = __lasx_xvldrepl_d( p_src, 0 );
        p_src += i_src_stride;
        src2 = __lasx_xvldrepl_d( p_src, 0 );
        p_src += i_src_stride;
        src3 = __lasx_xvldrepl_d( p_src, 0 );
        p_src += i_src_stride;

        ref0 = __lasx_xvldrepl_d( p_ref, 0 );
        p_ref += i_ref_stride;
        ref1 = __lasx_xvldrepl_d( p_ref, 0 );
        p_ref += i_ref_stride;
        ref2 = __lasx_xvldrepl_d( p_ref, 0 );
        p_ref += i_ref_stride;
        ref3 = __lasx_xvldrepl_d( p_ref, 0 );
        p_ref += i_ref_stride;

        DUP4_ARG2( __lasx_xvpickev_d, src1, src0, src3, src2, ref1, ref0, ref3, ref2,
                   src0, src1, ref0, ref1 );
        src0 = __lasx_xvpermi_q( src1, src0, 0x20 );
        ref0 = __lasx_xvpermi_q( ref1, ref0, 0x20 );
        LASX_CALC_MSE_AVG_B( src0, ref0, var, avg );
    }

    avg = __lasx_xvhaddw_w_h( avg, avg );
    *p_diff = LASX_HADD_SW_S32( avg );
    u_sse = LASX_HADD_SW_S32( var );

    return u_sse;
}

static uint64_t avc_pixel_var16width_lasx( uint8_t *p_pix, int32_t i_stride,
                                           uint8_t i_height )
{
    uint32_t u_sum = 0, u_sqr_out = 0, u_cnt;
    int32_t i_stride_x2 = i_stride << 1;
    int32_t i_stride_x3 = i_stride_x2 + i_stride;
    int32_t i_stride_x4 = i_stride << 2;
    int32_t i_stride_x5 = i_stride_x4 + i_stride;
    int32_t i_stride_x6 = i_stride_x4 + i_stride_x2;
    int32_t i_stride_x7 = i_stride_x4 + i_stride_x3;
    __m256i pix0, pix1, pix2, pix3, pix4, pix5, pix6, pix7;
    __m256i zero = __lasx_xvldi( 0 );
    __m256i add, pix_h, pix_l;
    __m256i sqr = __lasx_xvldi( 0 );

#define LASX_PIXEL_VAR_16W( src0, src1 )                       \
    src0 = __lasx_xvpermi_q( src1, src0, 0x20 );               \
    add = __lasx_xvhaddw_hu_bu( src0, src0 );                  \
    u_sum += LASX_HADD_UH_U32( add );                          \
    pix_h =__lasx_xvilvl_b( zero, src0 );                      \
    pix_l =__lasx_xvilvh_b( zero, src0 );                      \
    DUP2_ARG3( __lasx_xvdp2add_w_h, sqr, pix_h, pix_h,         \
               sqr, pix_l, pix_l, sqr, sqr );

    for( u_cnt = ( i_height >> 3 ); u_cnt--; )
    {
        DUP4_ARG2( __lasx_xvldx, p_pix, 0, p_pix, i_stride, p_pix, i_stride_x2, p_pix,
                   i_stride_x3, pix0, pix1, pix2, pix3 );
        DUP4_ARG2( __lasx_xvldx, p_pix, i_stride_x4, p_pix, i_stride_x5, p_pix,
                   i_stride_x6, p_pix, i_stride_x7, pix4, pix5, pix6, pix7 );
        p_pix += ( i_stride << 3 );

        LASX_PIXEL_VAR_16W( pix0, pix1 );
        LASX_PIXEL_VAR_16W( pix2, pix3 );
        LASX_PIXEL_VAR_16W( pix4, pix5 );
        LASX_PIXEL_VAR_16W( pix6, pix7 );
    }

    u_sqr_out = LASX_HADD_SW_S32( sqr );

#undef LASX_PIXEL_VAR_16W

    return ( u_sum + ( ( uint64_t ) u_sqr_out << 32 ) );
}

static uint64_t avc_pixel_var8width_lasx( uint8_t *p_pix, int32_t i_stride,
                                          uint8_t i_height )
{
    uint32_t u_sum = 0, u_sqr_out = 0, u_cnt;
    __m256i pix0, pix1, pix2, pix3, pix4, pix5, pix6, pix7;
    __m256i zero = __lasx_xvldi( 0 );
    __m256i add, pix_h, pix_l;
    __m256i sqr = __lasx_xvldi( 0 );

#define LASX_PIXEL_VAR_8W( src0, src1, src2, src3 )            \
    src0 = __lasx_xvpickev_d( src1, src0 );                    \
    src1 = __lasx_xvpickev_d( src3, src2 );                    \
    src0 = __lasx_xvpermi_q( src1, src0, 0x20 );               \
    add = __lasx_xvhaddw_hu_bu( src0, src0 );                  \
    u_sum += LASX_HADD_UH_U32( add );                          \
    pix_h = __lasx_xvilvl_b( zero, src0 );                     \
    pix_l = __lasx_xvilvh_b( zero, src0 );                     \
    DUP2_ARG3( __lasx_xvdp2add_w_h, sqr, pix_h, pix_h,         \
               sqr, pix_l, pix_l, sqr, sqr );

    for( u_cnt = ( i_height >> 3 ); u_cnt--; )
    {
        pix0 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;
        pix1 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;
        pix2 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;
        pix3 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;
        pix4 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;
        pix5 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;
        pix6 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;
        pix7 = __lasx_xvldrepl_d( p_pix, 0 );
        p_pix += i_stride;

        LASX_PIXEL_VAR_8W( pix0, pix1, pix2, pix3 );
        LASX_PIXEL_VAR_8W( pix4, pix5, pix6, pix7 );
    }

    u_sqr_out = LASX_HADD_SW_S32( sqr );

#undef LASX_PIXEL_VAR_8W

    return ( u_sum + ( ( uint64_t ) u_sqr_out << 32 ) );
}

uint64_t x264_pixel_var_16x16_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    return avc_pixel_var16width_lasx( p_pix, i_stride, 16 );
}

uint64_t x264_pixel_var_8x16_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    return avc_pixel_var8width_lasx( p_pix, i_stride, 16 );
}

uint64_t x264_pixel_var_8x8_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    return avc_pixel_var8width_lasx( p_pix, i_stride, 8 );
}

int32_t x264_pixel_var2_8x16_lasx( uint8_t *p_pix1, uint8_t *p_pix2,
                                   int32_t ssd[2] )
{
    int32_t i_var = 0, i_diff_u = 0, i_sqr_u = 0;
    int32_t i_diff_v = 0, i_sqr_v = 0;

    i_sqr_u = sse_diff_8width_lasx( p_pix1, FENC_STRIDE,
                                    p_pix2, FDEC_STRIDE, 16, &i_diff_u );
    i_sqr_v = sse_diff_8width_lasx( p_pix1 + (FENC_STRIDE >> 1),
                                    FENC_STRIDE,
                                    p_pix2 + (FDEC_STRIDE >> 1),
                                    FDEC_STRIDE, 16, &i_diff_v );
    i_var = VARIANCE_WxH( i_sqr_u, i_diff_u, 7 ) +
            VARIANCE_WxH( i_sqr_v, i_diff_v, 7 );
    ssd[0] = i_sqr_u;
    ssd[1] = i_sqr_v;

    return i_var;
}

int32_t x264_pixel_var2_8x8_lasx( uint8_t *p_pix1, uint8_t *p_pix2,
                                  int32_t ssd[2] )
{
    int32_t i_var = 0, i_diff_u = 0, i_sqr_u = 0;
    int32_t i_diff_v = 0, i_sqr_v = 0;

    i_sqr_u = sse_diff_8width_lasx( p_pix1, FENC_STRIDE,
                                    p_pix2, FDEC_STRIDE, 8, &i_diff_u );
    i_sqr_v = sse_diff_8width_lasx( p_pix1 + (FENC_STRIDE >> 1),
                                    FENC_STRIDE,
                                    p_pix2 + (FDEC_STRIDE >> 1),
                                    FDEC_STRIDE, 8, &i_diff_v );
    i_var = VARIANCE_WxH( i_sqr_u, i_diff_u, 6 ) +
            VARIANCE_WxH( i_sqr_v, i_diff_v, 6 );
    ssd[0] = i_sqr_u;
    ssd[1] = i_sqr_v;

    return i_var;
}

#endif
