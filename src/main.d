/*
Copyright (c) 2021-2023 Timur Gafarov

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
module main;

import std.stdio;
import std.conv;
import std.string;
import core.stdc.string: memcpy;
import dlib.core.ownership;
import dlib.core.memory;
import dlib.math.vector;
import dlib.image.color;
import dlib.image.image;
import bindbc.wgpu;
import dgpu.core.application;
import dgpu.core.time;
import dgpu.core.gpu;
import dgpu.render.renderer;
import dgpu.render.vertexbuffer;
import dgpu.asset.scene;
import dgpu.asset.entity;
import dgpu.asset.trimesh;
import dgpu.asset.io.obj;
import dgpu.asset.image;
import dgpu.asset.texture;
import freeview;

class MyApplication: Application
{
    Renderer renderer;
    Scene scene;
    Entity eCerberus;
    FreeviewComponent view;
    
    this(uint winWidth, uint winHeight, bool fullscreen, string windowTitle, string[] args)
    {
        super(winWidth, winHeight, fullscreen, windowTitle, args);
        renderer = New!Renderer(this, this);
        scene = New!Scene(this);
        auto img = image(128, 128, 4);
        Texture defaultTexture = New!Texture(renderer.gpu, img, this);
        scene.defaultMaterial.baseColorTexture = defaultTexture;
        scene.defaultMaterial.normalTexture = defaultTexture;
        scene.defaultMaterial.roughnessMetallicTexture = defaultTexture;
        scene.activeCamera.position = vec3(0, 0, 10);
        
        SuperImage cerberusAlbedo = loadImageSTB("data/cerberus-albedo.png");
        SuperImage cerberusNormal = loadImageSTB("data/cerberus-normal.png");
        SuperImage cerberusRM = loadImageSTB("data/cerberus-roughness-metallic.png");
        
        Texture texCerberusAlbedo = New!Texture(renderer.gpu, cerberusAlbedo, this);
        Texture texCerberusNormal = New!Texture(renderer.gpu, cerberusNormal, this);
        Texture texCerberusRoughnessMetallic = New!Texture(renderer.gpu, cerberusRM, this);
        
        auto istrm = fs.openForInput("data/cerberus.obj");
        auto res = loadOBJ(istrm);
        Delete(istrm);
        
        auto mesh = res[0];
        if (mesh)
        {
            VertexBuffer cerberus = New!VertexBuffer(mesh, renderer, this);
            Delete(mesh);
            
            eCerberus = scene.createEntity();
            eCerberus.geometry = cerberus;
            eCerberus.material = scene.createMaterial();
            eCerberus.material.baseColorFactor = Color4f(1.0, 0.5, 0.0, 1.0);
            eCerberus.material.baseColorTexture = texCerberusAlbedo;
            eCerberus.material.normalTexture = texCerberusNormal;
            eCerberus.material.roughnessMetallicTexture = texCerberusRoughnessMetallic;
        }
        else
        {
            writeln(res[1]);
        }
        
        view = New!FreeviewComponent(eventManager, this);
    }
    
    override void onUpdate(Time t)
    {
        view.update(t);
        
        scene.update(t);
        scene.activeCamera.modelMatrix = view.invTransform;
        renderer.update(t);
    }
    
    override void onRender()
    {
        renderer.renderScene(scene);
    }
}

void main(string[] args)
{
    MyApplication app = New!MyApplication(1280, 720, false, "WebGPU Cerberus demo", args);
    app.run();
    Delete(app);
    writeln(allocatedMemory);
}
