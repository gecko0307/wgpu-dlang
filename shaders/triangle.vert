#version 450

out gl_PerVertex {
    vec4 gl_Position;
};

layout(location = 1) out vec3 vColor;

const vec2 positions[3] = vec2[3](
    vec2(0.0, -0.5),
    vec2(0.5, 0.5),
    vec2(-0.5, 0.5)
);

void main() {
    vec2 pos = positions[gl_VertexIndex];
    vColor = vec3(pos + 0.5, 0.0);
    gl_Position = vec4(pos, 0.0, 1.0);
}
