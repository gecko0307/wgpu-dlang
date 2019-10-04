@echo off
tools\x64\glslangValidator shaders/cube.vert -V -o data/shaders/cube.vert.spv
tools\x64\glslangValidator shaders/cube.frag -V -o data/shaders/cube.frag.spv