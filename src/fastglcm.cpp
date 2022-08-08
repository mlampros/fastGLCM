# include <RcppArmadillo.h>
# include <OpenImageRheader.h>
// [[Rcpp::depends("RcppArmadillo")]]
// [[Rcpp::plugins(openmp)]]
// [[Rcpp::depends(OpenImageR)]]
// [[Rcpp::plugins(cpp11)]]

#include <cstdlib>

#ifdef WIN32
std::string os_separator = "\\";
#else
std::string os_separator =  "/";
#endif


#ifdef _OPENMP
#include <omp.h>
#endif


// this function returns the same output as the "np.digitize(img, bins) - 1" function if 'img' is a matrix
// the input matrix MUST be in range between 0 and 256
//
// It also returns the indices of the bins to which each value of the input matrix belongs
// The function is different from the "histc()" Armadillo function because it returns a matrix with the
// same dimensions as the input matrix, whereas in the "histc()" Armadillo function one dimension of the
// output matrix equals the number of bins (either in row or column depending on the "dim" parameter)
//
// The weblink https://stackoverflow.com/a/32765547 discusses what is the corresponding function for "np.digitize()"
// which is required for "fast_glcm()". In RcppArmadillo the " histc()" function is similar to the matlab one.
//

// [[Rcpp::export]]
arma::mat digitize(arma::Mat<int> x, int bins, int min = 0, int max = 256) {
// arma::Mat<int> digitize(arma::Mat<int> x, int bins, int min = 0, int max = 256) {

  arma::Row<int> res_linsp = arma::linspace<arma::Row<int>>(min, max, bins);
  arma::Row<int> res_bins(max);
  res_bins.fill(arma::datum::nan);

  for (unsigned int i = 0; i < res_linsp.n_elem - 1; i++) {
    res_bins.subvec(res_linsp(i), res_linsp(i+1) - 1).fill(i);
  }

  // arma::Mat<int> mt_bins(x.n_rows, x.n_cols, arma::fill::zeros);
  arma::mat mt_bins(x.n_rows, x.n_cols, arma::fill::zeros);

  for (unsigned int k = 0; k < x.n_rows; k++) {
    for (unsigned int j = 0; j < x.n_cols; j++) {
      mt_bins(k,j) = res_bins(x(k,j));
    }
  }

  return mt_bins;
}


// degrees to radians function
//

// [[Rcpp::export]]
double deg2rad(double x) {
  return (x / (180.0 / arma::datum::pi));
}


// Limitations compared to the cv2.Filter2D(): There is no border interpolation when applying 2D-convolution in armadillo using conv2(). Depending on the
// kernel size there might be artifacts at the border of the image. The bigger the kernel_size parameter the more obvious the artifacts at the border of
// the image will be. I could add an offset parameter to account for this but it will slow down the function, that means I would have to extend the image
// first depending on the kernel size then I would apply convolution and finally I would crop the image based on the offset variable (similar to padding).
// The artifacts at the border of the image are not visible for bigger images, whereas for smaller images are more obvious.
//

