/*****************************************************************************
 * pixel-c-sve.c: aarch64 pixel kernels (SVE)
 *****************************************************************************
 * Copyright (C) 2017-2024 x264 project
 *
 * Authors: Matthias Langer <mlanger@nvidia.com>
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

#include "pixel.h"
#include <arm_sve.h>

/* === ADS ====================================================================================== */

int ALWAYS_INLINE x264_pixel_ads1_sve( int enc_dc[1], uint16_t *const sums, const int delta,
                                       uint16_t *const cost_mvx, int16_t *const mvs, const int width, const int thresh )
{
    const size_t sve_size = svcntw();

    const svint32_t edc0 = svdup_s32(enc_dc[0]);
    
    svint32_t i_sve = svindex_s32(0, 1);
    int nmv = 0;
    for( int i = 0; i < width; i += sve_size )
    {
        svbool_t pg = svwhilelt_b32(i, width);

        const svint32_t cmvx = svld1uh_s32(pg, &cost_mvx[i]);
        const svint32_t sums0 = svld1uh_s32(pg, &sums[i]);

        svint32_t ads = cmvx;
        ads = svaba_s32(ads, edc0, sums0);

        const svbool_t plt = svcmplt_n_s32(pg, ads, thresh);
        const int nlt = svcntp_b32(svptrue_b32(), plt);

        pg = svwhilelt_b32(0, nlt);
        svst1h_s32(pg, &mvs[nmv], svcompact_s32(plt, i_sve));
        nmv += nlt;

        i_sve = svadd_n_s32_m(svptrue_b32(), i_sve, sve_size);
    }
    return nmv;
}

int ALWAYS_INLINE x264_pixel_ads2_sve( int enc_dc[2], uint16_t *sums, const int delta,
                                       uint16_t *const cost_mvx, int16_t *const mvs, const int width, const int thresh )
{
    const size_t sve_size = svcntw();

    const svint32_t edc0 = svdup_s32(enc_dc[0]);
    const svint32_t edc1 = svdup_s32(enc_dc[1]);

    svint32_t i_sve = svindex_s32(0, 1);
    int nmv = 0;
    for( int i = 0; i < width; i += sve_size, sums += sve_size )
    {
        svbool_t pg = svwhilelt_b32(i, width);

        const svint32_t cmvx = svld1uh_s32(pg, &cost_mvx[i]);
        const svint32_t sums0 = svld1uh_s32(pg, &sums[0]);
        const svint32_t sums1 = svld1uh_s32(pg, &sums[delta]);

        svint32_t ads = cmvx;
        ads = svaba_s32(ads, edc0, sums0);
        ads = svaba_s32(ads, edc1, sums1);

        const svbool_t plt = svcmplt_n_s32(pg, ads, thresh);
        const int nlt = svcntp_b32(svptrue_b32(), plt);

        pg = svwhilelt_b32(0, nlt);
        svst1h_s32(pg, &mvs[nmv], svcompact_s32(plt, i_sve));
        nmv += nlt;

        i_sve = svadd_n_s32_m(svptrue_b32(), i_sve, sve_size)
    }
    return nmv;
}

int ALWAYS_INLINE x264_pixel_ads4_sve( int enc_dc[4], uint16_t *sums, int delta,
                                       uint16_t *cost_mvx, int16_t *mvs, int width, int thresh )
{
    const size_t sve_size = svcntw();

    const svint32_t edc0 = svdup_s32(enc_dc[0]);
    const svint32_t edc1 = svdup_s32(enc_dc[1]);
    const svint32_t edc2 = svdup_s32(enc_dc[2]);
    const svint32_t edc3 = svdup_s32(enc_dc[3]);

    svint32_t i_sve = svindex_s32(0, 1);
    int nmv = 0;
    for( int i = 0; i < width; i += sve_size, sums += sve_size )
    {
        svbool_t pg = svwhilelt_b32(i, width);

        const svint32_t cmvx = svld1uh_s32(pg, &cost_mvx[i]);
        const svint32_t sums0 = svld1uh_s32(pg, &sums[0]);
        const svint32_t sums1 = svld1uh_s32(pg, &sums[8]);
        const svint32_t sums2 = svld1uh_s32(pg, &sums[delta]);
        const svint32_t sums3 = svld1uh_s32(pg, &sums[delta+8]);

        svint32_t ads = cmvx;
        ads = svaba_s32(ads, sums0, edc0);
        ads = svaba_s32(ads, sums1, edc1);
        ads = svaba_s32(ads, sums2, edc2);
        ads = svaba_s32(ads, sums3, edc3);

        const svbool_t plt = svcmplt_n_s32(pg, ads, thresh);
        const int nlt = svcntp_b32(svptrue_b32(), plt);

        pg = svwhilelt_b32(0, nlt);
        svst1h_s32(pg, &mvs[nmv], svcompact_s32(plt, i_sve));
        nmv += nlt;

        i_sve = svadd_n_s32_m(svptrue_b32(), i_sve, sve_size)
    }
    return nmv;
}