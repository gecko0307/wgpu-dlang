/*
Copyright (c) 2020 Timur Gafarov.

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
module mesh;

import std.stdio;
import std.string;
import std.format;

import core.stdc.string;
import dlib.core.memory;
import dlib.core.stream;
import dlib.math.vector;
import dlib.geometry.trimesh;
import dlib.filesystem.stdfs;
import bindbc.wgpu;

struct WGPUMesh
{
    WGPUBufferId attributeBuffer;
    WGPUBufferId indexBuffer;
    uint numVertices;
    uint numIndices;
}

struct WGPUMeshVertexAttribute
{
    Vector3f v;
    Vector2f t;
    Vector3f n;
}

WGPUMesh wgpuMesh(WGPUDeviceId device, Vector3f[] vertices, Vector2f[] texcoords, Vector3f[] normals, uint[] indices)
{
    WGPUMeshVertexAttribute[] attributes = New!(WGPUMeshVertexAttribute[])(vertices.length);

    for (size_t i = 0; i < vertices.length; i++)
    {
        attributes[i].v = vertices[i];
        attributes[i].t = texcoords[i];
        attributes[i].n = normals[i];
    }

    WGPUBufferId attributeBuffer, indexBuffer;

    size_t attributesSize = cast(size_t)attributes.length * WGPUMeshVertexAttribute.sizeof;
    WGPUBufferDescriptor attributeBufferDescriptor = WGPUBufferDescriptor("AttributeBuffer1", attributesSize, WGPUBufferUsage.VERTEX | WGPUBufferUsage.COPY_SRC | WGPUBufferUsage.COPY_DST);
    attributeBuffer = wgpu_device_create_buffer(device, &attributeBufferDescriptor);
    auto queue = wgpu_device_get_default_queue(device);
    wgpu_queue_write_buffer(queue, attributeBuffer, 0, cast(ubyte*)attributes.ptr, attributesSize);

    size_t indicesSize = cast(size_t)indices.length * uint.sizeof;
    WGPUBufferDescriptor indexBufferDescriptor = WGPUBufferDescriptor("IndexBuffer1", indicesSize, WGPUBufferUsage.INDEX | WGPUBufferUsage.COPY_SRC | WGPUBufferUsage.COPY_DST);
    indexBuffer = wgpu_device_create_buffer(device, &indexBufferDescriptor);
    wgpu_queue_write_buffer(queue, indexBuffer, 0, cast(ubyte*)indices.ptr, indicesSize);
    
    writeln("Command encoder for writing...");
    WGPUCommandEncoderDescriptor meshBufferWriteDescriptor = WGPUCommandEncoderDescriptor("commandEncDescriptor_mesh_write");
    WGPUCommandEncoderId meshBufferWriteCmdEncoder = wgpu_device_create_command_encoder(device, &meshBufferWriteDescriptor);
    writeln("OK");

    writeln("Submit...");
    WGPUCommandBufferId meshBufferWriteCmdBuf = wgpu_command_encoder_finish(meshBufferWriteCmdEncoder, null);
    wgpu_queue_submit(queue, &meshBufferWriteCmdBuf, 1);
    writeln("OK");

    Delete(attributes);

    return WGPUMesh(attributeBuffer, indexBuffer, cast(uint)vertices.length, cast(uint)indices.length);
}

struct ObjFace
{
    uint[3] v;
    uint[3] t;
    uint[3] n;
}

WGPUMesh loadOBJ(WGPUDeviceId device, InputStream istrm)
{
    uint numVerts = 0;
    uint numNormals = 0;
    uint numTexcoords = 0;
    uint numFaces = 0;

    string fileStr = readText(istrm);
    foreach(line; lineSplitter(fileStr))
    {
        if (line.startsWith("v "))
            numVerts++;
        else if (line.startsWith("vn "))
            numNormals++;
        else if (line.startsWith("vt "))
            numTexcoords++;
        else if (line.startsWith("f "))
            numFaces++;
    }

    Vector3f[] tmpVertices;
    Vector3f[] tmpNormals;
    Vector2f[] tmpTexcoords;
    ObjFace[] tmpFaces;

    bool needGenNormals = false;

    if (!numVerts)
        writeln("Warning: OBJ file has no vertices");
    if (!numNormals)
    {
        writeln("Warning: OBJ file has no normals");
        numNormals = numVerts;
        needGenNormals = true;
    }
    if (!numTexcoords)
    {
        writeln("Warning: OBJ file has no texcoords");
        numTexcoords = numVerts;
    }

    if (numVerts)
        tmpVertices = New!(Vector3f[])(numVerts);
    if (numNormals)
        tmpNormals = New!(Vector3f[])(numNormals);
    if (numTexcoords)
        tmpTexcoords = New!(Vector2f[])(numTexcoords);
    if (numFaces)
        tmpFaces = New!(ObjFace[])(numFaces);

    tmpVertices[] = Vector3f(0, 0, 0);
    tmpNormals[] = Vector3f(0, 0, 0);
    tmpTexcoords[] = Vector2f(0, 0);

    float x, y, z;
    int v1, v2, v3, v4;
    int t1, t2, t3, t4;
    int n1, n2, n3, n4;
    uint vi = 0;
    uint ni = 0;
    uint ti = 0;
    uint fi = 0;

    bool warnAboutQuads = false;

    foreach(line; lineSplitter(fileStr))
    {
        if (line.startsWith("v "))
        {
            if (formattedRead(line, "v %s %s %s", &x, &y, &z))
            {
                tmpVertices[vi] = Vector3f(x, y, z);
                vi++;
            }
        }
        else if (line.startsWith("vn"))
        {
            if (formattedRead(line, "vn %s %s %s", &x, &y, &z))
            {
                tmpNormals[ni] = Vector3f(x, y, z);
                ni++;
            }
        }
        else if (line.startsWith("vt"))
        {
            if (formattedRead(line, "vt %s %s", &x, &y))
            {
                tmpTexcoords[ti] = Vector2f(x, -y);
                ti++;
            }
        }
        else if (line.startsWith("vp"))
        {
        }
        else if (line.startsWith("f"))
        {
            char[256] tmpStr;
            tmpStr[0..line.length] = line[];
            tmpStr[line.length] = 0;

            if (sscanf(tmpStr.ptr, "f %u/%u/%u %u/%u/%u %u/%u/%u %u/%u/%u", &v1, &t1, &n1, &v2, &t2, &n2, &v3, &t3, &n3, &v4, &t4, &n4) == 12)
            {
                tmpFaces[fi].v[0] = v1-1;
                tmpFaces[fi].v[1] = v2-1;
                tmpFaces[fi].v[2] = v3-1;

                tmpFaces[fi].t[0] = t1-1;
                tmpFaces[fi].t[1] = t2-1;
                tmpFaces[fi].t[2] = t3-1;

                tmpFaces[fi].n[0] = n1-1;
                tmpFaces[fi].n[1] = n2-1;
                tmpFaces[fi].n[2] = n3-1;

                fi++;

                warnAboutQuads = true;
            }
            if (sscanf(tmpStr.ptr, "f %u/%u/%u %u/%u/%u %u/%u/%u", &v1, &t1, &n1, &v2, &t2, &n2, &v3, &t3, &n3) == 9)
            {
                tmpFaces[fi].v[0] = v1-1;
                tmpFaces[fi].v[1] = v2-1;
                tmpFaces[fi].v[2] = v3-1;

                tmpFaces[fi].t[0] = t1-1;
                tmpFaces[fi].t[1] = t2-1;
                tmpFaces[fi].t[2] = t3-1;

                tmpFaces[fi].n[0] = n1-1;
                tmpFaces[fi].n[1] = n2-1;
                tmpFaces[fi].n[2] = n3-1;

                fi++;
            }
            else if (sscanf(tmpStr.ptr, "f %u//%u %u//%u %u//%u %u//%u", &v1, &n1, &v2, &n2, &v3, &n3, &v4, &n4) == 8)
            {
                tmpFaces[fi].v[0] = v1-1;
                tmpFaces[fi].v[1] = v2-1;
                tmpFaces[fi].v[2] = v3-1;

                tmpFaces[fi].n[0] = n1-1;
                tmpFaces[fi].n[1] = n2-1;
                tmpFaces[fi].n[2] = n3-1;

                fi++;

                warnAboutQuads = true;
            }
            else if (sscanf(tmpStr.ptr, "f %u/%u %u/%u %u/%u", &v1, &t1, &v2, &t2, &v3, &t3) == 6)
            {
                tmpFaces[fi].v[0] = v1-1;
                tmpFaces[fi].v[1] = v2-1;
                tmpFaces[fi].v[2] = v3-1;

                tmpFaces[fi].t[0] = t1-1;
                tmpFaces[fi].t[1] = t2-1;
                tmpFaces[fi].t[2] = t3-1;

                fi++;
            }
            else if (sscanf(tmpStr.ptr, "f %u//%u %u//%u %u//%u", &v1, &n1, &v2, &n2, &v3, &n3) == 6)
            {
                tmpFaces[fi].v[0] = v1-1;
                tmpFaces[fi].v[1] = v2-1;
                tmpFaces[fi].v[2] = v3-1;

                tmpFaces[fi].n[0] = n1-1;
                tmpFaces[fi].n[1] = n2-1;
                tmpFaces[fi].n[2] = n3-1;

                fi++;
            }
            else if (sscanf(tmpStr.ptr, "f %u %u %u %u", &v1, &v2, &v3, &v4) == 4)
            {
                tmpFaces[fi].v[0] = v1-1;
                tmpFaces[fi].v[1] = v2-1;
                tmpFaces[fi].v[2] = v3-1;

                fi++;

                warnAboutQuads = true;
            }
            else if (sscanf(tmpStr.ptr, "f %u %u %u", &v1, &v2, &v3) == 3)
            {
                tmpFaces[fi].v[0] = v1-1;
                tmpFaces[fi].v[1] = v2-1;
                tmpFaces[fi].v[2] = v3-1;

                fi++;
            }
            else
                assert(0);
        }
    }

    Delete(fileStr);

    if (warnAboutQuads)
        writeln("Warning: OBJ file includes quads, but loadOBJ supports only triangles");

    auto indices = New!(uint[])(tmpFaces.length * 3);
    uint numUniqueVerts = cast(uint)indices.length;
    auto vertices = New!(Vector3f[])(numUniqueVerts);
    auto normals = New!(Vector3f[])(numUniqueVerts);
    auto texcoords = New!(Vector2f[])(numUniqueVerts);

    uint index = 0;

    foreach(i, ref ObjFace f; tmpFaces)
    {
        if (numVerts)
        {
            vertices[index] = tmpVertices[f.v[0]];
            vertices[index+1] = tmpVertices[f.v[1]];
            vertices[index+2] = tmpVertices[f.v[2]];
        }
        else
        {
            vertices[index] = Vector3f(0, 0, 0);
            vertices[index+1] = Vector3f(0, 0, 0);
            vertices[index+2] = Vector3f(0, 0, 0);
        }

        if (numNormals)
        {
            normals[index] = tmpNormals[f.n[0]];
            normals[index+1] = tmpNormals[f.n[1]];
            normals[index+2] = tmpNormals[f.n[2]];
        }
        else
        {
            normals[index] = Vector3f(0, 0, 0);
            normals[index+1] = Vector3f(0, 0, 0);
            normals[index+2] = Vector3f(0, 0, 0);
        }

        if (numTexcoords)
        {
            texcoords[index] = tmpTexcoords[f.t[0]];
            texcoords[index+1] = tmpTexcoords[f.t[1]];
            texcoords[index+2] = tmpTexcoords[f.t[2]];
        }
        else
        {
            texcoords[index] = Vector2f(0, 0);
            texcoords[index+1] = Vector2f(0, 0);
            texcoords[index+2] = Vector2f(0, 0);
        }

        indices[index] = cast(uint)index;
        indices[index+1] = cast(uint)(index + 1);
        indices[index+2] = cast(uint)(index + 2);

        index += 3;
    }

    // TODO
    //if (needGenNormals)
    //    mesh.generateNormals();

    if (tmpVertices.length)
        Delete(tmpVertices);
    if (tmpNormals.length)
        Delete(tmpNormals);
    if (tmpTexcoords.length)
        Delete(tmpTexcoords);
    if (tmpFaces.length)
        Delete(tmpFaces);

    auto res = wgpuMesh(device, vertices, texcoords, normals, indices);

    Delete(indices);
    Delete(vertices);
    Delete(normals);
    Delete(texcoords);

    return res;
}