// [[Rcpp::export]]
arma::cube fast_glcm(arma::Mat<int>& img,
                     int vmin = 0,
                     int vmax = 255,
                     unsigned int levels = 8,
                     int kernel_size = 5,
                     double distance = 1.0,
                     double angle = 0.0,
                     int threads = 1) {
  #ifdef _OPENMP
  omp_set_num_threads(threads);
  #endif

  int h = img.n_rows;
  int w = img.n_cols;

  // arma::Mat<int> gl1 = digitize(img, levels + 1, vmin, vmax + 1);
  arma::mat gl1 = digitize(img, levels + 1, vmin, vmax + 1);

  // make shifted image
  double dx = distance * std::cos(deg2rad(angle));
  double dy = distance * std::sin(deg2rad(-angle));
  arma::mat aff_transf_mt = { {1.0, 0.0, -dx}, {0.0, 1.0, -dy} };

  // load the warpAffine 2-dimensional function
  oimageR::Warp_Affine warp;
  arma::mat gl2 = warp.warpAffine_2d(gl1, aff_transf_mt, gl1.n_cols, gl1.n_rows, threads);
  // arma::Mat<int> gl2 = arma::join_horiz(gl1.cols(1, gl1.n_cols - 1), gl1.col(gl1.n_cols - 1));           // initial version of 'gl2' where 'angle' and 'distance' were not included in the 'fast_glcm()' function

  arma::Mat<int> gl1_int = arma::conv_to<arma::Mat<int>>::from(gl1);           // convert 'gl1' to type integer so that I can compare with the i,j indexing in the for-loop
  arma::Mat<int> gl2_int = arma::conv_to<arma::Mat<int>>::from(gl2);           // convert 'gl2' to type integer so that I can compare with the i,j indexing in the for-loop

  arma::cube glcm(h, w, levels * levels);
  glcm.fill(0);

  unsigned int i,j;

  #ifdef _OPENMP
  #pragma omp parallel for schedule(auto) shared(levels, gl2_int, gl1_int, glcm) private(i,j) collapse(2)
  #endif
  for (i = 0; i < levels; i++) {
    for (j = 0; j < levels; j++) {

      arma::uvec mask = arma::find((gl1_int == i) && (gl2_int == j));                         // intersection of 'x' and 'y' based on the 'i', 'j' indices

      if (mask.n_elem > 0) {
        for (unsigned int t = 0; t < mask.n_elem; t++) {

          #ifdef _OPENMP
          #pragma omp atomic write
          #endif
          glcm.slice(i * levels + j)(mask(t)) = 1;
        }
      }
    }
  }

  arma::mat kernel(kernel_size, kernel_size, arma::fill::ones);
  unsigned int k,m;

  #ifdef _OPENMP
  #pragma omp parallel for schedule(auto) shared(levels, kernel, glcm) private(k,m) collapse(2)
  #endif
  for (k = 0; k < levels; k++) {
    for (m = 0; m < levels; m++) {

      arma::mat filter2d = arma::conv2(glcm.slice(k * levels + m), kernel, "same");                        // overwrite the current iteration's matrix with the convolved matrix

      for (unsigned int f = 0; f < filter2d.n_rows; f++) {
        for (unsigned int g = 0; g < filter2d.n_cols; g++) {

          #ifdef _OPENMP
          #pragma omp atomic write
          #endif
          glcm.slice(k * levels + m)(f, g) = filter2d(f,g);
        }
      }
    }
  }

  return glcm;
}



// check if method exists [ see: https://stackoverflow.com/a/15103712, https://stackoverflow.com/a/13461561 ]
//

// [[Rcpp::export]]
bool method_exists(std::vector<std::string> methods, std::string this_method) {
  return std::any_of(methods.begin(), methods.end(), [&this_method](std::string i){return i == this_method;});
}


// function that returns either specified GCLM features or all GCLM features
//
// Efficient way to receive all GLCM-features compared to calling each function separately as is done in the python script
// The Python vectorised version for small kernel-sizes has pretty much the same computation time (slightly slower) but it becomes slower with increasing kernel-size & number of 'levels'
//

