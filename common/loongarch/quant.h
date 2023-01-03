/*****************************************************************************
 * quant.h: loongarch quantization and level-run
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

#ifndef X264_LOONGARCH_QUANT_H
#define X264_LOONGARCH_QUANT_H

#define x264_coeff_last64_lasx x264_template(coeff_last64_lasx)
int32_t x264_coeff_last64_lasx( int16_t *p_src );
#define x264_coeff_last16_lasx x264_template(coeff_last16_lasx)
int32_t x264_coeff_last16_lasx( int16_t *p_src );
#define x264_coeff_last15_lasx x264_template(coeff_last15_lasx)
int32_t x264_coeff_last15_lasx( int16_t *p_src );

#define x264_quant_4x4_lasx x264_template(quant_4x4_lasx)
int32_t x264_quant_4x4_lasx( int16_t *p_dct, uint16_t *p_mf, uint16_t *p_bias );
#define x264_quant_4x4x4_lasx x264_template(quant_4x4x4_lasx)
int32_t x264_quant_4x4x4_lasx( int16_t p_dct[4][16],
                               uint16_t pu_mf[16], uint16_t pu_bias[16] );
#define x264_quant_8x8_lasx x264_template(quant_8x8_lasx)
int32_t x264_quant_8x8_lasx( int16_t *p_dct, uint16_t *p_mf, uint16_t *p_bias );
#define x264_quant_4x4_dc_lasx x264_template(quant_4x4_dc_lasx)
int32_t x264_quant_4x4_dc_lasx( dctcoef dct[16], int32_t mf, int32_t bias );
#define x264_quant_2x2_dc_lsx x264_template(quant_2x2_dc_lsx)
int32_t x264_quant_2x2_dc_lsx( dctcoef dct[4], int32_t mf, int32_t bias );

#define x264_dequant_4x4_lasx x264_template(dequant_4x4_lasx)
void x264_dequant_4x4_lasx( dctcoef dct[16], int dequant_mf[6][16], int i_qp );
#define x264_dequant_8x8_lasx x264_template(dequant_8x8_lasx)
void x264_dequant_8x8_lasx( dctcoef dct[64], int dequant_mf[6][64], int i_qp );
#define x264_dequant_4x4_dc_lasx x264_template(dequant_4x4_dc_lasx)
void x264_dequant_4x4_dc_lasx( dctcoef dct[16], int dequant_mf[6][16], int i_qp );

#define x264_decimate_score15_lasx x264_template(decimate_score15_lasx)
int x264_decimate_score15_lasx( dctcoef *dct );
#define x264_decimate_score16_lasx x264_template(decimate_score16_lasx)
int x264_decimate_score16_lasx( dctcoef *dct );
#define x264_decimate_score64_lasx x264_template(decimate_score64_lasx)
int x264_decimate_score64_lasx( dctcoef *dct );

#endif/* X264_LOONGARCH_QUANT_H */
