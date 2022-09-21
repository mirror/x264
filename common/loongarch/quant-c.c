/*****************************************************************************
 * quant-c.c: loongarch quantization and level-run
 *****************************************************************************
 * Copyright (C) 2020 x264 project
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
#include "quant.h"

#if !HIGH_BIT_DEPTH

static inline int32_t avc_quant_4x4_lasx( int16_t *p_dct,
                                          uint16_t *p_mf,
                                          uint16_t *p_bias )
{
    int32_t non_zero = 0;
    __m256i zero = __lasx_xvldi( 0 );
    __m256i dct_mask;
    __m256i dct, dct0, dct1;
    __m256i mf, mf0, mf1;
    __m256i bias, bias0, bias1;
    __m256i tmp;

    dct = __lasx_xvld( p_dct, 0 );
    bias = __lasx_xvld( p_bias, 0 );
    mf = __lasx_xvld( p_mf, 0 );

    dct_mask = __lasx_xvslei_h( dct, 0 );

    LASX_UNPCK_SH( dct, dct0, dct1 );
    bias0 = __lasx_xvilvl_h( zero, bias );
    bias1 = __lasx_xvilvh_h( zero, bias );
    mf0 = __lasx_xvilvl_h( zero, mf );
    mf1 = __lasx_xvilvh_h( zero, mf );

    dct0 = __lasx_xvadda_w( dct0, bias0 );
    dct1 = __lasx_xvadda_w( dct1, bias1 );
    dct0 = __lasx_xvmul_w(dct0, mf0);
    dct1 = __lasx_xvmul_w(dct1, mf1);

    dct = __lasx_xvsrani_h_w(dct1, dct0, 16);

    tmp = __lasx_xvhaddw_w_h( dct, dct );
    tmp = __lasx_xvhaddw_d_w(tmp, tmp);
    tmp = __lasx_xvhaddw_q_d(tmp, tmp);
    non_zero = __lasx_xvpickve2gr_w(tmp, 0) + __lasx_xvpickve2gr_w(tmp, 4);

    dct0 = __lasx_xvsub_h( zero, dct );
    dct = __lasx_xvbitsel_v( dct, dct0, dct_mask );
    __lasx_xvst( dct, p_dct, 0 );

    return !!non_zero;
}

static inline int32_t avc_quant_8x8_lasx( int16_t *p_dct,
                                          uint16_t *p_mf,
                                          uint16_t *p_bias )
{
    int32_t non_zero = 0;
    __m256i zero = __lasx_xvldi( 0 );
    __m256i dct_mask0, dct_mask1;
    __m256i dct0, dct1, dct0_0, dct0_1, dct1_0, dct1_1;
    __m256i mf0, mf1, mf0_0, mf0_1, mf1_0, mf1_1;
    __m256i bias0, bias1, bias0_0, bias0_1, bias1_0, bias1_1;
    __m256i tmp;

    dct0 = __lasx_xvld( p_dct, 0 );
    dct1 = __lasx_xvld( p_dct, 32 );
    bias0 = __lasx_xvld( p_bias, 0 );
    bias1 = __lasx_xvld( p_bias, 32 );
    mf0 = __lasx_xvld( p_mf, 0 );
    mf1 = __lasx_xvld( p_mf, 32 );

    dct_mask0 = __lasx_xvslei_h( dct0, 0 );
    dct_mask1 = __lasx_xvslei_h( dct1, 0 );

    LASX_UNPCK_SH( dct0, dct0_0, dct0_1 );
    LASX_UNPCK_SH( dct1, dct1_0, dct1_1 );
    bias0_0 = __lasx_xvilvl_h( zero, bias0 );
    bias0_1 = __lasx_xvilvh_h( zero, bias0 );
    bias1_0 = __lasx_xvilvl_h( zero, bias1 );
    bias1_1 = __lasx_xvilvh_h( zero, bias1 );
    mf0_0 = __lasx_xvilvl_h( zero, mf0 );
    mf0_1 = __lasx_xvilvh_h( zero, mf0 );
    mf1_0 = __lasx_xvilvl_h( zero, mf1 );
    mf1_1 = __lasx_xvilvh_h( zero, mf1 );

    dct0_0 = __lasx_xvadda_w( dct0_0, bias0_0 );
    dct0_1 = __lasx_xvadda_w( dct0_1, bias0_1 );
    dct1_0 = __lasx_xvadda_w( dct1_0, bias1_0 );
    dct1_1 = __lasx_xvadda_w( dct1_1, bias1_1 );

    dct0_0 = __lasx_xvmul_w( dct0_0, mf0_0 );
    dct0_1 = __lasx_xvmul_w( dct0_1, mf0_1 );
    dct1_0 = __lasx_xvmul_w( dct1_0, mf1_0 );
    dct1_1 = __lasx_xvmul_w( dct1_1, mf1_1 );

    dct0 = __lasx_xvsrani_h_w( dct0_1, dct0_0, 16 );
    dct1 = __lasx_xvsrani_h_w( dct1_1, dct1_0, 16 );

    tmp = __lasx_xvadd_h( dct0, dct1 );
    tmp = __lasx_xvhaddw_w_h( tmp, tmp );
    tmp = __lasx_xvhaddw_d_w(tmp, tmp);
    tmp = __lasx_xvhaddw_q_d(tmp, tmp);
    non_zero = __lasx_xvpickve2gr_w(tmp, 0) + __lasx_xvpickve2gr_w(tmp, 4);

    dct0_0 = __lasx_xvsub_h( zero, dct0 );
    dct1_0 = __lasx_xvsub_h( zero, dct1 );
    dct0 = __lasx_xvbitsel_v( dct0, dct0_0, dct_mask0 );
    dct1 = __lasx_xvbitsel_v( dct1, dct1_0, dct_mask1 );

    __lasx_xvst( dct0, p_dct, 0 );
    __lasx_xvst( dct1, p_dct, 32 );

    /* next part */
    dct0 = __lasx_xvld( p_dct, 64 );
    dct1 = __lasx_xvld( p_dct, 96 );
    bias0 = __lasx_xvld( p_bias, 64 );
    bias1 = __lasx_xvld( p_bias, 96 );
    mf0 = __lasx_xvld( p_mf, 64 );
    mf1 = __lasx_xvld( p_mf, 96 );

    dct_mask0 = __lasx_xvslei_h( dct0, 0 );
    dct_mask1 = __lasx_xvslei_h( dct1, 0 );

    LASX_UNPCK_SH( dct0, dct0_0, dct0_1 );
    LASX_UNPCK_SH( dct1, dct1_0, dct1_1 );
    bias0_0 = __lasx_xvilvl_h( zero, bias0 );
    bias0_1 = __lasx_xvilvh_h( zero, bias0 );
    bias1_0 = __lasx_xvilvl_h( zero, bias1 );
    bias1_1 = __lasx_xvilvh_h( zero, bias1 );
    mf0_0 = __lasx_xvilvl_h( zero, mf0 );
    mf0_1 = __lasx_xvilvh_h( zero, mf0 );
    mf1_0 = __lasx_xvilvl_h( zero, mf1 );
    mf1_1 = __lasx_xvilvh_h( zero, mf1 );

    dct0_0 = __lasx_xvadda_w( dct0_0, bias0_0 );
    dct0_1 = __lasx_xvadda_w( dct0_1, bias0_1 );
    dct1_0 = __lasx_xvadda_w( dct1_0, bias1_0 );
    dct1_1 = __lasx_xvadda_w( dct1_1, bias1_1 );

    dct0_0 = __lasx_xvmul_w( dct0_0, mf0_0 );
    dct0_1 = __lasx_xvmul_w( dct0_1, mf0_1 );
    dct1_0 = __lasx_xvmul_w( dct1_0, mf1_0 );
    dct1_1 = __lasx_xvmul_w( dct1_1, mf1_1 );

    dct0 = __lasx_xvsrani_h_w( dct0_1, dct0_0, 16 );
    dct1 = __lasx_xvsrani_h_w( dct1_1, dct1_0, 16 );

    tmp = __lasx_xvadd_h( dct0, dct1 );
    tmp = __lasx_xvhaddw_w_h( tmp, tmp );
    tmp = __lasx_xvhaddw_d_w(tmp, tmp);
    tmp = __lasx_xvhaddw_q_d(tmp, tmp);
    non_zero += __lasx_xvpickve2gr_w(tmp, 0) + __lasx_xvpickve2gr_w(tmp, 4);

    dct0_0 = __lasx_xvsub_h( zero, dct0 );
    dct1_0 = __lasx_xvsub_h( zero, dct1 );
    dct0 = __lasx_xvbitsel_v( dct0, dct0_0, dct_mask0 );
    dct1 = __lasx_xvbitsel_v( dct1, dct1_0, dct_mask1 );

    __lasx_xvst( dct0, p_dct, 64 );
    __lasx_xvst( dct1, p_dct, 96 );

    return !!non_zero;
}

