!> @file
!> @brief Subroutine that computes PBL height based on bulk Richardson number.
!>
!> This routine computes the bulk Richardson number
!> and PBL height above surface.
!>     
!> @param[inout] PBLRI real PBL height above ground.
!>
!> ### Program history log:
!> Date | Programmer | Comments
!> -----|------------|---------
!> 2006-05-04 | M Tsidulko | Initial
!> 2021-09-02 | Bo Cui     | Decompose UPP in X direction          
!>   
!> @author M Tsidulko @date 2006-05-04
!-----------------------------------------------------------------------
!> @brief Subroutine that computes PBL height based on bulk Richardson number.
!>
!> @param[inout] PBLRI real PBL height above ground.
!-----------------------------------------------------------------------
      SUBROUTINE CALPBL(PBLRI)

!
      use vrbls3d, only: pmid, q, t, uh, vh, zmid
      use vrbls2d, only: fis
      use masks, only: vtm
      use params_mod, only: h10e5, capa, d608, h1, g, gi
      use ctlblk_mod, only: lm, im, jsta, jend, spval, jsta_m, jsta_2l, jend_2u, jend_m, &
                            ista, iend, ista_m, ista_2l, iend_2u, iend_m  
      use gridspec_mod, only: gridtype
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      implicit none
!     
!     DECLARE VARIABLES.
!     
      real,dimension(ista_2l:iend_2u,jsta_2l:jend_2u),intent(inout) :: PBLRI

      REAL, ALLOCATABLE :: THV(:,:,:)
      INTEGER IFRSTLEV(ista_2l:iend_2u,jsta_2l:jend_2u),ICALPBL(ista_2l:iend_2u,jsta_2l:jend_2u)   &
             ,LVLP(ista_2l:iend_2u,jsta_2l:jend_2u)
      REAL    RIF(ista_2l:iend_2u,jsta_2l:jend_2u)                                    &
             ,RIBP(ista_2l:iend_2u,jsta_2l:jend_2u),UBOT1(ista_2l:iend_2u,jsta_2l:jend_2u)         &
             ,VBOT1(ista_2l:iend_2u,jsta_2l:jend_2u),ZBOT1(ista_2l:iend_2u,jsta_2l:jend_2u)        &
             ,THVBOT1(ista_2l:iend_2u,jsta_2l:jend_2u)
      integer I,J,L,IE,IW
      real APE,BETTA,RICR,USTARR,WMIN,UHKL,ULKL,VHKL,VLKL,WNDSL,WNDSLP,  &
           UBOT,VBOT,VTOP,UTOP,THVTOP,ZTOP,WDL2,RIB
!     
!*************************************************************************
!     START CALRCHB HERE.
!     
      ALLOCATE ( THV(ISTA_2L:IEND_2U,JSTA_2L:JEND_2U,LM) )

!     INITIALIZE ARRAYS.
!
!$omp  parallel do private(i,j)
        DO J=JSTA,JEND
          DO I=ISTA,IEND
            PBLRI(I,J) = SPVAL
          ENDDO
        ENDDO
!
!     COMPUTE VIRTUAL POTENTIAL TEMPERATURE.
!
!$omp  parallel do private(i,j,l,ape)
      DO L=LM,1,-1
        DO J=JSTA,JEND
          DO I=ISTA,IEND
            if( PMID(I,J,L)<SPVAL) then
            APE        = (H10E5/PMID(I,J,L))**CAPA
            THV(I,J,L) = (Q(I,J,L)*D608+H1)*T(I,J,L)*APE
            endif
          ENDDO
        ENDDO
      ENDDO
!
!     COMPUTE BULK RICHARDSON NUMBER AS CODED IN GFS MODEL
!     AND RAOBS FOR VERIFICATION
!
!!$omp  parallel do
!!$omp& private(uhkl,ulkl,vhkl,vlkl,rib,ubot,utop,vbot,vtop,
!!$omp&         betta,ricr,ustarr,wmin,tvhtop,ztop,
!!$omp&         wndsl,wndslp,betta,ricr,ustarr,wmin 
!!$omp&       ,IFRSTLEV
!!$omp&       ,ICALPBL
!!$omp&       ,LVLP
!!$omp&       ,RIF
!!$omp&       ,RIBP
!!$omp&       ,UBOT1
!!$omp&       ,VBOT1
!!$omp&       ,ZBOT1
!!$omp&       ,THVBOT1)

!$omp  parallel do private(i,j)
      DO J=JSTA_M,JEND_M
        DO I=ISTA_M,IEND_M
           IFRSTLEV(I,J) = 0
           LVLP(I,J)     = LM
           ICALPBL(I,J)  = 0
        ENDDO
      ENDDO

      DO L = LM,2,-1

        BETTA  = 100.
        RICR   = 0.25
        USTARR = 0.1
        WMIN   = 0.01
!
!        if(GRIDTYPE /= 'A') THEN
          call exch(VTM(ista_2l,jsta_2l,L))
          call exch(UH(ista_2l,jsta_2l,L))
          call exch(VH(ista_2l,jsta_2l,L))  
          call exch(VTM(ista_2l,jsta_2l,L-1))
          call exch(UH(ista_2l,jsta_2l,L-1))
          call exch(VH(ista_2l,jsta_2l,L-1))
