/*****************************************************************************
 * opencl.h: OpenCL structures and defines
 *****************************************************************************
 * Copyright (C) 2012-2013 x264 project
 *
 * Authors: Steve Borho <sborho@multicorewareinc.com>
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

#ifndef X264_OPENCL_H
#define X264_OPENCL_H

#include "x264.h"
#include "common/common.h"

#include <CL/cl.h>

/* Number of downscale resolutions to use for motion search */
#define NUM_IMAGE_SCALES 4

/* Number of PCIe copies that can be queued before requiring a flush */
#define MAX_FINISH_COPIES 1024

/* Size (in bytes) of the page-locked buffer used for PCIe xfers */
#define PAGE_LOCKED_BUF_SIZE 32 * 1024 * 1024

typedef struct
{
    cl_context       context;
    cl_device_id     device;
    cl_command_queue queue;

    cl_program  lookahead_program;
    cl_int      last_buf;

    cl_mem      page_locked_buffer;
    char       *page_locked_ptr;
    int         pl_occupancy;

    struct
    {
        void *src;
        void *dest;
        int   bytes;
    } copies[MAX_FINISH_COPIES];
    int         num_copies;

    int         b_device_AMD_SI;
    int         b_fatal_error;
    int         lookahead_thread_pri;
    int         opencl_thread_pri;

    /* downscale lowres luma */
    cl_kernel   downscale_hpel_kernel;
    cl_kernel   downscale_kernel1;
    cl_kernel   downscale_kernel2;
    cl_mem      luma_16x16_image[2];

    /* weightp filtering */
    cl_kernel   weightp_hpel_kernel;
    cl_kernel   weightp_scaled_images_kernel;
    cl_mem      weighted_scaled_images[NUM_IMAGE_SCALES];
    cl_mem      weighted_luma_hpel;

    /* intra */
    cl_kernel   memset_kernel;
    cl_kernel   intra_kernel;
    cl_kernel   rowsum_intra_kernel;
    cl_mem      row_satds[2];

    /* hierarchical motion estimation */
    cl_kernel   hme_kernel;
    cl_kernel   subpel_refine_kernel;
    cl_mem      mv_buffers[2];
    cl_mem      lowres_mv_costs;
    cl_mem      mvp_buffer;

    /* bidir */
    cl_kernel   mode_select_kernel;
    cl_kernel   rowsum_inter_kernel;
    cl_mem      lowres_costs[2];
    cl_mem      frame_stats[2]; /* cost_est, cost_est_aq, intra_mbs */
} x264_opencl_t;

typedef struct
{
    cl_mem scaled_image2Ds[NUM_IMAGE_SCALES];
    cl_mem luma_hpel;
    cl_mem inv_qscale_factor;
    cl_mem intra_cost;
    cl_mem lowres_mvs0;
    cl_mem lowres_mvs1;
    cl_mem lowres_mv_costs0;
    cl_mem lowres_mv_costs1;
} x264_frame_opencl_t;

typedef struct x264_frame x264_frame;

int x264_opencl_init( x264_t *h );
int x264_opencl_init_lookahead( x264_t *h );
void x264_opencl_free( x264_t *h );
void x264_opencl_frame_delete( x264_frame *frame );

#endif
