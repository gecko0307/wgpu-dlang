#version 450

#define PI 3.14159265359
const float PI2 = PI * 2.0;
const float invPI = 1.0 / PI;

// TODO: layout(set = 1, binding = 0) uniform UniformsPass;

layout(set = 2, binding = 0) uniform UniformsMaterial
{
    vec4 baseColorFactor;
    vec4 pbrRoughnessMetallicFactor;
} material;

layout(set = 2, binding = 1) uniform sampler baseColorSampler;
layout(set = 2, binding = 2) uniform texture2DArray baseColorTexture;

layout(set = 2, binding = 3) uniform sampler normalSampler;
layout(set = 2, binding = 4) uniform texture2DArray normalTexture;

layout(set = 2, binding = 5) uniform sampler roughnessMetallicSampler;
layout(set = 2, binding = 6) uniform texture2DArray roughnessMetallicTexture;

vec3 toLinear(vec3 v)
{
    return pow(v, vec3(2.2));
}

vec3 toGamma(vec3 v)
{
    return pow(v, vec3(1.0 / 2.2));
}

mat3 cotangentFrame(in vec3 N, in vec3 p, in vec2 uv)
{
    vec3 pos_dx = dFdx(p);
    vec3 pos_dy = dFdy(p);
    vec2 st1 = dFdx(uv);
    vec2 st2 = dFdy(uv);
    vec3 T = (st2.y * pos_dx - st1.y * pos_dy) / (st1.x * st2.y - st2.x * st1.y);
    T = normalize(T - N * dot(N, T));
    vec3 B = normalize(cross(N, T));
    return mat3(T, B, N);
}

float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
    float num = a2;
    float denom = max(NdotH2 * (a2 - 1.0) + 1.0, 0.001);
    denom = PI * denom * denom;
    return num / denom;
}

float geometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    return num / denom;
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = geometrySchlickGGX(NdotV, roughness);
    float ggx1  = geometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

vec3 fresnelRoughness(float cosTheta, vec3 f0, float roughness)
{
    return f0 + (max(vec3(1.0 - roughness), f0) - f0) * pow(1.0 - cosTheta, 5.0);
}

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 texCoord;
layout(location = 2) in vec4 normal;

layout(location = 0) out vec4 outColor;

void main()
{
    vec3 N = normalize(normal.xyz);
    const vec3 E = normalize(-position.xyz);
    const mat3 tangentToEye = cotangentFrame(N, position.xyz, texCoord);
    
    vec3 tangentNormal = texture(sampler2DArray(normalTexture, normalSampler), vec3(texCoord, 0)).xyz;
    tangentNormal = normalize(tangentNormal * 2.0 - 1.0);
    tangentNormal.y = -tangentNormal.y;
    N = normalize(tangentToEye * tangentNormal);

    const vec3 L = normalize(vec3(1.0, 1.0, 1.0));
    const float lightEnergy = 5.0;

    const vec3 albedo = toLinear(texture(sampler2DArray(baseColorTexture, baseColorSampler), vec3(texCoord, 0)).rgb);
    const float roughness = texture(sampler2DArray(roughnessMetallicTexture, roughnessMetallicSampler), vec3(texCoord, 0)).g;
    const float metallic = texture(sampler2DArray(roughnessMetallicTexture, roughnessMetallicSampler), vec3(texCoord, 0)).b;
    
    const vec3 f0 = mix(vec3(0.04), albedo, metallic);
    const float NL = max(dot(N, L), 0.0);
    const vec3 H = normalize(E + L);
    float NDF = distributionGGX(N, H, roughness);
    float G = geometrySmith(N, E, L, roughness);
    const vec3 F = fresnelRoughness(max(dot(H, E), 0.0), f0, roughness);
    const vec3 kD = (1.0 - F) * (1.0 - metallic);
    const vec3 specular = (NDF * G * F) / max(4.0 * max(dot(N, E), 0.0) * NL, 0.001);
    const vec3 ambient = toLinear(vec3(0.1));
    const vec3 radiance = albedo * ambient + (kD * albedo * invPI + specular) * NL * lightEnergy;

    outColor = vec4(toGamma(radiance), 1.0);
}
