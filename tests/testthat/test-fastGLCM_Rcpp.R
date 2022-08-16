

testthat::test_that("the pixel values of the input image are between 0 and 255, otherwise throw an error", {

  im_norm_betw_0_and_285 = OpenImageR::norm_matrix_range(data = im, min_value = 0.0, max_value = 285)

  testthat::expect_error( fastGLCM_Rcpp(data = im_norm_betw_0_and_285, methods = 'mean', levels = 8, kernel_size = 5, distance = 0.0, angle = 1.0, threads = 1) )
})


testthat::test_that("the input data (image) is of type matrix", {

  testthat::expect_error( fastGLCM_Rcpp(data = im_3d, methods = 'mean', levels = 8, kernel_size = 5, distance = 0.0, angle = 1.0, threads = 1) )
})


testthat::test_that("the input method is valid!", {

  testthat::expect_error( fastGLCM_Rcpp(data = im, methods = 'INVALID', levels = 8, kernel_size = 5, distance = 0.0, angle = 1.0, threads = 1) )
})


testthat::test_that("the input methods (all) are valid", {

  testthat::expect_error( fastGLCM_Rcpp(data = im, methods = c('mean', 'INVALID'), levels = 8, kernel_size = 5, distance = 0.0, angle = 1.0, threads = 1) )
})


testthat::test_that("the input methods return the correct output object", {

  res_all = fastGLCM_Rcpp(data = im,
                          methods = methods,
                          levels = 8,
                          kernel_size = 5,
                          distance = 0.0,
                          angle = 1.0,
                          threads = 1)

  dim_im = dim(im)
  compare_dims_output = all(as.vector(unlist(lapply(res_all, function(x) all(dim_im == dim(x))))))

  testthat::expect_true( all(names(res_all) %in% methods) & length(res_all) == length(methods) & compare_dims_output )
})


testthat::test_that("the 'fastglcm' R6 class works on Github (it's not tested on CRAN)", {

  testthat::skip_on_cran()         # skip on CRAN because it requires a Python configuration

  MIN = min(as.vector(im))
  MAX = max(as.vector(im))

  methods_py = c('mean',
                 'std',
                 'contrast',
                 'dissimilarity',
                 'homogeneity',
                 'ASM_Energy',
                 'max',
                 'entropy')

  init = fastglcm$new()

  lst_glcm_py = list()

  for (item_m in methods_py) {

    res_item = init$GLCM_compute(img = im,
                                 method = item_m,
                                 vmin = as.integer(MIN),
                                 vmax = as.integer(MAX),
                                 levels = as.integer(8),
                                 ks = as.integer(5),
                                 distance = 1.0,
                                 angle = 0.0)

    lst_glcm_py[[item_m]] = res_item
  }

  lst_glcm_py = append(lst_glcm_py, list(lst_glcm_py[['ASM_Energy']][[1]]), after = 5)
  names(lst_glcm_py)[6] = 'ASM'

  lst_glcm_py = append(lst_glcm_py, list(lst_glcm_py[['ASM_Energy']][[2]]), after = 6)
  names(lst_glcm_py)[7] = 'energy'

  lst_glcm_py[['ASM_Energy']] = NULL

  dim_im = dim(im)
  compare_dims_output = all(as.vector(unlist(lapply(lst_glcm_py, function(x) all(dim_im == dim(x))))))

  testthat::expect_true( all(names(lst_glcm_py) %in% methods) & length(lst_glcm_py) == length(methods) & compare_dims_output )
})





