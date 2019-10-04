@echo off
glslangValidator shaders/cube.vert -V -o shaders/cube.vert.spv
glslangValidator shaders/cube.frag -V -o shaders/cube.frag.spv