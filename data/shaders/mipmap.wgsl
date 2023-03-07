var<private> positions: array<vec2<f32>, 3> = array<vec2<f32>, 3>(vec2<f32>(-1.0, -1.0), vec2<f32>(-1.0, 3.0), vec2<f32>(3.0, -1.0));

struct VertexOutput
{
    @builtin(position) position: vec4<f32>,
    @location(0) texCoord: vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput
{
    var output: VertexOutput;
    output.texCoord = positions[vertexIndex] * vec2<f32>(0.5, -0.5) + vec2<f32>(0.5);
    output.position = vec4<f32>(positions[vertexIndex], 0.0, 1.0);
    return output;
}

@group(0) @binding(0) var texSampler: sampler;
@group(0) @binding(1) var tex: texture_2d<f32>;

@fragment
fn fs_main(@location(0) texCoord: vec2<f32>) -> @location(0) vec4<f32>
{
    return textureSample(tex, texSampler, texCoord);
}
