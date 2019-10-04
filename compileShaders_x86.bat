@echo off
glslangValidator shaders/cube.vert -V -o data/shaders/cube.vert.spv
glslangValidator shaders/cube.frag -V -o data/shaders/cube.frag.spv