module main;

import core.stdc.stdlib;
import core.stdc.string;
import std.stdio;
import std.file;
import std.conv;
import std.string;
import std.process;
import bindbc.sdl;
import bindbc.wgpu;

import dlib.image;
import dlib.math;

void quit(string message)
{
    writeln(message);
    core.stdc.stdlib.exit(1);
}

void main()
{
    auto sdlSupport = loadSDL();
    writeln("sdlSupport: ", sdlSupport);

    auto wgpuSupport = loadWGPU();
    writeln("wgpuSupport: ", wgpuSupport);

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

    WGPURequestAdapterOptions reqAdaptersOptions =
    {
        power_preference: WGPUPowerPreference.LowPower,
        backends: 2 | 4 | 8
    };
    WGPUAdapterId adapter = wgpu_request_adapter(&reqAdaptersOptions);

    WGPUDeviceDescriptor deviceDescriptor =
    {
        extensions:
        {
            anisotropic_filtering: false
        },
        limits:
        {
            max_bind_groups: 1
        }
    };
    WGPUDeviceId device = wgpu_adapter_request_device(adapter, &deviceDescriptor);

    WGPUBindGroupLayoutBinding layoutBinding =
    {
        binding: 0,
        visibility: WGPUShaderStage_VERTEX | WGPUShaderStage_FRAGMENT,
        ty: WGPUBindingType.UniformBuffer,
        texture_dimension: WGPUTextureViewDimension.D1,
        multisampled: false,
        dynamic: false
    };
    WGPUBindGroupLayoutDescriptor bindGroupLayoutDescriptor = WGPUBindGroupLayoutDescriptor(&layoutBinding, 1);
    WGPUBindGroupLayoutId bindGroupLayout = wgpu_device_create_bind_group_layout(device, &bindGroupLayoutDescriptor);

    // Vertex buffer
    float[12] vertices = [
        -0.5,  0.5, 0.0,
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.5,  0.5, 0.0
    ];

    ushort[6] indices = [
        0, 1, 2,
        0, 2, 3
    ];

    size_t verticesSize = vertices.length * float.sizeof;
    WGPUBufferDescriptor verticesBufferDescriptor = WGPUBufferDescriptor(verticesSize,
        WGPUBufferUsage_VERTEX | WGPUBufferUsage_MAP_READ | WGPUBufferUsage_MAP_WRITE);
    ubyte* vertexBufferMem;
    WGPUBufferId vertexBuffer = wgpu_device_create_buffer_mapped(device, &verticesBufferDescriptor, &vertexBufferMem);
    memcpy(vertexBufferMem, vertices.ptr, verticesSize);
    wgpu_buffer_unmap(vertexBuffer);

    size_t indicesSize = indices.length * ushort.sizeof;
    WGPUBufferDescriptor indicesBufferDescriptor = WGPUBufferDescriptor(indicesSize,
        WGPUBufferUsage_INDEX | WGPUBufferUsage_MAP_READ | WGPUBufferUsage_MAP_WRITE);
    ubyte* indexBufferMem;
    WGPUBufferId indexBuffer = wgpu_device_create_buffer_mapped(device, &indicesBufferDescriptor, &indexBufferMem);
    memcpy(indexBufferMem, indices.ptr, indicesSize);
    wgpu_buffer_unmap(indexBuffer);

    // Uniform buffer
    struct Uniforms
    {
        Color4f color;
        Matrix4x4f modelViewMatrix;
        Matrix4x4f projectionMatrix;
    }

    Uniforms uniforms =
    {
        color: Color4f(1.0f, 0.5f, 0.0f, 0.0f),
        modelViewMatrix: Matrix4x4f.identity,
        projectionMatrix: orthoMatrix(0.0f, windowWidth, windowHeight, 0.0f, -1000.0f, 1000.0f)
    };

    float angle = 0.0f;
    float forward = 1.0f;

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
    WGPUBindGroupBinding binding = WGPUBindGroupBinding(0, bufBindingResource);
    WGPUBindGroupDescriptor bindGroupDescriptor = WGPUBindGroupDescriptor(bindGroupLayout, &binding, 1);
    WGPUBindGroupId bindGroup = wgpu_device_create_bind_group(device, &bindGroupDescriptor);

    // Pipeline
    uint[] vs = cast(uint[])std.file.read("shaders/triangle.vert.spv");
    uint[] fs = cast(uint[])std.file.read("shaders/triangle.frag.spv");

    WGPUShaderModuleDescriptor vsDescriptor = WGPUShaderModuleDescriptor(WGPUU32Array(vs.ptr, vs.length));
    WGPUShaderModuleId vertexShader = wgpu_device_create_shader_module(device, &vsDescriptor);

    WGPUShaderModuleDescriptor fsDescriptor = WGPUShaderModuleDescriptor(WGPUU32Array(fs.ptr, fs.length));
    WGPUShaderModuleId fragmentShader = wgpu_device_create_shader_module(device, &fsDescriptor);

    WGPUBindGroupLayoutId[1] bindGroupLayouts = [bindGroupLayout];
    WGPUPipelineLayoutDescriptor pipelineLayoutDescriptor = WGPUPipelineLayoutDescriptor(bindGroupLayouts.ptr, bindGroupLayouts.length);
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

    WGPUVertexAttributeDescriptor attribute =
    {
        offset: 0,
        format: WGPUVertexFormat.Float3,
        shader_location: 0
    };

    WGPUVertexBufferDescriptor vertexBufferDescriptor =
    {
        stride: float.sizeof * 3,
        step_mode: WGPUInputStepMode.Vertex,
        attributes: &attribute,
        attributes_length: 1
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
        depth_stencil_state: null,
        vertex_input:
        {
            index_format: WGPUIndexFormat.Uint16,
            vertex_buffers: &vertexBufferDescriptor,
            vertex_buffers_length: 1,
        },
        sample_count: 1
    };

    WGPURenderPipelineId renderPipeline = wgpu_device_create_render_pipeline(device, &renderPipelineDescriptor);

    // Swapchain
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

    WGPUSwapChainOutput nextTexture;
    WGPURenderPassColorAttachmentDescriptor[1] colorAttachments =
    [
        {
            attachment: nextTexture.view_id,
            load_op: WGPULoadOp.Clear,
            store_op: WGPUStoreOp.Store,
            clear_color: WGPUColor(0.5, 0.5, 0.5, 1.0)
        }
    ];

    // Main loop
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
                    uniforms.projectionMatrix = orthoMatrix(0.0f, windowWidth, windowHeight, 0.0f, -1000.0f, 1000.0f);
                    swapchain = createSwapchain(windowWidth, windowHeight);
                }
            }
        }

        nextTexture = wgpu_swap_chain_get_next_texture(swapchain);
        WGPUCommandEncoderDescriptor commandEncDescriptor = WGPUCommandEncoderDescriptor(0);
        WGPUCommandEncoderId cmdEncoder = wgpu_device_create_command_encoder(device, &commandEncDescriptor);
        colorAttachments[0].attachment = nextTexture.view_id;

        uniforms.color.b += forward * 0.01f;
        if (forward > 0.0f)
        {
            if (uniforms.color.b > 1.0f) { forward = -1; }
        }
        else
        {
            if (uniforms.color.b < 0.0f) { forward = 1; }
        }
        WGPUBufferId uniformBufferTmp;
        {
            ubyte* bufferMem;
            uniformBufferTmp = wgpu_device_create_buffer_mapped(device, &bufferDescriptor, &bufferMem);
            memcpy(bufferMem, &uniforms, uniformsSize);
            wgpu_buffer_unmap(uniformBufferTmp);
            wgpu_command_encoder_copy_buffer_to_buffer(cmdEncoder, uniformBufferTmp, 0, uniformBuffer, 0, uniformsSize);
        }

        angle += 1.0f;
        uniforms.modelViewMatrix =
            translationMatrix(Vector3f(windowWidth * 0.5f, windowHeight * 0.5f, 0.0f)) *
            rotationMatrix(Axis.z, degtorad(angle)) *
            scaleMatrix(Vector3f(200.0f, 200.0f, 200.0f));

        WGPURenderPassDescriptor renderPassDescriptor =
        {
            color_attachments: colorAttachments.ptr,
            color_attachments_length: 1,
            depth_stencil_attachment: null
        };
        WGPURenderPassId pass = wgpu_command_encoder_begin_render_pass(cmdEncoder, &renderPassDescriptor);

        wgpu_render_pass_set_pipeline(pass, renderPipeline);
        wgpu_render_pass_set_bind_group(pass, 0, bindGroup, null, 0);

        size_t offset = 0;
        wgpu_render_pass_set_vertex_buffers(pass, 0, &vertexBuffer, &offset, 1);
        wgpu_render_pass_set_index_buffer(pass, indexBuffer, 0);

        wgpu_render_pass_draw_indexed(pass, 6, 1, 0, 0, 0);

        WGPUQueueId queue = wgpu_device_get_queue(device);
        wgpu_render_pass_end_pass(pass);

        WGPUCommandBufferId cmdBuf = wgpu_command_encoder_finish(cmdEncoder, null);
        wgpu_queue_submit(queue, &cmdBuf, 1);
        wgpu_swap_chain_present(swapchain);

        wgpu_buffer_destroy(uniformBufferTmp);
    }

    SDL_Quit();
}
