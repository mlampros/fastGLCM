
## fastGLCM 1.0.1

* I fixed two *clang-UBSAN* warnings related to the *fastglcm.cpp* file. The *first* gave: *warning: use of bitwise '&' with boolean operands* (The CRAN information page for *clang14* mentions, *"& and | apply to integer types: && and || should be used for booleans"*. The *second* was a *runtime error: nan is outside the range of representable values of type 'int'* (integers can not be NaN).
* I've added a test case for the Python code of the *fastglcm* R6 class that is tested on Github (but not on CRAN)
* I've added a github action to update the python code of the 'GLCM_Python_Code' directory based on the 'https://github.com/tzm030329/GLCM' repository regularly (every week)
* I updated the Dockerfile


## fastGLCM 1.0.0

