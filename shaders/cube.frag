#version 450

layout(set = 0, binding = 1) uniform sampler mySampler;
layout(set = 0, binding = 2) uniform texture2DArray myTexture;

struct Inputs
{
    vec3 eyePosition;
    vec3 eyeNormal;
    vec2 texcoord;
};

layout(location = 0) in Inputs inputs;

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

void main()
{
    vec3 viewDirection = normalize(-inputs.eyePosition);
    vec3 eyeNormalNorm = normalize(inputs.eyeNormal);
    mat3 tangentToEye = cotangentFrame(eyeNormalNorm, inputs.eyePosition, inputs.texcoord);
    vec3 viewDirectionTangent = normalize(viewDirection * tangentToEye);
    
    float height = texture(sampler2DArray(myTexture, mySampler), vec3(inputs.texcoord, 2)).x;
    vec2 shiftedTexcoord = parallaxMapping(viewDirectionTangent, inputs.texcoord, height);
    vec3 tangentNormal = texture(sampler2DArray(myTexture, mySampler), vec3(shiftedTexcoord, 1)).xyz;
    tangentNormal = normalize(tangentNormal * 2.0 - 1.0);
    tangentNormal.y *= -1.0;
    eyeNormalNorm = normalize(tangentToEye * tangentNormal);
    
    vec4 albedo = texture(sampler2DArray(myTexture, mySampler), vec3(shiftedTexcoord, 0));
    
    const vec3 lightEye = normalize(vec3(1.0, -1.0, 1.0));
    float diffuse = max(dot(eyeNormalNorm, lightEye), 0.2);
    float specular = blinnPhong(lightEye, viewDirection, eyeNormalNorm, 32.0);
    const float specularity = 0.5;
    
    vec3 radiance = albedo.rgb * diffuse + specular * specularity;
    
    outColor = vec4(radiance, 1.0);
}
