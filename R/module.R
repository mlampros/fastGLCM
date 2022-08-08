

#' inner function of 'compute_elapsed_time'
#'
#' @param secs a numeric value specifying the seconds
#' @param estimated a boolean. If TRUE then the output label becomes the 'Estimated time'
#' @return a character string showing the estimated or elapsed time
#'
#' @keywords internal

inner_elapsed_time = function(secs, estimated = FALSE) {
  tmp_hours = as.integer((secs / 60) / 60)
  tmp_hours_minutes = (secs / 60) %% 60
  tmp_seconds = secs %% 60
  est_verb = ifelse(estimated, "Estimated time: ", "Elapsed time: ")
  res_out = paste(c(est_verb, tmp_hours, " hours and ", as.integer(tmp_hours_minutes), " minutes and ", as.integer(tmp_seconds), " seconds."), collapse = "")
  return(res_out)
}


#' elapsed time in hours & minutes & seconds
#'
#' @param time_start a numeric value specifying the start time
#' @return It does not return a value but only prints the time in form of a character string in the R session
#'
#' @keywords internal

compute_elapsed_time = function(time_start) {
  t_end = proc.time()
  time_total = as.numeric((t_end - time_start)['elapsed'])
  time_ = inner_elapsed_time(time_total)
  cat(time_, "\n")
}


#' Plot multiple images
#'
#' @export
#'
#' @param list_images a list of images that should be visualized
#' @param par_ROWS an integer specifying the number of rows of the ouput plot-grid
#' @param par_COLS an integer specifying the number of columns of the output plot-grid
#' @param ... further arguments for the 'plot_multi_images' method of the 'GaborFeatureExtract' R6 class ('OpenImageR' package)
#'
#' @return it doesn't return an R object but it displays a list of input images
#'
#' @importFrom OpenImageR GaborFeatureExtract

plot_multi_images = function(list_images,
                             par_ROWS,
                             par_COLS,
                             ...) {

  return(OpenImageR::GaborFeatureExtract$public_methods$plot_multi_images(list_images, par_ROWS, par_COLS, ...))
}


#' GLCM feature texture extraction
#'
#' @param data a numeric matrix
#' @param methods a vector of character strings. One or all of the following: 'mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM', 'energy', 'max', 'entropy'
#' @param levels an integer specifying the window size. This parameter will create a mask of size \emph{levels x levels} internally
#' @param kernel_size an integer specifying the kernel size. A kernel of 1's will be created and the \emph{cv2.filter2D} filter will be utilized for the convolution
#' @param distance a numeric value specifying the pixel pair distance offsets (a 'pixel' value such as 1.0, 2.0 etc.)
#' @param angle a numeric value specifying the pixel pair angles (a 'degree' value such as 0.0, 30.0, 45.0, 90.0 etc.)
#' @param dir_save either NULL or a character string specifying a valid path to a directory where the output GLCM matrices (for the specified 'methods') will be saved. By setting this parameter to a valid directory the memory usage will be decreased.
#' @param threads an integer value specifying the number of cores to run in parallel
#' @param verbose a boolean. If TRUE then information will be printed out in the console
#'
#' @return a list consisting of one or more GLCM features
#'
#' @details
#'
#' \strong{The following are two factors which (highly probable) will increase memory usage during computations:}
#' \itemize{
#'    \item \strong{1st.} the image size (the user might have to resize the image first)
#'    \item \strong{2nd.} the 'levels' parameter. The bigger this parameter the more matrices will be initialized and more memory will be used. For instance if the 'levels' parameter equals
#'    to 8 then 8 * 8 = 64 matrices of equal size to the input image will be initialized. That means if the image has dimensions (2745 x 2745) and the image-object size is approx. 60 MB then
#'    by initializing 64 matrices the memory will increase to 3.86 GB.
#' }
#'
#' \strong{This function is an Rcpp implementation} of the python fastGLCM module. When using each function separately by utilizing all threads it's slightly faster compared to the python
#' vectorized functions, however it's a lot faster when computing all features at once.
#'
#' The \strong{dir_save} parameter allows the user to save the GLCM's as .csv files to a directory. That way the output GLCM's matrices won't be returned in the R session (reduced memory usage). However, by
#' saving the GLCM's to .csv files the computation time increases.
#'
#' @references
#' https://github.com/tzm030329/GLCM
#' @export
#' @examples
#'
#' require(fastGLCM)
#' require(OpenImageR)
#' require(utils)
#'
#' temp_dir = tempdir(check = FALSE)
#' # temp_dir
#'
#' zip_file = system.file('images', 'JAXA_Joso-City2_PAN.tif.zip', package = "fastGLCM")
#' utils::unzip(zip_file, exdir = temp_dir)
#' path_extracted = file.path(temp_dir, 'JAXA_Joso-City2_PAN.tif')
#'
#' im = readImage(path = path_extracted)
#' dim(im)
#'
#' #...............................................
#' # resize the image and adjust pixel values range
#' #...............................................
#'
#' im = resizeImage(im, 500, 500, 'nearest')
#' im = OpenImageR::norm_matrix_range(im, 0, 255)
#'
#' #---------------------------------
#' # computation of all GLCM features
#' #---------------------------------
#'
#' methods = c('mean',
#'             'std',
#'             'contrast',
#'             'dissimilarity',
#'             'homogeneity',
#'             'ASM',
#'             'energy',
#'             'max',
#'             'entropy')
#'
#' res_glcm = fastGLCM_Rcpp(data = im,
#'                          methods = methods,
#'                          levels = 8,
#'                          kernel_size = 5,
#'                          distance = 1.0,
#'                          angle = 0.0,
#'                          threads = 1)
#' # str(res_glcm)
#'
#' # plot_multi_images(list_images = res_glcm,
#' #                   par_ROWS = 2,
#' #                   par_COLS = 5,
#' #                   titles = methods)
#'
#' if (file.exists(path_extracted)) file.remove(path_extracted)

