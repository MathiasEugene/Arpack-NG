      program dsdrv3
c
c     Program to illustrate the idea of reverse communication in
c     inverse mode for a generalized symmetric eigenvalue problem.
c     The following program uses the two LAPACK subroutines dgttrf .f
c     and dgttrs .f to factor and solve a tridiagonal system of equations.
c
c     We implement example three of ex-sym.doc in DOCUMENTS directory
c
c\Example-3
c     ... Suppose we want to solve A*x = lambda*M*x in inverse mode,
c         where A and M are obtained by the finite element of the
c         1-dimensional discrete Laplacian
c                             d^2u / dx^2
c         on the interval [0,1] with zero Dirichlet boundary condition
c         using piecewise linear elements.
c
c     ... OP = inv[M]*A  and  B = M.
c
c     ... Use mode 2 of DSAUPD .
c
c\BeginLib
c
c\Routines called:
c     dsaupd   ARPACK reverse communication interface routine.
c     dseupd   ARPACK routine that returns Ritz values and (optionally)
c             Ritz vectors.
c     dgttrf   LAPACK tridiagonal factorization routine.
c     dgttrs   LAPACK tridiagonal solve routine.
c     daxpy    Level 1 BLAS that computes y <- alpha*x+y.
c     dscal    Level 1 BLAS that scales a vector by a scalar.
c     dcopy    Level 1 BLAS that copies one vector to another.
c     dnrm2    Level 1 BLAS that computes the norm of a vector.
c     av      Matrix vector multiplication routine that computes A*x.
c     mv      Matrix vector multiplication routine that computes M*x.
c
c\Author
c     Richard Lehoucq
c     Danny Sorensen
c     Chao Yang
c     Dept. of Computational &
c     Applied Mathematics
c     Rice University
c     Houston, Texas
c
c\SCCS Information: @(#)
c FILE: sdrv3.F   SID: 2.5   DATE OF SID: 10/17/00   RELEASE: 2
c
c\Remarks
c     1. None
c
c\EndLib
c--------------------------------------------------------------------------
c
c     %-----------------------------%
c     | Define leading dimensions   |
c     | for all arrays.             |
c     | MAXN:   Maximum dimension   |
c     |         of the A allowed.   |
c     | MAXNEV: Maximum NEV allowed |
c     | MAXNCV: Maximum NCV allowed |
c     %-----------------------------%
c
      integer          maxn, maxnev, maxncv, ldv
      parameter        (maxn=256, maxnev=10, maxncv=25,
     &                 ldv=maxn )
c
c     %--------------%
c     | Local Arrays |
c     %--------------%
c
      Double precision
     &                 v(ldv,maxncv), workl(maxncv*(maxncv+8)),
     &                 workd(3*maxn), d(maxncv,2), resid(maxn),
     &                 ad(maxn), adl(maxn), adu(maxn), adu2(maxn),
     &                 ax(maxn), mx(maxn)
      logical          select(maxncv)
      integer          iparam(11), ipntr(11), ipiv(maxn)
c
c     %---------------%
c     | Local Scalars |
c     %---------------%
c
      character        bmat*1, which*2
      integer          ido, n, nev, ncv, lworkl, info, j, ierr,
     &                 nconv, maxitr, ishfts, mode
      logical          rvec
      Double precision
     &                 sigma, r1, r2, tol, h
c
c     %------------%
c     | Parameters |
c     %------------%
c
      Double precision
     &                 zero, one, four, six
      parameter        ( zero = 0.0D+0 , one = 1.0D+0 ,
     &                   four = 4.0D+0 , six = 6.0D+0  )
c
c     %-----------------------------%
c     | BLAS & LAPACK routines used |
c     %-----------------------------%
c
      Double precision
     &                 dnrm2
      external         daxpy , dcopy , dscal , dnrm2 , dgttrf , dgttrs
c
c     %--------------------%
c     | Intrinsic function |
c     %--------------------%
c
      intrinsic        abs
c
c     %-----------------------%
c     | Executable statements |
c     %-----------------------%
c
c     %----------------------------------------------------%
c     | The number N is the dimension of the matrix. A     |
c     | generalized eigenvalue problem is solved (BMAT =   |
c     | 'G'.) NEV is the number of eigenvalues to be       |
c     | approximated.  The user can modify NEV, NCV, WHICH |
c     | to solve problems of different sizes, and to get   |
c     | different parts of the spectrum.  However, The     |
c     | following conditions must be satisfied:            |
c     |                     N <= MAXN,                     |
c     |                   NEV <= MAXNEV,                   |
c     |               NEV + 1 <= NCV <= MAXNCV             |
c     %----------------------------------------------------%
c
      n = 100
      nev = 4
      ncv = 10
      if ( n .gt. maxn ) then
         print *, ' ERROR with _SDRV3: N is greater than MAXN '
         go to 9000
      else if ( nev .gt. maxnev ) then
         print *, ' ERROR with _SDRV3: NEV is greater than MAXNEV '
         go to 9000
      else if ( ncv .gt. maxncv ) then
         print *, ' ERROR with _SDRV3: NCV is greater than MAXNCV '
         go to 9000
      end if
      bmat = 'G'
      which = 'LM'
c
c     %--------------------------------------------------%
c     | The work array WORKL is used in DSAUPD  as        |
c     | workspace.  Its dimension LWORKL is set as       |
c     | illustrated below.  The parameter TOL determines |
c     | the stopping criterion.  If TOL<=0, machine      |
c     | precision is used.  The variable IDO is used for |
c     | reverse communication and is initially set to 0. |
c     | Setting INFO=0 indicates that a random vector is |
c     | generated in DSAUPD  to start the Arnoldi         |
c     | iteration.                                       |
c     %--------------------------------------------------%
c
      lworkl = ncv*(ncv+8)
      tol = zero
      ido = 0
      info = 0
c
c     %---------------------------------------------------%
c     | This program uses exact shifts with respect to    |
c     | the current Hessenberg matrix (IPARAM(1) = 1).    |
c     | IPARAM(3) specifies the maximum number of Arnoldi |
c     | iterations allowed.  Mode 2 of DSAUPD  is used     |
c     | (IPARAM(7) = 2).  All these options may be        |
c     | changed by the user. For details, see the         |
c     | documentation in DSAUPD .                          |
c     %---------------------------------------------------%
c
      ishfts = 1
      maxitr = 300
      mode   = 2
c
      iparam(1) = ishfts
      iparam(3) = maxitr
      iparam(7) = mode
c
c     %------------------------------------------------%
c     | Call LAPACK routine to factor the mass matrix. |
c     | The mass matrix is the tridiagonal matrix      |
c     | arising from using piecewise linear finite     |
c     | elements on the interval [0, 1].               |
c     %------------------------------------------------%
c
      h = one / dble (n+1)
c
      r1 = (four / six) * h
      r2 = (one / six) * h
      do 20 j=1,n
         ad(j) =  r1
         adl(j) = r2
 20   continue
      call dcopy  (n, adl, 1, adu, 1)
      call dgttrf  (n, adl, ad, adu, adu2, ipiv, ierr)
      if (ierr .ne. 0) then
         print *, ' '
         print *, ' Error with _gttrf in _SDRV3. '
         print *, ' '
         go to 9000
      end if
c
c     %-------------------------------------------%
c     | M A I N   L O O P (Reverse communication) |
c     %-------------------------------------------%
c
 10   continue
c
c        %---------------------------------------------%
c        | Repeatedly call the routine DSAUPD  and take |
c        | actions indicated by parameter IDO until    |
c        | either convergence is indicated or maxitr   |
c        | has been exceeded.                          |
c        %---------------------------------------------%
c
         call dsaupd  ( ido, bmat, n, which, nev, tol, resid,
     &                 ncv, v, ldv, iparam, ipntr, workd, workl,
     &                 lworkl, info )
c
         if (ido .eq. -1 .or. ido .eq. 1) then
c
c           %--------------------------------------%
c           | Perform  y <--- OP*x = inv[M]*A*x.   |
c           | The user should supply his/her own   |
c           | matrix vector multiplication (A*x)   |
c           | routine and a linear system solver   |
c           | here.  The matrix vector             |
c           | multiplication routine takes         |
c           | workd(ipntr(1)) as the input vector. |
c           | The final result is returned to      |
c           | workd(ipntr(2)). The result of A*x   |
c           | overwrites workd(ipntr(1)).          |
c           %--------------------------------------%
c               workd(ipntr(1)) -> x 
c               workd(ipntr(2)) -> y
            call av (n, workd(ipntr(1)), workd(ipntr(2)))

c           DCOPY(N,DX,INCX,DY,INCY)  
c           copies a vector, DX, to a vector, DY.    
c           DX is DOUBLE PRECISION array, dimension ( 1 + ( N - 1 )*abs( INCX ) )  
c           DY is DOUBLE PRECISION array, dimension ( 1 + ( N - 1 )*abs( INCY ) )

            call dcopy (n, workd(ipntr(2)),  1, workd(ipntr(1)), 1)
            call dgttrs  ('Notranspose', n, 1, adl, ad, adu, adu2, ipiv,
     &                  workd(ipntr(2)), n, ierr)
            if (ierr .ne. 0) then
               print *, ' '
               print *, ' Error with _gttrs in _SDRV3.'
               print *, ' '
               go to 9000
            end if
c
c           %-----------------------------------------%
c           | L O O P   B A C K to call DSAUPD  again. |
c           %-----------------------------------------%
c
            go to 10

c
         else if (ido .eq. 2) then
c
c           %-----------------------------------------%
c           |         Perform  y <--- M*x.            |
c           | Need the matrix vector multiplication   |
c           | routine here that takes workd(ipntr(1)) |
c           | as the input and returns the result to  |
c           | workd(ipntr(2)).                        |
c           %-----------------------------------------%
c
            call mv (n, workd(ipntr(1)), workd(ipntr(2)))
c
c           %-----------------------------------------%
c           | L O O P   B A C K to call DSAUPD  again. |
c           %-----------------------------------------%
c
            go to 10
c
         end if
c
c
c
c     %-----------------------------------------%
c     | Either we have convergence, or there is |
c     | an error.                               |
c     %-----------------------------------------%
c
      if ( info .lt. 0 ) then
c
c        %--------------------------%
c        | Error message, check the |
c        | documentation in DSAUPD   |
c        %--------------------------%
c
         print *, ' '
         print *, ' Error with _saupd, info = ',info
         print *, ' Check the documentation of _saupd '
         print *, ' '
c
      else
c
c        %-------------------------------------------%
c        | No fatal errors occurred.                 |
c        | Post-Process using DSEUPD .                |
c        |                                           |
c        | Computed eigenvalues may be extracted.    |
c        |                                           |
c        | Eigenvectors may also be computed now if  |
c        | desired.  (indicated by rvec = .true.)    |
c        %-------------------------------------------%
c
         rvec = .true.
c
         call dseupd  ( rvec, 'All', select, d, v, ldv, sigma,
     &        bmat, n, which, nev, tol, resid, ncv, v, ldv,
     &        iparam, ipntr, workd, workl, lworkl, ierr )
c
c        %----------------------------------------------%
c        | Eigenvalues are returned in the first column |
c        | of the two dimensional array D and the       |
c        | corresponding eigenvectors are returned in   |
c        | the first NEV columns of the two dimensional |
c        | array V if requested.  Otherwise, an         |
c        | orthogonal basis for the invariant subspace  |
c        | corresponding to the eigenvalues in D is     |
c        | returned in V.                               |
c        %----------------------------------------------%
c
         if (ierr .ne. 0) then
c
c           %------------------------------------%
c           | Error condition:                   |
c           | Check the documentation of DSEUPD . |
c           %------------------------------------%
c
            print *, ' '
            print *, ' Error with _seupd, info = ', ierr
            print *, ' Check the documentation of _seupd'
            print *, ' '
c
         else
c
            nconv =  iparam(5)
            do 30 j=1, nconv
c
c              %---------------------------%
c              | Compute the residual norm |
c              |                           |
c              |  ||  A*x - lambda*M*x ||  |
c              |                           |
c              | for the NCONV accurately  |
c              | computed eigenvalues and  |
c              | eigenvectors.  (iparam(5) |
c              | indicates how many are    |
c              | accurate to the requested |
c              | tolerance)                |
c              %---------------------------%
c
               call av(n, v(1,j), ax)
               call mv(n, v(1,j), mx)
               call daxpy (n, -d(j,1), mx, 1, ax, 1)
               d(j,2) = dnrm2 (n, ax, 1)
               d(j,2) = d(j,2) / abs(d(j,1))
c
 30         continue
c
c           %-----------------------------%
c           | Display computed residuals. |
c           %-----------------------------%
c
            call dmout (6, nconv, 2, d, maxncv, -6,
     &           'Ritz values and relative residuals')
         end if
c
c        %------------------------------------------%
c        | Print additional convergence information |
c        %------------------------------------------%
c
         if ( info .eq. 1) then
            print *, ' '
            print *, ' Maximum number of iterations reached.'
            print *, ' '
         else if ( info .eq. 3) then
            print *, ' '
            print *, ' No shifts could be applied during implicit',
     &               ' Arnoldi update, try increasing NCV.'
            print *, ' '
         end if
c
         print *, ' '
         print *, ' _SDRV3 '
         print *, ' ====== '
         print *, ' '
         print *, ' Size of the matrix is ', n
         print *, ' The number of Ritz values requested is ', nev
         print *, ' The number of Arnoldi vectors generated',
     &            ' (NCV) is ', ncv
         print *, ' What portion of the spectrum: ', which
         print *, ' The number of converged Ritz values is ',
     &              nconv
         print *, ' The number of Implicit Arnoldi update',
     &            ' iterations taken is ', iparam(3)
         print *, ' The number of OP*x is ', iparam(9)
         print *, ' The convergence criterion is ', tol
         print *, ' '
c
      end if
c
c     %---------------------------%
c     | Done with program dsdrv3 . |
c     %---------------------------%
c
 9000 continue
c
      end
c
c------------------------------------------------------------------------
c     Matrix vector subroutine
c     where the matrix is the 1 dimensional mass matrix
c     on the interval [0,1].
c
      subroutine mv (n, v, w)
      integer           n, j
      Double precision
     &                  v(n),w(n), one, four, six, h
      parameter         (one = 1.0D+0 , four = 4.0D+0 ,
     &                   six = 6.0D+0 )
c
      w(1) = four*v(1) + v(2)
      do 100 j = 2,n-1
         w(j) = v(j-1) + four*v(j) + v(j+1)
  100 continue
      j = n
      w(j) = v(j-1) + four*v(j)
c
c     Scale the vector w by h.
c
      h = one / (dble (n+1)*six)
      call dscal (n, h, w, 1)
      return
      end
c
c--------------------------------------------------------------------
c     matrix vector subroutine
c
c     The matrix used is the stiffness matrix obtained from the finite
c     element discretization of the 1-dimensional discrete Laplacian
c     on the interval [0,1] with zero Dirichlet boundary condition using
c     piecewise linear elements.
c
      subroutine av (n, v, w)
      integer           n, j
      Double precision
     &                  v(n),w(n), two, one, h
      parameter         ( one = 1.0D+0 , two = 2.0D+0  )
c
      w(1) =  two*v(1) - v(2)
      do 100 j = 2,n-1
         w(j) = - v(j-1) + two*v(j) - v(j+1)
  100 continue
      j = n
      w(j) = - v(j-1) + two*v(j)
c
c     Scale the vector w by (1 / h).
c
      h = one / dble (n+1)
      call dscal (n, one/h, w, 1)
      return
      end
