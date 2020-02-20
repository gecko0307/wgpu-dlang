#version 450

layout(set = 0, binding = 0) uniform Uniforms
{
    mat4 modelViewMatrix;
    mat4 normalMatrix;
    mat4 projectionMatrix;
} uniforms;

layout(location = 0) in vec3 vaVertex;
layout(location = 1) in vec2 vaTexcoord;
layout(location = 2) in vec3 vaNormal;

struct Outputs
{
    vec3 eyePosition;
    vec3 eyeNormal;
    vec2 texcoord;
};

layout(location = 0) out Outputs outputs;

out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    vec4 eyeVertex = uniforms.modelViewMatrix * vec4(vaVertex, 1.0);
    vec4 clipVertex = uniforms.projectionMatrix * eyeVertex;
    vec3 normal = (uniforms.normalMatrix * vec4(vaNormal, 0.0)).xyz;
    outputs.eyePosition = eyeVertex.xyz;
    outputs.eyeNormal = normal;
    outputs.texcoord = vaTexcoord;
    gl_Position = clipVertex;
}
