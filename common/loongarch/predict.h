/*****************************************************************************
 * predict.h: loongarch intra prediction
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Xiwei Gu <guxiwei-hf@loongson.cn>
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

#ifndef X264_LOONGARCH_PREDICT_H
#define X264_LOONGARCH_PREDICT_H

#define x264_predict_8x8c_p_lsx x264_template(predict_8x8c_p_lsx)
void x264_predict_8x8c_p_lsx(uint8_t *p_src);

#define x264_predict_8x8c_v_lsx x264_template(predict_8x8c_v_lsx)
void x264_predict_8x8c_v_lsx(uint8_t *p_src);

#define x264_predict_8x8c_h_lsx x264_template(predict_8x8c_h_lsx)
void x264_predict_8x8c_h_lsx(uint8_t *p_src);

#define x264_predict_8x8c_dc_lsx x264_template(predict_8x8c_dc_lsx)
void x264_predict_8x8c_dc_lsx(pixel *src);

#define x264_predict_8x8c_dc_128_lsx x264_template(predict_8x8c_dc_128_lsx)
void x264_predict_8x8c_dc_128_lsx(pixel *src);

#define x264_predict_8x8c_dc_top_lsx x264_template(predict_8x8c_dc_top_lsx)
void x264_predict_8x8c_dc_top_lsx(pixel *src);

#define x264_predict_8x8c_dc_left_lsx x264_template(predict_8x8c_dc_left_lsx)
void x264_predict_8x8c_dc_left_lsx(pixel *src);

#define x264_predict_16x16_dc_lsx x264_template(predict_16x16_dc_lsx)
void x264_predict_16x16_dc_lsx( pixel *src );

#define x264_predict_16x16_dc_left_lsx x264_template(predict_16x16_dc_left_lsx)
void x264_predict_16x16_dc_left_lsx( pixel *src );

#define x264_predict_16x16_dc_top_lsx x264_template(predict_16x16_dc_top_lsx)
void x264_predict_16x16_dc_top_lsx( pixel *src );

#define x264_predict_16x16_dc_128_lsx x264_template(predict_16x16_dc_128_lsx)
void x264_predict_16x16_dc_128_lsx( pixel *src );

#define x264_predict_16x16_h_lsx x264_template(predict_16x16_h_lsx)
void x264_predict_16x16_h_lsx( pixel *src );

#define x264_predict_16x16_v_lsx x264_template(predict_16x16_v_lsx)
void x264_predict_16x16_v_lsx( pixel *src );

#define x264_predict_16x16_p_lasx x264_template(predict_16x16_p_lasx)
void x264_predict_16x16_p_lasx( pixel *src );

#define x264_predict_16x16_p_lsx x264_template(predict_16x16_p_lsx)
void x264_predict_16x16_p_lsx( pixel *src );

#define x264_predict_8x8_v_lsx x264_template(predict_8x8_v_lsx)
void x264_predict_8x8_v_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_h_lasx x264_template(predict_8x8_h_lasx)
void x264_predict_8x8_h_lasx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_h_lsx x264_template(predict_8x8_h_lsx)
void x264_predict_8x8_h_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_dc_lsx x264_template(predict_8x8_dc_lsx)
void x264_predict_8x8_dc_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_dc_left_lsx x264_template(predict_8x8_dc_left_lsx)
void x264_predict_8x8_dc_left_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_dc_top_lsx x264_template(predict_8x8_dc_top_lsx)
void x264_predict_8x8_dc_top_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_dc_128_lsx x264_template(predict_8x8_dc_128_lsx)
void x264_predict_8x8_dc_128_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_ddl_lasx x264_template(predict_8x8_ddl_lasx)
void x264_predict_8x8_ddl_lasx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_ddl_lsx x264_template(predict_8x8_ddl_lsx)
void x264_predict_8x8_ddl_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_ddr_lasx x264_template(predict_8x8_ddr_lasx)
void x264_predict_8x8_ddr_lasx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_ddr_lsx x264_template(predict_8x8_ddr_lsx)
void x264_predict_8x8_ddr_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_vr_lasx x264_template(predict_8x8_vr_lasx)
void x264_predict_8x8_vr_lasx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_vr_lsx x264_template(predict_8x8_vr_lsx)
void x264_predict_8x8_vr_lsx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_vl_lasx x264_template(predict_8x8_vl_lasx)
void x264_predict_8x8_vl_lasx( pixel *src, pixel edge[36] );

#define x264_predict_8x8_vl_lsx x264_template(predict_8x8_vl_lsx)
void x264_predict_8x8_vl_lsx( pixel *src, pixel edge[36] );

#define x264_predict_4x4_v_lsx x264_template(predict_4x4_v_lsx)
void x264_predict_4x4_v_lsx( pixel *p_src );

#define x264_predict_4x4_h_lsx x264_template(predict_4x4_h_lsx)
void x264_predict_4x4_h_lsx( pixel *p_src );

#define x264_predict_4x4_dc_lsx x264_template(predict_4x4_dc_lsx)
void x264_predict_4x4_dc_lsx( pixel *p_src );

#define x264_predict_4x4_ddl_lsx x264_template(predict_4x4_ddl_lsx)
void x264_predict_4x4_ddl_lsx( pixel *p_src );

#define x264_predict_4x4_dc_top_lsx x264_template(predict_4x4_dc_top_lsx)
void x264_predict_4x4_dc_top_lsx( pixel *p_src );

#define x264_predict_4x4_dc_left_lsx x264_template(predict_4x4_dc_left_lsx)
void x264_predict_4x4_dc_left_lsx( pixel *p_src );

#define x264_predict_4x4_dc_128_lsx x264_template(predict_4x4_dc_128_lsx)
void x264_predict_4x4_dc_128_lsx( pixel *p_src );

#define x264_predict_4x4_init_loongarch x264_template(predict_4x4_init_loongarch)
void x264_predict_4x4_init_loongarch( int cpu, x264_predict_t pf[12] );
#define x264_predict_8x8_init_loongarch x264_template(predict_8x8_init_loongarch)
void x264_predict_8x8_init_loongarch( int cpu, x264_predict8x8_t pf[12],
                                      x264_predict_8x8_filter_t *predict_filter );
#define x264_predict_8x8c_init_loongarch x264_template(predict_8x8c_init_loongarch)
void x264_predict_8x8c_init_loongarch( int cpu, x264_predict_t pf[7] );
#define x264_predict_16x16_init_loongarch x264_template(predict_16x16_init_loongarch)
void x264_predict_16x16_init_loongarch( int cpu, x264_predict_t pf[7] );

#endif