int32_t x264_coeff_last16_lasx( int16_t *p_src )
{
    __m256i src0, tmp0, tmp1;
    __m256i one = __lasx_xvldi(1);
    int32_t result;

    src0 = __lasx_xvld( p_src, 0 );
    tmp0 = __lasx_xvssrlni_bu_h(src0, src0, 0);
    tmp0 = __lasx_xvpermi_d(tmp0, 0xD8);
    tmp1 = __lasx_xvsle_bu(one, tmp0);
    tmp0 = __lasx_xvssrlni_bu_h(tmp1, tmp1, 4);
    tmp1 = __lasx_xvclz_d(tmp0);
    result = __lasx_xvpickve2gr_w(tmp1, 0);

    return 15 - (result >> 2);
}

int32_t x264_coeff_last15_lasx( int16_t *psrc )
{
    __m256i src0, tmp0, tmp1;
    __m256i one = __lasx_xvldi(1);
    int32_t result;

    src0 = __lasx_xvld( psrc, -2 );
    tmp0 = __lasx_xvssrlni_bu_h(src0, src0, 0);
    tmp0 = __lasx_xvpermi_d(tmp0, 0xD8);
    tmp1 = __lasx_xvsle_bu(one, tmp0);
    tmp0 = __lasx_xvssrlni_bu_h(tmp1, tmp1, 4);
    tmp1 = __lasx_xvclz_d(tmp0);
    result = __lasx_xvpickve2gr_w(tmp1, 0);

    return 14 - (result >> 2);
}

