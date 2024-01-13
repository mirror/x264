/*****************************************************************************
 * mc.h: loongarch motion compensation
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

#ifndef X264_LOONGARCH_MC_H
#define X264_LOONGARCH_MC_H

#define x264_mc_init_loongarch x264_template(mc_init_loongarch)
void x264_mc_init_loongarch( int cpu, x264_mc_functions_t *pf );

#define x264_pixel_avg_16x16_lsx x264_template(pixel_avg_16x16_lsx)
void x264_pixel_avg_16x16_lsx( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_16x8_lsx x264_template(pixel_avg_16x8_lsx)
void x264_pixel_avg_16x8_lsx( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_8x16_lsx x264_template(pixel_avg_8x16_lsx)
void x264_pixel_avg_8x16_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_8x8_lsx x264_template(pixel_avg_8x8_lsx)
void x264_pixel_avg_8x8_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_8x4_lsx x264_template(pixel_avg_8x4_lsx)
void x264_pixel_avg_8x4_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x16_lsx x264_template(pixel_avg_4x16_lsx)
void x264_pixel_avg_4x16_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x8_lsx x264_template(pixel_avg_4x8_lsx)
void x264_pixel_avg_4x8_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x4_lsx x264_template(pixel_avg_4x4_lsx)
void x264_pixel_avg_4x4_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x2_lsx x264_template(pixel_avg_4x2_lsx)
void x264_pixel_avg_4x2_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );

#define x264_pixel_avg2_w4_lsx x264_template(pixel_avg2_w4_lsx)
void x264_pixel_avg2_w4_lsx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );
#define x264_pixel_avg2_w8_lsx x264_template(pixel_avg2_w8_lsx)
void x264_pixel_avg2_w8_lsx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );
#define x264_pixel_avg2_w16_lsx x264_template(pixel_avg2_w16_lsx)
void x264_pixel_avg2_w16_lsx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );
#define x264_pixel_avg2_w20_lsx x264_template(pixel_avg2_w20_lsx)
void x264_pixel_avg2_w20_lsx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );

#define x264_mc_weight_w20_lsx x264_template(mc_weight_w20_lsx)
void x264_mc_weight_w20_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w20_noden_lsx x264_template(mc_weight_w20_noden_lsx)
void x264_mc_weight_w20_noden_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w16_lsx x264_template(mc_weight_w16_lsx)
void x264_mc_weight_w16_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w16_noden_lsx x264_template(mc_weight_w16_noden_lsx)
void x264_mc_weight_w16_noden_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w8_lsx x264_template(mc_weight_w8_lsx)
void x264_mc_weight_w8_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w8_noden_lsx x264_template(mc_weight_w8_noden_lsx)
void x264_mc_weight_w8_noden_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w4_lsx x264_template(mc_weight_w4_lsx)
void x264_mc_weight_w4_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w4_noden_lsx x264_template(mc_weight_w4_noden_lsx)
void x264_mc_weight_w4_noden_lsx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );

#define x264_mc_copy_w16_lsx x264_template(mc_copy_w16_lsx)
void x264_mc_copy_w16_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_mc_copy_w8_lsx x264_template(mc_copy_w8_lsx)
void x264_mc_copy_w8_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_mc_copy_w4_lsx x264_template(mc_copy_w4_lsx)
void x264_mc_copy_w4_lsx( uint8_t *, intptr_t, uint8_t *, intptr_t, int );

#define x264_store_interleave_chroma_lsx x264_template(store_interleave_chroma_lsx)
void x264_store_interleave_chroma_lsx( pixel *dst, intptr_t i_dst, pixel *srcu, pixel *srcv, int height );
#define x264_load_deinterleave_chroma_fenc_lsx x264_template(load_deinterleave_chroma_fenc_lsx)
void x264_load_deinterleave_chroma_fenc_lsx( pixel *dst, pixel *src, intptr_t i_src, int height );
#define x264_load_deinterleave_chroma_fdec_lsx x264_template(load_deinterleave_chroma_fdec_lsx)
void x264_load_deinterleave_chroma_fdec_lsx( pixel *dst, pixel *src, intptr_t i_src, int height );

#define x264_plane_copy_interleave_core_lsx x264_template(plane_copy_interleave_core_lsx)
void x264_plane_copy_interleave_core_lsx( pixel *dst,  intptr_t i_dst,
                                          pixel *srcu, intptr_t i_srcu,
                                          pixel *srcv, intptr_t i_srcv, int w, int h );
#define x264_plane_copy_deinterleave_lsx x264_template(plane_copy_deinterleave_lsx)
void x264_plane_copy_deinterleave_lsx( pixel *dstu, intptr_t i_dstu,
                                       pixel *dstv, intptr_t i_dstv,
                                       pixel *src,  intptr_t i_src, int w, int h );

#define x264_plane_copy_deinterleave_lasx x264_template(plane_copy_deinterleave_lasx)
void x264_plane_copy_deinterleave_lasx( pixel *dstu, intptr_t i_dstu,
                                        pixel *dstv, intptr_t i_dstv,
                                        pixel *src,  intptr_t i_src, int w, int h );

#define x264_prefetch_fenc_420_lsx x264_template(prefetch_fenc_420_lsx)
void x264_prefetch_fenc_420_lsx( uint8_t *pix_y, intptr_t stride_y,
                                 uint8_t *pix_uv, intptr_t stride_uv,
                                 int32_t mb_x );
#define x264_prefetch_fenc_422_lsx x264_template(prefetch_fenc_422_lsx)
void x264_prefetch_fenc_422_lsx( uint8_t *pix_y, intptr_t stride_y,
                                 uint8_t *pix_uv, intptr_t stride_uv,
                                 int32_t mb_x );
#define x264_prefetch_ref_lsx x264_template(prefetch_ref_lsx)
void x264_prefetch_ref_lsx( uint8_t *pix, intptr_t stride, int32_t parity );

#define x264_memcpy_aligned_lsx x264_template(memcpy_aligned_lsx)
void *x264_memcpy_aligned_lsx( void *dst, const void *src, size_t n );
#define x264_memzero_aligned_lsx x264_template(memzero_aligned_lsx)
void x264_memzero_aligned_lsx( void *p_dst, size_t n );

#define x264_hpel_filter_lsx x264_template(hpel_filter_lsx)
void x264_hpel_filter_lsx( pixel *, pixel *, pixel *, pixel *, intptr_t, int, int, int16_t * );
#define x264_frame_init_lowres_core_lsx x264_template(frame_init_lowres_core_lsx)
void x264_frame_init_lowres_core_lsx( uint8_t *, uint8_t *, uint8_t *, uint8_t *,
                                      uint8_t *, intptr_t, intptr_t, int, int );

#define x264_pixel_avg_16x8_lasx x264_template(pixel_avg_16x8_lasx)
void x264_pixel_avg_16x8_lasx( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_8x16_lasx x264_template(pixel_avg_8x16_lasx)
void x264_pixel_avg_8x16_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_8x8_lasx x264_template(pixel_avg_8x8_lasx)
void x264_pixel_avg_8x8_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_8x4_lasx x264_template(pixel_avg_8x4_lasx)
void x264_pixel_avg_8x4_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x16_lasx x264_template(pixel_avg_4x16_lasx)
void x264_pixel_avg_4x16_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x8_lasx x264_template(pixel_avg_4x8_lasx)
void x264_pixel_avg_4x8_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x4_lasx x264_template(pixel_avg_4x4_lasx)
void x264_pixel_avg_4x4_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_pixel_avg_4x2_lasx x264_template(pixel_avg_4x2_lasx)
void x264_pixel_avg_4x2_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, intptr_t, int );

#define x264_pixel_avg2_w4_lasx x264_template(pixel_avg2_w4_lasx)
void x264_pixel_avg2_w4_lasx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );
#define x264_pixel_avg2_w8_lasx x264_template(pixel_avg2_w8_lasx)
void x264_pixel_avg2_w8_lasx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );
#define x264_pixel_avg2_w16_lasx x264_template(pixel_avg2_w16_lasx)
void x264_pixel_avg2_w16_lasx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );
#define x264_pixel_avg2_w20_lasx x264_template(pixel_avg2_w20_lasx)
void x264_pixel_avg2_w20_lasx ( uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int );

#define x264_mc_weight_w20_lasx x264_template(mc_weight_w20_lasx)
void x264_mc_weight_w20_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w20_noden_lasx x264_template(mc_weight_w20_noden_lasx)
void x264_mc_weight_w20_noden_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w16_lasx x264_template(mc_weight_w16_lasx)
void x264_mc_weight_w16_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w16_noden_lasx x264_template(mc_weight_w16_noden_lasx)
void x264_mc_weight_w16_noden_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w8_lasx x264_template(mc_weight_w8_lasx)
void x264_mc_weight_w8_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w8_noden_lasx x264_template(mc_weight_w8_noden_lasx)
void x264_mc_weight_w8_noden_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w4_lasx x264_template(mc_weight_w4_lasx)
void x264_mc_weight_w4_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );
#define x264_mc_weight_w4_noden_lasx x264_template(mc_weight_w4_noden_lasx)
void x264_mc_weight_w4_noden_lasx( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );

#define x264_mc_copy_w16_lasx x264_template(mc_copy_w16_lasx)
void x264_mc_copy_w16_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_mc_copy_w8_lasx x264_template(mc_copy_w8_lasx)
void x264_mc_copy_w8_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, int );
#define x264_mc_copy_w4_lasx x264_template(mc_copy_w4_lasx)
void x264_mc_copy_w4_lasx( uint8_t *, intptr_t, uint8_t *, intptr_t, int );

#define x264_plane_copy_interleave_core_lasx x264_template(plane_copy_interleave_core_lasx)
void x264_plane_copy_interleave_core_lasx( pixel *dst,  intptr_t i_dst,
                                           pixel *srcu, intptr_t i_srcu,
                                           pixel *srcv, intptr_t i_srcv, int w, int h );

#define x264_plane_copy_deinterleave_lasx x264_template(plane_copy_deinterleave_lasx)
void x264_plane_copy_deinterleave_lasx( pixel *dstu, intptr_t i_dstu,
                                        pixel *dstv, intptr_t i_dstv,
                                        pixel *src,  intptr_t i_src, int w, int h );

#define x264_memzero_aligned_lasx x264_template(memzero_aligned_lasx)
void x264_memzero_aligned_lasx( void *p_dst, size_t n );

#define x264_hpel_filter_lasx x264_template(hpel_filter_lasx)
void x264_hpel_filter_lasx( pixel *, pixel *, pixel *, pixel *, intptr_t, int, int, int16_t * );
#define x264_frame_init_lowres_core_lasx x264_template(frame_init_lowres_core_lasx)
void x264_frame_init_lowres_core_lasx( uint8_t *, uint8_t *, uint8_t *, uint8_t *, uint8_t *,
                                       intptr_t, intptr_t, int, int );

#endif
