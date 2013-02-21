/*****************************************************************************
 * opencl.c: OpenCL initialization and kernel compilation
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

#include "common.h"
#if _WIN32
#include <windows.h>
#else
#include <dlfcn.h> //dlopen, dlsym, dlclose
#endif

/* define from recent cl_ext.h, copied here in case headers are old */
#define CL_DEVICE_SIMD_INSTRUCTION_WIDTH_AMD        0x4042

/* Requires full include path in case of out-of-tree builds */
#include "common/oclobj.h"

static int x264_detect_switchable_graphics();

/* Try to load the cached compiled program binary, verify the device context is
 * still valid before reuse */
static cl_program x264_opencl_cache_load( x264_t *h, char *devname, char *devvendor, char *driverversion )
{
    cl_program program = NULL;
    cl_int status;

    /* try to load cached program binary */
    FILE *fp = fopen( h->param.psz_clbin_file, "rb" );
    if( !fp )
        return NULL;

    fseek( fp, 0L, SEEK_END );
    size_t size = ftell( fp );
    rewind( fp );
    uint8_t *binary;
    CHECKED_MALLOC( binary, size );

    fread( binary, 1, size, fp );
    const uint8_t *ptr = (const uint8_t*)binary;

#define CHECK_STRING( STR )\
    do {\
        size_t len = strlen( STR );\
        if( size <= len || strncmp( (char*)ptr, STR, len ) )\
            goto fail;\
        else {\
            size -= (len+1); ptr += (len+1);\
        }\
    } while( 0 )

    CHECK_STRING( devname );
    CHECK_STRING( devvendor );
    CHECK_STRING( driverversion );
    CHECK_STRING( x264_opencl_source_hash );
#undef CHECK_STRING

    program = clCreateProgramWithBinary( h->opencl.context, 1, &h->opencl.device, &size, &ptr, NULL, &status );
    if( status != CL_SUCCESS )
        program = NULL;

fail:
    fclose( fp );
    x264_free( binary );
    return program;
}

/* Save the compiled program binary to a file for later reuse.  Device context
 * is also saved in the cache file so we do not reuse stale binaries */
static void x264_opencl_cache_save( x264_t *h, cl_program program, char *devname, char *devvendor, char *driverversion )
{
    FILE *fp = fopen( h->param.psz_clbin_file, "wb" );
    if( !fp )
    {
        x264_log( h, X264_LOG_INFO, "OpenCL: unable to open clbin file for write");
        return;
    }

    size_t size;
    cl_int status = clGetProgramInfo( program, CL_PROGRAM_BINARY_SIZES, sizeof(size_t), &size, NULL );
    if( status == CL_SUCCESS )
    {
        uint8_t *binary;
        CHECKED_MALLOC( binary, size );
        status = clGetProgramInfo( program, CL_PROGRAM_BINARIES, sizeof(uint8_t *), &binary, NULL );
        if( status == CL_SUCCESS )
        {
            fputs( devname, fp );
            fputc( '\n', fp );
            fputs( devvendor, fp );
            fputc( '\n', fp );
            fputs( driverversion, fp );
            fputc( '\n', fp );
            fputs( x264_opencl_source_hash, fp );
            fputc( '\n', fp );
            fwrite( binary, 1, size, fp );
        }
        else
            x264_log( h, X264_LOG_INFO, "OpenCL: Unable to query program binary, no cache file generated");
        x264_free( binary );
    }
    else
        x264_log( h, X264_LOG_INFO, "OpenCL: Unable to query program binary size, no cache file generated");
    fclose( fp );

fail:
    return;
}

/* The OpenCL source under common/opencl will be merged into common/oclobj.h by
 * the Makefile. It defines a x264_opencl_source byte array which we will pass
 * to clCreateProgramWithSource().  We also attempt to use a cache file for the
 * compiled binary, stored in the current working folder. */
