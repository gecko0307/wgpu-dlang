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

import mesh;

void quit(string message)
{
    writeln(message);
    core.stdc.stdlib.exit(1);
}

extern(C) void requestAdapterCallback(WGPUAdapterId adapter, void* userdata)
{
    *cast(WGPUAdapterId*)userdata = adapter;
}

void main()
{
    auto sdlSupport = loadSDL();
    writeln("sdlSupport: ", sdlSupport);

    auto wgpuSupport = loadWGPU();
    writeln("wgpuSupport: ", wgpuSupport);

    if (sdlSupport == SDLSupport.noLibrary)
        quit("Error: SDL is not installed");

    if (wgpuSupport == WGPUSupport.noLibrary)
        quit("Error: WGPU is not installed");

    if (SDL_Init(SDL_INIT_EVERYTHING) == -1)
        quit("Error: failed to init SDL: " ~ to!string(SDL_GetError()));

    uint windowWidth = 800;
    uint windowHeight = 600;

    auto window = SDL_CreateWindow(toStringz("WebGPU Demo"),
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        windowWidth, windowHeight,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
    SDL_SysWMinfo winInfo;
    SDL_GetWindowWMInfo(window, &winInfo);
    auto hwnd = winInfo.info.win.window;
    auto hinstance = winInfo.info.win.hinstance;

    writeln("Adapter...");
    WGPURequestAdapterOptions reqAdaptersOptions =
    {
        power_preference: WGPUPowerPreference.HighPerformance
    };
    WGPUAdapterId adapter;
    wgpu_request_adapter_async(&reqAdaptersOptions, 2 | 4 | 8, &requestAdapterCallback, &adapter);
    writeln("OK");

    writeln("Device...");
    WGPUDeviceDescriptor deviceDescriptor =
    {
        extensions:
        {
            anisotropic_filtering: false
        },
        limits:
        {
            max_bind_groups: 3
        }
    };
    WGPUDeviceId device = wgpu_adapter_request_device(adapter, &deviceDescriptor);
    writeln("OK");

    WGPUQueueId queue = wgpu_device_get_queue(device);

    writeln("Bind group layout...");
    WGPUBindGroupLayoutBinding layoutBindingUniforms =
    {
        binding: 0,
        visibility: WGPUShaderStage_VERTEX | WGPUShaderStage_FRAGMENT,
        ty: WGPUBindingType.UniformBuffer,
        texture_dimension: WGPUTextureViewDimension.D1,
        multisampled: false,
        dynamic: false
    };
    WGPUBindGroupLayoutBinding layoutBindingSampler =
    {
        binding: 1,
        visibility: WGPUShaderStage_FRAGMENT,
        ty: WGPUBindingType.Sampler,
        texture_dimension: WGPUTextureViewDimension.D2Array,
        multisampled: false,
        dynamic: false
    };
    WGPUBindGroupLayoutBinding layoutBindingTexture =
    {
        binding: 2,
        visibility: WGPUShaderStage_FRAGMENT,
        ty: WGPUBindingType.SampledTexture,
        texture_dimension: WGPUTextureViewDimension.D2Array,
        multisampled: false,
        dynamic: false
    };

    WGPUBindGroupLayoutBinding[] bindGroupLayoutBindings =
    [
        layoutBindingUniforms, layoutBindingSampler, layoutBindingTexture
    ];
    WGPUBindGroupLayoutDescriptor bindGroupLayoutDescriptor = WGPUBindGroupLayoutDescriptor(bindGroupLayoutBindings.ptr, bindGroupLayoutBindings.length);
    WGPUBindGroupLayoutId uniformsBindGroupLayout = wgpu_device_create_bind_group_layout(device, &bindGroupLayoutDescriptor);
    writeln("OK");

    // Vertex buffer
    writeln("Vertex buffer...");

    /*
    Vector3f[] vertices = [
        Vector3f(0.5f, 0.5f, 0.5f),
        Vector3f(-0.5f, 0.5f, 0.5f),
        Vector3f(-0.5f,-0.5f, 0.5f),
        Vector3f(0.5f,-0.5f, 0.5f), // v0,v1,v2,v3 (front)

        Vector3f(0.5f, 0.5f, 0.5f),
        Vector3f(0.5f,-0.5f, 0.5f),
        Vector3f(0.5f,-0.5f,-0.5f),
        Vector3f(0.5f, 0.5f,-0.5f), // v0,v3,v4,v5 (right)

        Vector3f(0.5f, 0.5f, 0.5f),
        Vector3f(0.5f, 0.5f,-0.5f),
        Vector3f(-0.5f, 0.5f,-0.5f),
        Vector3f(-0.5f, 0.5f, 0.5f), // v0,v5,v6,v1 (top)

        Vector3f(-0.5f, 0.5f, 0.5f),
        Vector3f(-0.5f, 0.5f,-0.5f),
        Vector3f(-0.5f,-0.5f,-0.5f),
        Vector3f(-0.5f,-0.5f, 0.5f), // v1,v6,v7,v2 (left)

        Vector3f(-0.5f,-0.5f,-0.5f),
        Vector3f(0.5f,-0.5f,-0.5f),
        Vector3f(0.5f,-0.5f, 0.5f),
        Vector3f(-0.5f,-0.5f, 0.5f), // v7,v4,v3,v2 (bottom)

        Vector3f(0.5f,-0.5f,-0.5f),
        Vector3f(-0.5f,-0.5f,-0.5f),
        Vector3f(-0.5f, 0.5f,-0.5f),
        Vector3f(0.5f, 0.5f,-0.5f)  // v4,v7,v6,v5 (back)
    ];

    Vector2f[] texcoords = [
        Vector2f(1, 0),
        Vector2f(0, 0),
        Vector2f(0, 1),
        Vector2f(1, 1), // v0,v1,v2,v3 (front)

        Vector2f(0, 0),
        Vector2f(0, 1),
        Vector2f(1, 1),
        Vector2f(1, 0), // v0,v3,v4,v5 (right)

        Vector2f(1, 1),
        Vector2f(1, 0),
        Vector2f(0, 0),
        Vector2f(0, 1), // v0,v5,v6,v1 (top)

        Vector2f(1, 0),
        Vector2f(0, 0),
        Vector2f(0, 1),
        Vector2f(1, 1), // v1,v6,v7,v2 (left)

        Vector2f(0, 1),
        Vector2f(1, 1),
        Vector2f(1, 0),
        Vector2f(0, 0), // v7,v4,v3,v2 (bottom)

        Vector2f(0, 1),
        Vector2f(1, 1),
        Vector2f(1, 0),
        Vector2f(0, 0)  // v4,v7,v6,v5 (back)
    ];

    Vector3f[] normals = [
        Vector3f(0, 0, 1),
        Vector3f(0, 0, 1),
        Vector3f(0, 0, 1),
        Vector3f(0, 0, 1), // v0,v1,v2,v3 (front)

        Vector3f(1, 0, 0),
        Vector3f(1, 0, 0),
        Vector3f(1, 0, 0),
        Vector3f(1, 0, 0), // v0,v3,v4,v5 (right)

        Vector3f(0, 1, 0),
        Vector3f(0, 1, 0),
        Vector3f(0, 1, 0),
        Vector3f(0, 1, 0), // v0,v5,v6,v1 (top)

        Vector3f(-1, 0, 0),
        Vector3f(-1, 0, 0),
        Vector3f(-1, 0, 0),
        Vector3f(-1, 0, 0), // v1,v6,v7,v2 (left)

        Vector3f(0, -1, 0),
        Vector3f(0, -1, 0),
        Vector3f(0, -1, 0),
        Vector3f(0, -1, 0), // v7,v4,v3,v2 (bottom)

        Vector3f(0, 0, -1),
        Vector3f(0, 0, -1),
        Vector3f(0, 0, -1),
        Vector3f(0, 0, -1)  // v4,v7,v6,v5 (back)
    ];

    ushort[] indices = [
        0, 1, 2,  2, 3, 0,    // v0-v1-v2, v2-v3-v0 (front)
        4, 5, 6,  6, 7, 4,    // v0-v3-v4, v4-v5-v0 (right)
        8, 9,10,  10,11, 8,   // v0-v5-v6, v6-v1-v0 (top)
        12,13,14, 14,15,12,   // v1-v6-v7, v7-v2-v1 (left)
        16,17,18, 18,19,16,   // v7-v4-v3, v3-v2-v7 (bottom)
        20,21,22, 22,23,20    // v4-v7-v6, v6-v5-v4 (back)
    ];
    */

    //GPUMesh cubeGPUMesh = gpuMesh(device, vertices, texcoords, normals, indices);

    InputStream istrm = openForInput("data/cerberus.obj");

    GPUMesh objGPUMesh = loadOBJ(device, istrm);
    WGPUBufferId vertexBuffer = objGPUMesh.attributeBuffer;
    WGPUBufferId indexBuffer = objGPUMesh.indexBuffer;
    uint numIndices = objGPUMesh.numIndices;

    writeln("OK");

    // Texture
    writeln("Textures...");
    auto imgAlbedo = loadPNG("data/cerberus-albedo.png");
    auto imgNormal = loadPNG("data/cerberus-normal.png");
    //auto imgHeight = loadPNG("data/height.png");

    WGPUTextureDescriptor textureDescriptor =
    {
        size: WGPUExtent3d(imgAlbedo.width, imgAlbedo.height, 1),
        array_layer_count: 2, //3
        mip_level_count: 1,
        sample_count: 1,
        dimension: WGPUTextureDimension.D2,
        format: WGPUTextureFormat.Rgba8Unorm,
        usage: WGPUTextureUsage_SAMPLED | WGPUTextureUsage_COPY_DST
    };
    WGPUTextureId texture = wgpu_device_create_texture(device, &textureDescriptor);

    WGPUTextureViewDescriptor textureViewDescriptor =
    {
        format: WGPUTextureFormat.Rgba8Unorm,
        dimension: WGPUTextureViewDimension.D2Array,
        aspect: WGPUTextureAspect.All,
        base_mip_level: 0,
        level_count: 1,
        base_array_layer: 0,
        array_layer_count: 2 //3
    };
    WGPUTextureViewId textureView = wgpu_texture_create_view(texture, &textureViewDescriptor);


    void imageToTexture(SuperImage img, WGPUTextureId texture, uint arrayLayer)
    {
        size_t texBufferSize = img.data.length;
        WGPUBufferDescriptor texBufferDescriptor = WGPUBufferDescriptor(texBufferSize,
            WGPUBufferUsage_STORAGE | WGPUBufferUsage_MAP_READ | WGPUBufferUsage_MAP_WRITE | WGPUBufferUsage_COPY_SRC);
        ubyte* texBufferMem;
        WGPUBufferId textureBuffer = wgpu_device_create_buffer_mapped(device, &texBufferDescriptor, &texBufferMem);
        memcpy(texBufferMem, img.data.ptr, texBufferSize);
        wgpu_buffer_unmap(textureBuffer);

        WGPUCommandEncoderDescriptor texCopyDescriptor = WGPUCommandEncoderDescriptor(0);
        WGPUCommandEncoderId texCopyCmdEncoder = wgpu_device_create_command_encoder(device, &texCopyDescriptor);
        WGPUBufferCopyView srcBufferCopyView =
        {
            buffer: textureBuffer,
            offset: 0,
            row_pitch: img.width * 4,
            image_height: img.height
        };
        WGPUTextureCopyView dstTextureCopyView =
        {
            texture: texture,
            mip_level: 0,
            array_layer: arrayLayer,
            origin: WGPUOrigin3d(0, 0, 0)
        };
        wgpu_command_encoder_copy_buffer_to_texture(texCopyCmdEncoder, &srcBufferCopyView, &dstTextureCopyView, WGPUExtent3d(img.width, img.height, 1));
        WGPUCommandBufferId texCopyCmdBuf = wgpu_command_encoder_finish(texCopyCmdEncoder, null);
        wgpu_queue_submit(queue, &texCopyCmdBuf, 1);
    }

    imageToTexture(imgAlbedo, texture, 0);
    imageToTexture(imgNormal, texture, 1);
    //imageToTexture(imgHeight, texture, 2);

    writeln("OK");

    // Sampler
    writeln("Samplers...");
    WGPUSamplerDescriptor samplerDescriptor =
    {
        address_mode_u: WGPUAddressMode.Repeat,
        address_mode_v: WGPUAddressMode.Repeat,
        address_mode_w: WGPUAddressMode.Repeat,
        mag_filter: WGPUFilterMode.Linear,
        min_filter: WGPUFilterMode.Linear,
        mipmap_filter: WGPUFilterMode.Linear,
        lod_min_clamp: 0.0f,
        lod_max_clamp: 0.0f,
        compare_function: WGPUCompareFunction.Always
    };
    WGPUSamplerId sampler = wgpu_device_create_sampler(device, &samplerDescriptor);

    writeln("OK");

    // Uniform buffer
    writeln("Uniforms...");
    struct Uniforms
    {
        Matrix4x4f modelViewMatrix;
        Matrix4x4f normalMatrix;
        Matrix4x4f projectionMatrix;
    }

    float fov = 60.0f;
    float aspectRatio = cast(float)windowWidth / cast(float)windowHeight;

    Uniforms uniforms =
    {
        modelViewMatrix: Matrix4x4f.identity,
        normalMatrix: Matrix4x4f.identity,
        projectionMatrix: perspectiveMatrix(fov, aspectRatio, 0.01f, 1000.0f)
    };

    float angle = 0.0f;

    size_t uniformsSize = uniforms.sizeof;

    WGPUBufferDescriptor bufferDescriptor = WGPUBufferDescriptor(uniformsSize,
        WGPUBufferUsage_UNIFORM |
        WGPUBufferUsage_MAP_READ |
        WGPUBufferUsage_MAP_WRITE |
        WGPUBufferUsage_COPY_SRC |
        WGPUBufferUsage_COPY_DST);

    WGPUBufferId uniformBuffer = wgpu_device_create_buffer(device, &bufferDescriptor);

    auto bufBinding = WGPUBufferBinding(uniformBuffer, 0, uniformsSize);

    WGPUBindingResource bufBindingResource;
    bufBindingResource.tag = WGPUBindingResource_Tag.Buffer;
    bufBindingResource.buffer = WGPUBindingResource_WGPUBuffer_Body(bufBinding);
    WGPUBindGroupBinding uniformsBinding = WGPUBindGroupBinding(0, bufBindingResource);

    WGPUBindingResource samplerBindingResource;
    samplerBindingResource.tag = WGPUBindingResource_Tag.Sampler;
    samplerBindingResource.sampler = WGPUBindingResource_WGPUSampler_Body(sampler);
    WGPUBindGroupBinding samplerBinding = WGPUBindGroupBinding(1, samplerBindingResource);

    WGPUBindingResource textureBindingResource;
    textureBindingResource.tag = WGPUBindingResource_Tag.TextureView;
    textureBindingResource.texture_view = WGPUBindingResource_WGPUTextureView_Body(textureView);
    WGPUBindGroupBinding textureBinding = WGPUBindGroupBinding(2, textureBindingResource);

    WGPUBindGroupBinding[] uniformBindGroupBindings =
    [
        uniformsBinding, samplerBinding, textureBinding
    ];
    WGPUBindGroupDescriptor bindGroupDescriptor = WGPUBindGroupDescriptor(uniformsBindGroupLayout, uniformBindGroupBindings.ptr, uniformBindGroupBindings.length);
    WGPUBindGroupId bindGroup = wgpu_device_create_bind_group(device, &bindGroupDescriptor);

    writeln("OK");

    // Pipeline
    writeln("Shaders...");
    uint[] vs = cast(uint[])std.file.read("data/shaders/cube.vert.spv");
    uint[] fs = cast(uint[])std.file.read("data/shaders/cube.frag.spv");

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
    WGPUVertexBufferDescriptor vertexBufferDescriptor =
    {
        stride: vertexSize + texcoordSize + normalSize,
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
        vertex_input:
        {
            index_format: WGPUIndexFormat.Uint32,
            vertex_buffers: &vertexBufferDescriptor,
            vertex_buffers_length: 1,
        },
        sample_count: 1,
        sample_mask: 1,
        alpha_to_coverage_enabled: 0
    };
    WGPURenderPipelineId renderPipeline = wgpu_device_create_render_pipeline(device, &renderPipelineDescriptor);

    writeln("OK");

    // Swapchain
    writeln("Swapchain...");
    WGPUSurfaceId surface = wgpu_create_surface_from_windows_hwnd(hinstance, hwnd);

    WGPUSwapChainId createSwapchain(uint w, uint h)
    {
        WGPUSwapChainDescriptor sd = {
            usage: WGPUTextureUsage_OUTPUT_ATTACHMENT,
            format: WGPUTextureFormat.Bgra8Unorm,
            width: w,
            height: h,
            present_mode: WGPUPresentMode.Vsync
        };
        return wgpu_device_create_swap_chain(device, surface, &sd);
    }

    WGPUSwapChainId swapchain = createSwapchain(windowWidth, windowHeight);

    // Render pass attachments
    WGPUSwapChainOutput nextTexture;
    WGPURenderPassColorAttachmentDescriptor colorAttachment =
    {
        attachment: nextTexture.view_id,
        load_op: WGPULoadOp.Clear,
        store_op: WGPUStoreOp.Store,
        clear_color: WGPUColor(0.5, 0.5, 0.5, 1.0)
    };

    WGPUTextureId depthTexture;
    WGPUTextureViewId depthAttachment;
    auto createDepthTexture(uint w, uint h)
    {
        if (depthAttachment)
        {
            writeln("wgpu_texture_view_destroy(depthAttachment)");
            wgpu_texture_view_destroy(depthAttachment);
        }
        if (depthTexture)
        {
            writeln("wgpu_texture_destroy(depthTexture)");
            wgpu_texture_destroy(depthTexture);
        }

        WGPUTextureDescriptor depthTextureDescriptor =
        {
            size: WGPUExtent3d(w, h, 1),
            array_layer_count: 1,
            mip_level_count: 1,
            sample_count: 1,
            dimension: WGPUTextureDimension.D2,
            format: WGPUTextureFormat.Depth24PlusStencil8,
            usage: WGPUTextureUsage_OUTPUT_ATTACHMENT
        };
        depthTexture = wgpu_device_create_texture(device, &depthTextureDescriptor);

        WGPUTextureViewDescriptor depthTextureViewDescriptor =
        {
            format: WGPUTextureFormat.Depth24PlusStencil8,
            dimension: WGPUTextureViewDimension.D2,
            aspect: WGPUTextureAspect.DepthOnly,
            base_mip_level: 0,
            level_count: 1,
            base_array_layer: 0,
            array_layer_count: 1
        };
        depthAttachment = wgpu_texture_create_view(depthTexture, &depthTextureViewDescriptor);

        WGPURenderPassDepthStencilAttachmentDescriptor depthStencilAttachment =
        {
            attachment: depthAttachment,
            depth_load_op: WGPULoadOp.Clear,
            depth_store_op: WGPUStoreOp.Store,
            clear_depth: 1.0f,
            stencil_load_op: WGPULoadOp.Clear,
            stencil_store_op: WGPUStoreOp.Store,
            clear_stencil: 0
        };

        return depthStencilAttachment;
    }

    auto depthStencilAttachment = createDepthTexture(windowWidth, windowHeight);

    writeln("OK");

    // Main loop
    writeln("Running...");
    bool running = true;
    SDL_Event event;
    while(running)
    {
        if (SDL_PollEvent(&event))
        {
            if (event.type == SDL_QUIT)
                running = false;
            else if (event.type == SDL_WINDOWEVENT)
            {
                if (event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED)
                {
                    windowWidth = event.window.data1;
                    windowHeight = event.window.data2;
                    writeln(windowWidth, "x", windowHeight);
                    aspectRatio = cast(float)windowWidth / cast(float)windowHeight;
                    uniforms.projectionMatrix = perspectiveMatrix(fov, aspectRatio, 0.01f, 1000.0f);
                    swapchain = createSwapchain(windowWidth, windowHeight);
                    depthStencilAttachment = createDepthTexture(windowWidth, windowHeight);
                }
            }
        }

        // Update uniforms
        angle += 0.5f;
        uniforms.modelViewMatrix =
            scaleMatrix(Vector3f(1, -1, 1)) * // Flip Y
            translationMatrix(Vector3f(0.0f, -5.0f, -15.0f)) *
            rotationMatrix(Axis.y, degtorad(angle)) *
            scaleMatrix(Vector3f(1, 1, 1));
        uniforms.normalMatrix = uniforms.modelViewMatrix.inverse.transposed;

        nextTexture = wgpu_swap_chain_get_next_texture(swapchain);
        colorAttachment.attachment = nextTexture.view_id;

        WGPUCommandEncoderDescriptor commandEncDescriptor = WGPUCommandEncoderDescriptor(0);
        WGPUCommandEncoderId cmdEncoder = wgpu_device_create_command_encoder(device, &commandEncDescriptor);

        WGPUBufferId uniformBufferTmp;
        {
            ubyte* bufferMem;
            uniformBufferTmp = wgpu_device_create_buffer_mapped(device, &bufferDescriptor, &bufferMem);
            memcpy(bufferMem, &uniforms, uniformsSize);
            wgpu_buffer_unmap(uniformBufferTmp);
            wgpu_command_encoder_copy_buffer_to_buffer(cmdEncoder, uniformBufferTmp, 0, uniformBuffer, 0, uniformsSize);
        }

        WGPURenderPassDescriptor renderPassDescriptor =
        {
            color_attachments: &colorAttachment,
            color_attachments_length: 1,
            depth_stencil_attachment: &depthStencilAttachment
        };
        WGPURenderPassId pass = wgpu_command_encoder_begin_render_pass(cmdEncoder, &renderPassDescriptor);

        wgpu_render_pass_set_pipeline(pass, renderPipeline);
        wgpu_render_pass_set_bind_group(pass, 0, bindGroup, null, 0);

        WGPUBufferAddress offset = 0;
        wgpu_render_pass_set_vertex_buffers(pass, 0, &vertexBuffer, &offset, 1);
        wgpu_render_pass_set_index_buffer(pass, indexBuffer, 0);

        wgpu_render_pass_draw_indexed(pass, numIndices, 1, 0, 0, 0);

        wgpu_render_pass_end_pass(pass);

        WGPUCommandBufferId cmdBuf = wgpu_command_encoder_finish(cmdEncoder, null);
        wgpu_queue_submit(queue, &cmdBuf, 1);
        wgpu_swap_chain_present(swapchain);

        wgpu_buffer_destroy(uniformBufferTmp);
    }

    SDL_Quit();
}
