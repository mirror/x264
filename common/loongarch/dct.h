/*****************************************************************************
 * dct.h: loongarch transform and zigzag
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Peng Zhou <zhoupeng@loongson.cn>
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

#ifndef X264_LOONGARCH_DCT_H
#define X264_LOONGARCH_DCT_H

#define x264_sub8x8_dct_lasx x264_template(sub8x8_dct_lasx)
void x264_sub8x8_dct_lasx( int16_t p_dst[4][16], uint8_t *p_src, uint8_t *p_ref );
#define x264_sub16x16_dct_lasx x264_template(sub16x16_dct_lasx)
void x264_sub16x16_dct_lasx( int16_t p_dst[16][16], uint8_t *p_src, uint8_t *p_ref );

#define x264_sub8x8_dct8_lsx x264_template(sub8x8_dct8_lsx)
void x264_sub8x8_dct8_lsx( int16_t pi_dct[64], uint8_t *p_pix1, uint8_t *p_pix2 );
#define x264_sub16x16_dct8_lasx x264_template(sub16x16_dct8_lasx)
void x264_sub16x16_dct8_lasx( int16_t pi_dct[4][64], uint8_t *p_pix1,
                              uint8_t *p_pix2 );

#define x264_add4x4_idct_lsx x264_template(add4x4_idct_lsx)
void x264_add4x4_idct_lsx( uint8_t *p_dst, int16_t pi_dct[16] );
#define x264_add8x8_idct_lasx x264_template(add8x8_idct_lasx)
void x264_add8x8_idct_lasx( uint8_t *p_dst, int16_t pi_dct[4][16] );
#define x264_add16x16_idct_lasx x264_template(add16x16_idct_lasx)
void x264_add16x16_idct_lasx( uint8_t *p_dst, int16_t pi_dct[16][16] );
#define x264_add8x8_idct8_lasx x264_template(add8x8_idct8_lasx)
void x264_add8x8_idct8_lasx( uint8_t *p_dst, int16_t pi_dct[64] );
#define x264_add8x8_idct_dc_lasx x264_template(add8x8_idct_dc_lasx)
void x264_add8x8_idct_dc_lasx( uint8_t *p_dst, int16_t dct[4] );
#define x264_add16x16_idct_dc_lasx x264_template(add16x16_idct_dc_lasx)
void x264_add16x16_idct_dc_lasx( uint8_t *p_dst, int16_t dct[16] );

#define x264_idct4x4dc_lasx x264_template(idct4x4dc_lasx)
void x264_idct4x4dc_lasx( int16_t d[16] );
#define x264_dct4x4dc_lasx x264_template(dct4x4dc_lasx)
void x264_dct4x4dc_lasx( int16_t d[16] );

#define x264_zigzag_scan_4x4_frame_lasx x264_template(zigzag_scan_4x4_frame_lasx)
void x264_zigzag_scan_4x4_frame_lasx( int16_t level[16], int16_t dct[16] );

#define x264_sub4x4_dct_lsx x264_template(sub4x4_dct_lsx)
void x264_sub4x4_dct_lsx( int16_t p_dst[16], uint8_t *p_src, uint8_t *p_ref );
#define x264_sub8x8_dct_lsx x264_template(sub8x8_dct_lsx)
void x264_sub8x8_dct_lsx( int16_t p_dst[4][16], uint8_t *p_src, uint8_t *p_ref );
#define x264_sub16x16_dct_lsx x264_template(sub16x16_dct_lsx)
void x264_sub16x16_dct_lsx( int16_t p_dst[16][16], uint8_t *p_src, uint8_t *p_ref );

#define x264_sub8x8_dct8_lsx x264_template(sub8x8_dct8_lsx)
void x264_sub8x8_dct8_lsx( int16_t pi_dct[64], uint8_t *p_pix1, uint8_t *p_pix2 );
#define x264_sub16x16_dct8_lsx x264_template(sub16x16_dct8_lsx)
void x264_sub16x16_dct8_lsx( int16_t pi_dct[4][64], uint8_t *p_pix1,
                              uint8_t *p_pix2 );

#define x264_add4x4_idct_lsx x264_template(add4x4_idct_lsx)
void x264_add4x4_idct_lsx( uint8_t *p_dst, int16_t pi_dct[16] );
#define x264_add8x8_idct_lsx x264_template(add8x8_idct_lsx)
void x264_add8x8_idct_lsx( uint8_t *p_dst, int16_t pi_dct[4][16] );
#define x264_add16x16_idct_lsx x264_template(add16x16_idct_lsx)
void x264_add16x16_idct_lsx( uint8_t *p_dst, int16_t pi_dct[16][16] );
#define x264_add8x8_idct8_lsx x264_template(add8x8_idct8_lsx)
void x264_add8x8_idct8_lsx( uint8_t *p_dst, int16_t pi_dct[64] );
#define x264_add8x8_idct_dc_lsx x264_template(add8x8_idct_dc_lsx)
void x264_add8x8_idct_dc_lsx( uint8_t *p_dst, int16_t dct[4] );
#define x264_add16x16_idct_dc_lsx x264_template(add16x16_idct_dc_lsx)
void x264_add16x16_idct_dc_lsx( uint8_t *p_dst, int16_t dct[16] );

#define x264_idct4x4dc_lsx x264_template(idct4x4dc_lsx)
void x264_idct4x4dc_lsx( int16_t d[16] );
#define x264_dct4x4dc_lsx x264_template(dct4x4dc_lsx)
void x264_dct4x4dc_lsx( int16_t d[16] );

#define x264_zigzag_scan_4x4_frame_lsx x264_template(zigzag_scan_4x4_frame_lsx)
void x264_zigzag_scan_4x4_frame_lsx( int16_t level[16], int16_t dct[16] );

#endif