static cl_program x264_opencl_compile( x264_t *h )
{
    cl_program program;
    cl_int status;

    char devname[64];
    char devvendor[64];
    char driverversion[64];
    status  = clGetDeviceInfo( h->opencl.device, CL_DEVICE_NAME,    sizeof(devname), devname, NULL );
    status |= clGetDeviceInfo( h->opencl.device, CL_DEVICE_VENDOR,  sizeof(devvendor), devvendor, NULL );
    status |= clGetDeviceInfo( h->opencl.device, CL_DRIVER_VERSION, sizeof(driverversion), driverversion, NULL );
    if( status != CL_SUCCESS )
        return NULL;

    // Most AMD GPUs have vector registers
    int vectorize = !strcmp( devvendor, "Advanced Micro Devices, Inc." );
    h->opencl.b_device_AMD_SI = 0;

    if( vectorize )
    {
        /* Disable OpenCL on Intel/AMD switchable graphics devices */
        if( x264_detect_switchable_graphics() )
        {
            x264_log( h, X264_LOG_INFO, "OpenCL acceleration disabled, switchable graphics detected\n" );
            return NULL;
        }

        /* Detect AMD SouthernIsland or newer device (single-width registers) */
        cl_uint simdwidth = 4;
        status = clGetDeviceInfo( h->opencl.device, CL_DEVICE_SIMD_INSTRUCTION_WIDTH_AMD, sizeof(cl_uint), &simdwidth, NULL );
        if( status == CL_SUCCESS && simdwidth == 1 )
        {
            vectorize = 0;
            h->opencl.b_device_AMD_SI = 1;
        }
    }

    x264_log( h, X264_LOG_INFO, "OpenCL acceleration enabled with %s %s %s\n", devvendor, devname, h->opencl.b_device_AMD_SI ? "(SI)" : "" );

    program = x264_opencl_cache_load( h, devname, devvendor, driverversion );
    if( !program )
    {
        /* clCreateProgramWithSource() requires a pointer variable, you cannot just use &x264_opencl_source */
        x264_log( h, X264_LOG_INFO, "Compiling OpenCL kernels...\n" );
        const char *strptr = (const char*)x264_opencl_source;
        size_t size = sizeof(x264_opencl_source);
        program = clCreateProgramWithSource( h->opencl.context, 1, &strptr, &size, &status );
        if( status != CL_SUCCESS || !program )
        {
            x264_log( h, X264_LOG_WARNING, "OpenCL: unable to create program\n" );
            return NULL;
        }
    }

    /* Build the program binary for the OpenCL device */
    const char *buildopts = vectorize ? "-DVECTORIZE=1" : "";
    status = clBuildProgram( program, 1, &h->opencl.device, buildopts, NULL, NULL );
    if( status == CL_SUCCESS )
    {
        x264_opencl_cache_save( h, program, devname, devvendor, driverversion );
        return program;
    }

    /* Compile failure, should not happen with production code. */

    size_t build_log_len = 0;

    status = clGetProgramBuildInfo( program, h->opencl.device, CL_PROGRAM_BUILD_LOG, build_log_len, NULL, &build_log_len );
    if( status != CL_SUCCESS )
    {
        x264_log( h, X264_LOG_WARNING, "OpenCL: Compilation failed, unable to query build log\n" );
        return NULL;
    }

    char *build_log;
    CHECKED_MALLOC( build_log, build_log_len );
    if( !build_log )
    {
        x264_log( h, X264_LOG_WARNING, "OpenCL: Compilation failed, unable to alloc build log\n" );
        return NULL;
    }

    status = clGetProgramBuildInfo( program, h->opencl.device, CL_PROGRAM_BUILD_LOG, build_log_len, build_log, NULL );
    if( status != CL_SUCCESS )
    {
        x264_log( h, X264_LOG_WARNING, "OpenCL: Compilation failed, unable to get build log\n" );
        x264_free( build_log );
        return NULL;
    }

    FILE *lg = fopen( "x264_kernel_build_log.txt", "w" );
    if( lg )
    {
        fwrite( build_log, 1, build_log_len, lg );
        fclose( lg );
        x264_log( h, X264_LOG_WARNING, "OpenCL: kernel build errors written to x264_kernel_build_log.txt\n" );
    }

    x264_free( build_log );
fail:
    return NULL;
}