!        end if  
         
        DO J=JSTA_M,JEND_M
          DO I=ISTA_M,IEND_M
!
            if( PMID(I,J,L)<SPVAL) then

            RIF(I,J) = 0.
            IF(IFRSTLEV(I,J) == 0) THEN
              RIBP(I,J) = RIF(I,J)
            ENDIF

            IF(GRIDTYPE == 'A') THEN
              UBOT = UH(I,J,L)
              UTOP = UH(I,J,L-1)
              VBOT = VH(I,J,L)
              VTOP = VH(I,J,L-1)
            ELSE IF(GRIDTYPE == 'E') THEN
              IE = I+MOD(J+1,2) 
              IW = I+MOD(J+1,2)-1
!
!         WE NEED (U,V) WINDS AT A MASS POINT.  FOUR POINT
!         AVERAGE (U,V) WINDS TO MASS POINT.  NORMALIZE FOUR
!         POINT AVERAGE BY THE ACTUAL NUMBER OF (U,V) WINDS
!         USED IN THE AVERAGING.  VTM=1 IF WIND POINT IS
!         ABOVE GROUND.  VTM=0 IF BELOW GROUND.
!
              WNDSL  = VTM(I,J-1,L)+VTM(IW,J,L)+VTM(IE,J,L)+VTM(I,J+1,L)
              WNDSLP = VTM(I,J-1,L-1)+VTM(IW,J,L-1)+                       &
                       VTM(IE,J,L-1)+VTM(I,J+1,L-1)
              IF(WNDSL == 0. .OR. WNDSLP == 0.) cycle
              UBOT = (UH(I,J-1,L)+UH(IW,J,L)+UH(IE,J,L)+UH(I,J+1,L))/WNDSL  
              UTOP = (UH(I,J-1,L-1)+UH(IW,J,L-1)+UH(IE,J,L-1)+             &
                      UH(I,J+1,L-1))/WNDSLP
              VBOT = (VH(I,J-1,L)+VH(IW,J,L)+VH(IE,J,L)+VH(I,J+1,L))/WNDSL  
              VTOP = (VH(I,J-1,L-1)+VH(IW,J,L-1)+VH(IE,J,L-1)+             &
                      VH(I,J+1,L-1))/WNDSLP
            ELSE IF(GRIDTYPE == 'B')THEN
              IE=I 
              IW=I-1
              UBOT = (UH(IW,J-1,L)+UH(IW,J,L)+UH(IE,J-1,L)+UH(I,J,L))*0.25  
              UTOP = (UH(IW,J-1,L-1)+UH(IW,J,L-1)+UH(IE,J-1,L-1)+             &
                      UH(I,J,L-1))*0.25
              VBOT = (VH(IW,J-1,L)+VH(IW,J,L)+VH(IE,J-1,L)+VH(I,J,L))*0.25  
              VTOP = (VH(IW,J-1,L-1)+VH(IW,J,L-1)+VH(IE,J-1,L-1)+             &
                      VH(I,J,L-1))*0.25
            END IF

            IF(IFRSTLEV(I,J) == 0) THEN
              UBOT1(I,J)    = UBOT
              VBOT1(I,J)    = VBOT
              ZBOT1(I,J)    = ZMID(I,J,L)
              THVBOT1(I,J)  = THV(I,J,L)
              IFRSTLEV(I,J) = 1
            ENDIF

            THVTOP = THV(I,J,L-1)
            ZTOP   = ZMID(I,J,L-1)

!     
!         COMPUTE BULK RICHARDSON NUMBER.
!     
!  FOLLOWING VOGELEZANG AND HOLTSLAG (1996):

            WDL2 = (UTOP-UBOT1(I,J))**2 + (VTOP-VBOT1(I,J))**2 + WMIN**2
            RIB  = (G/THVBOT1(I,J))*(THVTOP-THVBOT1(I,J))*                  &
                   (ZTOP-ZBOT1(I,J))/(WDL2+BETTA*(USTARR**2))
!     
!         COMPUTE PBL HEIGHT
!     
! --------------------------------------------------------------------
!  IF BULK RICHARDSON NUMBER (RIB) EXCEEDS THE CRITICAL RICHARDSON
!  NUMBER (RICR), DETERMINE ABL HEIGHT USING LINEAR INTERPOLATION
!  BETWEEN HEIGHTS, AND PREVIOUS (RIBP) AND CURRENT (RIB) BULK
!  RICHARDSON NUMBERS. L IS BOUNDARY-LAYER TOP LEVEL NUMBER.
! --------------------------------------------------------------------
            IF (RIB>=RICR.AND.ICALPBL(I,J)==0) THEN
              PBLRI(I,J) = ZMID(I,J,L)+(ZMID(I,J,L-1)-ZMID(I,J,L))*      &
                           (RICR-RIBP(I,J))/(RIB-RIBP(I,J))
              ICALPBL(I,J) = 1

!-------- Extract surface height -----------------------------------

              PBLRI(I,J) = PBLRI(I,J)-FIS(I,J)*GI

            ENDIF
            
            RIBP(I,J) = RIB
            LVLP(I,J) = L-1
!
 10         CONTINUE

            endif !spval

          ENDDO
        ENDDO
      ENDDO
!     
      DEALLOCATE (THV)
!     END OF ROUTINE.
!     
      RETURN
      END

