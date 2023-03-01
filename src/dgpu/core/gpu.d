/*
Copyright (c) 2021-2023 Timur Gafarov

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
module dgpu.core.gpu;

import std.stdio;
import std.conv;
import bindbc.sdl;
import bindbc.wgpu;
import dlib.core.ownership;
import dgpu.core.application;

class GPU: Owner
{
    Application application;
    WGPUInstance instance;
    WGPUSurface surface;
    WGPUAdapter adapter;
    WGPUDevice device;
    WGPUQueue queue;
    WGPUAdapterProperties adapterProperties;
    
    this(Application app)
    {
        super(app);
        application = app;
        
        debug
        {
            WGPULogLevel logLevel = WGPULogLevel.Debug; // WGPULogLevel.Trace
        }
        else
        {
            WGPULogLevel logLevel = WGPULogLevel.Warn;
        }
        wgpuSetLogLevel(logLevel);
        wgpuSetLogCallback(&logCallback, null);
        
        WGPUInstanceDescriptor instanceDesc;
        instance = wgpuCreateInstance(&instanceDesc);
        
        SDL_SysWMinfo wmInfo;
        SDL_GetWindowWMInfo(app.window, &wmInfo);
        app.logger.log("Subsystem: " ~ to!string(wmInfo.subsystem));
        surface = createSurface(wmInfo);
        app.logger.log("Surface created");
        adapter = createAdapter(surface);
        app.logger.log("Adapter created");
        device = createDevice(adapter);
        app.logger.log("Device created");
        queue = wgpuDeviceGetQueue(device);
        app.logger.log("Queue created");
        
        wgpuAdapterGetProperties(adapter, &adapterProperties);
        app.logger.log("Device ID: " ~ to!string(adapterProperties.deviceID));
        app.logger.log("Vendor ID: " ~ to!string(adapterProperties.vendorID));
        app.logger.log("Adapter type: " ~ to!string(adapterProperties.adapterType));
        app.logger.log("Backend: " ~ to!string(adapterProperties.backendType));
    }
    
    protected WGPUAdapter createAdapter(WGPUSurface surface)
    {
        WGPUAdapter adapter;
        WGPURequestAdapterOptions adapterOptions = {
            nextInChain: null,
            compatibleSurface: surface,
            powerPreference: WGPUPowerPreference.HighPerformance
        };
        wgpuInstanceRequestAdapter(instance, &adapterOptions, &requestAdapterCallback, cast(void*)&adapter);
        return adapter;
    }
    
    protected WGPUDevice createDevice(WGPUAdapter adapter)
    {
        WGPUDeviceExtras deviceExtras = {
            chain: {
                next: null,
                sType: cast(WGPUSType)WGPUNativeSType.DeviceExtras
            },
            //nativeFeatures: WGPUNativeFeature.TEXTURE_ADAPTER_SPECIFIC_FORMAT_FEATURES,
            //label: "Device",
            tracePath: null,
        };
        WGPURequiredLimits limits = {
            nextInChain: null,
            limits: {
                maxTextureDimension1D: 8192,
                maxTextureDimension2D: 8192,
                maxTextureDimension3D: 8192,
                maxTextureArrayLayers: 256,
                maxBindGroups: 4,
                maxBindingsPerBindGroup: 640,
                maxDynamicUniformBuffersPerPipelineLayout: 8,
                maxDynamicStorageBuffersPerPipelineLayout: 4,
                maxSampledTexturesPerShaderStage: 16,
                maxSamplersPerShaderStage: 16,
                maxStorageBuffersPerShaderStage: 8,
                maxStorageTexturesPerShaderStage: 4,
                maxUniformBuffersPerShaderStage: 12,
                maxUniformBufferBindingSize: 65536,
                maxStorageBufferBindingSize: 134217728,
                minUniformBufferOffsetAlignment: 256,
                minStorageBufferOffsetAlignment: 256,
                maxVertexBuffers: 8,
                maxBufferSize: 268435456,
                maxVertexAttributes: 16,
                maxVertexBufferArrayStride: 2048,
                maxInterStageShaderComponents: 60,
                maxInterStageShaderVariables: 16,
                maxColorAttachments: 8,
                maxComputeWorkgroupStorageSize: 16352,
                maxComputeInvocationsPerWorkgroup: 256,
                maxComputeWorkgroupSizeX: 256,
                maxComputeWorkgroupSizeY: 256,
                maxComputeWorkgroupSizeZ: 64,
                maxComputeWorkgroupsPerDimension: 65535
            }
        };
        WGPUDeviceDescriptor deviceDescriptor = {
            nextInChain: cast(const(WGPUChainedStruct)*)&deviceExtras,
            requiredFeaturesCount: 0,
            requiredFeatures: null,
            requiredLimits: &limits
        };
        WGPUDevice device = null;
        wgpuAdapterRequestDevice(adapter, &deviceDescriptor, &requestDeviceCallback, cast(void*)&device);
        return device;
    }
    
    WGPUCommandEncoder createCommandEncoder()
    {
        WGPUCommandEncoderDescriptor commandEncoderDescriptor = {
            label: "Command Encoder"
        };
        return wgpuDeviceCreateCommandEncoder(device, &commandEncoderDescriptor);
    }
    
    void submitCommands(WGPUCommandEncoder commandEncoder)
    {
        WGPUCommandBufferDescriptor commandBufferDescriptor = { label: null };
        WGPUCommandBuffer commandBuffer = wgpuCommandEncoderFinish(commandEncoder, &commandBufferDescriptor);
        wgpuQueueSubmit(queue, 1, &commandBuffer);
    }
    
    protected WGPUSurface createSurface(SDL_SysWMinfo wmInfo)
    {
        WGPUSurface surface;
        version(Windows)
        {
            if (wmInfo.subsystem == SDL_SYSWM_WINDOWS)
            {
                auto win_hwnd = wmInfo.info.win.window;
                auto win_hinstance = wmInfo.info.win.hinstance;
                WGPUSurfaceDescriptorFromWindowsHWND sfdHwnd = {
                    chain: {
                        next: null,
                        sType: WGPUSType.SurfaceDescriptorFromWindowsHWND
                    },
                    hinstance: win_hinstance,
                    hwnd: win_hwnd
                };
                WGPUSurfaceDescriptor sfd = {
                    label: null,
                    nextInChain: cast(const(WGPUChainedStruct)*)&sfdHwnd
                };
                surface = wgpuInstanceCreateSurface(instance, &sfd);
            }
            else
            {
                application.logger.error("Unsupported subsystem, sorry");
            }
        }
        else version(linux)
        {
            // Needs test!
            if (wmInfo.subsystem == SDL_SYSWM_X11)
            {
                auto x11_display = wmInfo.info.x11.display;
                auto x11_window = wmInfo.info.x11.window;
                WGPUSurfaceDescriptorFromXlib sfdX11 = {
                    chain: {
                        next: null,
                        sType: WGPUSType.SurfaceDescriptorFromXlib
                    },
                    display: x11_display,
                    window: x11_window
                };
                WGPUSurfaceDescriptor sfd = {
                    label: null,
                    nextInChain: cast(const(WGPUChainedStruct)*)&sfdX11
                };
                surface = wgpuInstanceCreateSurface(instance, &sfd);
            }
            else
            {
                application.logger.error("Unsupported subsystem, sorry");
            }
        }
        else version(OSX)
        {
            // Needs test!
            SDL_Renderer* renderer = SDL_CreateRenderer(window.sdlWindow, -1, SDL_RENDERER_PRESENTVSYNC);
            auto metalLayer = SDL_RenderGetMetalLayer(renderer);
            
            WGPUSurfaceDescriptorFromMetalLayer sfdMetal = {
                chain: {
                    next: null,
                    sType: WGPUSType.SurfaceDescriptorFromMetalLayer
                },
                layer: metalLayer
            };
            WGPUSurfaceDescriptor sfd = {
                label: null,
                nextInChain: cast(const(WGPUChainedStruct)*)&sfdMetal
            };
            surface = wgpuInstanceCreateSurface(instance, &sfd);
            
            SDL_DestroyRenderer(renderer);
        }
        return surface;
    }
}

private extern(C)
{
    void logCallback(WGPULogLevel level, const(char)* msg, void* user_data)
    {
        const (char)[] level_message;
        switch(level)
        {
            case WGPULogLevel.Off:level_message = "off";break;
            case WGPULogLevel.Error:level_message = "error";break;
            case WGPULogLevel.Warn:level_message = "warn";break;
            case WGPULogLevel.Info:level_message = "info";break;
            case WGPULogLevel.Debug:level_message = "debug";break;
            case WGPULogLevel.Trace:level_message = "trace";break;
            default: level_message = "-";
        }
        writeln("WebGPU ", level_message, ": ",  to!string(msg));
    }
    
    void requestAdapterCallback(WGPURequestAdapterStatus status, WGPUAdapter adapter, const(char)* message, void* userdata)
    {
        if (status == WGPURequestAdapterStatus.Success)
            *cast(WGPUAdapter*)userdata = adapter;
        else
        {
            writeln(status);
            writeln(to!string(message));
        }
    }

    void requestDeviceCallback(WGPURequestDeviceStatus status, WGPUDevice device, const(char)* message, void* userdata)
    {
        if (status == WGPURequestDeviceStatus.Success)
            *cast(WGPUDevice*)userdata = device;
        else
        {
            writeln(status);
            writeln(to!string(message));
        }
    }
}