static void x264_opencl_free_lookahead( x264_t *h )
{
#define RELEASE( a, f ) if( a ) f( a );
    RELEASE( h->opencl.intra_kernel, clReleaseKernel )
    RELEASE( h->opencl.rowsum_intra_kernel, clReleaseKernel )
    RELEASE( h->opencl.downscale_kernel1, clReleaseKernel )
    RELEASE( h->opencl.downscale_kernel2, clReleaseKernel )
    RELEASE( h->opencl.downscale_hpel_kernel, clReleaseKernel )
    RELEASE( h->opencl.weightp_hpel_kernel, clReleaseKernel )
    RELEASE( h->opencl.weightp_scaled_images_kernel, clReleaseKernel )
    RELEASE( h->opencl.memset_kernel, clReleaseKernel )
    RELEASE( h->opencl.hme_kernel, clReleaseKernel )
    RELEASE( h->opencl.subpel_refine_kernel, clReleaseKernel )
    RELEASE( h->opencl.mode_select_kernel, clReleaseKernel )
    RELEASE( h->opencl.rowsum_inter_kernel, clReleaseKernel )
    RELEASE( h->opencl.lookahead_program, clReleaseProgram )
    RELEASE( h->opencl.row_satds[0], clReleaseMemObject )
    RELEASE( h->opencl.row_satds[1], clReleaseMemObject )
    RELEASE( h->opencl.frame_stats[0], clReleaseMemObject )
    RELEASE( h->opencl.frame_stats[1], clReleaseMemObject )
    RELEASE( h->opencl.mv_buffers[0], clReleaseMemObject )
    RELEASE( h->opencl.mv_buffers[1], clReleaseMemObject )
    RELEASE( h->opencl.mvp_buffer, clReleaseMemObject )
    RELEASE( h->opencl.luma_16x16_image[0], clReleaseMemObject )
    RELEASE( h->opencl.luma_16x16_image[1], clReleaseMemObject )
    RELEASE( h->opencl.lowres_mv_costs, clReleaseMemObject )
    RELEASE( h->opencl.lowres_costs[0], clReleaseMemObject )
    RELEASE( h->opencl.lowres_costs[1], clReleaseMemObject )
    RELEASE( h->opencl.page_locked_buffer, clReleaseMemObject )
    RELEASE( h->opencl.weighted_luma_hpel, clReleaseMemObject )
    for( int i = 0; i < NUM_IMAGE_SCALES; i++ )
        RELEASE( h->opencl.weighted_scaled_images[i], clReleaseMemObject )
#undef RELEASE
}

