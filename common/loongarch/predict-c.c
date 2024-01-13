/*****************************************************************************
 * predict-c.c: loongarch intra prediction
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
#include "predict.h"

void x264_predict_16x16_init_loongarch( int cpu, x264_predict_t pf[7] )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_LSX )
    {
        pf[I_PRED_16x16_V ]     = x264_predict_16x16_v_lsx;
        pf[I_PRED_16x16_H ]     = x264_predict_16x16_h_lsx;
        pf[I_PRED_16x16_DC]     = x264_predict_16x16_dc_lsx;
        pf[I_PRED_16x16_DC_LEFT]= x264_predict_16x16_dc_left_lsx;
        pf[I_PRED_16x16_DC_TOP ]= x264_predict_16x16_dc_top_lsx;
        pf[I_PRED_16x16_DC_128 ]= x264_predict_16x16_dc_128_lsx;
        pf[I_PRED_16x16_P ]     = x264_predict_16x16_p_lsx;
    }
    if( cpu&X264_CPU_LASX )
    {
        pf[I_PRED_16x16_P ]     = x264_predict_16x16_p_lasx;
    }
#endif
}

void x264_predict_8x8c_init_loongarch( int cpu, x264_predict_t pf[7] )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_LSX )
    {
        pf[I_PRED_CHROMA_P]      = x264_predict_8x8c_p_lsx;
        pf[I_PRED_CHROMA_V]      = x264_predict_8x8c_v_lsx;
        pf[I_PRED_CHROMA_H]      = x264_predict_8x8c_h_lsx;
        pf[I_PRED_CHROMA_DC]     = x264_predict_8x8c_dc_lsx;
        pf[I_PRED_CHROMA_DC_128] = x264_predict_8x8c_dc_128_lsx;
        pf[I_PRED_CHROMA_DC_TOP] = x264_predict_8x8c_dc_top_lsx;
        pf[I_PRED_CHROMA_DC_LEFT]= x264_predict_8x8c_dc_left_lsx;
    }
#endif
}

void x264_predict_8x8_init_loongarch( int cpu, x264_predict8x8_t pf[12], x264_predict_8x8_filter_t *predict_filter )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_LSX )
    {
        pf[I_PRED_8x8_V]      = x264_predict_8x8_v_lsx;
        pf[I_PRED_8x8_DC]     = x264_predict_8x8_dc_lsx;
        pf[I_PRED_8x8_DC_LEFT]= x264_predict_8x8_dc_left_lsx;
        pf[I_PRED_8x8_DC_TOP] = x264_predict_8x8_dc_top_lsx;
        pf[I_PRED_8x8_DC_128] = x264_predict_8x8_dc_128_lsx;
        pf[I_PRED_8x8_H]      = x264_predict_8x8_h_lsx;
        pf[I_PRED_8x8_DDL]    = x264_predict_8x8_ddl_lsx;
        pf[I_PRED_8x8_DDR]    = x264_predict_8x8_ddr_lsx;
        pf[I_PRED_8x8_VR]     = x264_predict_8x8_vr_lsx;
        pf[I_PRED_8x8_VL]     = x264_predict_8x8_vl_lsx;
    }
    if( cpu&X264_CPU_LASX )
    {
        pf[I_PRED_8x8_H]      = x264_predict_8x8_h_lasx;
        pf[I_PRED_8x8_DDL]    = x264_predict_8x8_ddl_lasx;
        pf[I_PRED_8x8_DDR]    = x264_predict_8x8_ddr_lasx;
        pf[I_PRED_8x8_VR]     = x264_predict_8x8_vr_lasx;
        pf[I_PRED_8x8_VL]     = x264_predict_8x8_vl_lasx;
    }
#endif
}

void x264_predict_4x4_init_loongarch( int cpu, x264_predict_t pf[12] )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_LSX )
    {
        pf[I_PRED_4x4_V]      = x264_predict_4x4_v_lsx;
        pf[I_PRED_4x4_H]      = x264_predict_4x4_h_lsx;
        pf[I_PRED_4x4_DC]     = x264_predict_4x4_dc_lsx;
        pf[I_PRED_4x4_DDL]    = x264_predict_4x4_ddl_lsx;
        pf[I_PRED_4x4_DC_LEFT]= x264_predict_4x4_dc_left_lsx;
        pf[I_PRED_4x4_DC_TOP] = x264_predict_4x4_dc_top_lsx;
        pf[I_PRED_4x4_DC_128] = x264_predict_4x4_dc_128_lsx;
    }
#endif
}
