/*****************************************************************************
 * mc-c.c: loongarch motion compensation
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

#include "common/common.h"
#include "mc.h"

#if !HIGH_BIT_DEPTH

#define MC_WEIGHT_LSX(func)                                                                                        \
static void (* mc##func##_wtab_lsx[6])( uint8_t *, intptr_t, uint8_t *, intptr_t, const x264_weight_t *, int ) =   \
{                                                                                                                  \
    x264_mc_weight_w4##func##_lsx,                                                                                 \
    x264_mc_weight_w4##func##_lsx,                                                                                 \
    x264_mc_weight_w8##func##_lsx,                                                                                 \
    x264_mc_weight_w16##func##_lsx,                                                                                \
    x264_mc_weight_w16##func##_lsx,                                                                                \
    x264_mc_weight_w20##func##_lsx,                                                                                \
};

#define MC_WEIGHT(func)                                                                                             \
static void (* mc##func##_wtab_lasx[6])( uint8_t *, intptr_t, uint8_t *, intptr_t, const x264_weight_t *, int ) =   \
{                                                                                                                   \
    x264_mc_weight_w4##func##_lasx,                                                                                 \
    x264_mc_weight_w4##func##_lasx,                                                                                 \
    x264_mc_weight_w8##func##_lasx,                                                                                 \
    x264_mc_weight_w16##func##_lasx,                                                                                \
    x264_mc_weight_w16##func##_lasx,                                                                                \
    x264_mc_weight_w20##func##_lasx,                                                                                \
};

#if !HIGH_BIT_DEPTH
MC_WEIGHT_LSX()
MC_WEIGHT_LSX(_noden)
MC_WEIGHT()
MC_WEIGHT(_noden)
#endif

static void weight_cache_lsx( x264_t *h, x264_weight_t *w )
{
    if ( w->i_denom >= 1)
    {
        w->weightfn = mc_wtab_lsx;
    }
    else
        w->weightfn = mc_noden_wtab_lsx;
}

static weight_fn_t mc_weight_wtab_lsx[6] =
{
    x264_mc_weight_w4_lsx,
    x264_mc_weight_w4_lsx,
    x264_mc_weight_w8_lsx,
    x264_mc_weight_w16_lsx,
    x264_mc_weight_w16_lsx,
    x264_mc_weight_w20_lsx,
};

static void (* const pixel_avg_wtab_lsx[6])(uint8_t *, intptr_t, uint8_t *, intptr_t, uint8_t *, int ) =
{
    NULL,
    x264_pixel_avg2_w4_lsx,
    x264_pixel_avg2_w8_lsx,
    x264_pixel_avg2_w16_lsx,
    x264_pixel_avg2_w16_lsx,
    x264_pixel_avg2_w20_lsx,
};

static void (* const mc_copy_wtab_lsx[5])( uint8_t *, intptr_t, uint8_t *, intptr_t, int ) =
{
    NULL,
    x264_mc_copy_w4_lsx,
    x264_mc_copy_w8_lsx,
    NULL,
    x264_mc_copy_w16_lsx,
};

static void weight_cache_lasx( x264_t *h, x264_weight_t *w )
{
    if ( w->i_denom >= 1)
    {
        w->weightfn = mc_wtab_lasx;
    }
    else
        w->weightfn = mc_noden_wtab_lasx;
}

static weight_fn_t mc_weight_wtab_lasx[6] =
{
    x264_mc_weight_w4_lasx,
    x264_mc_weight_w4_lasx,
    x264_mc_weight_w8_lasx,
    x264_mc_weight_w16_lasx,
    x264_mc_weight_w16_lasx,
    x264_mc_weight_w20_lasx,
};

static void (* const pixel_avg_wtab_lasx[6])(uint8_t *, intptr_t, uint8_t *,
                                             intptr_t, uint8_t *, int ) =
{
    NULL,
    x264_pixel_avg2_w4_lasx,
    x264_pixel_avg2_w8_lasx,
    x264_pixel_avg2_w16_lasx,
    x264_pixel_avg2_w16_lasx,
    x264_pixel_avg2_w20_lasx,
};

static void (* const mc_copy_wtab_lasx[5])( uint8_t *, intptr_t, uint8_t *,
                                            intptr_t, int ) =
{
    NULL,
    x264_mc_copy_w4_lasx,
    x264_mc_copy_w8_lasx,
    NULL,
    x264_mc_copy_w16_lasx,
};

static uint8_t *get_ref_lsx( uint8_t *p_dst, intptr_t *p_dst_stride,
                             uint8_t *p_src[4], intptr_t i_src_stride,
                             int32_t m_vx, int32_t m_vy,
                             int32_t i_width, int32_t i_height,
                             const x264_weight_t *pWeight )
{
    int32_t i_qpel_idx;
    int32_t i_offset;
    uint8_t *p_src1;
    int32_t r_vy = m_vy & 3;
    int32_t r_vx = m_vx & 3;
    int32_t width = i_width >> 2;

    i_qpel_idx = ( r_vy << 2 ) + r_vx;
    i_offset = ( m_vy >> 2 ) * i_src_stride + ( m_vx >> 2 );
    p_src1 = p_src[x264_hpel_ref0[i_qpel_idx]] + i_offset +
           ( 3 == r_vy ) * i_src_stride;

    if( i_qpel_idx & 5 )
    {
        uint8_t *p_src2 = p_src[x264_hpel_ref1[i_qpel_idx]] +
                          i_offset + ( 3 == r_vx );
        pixel_avg_wtab_lsx[width](
                p_dst, *p_dst_stride, p_src1, i_src_stride,
                p_src2, i_height );

        if( pWeight->weightfn )
        {
            pWeight->weightfn[width](p_dst, *p_dst_stride, p_dst, *p_dst_stride, pWeight, i_height);
        }
        return p_dst;
    }
    else if ( pWeight->weightfn )
    {
        pWeight->weightfn[width]( p_dst, *p_dst_stride, p_src1, i_src_stride, pWeight, i_height );
        return p_dst;
    }
    else
    {
        *p_dst_stride = i_src_stride;
        return p_src1;
    }
}

static void mc_luma_lsx( uint8_t *p_dst, intptr_t i_dst_stride,
                         uint8_t *p_src[4], intptr_t i_src_stride,
                         int32_t m_vx, int32_t m_vy,
                         int32_t i_width, int32_t i_height,
                         const x264_weight_t *pWeight )
{
    int32_t  i_qpel_idx;
    int32_t  i_offset;
    uint8_t  *p_src1;

    i_qpel_idx = ( ( m_vy & 3 ) << 2 ) + ( m_vx & 3 );
    i_offset = ( m_vy >> 2 ) * i_src_stride + ( m_vx >> 2 );
    p_src1 = p_src[x264_hpel_ref0[i_qpel_idx]] + i_offset +
             ( 3 == ( m_vy & 3 ) ) * i_src_stride;

    if( i_qpel_idx & 5 )
    {
        uint8_t *p_src2 = p_src[x264_hpel_ref1[i_qpel_idx]] +
                          i_offset + ( 3 == ( m_vx & 3 ) );

        pixel_avg_wtab_lsx[i_width >> 2](
                p_dst, i_dst_stride, p_src1, i_src_stride,
                p_src2, i_height );

        if( pWeight->weightfn )
        {
            pWeight->weightfn[i_width>>2]( p_dst, i_dst_stride, p_dst, i_dst_stride, pWeight, i_height );
        }
    }
    else if( pWeight->weightfn )
    {
        pWeight->weightfn[i_width>>2]( p_dst, i_dst_stride, p_src1, i_src_stride, pWeight, i_height );
    }
    else
    {
        mc_copy_wtab_lsx[i_width>>2]( p_dst, i_dst_stride, p_src1, i_src_stride, i_height );
    }
}

PLANE_INTERLEAVE(lsx)
PLANE_COPY_YUYV(32, lsx)

#define x264_mc_chroma_lsx x264_template(mc_chroma_lsx)
void x264_mc_chroma_lsx( uint8_t *p_dst_u, uint8_t *p_dst_v,
                         intptr_t i_dst_stride,
                         uint8_t *p_src, intptr_t i_src_stride,
                         int32_t m_vx, int32_t m_vy,
                         int32_t i_width, int32_t i_height );

static uint8_t *get_ref_lasx( uint8_t *p_dst, intptr_t *p_dst_stride,
                              uint8_t *p_src[4], intptr_t i_src_stride,
                              int32_t m_vx, int32_t m_vy,
                              int32_t i_width, int32_t i_height,
                              const x264_weight_t *pWeight )
{
    int32_t i_qpel_idx;
    int32_t i_offset;
    uint8_t *p_src1;
    int32_t r_vy = m_vy & 3;
    int32_t r_vx = m_vx & 3;
    int32_t width = i_width >> 2;

    i_qpel_idx = ( r_vy << 2 ) + r_vx;
    i_offset = ( m_vy >> 2 ) * i_src_stride + ( m_vx >> 2 );
    p_src1 = p_src[x264_hpel_ref0[i_qpel_idx]] + i_offset +
           ( 3 == r_vy ) * i_src_stride;

    if( i_qpel_idx & 5 )
    {
        uint8_t *p_src2 = p_src[x264_hpel_ref1[i_qpel_idx]] +
                          i_offset + ( 3 == r_vx );
        pixel_avg_wtab_lasx[width](
                p_dst, *p_dst_stride, p_src1, i_src_stride,
                p_src2, i_height );

        if( pWeight->weightfn )
        {
            pWeight->weightfn[width](p_dst, *p_dst_stride, p_dst, *p_dst_stride, pWeight, i_height);
        }
        return p_dst;
    }
    else if ( pWeight->weightfn )
    {
        pWeight->weightfn[width]( p_dst, *p_dst_stride, p_src1, i_src_stride, pWeight, i_height );
        return p_dst;
    }
    else
    {
        *p_dst_stride = i_src_stride;
        return p_src1;
    }
}

static void mc_luma_lasx( uint8_t *p_dst, intptr_t i_dst_stride,
                          uint8_t *p_src[4], intptr_t i_src_stride,
                          int32_t m_vx, int32_t m_vy,
                          int32_t i_width, int32_t i_height,
                          const x264_weight_t *pWeight )
{
    int32_t  i_qpel_idx;
    int32_t  i_offset;
    uint8_t  *p_src1;

    i_qpel_idx = ( ( m_vy & 3 ) << 2 ) + ( m_vx & 3 );
    i_offset = ( m_vy >> 2 ) * i_src_stride + ( m_vx >> 2 );
    p_src1 = p_src[x264_hpel_ref0[i_qpel_idx]] + i_offset +
             ( 3 == ( m_vy & 3 ) ) * i_src_stride;

    if( i_qpel_idx & 5 )
    {
        uint8_t *p_src2 = p_src[x264_hpel_ref1[i_qpel_idx]] +
                          i_offset + ( 3 == ( m_vx & 3 ) );

        pixel_avg_wtab_lasx[i_width >> 2](
                p_dst, i_dst_stride, p_src1, i_src_stride,
                p_src2, i_height );

        if( pWeight->weightfn )
        {
            pWeight->weightfn[i_width>>2]( p_dst, i_dst_stride, p_dst, i_dst_stride, pWeight, i_height );
        }
    }
    else if( pWeight->weightfn )
    {
        pWeight->weightfn[i_width>>2]( p_dst, i_dst_stride, p_src1, i_src_stride, pWeight, i_height );
    }
    else
    {
        mc_copy_wtab_lasx[i_width>>2]( p_dst, i_dst_stride, p_src1, i_src_stride, i_height );
    }
}

PLANE_COPY_YUYV(64, lasx)

#define x264_mc_chroma_lasx x264_template(mc_chroma_lasx)
void x264_mc_chroma_lasx( uint8_t *p_dst_u, uint8_t *p_dst_v,
                          intptr_t i_dst_stride,
                          uint8_t *p_src, intptr_t i_src_stride,
                          int32_t m_vx, int32_t m_vy,
                          int32_t i_width, int32_t i_height );
#endif // !HIGH_BIT_DEPTH

void x264_mc_init_loongarch( int32_t cpu, x264_mc_functions_t *pf  )
{
#if !HIGH_BIT_DEPTH
    if( cpu & X264_CPU_LSX )
    {
        pf->mc_luma = mc_luma_lsx;
        pf->mc_chroma = x264_mc_chroma_lsx;
        pf->get_ref = get_ref_lsx;

        pf->avg[PIXEL_16x16]= x264_pixel_avg_16x16_lsx;
        pf->avg[PIXEL_16x8] = x264_pixel_avg_16x8_lsx;
        pf->avg[PIXEL_8x16] = x264_pixel_avg_8x16_lsx;
        pf->avg[PIXEL_8x8] = x264_pixel_avg_8x8_lsx;
        pf->avg[PIXEL_8x4] = x264_pixel_avg_8x4_lsx;
        pf->avg[PIXEL_4x16] = x264_pixel_avg_4x16_lsx;
        pf->avg[PIXEL_4x8] = x264_pixel_avg_4x8_lsx;
        pf->avg[PIXEL_4x4] = x264_pixel_avg_4x4_lsx;
        pf->avg[PIXEL_4x2] = x264_pixel_avg_4x2_lsx;

        pf->weight = mc_weight_wtab_lsx;
        pf->offsetadd = mc_weight_wtab_lsx;
        pf->offsetsub = mc_weight_wtab_lsx;
        pf->weight_cache = weight_cache_lsx;

        pf->copy_16x16_unaligned = x264_mc_copy_w16_lsx;
        pf->copy[PIXEL_16x16] = x264_mc_copy_w16_lsx;
        pf->copy[PIXEL_8x8] = x264_mc_copy_w8_lsx;
        pf->copy[PIXEL_4x4] = x264_mc_copy_w4_lsx;

        pf->store_interleave_chroma = x264_store_interleave_chroma_lsx;
        pf->load_deinterleave_chroma_fenc = x264_load_deinterleave_chroma_fenc_lsx;
        pf->load_deinterleave_chroma_fdec = x264_load_deinterleave_chroma_fdec_lsx;

        pf->plane_copy_interleave = plane_copy_interleave_lsx;
        pf->plane_copy_deinterleave = x264_plane_copy_deinterleave_lsx;
        pf->plane_copy_deinterleave_yuyv = plane_copy_deinterleave_yuyv_lsx;

        pf->hpel_filter = x264_hpel_filter_lsx;
        pf->memcpy_aligned = x264_memcpy_aligned_lsx;
        pf->memzero_aligned = x264_memzero_aligned_lsx;
        pf->frame_init_lowres_core = x264_frame_init_lowres_core_lsx;

        pf->prefetch_fenc_420 = x264_prefetch_fenc_420_lsx;
        pf->prefetch_fenc_422 = x264_prefetch_fenc_422_lsx;
        pf->prefetch_ref  = x264_prefetch_ref_lsx;
    }

    if( cpu & X264_CPU_LASX )
    {
        pf->mc_luma = mc_luma_lasx;
        pf->mc_chroma = x264_mc_chroma_lasx;
        pf->get_ref = get_ref_lasx;

        pf->avg[PIXEL_16x8] = x264_pixel_avg_16x8_lasx;
        pf->avg[PIXEL_8x16] = x264_pixel_avg_8x16_lasx;
        pf->avg[PIXEL_8x8] = x264_pixel_avg_8x8_lasx;
        pf->avg[PIXEL_8x4] = x264_pixel_avg_8x4_lasx;
        pf->avg[PIXEL_4x16] = x264_pixel_avg_4x16_lasx;
        pf->avg[PIXEL_4x8] = x264_pixel_avg_4x8_lasx;
        pf->avg[PIXEL_4x4] = x264_pixel_avg_4x4_lasx;
        pf->avg[PIXEL_4x2] = x264_pixel_avg_4x2_lasx;

        pf->weight = mc_weight_wtab_lasx;
        pf->offsetadd = mc_weight_wtab_lasx;
        pf->offsetsub = mc_weight_wtab_lasx;
        pf->weight_cache = weight_cache_lasx;

        pf->plane_copy_deinterleave = x264_plane_copy_deinterleave_lasx;
        pf->plane_copy_deinterleave_yuyv = plane_copy_deinterleave_yuyv_lasx;

        pf->copy_16x16_unaligned = x264_mc_copy_w16_lasx;
        pf->copy[PIXEL_16x16] = x264_mc_copy_w16_lasx;
        pf->copy[PIXEL_8x8] = x264_mc_copy_w8_lasx;
        pf->copy[PIXEL_4x4] = x264_mc_copy_w4_lasx;

        pf->hpel_filter = x264_hpel_filter_lasx;
        pf->memzero_aligned = x264_memzero_aligned_lasx;
        pf->frame_init_lowres_core = x264_frame_init_lowres_core_lasx;
    }
#endif // !HIGH_BIT_DEPTH
}
