/*
Copyright (c) 2019-2020 Timur Gafarov.

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
module main;

import core.stdc.stdlib;
import core.stdc.string;
import std.stdio;
import std.file;
import std.conv;
import std.string;
import std.process;
import std.range;
import bindbc.sdl;
import bindbc.wgpu;

import dlib.core;
import dlib.image;
import dlib.math;
import dlib.geometry;
import dlib.filesystem;

import wgpuapplication;
import mesh;
import time;
import texture;

struct Uniforms
{
    Matrix4x4f modelViewMatrix;
    Matrix4x4f normalMatrix;
    Matrix4x4f projectionMatrix;
}

class MyApplication: WGPUApplication
{
    WGPUMesh cerberusMesh;
    
    float fov = 60.0f;
    float angle = 0.0f;
    Vector3f cameraPosition = Vector3f(0.0f, 5.0f, 15.0f);
    
    Uniforms uniforms;
    WGPUBufferDescriptor uniformBufferDescriptor;
    WGPUBufferId uniformBuffer;
    WGPUBindGroupId bindGroup;
    
    WGPURenderPipelineId renderPipeline;
    
    this(uint windowWidth, uint windowHeight, Owner owner = null)
    {
        super(windowWidth, windowHeight, owner);
        writeln("Init...");
        initData();
    }
    
    void initData()
    {
        // Mesh
        writeln("Mesh...");
        InputStream istrm = openForInput("data/cerberus.obj");
        cerberusMesh = loadOBJ(device, istrm);
        writeln("OK");
        
        // Textures
        writeln("Textures...");
        // TODO: load images using GC-free loadPNG
        auto imgAlbedo = loadPNG("data/cerberus-albedo.png");
        auto imgNormal = loadPNG("data/cerberus-normal.png");
        auto imgRoughness = loadPNG("data/cerberus-roughness.png");
        auto imgMetallic = loadPNG("data/cerberus-metallic.png");
        Texture texture = New!Texture(device, queue, imgAlbedo.width, imgAlbedo.height, 4, this);
        texture.layerFromImage(imgAlbedo, 0);
        texture.layerFromImage(imgNormal, 1);
        texture.layerFromImage(imgRoughness, 2);
        texture.layerFromImage(imgMetallic, 3);
        writeln("OK");

        // Sampler
        writeln("Samplers...");
        WGPUSamplerDescriptor samplerDescriptor =
        {
            label: "samplerDescriptor0",
            address_mode_u: WGPUAddressMode.Repeat,
            address_mode_v: WGPUAddressMode.Repeat,
            address_mode_w: WGPUAddressMode.Repeat,
            mag_filter: WGPUFilterMode.Linear,
            min_filter: WGPUFilterMode.Linear,
            mipmap_filter: WGPUFilterMode.Linear,
            lod_min_clamp: 0.0f,
            lod_max_clamp: 0.0f,
            compare: WGPUCompareFunction.Always
        };
        WGPUSamplerId sampler = wgpu_device_create_sampler(device, &samplerDescriptor);
        writeln("OK");

        // Bind group
        writeln("Bind group...");
        WGPUBindGroupLayoutEntry bindingUniforms =
        {
            binding: 0,
            visibility: WGPUShaderStage_VERTEX | WGPUShaderStage_FRAGMENT,
            ty: WGPUBindingType.UniformBuffer,
            view_dimension: WGPUTextureViewDimension.D1,
            multisampled: false,
            has_dynamic_offset: false
        };
        WGPUBindGroupLayoutEntry bindingSampler =
        {
            binding: 1,
            visibility: WGPUShaderStage_FRAGMENT,
            ty: WGPUBindingType.Sampler,
            view_dimension: WGPUTextureViewDimension.D2Array,
            multisampled: false,
            has_dynamic_offset: false
        };
        WGPUBindGroupLayoutEntry bindingTexture =
        {
            binding: 2,
            visibility: WGPUShaderStage_FRAGMENT,
            ty: WGPUBindingType.SampledTexture,
            view_dimension: WGPUTextureViewDimension.D2Array,
            multisampled: false,
            has_dynamic_offset: false
        };

        WGPUBindGroupLayoutEntry[3] bindGroupLayoutBindings =
        [
            bindingUniforms, bindingSampler, bindingTexture
        ];
        WGPUBindGroupLayoutDescriptor bindGroupLayoutDescriptor = WGPUBindGroupLayoutDescriptor("Main", bindGroupLayoutBindings.ptr, bindGroupLayoutBindings.length);
        WGPUBindGroupLayoutId uniformsBindGroupLayout = wgpu_device_create_bind_group_layout(device, &bindGroupLayoutDescriptor);

        float aspectRatio = cast(float)window.width / cast(float)window.height;

        uniforms.modelViewMatrix = Matrix4x4f.identity;
        uniforms.normalMatrix = Matrix4x4f.identity;
        uniforms.projectionMatrix = perspectiveMatrix(fov, aspectRatio, 0.01f, 1000.0f);

        uniformBufferDescriptor = WGPUBufferDescriptor("UniformBuffer", uniforms.sizeof,
            WGPUBufferUsage_UNIFORM |
            WGPUBufferUsage_COPY_SRC |
            WGPUBufferUsage_COPY_DST);

        uniformBuffer = wgpu_device_create_buffer(device, &uniformBufferDescriptor);

        WGPUBindingResource bufBindingResource;
        bufBindingResource.tag = WGPUBindingResource_Tag.Buffer;
        bufBindingResource.buffer = WGPUBindingResource_WGPUBuffer_Body(WGPUBufferBinding(uniformBuffer, 0, uniforms.sizeof));

        WGPUBindingResource samplerBindingResource;
        samplerBindingResource.tag = WGPUBindingResource_Tag.Sampler;
        samplerBindingResource.sampler = WGPUBindingResource_WGPUSampler_Body(sampler);

        WGPUBindingResource textureBindingResource;
        textureBindingResource.tag = WGPUBindingResource_Tag.TextureView;
        textureBindingResource.texture_view = WGPUBindingResource_WGPUTextureView_Body(texture.viewId);

        WGPUBindGroupEntry[3] uniformBindGroupEntries =
        [
            WGPUBindGroupEntry(0, bufBindingResource),
            WGPUBindGroupEntry(1, samplerBindingResource),
            WGPUBindGroupEntry(2, textureBindingResource)
        ];
        WGPUBindGroupDescriptor bindGroupDescriptor = WGPUBindGroupDescriptor("Main", uniformsBindGroupLayout, uniformBindGroupEntries.ptr, uniformBindGroupEntries.length);
        bindGroup = wgpu_device_create_bind_group(device, &bindGroupDescriptor);
        writeln("OK");

        // Pipeline
        writeln("Shaders...");
        uint[] vs = cast(uint[])std.file.read("data/shaders/pbr.vert.spv");
        uint[] fs = cast(uint[])std.file.read("data/shaders/pbr.frag.spv");

        WGPUShaderModuleDescriptor vsDescriptor = WGPUShaderModuleDescriptor(WGPUU32Array(vs.ptr, vs.length));
        WGPUShaderModuleId vertexShader = wgpu_device_create_shader_module(device, &vsDescriptor);

        WGPUShaderModuleDescriptor fsDescriptor = WGPUShaderModuleDescriptor(WGPUU32Array(fs.ptr, fs.length));
        WGPUShaderModuleId fragmentShader = wgpu_device_create_shader_module(device, &fsDescriptor);

        WGPUPipelineLayoutDescriptor pipelineLayoutDescriptor = WGPUPipelineLayoutDescriptor(&uniformsBindGroupLayout, 1);
        WGPUPipelineLayoutId pipelineLayout = wgpu_device_create_pipeline_layout(device, &pipelineLayoutDescriptor);

        WGPUProgrammableStageDescriptor vsStageDescriptor =
        {
            _module: vertexShader,
            entry_point: "main".ptr
        };

        WGPUProgrammableStageDescriptor fsStageDescriptor =
        {
            _module: fragmentShader,
            entry_point: "main".ptr
        };
        writeln("OK");

        writeln("Pipeline...");
        WGPURasterizationStateDescriptor rastStateDescriptor =
        {
            front_face: WGPUFrontFace.Ccw,
            cull_mode: WGPUCullMode.None,
            depth_bias: 0,
            depth_bias_slope_scale: 0.0,
            depth_bias_clamp: 0.0
        };

        WGPUColorStateDescriptor colorStateDescriptor =
        {
            format: WGPUTextureFormat.Bgra8Unorm,
            alpha_blend:
            {
                src_factor: WGPUBlendFactor.One,
                dst_factor: WGPUBlendFactor.Zero,
                operation: WGPUBlendOperation.Add
            },
            color_blend:
            {
                src_factor: WGPUBlendFactor.One,
                dst_factor: WGPUBlendFactor.Zero,
                operation: WGPUBlendOperation.Add
            },
            write_mask: WGPUColorWrite_ALL
        };

        size_t vertexSize = float.sizeof * 3;
        size_t texcoordSize = float.sizeof * 2;
        size_t normalSize = float.sizeof * 3;

        WGPUVertexAttributeDescriptor attributeVertex =
        {
            offset: 0,
            format: WGPUVertexFormat.Float3,
            shader_location: 0
        };

        WGPUVertexAttributeDescriptor attributeTexcoord =
        {
            offset: vertexSize,
            format: WGPUVertexFormat.Float2,
            shader_location: 1
        };

        WGPUVertexAttributeDescriptor attributeNormal =
        {
            offset: vertexSize + texcoordSize,
            format: WGPUVertexFormat.Float3,
            shader_location: 2
        };

        WGPUVertexAttributeDescriptor[] attributes =
        [
            attributeVertex, attributeTexcoord, attributeNormal
        ];
        WGPUVertexBufferLayoutDescriptor vertexBufferLayoutDescriptor =
        {
            array_stride: vertexSize + texcoordSize + normalSize,
            step_mode: WGPUInputStepMode.Vertex,
            attributes: attributes.ptr,
            attributes_length: attributes.length
        };

        WGPUDepthStencilStateDescriptor depthStencilStateDecsriptor =
        {
            format: WGPUTextureFormat.Depth24PlusStencil8,
            depth_write_enabled: true,
            depth_compare: WGPUCompareFunction.Less,
            stencil_front:
            {
                compare: WGPUCompareFunction.Always,
                fail_op: WGPUStencilOperation.Keep,
                depth_fail_op: WGPUStencilOperation.Keep,
                pass_op: WGPUStencilOperation.Keep
            },
            stencil_back:
            {
                compare: WGPUCompareFunction.Always,
                fail_op: WGPUStencilOperation.Keep,
                depth_fail_op: WGPUStencilOperation.Keep,
                pass_op: WGPUStencilOperation.Keep
            },
            stencil_read_mask: 0x00000000,
            stencil_write_mask: 0x00000000
        };

        WGPURenderPipelineDescriptor renderPipelineDescriptor =
        {
            layout: pipelineLayout,
            vertex_stage: vsStageDescriptor,
            fragment_stage: &fsStageDescriptor,
            primitive_topology: WGPUPrimitiveTopology.TriangleList,
            rasterization_state: &rastStateDescriptor,
            color_states: &colorStateDescriptor,
            color_states_length: 1,
            depth_stencil_state: &depthStencilStateDecsriptor,
            vertex_state:
            {
                index_format: WGPUIndexFormat.Uint32,
                vertex_buffers: &vertexBufferLayoutDescriptor,
                vertex_buffers_length: 1,
            },
            sample_count: 1,
            sample_mask: 1,
            alpha_to_coverage_enabled: 0
        };
        renderPipeline = wgpu_device_create_render_pipeline(device, &renderPipelineDescriptor);
        writeln("OK");
    }

    ~this()
    {

    }
    
    override void onResize(int width, int height)
    {
        super.onResize(width, height);
        writeln(width, "x", height);
        float aspectRatio = cast(float)width / cast(float)height;
        uniforms.projectionMatrix = perspectiveMatrix(fov, aspectRatio, 0.01f, 1000.0f);
    }
    
    override void onUpdate(Time t)
    {
        angle += 0.5f;
        updateUniforms();
    }
    
    void updateUniforms()
    {
        uniforms.modelViewMatrix =
            //scaleMatrix(Vector3f(1, -1, 1)) * // Flip Y for OpenGL compatibility
            translationMatrix(-cameraPosition) *
            rotationMatrix(Axis.y, degtorad(angle)) *
            scaleMatrix(Vector3f(1, 1, 1));
        uniforms.normalMatrix = uniforms.modelViewMatrix.inverse.transposed;
    }
    
    override void onRender()
    {
        super.onRender();

        WGPUCommandEncoderDescriptor commandEncDescriptor = WGPUCommandEncoderDescriptor("commandEncDescriptor0");
        WGPUCommandEncoderId cmdEncoder = wgpu_device_create_command_encoder(device, &commandEncDescriptor);

        wgpu_queue_write_buffer(queue, uniformBuffer, 0, cast(ubyte*)&uniforms, uniforms.sizeof);

        WGPURenderPassDescriptor renderPassDescriptor =
        {
            color_attachments: &_colorAttachment,
            color_attachments_length: 1,
            depth_stencil_attachment: &_depthStencilAttachment
        };
        WGPURenderPassId pass = wgpu_command_encoder_begin_render_pass(cmdEncoder, &renderPassDescriptor);

        wgpu_render_pass_set_pipeline(pass, renderPipeline);
        wgpu_render_pass_set_bind_group(pass, 0, bindGroup, null, 0);

        // Draw Cerberus mesh
        wgpu_render_pass_set_vertex_buffer(pass, 0, cerberusMesh.attributeBuffer, 0, Vector3f.sizeof * cerberusMesh.numVertices);
        wgpu_render_pass_set_index_buffer(pass, cerberusMesh.indexBuffer, 0, uint.sizeof * cerberusMesh.numIndices);
        wgpu_render_pass_draw_indexed(pass, cerberusMesh.numIndices, 1, 0, 0, 0);

        wgpu_render_pass_end_pass(pass);
        
        WGPUCommandBufferId cmdBuf = wgpu_command_encoder_finish(cmdEncoder, null);
        wgpu_queue_submit(queue, &cmdBuf, 1);
        wgpu_swap_chain_present(swapchain);
    }
}

void main()
{
    MyApplication app = New!MyApplication(800, 600);
    app.run();
    Delete(app);
    writeln("allocatedMemory: ", allocatedMemory);
}
