#version 450

vec2 positions[3] = vec2[3](
    vec2(-1.0, -1.0),
    vec2(-1.0, 3.0),
    vec2(3.0, -1.0)
);

layout(location = 0) out vec2 texCoord;

out gl_PerVertex
{
    vec4 gl_Position;
};

void main()
{
    texCoord = positions[gl_VertexIndex] * vec2(0.5, -0.5) + vec2(0.5);
    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
}
