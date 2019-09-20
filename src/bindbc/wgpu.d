module bindbc.wgpu;

import bindbc.loader;

enum WGPUSupport {
    noLibrary,
    badLibrary,
    goodLibrary
}

enum WGPUMAX_BIND_GROUPS = 4;
enum WGPUMAX_COLOR_TARGETS = 4;
enum WGPUMAX_MIP_LEVELS = 16;
enum WGPUMAX_VERTEX_BUFFERS = 8;

enum WGPUAddressMode
{
    ClampToEdge = 0,
    Repeat = 1,
    MirrorRepeat = 2
}

enum WGPUBindingType
{
    UniformBuffer = 0,
    StorageBuffer = 1,
    ReadonlyStorageBuffer = 2,
    Sampler = 3,
    SampledTexture = 4,
    StorageTexture = 5
}

enum WGPUBlendFactor
{
    Zero = 0,
    One = 1,
    SrcColor = 2,
    OneMinusSrcColor = 3,
    SrcAlpha = 4,
    OneMinusSrcAlpha = 5,
    DstColor = 6,
    OneMinusDstColor = 7,
    DstAlpha = 8,
    OneMinusDstAlpha = 9,
    SrcAlphaSaturated = 10,
    BlendColor = 11,
    OneMinusBlendColor = 12
}

enum WGPUBlendOperation
{
    Add = 0,
    Subtract = 1,
    ReverseSubtract = 2,
    Min = 3,
    Max = 4
}

enum WGPUBufferMapAsyncStatus
{
    Success,
    Error,
    Unknown,
    ContextLost
}

enum WGPUCompareFunction
{
    Never = 0,
    Less = 1,
    Equal = 2,
    LessEqual = 3,
    Greater = 4,
    NotEqual = 5,
    GreaterEqual = 6,
    Always = 7
}

enum WGPUCullMode
{
    None = 0,
    Front = 1,
    Back = 2
}

enum WGPUFilterMode
{
    Nearest = 0,
    Linear = 1
}

enum WGPUFrontFace
{
    Ccw = 0,
    Cw = 1
}

enum WGPUIndexFormat
{
    Uint16 = 0,
    Uint32 = 1
}

enum WGPUInputStepMode
{
    Vertex = 0,
    Instance = 1
}

enum WGPULoadOp
{
    Clear = 0,
    Load = 1
}

enum WGPUPowerPreference
{
    Default = 0,
    LowPower = 1,
    HighPerformance = 2
}

enum WGPUPresentMode
{
    NoVsync = 0,
    Vsync = 1
}

enum WGPUPrimitiveTopology
{
    PointList = 0,
    LineList = 1,
    LineStrip = 2,
    TriangleList = 3,
    TriangleStrip = 4
}

enum WGPUStencilOperation
{
    Keep = 0,
    Zero = 1,
    Replace = 2,
    Invert = 3,
    IncrementClamp = 4,
    DecrementClamp = 5,
    IncrementWrap = 6,
    DecrementWrap = 7
}

enum WGPUStoreOp
{
    Clear = 0,
    Store = 1
}

enum WGPUTextureAspect
{
    All,
    StencilOnly,
    DepthOnly
}

enum WGPUTextureDimension
{
    D1,
    D2,
    D3
}

enum WGPUTextureFormat
{
    R8Unorm = 0,
    R8Snorm = 1,
    R8Uint = 2,
    R8Sint = 3,
    R16Unorm = 4,
    R16Snorm = 5,
    R16Uint = 6,
    R16Sint = 7,
    R16Float = 8,
    Rg8Unorm = 9,
    Rg8Snorm = 10,
    Rg8Uint = 11,
    Rg8Sint = 12,
    R32Uint = 13,
    R32Sint = 14,
    R32Float = 15,
    Rg16Unorm = 16,
    Rg16Snorm = 17,
    Rg16Uint = 18,
    Rg16Sint = 19,
    Rg16Float = 20,
    Rgba8Unorm = 21,
    Rgba8UnormSrgb = 22,
    Rgba8Snorm = 23,
    Rgba8Uint = 24,
    Rgba8Sint = 25,
    Bgra8Unorm = 26,
    Bgra8UnormSrgb = 27,
    Rgb10a2Unorm = 28,
    Rg11b10Float = 29,
    Rg32Uint = 30,
    Rg32Sint = 31,
    Rg32Float = 32,
    Rgba16Unorm = 33,
    Rgba16Snorm = 34,
    Rgba16Uint = 35,
    Rgba16Sint = 36,
    Rgba16Float = 37,
    Rgba32Uint = 38,
    Rgba32Sint = 39,
    Rgba32Float = 40,
    Depth32Float = 41,
    Depth24Plus = 42,
    Depth24PlusStencil8 = 43
}

enum WGPUTextureViewDimension
{
    D1,
    D2,
    D2Array,
    Cube,
    CubeArray,
    D3
}

enum WGPUVertexFormat
{
    Uchar2 = 1,
    Uchar4 = 3,
    Char2 = 5,
    Char4 = 7,
    Uchar2Norm = 9,
    Uchar4Norm = 11,
    Char2Norm = 14,
    Char4Norm = 16,
    Ushort2 = 18,
    Ushort4 = 20,
    Short2 = 22,
    Short4 = 24,
    Ushort2Norm = 26,
    Ushort4Norm = 28,
    Short2Norm = 30,
    Short4Norm = 32,
    Half2 = 34,
    Half4 = 36,
    Float = 37,
    Float2 = 38,
    Float3 = 39,
    Float4 = 40,
    Uint = 41,
    Uint2 = 42,
    Uint3 = 43,
    Uint4 = 44,
    Int = 45,
    Int2 = 46,
    Int3 = 47,
    Int4 = 48
}

