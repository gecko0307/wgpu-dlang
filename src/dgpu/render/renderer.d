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
module dgpu.render.renderer;

import std.conv;
import std.string;
import bindbc.wgpu;
import dlib.core.memory;
import dlib.core.ownership;
import dlib.container.array;
import dlib.container.dict;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.transformation;
import dgpu.core.application;
import dgpu.core.event;
import dgpu.core.time;
import dgpu.core.gpu;
import dgpu.asset.scene;
import dgpu.asset.material;
import dgpu.render.target;
import dgpu.render.pass;
import dgpu.render.resource;

WGPUBindGroupLayout createRendererResourceLayout(Renderer renderer)
{
    WGPUBindGroupLayoutEntry[1] entries = [
        {
            nextInChain: null,
            binding: 0,
            visibility: WGPUShaderStage.Vertex | WGPUShaderStage.Fragment,
            buffer: {
                nextInChain: null,
                type: WGPUBufferBindingType.Uniform,
                hasDynamicOffset: false,
                minBindingSize: RendererUniforms.sizeof
            }
        }
    ];
    
    WGPUBindGroupLayoutDescriptor bindGroupLayoutDescriptor = {
        label: renderer.label.toStringz,
        entries: entries.ptr,
        entryCount: entries.length
    };
    
    return wgpuDeviceCreateBindGroupLayout(renderer.gpu.device, &bindGroupLayoutDescriptor);
}

WGPUBindGroupLayout createMaterialResourceLayout(Renderer renderer)
{
    WGPUBindGroupLayoutEntry[7] entries = [
        {
            nextInChain: null,
            binding: 0,
            visibility: WGPUShaderStage.Fragment,
            buffer: {
                nextInChain: null,
                type: WGPUBufferBindingType.Uniform,
                hasDynamicOffset: false,
                minBindingSize: MaterialUniforms.sizeof
            }
        },
        {
            nextInChain: null,
            binding: 1,
            visibility: WGPUShaderStage.Fragment,
            sampler: {
                nextInChain: null,
                type: WGPUSamplerBindingType.Filtering
            }
        },
        {
            nextInChain: null,
            binding: 2,
            visibility: WGPUShaderStage.Fragment,
            texture: {
                nextInChain: null,
                sampleType: WGPUTextureSampleType.Float,
                viewDimension: WGPUTextureViewDimension.D2Array,
                multisampled: false
            }
        },
        {
            nextInChain: null,
            binding: 3,
            visibility: WGPUShaderStage.Fragment,
            sampler: {
                nextInChain: null,
                type: WGPUSamplerBindingType.Filtering
            }
        },
        {
            nextInChain: null,
            binding: 4,
            visibility: WGPUShaderStage.Fragment,
            texture: {
                nextInChain: null,
                sampleType: WGPUTextureSampleType.Float,
                viewDimension: WGPUTextureViewDimension.D2Array,
                multisampled: false
            }
        },
        {
            nextInChain: null,
            binding: 5,
            visibility: WGPUShaderStage.Fragment,
            sampler: {
                nextInChain: null,
                type: WGPUSamplerBindingType.Filtering
            }
        },
        {
            nextInChain: null,
            binding: 6,
            visibility: WGPUShaderStage.Fragment,
            texture: {
                nextInChain: null,
                sampleType: WGPUTextureSampleType.Float,
                viewDimension: WGPUTextureViewDimension.D2Array,
                multisampled: false
            }
        }
    ];
    
    WGPUBindGroupLayoutDescriptor bindGroupLayoutDescriptor = {
        label: renderer.label.toStringz,
        entries: entries.ptr,
        entryCount: entries.length
    };
    
    return wgpuDeviceCreateBindGroupLayout(renderer.gpu.device, &bindGroupLayoutDescriptor);
}

WGPUBindGroupLayout createGeometryResourceLayout(Renderer renderer)
{
    WGPUBindGroupLayoutEntry[1] entries = [
        {
            nextInChain: null,
            binding: 0,
            visibility: WGPUShaderStage.Vertex | WGPUShaderStage.Fragment,
            buffer: {
                nextInChain: null,
                type: WGPUBufferBindingType.Uniform,
                hasDynamicOffset: false,
                minBindingSize: GeometryUniforms.sizeof
            }
        }
    ];
    
    WGPUBindGroupLayoutDescriptor bindGroupLayoutDescriptor = {
        label: renderer.label.toStringz,
        entries: entries.ptr,
        entryCount: entries.length
    };
    
    return wgpuDeviceCreateBindGroupLayout(renderer.gpu.device, &bindGroupLayoutDescriptor);
}

