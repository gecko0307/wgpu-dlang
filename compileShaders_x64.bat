@echo off
tools\x64\glslangValidator shaders/pbr.vert -V -o data/shaders/pbr.vert.spv
tools\x64\glslangValidator shaders/pbr.frag -V -o data/shaders/pbr.frag.spv