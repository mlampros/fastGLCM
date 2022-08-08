

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

  methods = c('mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM', 'energy', 'max', 'entropy')

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
