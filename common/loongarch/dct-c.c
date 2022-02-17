/*****************************************************************************
 * dct-c.c: loongarch transform and zigzag
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
#include "dct.h"

#if !HIGH_BIT_DEPTH

#define LASX_LD4x4( p_src, out0, out1, out2, out3 )     \
{                                                       \
    out0 = __lasx_xvld( p_src, 0 );                     \
    out1 = __lasx_xvpermi_d( out0, 0x55 );              \
    out2 = __lasx_xvpermi_d( out0, 0xAA );              \
    out3 = __lasx_xvpermi_d( out0, 0xFF );              \
}

#define LASX_ITRANS_H( in0, in1, in2, in3, out0, out1, out2, out3 )         \
{                                                                           \
    __m256i tmp0_m, tmp1_m, tmp2_m, tmp3_m;                                 \
                                                                            \
    tmp0_m = __lasx_xvadd_h( in0, in2 );                                    \
    tmp1_m = __lasx_xvsub_h( in0, in2 );                                    \
    tmp2_m = __lasx_xvsrai_h( in1, 1 );                                     \
    tmp2_m = __lasx_xvsub_h( tmp2_m, in3 );                                 \
    tmp3_m = __lasx_xvsrai_h( in3, 1 );                                     \
    tmp3_m = __lasx_xvadd_h( in1, tmp3_m );                                 \
                                                                            \
    LASX_BUTTERFLY_4_H( tmp0_m, tmp1_m, tmp2_m, tmp3_m,                     \
                        out0, out1, out2, out3 );                           \
}

#define LASX_ADDBLK_ST4x4_128SV( in0, in1, in2, in3, p_dst, stride )        \
{                                                                           \
    uint32_t src0_m, src1_m, src2_m, src3_m;                                \
    uint8_t *p_dst0;                                                        \
    __m256i inp0_m, inp1_m, res0_m, res1_m;                                 \
    __m256i dst0_m = __lasx_xvldi( 0 );                                     \
    __m256i dst1_m = __lasx_xvldi( 0 );                                     \
    __m256i zero_m = __lasx_xvldi( 0 );                                     \
                                                                            \
    DUP2_ARG2( __lasx_xvilvl_d, in1, in0, in3, in2, inp0_m, inp1_m );       \
    src0_m = *( uint32_t* )( p_dst );                                       \
    p_dst0 = p_dst + stride;                                                \
    src1_m = *( uint32_t* )( p_dst0 );                                      \
    p_dst0 += stride;                                                       \
    src2_m = *( uint32_t* )( p_dst0 );                                      \
    p_dst0 += stride;                                                       \
    src3_m = *( uint32_t* )( p_dst0 );                                      \
    dst0_m = __lasx_xvinsgr2vr_w( dst0_m, src0_m, 0 );                      \
    dst0_m = __lasx_xvinsgr2vr_w( dst0_m, src1_m, 1 );                      \
    dst1_m = __lasx_xvinsgr2vr_w( dst1_m, src2_m, 0 );                      \
    dst1_m = __lasx_xvinsgr2vr_w( dst1_m, src3_m, 1 );                      \
    DUP2_ARG2( __lasx_xvilvl_b, zero_m, dst0_m, zero_m, dst1_m, res0_m,     \
               res1_m );                                                    \
    res0_m = __lasx_xvadd_h( res0_m, inp0_m );                              \
    res1_m = __lasx_xvadd_h( res1_m, inp1_m );                              \
    DUP2_ARG1( __lasx_xvclip255_h, res0_m, res1_m, res0_m, res1_m );        \
    DUP2_ARG2( __lasx_xvpickev_b, res0_m, res0_m, res1_m, res1_m, dst0_m,   \
               dst1_m );                                                    \
                                                                            \
    __lasx_xvstelm_w( dst0_m, p_dst, 0, 0 );                                \
    p_dst0 = p_dst + stride;                                                \
    __lasx_xvstelm_w( dst0_m, p_dst0, 0, 1 );                               \
    p_dst0 += stride;                                                       \
    __lasx_xvstelm_w( dst1_m, p_dst0, 0, 0 );                               \
    p_dst0 += stride;                                                       \
    __lasx_xvstelm_w( dst1_m, p_dst0, 0, 1 );                               \
}

static void avc_sub4x4_dct_lasx( uint8_t *p_src, int32_t i_src_stride,
                                 uint8_t *p_ref, int32_t i_dst_stride,
                                 int16_t *p_dst )
{
    __m256i src0, src1, src2, src3;
    __m256i ref0, ref1, ref2, ref3;
    __m256i inp0, inp1, tmp;
    __m256i diff0, diff1, diff2, diff3;
    __m256i temp0, temp1, temp2, temp3;

    src0 = __lasx_xvldrepl_w( p_src, 0 );
    p_src += i_src_stride;
    src1 = __lasx_xvldrepl_w( p_src, 0 );
    p_src += i_src_stride;
    src2 = __lasx_xvldrepl_w( p_src, 0 );
    p_src += i_src_stride;
    src3 = __lasx_xvldrepl_w( p_src, 0 );
    src0 = __lasx_xvpackev_w( src1, src0 );
    src1 = __lasx_xvpackev_w( src3, src2 );
    src0 = __lasx_xvpackev_d( src1, src0 );

    ref0 = __lasx_xvldrepl_w( p_ref, 0 );
    p_ref += i_dst_stride;
    ref1 = __lasx_xvldrepl_w( p_ref, 0 );
    p_ref += i_dst_stride;
    ref2 = __lasx_xvldrepl_w( p_ref, 0 );
    p_ref += i_dst_stride;
    ref3 = __lasx_xvldrepl_w( p_ref, 0 );
    ref0 = __lasx_xvpackev_w( ref1, ref0 );
    ref1 = __lasx_xvpackev_w( ref3, ref2 );
    ref0 = __lasx_xvpackev_d( ref1, ref0 );

    inp0 = __lasx_xvilvl_b( src0, ref0 );
    inp1 = __lasx_xvilvh_b( src0, ref0 );
    DUP2_ARG2( __lasx_xvhsubw_hu_bu, inp0, inp0, inp1, inp1, diff0, diff2 );
    DUP2_ARG2( __lasx_xvilvh_d, diff0, diff0, diff2, diff2, diff1, diff3 );

    LASX_BUTTERFLY_4_H( diff0, diff1, diff2, diff3, temp0, temp1, temp2, temp3 );

    diff0 = __lasx_xvadd_h( temp0, temp1);
    tmp = __lasx_xvslli_h( temp3, 1);
    diff1 = __lasx_xvadd_h( tmp, temp2);
    diff2 = __lasx_xvsub_h( temp0, temp1 );
    tmp = __lasx_xvslli_h( temp2, 1);
    diff3 = __lasx_xvsub_h( temp3, tmp );

    LASX_TRANSPOSE4x4_H( diff0, diff1, diff2, diff3, temp0, temp1, temp2, temp3 );
    LASX_BUTTERFLY_4_H( temp0, temp1, temp2, temp3, diff0, diff1, diff2, diff3 );

    temp0 = __lasx_xvadd_h( diff0, diff1);
    tmp = __lasx_xvslli_h( diff3, 1);
    temp1 = __lasx_xvadd_h( tmp, diff2);
    temp2 = __lasx_xvsub_h( diff0, diff1 );
    tmp = __lasx_xvslli_h( diff2, 1);
    temp3 = __lasx_xvsub_h( diff3, tmp );

    DUP2_ARG2( __lasx_xvilvl_d, temp1, temp0, temp3, temp2, inp0, inp1 );
    inp0 = __lasx_xvpermi_q(inp1, inp0, 0x20);
    __lasx_xvst( inp0, p_dst, 0 );
}

void x264_sub4x4_dct_lasx( int16_t p_dst[16], uint8_t *p_src,
                           uint8_t *p_ref )
{
    avc_sub4x4_dct_lasx( p_src, FENC_STRIDE, p_ref, FDEC_STRIDE, p_dst );
}

void x264_sub8x8_dct_lasx( int16_t p_dst[4][16], uint8_t *p_src,
                           uint8_t *p_ref )
{
    avc_sub4x4_dct_lasx( &p_src[0], FENC_STRIDE,
                         &p_ref[0], FDEC_STRIDE, p_dst[0] );
    avc_sub4x4_dct_lasx( &p_src[4], FENC_STRIDE, &p_ref[4],
                         FDEC_STRIDE, p_dst[1] );
    avc_sub4x4_dct_lasx( &p_src[4 * FENC_STRIDE + 0],
                         FENC_STRIDE, &p_ref[4 * FDEC_STRIDE + 0],
                         FDEC_STRIDE, p_dst[2] );
    avc_sub4x4_dct_lasx( &p_src[4 * FENC_STRIDE + 4],
                         FENC_STRIDE, &p_ref[4 * FDEC_STRIDE + 4],
                         FDEC_STRIDE, p_dst[3] );
}

void x264_sub16x16_dct_lasx( int16_t p_dst[16][16],
                             uint8_t *p_src,
                             uint8_t *p_ref )
{
    x264_sub8x8_dct_lasx( &p_dst[ 0], &p_src[0], &p_ref[0] );
    x264_sub8x8_dct_lasx( &p_dst[ 4], &p_src[8], &p_ref[8] );
    x264_sub8x8_dct_lasx( &p_dst[ 8], &p_src[8 * FENC_STRIDE + 0],
                          &p_ref[8*FDEC_STRIDE+0] );
    x264_sub8x8_dct_lasx( &p_dst[12], &p_src[8 * FENC_STRIDE + 8],
                          &p_ref[8*FDEC_STRIDE+8] );
}

static void avc_idct4x4_addblk_lasx( uint8_t *p_dst, int16_t *p_src,
                                     int32_t i_dst_stride )
{
    __m256i src0, src1, src2, src3;
    __m256i hres0, hres1, hres2, hres3;
    __m256i vres0, vres1, vres2, vres3;

    LASX_LD4x4( p_src, src0, src1, src2, src3 );
    LASX_ITRANS_H( src0, src1, src2, src3, hres0, hres1, hres2, hres3 );
    LASX_TRANSPOSE4x4_H( hres0, hres1, hres2, hres3, hres0, hres1, hres2, hres3 );
    LASX_ITRANS_H( hres0, hres1, hres2, hres3, vres0, vres1, vres2, vres3 );

    DUP4_ARG2( __lasx_xvsrari_h, vres0, 6, vres1, 6, vres2, 6, vres3, 6,
               vres0, vres1, vres2, vres3 );
    LASX_ADDBLK_ST4x4_128SV( vres0, vres1, vres2, vres3, p_dst, i_dst_stride );
}

void x264_add4x4_idct_lasx( uint8_t *p_dst, int16_t pi_dct[16] )
{
    avc_idct4x4_addblk_lasx( p_dst, pi_dct, FDEC_STRIDE );
}

void x264_add8x8_idct8_lasx( uint8_t *dst, int16_t dct[64] )
{
    int32_t stride2, stride3, stride4;
    uint8_t* dst_tmp;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
    __m256i reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7;
    __m256i shift = {0x0000000400000000, 0x0000000500000001,
                     0x0000000600000002, 0x0000000700000003};

    dct[0] += 32;
    stride2 = FDEC_STRIDE << 1;
    stride3 = FDEC_STRIDE + stride2;
    stride4 = stride2 << 1;
    dst_tmp = dst + stride4;

    src0 = __lasx_xvld(dct, 0);
    src2 = __lasx_xvld(dct, 32);
    src4 = __lasx_xvld(dct, 64);
    src6 = __lasx_xvld(dct, 96);
    src1 = __lasx_xvpermi_d(src0, 0x4E);
    src3 = __lasx_xvpermi_d(src2, 0x4E);
    src5 = __lasx_xvpermi_d(src4, 0x4E);
    src7 = __lasx_xvpermi_d(src6, 0x4E);

    src0 = __lasx_vext2xv_w_h(src0);
    src1 = __lasx_vext2xv_w_h(src1);
    src2 = __lasx_vext2xv_w_h(src2);
    src3 = __lasx_vext2xv_w_h(src3);
    src4 = __lasx_vext2xv_w_h(src4);
    src5 = __lasx_vext2xv_w_h(src5);
    src6 = __lasx_vext2xv_w_h(src6);
    src7 = __lasx_vext2xv_w_h(src7);

    tmp0 = __lasx_xvadd_w(src0, src4);
    tmp2 = __lasx_xvsub_w(src0, src4);
    tmp4 = __lasx_xvsrai_w(src2, 1);
    tmp4 = __lasx_xvsub_w(tmp4, src6);
    tmp6 = __lasx_xvsrai_w(src6, 1);
    tmp6 = __lasx_xvadd_w(tmp6, src2);
    reg7 = __lasx_xvsrai_w(src7, 1);
    reg3 = __lasx_xvsrai_w(src3, 1);
    reg5 = __lasx_xvsrai_w(src5, 1);
    reg1 = __lasx_xvsrai_w(src1, 1);
    tmp1 = __lasx_xvsub_w(src5, src3);
    tmp3 = __lasx_xvadd_w(src1, src7);
    tmp5 = __lasx_xvsub_w(src7, src1);
    tmp7 = __lasx_xvadd_w(src3, src5);
    reg7 = __lasx_xvadd_w(src7, reg7);
    reg3 = __lasx_xvadd_w(src3, reg3);
    reg5 = __lasx_xvadd_w(reg5, src5);
    reg1 = __lasx_xvadd_w(reg1, src1);
    tmp1 = __lasx_xvsub_w(tmp1, reg7);
    tmp3 = __lasx_xvsub_w(tmp3, reg3);
    tmp5 = __lasx_xvadd_w(reg5, tmp5);
    tmp7 = __lasx_xvadd_w(tmp7, reg1);
    reg0 = __lasx_xvadd_w(tmp0, tmp6);
    reg2 = __lasx_xvadd_w(tmp2, tmp4);
    reg4 = __lasx_xvsub_w(tmp2, tmp4);
    reg6 = __lasx_xvsub_w(tmp0, tmp6);
    reg1 = __lasx_xvsrai_w(tmp7, 2);
    reg3 = __lasx_xvsrai_w(tmp5, 2);
    reg5 = __lasx_xvsrai_w(tmp3, 2);
    reg7 = __lasx_xvsrai_w(tmp1, 2);
    reg1 = __lasx_xvadd_w(tmp1, reg1);
    reg3 = __lasx_xvadd_w(tmp3, reg3);
    reg5 = __lasx_xvsub_w(reg5, tmp5);
    reg7 = __lasx_xvsub_w(tmp7, reg7);

    src0 = __lasx_xvadd_w(reg0, reg7);
    src1 = __lasx_xvadd_w(reg2, reg5);
    src2 = __lasx_xvadd_w(reg4, reg3);
    src3 = __lasx_xvadd_w(reg6, reg1);
    src4 = __lasx_xvsub_w(reg6, reg1);
    src5 = __lasx_xvsub_w(reg4, reg3);
    src6 = __lasx_xvsub_w(reg2, reg5);
    src7 = __lasx_xvsub_w(reg0, reg7);

    LASX_TRANSPOSE8x8_W(src0, src1, src2, src3, src4, src5, src6, src7,
                        src0, src1, src2, src3, src4, src5, src6, src7);

    tmp0 = __lasx_xvaddwev_w_h(src0, src4);
    tmp2 = __lasx_xvsubwev_w_h(src0, src4);
    tmp4 = __lasx_xvsrai_h(src2, 1);
    tmp4 = __lasx_xvsubwev_w_h(tmp4, src6);
    tmp6 = __lasx_xvsrai_h(src6, 1);
    tmp6 = __lasx_xvaddwev_w_h(tmp6, src2);
    reg7 = __lasx_xvsrai_h(src7, 1);
    reg3 = __lasx_xvsrai_h(src3, 1);
    reg5 = __lasx_xvsrai_h(src5, 1);
    reg1 = __lasx_xvsrai_h(src1, 1);
    tmp1 = __lasx_xvsubwev_w_h(src5, src3);
    tmp3 = __lasx_xvaddwev_w_h(src1, src7);
    tmp5 = __lasx_xvsubwev_w_h(src7, src1);
    tmp7 = __lasx_xvaddwev_w_h(src3, src5);
    reg7 = __lasx_xvaddwev_w_h(src7, reg7);
    reg3 = __lasx_xvaddwev_w_h(src3, reg3);
    reg5 = __lasx_xvaddwev_w_h(reg5, src5);
    reg1 = __lasx_xvaddwev_w_h(reg1, src1);

    tmp1 = __lasx_xvsub_w(tmp1, reg7);
    tmp3 = __lasx_xvsub_w(tmp3, reg3);
    tmp5 = __lasx_xvadd_w(reg5, tmp5);
    tmp7 = __lasx_xvadd_w(tmp7, reg1);
    reg0 = __lasx_xvadd_w(tmp0, tmp6);
    reg2 = __lasx_xvadd_w(tmp2, tmp4);
    reg4 = __lasx_xvsub_w(tmp2, tmp4);
    reg6 = __lasx_xvsub_w(tmp0, tmp6);
    reg1 = __lasx_xvsrai_w(tmp7, 2);
    reg3 = __lasx_xvsrai_w(tmp5, 2);
    reg5 = __lasx_xvsrai_w(tmp3, 2);
    reg7 = __lasx_xvsrai_w(tmp1, 2);
    reg1 = __lasx_xvadd_w(tmp1, reg1);
    reg3 = __lasx_xvadd_w(tmp3, reg3);
    reg5 = __lasx_xvsub_w(reg5, tmp5);
    reg7 = __lasx_xvsub_w(tmp7, reg7);
    src0 = __lasx_xvadd_w(reg0, reg7);
    src1 = __lasx_xvadd_w(reg2, reg5);
    src2 = __lasx_xvadd_w(reg4, reg3);
    src3 = __lasx_xvadd_w(reg6, reg1);
    src4 = __lasx_xvsub_w(reg6, reg1);
    src5 = __lasx_xvsub_w(reg4, reg3);
    src6 = __lasx_xvsub_w(reg2, reg5);
    src7 = __lasx_xvsub_w(reg0, reg7);

    src0 = __lasx_xvsrai_w(src0, 6);
    src1 = __lasx_xvsrai_w(src1, 6);
    src2 = __lasx_xvsrai_w(src2, 6);
    src3 = __lasx_xvsrai_w(src3, 6);
    src4 = __lasx_xvsrai_w(src4, 6);
    src5 = __lasx_xvsrai_w(src5, 6);
    src6 = __lasx_xvsrai_w(src6, 6);
    src7 = __lasx_xvsrai_w(src7, 6);

    reg0 = __lasx_xvld(dst, 0);
    reg1 = __lasx_xvld(dst, FDEC_STRIDE);
    reg2 = __lasx_xvldx(dst, stride2);
    reg3 = __lasx_xvldx(dst, stride3);
    reg4 = __lasx_xvld(dst_tmp, 0);
    reg5 = __lasx_xvld(dst_tmp, FDEC_STRIDE);
    reg6 = __lasx_xvldx(dst_tmp, stride2);
    reg7 = __lasx_xvldx(dst_tmp, stride3);

    reg0 = __lasx_vext2xv_wu_bu(reg0);
    reg1 = __lasx_vext2xv_wu_bu(reg1);
    reg2 = __lasx_vext2xv_wu_bu(reg2);
    reg3 = __lasx_vext2xv_wu_bu(reg3);
    reg4 = __lasx_vext2xv_wu_bu(reg4);
    reg5 = __lasx_vext2xv_wu_bu(reg5);
    reg6 = __lasx_vext2xv_wu_bu(reg6);
    reg7 = __lasx_vext2xv_wu_bu(reg7);
    reg0 = __lasx_xvadd_w(reg0, src0);
    reg1 = __lasx_xvadd_w(reg1, src1);
    reg2 = __lasx_xvadd_w(reg2, src2);
    reg3 = __lasx_xvadd_w(reg3, src3);
    reg4 = __lasx_xvadd_w(reg4, src4);
    reg5 = __lasx_xvadd_w(reg5, src5);
    reg6 = __lasx_xvadd_w(reg6, src6);
    reg7 = __lasx_xvadd_w(reg7, src7);

    reg0 = __lasx_xvmaxi_w(reg0, 0);
    reg1 = __lasx_xvmaxi_w(reg1, 0);
    reg2 = __lasx_xvmaxi_w(reg2, 0);
    reg3 = __lasx_xvmaxi_w(reg3, 0);
    reg4 = __lasx_xvmaxi_w(reg4, 0);
    reg5 = __lasx_xvmaxi_w(reg5, 0);
    reg6 = __lasx_xvmaxi_w(reg6, 0);
    reg7 = __lasx_xvmaxi_w(reg7, 0);
    src0 = __lasx_xvssrlni_hu_w(reg1, reg0, 0);
    src1 = __lasx_xvssrlni_hu_w(reg3, reg2, 0);
    src2 = __lasx_xvssrlni_hu_w(reg5, reg4, 0);
    src3 = __lasx_xvssrlni_hu_w(reg7, reg6, 0);
    src0 = __lasx_xvssrlni_bu_h(src1, src0, 0);
    src1 = __lasx_xvssrlni_bu_h(src3, src2, 0);
    src0 = __lasx_xvperm_w(src0, shift);
    src1 = __lasx_xvperm_w(src1, shift);
    __lasx_xvstelm_d(src0, dst, 0, 0);
    dst += FDEC_STRIDE;
    __lasx_xvstelm_d(src0, dst, 0, 1);
    dst += FDEC_STRIDE;
    __lasx_xvstelm_d(src0, dst, 0, 2);
    dst += FDEC_STRIDE;
    __lasx_xvstelm_d(src0, dst, 0, 3);
    dst += FDEC_STRIDE;
    __lasx_xvstelm_d(src1, dst, 0, 0);
    dst += FDEC_STRIDE;
    __lasx_xvstelm_d(src1, dst, 0, 1);
    dst += FDEC_STRIDE;
    __lasx_xvstelm_d(src1, dst, 0, 2);
    dst += FDEC_STRIDE;
    __lasx_xvstelm_d(src1, dst, 0, 3);
}

void x264_add8x8_idct_lasx( uint8_t *p_dst, int16_t pi_dct[4][16] )
{
    avc_idct4x4_addblk_lasx( &p_dst[0], &pi_dct[0][0], FDEC_STRIDE );
    avc_idct4x4_addblk_lasx( &p_dst[4], &pi_dct[1][0], FDEC_STRIDE );
    avc_idct4x4_addblk_lasx( &p_dst[4 * FDEC_STRIDE + 0],
                            &pi_dct[2][0], FDEC_STRIDE );
    avc_idct4x4_addblk_lasx( &p_dst[4 * FDEC_STRIDE + 4],
                            &pi_dct[3][0], FDEC_STRIDE );
}

void x264_add16x16_idct_lasx( uint8_t *p_dst, int16_t pi_dct[16][16] )
{
    x264_add8x8_idct_lasx( &p_dst[0], &pi_dct[0] );
    x264_add8x8_idct_lasx( &p_dst[8], &pi_dct[4] );
    x264_add8x8_idct_lasx( &p_dst[8 * FDEC_STRIDE + 0], &pi_dct[8] );
    x264_add8x8_idct_lasx( &p_dst[8 * FDEC_STRIDE + 8], &pi_dct[12] );
}

void x264_add8x8_idct_dc_lasx( uint8_t *pdst, int16_t dct[4] )
{
    int32_t stride2 = FDEC_STRIDE << 1;
    int32_t stride3 = FDEC_STRIDE + stride2;
    int32_t stride4 = stride2 << 1;
    uint8_t *pdst_tmp = pdst + stride4;
    __m256i vec_dct, vec_dct0, vec_dct1;
    __m256i src0, src1, src2, src3, src4, src5, src6, src7;
    __m256i const_32 = __lasx_xvldi(0x420);

    vec_dct = __lasx_xvldrepl_d(dct, 0);
    vec_dct = __lasx_xvadd_h(vec_dct, const_32);
    vec_dct = __lasx_xvsrai_h(vec_dct, 6);
    vec_dct = __lasx_xvilvl_h(vec_dct, vec_dct);
    vec_dct0 = __lasx_xvilvl_w(vec_dct, vec_dct);
    vec_dct1 = __lasx_xvilvh_w(vec_dct, vec_dct);

    src0 = __lasx_xvld(pdst, 0);
    src1 = __lasx_xvld(pdst, FDEC_STRIDE);
    src2 = __lasx_xvldx(pdst, stride2);
    src3 = __lasx_xvldx(pdst, stride3);
    src4 = __lasx_xvld(pdst_tmp, 0);
    src5 = __lasx_xvld(pdst_tmp, FDEC_STRIDE);
    src6 = __lasx_xvldx(pdst_tmp, stride2);
    src7 = __lasx_xvldx(pdst_tmp, stride3);

    src0 = __lasx_xvilvl_d(src1, src0);
    src1 = __lasx_xvilvl_d(src3, src2);
    src2 = __lasx_xvilvl_d(src5, src4);
    src3 = __lasx_xvilvl_d(src7, src6);

    src0 = __lasx_vext2xv_hu_bu(src0);
    src1 = __lasx_vext2xv_hu_bu(src1);
    src2 = __lasx_vext2xv_hu_bu(src2);
    src3 = __lasx_vext2xv_hu_bu(src3);

    src0 = __lasx_xvadd_h(src0, vec_dct0);
    src1 = __lasx_xvadd_h(src1, vec_dct0);
    src2 = __lasx_xvadd_h(src2, vec_dct1);
    src3 = __lasx_xvadd_h(src3, vec_dct1);

    src0 = __lasx_xvmaxi_h(src0, 0);
    src1 = __lasx_xvmaxi_h(src1, 0);
    src2 = __lasx_xvmaxi_h(src2, 0);
    src3 = __lasx_xvmaxi_h(src3, 0);
    src0 = __lasx_xvssrlni_bu_h(src1, src0, 0);
    src1 = __lasx_xvssrlni_bu_h(src3, src2, 0);
    __lasx_xvstelm_d(src0, pdst, 0, 0);
    pdst += FDEC_STRIDE;
    __lasx_xvstelm_d(src0, pdst, 0, 2);
    pdst += FDEC_STRIDE;
    __lasx_xvstelm_d(src0, pdst, 0, 1);
    pdst += FDEC_STRIDE;
    __lasx_xvstelm_d(src0, pdst, 0, 3);
    __lasx_xvstelm_d(src1, pdst_tmp, 0, 0);
    pdst_tmp += FDEC_STRIDE;
    __lasx_xvstelm_d(src1, pdst_tmp, 0, 2);
    pdst_tmp += FDEC_STRIDE;
    __lasx_xvstelm_d(src1, pdst_tmp, 0, 1);
    pdst_tmp += FDEC_STRIDE;
    __lasx_xvstelm_d(src1, pdst_tmp, 0, 3);
}

/****************************************************************************
 * 8x8 transform:
 ****************************************************************************/