fastGLCM_Rcpp = function(data,
                         methods,
                         levels = 8,
                         kernel_size = 5,
                         distance = 1.0,
                         angle = 0.0,
                         dir_save = NULL,
                         threads = 1,
                         verbose = FALSE) {

  if (verbose) t_start = proc.time()

  if (!inherits(data, 'matrix')) stop("The 'data' parameter must be of type 'matrix'!", call. = F)
  if (!all(methods %in% c('mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM', 'energy', 'max', 'entropy'))) stop("The 'methods' parameter must be one (or more) of the following: 'mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM', 'energy', 'max', 'entropy'!", call. = F)

  obj_out = fast_GLCM(img = data,
                      methods = methods,
                      levels = levels,
                      kernel_size = kernel_size,
                      distance = distance,
                      angle = angle,
                      threads = threads,
                      dir_save = dir_save)

  if (verbose) compute_elapsed_time(time_start = t_start)

  return(obj_out)
}


#' GLCM feature texture extraction
#'
#' @export
#'
#' @docType class
#' @importFrom R6 R6Class
#' @importFrom rlang is_installed
#'
#' @section Methods:
#'
#'
#' \describe{
#'  \item{\code{fastglcm$new()}}{}
#'
#'  \item{\code{--------------}}{}
#'
#'  \item{\code{GLCM_compute()}}{}
#'
#'  \item{\code{--------------}}{}
#' }
#'
#' @usage # init <- fastglcm$new()
#' @examples
#'
#' \dontrun{
#'
#' require(fastGLCM)
#' require(OpenImageR)
#'
#' file_im = system.file('images', 'Sugar_Cane_Bolivia_PlanetNICFI.png', package = 'fastGLCM')
#' im = readImage(file_im)
#'
#' #...................................
#' # convert to gray and make sure that
#' # pixel values are between 0 and 255
#' #...................................
#'
#' im = rgb_2gray(im)
#' im = im * 255
#'
#' MIN = min(as.vector(im))
#' MAX = max(as.vector(im))
#'
#' #...............
#' # methods to use
#' #...............
#'
#' methods_py = c('mean',
#'                'std',
#'                'contrast',
#'                'dissimilarity',
#'                'homogeneity',
#'                'ASM_Energy',
#'                'max',
#'                'entropy')
#'
#' init = fastglcm$new()
#'
#' lst_glcm_py = list()
#'
#' for (item_m in methods_py) {
#'
#'   cat(paste0('Method: ', item_m), '\n')
#'
#'   res_item = init$GLCM_compute(img = im,
#'                                method = item_m,
#'                                vmin = as.integer(MIN),
#'                                vmax = as.integer(MAX),
#'                                levels = as.integer(8),
#'                                ks = as.integer(5),
#'                                distance = 1.0,
#'                                angle = 0.0)
#'
#'   lst_glcm_py[[item_m]] = res_item
#' }
#'
#' #..............................
#' # Create two different sublists
#' # for 'ASM' and 'Energy'
#' #..............................
#'
#' lst_glcm_py = append(lst_glcm_py, list(lst_glcm_py[['ASM_Energy']][[1]]), after = 5)
#' names(lst_glcm_py)[6] = 'ASM'
#'
#' lst_glcm_py = append(lst_glcm_py, list(lst_glcm_py[['ASM_Energy']][[2]]), after = 6)
#' names(lst_glcm_py)[7] = 'Energy'
#'
#' lst_glcm_py[['ASM_Energy']] = NULL
#'
#' str(lst_glcm_py)
#'
#' #.........................
#' # multi-plot of the output
#' #.........................
#'
#' plot_multi_images(list_images = lst_glcm_py,
#'                   par_ROWS = 2,
#'                   par_COLS = 5,
#'                   titles = names(lst_glcm_py))
#' }

