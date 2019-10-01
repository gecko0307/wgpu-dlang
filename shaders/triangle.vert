#version 450

layout(location = 0) in vec3 vaVertex;

out gl_PerVertex {
    vec4 gl_Position;
};

void main() {
    gl_Position = vec4(vaVertex, 1.0);
}