// [[Rcpp::export]]
Rcpp::List fast_GLCM(arma::Mat<int>& img,
                     std::vector<std::string> methods,
                     int levels = 8,
                     int kernel_size = 5,
                     double distance = 1.0,
                     double angle = 0.0,
                     int threads = 1,
                     Rcpp::Nullable<Rcpp::String> dir_save = R_NilValue) {
  int vmin = 0;                                                                            // by default I assume that the range of the data is between 0 and 255
  int vmax = 255;
  std::string dir_name;

  if (dir_save.isNotNull()) {
    std::string dir_save_upd = Rcpp::as<std::string>(dir_save);
    dir_name = dir_save_upd + os_separator;
  }

  // arma::Mat<int> img = norm_matrix_range(data, vmin, vmax);

  int MIN = img.min();           // after adjusting the range between 0 and 255 verify it
  int MAX = img.max();
  if (!((MIN >= vmin) & (MIN <= vmax))) Rcpp::stop("The 'minimum' pixel value of the normalized image must be between 0 and 255!");
  if (!((MAX >= vmin) & (MAX <= vmax))) Rcpp::stop("The 'maximum' pixel value of the normalized image must be between 0 and 255!");

  if (methods.empty()) Rcpp::stop("The 'methods' parameter must include at least one fo the following: 'mean', 'std', 'contrast', 'dissimilarity', 'homogeneity', 'ASM', 'energy', 'max', 'entropy'!");

  arma::cube glcm = fast_glcm(img,
                              vmin,
                              vmax,
                              levels,
                              kernel_size,
                              distance,
                              angle,
                              threads);
  Rcpp::List GLCM_list;
  arma::mat mean_mt, std_mt, cont, diss, homo, ASM;

  if (method_exists(methods, "mean") || (method_exists(methods, "std"))) mean_mt.zeros(img.n_rows, img.n_cols);       // it sets the size & initializes the matrix to zeros()  [ see documentation in .set_size() ]
  if (method_exists(methods, "std")) std_mt.zeros(img.n_rows, img.n_cols);
  if (method_exists(methods, "contrast")) cont.zeros(img.n_rows, img.n_cols);
  if (method_exists(methods, "dissimilarity")) diss.zeros(img.n_rows, img.n_cols);
  if (method_exists(methods, "homogeneity")) homo.zeros(img.n_rows, img.n_cols);
  if (method_exists(methods, "ASM") || method_exists(methods, "energy")) ASM.zeros(img.n_rows, img.n_cols);

  for (int k = 0; k < levels; k++) {
    for (int t = 0; t < levels; t++) {

      if (method_exists(methods, "mean") || (method_exists(methods, "std"))) {
        mean_mt += glcm.slice(k * levels + t) * k / std::pow(levels, 2.0);
      }
      if (method_exists(methods, "contrast")) {
        cont += glcm.slice(k * levels + t) * std::pow((k - t), 2.0);
      }
      if (method_exists(methods, "dissimilarity")) {
        diss += glcm.slice(k * levels + t) * std::abs(k - t);
      }
      if (method_exists(methods, "homogeneity")) {
        homo += glcm.slice(k * levels + t) / (1.0 + std::pow((k - t), 2.0));
      }
      if (method_exists(methods, "ASM") || method_exists(methods, "energy")) {
        ASM += arma::pow(glcm.slice(k * levels + t), 2.0);
      }
    }
  }

  if (method_exists(methods, "std")) {
    for (int f = 0; f < levels; f++) {
      for (int g = 0; g < levels; g++) {
        std_mt += arma::pow((glcm.slice(f * levels + g) * f - mean_mt), 2.0);
      }
    }
  }

  if (!mean_mt.empty()) {
    if (dir_save.isNotNull()) {
      mean_mt.save(dir_name + "mean.csv", arma::csv_ascii);
      mean_mt.reset();                                                     // To forcefully release memory
    }
    else {
      GLCM_list["mean"] = mean_mt;
    }
  }
  if (!std_mt.empty()) {
    arma::mat std_out = arma::sqrt(std_mt);
    if (dir_save.isNotNull()) {
      std_out.save(dir_name + "std.csv", arma::csv_ascii);
      std_mt.reset();
      std_out.reset();
    }
    else {
      GLCM_list["std"] = std_out;
    }
  }
  if (!cont.empty()) {
    if (dir_save.isNotNull()) {
      cont.save(dir_name + "contrast.csv", arma::csv_ascii);
      cont.reset();
    }
    else {
      GLCM_list["contrast"] = cont;
    }
  }
  if (!diss.empty()) {
    if (dir_save.isNotNull()) {
      diss.save(dir_name + "dissimilarity.csv", arma::csv_ascii);
      diss.reset();
    }
    else {
      GLCM_list["dissimilarity"] = diss;
    }
  }
  if (!homo.empty()) {
    if (dir_save.isNotNull()) {
      homo.save(dir_name + "homogeneity.csv", arma::csv_ascii);
      homo.reset();
    }
    else {
      GLCM_list["homogeneity"] = homo;
    }
  }
  if (!ASM.empty() & method_exists(methods, "ASM")) {
    if (dir_save.isNotNull()) {
      ASM.save(dir_name + "ASM.csv", arma::csv_ascii);
    }
    else {
      GLCM_list["ASM"] = ASM;
    }
  }
  if (method_exists(methods, "energy")) {
    arma::mat ene_out = arma::sqrt(ASM);
    ASM.reset();
    if (dir_save.isNotNull()) {
      ene_out.save(dir_name + "energy.csv", arma::csv_ascii);
      ene_out.reset();
    }
    else {
      GLCM_list["energy"] = ene_out;
    }
  }
  if (method_exists(methods, "max")) {
    arma::mat max_out = arma::max(glcm, 2);
    if (dir_save.isNotNull()) {
      max_out.save(dir_name + "max.csv", arma::csv_ascii);
      max_out.reset();
    }
    else {
      GLCM_list["max"] = max_out;
    }
  }
  if (method_exists(methods, "entropy")) {
    arma::mat mt_sum = arma::sum(glcm, 2);

    for (unsigned int i = 0; i < glcm.n_slices; i++) {
      glcm.slice(i) /= mt_sum;                                              // overwrite slice-wise
    }
    mt_sum.reset();

    glcm = glcm + (1.0 / std::pow(kernel_size, 2.0));                       // overwrite (this code line corresponds to 'pnorm')

    for (unsigned int j = 0; j < glcm.n_slices; j++) {
      glcm.slice(j) = -glcm.slice(j) % arma::log(glcm.slice(j));            // overwrite slice-wise (corresponds to "arma::mat ent  = arma::sum(-glcm % arma::log(glcm), 2);" which requires too much RAM usage)
    }
    arma::mat ent  = arma::sum(glcm, 2);

    if (dir_save.isNotNull()) {
      ent.save(dir_name + "entropy.csv", arma::csv_ascii);
      ent.reset();
    }
    else {
      GLCM_list["entropy"] = ent;
    }
  }

  glcm.reset();

  return GLCM_list;
}