void x264_sub8x8_dct8_lasx( int16_t pi_dct[64], uint8_t *p_pix1,
                            uint8_t *p_pix2 )
{
    __m256i src0, src1, src2, src3;
    __m256i tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
    __m256i temp, temp1;
    __m256i zero = {0};
    __m256i s07, s16, s25, s34, d07, d16, d25, d34;
    __m256i a0, a1, a2, a3, a4, a5, a6, a7;

#define LOAD_PIX_DATA_2(data1, data2)                                     \
    DUP2_ARG2( __lasx_xvld, p_pix1, 0, p_pix1, FENC_STRIDE, src0, src1 ); \
    DUP2_ARG2( __lasx_xvld, p_pix2, 0, p_pix2, FDEC_STRIDE, src2, src3 ); \
    DUP4_ARG2( __lasx_xvilvl_b, zero, src0, zero, src1, zero, src2, zero, \
               src3, src0, src1, src2, src3 );                            \
    data1 = __lasx_xvsub_h( src0, src2 );                                 \
    data2 = __lasx_xvsub_h( src1, src3 );                                 \
    p_pix1 += ( FENC_STRIDE << 1 );                                       \
    p_pix2 += ( FDEC_STRIDE << 1 );

    LOAD_PIX_DATA_2(tmp0, tmp1);
    LOAD_PIX_DATA_2(tmp2, tmp3);
    LOAD_PIX_DATA_2(tmp4, tmp5);
    LOAD_PIX_DATA_2(tmp6, tmp7);

#undef LOAD_PIX_DATA_2

#define LASX_DCT8_1D                      \
    s07 = __lasx_xvadd_h( tmp0, tmp7 );   \
    s16 = __lasx_xvadd_h( tmp1, tmp6 );   \
    s25 = __lasx_xvadd_h( tmp2, tmp5 );   \
    s34 = __lasx_xvadd_h( tmp3, tmp4 );   \
    a0 = __lasx_xvadd_h( s07, s34 );      \
    a1 = __lasx_xvadd_h( s16, s25 );      \
    a2 = __lasx_xvsub_h( s07, s34 );      \
    a3 = __lasx_xvsub_h( s16, s25 );      \
                                          \
    d07 = __lasx_xvsub_h( tmp0, tmp7 );   \
    d16 = __lasx_xvsub_h( tmp1, tmp6 );   \
    d25 = __lasx_xvsub_h( tmp2, tmp5 );   \
    d34 = __lasx_xvsub_h( tmp3, tmp4 );   \
                                          \
    temp = __lasx_xvsrai_h( d07, 1 );     \
    temp = __lasx_xvadd_h( temp, d16 );   \
    temp = __lasx_xvadd_h( temp, d25 );   \
    a4 = __lasx_xvadd_h( temp, d07 );     \
                                          \
    temp = __lasx_xvsrai_h( d25, 1 );     \
    temp1 = __lasx_xvsub_h( d07, d34 );   \
    temp1 = __lasx_xvsub_h( temp1, d25 ); \
    a5 = __lasx_xvsub_h( temp1, temp );   \
                                          \
    temp = __lasx_xvsrai_h( d16, 1 );     \
    temp1 = __lasx_xvadd_h( d07, d34 );   \
    temp1 = __lasx_xvsub_h( temp1, d16 ); \
    a6 = __lasx_xvsub_h( temp1, temp );   \
                                          \
    temp = __lasx_xvsrai_h( d34, 1 );     \
    temp1 = __lasx_xvsub_h( d16, d25 );   \
    temp1 = __lasx_xvadd_h( temp1, d34 ); \
    a7 = __lasx_xvadd_h( temp1, temp );   \
                                          \
    tmp0 = __lasx_xvadd_h( a0, a1 );      \
    temp = __lasx_xvsrai_h( a7, 2 );      \
    tmp1 = __lasx_xvadd_h( a4, temp );    \
    temp = __lasx_xvsrai_h( a3, 1 );      \
    tmp2 = __lasx_xvadd_h( a2, temp );    \
    temp = __lasx_xvsrai_h( a6, 2 );      \
    tmp3 = __lasx_xvadd_h( a5, temp );    \
    tmp4 = __lasx_xvsub_h( a0, a1 );      \
    temp = __lasx_xvsrai_h( a5, 2 );      \
    tmp5 = __lasx_xvsub_h( a6, temp );    \
    temp = __lasx_xvsrai_h( a2, 1 );      \
    tmp6 = __lasx_xvsub_h( temp, a3 );    \
    temp = __lasx_xvsrai_h( a4, 2 );      \
    tmp7 = __lasx_xvsub_h( temp, a7 );

    LASX_DCT8_1D;
    LASX_TRANSPOSE8x8_H( tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7,
                         tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7);
    LASX_DCT8_1D;

#undef LASX_DCT8_1D

    __lasx_xvstelm_d( tmp0, &pi_dct[0], 0, 0 );
    __lasx_xvstelm_d( tmp0, &pi_dct[4], 0, 1 );
    __lasx_xvstelm_d( tmp1, &pi_dct[8], 0, 0 );
    __lasx_xvstelm_d( tmp1, &pi_dct[12], 0, 1 );
    __lasx_xvstelm_d( tmp2, &pi_dct[16], 0, 0 );
    __lasx_xvstelm_d( tmp2, &pi_dct[20], 0, 1 );
    __lasx_xvstelm_d( tmp3, &pi_dct[24], 0, 0 );
    __lasx_xvstelm_d( tmp3, &pi_dct[28], 0, 1 );
    __lasx_xvstelm_d( tmp4, &pi_dct[32], 0, 0 );
    __lasx_xvstelm_d( tmp4, &pi_dct[36], 0, 1 );
    __lasx_xvstelm_d( tmp5, &pi_dct[40], 0, 0 );
    __lasx_xvstelm_d( tmp5, &pi_dct[44], 0, 1 );
    __lasx_xvstelm_d( tmp6, &pi_dct[48], 0, 0 );
    __lasx_xvstelm_d( tmp6, &pi_dct[52], 0, 1 );
    __lasx_xvstelm_d( tmp7, &pi_dct[56], 0, 0 );
    __lasx_xvstelm_d( tmp7, &pi_dct[60], 0, 1 );
}

