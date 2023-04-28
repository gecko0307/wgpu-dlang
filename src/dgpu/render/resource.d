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
module dgpu.render.resource;

import core.stdc.string: memcpy;
import std.conv;
import std.string;
import bindbc.wgpu;
import dlib.core.ownership;
import dlib.math.vector;
import dlib.math.matrix;
import dgpu.core.gpu;
import dgpu.core.resource;
import dgpu.asset.material;
import dgpu.render.renderer;

enum ResourceGroupIndex: uint
{
    PerFrame = 0,
    PerPass = 1,
    PerMaterial = 2,
    PerEntity = 3
}

struct RendererUniforms
{
    mat4 viewMatrix;
    mat4 invViewMatrix;
    mat4 projectionMatrix;
    vec4 view; // width, height, aspectRatio, 0
}

class RendererResource: Owner, Resource
{
    string label;
    Renderer renderer;
    RendererUniforms uniforms;
    WGPUBuffer uniformBuffer;
    WGPUBindGroup _bindGroup;
    
    this(Renderer renderer, Owner owner)
    {
        super(owner);
        label = "RendererResourceUB_" ~ toHash.to!string;
        this.renderer = renderer;
        
        uniforms.viewMatrix = mat4.identity;
        uniforms.invViewMatrix = mat4.identity;
        uniforms.projectionMatrix = mat4.identity;
        uniforms.view = vec4(1.0f, 1.0f, 1.0f, 0.0f);
        
        WGPUBufferDescriptor uniformBufferDescriptor = {
            nextInChain: null,
            label: label.toStringz,
            usage: WGPUBufferUsage.Uniform | WGPUBufferUsage.CopyDst,
            size: RendererUniforms.sizeof,
            mappedAtCreation: true
        };
        uniformBuffer = wgpuDeviceCreateBuffer(renderer.gpu.device, &uniformBufferDescriptor);
        void* destinationPtr = wgpuBufferGetMappedRange(uniformBuffer, 0, RendererUniforms.sizeof);
        memcpy(destinationPtr, cast(ubyte*)&uniforms, RendererUniforms.sizeof);
        wgpuBufferUnmap(uniformBuffer);
        
        WGPUBindGroupEntry entry = {
            nextInChain: null,
            binding: 0,
            buffer: uniformBuffer,
            offset: 0,
            size: RendererUniforms.sizeof,
            sampler: null,
            textureView: null
        };
        WGPUBindGroupDescriptor bindGroupDescriptor = {
            label: label.toStringz,
            layout: renderer.rendererResourceLayout,
            entries: &entry,
            entryCount: 1
        };
        _bindGroup = wgpuDeviceCreateBindGroup(renderer.gpu.device, &bindGroupDescriptor);
    }
    
    void upload()
    {
        wgpuQueueWriteBuffer(renderer.gpu.queue, uniformBuffer, 0, cast(ubyte*)&uniforms, RendererUniforms.sizeof);
    }
    
    WGPUBindGroup bindGroup() @property
    {
        return _bindGroup;
    }
}

struct PassUniforms
{
    vec4 placeholder;
}

class PassResource: Owner, Resource
{
    string label;
    Renderer renderer;
    PassUniforms uniforms;
    WGPUBuffer uniformBuffer;
    WGPUBindGroup _bindGroup;
    
    this(Renderer renderer, Owner owner)
    {
        super(owner);
        label = "PassResourceUB_" ~ toHash.to!string;
        this.renderer = renderer;
        
        uniforms.placeholder = vec4(0, 0, 0, 0);
        
        WGPUBufferDescriptor uniformBufferDescriptor = {
            nextInChain: null,
            label: label.toStringz,
            usage: WGPUBufferUsage.Uniform | WGPUBufferUsage.CopyDst,
            size: PassUniforms.sizeof,
            mappedAtCreation: true
        };
        uniformBuffer = wgpuDeviceCreateBuffer(renderer.gpu.device, &uniformBufferDescriptor);
        void* destinationPtr = wgpuBufferGetMappedRange(uniformBuffer, 0, PassUniforms.sizeof);
        memcpy(destinationPtr, cast(ubyte*)&uniforms, PassUniforms.sizeof);
        wgpuBufferUnmap(uniformBuffer);
        
        WGPUBindGroupEntry entry = {
            binding: 0,
            buffer: uniformBuffer,
            offset: 0,
            size: PassUniforms.sizeof
        };
        
        WGPUBindGroupDescriptor bindGroupDescriptor = {
            label: label.toStringz,
            layout: renderer.passResourceLayout,
            entries: &entry,
            entryCount: 1
        };
        _bindGroup = wgpuDeviceCreateBindGroup(renderer.gpu.device, &bindGroupDescriptor);
    }
    
    void upload()
    {
        wgpuQueueWriteBuffer(renderer.gpu.queue, uniformBuffer, 0, cast(ubyte*)&uniforms, PassUniforms.sizeof);
    }
    