alias WGPUId_Device_Dummy = ulong;
alias WGPUDeviceId = WGPUId_Device_Dummy;
alias WGPUId_Adapter_Dummy = ulong;
alias WGPUAdapterId = WGPUId_Adapter_Dummy;

struct WGPUExtensions
{
    bool anisotropic_filtering;
}

struct WGPULimits
{
    uint max_bind_groups;
}

struct WGPUDeviceDescriptor
{
    WGPUExtensions extensions;
    WGPULimits limits;
}

alias WGPUId_BindGroup_Dummy = ulong;
alias WGPUBindGroupId = WGPUId_BindGroup_Dummy;
alias WGPUId_Buffer_Dummy = ulong;
alias WGPUBufferId = WGPUId_Buffer_Dummy;
alias WGPUBufferAddress = ulong;
alias WGPUBufferMapReadCallback = extern(C) void function(WGPUBufferMapAsyncStatus status, const ubyte* data, ubyte* userdata);
alias WGPUBufferMapWriteCallback = extern(C) void function(WGPUBufferMapAsyncStatus status, ubyte* data, ubyte* userdata);
alias WGPUId_ComputePass_Dummy = ulong;
alias WGPUComputePassId = WGPUId_ComputePass_Dummy;
alias WGPUId_CommandBuffer_Dummy = ulong;
alias WGPUCommandBufferId = WGPUId_CommandBuffer_Dummy;
alias WGPUCommandEncoderId = WGPUCommandBufferId;

struct WGPUComputePassDescriptor
{
    uint todo;
}

alias WGPUId_RenderPass_Dummy = ulong;
alias WGPURenderPassId = WGPUId_RenderPass_Dummy;
alias WGPUId_TextureView_Dummy = ulong;
alias WGPUTextureViewId = WGPUId_TextureView_Dummy;

struct WGPUColor
{
    double r;
    double g;
    double b;
    double a;
}

enum WGPUColor_TRANSPARENT = WGPUColor(0.0, 0.0, 0.0, 0.0);
enum WGPUColor_BLACK = WGPUColor(0.0, 0.0, 0.0, 1.0);
enum WGPUColor_WHITE = WGPUColor(1.0, 1.0, 1.0, 1.0);
enum WGPUColor_RED = WGPUColor(1.0, 0.0, 0.0, 1.0);
enum WGPUColor_GREEN = WGPUColor(0.0, 1.0, 0.0, 1.0);
enum WGPUColor_BLUE = WGPUColor(0.0, 0.0, 1.0, 1.0);

struct WGPURenderPassColorAttachmentDescriptor
{
    WGPUTextureViewId attachment;
    const WGPUTextureViewId* resolve_target;
    WGPULoadOp load_op;
    WGPUStoreOp store_op;
    WGPUColor clear_color;
}

struct WGPURenderPassDepthStencilAttachmentDescriptor_TextureViewId
{
    WGPUTextureViewId attachment;
    WGPULoadOp depth_load_op;
    WGPUStoreOp depth_store_op;
    float clear_depth;
    WGPULoadOp stencil_load_op;
    WGPUStoreOp stencil_store_op;
    uint clear_stencil;
}

struct WGPURenderPassDescriptor
{
    const WGPURenderPassColorAttachmentDescriptor* color_attachments;
    size_t color_attachments_length;
    const WGPURenderPassDepthStencilAttachmentDescriptor_TextureViewId* depth_stencil_attachment;
}

struct WGPUBufferCopyView
{
    WGPUBufferId buffer;
    WGPUBufferAddress offset;
    uint row_pitch;
    uint image_height;
}

alias WGPUId_Texture_Dummy = ulong;
alias WGPUTextureId = WGPUId_Texture_Dummy;

struct WGPUOrigin3d
{
    float x;
    float y;
    float z;
}
enum WGPUOrigin3d_ZERO = WGPUOrigin3d(0.0, 0.0, 0.0);

struct WGPUTextureCopyView
{
    WGPUTextureId texture;
    uint mip_level;
    uint array_layer;
    WGPUOrigin3d origin;
}

struct WGPUExtent3d
{
    uint width;
    uint height;
    uint depth;
}

struct WGPUCommandBufferDescriptor
{
    uint todo;
}

alias WGPURawString = const char*;
alias WGPUId_ComputePipeline_Dummy = ulong;
alias WGPUComputePipelineId = WGPUId_ComputePipeline_Dummy;
alias WGPUId_Surface = ulong;
alias WGPUSurfaceId = WGPUId_Surface;
alias WGPUId_BindGroupLayout_Dummy = ulong;
alias WGPUBindGroupLayoutId = WGPUId_BindGroupLayout_Dummy;

struct WGPUBufferBinding
{
    WGPUBufferId buffer;
    WGPUBufferAddress offset;
    WGPUBufferAddress size;
}

alias WGPUId_Sampler_Dummy = ulong;
alias WGPUSamplerId = WGPUId_Sampler_Dummy;

enum WGPUBindingResource_Tag
{
    Buffer,
    Sampler,
    TextureView
}

struct WGPUBindingResource_WGPUBuffer_Body
{
    WGPUBufferBinding _0;
}

struct WGPUBindingResource_WGPUSampler_Body
{
    WGPUSamplerId _0;
}

struct WGPUBindingResource_WGPUTextureView_Body
{
    WGPUTextureViewId _0;
}