static void x264_sub8x8_dct8_ext_lasx( int16_t pi_dct1[64],
                                       uint8_t *p_pix1, uint8_t *p_pix2,
                                       int16_t pi_dct2[64] )
{
    __m256i src0, src1, src2, src3;
    __m256i tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
    __m256i temp, temp1;
    __m256i zero = {0};
    __m256i s07, s16, s25, s34, d07, d16, d25, d34;
    __m256i a0, a1, a2, a3, a4, a5, a6, a7;

#define LOAD_PIX_DATA_2_EXT(data1, data2)                                 \
    DUP2_ARG2( __lasx_xvld, p_pix1, 0, p_pix1, FENC_STRIDE, src0, src1 ); \
    DUP2_ARG2( __lasx_xvld, p_pix2, 0, p_pix2, FDEC_STRIDE, src2, src3 ); \
    src0 = __lasx_xvpermi_d( src0, 0x50 );                                \
    src1 = __lasx_xvpermi_d( src1, 0x50 );                                \
    src2 = __lasx_xvpermi_d( src2, 0x50 );                                \
    src3 = __lasx_xvpermi_d( src3, 0x50 );                                \
                                                                          \
    DUP4_ARG2( __lasx_xvilvl_b, zero, src0, zero, src1, zero, src2, zero, \
               src3, src0, src1, src2, src3 );                            \
    data1 = __lasx_xvsub_h( src0, src2 );                                 \
    data2 = __lasx_xvsub_h( src1, src3 );                                 \
    p_pix1 += ( FENC_STRIDE << 1 );                                       \
    p_pix2 += ( FDEC_STRIDE << 1 );

    LOAD_PIX_DATA_2_EXT(tmp0, tmp1);
    LOAD_PIX_DATA_2_EXT(tmp2, tmp3);
    LOAD_PIX_DATA_2_EXT(tmp4, tmp5);
    LOAD_PIX_DATA_2_EXT(tmp6, tmp7);

#undef LOAD_PIX_DATA_2_EXT

#define LASX_DCT8_1D_EXT                  \
    s07 = __lasx_xvadd_h( tmp0, tmp7 );   \
    s16 = __lasx_xvadd_h( tmp1, tmp6 );   \
    s25 = __lasx_xvadd_h( tmp2, tmp5 );   \
    s34 = __lasx_xvadd_h( tmp3, tmp4 );   \
    a0 = __lasx_xvadd_h( s07, s34 );      \
    a1 = __lasx_xvadd_h( s16, s25 );      \
    a2 = __lasx_xvsub_h( s07, s34 );      \
    a3 = __lasx_xvsub_h( s16, s25 );      \
                                          \
    d07 = __lasx_xvsub_h( tmp0, tmp7 );   \
    d16 = __lasx_xvsub_h( tmp1, tmp6 );   \
    d25 = __lasx_xvsub_h( tmp2, tmp5 );   \
    d34 = __lasx_xvsub_h( tmp3, tmp4 );   \
                                          \
    temp = __lasx_xvsrai_h( d07, 1 );     \
    temp = __lasx_xvadd_h( temp, d16 );   \
    temp = __lasx_xvadd_h( temp, d25 );   \
    a4 = __lasx_xvadd_h( temp, d07 );     \
                                          \
    temp = __lasx_xvsrai_h( d25, 1 );     \
    temp1 = __lasx_xvsub_h( d07, d34 );   \
    temp1 = __lasx_xvsub_h( temp1, d25 ); \
    a5 = __lasx_xvsub_h( temp1, temp );   \
                                          \
    temp = __lasx_xvsrai_h( d16, 1 );     \
    temp1 = __lasx_xvadd_h( d07, d34 );   \
    temp1 = __lasx_xvsub_h( temp1, d16 ); \
    a6 = __lasx_xvsub_h( temp1, temp );   \
                                          \
    temp = __lasx_xvsrai_h( d34, 1 );     \
    temp1 = __lasx_xvsub_h( d16, d25 );   \
    temp1 = __lasx_xvadd_h( temp1, d34 ); \
    a7 = __lasx_xvadd_h( temp1, temp );   \
                                          \
    tmp0 = __lasx_xvadd_h( a0, a1 );      \
    temp = __lasx_xvsrai_h( a7, 2 );      \
    tmp1 = __lasx_xvadd_h( a4, temp );    \
    temp = __lasx_xvsrai_h( a3, 1 );      \
    tmp2 = __lasx_xvadd_h( a2, temp );    \
    temp = __lasx_xvsrai_h( a6, 2 );      \
    tmp3 = __lasx_xvadd_h( a5, temp );    \
    tmp4 = __lasx_xvsub_h( a0, a1 );      \
    temp = __lasx_xvsrai_h( a5, 2 );      \
    tmp5 = __lasx_xvsub_h( a6, temp );    \
    temp = __lasx_xvsrai_h( a2, 1 );      \
    tmp6 = __lasx_xvsub_h( temp, a3 );    \
    temp = __lasx_xvsrai_h( a4, 2 );      \
    tmp7 = __lasx_xvsub_h( temp, a7 );

    LASX_DCT8_1D_EXT;
    LASX_TRANSPOSE8x8_H( tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7,
                         tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7);
    LASX_DCT8_1D_EXT;

#undef LASX_DCT8_1D_EXT

    __lasx_xvstelm_d( tmp0, &pi_dct1[0], 0, 0 );
    __lasx_xvstelm_d( tmp0, &pi_dct1[4], 0, 1 );
    __lasx_xvstelm_d( tmp1, &pi_dct1[8], 0, 0 );
    __lasx_xvstelm_d( tmp1, &pi_dct1[12], 0, 1 );
    __lasx_xvstelm_d( tmp2, &pi_dct1[16], 0, 0 );
    __lasx_xvstelm_d( tmp2, &pi_dct1[20], 0, 1 );
    __lasx_xvstelm_d( tmp3, &pi_dct1[24], 0, 0 );
    __lasx_xvstelm_d( tmp3, &pi_dct1[28], 0, 1 );
    __lasx_xvstelm_d( tmp4, &pi_dct1[32], 0, 0 );
    __lasx_xvstelm_d( tmp4, &pi_dct1[36], 0, 1 );
    __lasx_xvstelm_d( tmp5, &pi_dct1[40], 0, 0 );
    __lasx_xvstelm_d( tmp5, &pi_dct1[44], 0, 1 );
    __lasx_xvstelm_d( tmp6, &pi_dct1[48], 0, 0 );
    __lasx_xvstelm_d( tmp6, &pi_dct1[52], 0, 1 );
    __lasx_xvstelm_d( tmp7, &pi_dct1[56], 0, 0 );
    __lasx_xvstelm_d( tmp7, &pi_dct1[60], 0, 1 );

    __lasx_xvstelm_d( tmp0, &pi_dct2[0], 0, 2 );
    __lasx_xvstelm_d( tmp0, &pi_dct2[4], 0, 3 );
    __lasx_xvstelm_d( tmp1, &pi_dct2[8], 0, 2 );
    __lasx_xvstelm_d( tmp1, &pi_dct2[12], 0, 3 );
    __lasx_xvstelm_d( tmp2, &pi_dct2[16], 0, 2 );
    __lasx_xvstelm_d( tmp2, &pi_dct2[20], 0, 3 );
    __lasx_xvstelm_d( tmp3, &pi_dct2[24], 0, 2 );
    __lasx_xvstelm_d( tmp3, &pi_dct2[28], 0, 3 );
    __lasx_xvstelm_d( tmp4, &pi_dct2[32], 0, 2 );
    __lasx_xvstelm_d( tmp4, &pi_dct2[36], 0, 3 );
    __lasx_xvstelm_d( tmp5, &pi_dct2[40], 0, 2 );
    __lasx_xvstelm_d( tmp5, &pi_dct2[44], 0, 3 );
    __lasx_xvstelm_d( tmp6, &pi_dct2[48], 0, 2 );
    __lasx_xvstelm_d( tmp6, &pi_dct2[52], 0, 3 );
    __lasx_xvstelm_d( tmp7, &pi_dct2[56], 0, 2 );
    __lasx_xvstelm_d( tmp7, &pi_dct2[60], 0, 3 );

}

void x264_sub16x16_dct8_lasx( int16_t pi_dct[4][64], uint8_t *p_pix1,
                              uint8_t *p_pix2 )
{
    x264_sub8x8_dct8_ext_lasx( pi_dct[0], &p_pix1[0], &p_pix2[0],
                               pi_dct[1] );
    x264_sub8x8_dct8_ext_lasx( pi_dct[2], &p_pix1[8 * FENC_STRIDE + 0],
                               &p_pix2[8*FDEC_STRIDE+0], pi_dct[3] );
}

#endif
