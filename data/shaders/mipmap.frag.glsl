#version 450

layout(set = 0, binding = 0) uniform sampler texSampler;
layout(set = 0, binding = 1) uniform texture2D tex;

layout(location = 0) in vec2 texCoord;

layout(location = 0) out vec4 fragColor;

void main()
{
    fragColor = texture(sampler2D(tex, texSampler), texCoord);
}
