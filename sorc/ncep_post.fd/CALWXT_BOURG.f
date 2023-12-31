!> @file
!> @brief Subroutine that calculates precipitation type (Bourgouin).
!>
!> This routine computes precipitation type.
!> using a decision tree approach that uses the so-called
!> "energy method" of Bourgouin of AES (Canada) 1992.
!>
!> @param[in] im integer i dimension.
!> @param[in] jm integer j dimension.
!> @param[in] jsta_2l integer j dimension start point (including haloes).
!> @param[in] jend_2u integer j dimension end point (including haloes).
!> @param[in] jsta integer j dimension start point (excluding haloes).
!> @param[in] jend integer j dimension end point (excluding haloes).
!> @param[in] lm integer k dimension.
!> @param[in] lp1 integer k dimension plus 1.
!> @param[in] iseed integer random number seed.
!> @param[in] g real gravity (m/s**2).
!> @param[in] pthresh real precipitation threshold (m).
!> @param[in] t real(im,jsta_2l:jend_2u,lm) mid layer temp (K).
!> @param[in] q real(im,jsta_2l:jend_2u,lm) specific humidity (kg/kg).
!> @param[in] pmid real(im,jsta_2l:jend_2u,lm) mid layer pressure (Pa).
!> @param[in] pint real(im,jsta_2l:jend_2u,lp1) interface pressure (Pa).
!> @param[in] lmh real(im,jsta_2l:jend_2u) max number of layers.
!> @param[in] prec real(im,jsta_2l:jend_2u) precipitation (m).
!> @param[in] zint real(im,jsta_2l:jend_2u,lp1) interface height (m).
!> @param[out] ptype integer(im,jm) instantaneous weather type () acts like a 4 bit binary 1111 = rain/freezing rain/ice pellets/snow.
!><pre>
!>                   where the one's digit is for snow
!>                         the two's digit is for ice pellets
!>                         the four's digit is for freezing rain
!>                         and the eight's digit is for rain
!>                         in other words...
!>                         ptype=1 snow
!>                         ptype=2 ice pellets/mix with ice pellets
!>                         ptype=4 freezing rain/mix with freezing rain
!>                         ptype=8 rain
!></pre>
!> @param[in] me integer Identifier for the processor used in the current instance. 
!>
!> ### Program history log:
!> Date | Programmer | Comments
!> -----|------------|---------
!> 1999-07-06 | M Baldwin | Initial
!> 1999-09-20 | M Baldwin | make more consistent with bourgouin (1992)
!> 2005-08-24 | G Manikin | added to wrf post
!> 2007-06-19 | M Iredell | mersenne twister, best practices
!> 2015-??-?? | S Moorthi | changed random number call and optimization and cleanup
!> 2021-10-31 | J Meng    | 2D DECOMPOSITION
!>
!> Remarks: vertical order of arrays must be layer   1 = top
!>          and layer lmh = bottom
!>
!> @author M Baldwin np22 @date 1999-07-06
!--------------------------------------------------------------------------------------
!> @brief calwxt_bourg_post Subroutine that calculates precipitation type (Bourgouin).
!> 
!> @param[in] im integer i dimension.
!> @param[in] ista_2l integer i dimension start point (including haloes).
!> @param[in] iend_2u integer i dimension end point (including haloes).
!> @param[in] ista integer i dimension start point (excluding haloes).
!> @param[in] iend integer i dimension end point (excluding haloes).
!> @param[in] jm integer j dimension.
!> @param[in] jsta_2l integer j dimension start point (including haloes).
!> @param[in] jend_2u integer j dimension end point (including haloes).
!> @param[in] jsta integer j dimension start point (excluding haloes).
!> @param[in] jend integer j dimension end point (excluding haloes).
!> @param[in] lm integer k dimension.
!> @param[in] lp1 integer k dimension plus 1.
!> @param[in] iseed integer random number seed.
!> @param[in] g real gravity (m/s**2).
!> @param[in] pthresh real precipitation threshold (m).
!> @param[in] t real(im,jsta_2l:jend_2u,lm) mid layer temp (K).
!> @param[in] q real(im,jsta_2l:jend_2u,lm) specific humidity (kg/kg).
!> @param[in] pmid real(im,jsta_2l:jend_2u,lm) mid layer pressure (Pa).
!> @param[in] pint real(im,jsta_2l:jend_2u,lp1) interface pressure (Pa).
!> @param[in] lmh real(im,jsta_2l:jend_2u) max number of layers.
!> @param[in] prec real(im,jsta_2l:jend_2u) precipitation (m).
!> @param[in] zint real(im,jsta_2l:jend_2u,lp1) interface height (m).
!> @param[out] ptype integer(im,jm) instantaneous weather type () acts like a 4 bit binary 1111 = rain/freezing rain/ice pellets/snow.
!> @param[in] me integer Identifier for the processor used in the current instance. 
!------------------------------------------------------------------------------------------------------------
      subroutine calwxt_bourg_post(im,ista_2l,iend_2u,ista,iend,jm,     &
     &                              jsta_2l,jend_2u,jsta,jend,lm,lp1,   &
     &                             iseed,g,pthresh,                          &
     &                             t,q,pmid,pint,lmh,prec,zint,ptype,me)
      implicit none
