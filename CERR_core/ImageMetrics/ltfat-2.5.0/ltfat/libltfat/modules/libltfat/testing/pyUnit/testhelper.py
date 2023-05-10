#!/usr/bin/python3
# encoding: utf-8

import os
import subprocess
from cffi import FFI

ffi = FFI()
filedir = os.path.dirname(os.path.abspath(__file__))
libpath = os.path.join(filedir, '..', '..', 'build')
libltfat = os.path.join(libpath, 'libltfat.so')
header = os.path.join(libpath, 'ltfat_flat.h')

with open(header) as f_header:
    ffi.cdef(f_header.read())

lib = ffi.dlopen(libltfat)