int x264_opencl_init_lookahead( x264_t *h )
{
    if( !h->param.rc.i_lookahead )
        return -1;

    static const char const *kernelnames[] = {
        "mb_intra_cost_satd_8x8",
        "sum_intra_cost",
        "downscale_hpel",
        "downscale1",
        "downscale2",
        "memset_int16",
        "weightp_scaled_images",
        "weightp_hpel",
        "hierarchical_motion",
        "subpel_refine",
        "mode_selection",
        "sum_inter_cost"
    };
    cl_kernel *kernels[] = {
        &h->opencl.intra_kernel,
        &h->opencl.rowsum_intra_kernel,
        &h->opencl.downscale_hpel_kernel,
        &h->opencl.downscale_kernel1,
        &h->opencl.downscale_kernel2,
        &h->opencl.memset_kernel,
        &h->opencl.weightp_scaled_images_kernel,
        &h->opencl.weightp_hpel_kernel,
        &h->opencl.hme_kernel,
        &h->opencl.subpel_refine_kernel,
        &h->opencl.mode_select_kernel,
        &h->opencl.rowsum_inter_kernel
    };
    cl_int status;

    h->opencl.lookahead_program = x264_opencl_compile( h );
    if( !h->opencl.lookahead_program )
    {
        x264_opencl_free_lookahead( h );
        return -1;
    }

    for( int i = 0; i < ARRAY_SIZE(kernelnames); i++ )
    {
        *kernels[i] = clCreateKernel( h->opencl.lookahead_program, kernelnames[i], &status );
        if( status != CL_SUCCESS )
        {
            x264_log( h, X264_LOG_WARNING, "OpenCL: Unable to compile kernel '%s' (%d)\n", kernelnames[i], status );
            x264_opencl_free_lookahead( h );
            return -1;
        }
    }

    h->opencl.page_locked_buffer = clCreateBuffer( h->opencl.context, CL_MEM_WRITE_ONLY|CL_MEM_ALLOC_HOST_PTR, PAGE_LOCKED_BUF_SIZE, NULL, &status );
    if( status != CL_SUCCESS )
    {
        x264_log( h, X264_LOG_WARNING, "OpenCL: Unable to allocate page-locked buffer, error '%d'\n", status );
        x264_opencl_free_lookahead( h );
        return -1;
    }
    h->opencl.page_locked_ptr = clEnqueueMapBuffer( h->opencl.queue, h->opencl.page_locked_buffer, CL_TRUE, CL_MAP_READ | CL_MAP_WRITE,
                                                    0, PAGE_LOCKED_BUF_SIZE, 0, NULL, NULL, &status );
    if( status != CL_SUCCESS )
    {
        x264_log( h, X264_LOG_WARNING, "OpenCL: Unable to map page-locked buffer, error '%d'\n", status );
        x264_opencl_free_lookahead( h );
        return -1;
    }

    return 0;
}

static void x264_opencl_error_notify( const char *errinfo, const void *private_info, size_t cb, void *user_data )
{
    /* Any error notification can be assumed to be fatal to the OpenCL context.
     * We need to stop using it immediately to prevent further damage. */
    x264_t *h = (x264_t*)user_data;
    h->param.b_opencl = 0;
    h->opencl.b_fatal_error = 1;
    x264_log( h, X264_LOG_ERROR, "OpenCL: %s\n", errinfo );
    x264_log( h, X264_LOG_ERROR, "OpenCL: fatal error, aborting encode\n" );
}

