@echo off
tools\x64\glslangValidator shaders/cube.vert -V -o shaders/cube.vert.spv
tools\x64\glslangValidator shaders/cube.frag -V -o shaders/cube.frag.spv