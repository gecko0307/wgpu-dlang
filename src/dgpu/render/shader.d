/*
Copyright (c) 2021-2025 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003
Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module dgpu.render.shader;

import std.string;
import std.conv;
import bindbc.wgpu;
import dlib.core.memory;
import dlib.core.ownership;
import dgpu.render.renderer;

class Shader: Owner
{
    Renderer renderer;
    string label;
    string vertexEntryPoint = "vs_main";
    string fragmentEntryPoint = "fs_main";
    
    struct Modules
    {
        WGPUShaderModule vertex;
        WGPUShaderModule fragment;
    }
    
    Modules modules;
    
    this(string vertexEntryPoint, string fragmentEntryPoint, Renderer renderer, Owner owner)
    {
        super(owner);
        label = toHash.to!string;
        this.renderer = renderer;
        this.vertexEntryPoint = vertexEntryPoint;
        this.fragmentEntryPoint = fragmentEntryPoint;
    }
    
    this(string wgslCode, string vertexEntryPoint, string fragmentEntryPoint, Renderer renderer, Owner owner)
    {
        this(vertexEntryPoint, fragmentEntryPoint, renderer, owner);
        modules.vertex = moduleFromWGSL(wgslCode);
        modules.fragment = modules.vertex;
    }
    
    this(uint[] spvCode, string vertexEntryPoint, string fragmentEntryPoint, Renderer renderer, Owner owner)
    {
        this(vertexEntryPoint, fragmentEntryPoint, renderer, owner);
        modules.vertex = moduleFromSPIRV(spvCode);
        modules.fragment = modules.vertex;
    }
    
    this(uint[] spvVertCode, string vertexEntryPoint, uint[] spvFragCode, string fragmentEntryPoint, Renderer renderer, Owner owner)
    {
        this(vertexEntryPoint, fragmentEntryPoint, renderer, owner);
        modules.vertex = moduleFromSPIRV(spvVertCode);
        modules.fragment = moduleFromSPIRV(spvFragCode);
    }
    
    WGPUShaderModule moduleFromWGSL(string wgslCode)
    {
        const(char)* shaderText = wgslCode.toStringz;
        WGPUShaderModuleWGSLDescriptor wgslDescriptor = {
            chain: {
                next: null,
                sType: WGPUSType.ShaderModuleWGSLDescriptor
            },
            code: shaderText
        };
        
        WGPUShaderModuleDescriptor shaderModuleDescriptor = {
            nextInChain: cast(const(WGPUChainedStruct)*)&wgslDescriptor,
            label: label.toStringz,
        };
        
        return wgpuDeviceCreateShaderModule(renderer.gpu.device, &shaderModuleDescriptor);
    }
    
    WGPUShaderModule moduleFromSPIRV(uint[] spvCode)
    {
        WGPUShaderModuleSPIRVDescriptor spirvDescriptor = {
            chain: {
                next: null,
                sType: WGPUSType.ShaderModuleSPIRVDescriptor
            },
            codeSize: cast(uint)spvCode.length,
            code: spvCode.ptr
        };
        
        WGPUShaderModuleDescriptor shaderModuleDescriptor = {
            nextInChain: cast(const(WGPUChainedStruct)*)&spirvDescriptor,
            label: label.toStringz,
        };
        
        return wgpuDeviceCreateShaderModule(renderer.gpu.device, &shaderModuleDescriptor);
    }
}
