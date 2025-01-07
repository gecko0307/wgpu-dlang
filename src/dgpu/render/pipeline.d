/*
Copyright (c) 2021-2025 Timur Gafarov

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
module dgpu.render.pipeline;

import std.string;
import std.conv;
import bindbc.wgpu;
import dlib.core.memory;
import dlib.core.ownership;
import dgpu.core.gpu;
import dgpu.render.renderer;
import dgpu.render.target;
import dgpu.render.shader;
import dgpu.render.pass;

class RenderPipeline: Owner
{
    Renderer renderer;
    RenderPass pass;
    Shader shader;
    RenderTarget renderTarget;
    string label;
    WGPURenderPipeline pipeline;
    
    this(RenderPass pass, Shader shader, RenderTarget renderTarget, Renderer renderer, Owner owner)
    {
        super(owner);
        label = toHash.to!string;
        
        this.pass = pass;
        this.shader = shader;
        this.renderTarget = renderTarget;
        this.renderer = renderer;
        
        init();
    }
    
    void init()
    {
        WGPUBindGroupLayout[4] layouts = [
            renderer.rendererResourceLayout,
            renderer.passResourceLayout,
            renderer.materialResourceLayout,
            renderer.geometryResourceLayout
        ];
        
        WGPUPipelineLayoutDescriptor pipelineLayoutDescriptor = {
            bindGroupLayouts: layouts.ptr,
            bindGroupLayoutCount: layouts.length
        };
        WGPUPipelineLayout pipelineLayout = wgpuDeviceCreatePipelineLayout(renderer.gpu.device, &pipelineLayoutDescriptor);
        
        WGPUBlendState blendState = {
            color: {
                srcFactor: WGPUBlendFactor.One,
                dstFactor: WGPUBlendFactor.Zero,
                operation: WGPUBlendOperation.Add
            },
            alpha: {
                srcFactor: WGPUBlendFactor.One,
                dstFactor: WGPUBlendFactor.Zero,
                operation: WGPUBlendOperation.Add
            }
        };
        
        WGPUColorTargetState colorTargetState = {
            format: renderTarget.colorFormat,
            blend: &blendState,
            writeMask: WGPUColorWriteMask.All
        };
        
        size_t vertexSize = float.sizeof * 3;
        size_t texcoordSize = float.sizeof * 2;
        size_t normalSize = float.sizeof * 3;
        
        WGPUVertexAttribute[3] attributes =
        [
            WGPUVertexAttribute(WGPUVertexFormat.Float32x3, 0, 0), //position
            WGPUVertexAttribute(WGPUVertexFormat.Float32x2, vertexSize, 1), //texcoord
            WGPUVertexAttribute(WGPUVertexFormat.Float32x3, vertexSize + texcoordSize, 2) //normal
        ];
        
        WGPUVertexBufferLayout vertexBufferLayout = {
            arrayStride: vertexSize + texcoordSize + normalSize,
            stepMode: WGPUVertexStepMode.Vertex,
            attributeCount: attributes.length,
            attributes: attributes.ptr
        };
        
        WGPUVertexState vertexState = {
            module_: shader.modules.vertex,
            entryPoint: shader.vertexEntryPoint.toStringz,
            bufferCount: 1,
            buffers: &vertexBufferLayout
        };
        
        WGPUFragmentState fragmentState = {
            module_: shader.modules.fragment,
            entryPoint: shader.fragmentEntryPoint.toStringz,
            targetCount: 1,
            targets: &colorTargetState
        };
        
        WGPUStencilFaceState stencilStateFront = {
            compare: WGPUCompareFunction.Always,
            failOp: WGPUStencilOperation.Keep,
            depthFailOp: WGPUStencilOperation.Keep,
            passOp: WGPUStencilOperation.Keep
        };
        
        WGPUStencilFaceState stencilStateBack = {
            compare: WGPUCompareFunction.Always,
            failOp: WGPUStencilOperation.Keep,
            depthFailOp: WGPUStencilOperation.Keep,
            passOp: WGPUStencilOperation.Keep
        };
        
        WGPUDepthStencilState depthStencilState = {
            nextInChain: null,
            format: renderTarget.depthStencilFormat,
            depthWriteEnabled: true,
            depthCompare: WGPUCompareFunction.Less,
            stencilFront: stencilStateFront,
            stencilBack: stencilStateBack,
            stencilReadMask: 0,
            stencilWriteMask: 0,
            depthBias: 0,
            depthBiasSlopeScale: 1,
            depthBiasClamp: 1
        };
        
        WGPURenderPipelineDescriptor renderPipelineDescriptor = {
            label: label.toStringz,
            layout: pipelineLayout,
            vertex: vertexState,
            primitive: {
                topology: WGPUPrimitiveTopology.TriangleList,
                stripIndexFormat: WGPUIndexFormat.Undefined,
                frontFace: WGPUFrontFace.CCW,
                cullMode: WGPUCullMode.None
            },
            multisample: {
                count: 1,
                mask: ~0,
                alphaToCoverageEnabled: false
            },
            fragment: &fragmentState,
            depthStencil: &depthStencilState
        };
        
        pipeline = wgpuDeviceCreateRenderPipeline(renderer.gpu.device, &renderPipelineDescriptor);
    }
}
