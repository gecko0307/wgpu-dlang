#version 450

layout(set = 0, binding = 0) uniform UniformsRenderer
{
    mat4 viewMatrix;
    mat4 invViewMatrix;
    mat4 projectionMatrix;
    vec4 view;
} renderer;

layout(set = 3, binding = 0) uniform UniformsEntity {
    mat4 modelViewMatrix;
    mat4 normalMatrix;
} entity;

layout(location = 0) in vec3 vaVertex;
layout(location = 1) in vec2 vaTexcoord;
layout(location = 2) in vec3 vaNormal;

layout(location = 0) out vec4 outPositionEye;
layout(location = 1) out vec2 outTexcoord;
layout(location = 2) out vec4 outNormalEye;

out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    vec4 eyeVertex = entity.modelViewMatrix * vec4(vaVertex, 1.0);
    outPositionEye = eyeVertex;
    outNormalEye = (entity.normalMatrix * vec4(vaNormal, 0.0));
    outTexcoord = vaTexcoord;
    gl_Position = renderer.projectionMatrix * eyeVertex;
}
