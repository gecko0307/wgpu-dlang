#version 450

layout(location = 1) in vec3 color;

layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform Uniforms
{
    vec4 color;
    mat4 projectionMatrix;
} uniforms;

void main()
{
    outColor = vec4(color, 1.0);
}
