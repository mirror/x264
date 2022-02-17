/*****************************************************************************
 * predict-c.c: loongarch intra prediction
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
#include "predict.h"

#if !HIGH_BIT_DEPTH

static inline void intra_predict_dc_4blk_8x8_lasx( uint8_t *p_src,
                                                   int32_t i_stride )
{
    uint32_t u_mask = 0x01010101;
    int32_t i_stride_x4 = i_stride << 2;
    uint8_t *p_src1, *p_src2;
    __m256i sum, mask;
    v8u32 out;

    sum = __lasx_xvldx( p_src, -i_stride );
    sum = __lasx_xvhaddw_hu_bu( sum, sum );
    out = ( v8u32 ) __lasx_xvhaddw_wu_hu( sum, sum );
    mask = __lasx_xvreplgr2vr_w( u_mask );

    p_src1 = p_src - 1;
    p_src2 = p_src1 + ( i_stride << 2 );
    out[0] += p_src1[0];
    out[2] = p_src2[0];

    p_src1 += i_stride;
    p_src2 += i_stride;
    out[0] += p_src1[0];
    out[2] += p_src2[0];

    p_src1 += i_stride;
    p_src2 += i_stride;
    out[0] += p_src1[0];
    out[2] += p_src2[0];

    p_src1 += i_stride;
    p_src2 += i_stride;
    out[0] += p_src1[0];
    out[2] += p_src2[0];

    out[0] = ( out[0] + 4 ) >> 3;
    out[3] = ( out[1] + out[2] + 4 ) >> 3;
    out[1] = ( out[1] + 2 ) >> 2;
    out[2] = ( out[2] + 2 ) >> 2;

    out = ( v8u32 ) __lasx_xvmul_w( ( __m256i ) out, mask );

    __lasx_xvstelm_d( out, p_src, 0, 0 );
    __lasx_xvstelm_d( out, p_src + i_stride_x4, 0, 1 );
    p_src += i_stride;

    __lasx_xvstelm_d( out, p_src, 0, 0 );
    __lasx_xvstelm_d( out, p_src + i_stride_x4, 0, 1 );
    p_src += i_stride;

    __lasx_xvstelm_d( out, p_src, 0, 0 );
    __lasx_xvstelm_d( out, p_src + i_stride_x4, 0, 1 );
    p_src += i_stride;

    __lasx_xvstelm_d( out, p_src, 0, 0 );
    __lasx_xvstelm_d( out, p_src + i_stride_x4, 0, 1 );
    p_src += i_stride;
}

static inline void intra_predict_dc_4x4_lasx( uint8_t *p_src_top,
                                              uint8_t *p_src_left,
                                              int32_t i_src_stride_left,
                                              uint8_t *p_dst,
                                              int32_t i_dst_stride,
                                              uint8_t is_above,
                                              uint8_t is_left )
{
    uint32_t u_row;
    uint32_t u_addition = 0;
    int32_t i_dst_stride_x2 =  i_dst_stride << 1;
    int32_t i_dst_stride_x3 =  i_dst_stride_x2 + i_dst_stride;
    __m256i src, store;
    v8u32 sum;

    if( is_left && is_above )
    {
        src  = __lasx_xvld( p_src_top, 0 );
        src = __lasx_xvhaddw_hu_bu( src, src );
        sum = ( v8u32 ) __lasx_xvhaddw_wu_hu( src, src );
        u_addition = sum[0];

        for( u_row = 0; u_row < 4; u_row++ )
        {
            u_addition += p_src_left[u_row * i_src_stride_left];
        }

        u_addition = ( u_addition + 4 ) >> 3;
        store = __lasx_xvreplgr2vr_b( u_addition );
    }
    else if( is_left )
    {
        for( u_row = 0; u_row < 4; u_row++ )
        {
            u_addition += p_src_left[u_row * i_src_stride_left];
        }

        u_addition = ( u_addition + 2 ) >> 2;
        store = __lasx_xvreplgr2vr_b( u_addition );
    }
    else if( is_above )
    {
        src  = __lasx_xvld( p_src_top, 0 );
        src = __lasx_xvhaddw_hu_bu( src, src );
        src = __lasx_xvhaddw_wu_hu( src, src );
        src = __lasx_xvsrari_w( src, 2 );

        store = __lasx_xvrepl128vei_b( src, 0 );
    }
    else
    {
        u_addition = 128;

        store = __lasx_xvreplgr2vr_b( u_addition );
    }

    __lasx_xvstelm_w( store, p_dst, 0, 0 );
    __lasx_xvstelm_w( store, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_w( store, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_w( store, p_dst + i_dst_stride_x3, 0, 0 );
}

static inline void intra_predict_dc_8x8_lasx( uint8_t *p_src_top,
                                              uint8_t *p_src_left,
                                              uint8_t *p_dst,
                                              int32_t i_dst_stride )
{
    __m256i src0, src1, store;
    int32_t i_dst_stride_x2 =  i_dst_stride << 1;
    int32_t i_dst_stride_x3 =  i_dst_stride_x2 + i_dst_stride;

    src0 = __lasx_xvldrepl_d( p_src_top, 0 );
    src1 = __lasx_xvldrepl_d( p_src_left, 0 );
    src0 = __lasx_xvpickev_d( src1, src0 );

    src0 = __lasx_xvhaddw_hu_bu( src0, src0 );
    src0 = __lasx_xvhaddw_wu_hu( src0, src0 );
    src0 = __lasx_xvhaddw_du_wu( src0, src0 );
    src0 = __lasx_xvpickev_w( src0, src0 );
    src0 = __lasx_xvhaddw_du_wu( src0, src0 );
    src0 = __lasx_xvsrari_w( src0, 4 );
    store = __lasx_xvrepl128vei_b( src0, 0 );

    __lasx_xvstelm_d( store, p_dst, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 0, 0 );
    p_dst += ( i_dst_stride  << 2);
    __lasx_xvstelm_d( store, p_dst, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 0, 0 );
}

static inline void intra_predict_dc_16x16_lasx( uint8_t *p_src_top,
                                                uint8_t *p_src_left,
                                                int32_t i_src_stride_left,
                                                uint8_t *p_dst,
                                                int32_t i_dst_stride,
                                                uint8_t is_above,
                                                uint8_t is_left )
{
    uint32_t u_row;
    int32_t i_index = 0;
    uint32_t u_addition = 0;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_dst_stride_x3 = i_dst_stride_x2 + i_dst_stride;
    __m256i src, store;
    v4u64 sum;

    if( is_left && is_above )
    {
        src  = __lasx_xvld( p_src_top, 0 );
        src = __lasx_xvhaddw_hu_bu( src, src );
        src = __lasx_xvhaddw_wu_hu( src, src );
        src = __lasx_xvhaddw_du_wu( src, src );
        src = __lasx_xvpickev_w( src, src );
        sum = ( v4u64 ) __lasx_xvhaddw_du_wu( src, src );
        u_addition = sum[0];

        for( u_row = 0; u_row < 4; u_row++ )
        {
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
        }

        u_addition = ( u_addition + 16 ) >> 5;
        store = __lasx_xvreplgr2vr_b( u_addition );
    }
    else if( is_left )
    {
        for( u_row = 0; u_row < 4; u_row++ )
        {
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
            u_addition += p_src_left[i_index];
            i_index += i_src_stride_left;
        }

        u_addition = ( u_addition + 8 ) >> 4;
        store = __lasx_xvreplgr2vr_b( u_addition );
    }
    else if( is_above )
    {
        src  = __lasx_xvld( p_src_top, 0 );
        src = __lasx_xvhaddw_hu_bu( src, src );
        src = __lasx_xvhaddw_wu_hu( src, src );
        src = __lasx_xvhaddw_du_wu( src, src );
        src = __lasx_xvpickev_w( src, src );
        src = __lasx_xvhaddw_du_wu( src, src );
        src = __lasx_xvsrari_d( src, 4 );

        store = __lasx_xvrepl128vei_b( src, 0 );
    }
    else
    {
        u_addition = 128;

        store = __lasx_xvreplgr2vr_b( u_addition );
    }

    __lasx_xvstelm_d( store, p_dst, 0, 0 );
    __lasx_xvstelm_d( store, p_dst, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 8, 1 );
    p_dst += ( i_dst_stride  << 2);
    __lasx_xvstelm_d( store, p_dst, 0, 0 );
    __lasx_xvstelm_d( store, p_dst, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 8, 1 );
    p_dst += ( i_dst_stride  << 2);
    __lasx_xvstelm_d( store, p_dst, 0, 0 );
    __lasx_xvstelm_d( store, p_dst, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 8, 1 );
    p_dst += ( i_dst_stride  << 2);
    __lasx_xvstelm_d( store, p_dst, 0, 0 );
    __lasx_xvstelm_d( store, p_dst, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( store, p_dst + i_dst_stride_x3, 8, 1 );
}

static inline void intra_predict_horiz_16x16_lasx( uint8_t *p_src,
                                                   int32_t i_src_stride,
                                                   uint8_t *p_dst,
                                                   int32_t i_dst_stride )
{
    uint32_t u_row;
    uint8_t u_inp0, u_inp1, u_inp2, u_inp3;
    __m256i src0, src1, src2, src3;

    for( u_row = 4; u_row--; )
    {
        u_inp0 = p_src[0];
        p_src += i_src_stride;
        u_inp1 = p_src[0];
        p_src += i_src_stride;
        u_inp2 = p_src[0];
        p_src += i_src_stride;
        u_inp3 = p_src[0];
        p_src += i_src_stride;

        src0 = __lasx_xvreplgr2vr_b( u_inp0 );
        src1 = __lasx_xvreplgr2vr_b( u_inp1 );
        src2 = __lasx_xvreplgr2vr_b( u_inp2 );
        src3 = __lasx_xvreplgr2vr_b( u_inp3 );

        __lasx_xvstelm_d( src0, p_dst, 0, 0 );
        __lasx_xvstelm_d( src0, p_dst, 8, 1 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( src1, p_dst, 0, 0 );
        __lasx_xvstelm_d( src1, p_dst, 8, 1 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( src2, p_dst, 0, 0 );
        __lasx_xvstelm_d( src2, p_dst, 8, 1 );
        p_dst += i_dst_stride;
        __lasx_xvstelm_d( src3, p_dst, 0, 0 );
        __lasx_xvstelm_d( src3, p_dst, 8, 1 );
        p_dst += i_dst_stride;
    }
}

static inline void intra_predict_horiz_8x8_lasx( uint8_t *p_src,
                                                 int32_t i_src_stride,
                                                 uint8_t *p_dst,
                                                 int32_t i_dst_stride )
{
    uint8_t u_inp0, u_inp1, u_inp2, u_inp3;
    __m256i src0, src1, src2, src3;

    u_inp0 = p_src[0];
    p_src += i_src_stride;
    u_inp1 = p_src[0];
    p_src += i_src_stride;
    u_inp2 = p_src[0];
    p_src += i_src_stride;
    u_inp3 = p_src[0];
    p_src += i_src_stride;

    src0 = __lasx_xvreplgr2vr_b( u_inp0 );
    src1 = __lasx_xvreplgr2vr_b( u_inp1 );
    src2 = __lasx_xvreplgr2vr_b( u_inp2 );
    src3 = __lasx_xvreplgr2vr_b( u_inp3 );

    __lasx_xvstelm_d( src0, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_d( src1, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_d( src2, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_d( src3, p_dst, 0, 0 );
    p_dst += i_dst_stride;

    u_inp0 = p_src[0];
    p_src += i_src_stride;
    u_inp1 = p_src[0];
    p_src += i_src_stride;
    u_inp2 = p_src[0];
    p_src += i_src_stride;
    u_inp3 = p_src[0];
    p_src += i_src_stride;

    src0 = __lasx_xvreplgr2vr_b( u_inp0 );
    src1 = __lasx_xvreplgr2vr_b( u_inp1 );
    src2 = __lasx_xvreplgr2vr_b( u_inp2 );
    src3 = __lasx_xvreplgr2vr_b( u_inp3 );

    __lasx_xvstelm_d( src0, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_d( src1, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_d( src2, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_d( src3, p_dst, 0, 0 );
    p_dst += i_dst_stride;
}

static inline void intra_predict_horiz_4x4_lasx( uint8_t *p_src,
                                                 int32_t i_src_stride,
                                                 uint8_t *p_dst,
                                                 int32_t i_dst_stride )
{
    uint8_t u_inp0, u_inp1, u_inp2, u_inp3;
    __m256i src0, src1, src2, src3;

    u_inp0 = p_src[0];
    p_src += i_src_stride;
    u_inp1 = p_src[0];
    p_src += i_src_stride;
    u_inp2 = p_src[0];
    p_src += i_src_stride;
    u_inp3 = p_src[0];
    p_src += i_src_stride;

    src0 = __lasx_xvreplgr2vr_b( u_inp0 );
    src1 = __lasx_xvreplgr2vr_b( u_inp1 );
    src2 = __lasx_xvreplgr2vr_b( u_inp2 );
    src3 = __lasx_xvreplgr2vr_b( u_inp3 );

    __lasx_xvstelm_w( src0, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_w( src1, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_w( src2, p_dst, 0, 0 );
    p_dst += i_dst_stride;
    __lasx_xvstelm_w( src3, p_dst, 0, 0 );
    p_dst += i_dst_stride;
}

static inline void intra_predict_vert_16x16_lasx( uint8_t *p_src,
                                                  uint8_t *p_dst,
                                                  int32_t i_dst_stride )
{
    __m256i src;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_dst_stride_x3 = i_dst_stride_x2 + i_dst_stride;
    src  = __lasx_xvld( p_src, 0 );

    __lasx_xvstelm_d( src, p_dst, 0, 0 );
    __lasx_xvstelm_d( src, p_dst, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 8, 1 );
    p_dst += ( i_dst_stride  << 2);
    __lasx_xvstelm_d( src, p_dst, 0, 0 );
    __lasx_xvstelm_d( src, p_dst, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 8, 1 );
    p_dst += ( i_dst_stride  << 2);
    __lasx_xvstelm_d( src, p_dst, 0, 0 );
    __lasx_xvstelm_d( src, p_dst, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 8, 1 );
    p_dst += ( i_dst_stride  << 2);
    __lasx_xvstelm_d( src, p_dst, 0, 0 );
    __lasx_xvstelm_d( src, p_dst, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x2, 8, 1 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 0, 0 );
    __lasx_xvstelm_d( src, p_dst + i_dst_stride_x3, 8, 1 );
}

static inline void intra_predict_vert_8x8_lasx( uint8_t *p_src,
                                                uint8_t *p_dst,
                                                int32_t i_dst_stride )
{
    __m256i out;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_dst_stride_x3 = i_dst_stride_x2 + i_dst_stride;

    out = __lasx_xvldrepl_d( p_src, 0 );

    __lasx_xvstelm_d( out, p_dst, 0, 0 );
    __lasx_xvstelm_d( out, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( out, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( out, p_dst + i_dst_stride_x3, 0, 0 );
    p_dst += ( i_dst_stride << 2 );
    __lasx_xvstelm_d( out, p_dst, 0, 0 );
    __lasx_xvstelm_d( out, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_d( out, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_d( out, p_dst + i_dst_stride_x3, 0, 0 );
}

static inline void intra_predict_vert_4x4_lasx( uint8_t *p_src,
                                                uint8_t *p_dst,
                                                int32_t i_dst_stride )
{
    __m256i out;
    int32_t i_dst_stride_x2 = i_dst_stride << 1;
    int32_t i_dst_stride_x3 = i_dst_stride_x2 + i_dst_stride;

    out = __lasx_xvldrepl_w( p_src, 0 );

    __lasx_xvstelm_w( out, p_dst, 0, 0 );
    __lasx_xvstelm_w( out, p_dst + i_dst_stride, 0, 0 );
    __lasx_xvstelm_w( out, p_dst + i_dst_stride_x2, 0, 0 );
    __lasx_xvstelm_w( out, p_dst + i_dst_stride_x3, 0, 0 );
}

void x264_intra_predict_dc_4blk_8x8_lasx( uint8_t *p_src )
{
    intra_predict_dc_4blk_8x8_lasx( p_src, FDEC_STRIDE );
}

void x264_intra_predict_hor_8x8_lasx( uint8_t *p_src )
{
    intra_predict_horiz_8x8_lasx( ( p_src - 1 ), FDEC_STRIDE,
                                  p_src, FDEC_STRIDE );
}

void x264_intra_predict_vert_8x8_lasx( uint8_t *p_src )
{
    intra_predict_vert_8x8_lasx( ( p_src - FDEC_STRIDE ), p_src, FDEC_STRIDE );
}

void x264_intra_predict_dc_4x4_lasx( uint8_t *p_src )
{
    intra_predict_dc_4x4_lasx( ( p_src - FDEC_STRIDE ), ( p_src - 1 ),
                               FDEC_STRIDE, p_src, FDEC_STRIDE, 1, 1 );
}

void x264_intra_predict_hor_4x4_lasx( uint8_t *p_src )
{
    intra_predict_horiz_4x4_lasx( ( p_src - 1 ), FDEC_STRIDE,
                                  p_src, FDEC_STRIDE );
}

void x264_intra_predict_vert_4x4_lasx( uint8_t *p_src )
{
    intra_predict_vert_4x4_lasx( ( p_src - FDEC_STRIDE ), p_src, FDEC_STRIDE );
}

void x264_intra_predict_hor_16x16_lasx( uint8_t *p_src )
{
    intra_predict_horiz_16x16_lasx( ( p_src - 1 ), FDEC_STRIDE,
                                    p_src, FDEC_STRIDE );
}

void x264_intra_predict_vert_16x16_lasx( uint8_t *p_src )
{
    intra_predict_vert_16x16_lasx( ( p_src - FDEC_STRIDE ), p_src, FDEC_STRIDE );
}

void x264_intra_predict_dc_16x16_lasx( uint8_t *p_src )
{
    intra_predict_dc_16x16_lasx( ( p_src - FDEC_STRIDE ), ( p_src - 1 ),
                                 FDEC_STRIDE, p_src, FDEC_STRIDE, 1, 1 );
}

void x264_intra_predict_dc_8x8_lasx( uint8_t *p_src, uint8_t pu_xyz[36] )
{
    intra_predict_dc_8x8_lasx( ( pu_xyz + 16 ), ( pu_xyz + 7 ),
                               p_src, FDEC_STRIDE );
}

void x264_intra_predict_h_8x8_lasx( uint8_t *p_src, uint8_t pu_xyz[36] )
{
    intra_predict_horiz_8x8_lasx( ( pu_xyz + 14 ), -1, p_src, FDEC_STRIDE );
}

void x264_intra_predict_v_8x8_lasx( uint8_t *p_src, uint8_t pu_xyz[36] )
{
    intra_predict_vert_8x8_lasx( ( pu_xyz + 16 ), p_src, FDEC_STRIDE );
}

void x264_predict_16x16_init_lasx( int cpu, x264_predict_t pf[7] )
{
    if ( cpu&X264_CPU_LASX ) {
#if !HIGH_BIT_DEPTH
        pf[I_PRED_16x16_V]    = x264_intra_predict_vert_16x16_lasx;
        pf[I_PRED_16x16_H]    = x264_intra_predict_hor_16x16_lasx;
        pf[I_PRED_16x16_DC]   = x264_intra_predict_dc_16x16_lasx;
#endif
    }
}

#endif
