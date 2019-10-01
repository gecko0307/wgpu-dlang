#version 450

layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform Params
{
    vec4 color;
} params;

void main() {
    outColor = vec4(params.color.xyz, 1.0);
}