int x264_opencl_init( x264_t *h )
{
    cl_int status;
    cl_uint numPlatforms;
    int ret = -1;

    status = clGetPlatformIDs( 0, NULL, &numPlatforms );
    if( status != CL_SUCCESS || numPlatforms == 0 )
    {
        x264_log( h, X264_LOG_WARNING, "OpenCL: Unable to query installed platforms\n");
        return -1;
    }

    cl_platform_id *platforms = (cl_platform_id*)x264_malloc( numPlatforms * sizeof(cl_platform_id) );
    status = clGetPlatformIDs( numPlatforms, platforms, NULL );
    if( status != CL_SUCCESS )
    {
        x264_log( h, X264_LOG_WARNING, "OpenCL: Unable to query installed platforms\n");
        x264_free( platforms );
        return -1;
    }

    /* Select the first OpenCL platform with a GPU device that supports our
     * required image (texture) formats */
    for( cl_uint i = 0; i < numPlatforms; ++i )
    {
        cl_uint gpu_count = 0;
        status = clGetDeviceIDs( platforms[i], CL_DEVICE_TYPE_GPU, 0, NULL, &gpu_count );
        if( status != CL_SUCCESS || !gpu_count )
            continue;

        cl_device_id *devices = x264_malloc( sizeof(cl_device_id) * gpu_count );
        if( !devices )
            continue;

        status = clGetDeviceIDs( platforms[i], CL_DEVICE_TYPE_GPU, gpu_count, devices, NULL );
        if( status != CL_SUCCESS )
        {
            x264_free( devices );
            continue;
        }

        /* Find a GPU device that supports our image formats */
        for( cl_uint gpu = 0; gpu < gpu_count; gpu++ )
        {
            h->opencl.device = devices[gpu];

            /* if the user has specified an exact device ID, skip all other
             * GPUs.  If this device matches, allow it to continue through the
             * checks for supported images, etc.  */
            if( h->param.opencl_device_id && devices[gpu] != (cl_device_id) h->param.opencl_device_id )
                continue;

            cl_bool image_support;
            clGetDeviceInfo( h->opencl.device, CL_DEVICE_IMAGE_SUPPORT, sizeof(cl_bool), &image_support, NULL );
            if( !image_support )
                continue;

            cl_context context = clCreateContext( NULL, 1, &h->opencl.device, (void*)x264_opencl_error_notify, (void*)h, &status );
            if( status != CL_SUCCESS )
                continue;

            cl_uint imagecount = 0;
            clGetSupportedImageFormats( context, CL_MEM_READ_WRITE, CL_MEM_OBJECT_IMAGE2D, 0, NULL, &imagecount );
            if( !imagecount )
            {
                clReleaseContext( context );
                continue;
            }

            cl_image_format *imageType = x264_malloc( sizeof(cl_image_format) * imagecount );
            if( !imageType )
            {
                clReleaseContext( context );
                continue;
            }

            clGetSupportedImageFormats( context, CL_MEM_READ_WRITE, CL_MEM_OBJECT_IMAGE2D, imagecount, imageType, NULL );

            int b_has_r = 0;
            int b_has_rgba = 0;
            for( cl_uint j = 0; j < imagecount; j++ )
            {
                if( imageType[j].image_channel_order == CL_R &&
                    imageType[j].image_channel_data_type == CL_UNSIGNED_INT32 )
                    b_has_r = 1;
                else if( imageType[j].image_channel_order == CL_RGBA &&
                         imageType[j].image_channel_data_type == CL_UNSIGNED_INT8 )
                    b_has_rgba = 1;
            }
            x264_free( imageType );
            if( !b_has_r || !b_has_rgba )
            {
                char devname[64];
                status = clGetDeviceInfo( h->opencl.device, CL_DEVICE_NAME, sizeof(devname), devname, NULL );
                if( status == CL_SUCCESS )
                {
                    /* emit warning if we are discarding the user's explicit choice */
                    int level = h->param.opencl_device_id ? X264_LOG_WARNING : X264_LOG_DEBUG;
                    x264_log( h, level, "OpenCL: %s does not support required image formats\n", devname);
                }
                clReleaseContext( context );
                continue;
            }

            /* user selection of GPU device, skip N first matches */
            if( h->param.i_opencl_device )
            {
                h->param.i_opencl_device--;
                clReleaseContext( context );
                continue;
            }

            h->opencl.queue = clCreateCommandQueue( context, h->opencl.device, 0, &status );
            if( status != CL_SUCCESS )
            {
                clReleaseContext( context );
                continue;
            }

            h->opencl.context = context;

            ret = 0;
            break;
        }

        x264_free( devices );

        if( !ret )
            break;
    }

    x264_free( platforms );

    if( !h->param.psz_clbin_file )
        h->param.psz_clbin_file = "x264_lookahead.clbin";

    if( ret )
        x264_log( h, X264_LOG_WARNING, "OpenCL: Unable to find a compatible device\n");
    else
        ret = x264_opencl_init_lookahead( h );

    return ret;
}

void x264_opencl_frame_delete( x264_frame_t *frame )
{
#define RELEASEBUF(mem) if( mem ) clReleaseMemObject( mem );
    for( int j = 0; j < NUM_IMAGE_SCALES; j++ )
        RELEASEBUF( frame->opencl.scaled_image2Ds[j] );
    RELEASEBUF( frame->opencl.luma_hpel );
    RELEASEBUF( frame->opencl.inv_qscale_factor );
    RELEASEBUF( frame->opencl.intra_cost );
    RELEASEBUF( frame->opencl.lowres_mvs0 );
    RELEASEBUF( frame->opencl.lowres_mvs1 );
    RELEASEBUF( frame->opencl.lowres_mv_costs0 );
    RELEASEBUF( frame->opencl.lowres_mv_costs1 );
#undef RELEASEBUF
}

void x264_opencl_free( x264_t *h )
{
    if( h->opencl.queue )
        clFinish(h->opencl.queue );

    x264_opencl_free_lookahead( h );

    if( h->opencl.queue )
        clReleaseCommandQueue( h->opencl.queue );
    if( h->opencl.context )
        clReleaseContext( h->opencl.context );
}

