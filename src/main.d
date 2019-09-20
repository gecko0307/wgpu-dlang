module main;

import core.stdc.stdlib;
import std.stdio;
import std.file;
import std.conv;
import std.string;
import std.process;
import bindbc.sdl;
import bindbc.wgpu;

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
    
    auto window = SDL_CreateWindow(toStringz("wgpu-native"), SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, windowWidth, windowHeight, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
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
            max_bind_groups: 0
        }
    };
    WGPUDeviceId device = wgpu_adapter_request_device(adapter, &deviceDescriptor);
    
    uint[] vs = cast(uint[])std.file.read("shaders/triangle.vert.spv");
    uint[] fs = cast(uint[])std.file.read("shaders/triangle.frag.spv");
    
    WGPUShaderModuleDescriptor vsDescriptor = WGPUShaderModuleDescriptor(WGPUU32Array(vs.ptr, vs.length));
    WGPUShaderModuleId vertexShader = wgpu_device_create_shader_module(device, &vsDescriptor);
    
    WGPUShaderModuleDescriptor fsDescriptor = WGPUShaderModuleDescriptor(WGPUU32Array(fs.ptr, fs.length));
    WGPUShaderModuleId fragmentShader = wgpu_device_create_shader_module(device, &fsDescriptor);
    
    WGPUBindGroupLayoutDescriptor bindGroupLayoutDescriptor = WGPUBindGroupLayoutDescriptor(null, 0);
    WGPUBindGroupLayoutId bindGroupLayout = wgpu_device_create_bind_group_layout(device, &bindGroupLayoutDescriptor);
    
    WGPUBindGroupDescriptor bindGroupDescriptor = WGPUBindGroupDescriptor(bindGroupLayout, null, 0);
    WGPUBindGroupId bindGroup = wgpu_device_create_bind_group(device, &bindGroupDescriptor);
    
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
            vertex_buffers: null,
            vertex_buffers_length: 0,
        },
        sample_count: 1
    };
    
    WGPURenderPipelineId renderPipeline = wgpu_device_create_render_pipeline(device, &renderPipelineDescriptor);
    
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
                    swapchain = createSwapchain(windowWidth, windowHeight);
                }
            }
        }
        
        nextTexture = wgpu_swap_chain_get_next_texture(swapchain);
        WGPUCommandEncoderDescriptor commandEncDescriptor = WGPUCommandEncoderDescriptor(0);
        WGPUCommandEncoderId cmdEncoder = wgpu_device_create_command_encoder(device, &commandEncDescriptor);
        colorAttachments[0].attachment = nextTexture.view_id;
        
        WGPURenderPassDescriptor renderPassDescriptor = 
        {
            color_attachments: colorAttachments.ptr,
            color_attachments_length: 1,
            depth_stencil_attachment: null
        };
        WGPURenderPassId rpass = wgpu_command_encoder_begin_render_pass(cmdEncoder, &renderPassDescriptor);
        
        wgpu_render_pass_set_pipeline(rpass, renderPipeline);
        wgpu_render_pass_set_bind_group(rpass, 0, bindGroup, null, 0);
        wgpu_render_pass_draw(rpass, 3, 1, 0, 0);
        
        WGPUQueueId queue = wgpu_device_get_queue(device);
        wgpu_render_pass_end_pass(rpass);
        
        WGPUCommandBufferId cmdBuf = wgpu_command_encoder_finish(cmdEncoder, null);
        wgpu_queue_submit(queue, &cmdBuf, 1);
        wgpu_swap_chain_present(swapchain);
    }
    
    SDL_Quit();
}
