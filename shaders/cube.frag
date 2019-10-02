#version 450

layout(set = 0, binding = 1) uniform sampler mySampler;
layout(set = 0, binding = 2) uniform texture2D myTexture;

struct Inputs
{
    vec3 eyePosition;
    vec3 eyeNormal;
    vec2 texcoord;
};

layout(location = 0) in Inputs inputs;

layout(location = 0) out vec4 outColor;

void main()
{
    vec3 eyeNormalNorm = normalize(inputs.eyeNormal);
    vec4 albedo = texture(sampler2D(myTexture, mySampler), inputs.texcoord);
    const vec3 lightEye = normalize(vec3(1.0, -1.0, 1.0));
    float diffuse = max(dot(eyeNormalNorm, lightEye), 0.2);
    outColor = vec4(albedo.rgb * diffuse, 1.0);
}
