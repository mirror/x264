/*****************************************************************************
 * pixel-c.c: loongarch pixel metrics
 *****************************************************************************
 * Copyright (C) 2023-2024 x264 project
 *
 * Authors: Hecai Yuan <yuanhecai@loongson.cn>
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
#include "pixel.h"
#include "predict.h"

#if !HIGH_BIT_DEPTH

uint64_t x264_pixel_hadamard_ac_8x8_lsx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = x264_hadamard_ac_8x8_lsx( p_pix, i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_8x16_lsx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = x264_hadamard_ac_8x8_lsx( p_pix, i_stride );
    u_sum += x264_hadamard_ac_8x8_lsx( p_pix + 8 * i_stride, i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_16x8_lsx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = x264_hadamard_ac_8x8_lsx( p_pix, i_stride );
    u_sum += x264_hadamard_ac_8x8_lsx( p_pix + 8, i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_16x16_lsx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = x264_hadamard_ac_8x8_lsx( p_pix, i_stride );
    u_sum += x264_hadamard_ac_8x8_lsx( p_pix + 8, i_stride );
    u_sum += x264_hadamard_ac_8x8_lsx( p_pix + 8 * i_stride, i_stride );
    u_sum += x264_hadamard_ac_8x8_lsx( p_pix + 8 * i_stride + 8, i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_8x8_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = x264_hadamard_ac_8x8_lasx( p_pix, i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

uint64_t x264_pixel_hadamard_ac_8x16_lasx( uint8_t *p_pix, intptr_t i_stride )
{
    uint64_t u_sum;

    u_sum = x264_hadamard_ac_8x8_lasx( p_pix, i_stride );
    u_sum += x264_hadamard_ac_8x8_lasx( p_pix + ( i_stride << 3 ), i_stride );

    return ( ( u_sum >> 34 ) << 32 ) + ( ( uint32_t ) u_sum >> 1 );
}

void x264_intra_sa8d_x3_8x8_lsx( uint8_t *p_enc, uint8_t p_edge[36],
                                 int32_t p_sad_array[3] )
{
    ALIGNED_ARRAY_16( uint8_t, pix, [8 * FDEC_STRIDE] );

    x264_predict_8x8_v_lsx( pix, p_edge );
    p_sad_array[0] = x264_pixel_sa8d_8x8_lsx( pix, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_predict_8x8_h_lsx( pix, p_edge );
    p_sad_array[1] = x264_pixel_sa8d_8x8_lsx( pix, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_predict_8x8_dc_lsx( pix, p_edge );
    p_sad_array[2] = x264_pixel_sa8d_8x8_lsx( pix, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );
}

void x264_intra_sa8d_x3_8x8_lasx( uint8_t *p_enc, uint8_t p_edge[36],
                                  int32_t p_sad_array[3] )
{
    ALIGNED_ARRAY_16( uint8_t, pix, [8 * FDEC_STRIDE] );

    x264_predict_8x8_v_lsx( pix, p_edge );
    p_sad_array[0] = x264_pixel_sa8d_8x8_lasx( pix, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_predict_8x8_h_lasx( pix, p_edge );
    p_sad_array[1] = x264_pixel_sa8d_8x8_lasx( pix, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_predict_8x8_dc_lsx( pix, p_edge );
    p_sad_array[2] = x264_pixel_sa8d_8x8_lasx( pix, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );
}

void x264_intra_satd_x3_4x4_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                 int32_t p_sad_array[3] )
{
    x264_predict_4x4_v_lsx( p_dec );
    p_sad_array[0] = x264_pixel_satd_4x4_lsx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_predict_4x4_h_lsx( p_dec );
    p_sad_array[1] = x264_pixel_satd_4x4_lsx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_predict_4x4_dc_lsx( p_dec );
    p_sad_array[2] = x264_pixel_satd_4x4_lsx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );
}

void x264_intra_satd_x3_16x16_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                   int32_t p_sad_array[3] )
{
    x264_predict_16x16_v_lsx( p_dec );
    p_sad_array[0] = x264_pixel_satd_16x16_lsx( p_dec, FDEC_STRIDE,
                                                p_enc, FENC_STRIDE );

    x264_predict_16x16_h_lsx( p_dec );
    p_sad_array[1] = x264_pixel_satd_16x16_lsx( p_dec, FDEC_STRIDE,
                                                p_enc, FENC_STRIDE );

    x264_predict_16x16_dc_lsx( p_dec );
    p_sad_array[2] = x264_pixel_satd_16x16_lsx( p_dec, FDEC_STRIDE,
                                                p_enc, FENC_STRIDE );
}

void x264_intra_satd_x3_16x16_lasx( uint8_t *p_enc, uint8_t *p_dec,
                                    int32_t p_sad_array[3] )
{
    x264_predict_16x16_v_lsx( p_dec );
    p_sad_array[0] = x264_pixel_satd_16x16_lasx( p_dec, FDEC_STRIDE,
                                                 p_enc, FENC_STRIDE );

    x264_predict_16x16_h_lsx( p_dec );
    p_sad_array[1] = x264_pixel_satd_16x16_lasx( p_dec, FDEC_STRIDE,
                                                 p_enc, FENC_STRIDE );

    x264_predict_16x16_dc_lsx( p_dec );
    p_sad_array[2] = x264_pixel_satd_16x16_lasx( p_dec, FDEC_STRIDE,
                                                 p_enc, FENC_STRIDE );
}

void x264_intra_satd_x3_8x8c_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                  int32_t p_sad_array[3] )
{
    x264_predict_8x8c_dc_lsx( p_dec );
    p_sad_array[0] = x264_pixel_satd_8x8_lsx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_predict_8x8c_h_lsx( p_dec );
    p_sad_array[1] = x264_pixel_satd_8x8_lsx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );

    x264_predict_8x8c_v_lsx( p_dec );
    p_sad_array[2] = x264_pixel_satd_8x8_lsx( p_dec, FDEC_STRIDE,
                                              p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_4x4_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                int32_t p_sad_array[3] )
{
    x264_predict_4x4_v_lsx( p_dec );
    p_sad_array[0] = x264_pixel_sad_4x4_lsx( p_dec, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );

    x264_predict_4x4_h_lsx( p_dec );
    p_sad_array[1] = x264_pixel_sad_4x4_lsx( p_dec, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );

    x264_predict_4x4_dc_lsx( p_dec );
    p_sad_array[2] = x264_pixel_sad_4x4_lsx( p_dec, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_16x16_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                  int32_t p_sad_array[3] )
{
    x264_predict_16x16_v_lsx( p_dec );
    p_sad_array[0] = x264_pixel_sad_16x16_lsx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_predict_16x16_h_lsx( p_dec );
    p_sad_array[1] = x264_pixel_sad_16x16_lsx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );

    x264_predict_16x16_dc_lsx( p_dec );
    p_sad_array[2] = x264_pixel_sad_16x16_lsx( p_dec, FDEC_STRIDE,
                                               p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_8x8_lsx( uint8_t *p_enc, uint8_t p_edge[36],
                                int32_t p_sad_array[3] )
{
    ALIGNED_ARRAY_16( uint8_t, pix, [8 * FDEC_STRIDE] );

    x264_predict_8x8_v_lsx( pix, p_edge );
    p_sad_array[0] = x264_pixel_sad_8x8_lsx( pix, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );

    x264_predict_8x8_h_lsx( pix, p_edge );
    p_sad_array[1] = x264_pixel_sad_8x8_lsx( pix, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );

    x264_predict_8x8_dc_lsx( pix, p_edge );
    p_sad_array[2] = x264_pixel_sad_8x8_lsx( pix, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );
}

void x264_intra_sad_x3_8x8c_lsx( uint8_t *p_enc, uint8_t *p_dec,
                                 int32_t p_sad_array[3] )
{
    x264_predict_8x8c_dc_lsx( p_dec );
    p_sad_array[0] = x264_pixel_sad_8x8_lsx( p_dec, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );

    x264_predict_8x8c_h_lsx( p_dec );
    p_sad_array[1] = x264_pixel_sad_8x8_lsx( p_dec, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );

    x264_predict_8x8c_v_lsx( p_dec );
    p_sad_array[2] = x264_pixel_sad_8x8_lsx( p_dec, FDEC_STRIDE,
                                             p_enc, FENC_STRIDE );
}


#endif
