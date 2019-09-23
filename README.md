# wgpu-dlang
[wgpu](https://github.com/gfx-rs/wgpu) binding for D. Includes a port of the triangle demo from wgpu repository. Uses SDL2 for window creation and [glslangValidator](https://github.com/KhronosGroup/glslang) to compile shaders.

## What is WebGPU?
It is a new low-level graphics and compute API for the Web that works on top of Vulkan, DirectX 12, or Metal. It exposes the generic computational facilities available in today's GPUs in a cross-platform way.

[wgpu](https://github.com/gfx-rs/wgpu) is a native WebGPU implementation in Rust that compiles to a library with C API, which can be used in any language.

## Binding status
Highly experimental! I've tested it only on 64-bit Windows so far.

