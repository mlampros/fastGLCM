

## fastGLCM 1.0.1

* I fixed a *clang14* warning related to line 296 of the fastglcm.cpp file: *warning: use of bitwise '&' with boolean operands*. The CRAN information page for *clang14* mentions: *"& and | apply to integer types: && and || should be used for booleans"*
* I've added a test case for the Python code of the *fastglcm* R6 class that is tested on Github (but not on CRAN)
* I've added a github action to update the python code of the 'GLCM_Python_Code' directory based on the 'https://github.com/tzm030329/GLCM' repository regularly (every week)


## fastGLCM 1.0.0
