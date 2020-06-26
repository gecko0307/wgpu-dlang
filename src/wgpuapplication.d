/*
Copyright (c) 2020 Timur Gafarov.

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module wgpuapplication;

import std.stdio;
import dlib.core.ownership;
import dlib.core.memory;
import bindbc.sdl;
import bindbc.wgpu;
import application;
import time;

class WGPUApplication: Application
{
    protected:
    WGPUAdapterId _adapter;
    WGPUDeviceId _device;
    WGPUQueueId _queue;
    WGPUSurfaceId _surface;
    WGPUSwapChainId _swapchain;
    WGPUSwapChainOutput _nextSwapchainOutput;
    WGPURenderPassColorAttachmentDescriptor _colorAttachment;
    WGPURenderPassDepthStencilAttachmentDescriptor _depthStencilAttachment;
    WGPUTextureId _depthStencilTexture;
    WGPUTextureViewId _depthStencilTextureView;

    public:
    this(uint windowWidth, uint windowHeight, Owner owner = null)
    {
        super(windowWidth, windowHeight, owner);
        __init();
    }

    ~this()
    {

    }

    protected void __init()
    {
        wgpu_set_log_level(WGPULogLevel.Debug);
        
        writeln("Surface...");
        _surface = createSurface();
        writeln("OK");
        
        writeln("Adapter...");
        _adapter = requestAdapter();
        writeln(_adapter);
        writeln("OK");

        writeln("Device...");
        _device = requestDevice();
        writeln("OK");
        
        writeln("Device queue...");
        _queue = wgpu_device_get_default_queue(_device);
        writeln("OK");

        writeln("Swapchain...");
        _swapchain = createSwapchain(window.width, window.height);
        writeln("OK");
        
        writeln("Attachments...");
        _colorAttachment = createColorAttachment(_nextSwapchainOutput);
        writeln("Color attachment OK");
        updateDepthStencilTexture(window.width, window.height);
        writeln("Depth-stencil texture OK");
        _depthStencilAttachment = createDepthStencilAttachment(_depthStencilTextureView);
        writeln("Depth-stencil attachment OK");
        writeln("OK");
    }

    protected static extern(C) void __requestAdapterCallback(WGPUOption_AdapterId id, void* userdata)
    {
        *cast(WGPUOption_AdapterId*)userdata = id;
    }

    WGPUAdapterId requestAdapter()
    {
        WGPURequestAdapterOptions reqAdaptersOptions =
        {
            power_preference: WGPUPowerPreference.HighPerformance,
            compatible_surface: _surface
        };
        WGPUAdapterId resAdapter;
        wgpu_request_adapter_async(&reqAdaptersOptions, 2 | 4 | 8, 1, &__requestAdapterCallback, &resAdapter);
        return resAdapter;
    }

    WGPUDeviceId requestDevice()
    {
        WGPUCLimits limits = 
        {
            max_bind_groups: 1 //WGPUDEFAULT_BIND_GROUPS
        };
        
        return wgpu_adapter_request_device(_adapter, 0, &limits, "trace");
    }

    WGPUSurfaceId createSurface()
    {
        SDL_SysWMinfo wmInfo = window.wmInfo;
        writeln("Subsystem: ", wmInfo.subsystem);
        WGPUSurfaceId surf;

        version(Windows)
        {
            if (wmInfo.subsystem == SDL_SYSWM_WINDOWS)
            {
                auto win_hwnd = wmInfo.info.win.window;
                auto win_hinstance = wmInfo.info.win.hinstance;
                surf = wgpu_create_surface_from_windows_hwnd(win_hinstance, win_hwnd);
            }
            else
            {
                quit("Unsupported subsystem, sorry");
            }
        }
        else version(linux)
        {
            // Needs test!
            if (wmInfo.subsystem == SDL_SYSWM_X11)
            {
                auto x11_display = wmInfo.info.x11.display;
                auto x11_window = wmInfo.info.x11.window;
                surf = wgpu_create_surface_from_xlib(cast(void**)x11_display, x11_window);
            }
            else if (wmInfo.subsystem == SDL_SYSWM_WAYLAND)
            {
                auto wl_surface = wmInfo.info.wl.surface;
                auto wl_display = wmInfo.info.wl.display;
                surf = wgpu_create_surface_from_wayland(wl_surface, wl_display);
            }
            else
            {
                quit("Unsupported subsystem, sorry");
            }
        }
        else version(OSX)
        {
            // Needs test!
            SDL_Renderer* renderer = SDL_CreateRenderer(window.sdlWindow, -1, SDL_RENDERER_PRESENTVSYNC);
            auto m_layer = SDL_RenderGetMetalLayer(renderer);
            surf = wgpu_create_surface_from_metal_layer(m_layer);
            SDL_DestroyRenderer(renderer);
        }
        else
        {
            quit("Unsupported system, sorry");
        }

        return surf;
    }

    WGPUSwapChainId createSwapchain(uint w, uint h)
    {
        WGPUSwapChainDescriptor sd = {
            usage: WGPUTextureUsage_OUTPUT_ATTACHMENT,
            format: WGPUTextureFormat.Bgra8Unorm,
            width: w,
            height: h,
            present_mode: WGPUPresentMode.Fifo
        };
        return wgpu_device_create_swap_chain(device, surface, &sd);
    }
    
    WGPURenderPassColorAttachmentDescriptor createColorAttachment(WGPUSwapChainOutput swapchainOutput)
    {
        WGPURenderPassColorAttachmentDescriptor colorAttachment =
        {
            attachment: swapchainOutput.view_id,
            load_op: WGPULoadOp.Clear,
            store_op: WGPUStoreOp.Store,
            clear_color: WGPUColor(0.5, 0.5, 0.5, 1.0)
        };
        return colorAttachment;
    }
    
    WGPUTextureId createDepthStencilTexture(uint width, uint height)
    {
        WGPUTextureDescriptor depthTextureDescriptor =
        {
            label: "depthTextureDescriptor0",
            size: WGPUExtent3d(width, height, 1),
            //array_layer_count: 1,
            mip_level_count: 1,
            sample_count: 1,
            dimension: WGPUTextureDimension.D2,
            format: WGPUTextureFormat.Depth24PlusStencil8,
            usage: WGPUTextureUsage_OUTPUT_ATTACHMENT
        };
        return wgpu_device_create_texture(device, &depthTextureDescriptor);
    }
    
    WGPUTextureViewId createDepthStencilTextureView(WGPUTextureId texture)
    {
        WGPUTextureViewDescriptor viewDescriptor =
        {
            label: "depthTextureViewDescriptor0",
            format: WGPUTextureFormat.Depth24PlusStencil8,
            dimension: WGPUTextureViewDimension.D2,
            aspect: WGPUTextureAspect.DepthOnly,
            base_mip_level: 0,
            level_count: 1,
            base_array_layer: 0,
            array_layer_count: 1
        };
        return wgpu_texture_create_view(texture, &viewDescriptor);
    }
    
    void updateDepthStencilTexture(uint width, uint height)
    {
        if (_depthStencilTexture)
        {
            writeln("wgpu_texture_destroy(depthTexture)");
            wgpu_texture_destroy(_depthStencilTexture);
        }
        
        if (_depthStencilTextureView)
        {
            writeln("wgpu_texture_view_destroy(depthAttachment)");
            wgpu_texture_view_destroy(_depthStencilTextureView);
        }

        writeln("Depth-stencil texture...");
        _depthStencilTexture = createDepthStencilTexture(width, height);
        
        writeln("Depth-stencil texture view...");
        _depthStencilTextureView = createDepthStencilTextureView(_depthStencilTexture);
    }
    
    WGPURenderPassDepthStencilAttachmentDescriptor createDepthStencilAttachment(WGPUTextureViewId view)
    {
        WGPURenderPassDepthStencilAttachmentDescriptor attachment = {
            attachment: view,
            depth_load_op: WGPULoadOp.Clear,
            depth_store_op: WGPUStoreOp.Store,
            clear_depth: 1.0f,
            stencil_load_op: WGPULoadOp.Clear,
            stencil_store_op: WGPUStoreOp.Store,
            clear_stencil: 0
        };
        return attachment;
    }

    public:
    WGPUAdapterId adapter()
    {
        return _adapter;
    }

    WGPUDeviceId device()
    {
        return _device;
    }

    WGPUQueueId queue()
    {
        return _queue;
    }

    WGPUSurfaceId surface()
    {
        return _surface;
    }

    WGPUSwapChainId swapchain()
    {
        return _swapchain;
    }
    
    override void onRender()
    {
        _nextSwapchainOutput = wgpu_swap_chain_get_next_texture(_swapchain);
        _colorAttachment.attachment = _nextSwapchainOutput.view_id;
    }
    
    override void onResize(int width, int height)
    {
        window.querySize();
        _swapchain = createSwapchain(width, height);
        updateDepthStencilTexture(width, height);
        _depthStencilAttachment = createDepthStencilAttachment(_depthStencilTextureView);
    }
}
