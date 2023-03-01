struct UniformsRenderer {
    viewMatrix: mat4x4<f32>,
    invViewMatrix: mat4x4<f32>,
    projectionMatrix: mat4x4<f32>,
    view: vec4<f32>
};

struct UniformsMaterial {
    baseColorFactor: vec4<f32>,
    pbrRoughnessMetallicFactor: vec4<f32>
};

struct UniformsEntity {
    modelViewMatrix: mat4x4<f32>,
    normalMatrix: mat4x4<f32>
};

@group(0) @binding(0) var<uniform> renderer: UniformsRenderer;

// TODO: @group(1) @binding(0) var<uniform> pass: UniformsPass;

@group(2) @binding(0) var<uniform> material: UniformsMaterial;
@group(2) @binding(1) var baseColorSampler: sampler;
@group(2) @binding(2) var baseColorTexture: texture_2d_array<f32>;
@group(2) @binding(3) var normalSampler: sampler;
@group(2) @binding(4) var normalTexture: texture_2d_array<f32>;
@group(2) @binding(5) var roughnessMetallicSampler: sampler;
@group(2) @binding(6) var roughnessMetallicTexture: texture_2d_array<f32>;

@group(3) @binding(0) var<uniform> entity: UniformsEntity;

struct VertexInput
{
    @location(0) position: vec3<f32>,
    @location(1) texcoord: vec2<f32>,
    @location(2) normal: vec3<f32>
};

struct VertexOutput
{
    @builtin(position) position: vec4<f32>,
    @location(0) positionEye: vec4<f32>,
    @location(1) texcoord: vec2<f32>,
    @location(2) normal: vec4<f32>
};

@vertex
fn vs_main(input: VertexInput) -> VertexOutput
{
    var output: VertexOutput;
    let positionEye = entity.modelViewMatrix * vec4<f32>(input.position, 1.0);
    output.position = renderer.projectionMatrix * positionEye;
    output.positionEye = positionEye;
    output.texcoord = input.texcoord;
    output.normal = entity.normalMatrix * vec4<f32>(input.normal, 0.0);
    return output;
}

fn toLinear(v: vec3<f32>) -> vec3<f32>
{
    return pow(v, vec3<f32>(2.2));
}

fn toGamma(v: vec3<f32>) -> vec3<f32>
{
    return pow(v, vec3<f32>(1.0 / 2.2));
}

fn cotangentFrame(N: vec3<f32>, p: vec3<f32>, uv: vec2<f32>) -> mat3x3<f32>
{
    let pos_dx = dpdx(p);
    let pos_dy = dpdy(p);
    let st1 = dpdx(uv);
    let st2 = dpdy(uv);
    var T = (st2.y * pos_dx - st1.y * pos_dy) / (st1.x * st2.y - st2.x * st1.y);
    T = normalize(T - N * dot(N, T));
    let B = normalize(cross(N, T));
    return mat3x3<f32>(T, B, N);
    
    /*
    // Old version
    let dp1 = dpdx(p);
    let dp2 = dpdy(p);
    let duv1 = dpdx(uv);
    let duv2 = dpdy(uv);
    let dp2perp = cross(dp2, N);
    let dp1perp = cross(N, dp1);
    let T = dp2perp * duv1.x + dp1perp * duv2.x;
    let B = dp2perp * duv1.y + dp1perp * duv2.y;
    let invmax = inverseSqrt(max(dot(T, T), dot(B, B)));
    return mat3x3<f32>(T * invmax, B * invmax, N);
    */
}

fn distributionGGX(N: vec3<f32>, H: vec3<f32>, roughness: f32) -> f32
{
    let PI: f32 = 3.14159265359;
    let a = roughness * roughness;
    let a2 = a * a;
    let NdotH = max(dot(N, H), 0.0);
    let NdotH2 = NdotH * NdotH;
    let num = a2;
    var denom = max(NdotH2 * (a2 - 1.0) + 1.0, 0.001);
    denom = PI * denom * denom;
    return num / denom;
}

fn geometrySchlickGGX(NdotV: f32, roughness: f32) -> f32
{
    let r = (roughness + 1.0);
    let k = (r*r) / 8.0;
    let num = NdotV;
    let denom = NdotV * (1.0 - k) + k;
    return num / denom;
}

fn geometrySmith(N: vec3<f32>, V: vec3<f32>, L: vec3<f32>, roughness: f32) -> f32
{
    let NdotV = max(dot(N, V), 0.0);
    let NdotL = max(dot(N, L), 0.0);
    let ggx2  = geometrySchlickGGX(NdotV, roughness);
    let ggx1  = geometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

fn fresnelRoughness(cosTheta: f32, f0: vec3<f32>, roughness: f32) -> vec3<f32>
{
    return f0 + (max(vec3<f32>(1.0 - roughness), f0) - f0) * pow(1.0 - cosTheta, 5.0);
}

struct FragmentInput
{
    @location(0) position: vec4<f32>,
    @location(1) texcoord: vec2<f32>,
    @location(2) normal: vec4<f32>
};

@fragment
fn fs_main(input: FragmentInput) -> @location(0) vec4<f32>
{
    let PI: f32 = 3.14159265359;
    let invPI: f32 = 1.0 / PI;
    
    var N = normalize(input.normal.xyz);
    let E = normalize(-input.position.xyz);
    let tangentToEye = cotangentFrame(N, input.position.xyz, input.texcoord);
    
    var tangentNormal = textureSample(normalTexture, normalSampler, input.texcoord, 0).rgb;
    tangentNormal = tangentNormal * 2.0 - 1.0;
    tangentNormal.y = -tangentNormal.y;
    N = normalize(tangentToEye * tangentNormal);
    
    let L = normalize(vec3<f32>(0.0, 0.0, 1.0));
    let lightEnergy = 5.0;
    
    let albedo = toLinear(textureSample(baseColorTexture, baseColorSampler, input.texcoord, 0).rgb);
    let roughness = textureSample(roughnessMetallicTexture, roughnessMetallicSampler, input.texcoord, 0).g;
    let metallic = textureSample(roughnessMetallicTexture, roughnessMetallicSampler, input.texcoord, 0).b;
    
    let f0 = mix(vec3<f32>(0.04), albedo, metallic);
    let NL = max(dot(N, L), 0.0);
    let H = normalize(E + L);
    let NDF = distributionGGX(N, H, roughness);
    let G = geometrySmith(N, E, L, roughness);
    let F = fresnelRoughness(max(dot(H, E), 0.0), f0, roughness);
    let kD = (1.0 - F) * (1.0 - metallic);
    let specular = (NDF * G * F) / max(4.0 * max(dot(N, E), 0.0) * NL, 0.001);
    let ambient = toLinear(vec3<f32>(0.1, 0.1, 0.1));
    let radiance = albedo * ambient + (kD * albedo * invPI + specular) * NL * lightEnergy;
    
    return vec4<f32>(toGamma(radiance), 1.0);
}