!
!    input:
      integer,intent(in):: im,jm,jsta_2l,jend_2u,jsta,jend,lm,lp1,iseed,me,&
                                 ista_2l,iend_2u,ista,iend
      real,intent(in):: g,pthresh
      real,intent(in), dimension(ista_2l:iend_2u,jsta_2l:jend_2u,lm)  :: t, q, pmid
      real,intent(in), dimension(ista_2l:iend_2u,jsta_2l:jend_2u,lp1) :: pint, zint
      real,intent(in), dimension(ista_2l:iend_2u,jsta_2l:jend_2u)     :: lmh, prec
!
!    output:
!     real,intent(out)    :: ptype(im,jm)
      integer,intent(out) :: ptype(ista:iend,jsta:jend)
!
      integer i,j,ifrzl,iwrml,l,lhiwrm,lmhk,jlen
      real pintk1,areane,tlmhk,areape,pintk2,surfw,area1,dzkl,psfck,r1,r2
      real rn(im*jm*2)
      integer :: rn_seed_size
      integer, allocatable, dimension(:) :: rn_seed
      logical, parameter :: debugprint = .false.
!
!     initialize weather type array to zero (ie, off).
!     we do this since we want ptype to represent the
!     instantaneous weather type on return.
      if (debugprint) then
        print *,'in calwxtbg, jsta,jend=',jsta,jend,' im=',im
        print *,'in calwxtbg,me=',me,'iseed=',iseed
     endif
!
!$omp  parallel do
      do j=jsta,jend
        do i=ista,iend
          ptype(i,j) = 0
        enddo
      enddo
!
      jlen = jend - jsta + 1

      call random_seed(size = rn_seed_size)
      allocate(rn_seed(rn_seed_size))
      rn_seed = iseed
      call random_seed(put = rn_seed)
      call random_number(rn)
!
!!$omp  parallel do                                                   &
!     & private(a,lmhk,tlmhk,iwrml,psfck,lhiwrm,pintk1,pintk2,area1,  &
!     &         areape,dzkl,surfw,r1,r2)
!      print *,'incalwxtbg, rn',maxval(rn),minval(rn)

      do j=jsta,jend
!      if(me==1)print *,'incalwxtbg, j=',j
        do i=ista,iend
           lmhk  = min(nint(lmh(i,j)),lm)
           psfck = pint(i,j,lmhk+1)
!
           if (prec(i,j) <= pthresh) cycle    ! skip this point if no precip this time step

!     find the depth of the warm layer based at the surface
!     this will be the cut off point between computing
!     the surface based warm air and the warm air aloft
!
           tlmhk = t(i,j,lmhk)                ! lowest layer t
           iwrml = lmhk + 1
           if (tlmhk >= 273.15) then
             do l = lmhk, 2, -1
               if (t(i,j,l) >= 273.15 .and. t(i,j,l-1) < 273.15 .and.    &
     &             iwrml == lmhk+1) iwrml = l
             end do
           end if
!
!     now find the highest above freezing level
!
! gsm  added 250 mb check to prevent stratospheric warming situations
!       from counting as warm layers aloft
           lhiwrm = lmhk + 1
           do l = lmhk, 1, -1
             if (t(i,j,l) >= 273.15 .and. pmid(i,j,l) > 25000.) lhiwrm = l
           end do

!     energy variables