class Renderer: EventListener
{
    string label;
    GPU gpu;
    ScreenRenderTarget screenRenderTarget;
    Array!RenderPass passes;
    WGPUBindGroupLayout rendererResourceLayout;
    WGPUBindGroupLayout materialResourceLayout;
    WGPUBindGroupLayout geometryResourceLayout;
    RendererResource rendererResource;
    Dict!(MaterialResource, Material) materialResource;
    GeometryResource geometryResource;
    
    this(Application app, Owner owner)
    {
        super(app.eventManager, owner);
        label = toHash.to!string;
        gpu = app.gpu;
        screenRenderTarget = New!ScreenRenderTarget(gpu, app.width, app.height, this);
        app.logger.log("Swapchain format: " ~ to!string(screenRenderTarget.swapChainFormat));
        
        rendererResourceLayout = createRendererResourceLayout(this);
        materialResourceLayout = createMaterialResourceLayout(this);
        geometryResourceLayout = createGeometryResourceLayout(this);
        
        rendererResource = New!RendererResource(this, this);
        materialResource = New!(Dict!(MaterialResource, Material))();
        geometryResource = New!GeometryResource(this, this);
        
        createPass();
    }
    
    ~this()
    {
        passes.free();
        Delete(materialResource);
    }
    
    RenderPass createPass()
    {
        RenderPass pass = New!RenderPass(this);
        passes.append(pass);
        return pass;
    }
    
    override void onResize(uint width, uint height)
    {
        screenRenderTarget.resize(width, height);
    }
    
    void update(Time t)
    {
        processEvents();
    }
    
    void renderScene(Scene scene)
    {
        WGPUCommandEncoder commandEncoder = gpu.createCommandEncoder();
        
        float width = cast(float)screenRenderTarget.width;
        float height = cast(float)screenRenderTarget.height;
        float aspect = screenRenderTarget.aspectRatio;
        
        if (scene.activeCamera)
        {
            rendererResource.uniforms.viewMatrix = scene.activeCamera.viewMatrix;
            rendererResource.uniforms.invViewMatrix = scene.activeCamera.invViewMatrix;
            rendererResource.uniforms.projectionMatrix = scene.activeCamera.projectionMatrix(aspect);
        }
        else
        {
            rendererResource.uniforms.viewMatrix = translationMatrix(vec3(0, 0, 0));
            rendererResource.uniforms.invViewMatrix = rendererResource.uniforms.viewMatrix.inverse;
            rendererResource.uniforms.projectionMatrix = perspectiveMatrix(60.0f, aspect, 0.01f, 1000.0f);
        }
        rendererResource.uniforms.view = vec4(width, height, aspect, 0.0f);
        rendererResource.upload();
        
        RenderBuffer colorBuffer = screenRenderTarget.nextBackBuffer();
        if (!colorBuffer.view)
            return;
        RenderBuffer depthStencilBuffer = screenRenderTarget.depthStencilBuffer();
        if (!depthStencilBuffer.view)
            return;
        
        bool canSubmit = true;
        foreach(pass; passes)
        {
            WGPURenderPassEncoder encoder = pass.begin(colorBuffer.view, depthStencilBuffer.view, commandEncoder);
            
            if (encoder)
            {
                wgpuRenderPassEncoderSetViewport(encoder, 0.0f, 0.0f, width, height, 0.0f, 1.0f);
                wgpuRenderPassEncoderSetScissorRect(encoder, 0, 0, screenRenderTarget.width, screenRenderTarget.height);
                wgpuRenderPassEncoderSetBindGroup(encoder, ResourceGroupIndex.PerFrame, rendererResource.bindGroup, 0, null);
                pass.renderScene(scene, encoder);
                pass.end(encoder);
            }
            else
            {
                canSubmit = false;
                break;
            }
        }
        
        if (!canSubmit) return;
        
        gpu.submitCommands(commandEncoder);
        screenRenderTarget.present();
    }
}