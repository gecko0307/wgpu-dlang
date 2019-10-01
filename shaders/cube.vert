#version 450

layout(location = 0) in vec3 vaVertex;

layout(binding = 0) uniform Uniforms
{
    vec4 color;
    mat4 modelViewMatrix;
    mat4 projectionMatrix;
} uniforms;

layout(location = 1) out vec3 color;

out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    vec4 eyeVertex = uniforms.modelViewMatrix * vec4(vaVertex, 1.0);
    vec4 clipVertex = uniforms.projectionMatrix * eyeVertex;
    color = vaVertex * 0.5 + 0.5;
    gl_Position = clipVertex;
}
