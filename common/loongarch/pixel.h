/*****************************************************************************
 * pixel.h: loongarch pixel metrics
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Lu Wang <wanglu@loongson.cn>
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

#ifndef X264_LOONGARCH_PIXEL_H
#define X264_LOONGARCH_PIXEL_H

#define x264_pixel_satd_4x4_lsx x264_template(pixel_satd_4x4_lsx)
int32_t x264_pixel_satd_4x4_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                 uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_4x8_lsx x264_template(pixel_satd_4x8_lsx)
int32_t x264_pixel_satd_4x8_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                 uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_4x16_lsx x264_template(pixel_satd_4x16_lsx)
int32_t x264_pixel_satd_4x16_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_8x4_lsx x264_template(pixel_satd_8x4_lsx)
int32_t x264_pixel_satd_8x4_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                 uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_8x8_lsx x264_template(pixel_satd_8x8_lsx)
int32_t x264_pixel_satd_8x8_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                 uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_8x16_lsx x264_template(pixel_satd_8x16_lsx)
int32_t x264_pixel_satd_8x16_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_16x8_lsx x264_template(pixel_satd_16x8_lsx)
int32_t x264_pixel_satd_16x8_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_16x16_lsx x264_template(pixel_satd_16x16_lsx)
int32_t x264_pixel_satd_16x16_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 );

#define x264_pixel_satd_4x8_lasx x264_template(pixel_satd_4x8_lasx)
int32_t x264_pixel_satd_4x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_4x16_lasx x264_template(pixel_satd_4x16_lasx)
int32_t x264_pixel_satd_4x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_8x4_lasx x264_template(pixel_satd_8x4_lasx)
int32_t x264_pixel_satd_8x4_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_8x8_lasx x264_template(pixel_satd_8x8_lasx)
int32_t x264_pixel_satd_8x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_8x16_lasx x264_template(pixel_satd_8x16_lasx)
int32_t x264_pixel_satd_8x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_16x8_lasx x264_template(pixel_satd_16x8_lasx)
int32_t x264_pixel_satd_16x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_satd_16x16_lasx x264_template(pixel_satd_16x16_lasx)
int32_t x264_pixel_satd_16x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                    uint8_t *p_pix2, intptr_t i_stride2 );

#define x264_pixel_sad_x4_16x16_lsx x264_template(pixel_sad_x4_16x16_lsx)
void x264_pixel_sad_x4_16x16_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  uint8_t *p_ref3, intptr_t i_ref_stride,
                                  int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_16x8_lsx x264_template(pixel_sad_x4_16x8_lsx)
void x264_pixel_sad_x4_16x8_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_8x16_lsx x264_template(pixel_sad_x4_8x16_lsx)
void x264_pixel_sad_x4_8x16_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_8x8_lsx x264_template(pixel_sad_x4_8x8_lsx)
void x264_pixel_sad_x4_8x8_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                uint8_t *p_ref3, intptr_t i_ref_stride,
                                int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_8x4_lsx x264_template(pixel_sad_x4_8x4_lsx)
void x264_pixel_sad_x4_8x4_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                uint8_t *p_ref3, intptr_t i_ref_stride,
                                int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_4x8_lsx x264_template(pixel_sad_x4_4x8_lsx)
void x264_pixel_sad_x4_4x8_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                uint8_t *p_ref3, intptr_t i_ref_stride,
                                int32_t p_sad_array[4] );

#define x264_pixel_sad_x4_16x16_lasx x264_template(pixel_sad_x4_16x16_lasx)
void x264_pixel_sad_x4_16x16_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                   uint8_t *p_ref1, uint8_t *p_ref2,
                                   uint8_t *p_ref3, intptr_t i_ref_stride,
                                   int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_16x8_lasx x264_template(pixel_sad_x4_16x8_lasx)
void x264_pixel_sad_x4_16x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  uint8_t *p_ref3, intptr_t i_ref_stride,
                                  int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_8x8_lasx x264_template(pixel_sad_x4_8x8_lasx)
void x264_pixel_sad_x4_8x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_8x4_lasx x264_template(pixel_sad_x4_8x4_lasx)
void x264_pixel_sad_x4_8x4_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 uint8_t *p_ref3, intptr_t i_ref_stride,
                                 int32_t p_sad_array[4] );
#define x264_pixel_sad_x4_4x4_lsx x264_template(pixel_sad_x4_4x4_lsx)
void x264_pixel_sad_x4_4x4_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                uint8_t *p_ref3, intptr_t i_ref_stride,
                                int32_t p_sad_array[4] );

#define x264_pixel_sad_x3_16x16_lsx x264_template(pixel_sad_x3_16x16_lsx)
void x264_pixel_sad_x3_16x16_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  intptr_t i_ref_stride,
                                  int32_t p_sad_array[3] );
#define x264_pixel_sad_x3_16x8_lsx x264_template(pixel_sad_x3_16x8_lsx)
void x264_pixel_sad_x3_16x8_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 intptr_t i_ref_stride,
                                 int32_t p_sad_array[3] );
#define x264_pixel_sad_x3_8x16_lsx x264_template(pixel_sad_x3_8x16_lsx)
void x264_pixel_sad_x3_8x16_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                 uint8_t *p_ref1, uint8_t *p_ref2,
                                 intptr_t i_ref_stride,
                                 int32_t p_sad_array[3] );
#define x264_pixel_sad_x3_8x8_lsx x264_template(pixel_sad_x3_8x8_lsx)
void x264_pixel_sad_x3_8x8_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                intptr_t i_ref_stride,
                                int32_t p_sad_array[3] );
#define x264_pixel_sad_x3_8x4_lsx x264_template(pixel_sad_x3_8x4_lsx)
void x264_pixel_sad_x3_8x4_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                intptr_t i_ref_stride,
                                int32_t p_sad_array[3] );
#define x264_pixel_sad_x3_4x4_lsx x264_template(pixel_sad_x3_4x4_lsx)
void x264_pixel_sad_x3_4x4_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                intptr_t i_ref_stride,
                                int32_t p_sad_array[3] );
#define x264_pixel_sad_x3_4x8_lsx x264_template(pixel_sad_x3_4x8_lsx)
void x264_pixel_sad_x3_4x8_lsx( uint8_t *p_src, uint8_t *p_ref0,
                                uint8_t *p_ref1, uint8_t *p_ref2,
                                intptr_t i_ref_stride,
                                int32_t p_sad_array[3] );

#define x264_pixel_sad_x3_16x16_lasx x264_template(pixel_sad_x3_16x16_lasx)
void x264_pixel_sad_x3_16x16_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  intptr_t i_ref_stride,
                                  int32_t p_sad_array[3] );
#define x264_pixel_sad_x3_16x8_lasx x264_template(pixel_sad_x3_16x8_lasx)
void x264_pixel_sad_x3_16x8_lasx( uint8_t *p_src, uint8_t *p_ref0,
                                  uint8_t *p_ref1, uint8_t *p_ref2,
                                  intptr_t i_ref_stride,
                                  int32_t p_sad_array[3] );

#define x264_pixel_sad_16x16_lsx x264_template(pixel_sad_16x16_lsx)
int32_t x264_pixel_sad_16x16_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_sad_16x8_lsx x264_template(pixel_sad_16x8_lsx)
int32_t x264_pixel_sad_16x8_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_sad_8x16_lsx x264_template(pixel_sad_8x16_lsx)
int32_t x264_pixel_sad_8x16_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_sad_8x8_lsx x264_template(pixel_sad_8x8_lsx)
int32_t x264_pixel_sad_8x8_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_sad_8x4_lsx x264_template(pixel_sad_8x4_lsx)
int32_t x264_pixel_sad_8x4_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_sad_4x16_lsx x264_template(pixel_sad_4x16_lsx)
int32_t x264_pixel_sad_4x16_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_sad_4x8_lsx x264_template(pixel_sad_4x8_lsx)
int32_t x264_pixel_sad_4x8_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_sad_4x4_lsx x264_template(pixel_sad_4x4_lsx)
int32_t x264_pixel_sad_4x4_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );

#define x264_pixel_sad_8x4_lasx x264_template(pixel_sad_8x4_lasx)
int32_t x264_pixel_sad_8x4_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );

#define x264_hadamard_ac_8x8_lsx x264_template(hadamard_ac_8x8_lsx)
uint64_t x264_hadamard_ac_8x8_lsx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_8x8_lsx x264_template(pixel_hadamard_ac_8x8_lsx)
uint64_t x264_pixel_hadamard_ac_8x8_lsx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_8x16_lsx x264_template(pixel_hadamard_ac_8x16_lsx)
uint64_t x264_pixel_hadamard_ac_8x16_lsx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_16x8_lsx x264_template(pixel_hadamard_ac_16x8_lsx)
uint64_t x264_pixel_hadamard_ac_16x8_lsx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_16x16_lsx x264_template(pixel_hadamard_ac_16x16_lsx)
uint64_t x264_pixel_hadamard_ac_16x16_lsx( uint8_t *p_pix, intptr_t i_stride );

#define x264_hadamard_ac_8x8_lasx x264_template(hadamard_ac_8x8_lasx)
uint64_t x264_hadamard_ac_8x8_lasx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_8x8_lasx x264_template(pixel_hadamard_ac_8x8_lasx)
uint64_t x264_pixel_hadamard_ac_8x8_lasx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_8x16_lasx x264_template(pixel_hadamard_ac_8x16_lasx)
uint64_t x264_pixel_hadamard_ac_8x16_lasx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_16x8_lasx x264_template(pixel_hadamard_ac_16x8_lasx)
uint64_t x264_pixel_hadamard_ac_16x8_lasx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_hadamard_ac_16x16_lasx x264_template(pixel_hadamard_ac_16x16_lasx)
uint64_t x264_pixel_hadamard_ac_16x16_lasx( uint8_t *p_pix, intptr_t i_stride );

#define x264_intra_satd_x3_16x16_lsx x264_template(intra_satd_x3_16x16_lsx)
void x264_intra_satd_x3_16x16_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                   int32_t p_sad_array[3] );
#define x264_intra_satd_x3_8x8c_lsx x264_template(intra_satd_x3_8x8c_lsx)
void x264_intra_satd_x3_8x8c_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                  int32_t p_sad_array[3] );
#define x264_intra_satd_x3_4x4_lsx x264_template(intra_satd_x3_4x4_lsx)
void x264_intra_satd_x3_4x4_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                 int32_t p_sad_array[3] );
#define x264_intra_satd_x3_16x16_lasx x264_template(intra_satd_x3_16x16_lasx)
void x264_intra_satd_x3_16x16_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                    int32_t p_sad_array[3] );

#define x264_pixel_ssd_16x16_lsx x264_template(pixel_ssd_16x16_lsx)
int32_t x264_pixel_ssd_16x16_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_16x8_lsx x264_template(pixel_ssd_16x8_lsx)
int32_t x264_pixel_ssd_16x8_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_8x16_lsx x264_template(pixel_ssd_8x16_lsx)
int32_t x264_pixel_ssd_8x16_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_8x8_lsx x264_template(pixel_ssd_8x8_lsx)
int32_t x264_pixel_ssd_8x8_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_8x4_lsx x264_template(pixel_ssd_8x4_lsx)
int32_t x264_pixel_ssd_8x4_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_4x16_lsx x264_template(pixel_ssd_4x16_lsx)
int32_t x264_pixel_ssd_4x16_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_4x8_lsx x264_template(pixel_ssd_4x8_lsx)
int32_t x264_pixel_ssd_4x8_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_4x4_lsx x264_template(pixel_ssd_4x4_lsx)
int32_t x264_pixel_ssd_4x4_lsx( uint8_t *p_src, intptr_t i_src_stride,
                                uint8_t *p_ref, intptr_t i_ref_stride );

#define x264_pixel_ssd_16x16_lasx x264_template(pixel_ssd_16x16_lasx)
int32_t x264_pixel_ssd_16x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                   uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_16x8_lasx x264_template(pixel_ssd_16x8_lasx)
int32_t x264_pixel_ssd_16x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_8x16_lasx x264_template(pixel_ssd_8x16_lasx)
int32_t x264_pixel_ssd_8x16_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                  uint8_t *p_ref, intptr_t i_ref_stride );
#define x264_pixel_ssd_8x8_lasx x264_template(pixel_ssd_8x8_lasx)
int32_t x264_pixel_ssd_8x8_lasx( uint8_t *p_src, intptr_t i_src_stride,
                                 uint8_t *p_ref, intptr_t i_ref_stride );

#define x264_pixel_var2_8x16_lsx x264_template(pixel_var2_8x16_lsx)
int32_t x264_pixel_var2_8x16_lsx( uint8_t *p_pix1, uint8_t *p_pix2,
                                   int32_t ssd[2] );
#define x264_pixel_var2_8x8_lsx x264_template(pixel_var2_8x8_lsx)
int32_t x264_pixel_var2_8x8_lsx( uint8_t *p_pix1, uint8_t *p_pix2,
                                 int32_t ssd[2] );
#define x264_pixel_var_16x16_lsx x264_template(pixel_var_16x16_lsx)
uint64_t x264_pixel_var_16x16_lsx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_var_8x16_lsx x264_template(pixel_var_8x16_lsx)
uint64_t x264_pixel_var_8x16_lsx( uint8_t *p_pix, intptr_t i_stride );
#define x264_pixel_var_8x8_lsx x264_template(pixel_var_8x8_lsx)
uint64_t x264_pixel_var_8x8_lsx( uint8_t *p_pix, intptr_t i_stride );

#define x264_pixel_var2_8x16_lasx x264_template(pixel_var2_8x16_lasx)
int32_t x264_pixel_var2_8x16_lasx( uint8_t *p_pix1, uint8_t *p_pix2,
                                   int32_t ssd[2] );
#define x264_pixel_var2_8x8_lasx x264_template(pixel_var2_8x8_lasx)
int32_t x264_pixel_var2_8x8_lasx( uint8_t *p_pix1, uint8_t *p_pix2,
                                  int32_t ssd[2] );

#define x264_pixel_sa8d_8x8_lsx x264_template(pixel_sa8d_8x8_lsx)
int32_t x264_pixel_sa8d_8x8_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                 uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_sa8d_16x16_lsx x264_template(pixel_sa8d_16x16_lsx)
int32_t x264_pixel_sa8d_16x16_lsx( uint8_t *p_pix1, intptr_t i_stride,
                                   uint8_t *p_pix2, intptr_t i_stride2 );

#define x264_intra_sa8d_x3_8x8_lsx x264_template(intra_sa8d_x3_8x8_lsx)
void x264_intra_sa8d_x3_8x8_lsx( uint8_t *p_enc, uint8_t p_edge[36],
                                 int32_t p_sad_array[3] );
#define x264_intra_sa8d_x3_8x8_lasx x264_template(intra_sa8d_x3_8x8_lasx)
void x264_intra_sa8d_x3_8x8_lasx( uint8_t *p_enc, uint8_t p_edge[36],
                                  int32_t p_sad_array[3] );
#define x264_pixel_sa8d_8x8_lasx x264_template(pixel_sa8d_8x8_lasx)
int32_t x264_pixel_sa8d_8x8_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                  uint8_t *p_pix2, intptr_t i_stride2 );
#define x264_pixel_sa8d_16x16_lasx x264_template(pixel_sa8d_16x16_lasx)
int32_t x264_pixel_sa8d_16x16_lasx( uint8_t *p_pix1, intptr_t i_stride,
                                    uint8_t *p_pix2, intptr_t i_stride2 );

#define x264_intra_sad_x3_16x16_lsx x264_template(intra_sad_x3_16x16_lsx)
void x264_intra_sad_x3_16x16_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                  int32_t p_sad_array[3] );
#define x264_intra_sad_x3_8x8_lsx x264_template(intra_sad_x3_8x8_lsx)
void x264_intra_sad_x3_8x8_lsx( uint8_t *p_enc, uint8_t p_edge[36],
                                int32_t p_sad_array[3] );
#define x264_intra_sad_x3_8x8c_lsx x264_template(intra_sad_x3_8x8c_lsx)
void x264_intra_sad_x3_8x8c_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                 int32_t p_sad_array[3] );
#define x264_intra_sad_x3_4x4_lsx x264_template(intra_sad_x3_4x4_lsx)
void x264_intra_sad_x3_4x4_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                int32_t p_sad_array[3] );

#endif
