/*****************************************************************************
 * deblock-c.c: loongarch deblocking
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
#include "deblock.h"

#if !HIGH_BIT_DEPTH

#define LASX_LPF_P1_OR_Q1( p0_or_q0_org_in, q0_or_p0_org_in,         \
                           p1_or_q1_org_in, p2_or_q2_org_in,         \
                           negate_tc_in, tc_in, p1_or_q1_out )       \
{                                                                    \
    __m256i clip0, temp;                                             \
                                                                     \
    clip0 = __lasx_xvavgr_hu( p0_or_q0_org_in, q0_or_p0_org_in );    \
    temp = __lasx_xvslli_h( p1_or_q1_org_in, 1 );                    \
    clip0 = __lasx_xvsub_h( clip0, temp );                           \
    clip0 = __lasx_xvavg_h( p2_or_q2_org_in, clip0 );                \
    clip0 = __lasx_xvclip_h( clip0, negate_tc_in, tc_in );           \
    p1_or_q1_out = __lasx_xvadd_h( p1_or_q1_org_in, clip0 );         \
}

#define LASX_LPF_P0Q0( q0_or_p0_org_in, p0_or_q0_org_in,             \
                       p1_or_q1_org_in, q1_or_p1_org_in,             \
                       negate_threshold_in, threshold_in,            \
                       p0_or_q0_out, q0_or_p0_out )                  \
{                                                                    \
    __m256i q0_sub_p0, p1_sub_q1, delta;                             \
                                                                     \
    q0_sub_p0 = __lasx_xvsub_h( q0_or_p0_org_in, p0_or_q0_org_in );  \
    p1_sub_q1 = __lasx_xvsub_h( p1_or_q1_org_in, q1_or_p1_org_in );  \
    q0_sub_p0 = __lasx_xvslli_h( q0_sub_p0, 2 );                     \
    p1_sub_q1 = __lasx_xvaddi_hu( p1_sub_q1, 4 );                    \
    delta = __lasx_xvadd_h( q0_sub_p0, p1_sub_q1 );                  \
    delta = __lasx_xvsrai_h( delta, 3 );                             \
                                                                     \
    delta = __lasx_xvclip_h(delta, negate_threshold_in,              \
            threshold_in);                                           \
                                                                     \
    p0_or_q0_out = __lasx_xvadd_h( p0_or_q0_org_in, delta );         \
    q0_or_p0_out = __lasx_xvsub_h( q0_or_p0_org_in, delta );         \
                                                                     \
    DUP2_ARG1( __lasx_xvclip255_h, p0_or_q0_out, q0_or_p0_out,       \
               p0_or_q0_out, q0_or_p0_out );                         \
}

void x264_deblock_h_luma_lasx( uint8_t *p_pix, intptr_t i_stride,
                               int32_t i_alpha, int32_t i_beta, int8_t *p_tc0 )
{
    uint8_t *p_src;
    intptr_t i_stride_2x = ( i_stride << 1 );
    intptr_t i_stride_4x = ( i_stride << 2 );
    intptr_t i_stride_3x = i_stride_2x + i_stride;
    __m256i beta, bs, tc;
    __m256i zero = __lasx_xvldi( 0 );

    tc = __lasx_xvld( p_tc0, 0 );
    tc = __lasx_xvilvl_b( tc, tc );
    tc = __lasx_xvilvl_h( tc, tc );

    beta = __lasx_xvsle_w( zero, tc );
    bs = __lasx_xvandi_b( beta, 0x01 );

    if( !__lasx_xbz_v( bs ) )
    {
        __m256i is_less_than, is_less_than_beta, is_bs_greater_than0;
        __m256i src0, src1, src2, src3, src4, src5, src6, src7;
        __m256i p3_org, p2_org, p1_org, p0_org, q0_org, q1_org, q2_org, q3_org;
        __m256i p2_org_l, p1_org_l, p0_org_l, q0_org_l, q1_org_l, q2_org_l;
        __m256i p2_org_h, p1_org_h, p0_org_h, q0_org_h, q1_org_h, q2_org_h;
        __m256i tc_l, tc_h;
        __m256i mask_l = { 0, 2, 0, 2 };
        __m256i mask_h = { 3, 0, 3, 0 };

        is_bs_greater_than0 = __lasx_xvslt_bu( zero, bs );

        {
            p_src = p_pix - 4;
            DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_stride, p_src, i_stride_2x, p_src,
                       i_stride_3x, src0, src1, src2, src3 );
            p_src += i_stride_4x;
            DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_stride, p_src, i_stride_2x, p_src,
                       i_stride_3x, src4, src5, src6, src7 );
            p_src += i_stride_4x;
            DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_stride, p_src, i_stride_2x, p_src,
                       i_stride_3x, p2_org_l, p1_org_l, p0_org_l, q0_org_l );
            p_src += i_stride_4x;
            DUP4_ARG2( __lasx_xvldx, p_src, 0, p_src, i_stride, p_src, i_stride_2x, p_src,
                       i_stride_3x, q1_org_l, q2_org_l, p2_org_h, p1_org_h );
            p_src -= i_stride_4x;

            LASX_TRANSPOSE16x8_B( src0, src1, src2, src3,
                                  src4, src5, src6, src7,
                                  p2_org_l, p1_org_l, p0_org_l, q0_org_l,
                                  q1_org_l, q2_org_l, p2_org_h, p1_org_h,
                                  p3_org, p2_org, p1_org, p0_org,
                                  q0_org, q1_org, q2_org, q3_org );
        }
        {
            src0 = __lasx_xvabsd_bu( p0_org, q0_org );
            src1 = __lasx_xvabsd_bu( p1_org, p0_org );
            src2 = __lasx_xvabsd_bu( q1_org, q0_org );

            src3 = __lasx_xvreplgr2vr_b( i_alpha );
            beta = __lasx_xvreplgr2vr_b( i_beta );

            src4 = __lasx_xvslt_bu( src0, src3 );
            is_less_than_beta = __lasx_xvslt_bu( src1, beta );
            is_less_than = __lasx_xvand_v( is_less_than_beta, src4 );
            is_less_than_beta = __lasx_xvslt_bu( src2, beta );
            is_less_than = __lasx_xvand_v( is_less_than_beta,
                                           is_less_than );
            is_less_than = __lasx_xvand_v( is_less_than,
                                           is_bs_greater_than0 );
        }
        if( !__lasx_xbz_v( is_less_than ) )
        {
            __m256i negate_tc, sign_negate_tc;
            __m256i negate_tc_l, i16_negatetc_h;

            negate_tc = __lasx_xvsub_b( zero, tc );
            sign_negate_tc = __lasx_xvslti_b( negate_tc, 0 );

            negate_tc_l = __lasx_xvilvl_b( sign_negate_tc, negate_tc );
            i16_negatetc_h = __lasx_xvilvh_b( sign_negate_tc, negate_tc );

            tc_l = __lasx_xvilvl_b( zero, tc );
            tc_h = __lasx_xvilvh_b( zero, tc );
            p1_org_l = __lasx_xvilvl_b( zero, p1_org );
            p1_org_h = __lasx_xvilvh_b( zero, p1_org );
            p0_org_l = __lasx_xvilvl_b( zero, p0_org );
            p0_org_h = __lasx_xvilvh_b( zero, p0_org );
            q0_org_l = __lasx_xvilvl_b( zero, q0_org );
            q0_org_h = __lasx_xvilvh_b( zero, q0_org );

            {
                __m256i p2_asub_p0;
                __m256i is_less_than_beta_l, is_less_than_beta_h;

                p2_asub_p0 = __lasx_xvabsd_bu( p2_org, p0_org );
                is_less_than_beta = __lasx_xvslt_bu( p2_asub_p0, beta );
                is_less_than_beta = __lasx_xvand_v( is_less_than_beta,
                                                    is_less_than );

                is_less_than_beta_l = __lasx_xvshuf_d( mask_l, is_less_than_beta,
                                                       zero );
                if( !__lasx_xbz_v( is_less_than_beta_l ) )
                {
                    p2_org_l = __lasx_xvilvl_b( zero, p2_org );

                    LASX_LPF_P1_OR_Q1( p0_org_l, q0_org_l, p1_org_l, p2_org_l,
                                       negate_tc_l, tc_l, src2 );
                }

                is_less_than_beta_h = __lasx_xvshuf_d( mask_h, is_less_than_beta,
                                                       zero );
                if( !__lasx_xbz_v( is_less_than_beta_h ) )
                {
                    p2_org_h = __lasx_xvilvh_b( zero, p2_org );

                    LASX_LPF_P1_OR_Q1( p0_org_h, q0_org_h, p1_org_h, p2_org_h,
                                       i16_negatetc_h, tc_h, src6 );
                }
            }

            if( !__lasx_xbz_v( is_less_than_beta ) )
            {
                src6 = __lasx_xvpickev_b( src6, src2 );
                p1_org = __lasx_xvbitsel_v( p1_org, src6, is_less_than_beta );

                is_less_than_beta = __lasx_xvandi_b( is_less_than_beta, 1 );
                tc = __lasx_xvadd_b( tc, is_less_than_beta );
            }

            {
                __m256i u8_q2asub_q0;
                __m256i is_less_than_beta_h, is_less_than_beta_l;

                u8_q2asub_q0 = __lasx_xvabsd_bu( q2_org, q0_org );
                is_less_than_beta = __lasx_xvslt_bu( u8_q2asub_q0, beta );
                is_less_than_beta = __lasx_xvand_v( is_less_than_beta,
                                                    is_less_than );

                q1_org_l = __lasx_xvilvl_b( zero, q1_org );

                is_less_than_beta_l = __lasx_xvshuf_d( mask_l, is_less_than_beta,
                                                       zero );
                if( !__lasx_xbz_v( is_less_than_beta_l ) )
                {
                    q2_org_l = __lasx_xvilvl_b( zero, q2_org );
                    LASX_LPF_P1_OR_Q1( p0_org_l, q0_org_l, q1_org_l, q2_org_l,
                                       negate_tc_l, tc_l, src3 );
                }

                q1_org_h = __lasx_xvilvh_b( zero, q1_org );

                is_less_than_beta_h = __lasx_xvshuf_d( mask_h, is_less_than_beta,
                                                       zero );
                if( !__lasx_xbz_v( is_less_than_beta_h ) )
                {
                    q2_org_h = __lasx_xvilvh_b( zero, q2_org );
                    LASX_LPF_P1_OR_Q1( p0_org_h, q0_org_h, q1_org_h, q2_org_h,
                                       i16_negatetc_h, tc_h, src7 );
                }
            }

            if( !__lasx_xbz_v( is_less_than_beta ) )
            {
                src7 = __lasx_xvpickev_b( src7, src3 );
                q1_org = __lasx_xvbitsel_v( q1_org, src7, is_less_than_beta );

                is_less_than_beta = __lasx_xvandi_b( is_less_than_beta, 1 );
                tc = __lasx_xvadd_b( tc, is_less_than_beta );
            }

            {
                __m256i threshold_l, negate_thresh_l;
                __m256i threshold_h, negate_thresh_h;
                __m256i negate_thresh, sign_negate_thresh;

                negate_thresh = __lasx_xvsub_b( zero, tc );
                sign_negate_thresh = __lasx_xvslti_b( negate_thresh, 0 );

                DUP2_ARG2( __lasx_xvilvl_b, zero, tc, sign_negate_thresh, negate_thresh,
                           threshold_l, negate_thresh_l );

                LASX_LPF_P0Q0( q0_org_l, p0_org_l, p1_org_l, q1_org_l,
                               negate_thresh_l, threshold_l, src0, src1 );

                threshold_h = __lasx_xvilvh_b( zero, tc );
                negate_thresh_h = __lasx_xvilvh_b( sign_negate_thresh,
                                                   negate_thresh );

                LASX_LPF_P0Q0( q0_org_h, p0_org_h, p1_org_h, q1_org_h,
                               negate_thresh_h, threshold_h, src4, src5 );
            }

            src4 = __lasx_xvpickev_b( src4, src0 );
            src5 = __lasx_xvpickev_b( src5, src1 );

            p0_org = __lasx_xvbitsel_v( p0_org, src4, is_less_than );
            q0_org = __lasx_xvbitsel_v( q0_org, src5, is_less_than );
        }
        {
            p_src = p_pix - 3;

            src0 = __lasx_xvilvl_b( p1_org, p2_org );
            src2 = __lasx_xvilvh_b( p1_org, p2_org );
            src1 = __lasx_xvilvl_b( q0_org, p0_org );
            src3 = __lasx_xvilvh_b( q0_org, p0_org );
            src4 = __lasx_xvilvl_b( q2_org, q1_org );
            src5 = __lasx_xvilvh_b( q2_org, q1_org );

            src6 = __lasx_xvilvl_h( src1, src0 );
            src7 = __lasx_xvilvh_h( src1, src0 );
            src0 = __lasx_xvilvl_h( src3, src2 );
            src1 = __lasx_xvilvh_h( src3, src2 );

            __lasx_xvstelm_w( src6, p_src, 0, 0 );
            __lasx_xvstelm_h( src4, p_src, 4, 0 );
            p_src += i_stride;
            __lasx_xvstelm_w( src6, p_src, 0, 1 );
            __lasx_xvstelm_h( src4, p_src, 4, 1 );

            p_src += i_stride;
            __lasx_xvstelm_w( src6, p_src, 0, 2 );
            __lasx_xvstelm_h( src4, p_src, 4, 2 );
            p_src += i_stride;
            __lasx_xvstelm_w( src6, p_src, 0, 3 );
            __lasx_xvstelm_h( src4, p_src, 4, 3 );

            p_src += i_stride;
            __lasx_xvstelm_w( src7, p_src, 0, 0 );
            __lasx_xvstelm_h( src4, p_src, 4, 4 );
            p_src += i_stride;
            __lasx_xvstelm_w( src7, p_src, 0, 1 );
            __lasx_xvstelm_h( src4, p_src, 4, 5 );

            p_src += i_stride;
            __lasx_xvstelm_w( src7, p_src, 0, 2 );
            __lasx_xvstelm_h( src4, p_src, 4, 6 );
            p_src += i_stride;
            __lasx_xvstelm_w( src7, p_src, 0, 3 );
            __lasx_xvstelm_h( src4, p_src, 4, 7 );

            p_src += i_stride;
            __lasx_xvstelm_w( src0, p_src, 0, 0 );
            __lasx_xvstelm_h( src5, p_src, 4, 0 );
            p_src += i_stride;
            __lasx_xvstelm_w( src0, p_src, 0, 1 );
            __lasx_xvstelm_h( src5, p_src, 4, 1 );

            p_src += i_stride;
            __lasx_xvstelm_w( src0, p_src, 0, 2 );
            __lasx_xvstelm_h( src5, p_src, 4, 2 );
            p_src += i_stride;
            __lasx_xvstelm_w( src0, p_src, 0, 3 );
            __lasx_xvstelm_h( src5, p_src, 4, 3 );

            p_src += i_stride;
            __lasx_xvstelm_w( src1, p_src, 0, 0 );
            __lasx_xvstelm_h( src5, p_src, 4, 4 );
            p_src += i_stride;
            __lasx_xvstelm_w( src1, p_src, 0, 1 );
            __lasx_xvstelm_h( src5, p_src, 4, 5 );

            p_src += i_stride;
            __lasx_xvstelm_w( src1, p_src, 0, 2 );
            __lasx_xvstelm_h( src5, p_src, 4, 6 );
            p_src += i_stride;
            __lasx_xvstelm_w( src1, p_src, 0, 3 );
            __lasx_xvstelm_h( src5, p_src, 4, 7 );
        }
    }
}

void x264_deblock_v_luma_lasx( uint8_t *p_pix, intptr_t i_stride,
                               int32_t i_alpha, int32_t i_beta, int8_t *p_tc0 )
{
    __m256i bs, tc, beta;
    __m256i zero = __lasx_xvldi( 0 );
    intptr_t i_stride_2x = ( i_stride << 1 );
    intptr_t i_stride_3x = i_stride_2x + i_stride;

    tc = __lasx_xvld( p_tc0, 0 );
    tc = __lasx_xvilvl_b( tc, tc );
    tc = __lasx_xvilvl_h( tc, tc );

    beta = __lasx_xvsle_w( zero, tc );
    bs = __lasx_xvandi_b( beta, 0x01 );

    if( !__lasx_xbz_v( bs ) )
    {
        __m256i p2_asub_p0, u8_q2asub_q0;
        __m256i alpha, is_less_than, is_less_than_beta;
        __m256i src0, src1, src2, src3, src6, src4, src5, src7;
        __m256i p2_org, p1_org, p0_org, q0_org, q1_org, q2_org;
        __m256i p2_org_l, p1_org_l, p0_org_l, q0_org_l, q1_org_l, q2_org_l;
        __m256i p2_org_h, p1_org_h, p0_org_h, q0_org_h, q1_org_h, q2_org_h;
        __m256i mask_l = { 0, 2, 0, 2 };
        __m256i mask_h = { 3, 0, 3, 0 };

        alpha = __lasx_xvreplgr2vr_b( i_alpha );
        beta = __lasx_xvreplgr2vr_b( i_beta );

        p2_org = __lasx_xvldx( p_pix , -i_stride_3x );
        p_pix -= i_stride_2x;
        DUP4_ARG2(__lasx_xvldx, p_pix, 0, p_pix, i_stride, p_pix, i_stride_2x, p_pix,
                  i_stride_3x, p1_org, p0_org, q0_org, q1_org );
        p_pix += i_stride_2x;
        {
            src5 = __lasx_xvslt_bu( zero, bs );
            src0 = __lasx_xvabsd_bu( p0_org, q0_org );
            src1 = __lasx_xvabsd_bu( p1_org, p0_org );
            src2 = __lasx_xvabsd_bu( q1_org, q0_org );

            src4 = __lasx_xvslt_bu( src0, alpha );
            is_less_than_beta = __lasx_xvslt_bu( src1, beta );
            is_less_than = __lasx_xvand_v( is_less_than_beta,
                                           src4 );
            is_less_than_beta = __lasx_xvslt_bu( src2, beta );
            is_less_than = __lasx_xvand_v( is_less_than_beta,
                                           is_less_than );
            is_less_than = __lasx_xvand_v( is_less_than, src5 );
        }

        if( !__lasx_xbz_v( is_less_than ) )
        {
            __m256i sign_negate_tc, negate_tc;
            __m256i negate_tc_l, i16_negatetc_h, tc_h, tc_l;

            q2_org = __lasx_xvldx( p_pix, i_stride_2x );
            negate_tc = __lasx_xvsub_b( zero, tc );
            sign_negate_tc = __lasx_xvslti_b( negate_tc, 0 );

            negate_tc_l = __lasx_xvilvl_b( sign_negate_tc, negate_tc );
            i16_negatetc_h = __lasx_xvilvh_b( sign_negate_tc, negate_tc );

            tc_l = __lasx_xvilvl_b( zero, tc );
            tc_h = __lasx_xvilvh_b( zero, tc );
            p1_org_l = __lasx_xvilvl_b( zero, p1_org );
            p1_org_h = __lasx_xvilvh_b( zero, p1_org );
            p0_org_l = __lasx_xvilvl_b( zero, p0_org );
            p0_org_h = __lasx_xvilvh_b( zero, p0_org );
            q0_org_l = __lasx_xvilvl_b( zero, q0_org );
            q0_org_h = __lasx_xvilvh_b( zero, q0_org );

            p2_asub_p0 = __lasx_xvabsd_bu( p2_org, p0_org );
            is_less_than_beta = __lasx_xvslt_bu( p2_asub_p0, beta );
            is_less_than_beta = __lasx_xvand_v( is_less_than_beta,
                                                is_less_than );
            {
                __m256i is_less_than_beta_l, is_less_than_beta_h;

                is_less_than_beta_l = __lasx_xvshuf_d( mask_l, is_less_than_beta,
                                                       zero );
                if( !__lasx_xbz_v( is_less_than_beta_l ) )
                {
                    p2_org_l = __lasx_xvilvl_b( zero, p2_org );

                    LASX_LPF_P1_OR_Q1( p0_org_l, q0_org_l, p1_org_l, p2_org_l,
                                       negate_tc_l, tc_l, src2 );
                }

                is_less_than_beta_h = __lasx_xvshuf_d( mask_h, is_less_than_beta,
                                                       zero );
                if( !__lasx_xbz_v( is_less_than_beta_h ) )
                {
                    p2_org_h = __lasx_xvilvh_b( zero, p2_org );

                    LASX_LPF_P1_OR_Q1( p0_org_h, q0_org_h, p1_org_h, p2_org_h,
                                       i16_negatetc_h, tc_h, src6 );
                }
            }
            if( !__lasx_xbz_v( is_less_than_beta ) )
            {
                src6 = __lasx_xvpickev_b( src6, src2 );
                p1_org = __lasx_xvbitsel_v( p1_org, src6, is_less_than_beta );
                __lasx_xvstelm_d( p1_org, p_pix - i_stride_2x, 0, 0 );
                __lasx_xvstelm_d( p1_org, p_pix - i_stride_2x, 8, 1 );

                is_less_than_beta = __lasx_xvandi_b( is_less_than_beta, 1 );
                tc = __lasx_xvadd_b( tc, is_less_than_beta );
            }

            u8_q2asub_q0 = __lasx_xvabsd_bu( q2_org, q0_org );
            is_less_than_beta = __lasx_xvslt_bu( u8_q2asub_q0, beta );
            is_less_than_beta = __lasx_xvand_v( is_less_than_beta,
                                                is_less_than );

            {
                __m256i is_less_than_beta_l, is_less_than_beta_h;
                is_less_than_beta_l = __lasx_xvshuf_d( mask_l, is_less_than_beta,
                                                       zero );

                q1_org_l = __lasx_xvilvl_b( zero, q1_org );
                if( !__lasx_xbz_v( is_less_than_beta_l ) )
                {
                    q2_org_l = __lasx_xvilvl_b( zero, q2_org );

                    LASX_LPF_P1_OR_Q1( p0_org_l, q0_org_l, q1_org_l, q2_org_l,
                                       negate_tc_l, tc_l, src3 );
                }
                is_less_than_beta_h = __lasx_xvshuf_d( mask_h, is_less_than_beta,
                                                       zero );

                q1_org_h = __lasx_xvilvh_b( zero, q1_org );
                if( !__lasx_xbz_v( is_less_than_beta_h ) )
                {
                    q2_org_h = __lasx_xvilvh_b( zero, q2_org );

                    LASX_LPF_P1_OR_Q1( p0_org_h, q0_org_h, q1_org_h, q2_org_h,
                                       i16_negatetc_h, tc_h, src7 );
                }
            }
            if( !__lasx_xbz_v( is_less_than_beta ) )
            {
                src7 = __lasx_xvpickev_b( src7, src3 );
                q1_org = __lasx_xvbitsel_v( q1_org, src7, is_less_than_beta );
                __lasx_xvstelm_d( q1_org, p_pix + i_stride, 0, 0 );
                __lasx_xvstelm_d( q1_org, p_pix + i_stride, 8, 1 );

                is_less_than_beta = __lasx_xvandi_b( is_less_than_beta, 1 );
                tc = __lasx_xvadd_b( tc, is_less_than_beta );
            }
            {
                __m256i negate_thresh, sign_negate_thresh;
                __m256i threshold_l, threshold_h;
                __m256i negate_thresh_h, negate_thresh_l;

                negate_thresh = __lasx_xvsub_b( zero, tc );
                sign_negate_thresh = __lasx_xvslti_b( negate_thresh, 0 );

                DUP2_ARG2( __lasx_xvilvl_b, zero, tc, sign_negate_thresh, negate_thresh,
                           threshold_l, negate_thresh_l );
                LASX_LPF_P0Q0( q0_org_l, p0_org_l, p1_org_l, q1_org_l,
                               negate_thresh_l, threshold_l, src0, src1 );

                threshold_h = __lasx_xvilvh_b( zero, tc );
                negate_thresh_h = __lasx_xvilvh_b( sign_negate_thresh,
                                                   negate_thresh );
                LASX_LPF_P0Q0( q0_org_h, p0_org_h, p1_org_h, q1_org_h,
                               negate_thresh_h, threshold_h, src4, src5 );
            }

            src4 = __lasx_xvpickev_b( src4, src0 );
            src5 = __lasx_xvpickev_b( src5, src1 );

            p0_org = __lasx_xvbitsel_v( p0_org, src4, is_less_than );
            q0_org = __lasx_xvbitsel_v( q0_org, src5, is_less_than );

            __lasx_xvstelm_d( p0_org, p_pix - i_stride, 0, 0 );
            __lasx_xvstelm_d( p0_org, p_pix - i_stride, 8, 1 );
            __lasx_xvstelm_d( q0_org, p_pix, 0, 0 );
            __lasx_xvstelm_d( q0_org, p_pix, 8, 1 );
        }
    }
}

static void avc_deblock_strength_lasx( uint8_t *nnz,
                                       int8_t pi_lef[2][X264_SCAN8_LUMA_SIZE],
                                       int16_t pi_mv[2][X264_SCAN8_LUMA_SIZE][2],
                                       uint8_t pu_bs[2][8][4],
                                       int32_t i_mvy_himit )
{
    __m256i nnz0, nnz1, nnz2, nnz3, nnz4;
    __m256i nnz_mask, ref_mask, mask, one, two, dst = { 0 };
    __m256i ref0, ref1, ref2, ref3, ref4;
    __m256i temp_vec0, temp_vec1, temp_vec2;
    __m256i mv0, mv1, mv2, mv3, mv4, mv5, mv6, mv7, mv8, mv9, mv_a, mv_b;
    __m256i four, mvy_himit_vec, sub0, sub1;
    int8_t* p_lef = pi_lef[0];
    int16_t* p_mv = pi_mv[0][0];

    DUP2_ARG2(__lasx_xvld, nnz, 4, nnz, 20, nnz0, nnz2 );
    nnz4 = __lasx_xvld( nnz, 36 );

    DUP2_ARG2(__lasx_xvld, p_lef, 4, p_lef, 20, ref0, ref2 );
    ref4 = __lasx_xvld( p_lef, 36 );

    DUP4_ARG2(__lasx_xvld, p_mv, 16, p_mv, 48, p_mv, 80, p_mv, 112, mv0, mv1, mv2, mv3 );
    mv4 = __lasx_xvld( p_mv, 144 );

    mvy_himit_vec = __lasx_xvreplgr2vr_h( i_mvy_himit );
    four = __lasx_xvreplgr2vr_h( 4 );
    mask = __lasx_xvldi( 0 );
    one = __lasx_xvldi( 1 );
    two = __lasx_xvldi( 2 );

    mv5 = __lasx_xvpickod_h( mv0, mv0 );
    mv6 = __lasx_xvpickod_h( mv1, mv1 );
    mv_a = __lasx_xvpickev_h( mv0, mv0 );
    mv_b = __lasx_xvpickev_h( mv1, mv1 );
    nnz1 = __lasx_xvrepl128vei_w( nnz0, 2 );
    ref1 = __lasx_xvrepl128vei_w( ref0, 2 );
    nnz_mask = __lasx_xvor_v( nnz0, nnz1 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref0, ref1 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv_b, mv_a );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );

    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[1][0], 0, 0 );

    dst = __lasx_xvldi( 0 );
    two = __lasx_xvldi( 2 );

    mv5 = __lasx_xvpickod_h( mv1, mv1 );
    mv6 = __lasx_xvpickod_h( mv2, mv2 );
    mv_a = __lasx_xvpickev_h( mv1, mv1 );
    mv_b = __lasx_xvpickev_h( mv2, mv2 );

    nnz_mask = __lasx_xvor_v( nnz2, nnz1 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref1, ref2 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv_b, mv_a );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );
    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[1][1], 0, 0 );

    dst = __lasx_xvldi( 0 );
    two = __lasx_xvldi( 2 );

    mv5 = __lasx_xvpickod_h( mv2, mv2 );
    mv6 = __lasx_xvpickod_h( mv3, mv3 );
    mv_a = __lasx_xvpickev_h( mv2, mv2 );
    mv_b = __lasx_xvpickev_h( mv3, mv3 );

    nnz3 = __lasx_xvrepl128vei_w( nnz2, 2 );
    ref3 = __lasx_xvrepl128vei_w( ref2, 2 );

    nnz_mask = __lasx_xvor_v( nnz3, nnz2 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref2, ref3 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv_b, mv_a );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );

    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[1][2], 0, 0 );

    dst = __lasx_xvldi( 0 );
    two = __lasx_xvldi( 2 );

    mv5 = __lasx_xvpickod_h( mv3, mv3 );
    mv6 = __lasx_xvpickod_h( mv4, mv4 );
    mv_a = __lasx_xvpickev_h( mv3, mv3 );
    mv_b = __lasx_xvpickev_h( mv4, mv4 );

    nnz_mask = __lasx_xvor_v( nnz4, nnz3 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref3, ref4 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv_b, mv_a );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );

    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[1][3], 0, 0 );

    DUP2_ARG2( __lasx_xvld, nnz, 8, nnz, 24, nnz0, nnz2 );
    DUP2_ARG2( __lasx_xvld, p_lef, 8, p_lef, 24, ref0, ref2);

    DUP4_ARG2(__lasx_xvld, p_mv, 32, p_mv, 48, p_mv, 64, p_mv, 80, mv0, mv1, mv2, mv3 );
    DUP4_ARG2(__lasx_xvld, p_mv, 96, p_mv, 112, p_mv, 128, p_mv, 144, mv4, mv7, mv8, mv9 );

    nnz1 = __lasx_xvrepl128vei_d( nnz0, 1 );
    nnz3 = __lasx_xvrepl128vei_d( nnz2, 1 );

    DUP2_ARG2( __lasx_xvilvl_b, nnz2, nnz0, nnz3, nnz1, temp_vec0, temp_vec1 );

    temp_vec2 = __lasx_xvilvl_b( temp_vec1, temp_vec0 );
    nnz1 = __lasx_xvilvh_b( temp_vec1, temp_vec0 );

    nnz0 = __lasx_xvrepl128vei_w( temp_vec2, 3 );
    nnz2 = __lasx_xvrepl128vei_w( nnz1, 1 );
    nnz3 = __lasx_xvrepl128vei_w( nnz1, 2 );
    nnz4 = __lasx_xvrepl128vei_w( nnz1, 3 );

    ref1 = __lasx_xvrepl128vei_d( ref0, 1 );
    ref3 = __lasx_xvrepl128vei_d( ref2, 1 );

    DUP2_ARG2( __lasx_xvilvl_b, ref2, ref0, ref3, ref1, temp_vec0, temp_vec1 );

    temp_vec2 = __lasx_xvilvl_b( temp_vec1, temp_vec0 );
    ref1 = __lasx_xvilvh_b( temp_vec1, temp_vec0 );

    ref0 = __lasx_xvrepl128vei_w( temp_vec2, 3 );

    ref2 = __lasx_xvrepl128vei_w( ref1, 1 );
    ref3 = __lasx_xvrepl128vei_w( ref1, 2 );
    ref4 = __lasx_xvrepl128vei_w( ref1, 3 );

    LASX_TRANSPOSE8X4_H( mv0, mv2, mv4, mv8, mv5, mv5, mv5, mv0 );
    LASX_TRANSPOSE8X4_H( mv1, mv3, mv7, mv9, mv1, mv2, mv3, mv4 );

    mvy_himit_vec = __lasx_xvreplgr2vr_h( i_mvy_himit );
    four = __lasx_xvreplgr2vr_h( 4 );
    mask = __lasx_xvldi( 0 );
    one = __lasx_xvldi( 1 );
    two = __lasx_xvldi( 2 );
    dst = __lasx_xvldi( 0 );

    mv5 = __lasx_xvrepl128vei_d( mv0, 1 );
    mv6 = __lasx_xvrepl128vei_d( mv1, 1 );

    nnz_mask = __lasx_xvor_v( nnz0, nnz1 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref0, ref1 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv1, mv0 );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );

    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[0][0], 0, 0 );

    two = __lasx_xvldi( 2 );
    dst = __lasx_xvldi( 0 );

    mv5 = __lasx_xvrepl128vei_d( mv1, 1 );
    mv6 = __lasx_xvrepl128vei_d( mv2, 1 );

    nnz_mask = __lasx_xvor_v( nnz1, nnz2 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref1, ref2 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv2, mv1 );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );
    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[0][1], 0, 0 );

    two = __lasx_xvldi( 2 );
    dst = __lasx_xvldi( 0 );

    mv5 = __lasx_xvrepl128vei_d( mv2, 1 );
    mv6 = __lasx_xvrepl128vei_d( mv3, 1 );

    nnz_mask = __lasx_xvor_v( nnz2, nnz3 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref2, ref3 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv3, mv2 );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );
    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[0][2], 0, 0 );

    two = __lasx_xvldi( 2 );
    dst = __lasx_xvldi( 0 );

    mv5 = __lasx_xvrepl128vei_d( mv3, 1 );
    mv6 = __lasx_xvrepl128vei_d( mv4, 1 );

    nnz_mask = __lasx_xvor_v( nnz3, nnz4 );
    nnz_mask = __lasx_xvseq_b( mask, nnz_mask );
    two = __lasx_xvbitsel_v( two, mask, nnz_mask );

    ref_mask = __lasx_xvseq_b( ref3, ref4 );
    ref_mask = __lasx_xvxori_b( ref_mask, 255 );

    sub0 = __lasx_xvabsd_h( mv4, mv3 );
    sub1 = __lasx_xvabsd_h( mv6, mv5 );
    sub0 = __lasx_xvsle_hu( four, sub0 );
    sub1 = __lasx_xvsle_hu( mvy_himit_vec, sub1 );

    sub0 = __lasx_xvpickev_b( sub0, sub0 );
    sub1 = __lasx_xvpickev_b( sub1, sub1 );
    ref_mask = __lasx_xvor_v( ref_mask, sub0 );
    ref_mask = __lasx_xvor_v( ref_mask, sub1 );

    dst = __lasx_xvbitsel_v( dst, one, ref_mask );
    dst = __lasx_xvbitsel_v( two, dst, nnz_mask );

    __lasx_xvstelm_w( dst, pu_bs[0][3], 0, 0 );
}

void x264_deblock_strength_lasx( uint8_t u_nnz[X264_SCAN8_SIZE],
                                 int8_t pi_lef[2][X264_SCAN8_LUMA_SIZE],
                                 int16_t pi_mv[2][X264_SCAN8_LUMA_SIZE][2],
                                 uint8_t pu_bs[2][8][4], int32_t i_mvy_himit,
                                 int32_t i_bframe )
{
    int32_t i_edge, i, loc, locn;
    int8_t* p_lef0 = pi_lef[0];
    int8_t* p_lef1 = pi_lef[1];
    uint8_t (*p_bs0)[4] = pu_bs[0];
    uint8_t (*p_bs1)[4] = pu_bs[1];
    int16_t (*p_mv0)[2] = pi_mv[0];
    int16_t (*p_mv1)[2] = pi_mv[1];

    if( i_bframe )
    {
        for( i_edge = 0; i_edge < 4; i_edge++ )
        {
            loc = X264_SCAN8_0 + i_edge;
            for( i = 0; i < 4; i++, loc += 8 )
            {
                locn = loc - 1;
                if( u_nnz[loc] || u_nnz[locn] )
                {
                    p_bs0[i_edge][i] = 2;
                }
                else if( p_lef0[loc] != p_lef0[locn] ||
                         abs( p_mv0[loc][0] - p_mv0[locn][0] ) >= 4 ||
                         abs( p_mv0[loc][1] - p_mv0[locn][1] ) >= i_mvy_himit ||
                         ( p_lef1[loc] != p_lef1[locn] ||
                           abs( p_mv1[loc][0] - p_mv1[locn][0] ) >= 4 ||
                           abs( p_mv1[loc][1] - p_mv1[locn][1] ) >= i_mvy_himit )
                       )
                {
                    p_bs0[i_edge][i] = 1;
                }
                else
                {
                    p_bs0[i_edge][i] = 0;
                }
            }
        }

        for( i_edge = 0; i_edge < 4; i_edge++ )
        {
            loc = X264_SCAN8_0 + ( i_edge << 3 );
            for( i = 0; i < 4; i++, loc++ )
            {
                locn = loc - 8;
                if( u_nnz[loc] || u_nnz[locn] )
                {
                    p_bs1[i_edge][i] = 2;
                }
                else if( p_lef0[loc] != p_lef0[locn] ||
                         abs( p_mv0[loc][0] - p_mv0[locn][0] ) >= 4 ||
                         abs( p_mv0[loc][1] - p_mv0[locn][1] ) >= i_mvy_himit ||
                         ( p_lef1[loc] != p_lef1[locn] ||
                           abs( p_mv1[loc][0] - p_mv1[locn][0] ) >= 4 ||
                           abs( p_mv1[loc][1] - p_mv1[locn][1] ) >= i_mvy_himit )
                       )
                {
                    p_bs1[i_edge][i] = 1;
                }
                else
                {
                    p_bs1[i_edge][i] = 0;
                }
            }
        }
    }
    else
    {
        avc_deblock_strength_lasx( u_nnz, pi_lef, pi_mv, pu_bs, i_mvy_himit );
    }
}

#endif
