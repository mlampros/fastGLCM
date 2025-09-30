
## fastGLCM 1.0.4

* I removed the `SystemRequirements` from the DESCRIPTION file.


## fastGLCM 1.0.3

* I updated the `Makevars` and `Makevars.win` files by adding `-DARMA_USE_CURRENT` (see issue: https://github.com/RcppCore/RcppArmadillo/issues/476)
* I removed the `-mthreads` compilation option from the "Makevars.win" file
* I removed the "CXX_STD = CXX11" from the "Makevars" files, and the "[[Rcpp::plugins(cpp11)]]" from the "fastglcm.cpp" file due to the following NOTE from CRAN, "NOTE Specified C++11: please drop specification unless essential" (see also: https://www.tidyverse.org/blog/2023/03/cran-checks-compiled-code/#note-regarding-systemrequirements-c11)


## fastGLCM 1.0.2

* I fixed a bug in the *'fastglcm.cpp'* file related to the 'mean' and 'std' methods (if 'std' was selected 'mean' was returned too, which is not expected)


## fastGLCM 1.0.1

* I fixed two *clang-UBSAN* warnings related to the *fastglcm.cpp* file. The *first* gave: *warning: use of bitwise '&' with boolean operands* (The CRAN information page for *clang14* mentions, *"& and | apply to integer types: && and || should be used for booleans"*. The *second* was a *runtime error: nan is outside the range of representable values of type 'int'* (integers can not be NaN).
* I've added a test case for the Python code of the *fastglcm* R6 class that is tested on Github (but not on CRAN)
* I've added a github action to update the python code of the 'GLCM_Python_Code' directory based on the 'https://github.com/tzm030329/GLCM' repository regularly (every week)
* I updated the Dockerfile


## fastGLCM 1.0.0

