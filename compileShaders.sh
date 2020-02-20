#!/bin/sh
glslangValidator shaders/pbr.vert -V -o data/shaders/pbr.vert.spv
glslangValidator shaders/pbr.frag -V -o data/shaders/pbr.frag.spv