int32_t x264_coeff_last64_lasx( int16_t *p_src )
{
    int32_t result;
    __m256i src0, src1, src2, src3;
    __m256i tmp0, tmp1, tmp2, tmp3;
    __m256i one = __lasx_xvldi(1);
    __m256i const_8 = __lasx_xvldi(0x408);
    __m256i const_1 = __lasx_xvldi(0x401);
    __m256i shift = {0x0000000400000000, 0x0000000500000001,
                     0x0000000600000002, 0x0000000700000003};
    src0 = __lasx_xvld( p_src, 0 );
    src1 = __lasx_xvld( p_src, 32);
    src2 = __lasx_xvld( p_src, 64);
    src3 = __lasx_xvld( p_src, 96);

    tmp0 = __lasx_xvssrlni_bu_h(src1, src0, 0);
    tmp1 = __lasx_xvssrlni_bu_h(src3, src2, 0);
    tmp2 = __lasx_xvsle_bu(one, tmp0);
    tmp3 = __lasx_xvsle_bu(one, tmp1);
    tmp0 = __lasx_xvssrlni_bu_h(tmp3, tmp2, 4);
    tmp0 = __lasx_xvperm_w(tmp0, shift);
    tmp1 = __lasx_xvclz_w(tmp0);
    tmp0 = __lasx_xvssrlni_hu_w(tmp1, tmp1, 2);
    tmp0 = __lasx_xvpermi_d(tmp0, 0xD8);

    tmp1 = __lasx_xvsub_h(const_8, tmp0);
    tmp0 = __lasx_xvsll_h(const_1, tmp1);
    tmp0 = __lasx_xvssrlni_bu_h(tmp0, tmp0, 1);
    tmp1 = __lasx_xvclz_d(tmp0);
    result = __lasx_xvpickve2gr_w(tmp1, 0);
    return 63 - result;
}

int32_t x264_quant_4x4_lasx( int16_t *p_dct, uint16_t *p_mf, uint16_t *p_bias )
{
    return avc_quant_4x4_lasx( p_dct, p_mf, p_bias );
}

int32_t x264_quant_4x4x4_lasx( int16_t p_dct[4][16],
                               uint16_t pu_mf[16], uint16_t pu_bias[16] )
{
    int32_t i_non_zero, i_non_zero_acc = 0;

    for( int32_t j = 0; j < 4; j++  )
    {
        i_non_zero = x264_quant_4x4_lasx( p_dct[j], pu_mf, pu_bias );

        i_non_zero_acc |= ( !!i_non_zero ) << j;
    }

    return i_non_zero_acc;
}

int32_t x264_quant_8x8_lasx( int16_t *p_dct, uint16_t *p_mf, uint16_t *p_bias )
{
    return avc_quant_8x8_lasx( p_dct, p_mf, p_bias );
}

#endif /* !HIGH_BIT_DEPTH */