struct WGPUBindingResource
{
    WGPUBindingResource_Tag tag;
    union
    {
        WGPUBindingResource_WGPUBuffer_Body buffer;
        WGPUBindingResource_WGPUSampler_Body sampler;
        WGPUBindingResource_WGPUTextureView_Body texture_view;
    };
}

struct WGPUBindGroupBinding
{
    uint binding;
    WGPUBindingResource resource;
}

struct WGPUBindGroupDescriptor
{
    WGPUBindGroupLayoutId layout;
    const WGPUBindGroupBinding* bindings;
    size_t bindings_length;
}

alias WGPUShaderStage = uint;

enum WGPUShaderStage_NONE = 0;
enum WGPUShaderStage_VERTEX = 1;
enum WGPUShaderStage_FRAGMENT = 2;
enum WGPUShaderStage_COMPUTE = 4;

struct WGPUBindGroupLayoutBinding
{
    uint binding;
    WGPUShaderStage visibility;
    WGPUBindingType ty;
    WGPUTextureViewDimension texture_dimension;
    bool multisampled;
    bool dynamic;
}

struct WGPUBindGroupLayoutDescriptor
{
    const WGPUBindGroupLayoutBinding* bindings;
    size_t bindings_length;
}

alias WGPUBufferUsage = uint;
enum WGPUBufferUsage_MAP_READ = 1;
enum WGPUBufferUsage_MAP_WRITE = 2;
enum WGPUBufferUsage_COPY_SRC = 4;
enum WGPUBufferUsage_COPY_DST = 8;
enum WGPUBufferUsage_INDEX = 16;
enum WGPUBufferUsage_VERTEX = 32;
enum WGPUBufferUsage_UNIFORM = 64;
enum WGPUBufferUsage_STORAGE = 128;
enum WGPUBufferUsage_STORAGE_READ = 256;
enum WGPUBufferUsage_INDIRECT = 512;
enum WGPUBufferUsage_NONE = 0;

struct WGPUBufferDescriptor
{
    WGPUBufferAddress size;
    WGPUBufferUsage usage;
}

struct WGPUCommandEncoderDescriptor
{
    uint todo;
}

alias WGPUId_PipelineLayout_Dummy = ulong;
alias WGPUPipelineLayoutId = WGPUId_PipelineLayout_Dummy;
alias WGPUId_ShaderModule_Dummy = ulong;
alias WGPUShaderModuleId = WGPUId_ShaderModule_Dummy;

struct WGPUProgrammableStageDescriptor
{
    WGPUShaderModuleId _module;
    WGPURawString entry_point;
}

struct WGPUComputePipelineDescriptor
{
    WGPUPipelineLayoutId layout;
    WGPUProgrammableStageDescriptor compute_stage;
}

struct WGPUPipelineLayoutDescriptor
{
    const WGPUBindGroupLayoutId* bind_group_layouts;
    size_t bind_group_layouts_length;
}

alias WGPUId_RenderPipeline_Dummy = ulong;
alias WGPURenderPipelineId = WGPUId_RenderPipeline_Dummy;

struct WGPURasterizationStateDescriptor
{
    WGPUFrontFace front_face;
    WGPUCullMode cull_mode;
    int depth_bias;
    float depth_bias_slope_scale;
    float depth_bias_clamp;
}

struct WGPUBlendDescriptor
{
    WGPUBlendFactor src_factor;
    WGPUBlendFactor dst_factor;
    WGPUBlendOperation operation;
}

alias WGPUColorWrite = uint;
enum WGPUColorWrite_RED = 1;
enum WGPUColorWrite_GREEN = 2;
enum WGPUColorWrite_BLUE = 4;
enum WGPUColorWrite_ALPHA = 8;
enum WGPUColorWrite_COLOR = 7;
enum WGPUColorWrite_ALL = 15;

struct WGPUColorStateDescriptor
{
    WGPUTextureFormat format;
    WGPUBlendDescriptor alpha_blend;
    WGPUBlendDescriptor color_blend;
    WGPUColorWrite write_mask;
}

struct WGPUStencilStateFaceDescriptor
{
    WGPUCompareFunction compare;
    WGPUStencilOperation fail_op;
    WGPUStencilOperation depth_fail_op;
    WGPUStencilOperation pass_op;
}

struct WGPUDepthStencilStateDescriptor
{
    WGPUTextureFormat format;
    bool depth_write_enabled;
    WGPUCompareFunction depth_compare;
    WGPUStencilStateFaceDescriptor stencil_front;
    WGPUStencilStateFaceDescriptor stencil_back;
    uint stencil_read_mask;
    uint stencil_write_mask;
}

alias WGPUShaderLocation = uint;

struct WGPUVertexAttributeDescriptor 
{
    WGPUBufferAddress offset;
    WGPUVertexFormat format;
    WGPUShaderLocation shader_location;
}

struct WGPUVertexBufferDescriptor
{
    WGPUBufferAddress stride;
    WGPUInputStepMode step_mode;
    const WGPUVertexAttributeDescriptor* attributes;
    size_t attributes_length;
}

struct WGPUVertexInputDescriptor
{
    WGPUIndexFormat index_format;
    const WGPUVertexBufferDescriptor* vertex_buffers;
    size_t vertex_buffers_length;
}

