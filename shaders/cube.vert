#version 450

layout(set = 0, binding = 0) uniform Uniforms
{
    vec4 color;
    mat4 modelViewMatrix;
    mat4 projectionMatrix;
} uniforms;

layout(location = 0) in vec3 vaVertex;
layout(location = 1) in vec2 vaTexcoord;

layout(location = 0) out Outputs
{
    vec3 color;
    vec2 texcoord;
} outputs;

out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    vec4 eyeVertex = uniforms.modelViewMatrix * vec4(vaVertex, 1.0);
    vec4 clipVertex = uniforms.projectionMatrix * eyeVertex;
    outputs.color = vaVertex * 0.5 + 0.5;
    outputs.texcoord = vaTexcoord;
    gl_Position = clipVertex;
}
