# wgpu-dlang
[bindbc-wgpu](https://github.com/gecko0307/bindbc-wgpu) usage example - a minimal render engine that can load and display textured and shaded OBJ files. Uses SDL2 for window creation.

**Warning: highly experimental!** I've tested it on Windows and Linux so far. It probably should work on macOS, however has not been tested yet.

[![Screenshot](screenshot.jpg)](screenshot.jpg)

To run the application, you should install [SDL2](https://www.libsdl.org) and [wgpu-native 22.1](https://github.com/gfx-rs/wgpu-native). Under Windows, `SDL2.dll` and `wgpu_native.dll` can be copied to the application directory.

## What is WebGPU?
It is a new low-level graphics and compute API for the Web that works on top of Vulkan, DirectX 12, or Metal. It exposes the generic computational facilities available in today's GPUs in a cross-platform way.

[wgpu](https://github.com/gfx-rs/wgpu) is a native WebGPU implementation in Rust that compiles to a library with C API, which can be used in any language.