    WGPUBindGroup bindGroup() @property
    {
        return _bindGroup;
    }
}

struct MaterialUniforms
{
    vec4 baseColorFactor;
    vec4 roughnessMetallicFactor;
}

class MaterialResource: Owner, Resource
{
    string label;
    Renderer renderer;
    MaterialUniforms uniforms;
    Material material;
    WGPUBuffer uniformBuffer;
    WGPUBindGroup _bindGroup;
    
    this(Renderer renderer, Material material, Owner o)
    {
        super(o);
        label = "MaterialResourceUB_" ~ toHash.to!string;
        this.renderer = renderer;
        this.material = material;
        
        WGPUBufferDescriptor uniformBufferDescriptor = {
            nextInChain: null,
            label: label.toStringz,
            usage: WGPUBufferUsage.Uniform | WGPUBufferUsage.CopyDst,
            size: MaterialUniforms.sizeof,
            mappedAtCreation: true
        };
        uniformBuffer = wgpuDeviceCreateBuffer(renderer.gpu.device, &uniformBufferDescriptor);
        void* destinationPtr = wgpuBufferGetMappedRange(uniformBuffer, 0, MaterialUniforms.sizeof);
        memcpy(destinationPtr, cast(ubyte*)&uniforms, MaterialUniforms.sizeof);
        wgpuBufferUnmap(uniformBuffer);
        
        WGPUBindGroupEntry[7] entries = [
            {
                binding: 0,
                buffer: uniformBuffer,
                offset: 0,
                size: MaterialUniforms.sizeof
            },
            {
                binding: 1,
                sampler: material.baseColorTexture.sampler
            },
            {
                binding: 2,
                textureView: material.baseColorTexture.view
            },
            {
                binding: 3,
                sampler: material.normalTexture.sampler
            },
            {
                binding: 4,
                textureView: material.normalTexture.view
            },
            {
                binding: 5,
                sampler: material.roughnessMetallicTexture.sampler
            },
            {
                binding: 6,
                textureView: material.roughnessMetallicTexture.view
            }
        ];
        WGPUBindGroupDescriptor bindGroupDescriptor = {
            label: label.toStringz,
            layout: renderer.materialResourceLayout,
            entries: entries.ptr,
            entryCount: entries.length
        };
        _bindGroup = wgpuDeviceCreateBindGroup(renderer.gpu.device, &bindGroupDescriptor);
    }
    
    void upload()
    {
        wgpuQueueWriteBuffer(renderer.gpu.queue, uniformBuffer, 0, cast(ubyte*)&uniforms, MaterialUniforms.sizeof);
    }
    
    WGPUBindGroup bindGroup() @property
    {
        return _bindGroup;
    }
}

struct GeometryUniforms
{
    mat4 modelViewMatrix;
    mat4 normalMatrix;
}

class GeometryResource: Owner, Resource
{
    string label;
    Renderer renderer;
    GeometryUniforms uniforms;
    WGPUBuffer uniformBuffer;
    WGPUBindGroup _bindGroup;
    
    this(Renderer renderer, Owner owner)
    {
        super(owner);
        label = "GeometryResourceUB_" ~ toHash.to!string;
        this.renderer = renderer;
        
        uniforms.modelViewMatrix = mat4.identity;
        uniforms.normalMatrix = mat4.identity;
        
        WGPUBufferDescriptor uniformBufferDescriptor = {
            nextInChain: null,
            label: label.toStringz,
            usage: WGPUBufferUsage.Uniform | WGPUBufferUsage.CopyDst,
            size: GeometryUniforms.sizeof,
            mappedAtCreation: true
        };
        uniformBuffer = wgpuDeviceCreateBuffer(renderer.gpu.device, &uniformBufferDescriptor);
        void* destinationPtr = wgpuBufferGetMappedRange(uniformBuffer, 0, GeometryUniforms.sizeof);
        memcpy(destinationPtr, cast(ubyte*)&uniforms, GeometryUniforms.sizeof);
        wgpuBufferUnmap(uniformBuffer);
        
        WGPUBindGroupEntry uniformBufferBindGroupEntry = {
            nextInChain: null,
            binding: 0,
            buffer: uniformBuffer,
            offset: 0,
            size: GeometryUniforms.sizeof,
            sampler: null,
            textureView: null
        };
        
        WGPUBindGroupDescriptor bindGroupDescriptor = {
            label: label.toStringz,
            layout: renderer.geometryResourceLayout,
            entries: &uniformBufferBindGroupEntry,
            entryCount: 1
        };
        
        _bindGroup = wgpuDeviceCreateBindGroup(renderer.gpu.device, &bindGroupDescriptor);
    }
    
    void upload()
    {
        wgpuQueueWriteBuffer(renderer.gpu.queue, uniformBuffer, 0, cast(ubyte*)&uniforms, GeometryUniforms.sizeof);
    }
    
    WGPUBindGroup bindGroup() @property
    {
        return _bindGroup;
    }
}
