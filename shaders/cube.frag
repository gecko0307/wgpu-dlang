#version 450

layout(set = 0, binding = 0) uniform Uniforms
{
    vec4 color;
    mat4 projectionMatrix;
} uniforms;

layout(set = 0, binding = 1) uniform sampler mySampler;
layout(set = 0, binding = 2) uniform texture2D myTexture;

layout(location = 0) in Inputs
{
    vec3 color;
    vec2 texcoord;
} inputs;

layout(location = 0) out vec4 outColor;

void main()
{
    vec4 tex = texture(sampler2D(myTexture, mySampler), inputs.texcoord);
    outColor = vec4(tex.rgb, 1.0);
}
