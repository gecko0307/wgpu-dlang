/*
Copyright (c) 2017-2023 Timur Gafarov

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

module dgpu.core.vfs;

import std.string;
import std.path;
import dlib.core.memory;
import dlib.core.stream;
import dlib.container.array;
import dlib.container.dict;
import dlib.filesystem.filesystem;
import dlib.filesystem.stdfs;

class StdDirFileSystem: ReadOnlyFileSystem
{
    StdFileSystem stdfs;
    string rootDir;

    this(string rootDir)
    {
        this.rootDir = rootDir;
        stdfs = New!StdFileSystem();
    }

    bool stat(string filename, out FileStat stat)
    {
        string path = format("%s/%s", rootDir, filename);
        return stdfs.stat(path, stat);
    }

    InputStream openForInput(string filename)
    {
        string path = format("%s/%s", rootDir, filename);
        return stdfs.openForInput(path);
    }

    Directory openDir(string dir)
    {
        string path = format("%s/%s", rootDir, dir);
        return stdfs.openDir(path);
    }

    ~this()
    {
        Delete(stdfs);
    }
}

class VirtualFileSystem: ReadOnlyFileSystem
{
    Array!ReadOnlyFileSystem mounted;

    this()
    {
    }

    void mount(string dir)
    {
        StdDirFileSystem fs = New!StdDirFileSystem(dir);
        mounted.append(fs);
    }

    void mount(ReadOnlyFileSystem fs)
    {
        mounted.append(fs);
    }

    string containingDir(string filename)
    {
        string res;
        foreach(i, fs; mounted)
        {
            if (cast(StdDirFileSystem)fs)
            {
                FileStat s;
                if (fs.stat(filename, s))
                {
                    res = (cast(StdDirFileSystem)fs).rootDir;
                    break;
                }
            }
        }
        return res;
    }

    bool stat(string filename, out FileStat stat)
    {
        bool res = false;
        foreach(i, fs; mounted)
        {
            FileStat s;
            if (fs.stat(filename, s))
            {
                stat = s;
                res = true;
                break;
            }
        }

        return res;
    }

    InputStream openForInput(string filename)
    {
        foreach(i, fs; mounted)
        {
            FileStat s;
            if (fs.stat(filename, s))
            {
                return fs.openForInput(filename);
            }
        }

        return null;
    }

    Directory openDir(string path)
    {
        // TODO
        return null;
    }

    ~this()
    {
        foreach(i, fs; mounted)
            Delete(fs);
        mounted.free();
    }
}
