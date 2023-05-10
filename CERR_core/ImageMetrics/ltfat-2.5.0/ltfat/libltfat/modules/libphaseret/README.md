#libPhaseReT
libPhaseReT is a C99 and C++11 library collecting implementations of phase 
reconstruction algorithms for complex time-frequency representations (like STFT).

## Requirements

The library depends on [libltfat](http://github.com/ltfat/libltfat).

## Instalation and usage

The following installs the library to /usr/local/lib and phaseret.h to /usr/local/include/

```
make
sudo make install
```

The path can be changed by calling

```
sudo make install PREFIX=/custom/path
```

## Documentation

Doxygen-generated documentation [webpage](http://ltfat.github.io/libphaseret).

# References

If you use this toolbox/library in your research, please cite

> Zdenek Prusa, Peter Soendergaard: TBD.

and/or relevant references found in help of the individual files.

# License
PhaseReT is distributed under terms of
[GPL3](http://www.gnu.org/licenses/gpl-3.0.en.html)
