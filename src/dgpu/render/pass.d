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
module dgpu.render.pass;

import std.conv;
import std.file;
import bindbc.wgpu;
import dlib.core.memory;
import dlib.core.ownership;
import dlib.image.color;
import dgpu.core.gpu;
import dgpu.core.time;
import dgpu.render.renderer;
import dgpu.render.target;
import dgpu.render.resource;
import dgpu.render.pipeline;
import dgpu.render.shader;
import dgpu.render.drawable;
import dgpu.asset.scene;

class RenderPass: Owner
{
    string label;
    Renderer renderer;
    Color4f clearColor = Color4f(0.7f, 0.7f, 0.7f, 1.0f);
    float clearDepth = 1.0f;
    uint clearStencil = 0;
    
    Shader simpleShader;
    RenderPipeline simplePipeline;
    
    PassResource resource;

    this(Renderer renderer)
    {
        super(renderer);
        label = toHash.to!string;
        this.renderer = renderer;
        
        resource = New!PassResource(renderer, this);
        
        simpleShader = New!Shader(readText("data/shaders/pbr.wgsl"), "vs_main", "fs_main", renderer, this);
        simplePipeline = New!RenderPipeline(this, simpleShader, renderer.screenRenderTarget, renderer, this);
        
        if (renderer.screenRenderTarget.colorFormat == WGPUTextureFormat.BGRA8UnormSrgb)
        {
            clearColor = clearColor.toLinear();
        }
    }
    
    WGPURenderPassEncoder begin(WGPUTextureView colorTargetView, WGPUTextureView depthStencilTargetView, WGPUCommandEncoder encoder)
    {
        Color4f cColor = clearColor;
        if (renderer.screenRenderTarget.colorFormat == WGPUTextureFormat.BGRA8UnormSrgb)
        {
            cColor = cColor.toLinear();
        }
        
        WGPURenderPassColorAttachment colorAttachment = {
            view: colorTargetView,
            resolveTarget: null,
            loadOp: WGPULoadOp.Clear,
            storeOp: WGPUStoreOp.Store,
            clearValue: WGPUColor(cColor.r, cColor.g, cColor.b, cColor.a)
        };
        WGPURenderPassDepthStencilAttachment depthStencilAttachmentDescriptor = {
            view: depthStencilTargetView,
            depthLoadOp: WGPULoadOp.Clear,
            depthStoreOp: WGPUStoreOp.Store,
            depthClearValue: clearDepth,
            depthReadOnly: false,
            stencilLoadOp: WGPULoadOp.Clear,
            stencilStoreOp: WGPUStoreOp.Store,
            stencilClearValue: clearStencil,
            stencilReadOnly: false
        };
        WGPURenderPassDescriptor renderPassDescriptor = {
            colorAttachments: &colorAttachment,
            colorAttachmentCount: 1,
            depthStencilAttachment: &depthStencilAttachmentDescriptor
        };
        WGPURenderPassEncoder renderPass = wgpuCommandEncoderBeginRenderPass(encoder, &renderPassDescriptor);
        
        return renderPass;
    }
    
    void renderScene(Scene scene, WGPURenderPassEncoder encoder)
    {
        // TODO: update resource
        wgpuRenderPassEncoderSetBindGroup(encoder, ResourceGroupIndex.PerPass, this.resource.bindGroup, 0, null);
        
        foreach(material; scene.materials)
        {
            MaterialResource materialResource;
            if (material in renderer.materialResource)
                materialResource = renderer.materialResource[material];
            else {
                materialResource = New!MaterialResource(renderer, material, material);
                renderer.materialResource[material] = materialResource;
            }
            
            auto materialParams = &materialResource.uniforms;
            materialParams.baseColorFactor = material.baseColorFactor;
            materialParams.roughnessMetallicFactor = material.roughnessMetallicFactor;
            materialResource.upload();
            
            wgpuRenderPassEncoderSetBindGroup(encoder, ResourceGroupIndex.PerMaterial, materialResource.bindGroup, 0, null);
            
            wgpuRenderPassEncoderSetPipeline(encoder, simplePipeline.pipeline);
            
            foreach(entity; scene.entitiesByMaterial(material))
            {
                if (entity.geometry)
                {
                    auto uni = &renderer.geometryResource.uniforms;
                    uni.modelViewMatrix = renderer.rendererResource.uniforms.viewMatrix * entity.geometry.modelMatrix;
                    uni.normalMatrix = uni.modelViewMatrix.inverse.transposed;
                    renderer.geometryResource.upload();
                    
                    wgpuRenderPassEncoderSetBindGroup(encoder, ResourceGroupIndex.PerEntity, renderer.geometryResource.bindGroup, 0, null);
                    
                    Drawable drawable = cast(Drawable)entity.geometry;
                    if (drawable)
                        drawable.draw(entity, encoder);
                }
            }
        }
    }
    
    void end(WGPURenderPassEncoder encoder)
    {
        wgpuRenderPassEncoderEnd(encoder);
    }
}