struct WGPURenderPipelineDescriptor
{
    WGPUPipelineLayoutId layout;
    WGPUProgrammableStageDescriptor vertex_stage;
    const WGPUProgrammableStageDescriptor* fragment_stage;
    WGPUPrimitiveTopology primitive_topology;
    const WGPURasterizationStateDescriptor* rasterization_state;
    const WGPUColorStateDescriptor* color_states;
    size_t color_states_length;
    const WGPUDepthStencilStateDescriptor* depth_stencil_state;
    WGPUVertexInputDescriptor vertex_input;
    uint sample_count;
    uint sample_mask;
    bool alpha_to_coverage_enabled;
}

struct WGPUSamplerDescriptor
{
    WGPUAddressMode address_mode_u;
    WGPUAddressMode address_mode_v;
    WGPUAddressMode address_mode_w;
    WGPUFilterMode mag_filter;
    WGPUFilterMode min_filter;
    WGPUFilterMode mipmap_filter;
    float lod_min_clamp;
    float lod_max_clamp;
    WGPUCompareFunction compare_function;
}

struct WGPUU32Array
{
    const uint* bytes;
    size_t length;
}

struct WGPUShaderModuleDescriptor
{
    WGPUU32Array code;
}

alias WGPUId_SwapChain_Dummy = ulong;
alias WGPUSwapChainId = WGPUId_SwapChain_Dummy;

alias WGPUTextureUsage = uint;
enum WGPUTextureUsage_COPY_SRC = 1;
enum WGPUTextureUsage_COPY_DST = 2;
enum WGPUTextureUsage_SAMPLED = 4;
enum WGPUTextureUsage_STORAGE = 8;
enum WGPUTextureUsage_OUTPUT_ATTACHMENT = 16;
enum WGPUTextureUsage_NONE = 0;
enum WGPUTextureUsage_UNINITIALIZED = 65535;

struct WGPUSwapChainDescriptor
{
    WGPUTextureUsage usage;
    WGPUTextureFormat format;
    uint width;
    uint height;
    WGPUPresentMode present_mode;
}

struct WGPUTextureDescriptor
{
    WGPUExtent3d size;
    uint array_layer_count;
    uint mip_level_count;
    uint sample_count;
    WGPUTextureDimension dimension;
    WGPUTextureFormat format;
    WGPUTextureUsage usage;
}

alias WGPUQueueId = WGPUDeviceId;
alias WGPUId_RenderBundle_Dummy = ulong;
alias WGPURenderBundleId = WGPUId_RenderBundle_Dummy;
alias WGPUBackendBit = uint;

struct WGPURequestAdapterOptions
{
    WGPUPowerPreference power_preference;
    WGPUBackendBit backends;
}

struct WGPUSwapChainOutput
{
    WGPUTextureViewId view_id;
}

struct WGPUTextureViewDescriptor
{
    WGPUTextureFormat format;
    WGPUTextureViewDimension dimension;
    WGPUTextureAspect aspect;
    uint base_mip_level;
    uint level_count;
    uint base_array_layer;
    uint array_layer_count;
}

