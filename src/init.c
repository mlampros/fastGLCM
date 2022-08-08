#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* FIXME: 
   Check these declarations against the C/Fortran source code.
*/

/* .Call calls */
extern SEXP _fastGLCM_deg2rad(SEXP);
extern SEXP _fastGLCM_digitize(SEXP, SEXP, SEXP, SEXP);
extern SEXP _fastGLCM_fast_glcm(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP _fastGLCM_fast_GLCM(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP _fastGLCM_method_exists(SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"_fastGLCM_deg2rad",       (DL_FUNC) &_fastGLCM_deg2rad,       1},
    {"_fastGLCM_digitize",      (DL_FUNC) &_fastGLCM_digitize,      4},
    {"_fastGLCM_fast_glcm",     (DL_FUNC) &_fastGLCM_fast_glcm,     8},
    {"_fastGLCM_fast_GLCM",     (DL_FUNC) &_fastGLCM_fast_GLCM,     8},
    {"_fastGLCM_method_exists", (DL_FUNC) &_fastGLCM_method_exists, 2},
    {NULL, NULL, 0}
};

void R_init_fastGLCM(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
