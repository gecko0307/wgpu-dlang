# wgpu-dlang
[bindbc-wgpu](https://github.com/gecko0307/bindbc-wgpu) usage example - a cube rendering demo. Uses SDL2 for window creation and [glslangValidator](https://github.com/KhronosGroup/glslang) to compile shaders at build time. 

Warning: highly experimental! I've tested it only on 64-bit Windows so far.

[![Screenshot](screenshot.jpg)](screenshot.jpg)

## What is WebGPU?
It is a new low-level graphics and compute API for the Web that works on top of Vulkan, DirectX 12, or Metal. It exposes the generic computational facilities available in today's GPUs in a cross-platform way.

[wgpu](https://github.com/gfx-rs/wgpu) is a native WebGPU implementation in Rust that compiles to a library with C API, which can be used in any language.