/* OpenCL misbehaves on hybrid laptops with Intel iGPU and AMD dGPU, so
 * we consult AMD's ADL interface to detect this situation and disable
 * OpenCL on these machines (Linux and Windows) */
#ifndef _WIN32
#define __stdcall
#define HINSTANCE void *
#endif
typedef void* ( __stdcall *ADL_MAIN_MALLOC_CALLBACK )( int );
typedef int ( *ADL_MAIN_CONTROL_CREATE )(ADL_MAIN_MALLOC_CALLBACK, int );
typedef int ( *ADL_ADAPTER_NUMBEROFADAPTERS_GET ) ( int* );
typedef int ( *ADL_POWERXPRESS_SCHEME_GET ) ( int, int *, int *, int * );
typedef int ( *ADL_MAIN_CONTROL_DESTROY )();
#define ADL_OK 0
#define ADL_PX_SCHEME_DYNAMIC 2

void* __stdcall adl_malloc_wrapper( int iSize ) { return x264_malloc( iSize ); }

static int x264_detect_switchable_graphics()
{
    ADL_MAIN_CONTROL_CREATE          ADL_Main_Control_Create;
    ADL_ADAPTER_NUMBEROFADAPTERS_GET ADL_Adapter_NumberOfAdapters_Get;
    ADL_POWERXPRESS_SCHEME_GET       ADL_PowerXpress_Scheme_Get;
    ADL_MAIN_CONTROL_DESTROY         ADL_Main_Control_Destroy;
    HINSTANCE hDLL;
    int ret = 0;

#if _WIN32
    hDLL = LoadLibrary( "atiadlxx.dll" );
    if( !hDLL )
        hDLL = LoadLibrary( "atiadlxy.dll" );
#else
    hDLL = dlopen( "libatiadlxx.so", RTLD_LAZY|RTLD_GLOBAL );
#define GetProcAddress dlsym
#endif
    if( !hDLL )
        return ret;

    ADL_Main_Control_Create = (ADL_MAIN_CONTROL_CREATE) GetProcAddress(hDLL, "ADL_Main_Control_Create");
    ADL_Main_Control_Destroy = (ADL_MAIN_CONTROL_DESTROY) GetProcAddress(hDLL, "ADL_Main_Control_Destroy");
    ADL_Adapter_NumberOfAdapters_Get = (ADL_ADAPTER_NUMBEROFADAPTERS_GET) GetProcAddress(hDLL, "ADL_Adapter_NumberOfAdapters_Get");
    ADL_PowerXpress_Scheme_Get = (ADL_POWERXPRESS_SCHEME_GET) GetProcAddress(hDLL, "ADL_PowerXpress_Scheme_Get");
    if( !ADL_Main_Control_Destroy || !ADL_Main_Control_Destroy || !ADL_Adapter_NumberOfAdapters_Get ||
        !ADL_PowerXpress_Scheme_Get )
        goto bail;

    if( ADL_OK != ADL_Main_Control_Create( adl_malloc_wrapper, 1) )
        goto bail;

    int numAdapters = 0;
    if( ADL_OK != ADL_Adapter_NumberOfAdapters_Get( &numAdapters ) )
    {
        ADL_Main_Control_Destroy();
        goto bail;
    }

    for( int i = 0; i < numAdapters; i++ )
    {
        int PXSchemeRange, PXSchemeCurrentState, PXSchemeDefaultState;
        if( ADL_OK != ADL_PowerXpress_Scheme_Get( i, &PXSchemeRange, &PXSchemeCurrentState, &PXSchemeDefaultState) )
            break;

        if( PXSchemeRange >= ADL_PX_SCHEME_DYNAMIC )
        {
            ret = 1;
            break;
        }
    }

    ADL_Main_Control_Destroy();

bail:
#if _WIN32
    FreeLibrary( hDLL );
#else
    dlclose( hDLL );
#endif

    return ret;
}
