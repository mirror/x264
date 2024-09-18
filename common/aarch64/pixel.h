/*****************************************************************************
 * pixel.h: aarch64 pixel metrics
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *          Janne Grunau <janne-x264@jannau.net>
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

#ifndef X264_AARCH64_PIXEL_H
#define X264_AARCH64_PIXEL_H

#define x264_pixel_sad_16x16_neon x264_template(pixel_sad_16x16_neon)
#define x264_pixel_sad_16x8_neon x264_template(pixel_sad_16x8_neon)
#define x264_pixel_sad_4x16_neon x264_template(pixel_sad_4x16_neon)
#define x264_pixel_sad_4x4_neon x264_template(pixel_sad_4x4_neon)
#define x264_pixel_sad_4x8_neon x264_template(pixel_sad_4x8_neon)
#define x264_pixel_sad_8x16_neon x264_template(pixel_sad_8x16_neon)
#define x264_pixel_sad_8x4_neon x264_template(pixel_sad_8x4_neon)
#define x264_pixel_sad_8x8_neon x264_template(pixel_sad_8x8_neon)
#define x264_pixel_sad_x3_16x16_neon x264_template(pixel_sad_x3_16x16_neon)
#define x264_pixel_sad_x3_16x8_neon x264_template(pixel_sad_x3_16x8_neon)
#define x264_pixel_sad_x3_4x4_neon x264_template(pixel_sad_x3_4x4_neon)
#define x264_pixel_sad_x3_4x8_neon x264_template(pixel_sad_x3_4x8_neon)
#define x264_pixel_sad_x3_8x16_neon x264_template(pixel_sad_x3_8x16_neon)
#define x264_pixel_sad_x3_8x4_neon x264_template(pixel_sad_x3_8x4_neon)
#define x264_pixel_sad_x3_8x8_neon x264_template(pixel_sad_x3_8x8_neon)
#define x264_pixel_sad_x4_16x16_neon x264_template(pixel_sad_x4_16x16_neon)
#define x264_pixel_sad_x4_16x8_neon x264_template(pixel_sad_x4_16x8_neon)
#define x264_pixel_sad_x4_4x4_neon x264_template(pixel_sad_x4_4x4_neon)
#define x264_pixel_sad_x4_4x8_neon x264_template(pixel_sad_x4_4x8_neon)
#define x264_pixel_sad_x4_8x16_neon x264_template(pixel_sad_x4_8x16_neon)
#define x264_pixel_sad_x4_8x4_neon x264_template(pixel_sad_x4_8x4_neon)
#define x264_pixel_sad_x4_8x8_neon x264_template(pixel_sad_x4_8x8_neon)
#define x264_pixel_satd_16x16_neon x264_template(pixel_satd_16x16_neon)
#define x264_pixel_satd_16x8_neon x264_template(pixel_satd_16x8_neon)
#define x264_pixel_satd_4x16_neon x264_template(pixel_satd_4x16_neon)
#define x264_pixel_satd_4x4_neon x264_template(pixel_satd_4x4_neon)
#define x264_pixel_satd_4x8_neon x264_template(pixel_satd_4x8_neon)
#define x264_pixel_satd_8x16_neon x264_template(pixel_satd_8x16_neon)
#define x264_pixel_satd_8x4_neon x264_template(pixel_satd_8x4_neon)
#define x264_pixel_satd_8x8_neon x264_template(pixel_satd_8x8_neon)
#define x264_pixel_ssd_16x16_neon x264_template(pixel_ssd_16x16_neon)
#define x264_pixel_ssd_16x8_neon x264_template(pixel_ssd_16x8_neon)
#define x264_pixel_ssd_4x16_neon x264_template(pixel_ssd_4x16_neon)
#define x264_pixel_ssd_4x4_neon x264_template(pixel_ssd_4x4_neon)
#define x264_pixel_ssd_4x8_neon x264_template(pixel_ssd_4x8_neon)
#define x264_pixel_ssd_8x16_neon x264_template(pixel_ssd_8x16_neon)
#define x264_pixel_ssd_8x4_neon x264_template(pixel_ssd_8x4_neon)
#define x264_pixel_ssd_8x8_neon x264_template(pixel_ssd_8x8_neon)
#define x264_pixel_ssd_4x16_sve x264_template(pixel_ssd_4x16_sve)
#define x264_pixel_ssd_4x4_sve x264_template(pixel_ssd_4x4_sve)
#define x264_pixel_ssd_4x8_sve x264_template(pixel_ssd_4x8_sve)
#define x264_pixel_ssd_8x4_sve x264_template(pixel_ssd_8x4_sve)
#define x264_pixel_ssd_8x8_sve x264_template(pixel_ssd_8x8_sve)
#define DECL_PIXELS( ret, name, suffix, args ) \
    ret x264_pixel_##name##_16x16_##suffix args;\
    ret x264_pixel_##name##_16x8_##suffix args;\
    ret x264_pixel_##name##_8x16_##suffix args;\
    ret x264_pixel_##name##_8x8_##suffix args;\
    ret x264_pixel_##name##_8x4_##suffix args;\
    ret x264_pixel_##name##_4x16_##suffix args;\
    ret x264_pixel_##name##_4x8_##suffix args;\
    ret x264_pixel_##name##_4x4_##suffix args;
#define DECL_PIXELS_SSD_SVE( ret, args ) \
    ret x264_pixel_ssd_8x8_sve args;\
    ret x264_pixel_ssd_8x4_sve args;\
    ret x264_pixel_ssd_4x16_sve args;\
    ret x264_pixel_ssd_4x8_sve args;\
    ret x264_pixel_ssd_4x4_sve args;

#define DECL_X1( name, suffix ) \
    DECL_PIXELS( int, name, suffix, ( pixel *, intptr_t, pixel *, intptr_t ) )
#define DECL_X1_SSD_SVE( ) \
    DECL_PIXELS_SSD_SVE( int, ( pixel *, intptr_t, pixel *, intptr_t ) )

#define DECL_X4( name, suffix ) \
    DECL_PIXELS( void, name##_x3, suffix, ( pixel *, pixel *, pixel *, pixel *, intptr_t, int * ) )\
    DECL_PIXELS( void, name##_x4, suffix, ( pixel *, pixel *, pixel *, pixel *, pixel *, intptr_t, int * ) )

DECL_X1( sad, neon )
DECL_X4( sad, neon )
DECL_X1( satd, neon )
DECL_X1( ssd, neon )
DECL_X1_SSD_SVE( )


#define x264_pixel_ssd_nv12_core_neon x264_template(pixel_ssd_nv12_core_neon)
void x264_pixel_ssd_nv12_core_neon( pixel *, intptr_t, pixel *, intptr_t, int, int, uint64_t *, uint64_t * );

#define x264_pixel_vsad_neon x264_template(pixel_vsad_neon)
int x264_pixel_vsad_neon( pixel *, intptr_t, int );

#define x264_pixel_sa8d_8x8_neon x264_template(pixel_sa8d_8x8_neon)
int x264_pixel_sa8d_8x8_neon  ( pixel *, intptr_t, pixel *, intptr_t );
#define x264_pixel_sa8d_16x16_neon x264_template(pixel_sa8d_16x16_neon)
int x264_pixel_sa8d_16x16_neon( pixel *, intptr_t, pixel *, intptr_t );
#define x264_pixel_sa8d_satd_16x16_neon x264_template(pixel_sa8d_satd_16x16_neon)
uint64_t x264_pixel_sa8d_satd_16x16_neon( pixel *, intptr_t, pixel *, intptr_t );
#define x264_pixel_sa8d_8x8_sve x264_template(pixel_sa8d_8x8_sve)
int x264_pixel_sa8d_8x8_sve  ( pixel *, intptr_t, pixel *, intptr_t );

#define x264_pixel_var_8x8_neon x264_template(pixel_var_8x8_neon)
uint64_t x264_pixel_var_8x8_neon  ( pixel *, intptr_t );
#define x264_pixel_var_8x16_neon x264_template(pixel_var_8x16_neon)
uint64_t x264_pixel_var_8x16_neon ( pixel *, intptr_t );
#define x264_pixel_var_16x16_neon x264_template(pixel_var_16x16_neon)
uint64_t x264_pixel_var_16x16_neon( pixel *, intptr_t );
#define x264_pixel_var2_8x8_neon x264_template(pixel_var2_8x8_neon)
int x264_pixel_var2_8x8_neon ( pixel *, pixel *, int * );
#define x264_pixel_var2_8x16_neon x264_template(pixel_var2_8x16_neon)
int x264_pixel_var2_8x16_neon( pixel *, pixel *, int * );
#define x264_pixel_var_8x8_sve x264_template(pixel_var_8x8_sve)
uint64_t x264_pixel_var_8x8_sve  ( pixel *, intptr_t );
#define x264_pixel_var_8x16_sve x264_template(pixel_var_8x16_sve)
uint64_t x264_pixel_var_8x16_sve ( pixel *, intptr_t );


#define x264_pixel_hadamard_ac_8x8_neon x264_template(pixel_hadamard_ac_8x8_neon)
uint64_t x264_pixel_hadamard_ac_8x8_neon  ( pixel *, intptr_t );
#define x264_pixel_hadamard_ac_8x16_neon x264_template(pixel_hadamard_ac_8x16_neon)
uint64_t x264_pixel_hadamard_ac_8x16_neon ( pixel *, intptr_t );
#define x264_pixel_hadamard_ac_16x8_neon x264_template(pixel_hadamard_ac_16x8_neon)
uint64_t x264_pixel_hadamard_ac_16x8_neon ( pixel *, intptr_t );
#define x264_pixel_hadamard_ac_16x16_neon x264_template(pixel_hadamard_ac_16x16_neon)
uint64_t x264_pixel_hadamard_ac_16x16_neon( pixel *, intptr_t );
#define x264_pixel_hadamard_ac_8x8_sve x264_template(pixel_hadamard_ac_8x8_sve)
uint64_t x264_pixel_hadamard_ac_8x8_sve  ( pixel *, intptr_t );
#define x264_pixel_hadamard_ac_8x16_sve x264_template(pixel_hadamard_ac_8x16_sve)
uint64_t x264_pixel_hadamard_ac_8x16_sve ( pixel *, intptr_t );
#define x264_pixel_hadamard_ac_16x8_sve x264_template(pixel_hadamard_ac_16x8_sve)
uint64_t x264_pixel_hadamard_ac_16x8_sve ( pixel *, intptr_t );
#define x264_pixel_hadamard_ac_16x16_sve x264_template(pixel_hadamard_ac_16x16_sve)
uint64_t x264_pixel_hadamard_ac_16x16_sve( pixel *, intptr_t );


#define x264_pixel_ssim_4x4x2_core_neon x264_template(pixel_ssim_4x4x2_core_neon)
void x264_pixel_ssim_4x4x2_core_neon( const pixel *, intptr_t,
                                      const pixel *, intptr_t,
                                      int sums[2][4] );
#define x264_pixel_ssim_end4_neon x264_template(pixel_ssim_end4_neon)
float x264_pixel_ssim_end4_neon( int sum0[5][4], int sum1[5][4], int width );

#define x264_pixel_asd8_neon x264_template(pixel_asd8_neon)
int x264_pixel_asd8_neon( pixel *, intptr_t,  pixel *, intptr_t, int );

#define x264_pixel_ads1_sve x264_template(pixel_ads1_sve)
int x264_pixel_ads1_sve( int[1], uint16_t *, int, uint16_t *, int16_t *, int, int );
#define x264_pixel_ads2_sve x264_template(pixel_ads2_sve)
int x264_pixel_ads2_sve( int[2], uint16_t *, int, uint16_t *, int16_t *, int, int );
#define x264_pixel_ads4_sve x264_template(pixel_ads4_sve)
int x264_pixel_ads4_sve( int[4], uint16_t *, int, uint16_t *, int16_t *, int, int );

#define x264_pixel_ads1_sve2 x264_template(pixel_ads1_sve2)
int x264_pixel_ads1_sve2( int[1], uint16_t *, int, uint16_t *, int16_t *, int, int );
#define x264_pixel_ads2_sve2 x264_template(pixel_ads2_sve2)
int x264_pixel_ads2_sve2( int[2], uint16_t *, int, uint16_t *, int16_t *, int, int );
#define x264_pixel_ads4_sve2 x264_template(pixel_ads4_sve2)
int x264_pixel_ads4_sve2( int[4], uint16_t *, int, uint16_t *, int16_t *, int, int );

#endif
