/*****************************************************************************
 * predict.h: loongarch intra prediction
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

#ifndef X264_LOONGARCH_PREDICT_H
#define X264_LOONGARCH_PREDICT_H

#define x264_intra_predict_dc_16x16_lasx x264_template(intra_predict_dc_16x16_lasx)
void x264_intra_predict_dc_16x16_lasx( uint8_t *p_src );
#define x264_intra_predict_hor_16x16_lasx x264_template(intra_predict_hor_16x16_lasx)
void x264_intra_predict_hor_16x16_lasx( uint8_t *p_src );
#define x264_intra_predict_vert_16x16_lasx x264_template(intra_predict_vert_16x16_lasx)
void x264_intra_predict_vert_16x16_lasx( uint8_t *p_src );

#define x264_intra_predict_dc_4blk_8x8_lasx x264_template(intra_predict_dc_4blk_8x8_lasx)
void x264_intra_predict_dc_4blk_8x8_lasx( uint8_t *p_src );
#define x264_intra_predict_hor_8x8_lasx x264_template(intra_predict_hor_8x8_lasx)
void x264_intra_predict_hor_8x8_lasx( uint8_t *p_src );
#define x264_intra_predict_vert_8x8_lasx x264_template(intra_predict_vert_8x8_lasx)
void x264_intra_predict_vert_8x8_lasx( uint8_t *p_src );

#define x264_intra_predict_dc_4x4_lasx x264_template(intra_predict_dc_4x4_lasx)
void x264_intra_predict_dc_4x4_lasx( uint8_t *p_src );
#define x264_intra_predict_hor_4x4_lasx x264_template(intra_predict_hor_4x4_lasx)
void x264_intra_predict_hor_4x4_lasx( uint8_t *p_src );
#define x264_intra_predict_vert_4x4_lasx x264_template(intra_predict_vert_4x4_lasx)
void x264_intra_predict_vert_4x4_lasx( uint8_t *p_src );

#define x264_intra_predict_dc_8x8_lasx x264_template(intra_predict_dc_8x8_lasx)
void x264_intra_predict_dc_8x8_lasx( uint8_t *p_src, uint8_t pu_xyz[36] );
#define x264_intra_predict_h_8x8_lasx x264_template(intra_predict_h_8x8_lasx)
void x264_intra_predict_h_8x8_lasx( uint8_t *p_src, uint8_t pu_xyz[36] );
#define x264_intra_predict_v_8x8_lasx x264_template(intra_predict_v_8x8_lasx)
void x264_intra_predict_v_8x8_lasx( uint8_t *p_src, uint8_t pu_xyz[36] );

#define x264_predict_16x16_init_lasx x264_template(predict_16x16_init_lasx)
void x264_predict_16x16_init_lasx( int cpu, x264_predict_t pf[7] );

#endif