fastglcm <- R6::R6Class("fastglcm",

                        lock_objects = FALSE,

                        public = list(

                          #' @description
                          #' Initialization method for the 'fastglcm' R6 class

                          initialize = function() {

                            message("The 'fastglcm' R6 class requires that the user has already configured Python, so that it can be used from within R!")

                            if (rlang::is_installed("reticulate")) {
                              self$MODULE = reticulate::py_run_file(file = system.file('GLCM_Python_Code', 'fast_glcm.py', package = 'fastGLCM'), convert = TRUE)
                            }
                            else {
                              self$MODULE = NULL
                            }

                            if (is.null(self$MODULE)) stop("I expect that the 'reticulate' R package is installed so that the 'fastglcm' R6 class can be used!", call. = F)
                          },

                          #' @description
                          #' The GLCM computation method to receive the results
                          #'
                          #' @param img a numeric matrix
                          #' @param method a character string specifying the method. Can be one of 'mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM_Energy', 'max' or 'entropy'
                          #' @param vmin a numeric value specifying the minimum value of the input image ( \emph{img} )
                          #' @param vmax a numeric value specifying the maximum value of the input image ( \emph{img} )
                          #' @param levels an integer specifying the window size. This parameter will create a mask of size \emph{levels x levels} internally
                          #' @param ks an integer specifying the kernel size. A kernel of 1's will be created and the \emph{cv2.filter2D} filter will be utilized for the convolution
                          #' @param distance a numeric value specifying the pixel pair distance offsets (a 'pixel' value such as 1.0, 2.0 etc.)
                          #' @param angle a numeric value specifying the pixel pair angles (a 'degree' value such as 0.0, 30.0, 45.0, 90.0 etc.)
                          #' @param verbose a boolean. If TRUE then information will be printed out in the console
                          #'
                          #' @references
                          #' https://github.com/tzm030329/GLCM
                          #' https://github.com/1044197988/Python-Image-feature-extraction
                          #'
                          #' @return a list object if the method is set to 'ASM_Energy' otherwise a numeric matrix

                          GLCM_compute = function(img,
                                                  method,
                                                  vmin = 0,
                                                  vmax = 255,
                                                  levels = 8,
                                                  ks = 5,
                                                  distance = 1.0,
                                                  angle = 0.0,
                                                  verbose = FALSE) {

                            if (verbose) t_start = proc.time()

                            if (!inherits(img, 'matrix')) stop("The input 'img' parameter must be of type matrix!", call. = F)
                            if (!method %in% c('mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM_Energy', 'max', 'entropy')) stop("The input 'method' parameter must be one of 'mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM_Energy', 'max' or 'entropy'!", call. = F)

                            args_kwargs = mget(names(formals()), sys.frame(sys.nframe()))           # see: https://stackoverflow.com/a/14398674
                            args_kwargs[['method']] = NULL                                          # remove the 'method' parameter before using the do.call() function
                            args_kwargs[['verbose']] = NULL
                            obj_out = do.call(private$method_module(method = method), args_kwargs)
                            if (verbose) compute_elapsed_time(time_start = t_start)
                            return(obj_out)
                          }
                        ),

                        private = list(

                          #.............................................
                          # switch function for the various GLCM Methods
                          #.............................................

                          method_module = function(method) {

                            switch(method,
                                   mean = {use_method = self$MODULE$fast_glcm_mean},
                                   std = {use_method = self$MODULE$fast_glcm_std},
                                   contrast = {use_method = self$MODULE$fast_glcm_contrast},
                                   dissimilarity = {use_method = self$MODULE$fast_glcm_dissimilarity},
                                   homogeneity = {use_method = self$MODULE$fast_glcm_homogeneity},
                                   ASM_Energy = {use_method = self$MODULE$fast_glcm_ASM},
                                   max = {use_method = self$MODULE$fast_glcm_max},
                                   entropy = {use_method = self$MODULE$fast_glcm_entropy},
                            )
                            return(use_method)
                          }
                        )
)

