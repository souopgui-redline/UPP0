!> @file
!>
!> @brief This module is to hold specification kinds for variable declaration.
!> This module is based on (copied from) Paul vanDelst's 
!> type_kinds module found in the community radiative transfer model.
!>
!> @note The numerical data types defined in this module are:
!> Variables name | Numerical data types
!> ---------------|------------
!>      i_byte    | specification kind for byte (1-byte) integer variable
!>      i_short   | specification kind for short (2-byte) integer variable
!>      i_long    | specification kind for long (4-byte) integer variable
!>      i_llong   | specification kind for double long (8-byte) integer variable
!>      r_single  | specification kind for single precision (4-byte) real variable
!>      r_double  | specification kind for double precision (8-byte) real variable
!>      r_quad    | specification kind for quad precision (16-byte) real variable
!>      i_kind    | generic specification kind for default integer
!>      r_kind    | generic specification kind for default floating point
!>
!>
!> ### Program History Log
!> Date | Programmer | Comments
!> -----|------------|---------
!> 2004-08-15 | Russ Treadon | Initial
!>
!> @author Russ Treadon np23 @date 2004-08-15
!
! ----------------------------------------------------------------------
!

      module kinds

  implicit none
  private

! Integer type definitions below

! Integer types
  !> Specification kind for byte (1-byte) integer variable
  integer, parameter, public  :: i_byte  = selected_int_kind(1)      ! byte  integer
  !> Specification kind for short (2-byte) integer variable
  integer, parameter, public  :: i_short = selected_int_kind(4)      ! short integer
  !> Specification kind for long (4-byte) integer variable
  integer, parameter, public  :: i_long  = selected_int_kind(8)      ! long  integer
  integer, parameter, private :: llong_t = selected_int_kind(16)     ! llong integer
  !> Specification kind for double long (8-byte) integer variable
  integer, parameter, public  :: i_llong = max( llong_t, i_long )

! Expected 8-bit byte sizes of the integer kinds
  !> Expected 8-bit byte size for byte integer
  integer, parameter, public :: num_bytes_for_i_byte  = 1
  !> Expected 8-bit byte size for short integer
  integer, parameter, public :: num_bytes_for_i_short = 2
  !> Expected 8-bit byte size for long integer
  integer, parameter, public :: num_bytes_for_i_long  = 4
  !> Expected 8-bit byte size for llong integer
  integer, parameter, public :: num_bytes_for_i_llong = 8

! Define arrays for default definition
  integer, parameter, private :: num_i_kinds = 4
  integer, parameter, dimension( num_i_kinds ), private :: integer_types = (/ &
       i_byte, i_short, i_long,  i_llong  /) 
  integer, parameter, dimension( num_i_kinds ), private :: integer_byte_sizes = (/ &
       num_bytes_for_i_byte, num_bytes_for_i_short, &
       num_bytes_for_i_long, num_bytes_for_i_llong  /)

! Default values
! **** CHANGE THE FOLLOWING TO CHANGE THE DEFAULT INTEGER TYPE KIND ***
#if defined(GSDRAPR) || defined(COMMCODE)
  integer, parameter, private :: default_integer = 3  ! 1=byte, 
#else
  integer, parameter, private :: default_integer = 2  ! 1=byte, 
#endif
                                                      ! 2=short, 
                                                      ! 3=long, 
                                                      ! 4=llong
  !> i_kind Generic specification kind for default integer
  integer, parameter, public  :: i_kind = integer_types( default_integer )
  !> Number of bytes for i_kind
  integer, parameter, public  :: num_bytes_for_i_kind = &
       integer_byte_sizes( default_integer )

! Real definitions below

! Real types
  !> Specification kind for single precision (4-byte) real variable
  integer, parameter, public  :: r_single = selected_real_kind(6)  ! single precision
  !> Specification kind for double precision (8-byte) real variable
  integer, parameter, public  :: r_double = selected_real_kind(15) ! double precision
  integer, parameter, private :: quad_t   = selected_real_kind(20) ! quad precision
  !> r_quad Specification kind for quad precision (16-byte) real variable
  integer, parameter, public  :: r_quad   = max( quad_t, r_double )

! Expected 8-bit byte sizes of the real kinds
  !> Expected 8-bit byte size for single precision types
  integer, parameter, public :: num_bytes_for_r_single = 4
  !> Expected 8-bit byte size for double precision types
  integer, parameter, public :: num_bytes_for_r_double = 8
  !> Expected 8-bit byte size for quad precision types
  integer, parameter, public :: num_bytes_for_r_quad   = 16

! Define arrays for default definition
  integer, parameter, private :: num_r_kinds = 3
  integer, parameter, dimension( num_r_kinds ), private :: real_kinds = (/ &
       r_single, r_double, r_quad    /) 
  integer, parameter, dimension( num_r_kinds ), private :: real_byte_sizes = (/ &
       num_bytes_for_r_single, num_bytes_for_r_double, &
       num_bytes_for_r_quad    /)

! Default values
! **** CHANGE THE FOLLOWING TO CHANGE THE DEFAULT REAL TYPE KIND ***
  integer, parameter, private :: default_real = 1  ! 1=single, 
                                                   ! 2=double, 
                                                   ! 3=quad
  !> r_kind Generic specification kind for default floating point
  integer, parameter, public  :: r_kind = real_kinds( default_real )
  !> Number of bytes for r_kind
  integer, parameter, public  :: num_bytes_for_r_kind = &
       real_byte_sizes( default_real )

end module kinds
