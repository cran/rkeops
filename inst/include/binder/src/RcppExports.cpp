// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <RcppEigen.h>
#include <Rcpp.h>

using namespace Rcpp;

// r_genred
SEXP r_genred(const Rcpp::List& input, const Rcpp::List& param);
RcppExport SEXP _binder_r_genred(SEXP inputSEXP, SEXP paramSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const Rcpp::List& >::type input(inputSEXP);
    Rcpp::traits::input_parameter< const Rcpp::List& >::type param(paramSEXP);
    rcpp_result_gen = Rcpp::wrap(r_genred(input, param));
    return rcpp_result_gen;
END_RCPP
}
// test_binder
int test_binder();
RcppExport SEXP _binder_test_binder() {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    rcpp_result_gen = Rcpp::wrap(test_binder());
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_binder_r_genred", (DL_FUNC) &_binder_r_genred, 2},
    {"_binder_test_binder", (DL_FUNC) &_binder_test_binder, 0},
    {NULL, NULL, 0}
};

RcppExport void R_init_binder(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