extern(C) @nogc nothrow
{
    alias da_wgpu_adapter_request_device = WGPUDeviceId function(WGPUAdapterId adapter_id, const WGPUDeviceDescriptor *desc);
    alias da_wgpu_bind_group_destroy = void function(WGPUBindGroupId bind_group_id);
    alias da_wgpu_buffer_destroy = void function(WGPUBufferId buffer_id);
    alias da_wgpu_buffer_map_read_async = void function(WGPUBufferId buffer_id, WGPUBufferAddress start, WGPUBufferAddress size, WGPUBufferMapReadCallback callback, ubyte* userdata);
    alias da_wgpu_buffer_map_write_async = void function(WGPUBufferId buffer_id,
                                     WGPUBufferAddress start,
                                     WGPUBufferAddress size,
                                     WGPUBufferMapWriteCallback callback,
                                     ubyte* userdata);
    alias da_wgpu_buffer_unmap = void function(WGPUBufferId buffer_id);
    alias da_wgpu_command_encoder_begin_compute_pass = WGPUComputePassId function(WGPUCommandEncoderId encoder_id, const WGPUComputePassDescriptor *desc);
    alias da_wgpu_command_encoder_begin_render_pass = WGPURenderPassId function(WGPUCommandEncoderId encoder_id, const WGPURenderPassDescriptor *desc);
    alias da_wgpu_command_encoder_copy_buffer_to_buffer = void function(WGPUCommandEncoderId command_encoder_id,
                                                    WGPUBufferId source,
                                                    WGPUBufferAddress source_offset,
                                                    WGPUBufferId destination,
                                                    WGPUBufferAddress destination_offset,
                                                    WGPUBufferAddress size);
    alias da_wgpu_command_encoder_copy_buffer_to_texture = void function(WGPUCommandEncoderId command_encoder_id,
                                                     const WGPUBufferCopyView* source,
                                                     const WGPUTextureCopyView* destination,
                                                     WGPUExtent3d copy_size);
    alias da_wgpu_command_encoder_copy_texture_to_buffer = void function(WGPUCommandEncoderId command_encoder_id,
                                                     const WGPUTextureCopyView* source,
                                                     const WGPUBufferCopyView* destination,
                                                     WGPUExtent3d copy_size);
    alias da_wgpu_command_encoder_copy_texture_to_texture = void function(WGPUCommandEncoderId command_encoder_id,
                                                      const WGPUTextureCopyView* source,
                                                      const WGPUTextureCopyView* destination,
                                                      WGPUExtent3d copy_size);
    alias da_wgpu_command_encoder_finish = WGPUCommandBufferId function(WGPUCommandEncoderId encoder_id,
                                                    const WGPUCommandBufferDescriptor* desc);
    alias da_wgpu_compute_pass_dispatch = void function(WGPUComputePassId pass_id, uint x, uint y, uint z);
    alias da_wgpu_compute_pass_dispatch_indirect = void function(WGPUComputePassId pass_id,
                                             WGPUBufferId indirect_buffer_id,
                                             WGPUBufferAddress indirect_offset);
    alias da_wgpu_compute_pass_end_pass = void function(WGPUComputePassId pass_id);
    alias da_wgpu_compute_pass_insert_debug_marker = void function(WGPUComputePassId _pass_id, WGPURawString _label);
    alias da_wgpu_compute_pass_pop_debug_group = void function(WGPUComputePassId _pass_id);
    alias da_wgpu_compute_pass_push_debug_group = void function(WGPUComputePassId _pass_id, WGPURawString _label);
    alias da_wgpu_compute_pass_set_bind_group = void function(WGPUComputePassId pass_id,
                                          uint index,
                                          WGPUBindGroupId bind_group_id,
                                          const WGPUBufferAddress* offsets,
                                          size_t offsets_length);
    alias da_wgpu_compute_pass_set_pipeline = void function(WGPUComputePassId pass_id, WGPUComputePipelineId pipeline_id);
    alias da_wgpu_create_surface_from_metal_layer = WGPUSurfaceId function(void *layer);
    alias da_wgpu_create_surface_from_windows_hwnd = WGPUSurfaceId function(void *_hinstance, void *hwnd);
    alias da_wgpu_create_surface_from_xlib = WGPUSurfaceId function(const void **display, ulong window);
    alias da_wgpu_device_create_bind_group = WGPUBindGroupId function(WGPUDeviceId device_id, const WGPUBindGroupDescriptor *desc);
    alias da_wgpu_device_create_bind_group_layout = WGPUBindGroupLayoutId function(WGPUDeviceId device_id, const WGPUBindGroupLayoutDescriptor *desc);
    alias da_wgpu_device_create_buffer = WGPUBufferId function(WGPUDeviceId device_id, const WGPUBufferDescriptor *desc);
    alias da_wgpu_device_create_buffer_mapped = WGPUBufferId function(WGPUDeviceId device_id,
                                              const WGPUBufferDescriptor *desc,
                                              ubyte **mapped_ptr_out);
    alias da_wgpu_device_create_command_encoder = WGPUCommandEncoderId function(WGPUDeviceId device_id, const WGPUCommandEncoderDescriptor *desc);
    alias da_wgpu_device_create_compute_pipeline = WGPUComputePipelineId function(WGPUDeviceId device_id, const WGPUComputePipelineDescriptor *desc);
    alias da_wgpu_device_create_pipeline_layout = WGPUPipelineLayoutId function(WGPUDeviceId device_id, const WGPUPipelineLayoutDescriptor *desc);
    alias da_wgpu_device_create_render_pipeline = WGPURenderPipelineId function(WGPUDeviceId device_id, const WGPURenderPipelineDescriptor *desc);
    alias da_wgpu_device_create_sampler = WGPUSamplerId function(WGPUDeviceId device_id, const WGPUSamplerDescriptor *desc);
    alias da_wgpu_device_create_shader_module = WGPUShaderModuleId function(WGPUDeviceId device_id, const WGPUShaderModuleDescriptor *desc);
    alias da_wgpu_device_create_swap_chain = WGPUSwapChainId function(WGPUDeviceId device_id,
                                              WGPUSurfaceId surface_id,
                                              const WGPUSwapChainDescriptor *desc);

    alias da_wgpu_device_create_texture = WGPUTextureId function(WGPUDeviceId device_id, const WGPUTextureDescriptor *desc);

    alias da_wgpu_device_destroy = void function(WGPUDeviceId device_id);

    alias da_wgpu_device_get_limits = void function(WGPUDeviceId _device_id, WGPULimits *limits);

    alias da_wgpu_device_get_queue = WGPUQueueId function(WGPUDeviceId device_id);
    alias da_wgpu_device_poll = void function(WGPUDeviceId device_id, bool force_wait);
    alias da_wgpu_queue_submit = void function(WGPUQueueId queue_id,
                           const WGPUCommandBufferId* command_buffers,
                           size_t command_buffers_length);
    alias da_wgpu_render_pass_draw = void function(WGPURenderPassId pass_id,
                               uint vertex_count,
                               uint instance_count,
                               uint first_vertex,
                               uint first_instance);
    alias da_wgpu_render_pass_draw_indexed = void function(WGPURenderPassId pass_id,
                                       uint index_count,
                                       uint instance_count,
                                       uint first_index,
                                       int base_vertex,
                                       uint first_instance);
    alias da_wgpu_render_pass_draw_indexed_indirect = void function(WGPURenderPassId pass_id,
                                                WGPUBufferId indirect_buffer_id,
                                                WGPUBufferAddress indirect_offset);
    alias da_wgpu_render_pass_draw_indirect = void function(WGPURenderPassId pass_id,
                                        WGPUBufferId indirect_buffer_id,
                                        WGPUBufferAddress indirect_offset);
    alias da_wgpu_render_pass_end_pass = void function(WGPURenderPassId pass_id);
    alias da_wgpu_render_pass_execute_bundles = void function(WGPURenderPassId _pass_id,
                                          const WGPURenderBundleId* _bundles,
                                          size_t _bundles_length);
    alias da_wgpu_render_pass_insert_debug_marker = void function(WGPURenderPassId _pass_id, WGPURawString _label);
    alias da_wgpu_render_pass_pop_debug_group = void function(WGPURenderPassId _pass_id);
    alias da_wgpu_render_pass_push_debug_group = void function(WGPURenderPassId _pass_id, WGPURawString _label);
    alias da_wgpu_render_pass_set_bind_group = void function(WGPURenderPassId pass_id,
                                         uint index,
                                         WGPUBindGroupId bind_group_id,
                                         const WGPUBufferAddress* offsets,
                                         size_t offsets_length);
    alias da_wgpu_render_pass_set_blend_color = void function(WGPURenderPassId pass_id, const WGPUColor* color);
    alias da_wgpu_render_pass_set_index_buffer = void function(WGPURenderPassId pass_id,
                                           WGPUBufferId buffer_id,
                                           WGPUBufferAddress offset);
    alias da_wgpu_render_pass_set_pipeline = void function(WGPURenderPassId pass_id, WGPURenderPipelineId pipeline_id);
    alias da_wgpu_render_pass_set_scissor_rect = void function(WGPURenderPassId pass_id,
                                           uint x,
                                           uint y,
                                           uint w,
                                           uint h);
    alias da_wgpu_render_pass_set_stencil_reference = void function(WGPURenderPassId pass_id, uint value);
    alias da_wgpu_render_pass_set_vertex_buffers = void function(WGPURenderPassId pass_id,
                                             uint start_slot,
                                             const WGPUBufferId* buffers,
                                             const WGPUBufferAddress* offsets,
                                             size_t length);
    alias da_wgpu_render_pass_set_viewport = void function(WGPURenderPassId pass_id,
                                       float x,
                                       float y,
                                       float w,
                                       float h,
                                       float min_depth,
                                       float max_depth);
    alias da_wgpu_request_adapter = WGPUAdapterId function(const WGPURequestAdapterOptions* desc);
    alias da_wgpu_swap_chain_get_next_texture = WGPUSwapChainOutput function(WGPUSwapChainId swap_chain_id);
    alias da_wgpu_swap_chain_present = void function(WGPUSwapChainId swap_chain_id);
    alias da_wgpu_texture_create_view = WGPUTextureViewId function(WGPUTextureId texture_id, const WGPUTextureViewDescriptor *desc);
    alias da_wgpu_texture_destroy = void function(WGPUTextureId texture_id);
    alias da_wgpu_texture_view_destroy = void function(WGPUTextureViewId texture_view_id);
}

