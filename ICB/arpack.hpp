#ifndef __ARPACK_HPP__
#define __ARPACK_HPP__

#include "arpackdef.h"

//#include <complex.h> 
#include <complex>
/*
* ---------------------------------------------------------------------|
* <complex.h> is necessary for using Microsoft CRT library, which      |
* supports the use of complex values defined in C99.                   |
* keyword complex or _Complex defined in C99 standard cannot be used;  |
* instead, Microsoft CRT implemented substitutive types:               |
*                                                                      |
* | ----------------------C99------------------ | ----CRT-- |          |
* |     float complex or float _Complex         | _Fcomplex |          |
* | double complex or double _Complex           | _Fcomplex |          |
* | long double complex or long double _Complex | _Lcomplex |          |
*                                                                      |
* <complex> is necessary for using the ISO standard implementation of  |
* complex numbers, such as std::complex<double>, std::complex<float>   |
*                                                                      |
* ---------------------------------------------------------------------|
*/

//=====================================================================
//
//          namespace using C++11 standard
//
//=====================================================================
/*
namespace arpack {
enum class which : int {
  /// 'LA' - compute the NEV largest (algebraic) eigenvalues
  largest_algebraic,
  /// 'SA' - compute the NEV smallest (algebraic) eigenvalues.
  smallest_algebraic,
  /// 'LM' - compute the NEV largest (in magnitude) eigenvalues.
  largest_magnitude,
  /// 'SM' - compute the NEV smallest (in magnitude) eigenvalues.
  smallest_magnitude,
  /// 'BE' - compute NEV eigenvalues, half from each end of the
  /// spectrum.  When NEV is odd, compute one more from the
  /// high end than from the low end.
  both_ends
};

enum class bmat : int {
  /// B = 'I' -> standard eigenvalue problem A*x = lambda*x
  identity,
  /// B = 'G' -> generalized eigenvalue problem A*x = lambda*B*x
  generalized
};

enum class howmny : int {
  /// 'A' Compute NEV Ritz vectors
  ritz_vectors,
  /// 'P' Compute NEV Schur vectors;
  schur_vectors,
  /// 'S' compute some of the Ritz vectors, specified by the logical array
  /// SELECT.
  ritz_specified
};
*/