!  surfw  is the positive energy between ground and the first sub-freezing layer above ground
!  areane is the negative energy between ground and the highest layer above ground
!                                                               that is above freezing
!  areape is the positive energy "aloft" which is the warm energy not based at the ground
!                                                  (the total warm energy = surfw + areape)
!
!  pintk1 is the pressure at the bottom of the layer
!  pintk2 is the pressure at the top of the layer
!  dzkl  is the thickness of the layer
!  ifrzl is a flag that tells us if we have hit a below freezing layer
!
           pintk1 = psfck
           ifrzl  = 0
           areane = 0.0
           areape = 0.0
           surfw  = 0.0

           do l = lmhk, 1, -1
             if (ifrzl == 0.and.t(i,j,l) <= 273.15) ifrzl = 1
             pintk2 = pint(i,j,l)
             dzkl   = zint(i,j,l)-zint(i,j,l+1)
             area1  = log(t(i,j,l)/273.15) * g * dzkl
             if (t(i,j,l) >= 273.15.and. pmid(i,j,l) > 25000.) then
               if (l < iwrml) areape  = areape + area1
               if (l >= iwrml) surfw  = surfw  + area1
             else
               if (l > lhiwrm) areane = areane + abs(area1)
             end if
             pintk1 = pintk2
           end do
!
!     decision tree time
!
           if (areape < 2.0) then
!         very little or no positive energy aloft, check for
!         positive energy just above the surface to determine rain vs. snow
             if (surfw < 5.6) then
!             not enough positive energy just above the surface
!              snow = 1
               ptype(i,j) = 1
             else if (surfw > 13.2) then
!             enough positive energy just above the surface
!              rain = 8
               ptype(i,j) = 8
             else
!             transition zone, assume equally likely rain/snow
!             picking a random number, if <=0.5 snow
               r1 = rn(i+im*(j-1))
               if (r1 <= 0.5) then
                 ptype(i,j) = 1        !                   snow = 1
               else
                 ptype(i,j) = 8        !                   rain = 8
               end if
             end if
!
           else
!         some positive energy aloft, check for enough negative energy
!         to freeze and make ice pellets to determine ip vs. zr
             if (areane > 66.0+0.66*areape) then
!             enough negative area to make ip,
!             now need to check if there is enough positive energy
!             just above the surface to melt ip to make rain
               if (surfw < 5.6) then
!                 not enough energy at the surface to melt ip
                  ptype(i,j) = 2       !                   ice pellets = 2
               else if (surfw > 13.2) then
!                 enough energy at the surface to melt ip
                 ptype(i,j) = 8        !                   rain = 8
               else
!                 transition zone, assume equally likely ip/rain
!                 picking a random number, if <=0.5 ip
                 r1 = rn(i+im*(j-1))
                 if (r1 <= 0.5) then
                   ptype(i,j) = 2      !                   ice pellets = 2
                 else
                   ptype(i,j) = 8      !                   rain = 8
                 end if
               end if
             else if (areane < 46.0+0.66*areape) then
!             not enough negative energy to refreeze, check surface temp
!             to determine rain vs. zr
               if (tlmhk < 273.15) then
                 ptype(i,j) = 4        !                   freezing rain = 4
               else
                 ptype(i,j) = 8        !                   rain = 8
               end if
             else
!             transition zone, assume equally likely ip/zr
!             picking a random number, if <=0.5 ip
               r1 = rn(i+im*(j-1))
               if (r1 <= 0.5) then
!                 still need to check positive energy
!                 just above the surface to melt ip vs. rain
                 if (surfw < 5.6) then
                   ptype(i,j) = 2       !                   ice pellets = 2
                 else if (surfw > 13.2) then
                   ptype(i,j) = 8       !                   rain = 8
                 else
!                     transition zone, assume equally likely ip/rain
!                     picking a random number, if <=0.5 ip
                   r2 = rn(i+im*(j-1)+im*jm)
                   if (r2 <= 0.5) then
                     ptype(i,j) = 2     !                   ice pellets = 2
                   else
                     ptype(i,j) = 8     !                   rain = 8
                   end if
                 end if
               else
!                 not enough negative energy to refreeze, check surface temp
!                 to determine rain vs. zr
                 if (tlmhk < 273.15) then
                   ptype(i,j) = 4       !                 freezing rain = 4
                 else
                   ptype(i,j) = 8       !                 rain = 8
                 end if
               end if
             end if
           end if
!     write(1000+me,*)' finished for i, j,  from calbourge me=',me,i,j
        end do
!     write(1000+me,*)' finished for  j,  from calbourge me=',me,j
      end do
!     write(1000+me,*)' returning from calbourge me=',me
      return
      end
