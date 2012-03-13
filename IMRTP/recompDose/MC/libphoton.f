c*******************************************************************
c* Short description                                               *
c*   Library of transport routines for photons                     *
c*                                                                 *
c* Dependencies:                                                   *
c*   -> uses libmat.f                                              *
c*   -> uses libmath.f                                             *
c*                                                                 *
c* Last update                                                     *
c*   1999-08-31                                                    *
c*******************************************************************


      real*8 function dcomp(eout,ein)
c*******************************************************************
c*    Klein-Nishina DCS for Compton scattering                     *
c*                                                                 *
c*    Input:                                                       *
c*      eout -> energy of the outgoing photon in eV                *
c*      ein -> energy of the incoming photon in eV                 *
c*    Output:                                                      *
c*      d_Sigma/d_Eout in cm^2/eV                                  *
c*******************************************************************
      implicit none
      real*8 eout,ein
      real*8 e0,e1,e0sqr,pi,re,mc2,imc2,pirmc2
      parameter (pi=3.1415926535897932d0,re=2.81794092d-13)
      parameter (mc2=510.99906d3,imc2=1.d0/mc2,pirmc2=pi*re*re*imc2)
      
      e0 = ein*imc2
      e1 = eout/ein
      e0sqr = e0*e0
      dcomp = pirmc2/(e0sqr*e0sqr*e1*e1)*
     &  (1.d0+e1*(e0sqr-2.d0*e0-2.d0+e1*(2.d0*e0+1.d0+e1*e0sqr)))
      end


      real*8 function compton(energy)
c*******************************************************************
c*    Klein-Nishina total CS for Compton scattering                *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> photon energy in eV                              *
c*    Output:                                                      *
c*      Cross section in cm^2                                      *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 e0,e0sqr,twoe01,pire2,pi,re,mc2,imc2
      parameter (pi=3.1415926535897932d0,re=2.817941d-13)
      parameter (pire2=pi*re*re,mc2=510.9991d3,imc2=1.d0/mc2)
      
      e0 = energy*imc2
      e0sqr = e0*e0
      twoe01 = 2.d0*e0+1.d0
      compton = pire2/(e0sqr*e0*twoe01*twoe01)*
     &  (twoe01*twoe01*(4.d0*e0+(e0sqr-2.d0*e0-2.d0)*dlog(twoe01)+
     &   e0sqr*e0*(1.d0+twoe01)))
      end
      
      
      subroutine comsam(energy,efrac,costhe)
c*******************************************************************
c*    Samples a Compton event following Klein-Nishina DCS          *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> photon energy in eV                              *
c*    Output:                                                      *
c*      efrac -> fraction of initial energy kept by 2nd photon     *
c*      costhe -> cos(theta) of the 2nd photon                     *
c*    Comments:                                                    *
c*      -> inirng() must be called before 1st call                 *
c*******************************************************************
      implicit none
      real*8 energy,efrac,costhe
      real*8 e0,imc2,mc2,twoe,kmin2,loge,rng,mess
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)
      
      e0 = energy*imc2
      twoe = 2.d0*e0
      kmin2 = 1.d0/(1.d0+twoe)**2
      loge = dlog(1.d0+twoe)

 10   continue
        if (rng()*(loge+twoe*(1.d0+e0)*kmin2).lt.loge) then
          efrac = dexp(-rng()*loge)
        else
          efrac = dsqrt(kmin2+rng()*(1.d0-kmin2))
        endif
        mess = e0*e0*efrac*(1.d0+efrac*efrac)
      if (rng()*mess.gt.mess-(1.d0-efrac)*((1.d0+twoe)*efrac-1.d0))
     &  goto 10

      costhe = 1.d0-(1.d0-efrac)/(efrac*e0)
      end


      real*8 function comang(energy,efrac)
c*******************************************************************
c*    Gives the angular deviation of a photon after a Compton      *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> photon energy in eV                              *
c*      efrac -> fraction of initial energy kept by 2nd photon     *
c*    Output:                                                      *
c*      -> cos(theta) of the 2nd photon                            *
c*******************************************************************
      implicit none
      real*8 energy,efrac
      real*8 mc2,imc2,e0
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)

      e0 = energy*imc2
      comang = 1.d0-(1.d0-efrac)/(efrac*e0)
      end


      real*8 function comele(energy,efrac,costhe)
c*******************************************************************
c*    Compton angular deviation of the secondary electron          *
c*    Input:                                                       *
c*      energy -> photon energy in eV                              *
c*      efrac -> fraction of initial energy kept by 2nd photon     *
c*      costhe-> photon scattering angle                           *
c*    Output:                                                      *
c*      -> cos(theta) of the 2nd electron                          *
c*******************************************************************
      implicit none
      real*8 energy,efrac,costhe
      real*8 mc2,imc2,e0
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)

c-opt-ComptonE-ON -> switch following lines for last three 
c     e0=energy**2+(energy*efrac*(energy*efrac-2.d0*energy*costhe))
c     if(e0.gt.1.0d-12) then
c       comele=(energy-energy*efrac*costhe)/dsqrt(e0)
c     else
c       comele=1.d0
c     endif
      e0 = energy*imc2
      comele = (1.d0+e0)*dsqrt((1.d0-efrac)/
     &                         (e0*(2.d0+e0*(1.d0-efrac))))
      end

c* end of file *****************************************************


