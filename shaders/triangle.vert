#version 450

layout(location = 0) in vec3 vaVertex;

out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    // TODO: projection matrix
    gl_Position = vec4(vaVertex.xy - 0.5, 0.0, 1.0);
}