__gshared
{
    da_wgpu_adapter_request_device wgpu_adapter_request_device;
    da_wgpu_bind_group_destroy wgpu_bind_group_destroy;
    da_wgpu_buffer_destroy wgpu_buffer_destroy;
    da_wgpu_buffer_map_read_async wgpu_buffer_map_read_async;
    da_wgpu_buffer_map_write_async wgpu_buffer_map_write_async;
    da_wgpu_buffer_unmap wgpu_buffer_unmap;
    da_wgpu_command_encoder_begin_compute_pass wgpu_command_encoder_begin_compute_pass;
    da_wgpu_command_encoder_begin_render_pass wgpu_command_encoder_begin_render_pass;
    da_wgpu_command_encoder_copy_buffer_to_buffer wgpu_command_encoder_copy_buffer_to_buffer;
    da_wgpu_command_encoder_copy_buffer_to_texture wgpu_command_encoder_copy_buffer_to_texture;
    da_wgpu_command_encoder_copy_texture_to_buffer wgpu_command_encoder_copy_texture_to_buffer;
    da_wgpu_command_encoder_copy_texture_to_texture wgpu_command_encoder_copy_texture_to_texture;
    da_wgpu_command_encoder_finish wgpu_command_encoder_finish;
    da_wgpu_compute_pass_dispatch_indirect wgpu_compute_pass_dispatch_indirect;
    da_wgpu_compute_pass_end_pass wgpu_compute_pass_end_pass;
    da_wgpu_compute_pass_insert_debug_marker wgpu_compute_pass_insert_debug_marker;
    da_wgpu_compute_pass_pop_debug_group wgpu_compute_pass_pop_debug_group;
    da_wgpu_compute_pass_push_debug_group wgpu_compute_pass_push_debug_group;
    da_wgpu_compute_pass_set_bind_group wgpu_compute_pass_set_bind_group;
    da_wgpu_compute_pass_set_pipeline wgpu_compute_pass_set_pipeline;
    da_wgpu_create_surface_from_metal_layer wgpu_create_surface_from_metal_layer;
    da_wgpu_create_surface_from_windows_hwnd wgpu_create_surface_from_windows_hwnd;
    da_wgpu_create_surface_from_xlib wgpu_create_surface_from_xlib;
    da_wgpu_device_create_bind_group wgpu_device_create_bind_group;
    da_wgpu_device_create_bind_group_layout wgpu_device_create_bind_group_layout;
    da_wgpu_device_create_buffer wgpu_device_create_buffer;
    da_wgpu_device_create_buffer_mapped wgpu_device_create_buffer_mapped;
    da_wgpu_device_create_command_encoder wgpu_device_create_command_encoder;
    da_wgpu_device_create_compute_pipeline wgpu_device_create_compute_pipeline;
    da_wgpu_device_create_pipeline_layout wgpu_device_create_pipeline_layout;
    da_wgpu_device_create_render_pipeline wgpu_device_create_render_pipeline;
    da_wgpu_device_create_sampler wgpu_device_create_sampler;
    da_wgpu_device_create_shader_module wgpu_device_create_shader_module;
    da_wgpu_device_create_swap_chain wgpu_device_create_swap_chain;
    da_wgpu_device_create_texture wgpu_device_create_texture;
    da_wgpu_device_destroy wgpu_device_destroy;
    da_wgpu_device_get_limits wgpu_device_get_limits;
    da_wgpu_device_get_queue wgpu_device_get_queue;
    da_wgpu_device_poll wgpu_device_poll;
    da_wgpu_queue_submit wgpu_queue_submit;
    da_wgpu_render_pass_draw wgpu_render_pass_draw;
    da_wgpu_render_pass_draw_indexed wgpu_render_pass_draw_indexed;
    da_wgpu_render_pass_draw_indexed_indirect wgpu_render_pass_draw_indexed_indirect;
    da_wgpu_render_pass_draw_indirect wgpu_render_pass_draw_indirect;
    da_wgpu_render_pass_end_pass wgpu_render_pass_end_pass;
    da_wgpu_render_pass_execute_bundles wgpu_render_pass_execute_bundles;
    da_wgpu_render_pass_insert_debug_marker wgpu_render_pass_insert_debug_marker;
    da_wgpu_render_pass_pop_debug_group wgpu_render_pass_pop_debug_group;
    da_wgpu_render_pass_push_debug_group wgpu_render_pass_push_debug_group;
    da_wgpu_render_pass_set_bind_group wgpu_render_pass_set_bind_group;
    da_wgpu_render_pass_set_blend_color wgpu_render_pass_set_blend_color;
    da_wgpu_render_pass_set_index_buffer wgpu_render_pass_set_index_buffer;
    da_wgpu_render_pass_set_pipeline wgpu_render_pass_set_pipeline;
    da_wgpu_render_pass_set_scissor_rect wgpu_render_pass_set_scissor_rect;
    da_wgpu_render_pass_set_stencil_reference wgpu_render_pass_set_stencil_reference;
    da_wgpu_render_pass_set_vertex_buffers wgpu_render_pass_set_vertex_buffers;
    da_wgpu_render_pass_set_viewport wgpu_render_pass_set_viewport;
    da_wgpu_request_adapter wgpu_request_adapter;
    da_wgpu_swap_chain_get_next_texture wgpu_swap_chain_get_next_texture;
    da_wgpu_swap_chain_present wgpu_swap_chain_present;
    da_wgpu_texture_create_view wgpu_texture_create_view;
    da_wgpu_texture_destroy wgpu_texture_destroy;
    da_wgpu_texture_view_destroy wgpu_texture_view_destroy;
}