//=====================================================================
//
//          namespace using C++03 standard
//
//=====================================================================
namespace arpack {
enum which {
  /// 'LA' - compute the NEV largest (algebraic) eigenvalues
  largest_algebraic,
  /// 'SA' - compute the NEV smallest (algebraic) eigenvalues.
  smallest_algebraic,
  /// 'LM' - compute the NEV largest (in magnitude) eigenvalues.
  largest_magnitude,
  /// 'SM' - compute the NEV smallest (in magnitude) eigenvalues.
  smallest_magnitude,
  /// 'BE' - compute NEV eigenvalues, half from each end of the
  /// spectrum.  When NEV is odd, compute one more from the
  /// high end than from the low end.
  both_ends
};

enum bmat{
  /// B = 'I' -> standard eigenvalue problem A*x = lambda*x
  identity,
  /// B = 'G' -> generalized eigenvalue problem A*x = lambda*B*x
  generalized
};

enum howmny {
  /// 'A' Compute NEV Ritz vectors
  ritz_vectors,
  /// 'P' Compute NEV Schur vectors;
  schur_vectors,
  /// 'S' compute some of the Ritz vectors, specified by the logical array
  /// SELECT.
  ritz_specified
};


namespace internal {
#include "arpack.h"

inline char const* convert_to_char(which const option) {
  switch (option) {
    case which::largest_algebraic: {
      return "LA";
      break;
    }
    case which::smallest_algebraic: {
      return "SA";
      break;
    }
    case which::largest_magnitude: {
      return "LM";
      break;
    }
    case which::smallest_magnitude: {
      return "SM";
      break;
    }
    case which::both_ends: {
      return "BE";
      break;
    }
  }
  return "LM";
}

inline char const* convert_to_char(bmat const option) {
  return option == bmat::identity ? "I" : "G";
}

inline char const* convert_to_char(howmny const option) {
  switch (option) {
    case howmny::ritz_vectors: {
      return "A";
      break;
    }
    case howmny::schur_vectors: {
      return "P";
      break;
    }
    case howmny::ritz_specified: {
      return "S";
      break;
    }
  }
  return "A";
}
}  // namespace internal

inline void saupd(a_int& ido, bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, float tol, float* resid,
                  a_int ncv, float* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  float* workd, float* workl, a_int lworkl, a_int& info) {
  internal::ssaupd_c(&ido, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}

inline void seupd(a_int rvec, howmny const howmny_option, a_int* select, float* d,
                  float* z, a_int ldz, float sigma, bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, float tol, float* resid,
                  a_int ncv, float* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  float* workd, float* workl, a_int lworkl, a_int& info) {
  internal::sseupd_c(rvec, internal::convert_to_char(howmny_option), select, d,
                     z, ldz, sigma, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}

inline void saupd(a_int& ido, bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, double tol, double* resid,
                  a_int ncv, double* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  double* workd, double* workl, a_int lworkl, a_int& info) {
  internal::dsaupd_c(&ido, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}

inline void seupd(a_int rvec, howmny const howmny_option, a_int* select, double* d,
                  double* z, a_int ldz, double sigma, bmat const bmat_option,
                  a_int n, which const ritz_option, a_int nev, double tol,
                  double* resid, a_int ncv, double* v, a_int ldv, a_int* iparam,
                  a_int* ipntr, double* workd, double* workl, a_int lworkl,
                  a_int& info) {
  internal::dseupd_c(rvec, internal::convert_to_char(howmny_option), select, d,
                     z, ldz, sigma, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}

inline void naupd(a_int& ido, bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, float tol, float* resid,
                  a_int ncv, float* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  float* workd, float* workl, a_int lworkl, a_int& info) {
  internal::snaupd_c(&ido, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}

inline void neupd(a_int rvec, howmny const howmny_option, a_int* select, float* dr,
                  float* di, float* z, a_int ldz,
                  float sigmar, float sigmai, float * workev,
                  bmat const bmat_option, a_int n, which const ritz_option,
                  a_int nev, float tol, float* resid, a_int ncv, float* v, a_int ldv,
                  a_int* iparam, a_int* ipntr, float* workd, float* workl,
                  a_int lworkl, a_int& info) {
  internal::sneupd_c(rvec, internal::convert_to_char(howmny_option), select, dr,
                     di, z, ldz, sigmar, sigmai, workev,
                     internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}

inline void naupd(a_int& ido, bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, double tol, double* resid,
                  a_int ncv, double* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  double* workd, double* workl, a_int lworkl, a_int& info) {
  internal::dnaupd_c(&ido, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}

inline void neupd(a_int rvec, howmny const howmny_option, a_int* select,
                  double* dr, double* di, double* z, a_int ldz,
                  double sigmar, double sigmai, double * workev,
                  bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, double tol, double* resid,
                  a_int ncv, double* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  double* workd, double* workl, a_int lworkl, a_int& info) {
  internal::dneupd_c(rvec, internal::convert_to_char(howmny_option), select, dr,
                     di, z, ldz, sigmar, sigmai, workev,
                     internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol, resid,
                     ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, &info);
}


// =============================================================================
//      
//                    Function for complex eigen values are commented
// 
// =============================================================================
/*
inline void naupd(a_int& ido, bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, float tol,
                  std::complex<float>* resid, a_int ncv, std::complex<float>* v,
                  a_int ldv, a_int* iparam, a_int* ipntr, std::complex<float>* workd,
                  std::complex<float>* workl, a_int lworkl,
                  float* rwork, a_int& info) {
  internal::cnaupd_c(&ido, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol,
                     reinterpret_cast<_Complex float*>(resid), ncv,
                     reinterpret_cast<_Complex float*>(v), ldv, iparam, ipntr,
                     reinterpret_cast<_Complex float*>(workd),
                     reinterpret_cast<_Complex float*>(workl), lworkl,
                     rwork, &info);
}

inline void neupd(a_int rvec, howmny const howmny_option, a_int* select,
                  std::complex<float>* d, std::complex<float>* z, a_int ldz,
                  std::complex<float> sigma, std::complex<float>* workev,
                  bmat const bmat_option, a_int n, which const ritz_option,
                  a_int nev, float tol, std::complex<float>* resid, a_int ncv,
                  std::complex<float>* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  std::complex<float>* workd, std::complex<float>* workl,
                  a_int lworkl, float* rwork, a_int& info) {
  std::complex<float> sigma2 = sigma;
  internal::cneupd_c(rvec, internal::convert_to_char(howmny_option), select,
                     reinterpret_cast<_Complex float*>(d),
                     reinterpret_cast<_Complex float*>(z), ldz,
                     *reinterpret_cast<_Complex float*>(&sigma2),
                     reinterpret_cast<_Complex float*>(workev),
                     internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol,
                     reinterpret_cast<_Complex float*>(resid), ncv,
                     reinterpret_cast<_Complex float*>(v), ldv, iparam, ipntr,
                     reinterpret_cast<_Complex float*>(workd),
                     reinterpret_cast<_Complex float*>(workl), lworkl,
                     rwork, &info);
}

inline void naupd(a_int& ido, bmat const bmat_option, a_int n,
                  which const ritz_option, a_int nev, double tol,
                  std::complex<double>* resid, a_int ncv, std::complex<double>* v,
                  a_int ldv, a_int* iparam, a_int* ipntr, std::complex<double>* workd,
                  std::complex<double>* workl, a_int lworkl,
                  double* rwork, a_int& info) {
  internal::znaupd_c(&ido, internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol,
                     reinterpret_cast<_Complex double*>(resid), ncv,
                     reinterpret_cast<_Complex double*>(v), ldv, iparam, ipntr,
                     reinterpret_cast<_Complex double*>(workd),
                     reinterpret_cast<_Complex double*>(workl), lworkl,
                     rwork, &info);
}

inline void neupd(a_int rvec, howmny const howmny_option, a_int* select,
                  std::complex<double>* d, std::complex<double>* z, a_int ldz,
                  std::complex<double> sigma, std::complex<double>* workev,
                  bmat const bmat_option, a_int n, which const ritz_option,
                  a_int nev, double tol, std::complex<double>* resid, a_int ncv,
                  std::complex<double>* v, a_int ldv, a_int* iparam, a_int* ipntr,
                  std::complex<double>* workd, std::complex<double>* workl,
                  a_int lworkl, double* rwork, a_int& info) {
  std::complex<double> sigma2 = sigma;
  internal::zneupd_c(rvec, internal::convert_to_char(howmny_option), select,
                     reinterpret_cast<_Complex double*>(d),
                     reinterpret_cast<_Complex double*>(z), ldz,
                     *reinterpret_cast<_Complex double*>(&sigma2),
                     reinterpret_cast<_Complex double*>(workev),
                     internal::convert_to_char(bmat_option), n,
                     internal::convert_to_char(ritz_option), nev, tol,
                     reinterpret_cast<_Complex double*>(resid), ncv,
                     reinterpret_cast<_Complex double*>(v), ldv, iparam, ipntr,
                     reinterpret_cast<_Complex double*>(workd),
                     reinterpret_cast<_Complex double*>(workl), lworkl,
                     rwork, &info);
} */

}  // namespace arpack

#endif
