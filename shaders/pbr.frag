#version 450

#define PI 3.14159265359
const float PI2 = PI * 2.0;
const float invPI = 1.0 / PI;

layout(set = 0, binding = 1) uniform sampler mySampler;
layout(set = 0, binding = 2) uniform texture2DArray myTexture;

layout(location = 0) in vec3 eyePosition;
layout(location = 1) in vec3 eyeNormal;
layout(location = 2) in vec2 texcoord;

layout(location = 0) out vec4 outColor;

mat3 cotangentFrame(in vec3 N, in vec3 p, in vec2 uv)
{
    vec3 dp1 = dFdx(p);
    vec3 dp2 = dFdy(p);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);
    vec3 dp2perp = cross(dp2, N);
    vec3 dp1perp = cross(N, dp1);
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
    float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
    return mat3(T * invmax, B * invmax, N);
}

const float parallaxScale = 0.03;
const float parallaxBias = -0.01;
vec2 parallaxMapping(in vec3 E, in vec2 uv, in float h)
{
    float currentHeight = h * parallaxScale + parallaxBias;
    return uv + (currentHeight * E.xy);
}

float blinnPhong(vec3 L, vec3 E, vec3 N, float shininess)
{
    vec3 H = normalize(E + L);
    return pow(max(0.0, dot(N, H)), shininess);
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
    float k = (r*r) / 8.0;
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

vec3 toLinear(vec3 v)
{
    return pow(v, vec3(2.2));
}

vec3 toGamma(vec3 v)
{
    return pow(v, vec3(1.0 / 2.2));
}

void main()
{
    vec3 viewDirection = normalize(-eyePosition);
    vec3 eyeNormalNorm = normalize(eyeNormal);
    mat3 tangentToEye = cotangentFrame(eyeNormalNorm, eyePosition, texcoord);
    vec3 viewDirectionTangent = normalize(viewDirection * tangentToEye);

    vec2 shiftedTexcoord = texcoord;
    vec3 tangentNormal = texture(sampler2DArray(myTexture, mySampler), vec3(shiftedTexcoord, 1)).xyz;
    tangentNormal = normalize(tangentNormal * 2.0 - 1.0);
    eyeNormalNorm = normalize(tangentToEye * tangentNormal);

    const vec3 lightEye = normalize(vec3(1.0, 1.0, 1.0));

    vec3 albedo = toLinear(texture(sampler2DArray(myTexture, mySampler), vec3(shiftedTexcoord, 0)).rgb);

    // GGX BRDF
    const float roughness = texture(sampler2DArray(myTexture, mySampler), vec3(shiftedTexcoord, 2)).r;
    const float metallic = texture(sampler2DArray(myTexture, mySampler), vec3(shiftedTexcoord, 3)).r;
    vec3 f0 = mix(vec3(0.04), albedo, metallic);
    float NL = max(dot(eyeNormalNorm, lightEye), 0.0);
    vec3 H = normalize(viewDirection + lightEye);
    float NDF = distributionGGX(eyeNormalNorm, H, roughness);
    float G = geometrySmith(eyeNormalNorm, viewDirection, lightEye, roughness);
    vec3 F = fresnelRoughness(max(dot(H, viewDirection), 0.0), f0, roughness);
    vec3 kD = (1.0 - F) * (1.0 - metallic);
    vec3 specular = (NDF * G * F) / max(4.0 * max(dot(eyeNormalNorm, viewDirection), 0.0) * NL, 0.001);
    vec3 ambient = vec3(0.3);
    vec3 radiance = albedo * ambient + (kD * albedo * invPI + specular) * NL;

    outColor = vec4(toGamma(radiance), 1.0);
}
