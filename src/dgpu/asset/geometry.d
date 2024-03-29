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
module dgpu.asset.geometry;

import dlib.core.memory;
import dlib.core.ownership;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.transformation;
import dlib.math.quaternion;
import dlib.math.utils;
import dgpu.core.time;

class Geometry: Owner
{
    vec3 position = vec3(0.0f, 0.0f, 0.0f);
    vec3 rotation = vec3(0.0f, 0.0f, 0.0f);
    vec3 scale = vec3(1.0f, 1.0f, 1.0f);
    Quaternionf orientation = Quaternionf.identity;
    mat4 modelMatrix = mat4.identity;
    
    this(Owner o)
    {
        super(o);
        position = Vector3f(0.0f, 0.0f, 0.0f);
        rotation = Quaternionf.identity;
        scale = Vector3f(1.0f, 1.0f, 1.0f);
        update(Time(0.0, 0.0));
    }
    
    void update(Time time)
    {
        orientation =
            rotationQuaternion!float(Axis.x, degtorad(rotation.x)) *
            rotationQuaternion!float(Axis.y, degtorad(rotation.y)) *
            rotationQuaternion!float(Axis.z, degtorad(rotation.z));
        modelMatrix = translationMatrix(position) * orientation.toMatrix4x4 * scaleMatrix(scale);
    }
}