private
{
    SharedLib lib;
    WGPUSupport loadedVersion;
}

void unloadWGPU()
{
    if (lib != invalidHandle)
    {
        lib.unload();
    }
}

WGPUSupport loadedWGPUVersion() { return loadedVersion; }
bool isWGPULoaded() { return lib != invalidHandle; }

WGPUSupport loadWGPU()
{
    version(Windows)
    {
        const(char)[][1] libNames =
        [
            "wgpu_native.dll"
        ];
    }
    else version(OSX)
    {
        const(char)[][1] libNames =
        [
            "/usr/local/lib/wgpu_native.dylib"
        ];
    }
    else version(Posix)
    {
        const(char)[][1] libNames =
        [
            "libwgpu_native.so"
        ];
    }
    else static assert(0, "wgpu_native is not yet supported on this platform.");

    WGPUSupport ret;
    foreach(name; libNames)
    {
        ret = loadWGPU(name.ptr);
        if (ret != WGPUSupport.noLibrary)
            break;
    }
    return ret;
}

WGPUSupport loadWGPU(const(char)* libName)
{    
    lib = load(libName);
    if(lib == invalidHandle)
    {
        return WGPUSupport.noLibrary;
    }

    auto errCount = errorCount();
    loadedVersion = WGPUSupport.badLibrary;

    lib.bindSymbol(cast(void**)&wgpu_adapter_request_device, "wgpu_adapter_request_device");
    lib.bindSymbol(cast(void**)&wgpu_bind_group_destroy, "wgpu_bind_group_destroy");
    lib.bindSymbol(cast(void**)&wgpu_buffer_destroy, "wgpu_buffer_destroy");
    lib.bindSymbol(cast(void**)&wgpu_buffer_map_read_async, "wgpu_buffer_map_read_async");
    lib.bindSymbol(cast(void**)&wgpu_buffer_map_write_async, "wgpu_buffer_map_write_async");
    lib.bindSymbol(cast(void**)&wgpu_buffer_unmap, "wgpu_buffer_unmap");
    lib.bindSymbol(cast(void**)&wgpu_command_encoder_begin_compute_pass, "wgpu_command_encoder_begin_compute_pass");
    lib.bindSymbol(cast(void**)&wgpu_command_encoder_begin_render_pass, "wgpu_command_encoder_begin_render_pass");
    lib.bindSymbol(cast(void**)&wgpu_command_encoder_copy_buffer_to_buffer, "wgpu_command_encoder_copy_buffer_to_buffer");
    lib.bindSymbol(cast(void**)&wgpu_command_encoder_copy_buffer_to_texture, "wgpu_command_encoder_copy_buffer_to_texture");
    lib.bindSymbol(cast(void**)&wgpu_command_encoder_copy_texture_to_buffer, "wgpu_command_encoder_copy_texture_to_buffer");
    lib.bindSymbol(cast(void**)&wgpu_command_encoder_copy_texture_to_texture, "wgpu_command_encoder_copy_texture_to_texture");
    lib.bindSymbol(cast(void**)&wgpu_command_encoder_finish, "wgpu_command_encoder_finish");
    lib.bindSymbol(cast(void**)&wgpu_compute_pass_dispatch_indirect, "wgpu_compute_pass_dispatch_indirect");
    lib.bindSymbol(cast(void**)&wgpu_compute_pass_end_pass, "wgpu_compute_pass_end_pass");
    lib.bindSymbol(cast(void**)&wgpu_compute_pass_insert_debug_marker, "wgpu_compute_pass_insert_debug_marker");
    lib.bindSymbol(cast(void**)&wgpu_compute_pass_pop_debug_group, "wgpu_compute_pass_pop_debug_group");
    lib.bindSymbol(cast(void**)&wgpu_compute_pass_push_debug_group, "wgpu_compute_pass_push_debug_group");
    lib.bindSymbol(cast(void**)&wgpu_compute_pass_set_bind_group, "wgpu_compute_pass_set_bind_group");
    lib.bindSymbol(cast(void**)&wgpu_compute_pass_set_pipeline, "wgpu_compute_pass_set_pipeline");
    version(OSX) 
    {
        lib.bindSymbol(cast(void**)&wgpu_create_surface_from_metal_layer, "wgpu_create_surface_from_metal_layer");
    }
    version(Windows)
    {
        lib.bindSymbol(cast(void**)&wgpu_create_surface_from_windows_hwnd, "wgpu_create_surface_from_windows_hwnd");
    }
    version(linux)
    {
        lib.bindSymbol(cast(void**)&wgpu_create_surface_from_xlib, "wgpu_create_surface_from_xlib");
    }
    lib.bindSymbol(cast(void**)&wgpu_device_create_bind_group, "wgpu_device_create_bind_group");
    lib.bindSymbol(cast(void**)&wgpu_device_create_bind_group_layout, "wgpu_device_create_bind_group_layout");
    lib.bindSymbol(cast(void**)&wgpu_device_create_buffer, "wgpu_device_create_buffer");
    lib.bindSymbol(cast(void**)&wgpu_device_create_buffer_mapped, "wgpu_device_create_buffer_mapped");
    lib.bindSymbol(cast(void**)&wgpu_device_create_command_encoder, "wgpu_device_create_command_encoder");
    lib.bindSymbol(cast(void**)&wgpu_device_create_compute_pipeline, "wgpu_device_create_compute_pipeline");
    lib.bindSymbol(cast(void**)&wgpu_device_create_pipeline_layout, "wgpu_device_create_pipeline_layout");
    lib.bindSymbol(cast(void**)&wgpu_device_create_render_pipeline, "wgpu_device_create_render_pipeline");
    lib.bindSymbol(cast(void**)&wgpu_device_create_sampler, "wgpu_device_create_sampler");
    lib.bindSymbol(cast(void**)&wgpu_device_create_shader_module, "wgpu_device_create_shader_module");
    lib.bindSymbol(cast(void**)&wgpu_device_create_swap_chain, "wgpu_device_create_swap_chain");
    lib.bindSymbol(cast(void**)&wgpu_device_create_texture, "wgpu_device_create_texture");
    lib.bindSymbol(cast(void**)&wgpu_device_destroy, "wgpu_device_destroy");
    lib.bindSymbol(cast(void**)&wgpu_device_get_limits, "wgpu_device_get_limits");
    lib.bindSymbol(cast(void**)&wgpu_device_get_queue, "wgpu_device_get_queue");
    lib.bindSymbol(cast(void**)&wgpu_device_poll, "wgpu_device_poll");
    lib.bindSymbol(cast(void**)&wgpu_queue_submit, "wgpu_queue_submit");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_draw, "wgpu_render_pass_draw");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_draw_indexed, "wgpu_render_pass_draw_indexed");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_draw_indexed_indirect, "wgpu_render_pass_draw_indexed_indirect");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_draw_indirect, "wgpu_render_pass_draw_indirect");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_end_pass, "wgpu_render_pass_end_pass");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_execute_bundles, "wgpu_render_pass_execute_bundles");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_insert_debug_marker, "wgpu_render_pass_insert_debug_marker");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_pop_debug_group, "wgpu_render_pass_pop_debug_group");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_push_debug_group, "wgpu_render_pass_push_debug_group");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_bind_group, "wgpu_render_pass_set_bind_group");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_blend_color, "wgpu_render_pass_set_blend_color");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_index_buffer, "wgpu_render_pass_set_index_buffer");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_pipeline, "wgpu_render_pass_set_pipeline");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_scissor_rect, "wgpu_render_pass_set_scissor_rect");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_stencil_reference, "wgpu_render_pass_set_stencil_reference");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_vertex_buffers, "wgpu_render_pass_set_vertex_buffers");
    lib.bindSymbol(cast(void**)&wgpu_render_pass_set_viewport, "wgpu_render_pass_set_viewport");
    lib.bindSymbol(cast(void**)&wgpu_request_adapter, "wgpu_request_adapter");
    lib.bindSymbol(cast(void**)&wgpu_swap_chain_get_next_texture, "wgpu_swap_chain_get_next_texture");
    lib.bindSymbol(cast(void**)&wgpu_swap_chain_present, "wgpu_swap_chain_present");
    lib.bindSymbol(cast(void**)&wgpu_texture_create_view, "wgpu_texture_create_view");
    lib.bindSymbol(cast(void**)&wgpu_texture_destroy, "wgpu_texture_destroy");
    lib.bindSymbol(cast(void**)&wgpu_texture_view_destroy, "wgpu_texture_view_destroy");
    
    loadedVersion = WGPUSupport.goodLibrary;

    if (errorCount() != errCount)
        return WGPUSupport.badLibrary;

    return loadedVersion;
}
