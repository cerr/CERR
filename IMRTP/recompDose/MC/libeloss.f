c*******************************************************************
c* Short description                                               *
c*   Library of inelastic transport routines for electrons         *
c*                                                                 *
c* Dependencies:                                                   *
c*   -> uses libmath.f                                             *
c*                                                                 *
c* Last update                                                     *
c*   1998-04-12                                                    *
c*******************************************************************


c*******************************************************************
c*******************************************************************
c*  Landau's stuff follows                                         *
c*******************************************************************
c*******************************************************************


      real*8 function landau(lambda)
c*******************************************************************
c*    Landau's pdf of energy losses --phi(lambda)--                *
c*                                                                 *
c*    Input:                                                       *
c*      lambda -> energy loss adimensional var -see Landau's paper-*
c*    Output:                                                      *
c*      Integral of dphi over a vertical line in the complex plane *
c*      with Re(z)>0. It corresponds to the energy loss pdf except *
c*      for a constant that depends on the path length             *
c*    Comments:                                                    *
c*      -> sig (sigma), which is Re(z), is set depending on lambda,*
c*         the energy loss var. This is so because although the    *
c*         integral of dphi() does not "analytically" depend on sig*
c*         it does depend numerically on this quantity in some     *
c*         intervals                                               *
c*******************************************************************
      implicit none
      real*8 lamlsi,sig
      common /phil/ lamlsi,sig
      real*8 pi,tol,upperf,accu,fourpi
      parameter (pi=3.1415926535897932d0,tol=1.d-13,accu=1.d-15)
      parameter (fourpi=4.d0*pi)
      integer*8 error
      integer*8 nloops,i
      real*8 integ,lambda,dphi,lowlim,upplim,abslam
      external dphi
      
      upperf=(1.d0-dlog(pi*accu*(0.5d0*pi-1.d0)))/(0.5d0*pi-1.d0)
com: Sigma depends on lambda to avoid numerical instabilities
      abslam = dabs(lambda)
      if (lambda.lt.1.d0) then
        sig = 1.d0
      else
        sig = 1.d0/abslam
      endif
      lamlsi = lambda+dlog(sig)
com: setting integration upper limit to upperf/sig=upperf*lambda
      nloops = upperf/(sig*fourpi)+1
      landau = 0.d0
      do 10 i=nloops,1,-1
        upplim = fourpi*i
        lowlim = upplim-fourpi
com: integrating in [0,+Inf] in 4pi intervals
        call gabq(dphi,lowlim,upplim,integ,tol,error)
c        if (error.ne.0) write(*,*) 
c     &    'landau Warning: low accuracy in integration interval ',
c     &    lowlim,upplim
        landau = landau+integ
 10   continue
      landau = landau*sig*dexp(sig*lamlsi)/pi
      if (landau.lt.accu) landau = 0.d0
      end


      real*8 function dphi(tgthe)
c*******************************************************************
c*    Integrant of Landau's pdf function, except constants         *
c*                                                                 *
c*    Input:                                                       *
c*      tgthe -> tg(arg(z)), with z the complex integration var    *
c*    Comments:                                                    *
c*      -> lam (lambda), related to the energy loss, and sig       *
c*         (sigma=Re(z)) are passed through a common block         *
c*******************************************************************
      implicit none
      real*8 lamlsi,sig
      common /phil/ lamlsi,sig
      real*8 tgthe,lcos,theta

      lcos = 0.5d0*dlog(1.d0+tgthe*tgthe)
      theta = datan(tgthe)
      dphi = dexp(sig*(lcos-tgthe*theta))*
     &       dcos(sig*(theta+tgthe*(lamlsi+lcos)))
      end



c*******************************************************************
c*******************************************************************
c*  Moller model for electron inelastic collisions                 *
c*******************************************************************
c*******************************************************************


      real*8 function moller(eloss,energy)
c*******************************************************************
c*    Gives de Moller DCS for a sigle electron-electron collision  *
c*                                                                 *
c*    Input:                                                       *
c*      eloss -> energy loss in eV                                 *
c*      energy -> initial electron energy in eV                    *
c*    Output:                                                      *
c*      d_Sigma/d_Eloss in cm^2/eV                                 *
c*    Comments:                                                    *
c*      -> to get the atomic DCS, multiply by the atomic number    *
c*******************************************************************
      implicit none
      real*8 eloss,energy
      real*8 twopi,mc2,imc2,re2,facmol
      parameter (twopi=2.d0*3.14159265358979d0)
      parameter (mc2=510.9991d3,imc2=1.d0/mc2,re2=2.817941d-13**2)
      parameter (facmol=twopi*re2*mc2)
      real*8 gamma,igam2,ibeta2,k,ko,a

      gamma = 1.d0+energy*imc2
      igam2 = 1.d0/(gamma*gamma)
      a = igam2*(gamma-1.d0)**2
      ibeta2 = 1.d0/(1.d0-igam2)
      k = eloss/energy
      ko = k/(1.d0-k)
      moller = facmol*ibeta2/(eloss*eloss)*
     &         (1.d0+ko*(ko-1.d0)+a*(k*k+ko))     
      end
      
      
      real*8 function stpmo(energy)
c*******************************************************************
c*    Moller (hard) stopping power                                 *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      stopping power in eV*cm^2/g                                *
c*    Comments:                                                    *
c*      -> iniion() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 mc2,imc2,kcmax
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)
      parameter (kcmax=0.4999999999d0)
      real*8 stfact,kcut,gamma,igam2,a
      
      kcut = wcion/energy
      if (kcut.gt.kcmax) then
        stpmo = 0.d0
        return
      endif
      gamma = 1.d0+energy*imc2
      igam2 = 1.d0/(gamma*gamma)
      a = igam2*(gamma-1.d0)**2
      stfact = 2.d0-1.d0/(1.d0-kcut)-dlog(2.d0*kcut)+
     & (a-2.d0)*dlog(2.d0*(1.d0-kcut))+a*(0.125d0-0.5d0*kcut*kcut)
      stpmo = facion*stfact/(1.d0-igam2)
      end
      
      
      real*8 function stgmo(energy)
c*******************************************************************
c*    Straggling parameter for the Moller DCS, that is, the        *
c*    increase of the variance of the energy losses per unit       *
c*    path length                                                  *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      d_Var(Eloss)/d_(rho*s) in eV^2*cm^2/g                      *
c*    Comments:                                                    *
c*      -> iniion() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 eletwe,one3rd,kcut,gamma,gamma2,a,fac,log1kc
      real*8 mc2,imc2,kcmax
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)
      parameter (kcmax=0.4999999999d0)
      parameter (eletwe=-11.d0/24.d0,one3rd=1.d0/3.d0)

      kcut = wcion/energy
      if (kcut.gt.kcmax) then
        stgmo = 0.d0
        return
      endif
      gamma = 1.d0+energy*imc2
      gamma2 = gamma*gamma
      fac = facion*mc2*gamma2/(1.d0+gamma)
      a = (gamma-1.d0)**2/gamma2
      log1kc = dlog(2.d0*(1.d0-kcut))
      stgmo = fac*(3.5d0-3.d0*kcut-1.d0/(1.d0-kcut)+log1kc+
     &              a*(eletwe+kcut-one3rd*kcut**3+log1kc))
      end

 
      real*8 function lambmo(energy)
c*******************************************************************
c*    Moller mean free path                                        *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      MFP in g/cm^2                                              *
c*    Comments:                                                    *
c*      -> iniion() or iniine() must be called before 1st call     *
c*******************************************************************

      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 inf,mc2,imc2,kcmax
      parameter (inf=1.d30,mc2=510.9991d3,imc2=1.d0/mc2)
      parameter (kcmax=0.4999999999d0)
      real*8 lamfac,kcut,gamma,igam2,a
      
      kcut = wcion/energy
      if (kcut.gt.kcmax) then
        lambmo = +inf
        return
      endif
      gamma = 1.d0+energy*imc2
      igam2 = 1.d0/(gamma*gamma)
      a = igam2*(gamma-1.d0)**2
      lamfac = (1.d0-2.d0*kcut)*(a*0.5d0+1.d0/(kcut*(1.d0-kcut)))+
     &         (a-1.d0)*dlog(1.d0/kcut-1.d0) 
      lambmo = energy*(1.d0-igam2)/(facion*lamfac)
      if (lambmo.gt.inf) lambmo = +inf
      end
      
      
      real*8 function sammo(energy)
c*******************************************************************
c*    Samples an energy loss according to Moller DCS               *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      eloss/energy, energy loss fraction                         *
c*    Comments:                                                    *
c*      -> iniion() or iniine() must be called before 1st call     *
c*      -> inirng() must be called before 1st call                 *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 mc2,imc2,kcmax
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)
      parameter (kcmax=0.4999999999d0)
      real*8 ko,aelos2,rng,kcut,a

      kcut = wcion/energy
      if (kcut.lt.kcmax) then
        a = (1.d0-1.d0/(1.d0+energy*imc2))**2
 10     continue
          if (rng()*(1.d0+2.5d0*a*kcut).lt.1.d0) then
            sammo = kcut/(1.d0-rng()*(1.d0-2.d0*kcut))
          else
            sammo = kcut+rng()*(0.5d0-kcut)
          endif
          ko = sammo/(1.d0-sammo)
          aelos2 = a*sammo*sammo
          if (rng()*(1.d0+5.d0*aelos2).lt.1.d0+aelos2+ko*(a+ko-1.d0))
     &      return
        goto 10
      else
        sammo = 0.d0
      endif
      end
      
      
      real*8 function angmo(eloss,energy)
c*******************************************************************
c*    Angular deviation the outgoing primary electron after a      *
c*    Moller interaction                                           *
c*                                                                 *
c*    Input:                                                       *
c*      eloss -> energy loss --also kinetic energy of the recoil e-*
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      cos(theta) in the lab frame                                *
c*    Coments:                                                     *
c*      -> eloss must be less than energy/2.0                      *
c*******************************************************************

      implicit none
      real*8 eloss,energy
      real*8 mc2,twomc2
      parameter (mc2=510.9991d3,twomc2=2.d0*mc2)
      
      angmo = dsqrt((energy-eloss)*(energy+twomc2)/
     &              (energy*(energy-eloss+twomc2)))
      end
      
      
      real*8 function secmo(eloss,energy)
c*******************************************************************
c*    Gives the outgoing angle of the delta ray after a Moller     *
c*    interaction                                                  *
c*                                                                 *
c*    Input:                                                       *
c*      eloss -> energy loss --also kinetic energy of the recoil e-*
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      cos(theta') in the lab frame                               *
c*    Coments:                                                     *
c*      -> eloss must be less than energy/2.0                      *
c*******************************************************************
      implicit none
      real*8 eloss,energy
      real*8 mc2,twomc2
      parameter (mc2=510.9991d3,twomc2=2.d0*mc2)
      
      secmo = dsqrt(eloss*(energy+twomc2)/(energy*(eloss+twomc2)))
      end
      
      
      real*8 function scatru(energy)
c*******************************************************************
c*    Scattering power associated with the Rutherford DCS for an   *
c*    electron-electron inelastic collision                        *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      Scattering power 1/(rho*lamb_1) in cm^2/g                  *
c*    Comments:                                                    *
c*      -> iniion() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 kcmax,kcut,gamma,ibeta2,ialph2,coscut,cosmin,mc2,imc2
      parameter (kcmax=0.4999999999d0,mc2=510.9991d3,imc2=1.d0/mc2)
      real*8 zero
      parameter (zero=1.d-30)

      kcut = wcion/energy
      if (kcut.gt.kcmax) then
        scatru = zero
        return
      endif
      gamma = 1.d0+energy*imc2
      ibeta2 = 1.d0/(1.d0-1.d0/(gamma*gamma))
      ialph2 = (gamma-1.d0)/(gamma+1.d0)
      coscut = dsqrt((1.d0-kcut)/(1.d0-kcut*ialph2))
      cosmin = 1.d0/dsqrt(2.d0-ialph2)
      scatru = facion*ibeta2*2.d0/(energy*(1.d0+gamma))*
     &   ((cosmin-coscut)/((1.d0+cosmin)*(1.d0+coscut))+
     &    0.5d0*dlog((1.d0+coscut)*(1.d0-cosmin)/
     &               ((1.d0-coscut)*(1.d0+cosmin))))
      end
      
      
      real*8 function scatmo(energy)
c*******************************************************************
c*    Scattering power associated to the Moller DCS                *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      Scattering power G_1/(rho*lambda) in cm^2/g                *
c*    Comments:                                                    *
c*      -> iniion() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 e
      common /c01scm/ e
      integer*8 error
      real*8 navo,integ,accu,scatf,zero,kcmax
      parameter (navo=6.022137d23,accu=1.d-8,zero=1.d-30)
      parameter (kcmax=0.4999999999d0)
      external scatf

      if (wcion.gt.energy*kcmax) then
        scatmo = zero
        return
      endif
      e = energy
      call gabq(scatf,wcion,energy/2.d0,integ,accu,error)
      if (error.ne.0) 
     &   call mexprintf('scatmo Warning: gabq reported low accuracy')
      scatmo = navo/mass*integ
      end
      
      
      real*8 function scatf(eloss)
c*******************************************************************
c*    Function integrated by scatmo() to get the Moller scattering *
c*    power                                                        *
c*                                                                 *
c*    Input:                                                       *
c*      eloss -> energy loss in eV                                 *
c*    Comments:                                                    *
c*      -> This function for internal use only                     *
c*******************************************************************
      implicit none
      real*8 eloss
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 e
      common /c01scm/ e
      real*8 moller,angmo
      
      scatf = (1.d0-angmo(eloss,e))*atno*moller(eloss,e)
      end
      
      
      real*8 function sca2mo(energy)
c*******************************************************************
c*    2nd scattering power of the Moller DCS                       *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      2nd scattering power G_2/(rho*lambda) in cm^2/g            *
c*    Comments:                                                    *
c*      -> iniion() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 e
      common /c02scm/ e
      integer*8 error
      real*8 navo,integ,accu,sca2f,zero,kcmax
      parameter (navo=6.022137d23,accu=1.d-8,zero=1.d-30)
      parameter (kcmax=0.4999999999d0)
      external sca2f

      if (wcion.gt.energy*kcmax) then
        sca2mo = zero
        return
      endif
      e = energy
      call gabq(sca2f,wcion,energy/2.d0,integ,accu,error)
      if (error.ne.0) 
     &   call mexprintf('sca2mo Warning: gabq reported low accuracy')
      sca2mo = navo/mass*integ
      end
      
      
      real*8 function sca2f(eloss)
c*******************************************************************
c*    Function integrated by sca2mo() to get the Moller 2nd        *
c*    scattering power                                             *
c*                                                                 *
c*    Input:                                                       *
c*      eloss -> energy loss in eV                                 *
c*    Comments:                                                    *
c*      -> This function for internal use only                     *
c*******************************************************************
      implicit none
      real*8 eloss
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 e
      common /c02scm/ e
      real*8 moller,angmo,plege2
      
      plege2 = 1.5d0*angmo(eloss,e)**2-0.5d0
      sca2f = (1.d0-plege2)*atno*moller(eloss,e)
      end
      
      
      subroutine iniion(Uatno,Umass,Uwcion)
c*******************************************************************
c*    Sets values used by other routines                           *
c*                                                                 *
c*    Input:                                                       *
c*      atno -> material atomic number (total)                     *
c*      mass -> material atomic mass (in atomic mass units)        *
c*      wcion -> ionization energy loss cutoff (eV)                *
c*    Comments:                                                    *
c*      -> for compounds, the atomic number is the stoichiometric  *
c*         sum of all components                                   *
c*******************************************************************
      implicit none
      real*8 Uatno,Umass,Uwcion
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 twopi,mc2,re2,navo,cfac
      parameter (twopi=2.d0*3.14159265358979d0)
      parameter (mc2=510.9991d3,re2=2.817941d-13**2,navo=6.022137d23)
      parameter (cfac=navo*twopi*re2*mc2)

      atno = Uatno
      mass = Umass
      facion = cfac*atno/mass
      wcion = Uwcion
      end
      
      
      subroutine iniine(
     &               atno,atno2,mass,dens,excite,wcion,wcbre)
c*******************************************************************
c*    Sets values used by other routines                           *
c*    A call to this routine substitute calls to iniion(), iniexc()*
c*    and inibre()                                                 *
c*                                                                 *
c*    Input:                                                       *
c*      atno -> material atomic number (total)                     *
c*      atno2 -> square of the atomic number                       * 
c*      mass -> material atomic mass (in atomic mass units)        *
c*      dens -> material density (g/cm^3) --density effect         *
c*      excite -> mean excitation energy (eV) --density effect     *
c*      wcion -> ionization energy loss cutoff (eV)                *
c*      wcbre -> bremsstrahlung energy loss cutoff (eV)            *
c*    Comments:                                                    *
c*      -> for compounds, the atomic number is the stoichiometric  *
c*         sum of all components                                   *
c*      -> for compounds, the atomic number^2 is the stoichiometric*
c*         sum of the squared atomic numbers                       *
c*******************************************************************
      implicit none
      real*8 atno,atno2,mass,dens,excite,wcion,wcbre
      
      call iniion(atno,mass,wcion)
      call iniexc(atno,mass,dens,excite)
      call inibre(atno2,mass,wcbre)
      end
      


c*******************************************************************
c*******************************************************************
c*  Simple Bremsstrahlung model that roughly reproduces Seltzer &  *
c*  Berger's tables in NIMB 12 (1985) p95                          *
c*******************************************************************
c*******************************************************************


      real*8 function brems(erad,energy)
c*******************************************************************
c*    DCS for bremsstrahlung production                            *
c*                                                                 *
c*    Input:                                                       *
c*      erad -> radiated energy in eV                              *
c*      energy -> initial electron kinetic energy in eV            *
c*    Output:                                                      *
c*      d_Sigma/d_Erad in cm^2/eV                                  *
c*    Comments:                                                    *
c*      -> inibre() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 erad,energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 c1,c2,ic2
      common /cbre/ c1,c2,ic2
      real*8 mc2,imc2,beta2
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)

      beta2 = 1.d0-1.d0/(1.d0+energy*imc2)**2
      brems = (1.d0/erad-c2/energy)*c1*atno2/beta2
      end
      
      
      real*8 function stpbre(energy)
c*******************************************************************
c*    Bremsstrahlung (hard) stopping power                         *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> electron kinetic energy in eV                    *
c*    Output:                                                      *
c*      stopping power in eV*cm^2/g                                *
c*    Comments:                                                    *
c*      -> inibre() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 c1,c2,ic2
      common /cbre/ c1,c2,ic2
      real*8 mc2,imc2
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)
      real*8 kcut,beta2

      kcut = wcbre/energy
      if (kcut.gt.1.d0) then
        stpbre = 0.d0
        return
      endif
      beta2 = 1.d0-1.d0/(1.d0+energy*imc2)**2
      stpbre =
     & facbre*energy*c1*(1.d0-kcut)*(1.d0-0.5d0*c2*(1.d0+kcut))/beta2
      end
      
      
      real*8 function stgbre(energy)
c*******************************************************************
c*    Straggling parameter for the bremsstrahlung DCS, that is, the*
c*    increase of the variance of the energy losses per unit       *
c*    path length                                                  *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy in eV                             *
c*    Output:                                                      *
c*      d_Var(Eloss)/d_(rho*s) in eV^2*cm^2/g                      *
c*    Comments:                                                    *
c*      -> inibre() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 c1,c2,ic2
      common /cbre/ c1,c2,ic2
      real*8 kcut,gamma,fac,kcut2
      real*8 mc2,imc2,mc2sqr,one3rd
      parameter (mc2=510.9991d3,imc2=1.d0/mc2,mc2sqr=mc2*mc2)
      parameter (one3rd=1.d0/3.d0)

      kcut = wcbre/energy
      if (kcut.gt.1.d0) then
        stgbre = 0.d0
        return
      endif
      gamma = 1.d0+energy*imc2
      fac = facbre*mc2sqr*gamma*gamma*(gamma-1.d0)/(gamma+1.d0)*c1
      kcut2 = kcut*kcut
      stgbre = fac*(0.5d0*(1.d0-kcut2)-one3rd*c2*(1.d0-kcut2*kcut))
      end


      real*8 function lambre(energy)
c*******************************************************************
c*    Bremsstrahlung mean free path                                *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> electron kinetic energy in eV                    *
c*    Output:                                                      *
c*      MFP in g/cm^2                                              *
c*    Comments:                                                    *
c*      -> inibre() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 c1,c2,ic2
      common /cbre/ c1,c2,ic2
      real*8 zero,inf,kcut
      parameter (zero=1.d-30,inf=1.d30)
      real*8 mc2,imc2,beta2
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)

      kcut = wcbre/energy
      if (kcut.gt.1.d0) then
        lambre = +inf
        return
      endif
      beta2 = 1.d0-1.d0/(1.d0+energy*imc2)**2
      lambre = facbre*c1*(-dlog(kcut)-c2*(1.d0-kcut))
      if (lambre.gt.zero) then
        lambre = beta2/lambre
      else
        lambre = +inf
      endif
      end
      
      
      real*8 function sambre(energy)
c*******************************************************************
c*    Samples radiative energy losses                              *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> electron kinetic energy in eV                    *
c*    Output:                                                      *
c*      eloss/energy, energy loss fraction                         *
c*    Comments:                                                    *
c*      -> inibre() or iniine() must be called before 1st call     *
c*      -> inirng() must be called before 1st call                 *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 c1,c2,ic2
      common /cbre/ c1,c2,ic2
      real*8 rng,kcut,logkc
      
      kcut = wcbre/energy
      if (kcut.lt.1.d0) then
        logkc = dlog(kcut)
 10     continue
          sambre = dexp(rng()*logkc)
          if (rng()*(ic2-kcut).lt.(ic2-sambre)) return
        goto 10
      else  
        sambre = 0.d0
      endif
      end
      
      
      subroutine inibre(Uatno2,Umass,Uwcbre)
c*******************************************************************
c*    Sets values used by other routines                           *
c*                                                                 *
c*    Input:                                                       *
c*      atno2 -> square of the atomic number                       * 
c*      mass -> material atomic mass (in atomic mass units)        *
c*      wcbre -> bremsstrahlung energy loss cutoff (eV)            *
c*    Comments:                                                    *
c*      -> for compounds, the atomic number^2 is the stoichiometric*
c*         sum of the squared atomic numbers                       *
c*******************************************************************
      implicit none
      real*8 Uatno2,Umass,Uwcbre
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 wcion,wcbre
      common /cutoff/ wcion,wcbre
      real*8 c1,c2,ic2
      common /cbre/ c1,c2,ic2
      real*8 navo
      parameter (navo=6.022137d23)

com: Notice that c1>0 and 0<=c2<=1
com: c1,c2 are provisional, although roughly correct... I believe...
C
      c1 = 15.d-27
      c2 = 0.99d0
      ic2 = 1.d0/c2
      atno2 = Uatno2
      mass = Umass
      wcbre = Uwcbre
      facbre = atno2*navo/mass
      end



c*******************************************************************
c*******************************************************************
c*  Inelastic excitation routines                                  *
c*  An approximate model is adopted in which energy loss is fixed  *
c*  at the excitation energy, whereas the angular pdf corresponds  *
c*  to the PENELOPE GOS model                                      *
c*******************************************************************
c*******************************************************************


      real*8 function stpexc(energy)
c*******************************************************************
c*    Excitation stopping power                                    *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      Stopping power in eV*cm^2/g                                *
c*    Comments:                                                    *
c*      -> iniexc() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 ilamex

      stpexc = excite*ilamex(energy)
      end


      real*8 function densef(energy)
c*******************************************************************
c*    Density effect correction                                    *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      -> density effect delta                                    *
c*    Comments:                                                    *
c*      -> iniexc() or iniine() must be called before 1st call     *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 defarg
      real*8 mc2,imc2
      parameter (mc2=510.9991d3,imc2=1.d0/mc2)

      defarg = faciom/(1.d0+energy*imc2)**2
      if (defarg.lt.1.d0) then
        densef = defarg-dlog(defarg)-1.d0
      else
        densef = 0.d0
      endif
      end


      real*8 function ilamex(energy)
c*******************************************************************
c*    Inverse mean free path for excitation collisions             *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      inverse MFP in cm^2/g                                      *
c*    Comments:                                                    *
c*      -> iniexc() or iniine() must be called before 1st call     *
c*      -> this routine must use not less than real*8 to keep      *
c*         significant accuracy                                    *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 gamma2,beta2,cp2,cpnew2,qminus,densef
      real*8 mc2,imc2,twomc2,sqrmc2,oneeps,zero
      parameter (mc2=510.9991d3,imc2=1.d0/mc2,twomc2=2.d0*mc2)
      parameter (sqrmc2=mc2*mc2,oneeps=1.d0+1.d-6,zero=1.d-30)
      
      if (energy.lt.excite*oneeps) then
        ilamex = zero
        return
      endif
      gamma2 = (1.d0+energy*imc2)**2
      beta2 = 1.d0-1.d0/gamma2
com: get Q_; careful! Q_/mc2~(excite/mc2)^2~1e-8 => low accuracy
      cp2 = energy*(energy+twomc2)
      cpnew2 = (energy-excite)*(energy-excite+twomc2)
      qminus = dsqrt(cp2+cpnew2-2.d0*dsqrt(cp2*cpnew2)+sqrmc2)-mc2
      ilamex = facexc/beta2*(dlog((gamma2*excite*(qminus+twomc2))/
     &                            (qminus*(excite+twomc2)))-
     &                       beta2-densef(energy))
      end
      
      
      real*8 function angexc(costhe,energy)
c*******************************************************************
c*    PDF for the angular deflection after an excitation collision *
c*                                                                 *
c*    Input:                                                       *
c*      costhe -> cos(theta)                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      p(cos(theta))                                              *
c*    Comments:                                                    *
c*      -> iniexc() or iniine() must be called before 1st call     *
c*      -> this routine must use not less than real*8 to keep      *
c*         significant accuracy                                    *
c*******************************************************************
      implicit none
      real*8 costhe,energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 mc2,twomc2,oneeps
      parameter (mc2=510.9991d3,twomc2=2.d0*mc2,oneeps=1.d0+1.d-6)
      real*8 cp2,cpnew2,twopp,fac

      if (energy.lt.excite*oneeps) then
        call mexprintf('angexc Error: energy cannot be > excite')
        stop
      endif
      cp2 = energy*(energy+twomc2)
      cpnew2 = (energy-excite)*(energy-excite+twomc2)
      twopp = 2.d0*dsqrt(cp2*cpnew2)
      fac = dlog(excite*(excite+twomc2)/(cp2+cpnew2-twopp))
      angexc = twopp/(fac*(cp2+cpnew2-twopp*costhe))
      end


      real*8 function samexc(energy)
c*******************************************************************
c*    Samples the angular deflection after an excitation collision *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      cos(theta)                                                 *
c*    Comments:                                                    *
c*      -> iniexc() or iniine() must be called before 1st call     *
c*      -> inirng() must be called before 1st call                 *
c*      -> this routine must use not less than real*8 to keep      *
c*         significant accuracy                                    *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 mc2,twomc2,oneeps
      parameter (mc2=510.9991d3,twomc2=2.d0*mc2,oneeps=1.d0+1.d-6)
      real*8 cp2,cpnew2,twopp,difcp2,arg,fac,rng

      if (energy.lt.excite*oneeps) then
        call mexprintf('samexc Error: energy cannot be > excite')
        stop
      endif
      cp2 = energy*(energy+twomc2)
      cpnew2 = (energy-excite)*(energy-excite+twomc2)
      twopp = 2.d0*dsqrt(cp2*cpnew2)
      difcp2 = cp2+cpnew2-twopp
      arg = excite*(excite+twomc2)/difcp2
      fac = dlog(arg)
      samexc = 1.d0+difcp2/twopp*(1.d0-arg*dexp(-fac*rng()))
      end


      real*8 function excG1(energy)
c*******************************************************************
c*    1st transport coef for excitation collisions                 *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      G_1 = 1-<cos(theta)>                                       *
c*    Comments:                                                    *
c*      -> iniexc() or iniine() must be called before 1st call     *
c*      -> this routine must use not less than real*8 to keep      *
c*         significant accuracy                                    *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 mc2,twomc2,oneeps,zero
      parameter (mc2=510.9991d3,twomc2=2.d0*mc2,oneeps=1.d0+1.d-6)
      parameter (zero=1.d-30)
      real*8 cp2,cpnew2,twopp,difcp2,arg,fac

      if (energy.lt.excite*oneeps) then
        excG1 = zero
        return
      endif
      cp2 = energy*(energy+twomc2)
      cpnew2 = (energy-excite)*(energy-excite+twomc2)
      twopp = 2.d0*dsqrt(cp2*cpnew2)
      difcp2 = cp2+cpnew2-twopp
      arg = excite*(excite+twomc2)/difcp2
      fac = dlog(arg)
      excG1 = difcp2*(arg-1.d0-fac)/(fac*twopp)
      end


      real*8 function excmin(energy)
c*******************************************************************
c*    Minimum cos(theta) allowed by the excitation collision model *
c*    being used                                                   *
c*                                                                 *
c*    Input:                                                       *
c*      energy -> kinetic energy (eV)                              *
c*    Output:                                                      *
c*      Min(costhe)                                                *
c*    Comments:                                                    *
c*      -> iniexc() or iniine() must be called before 1st call     *
c*      -> this routine must use not less than real*8 to keep      *
c*         significant accuracy                                    *
c*******************************************************************
      implicit none
      real*8 energy
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 mc2,twomc2,oneeps
      parameter (mc2=510.9991d3,twomc2=2.d0*mc2,oneeps=1.d0+1.d-6)
      real*8 cp2,cpnew2

      if (energy.lt.excite*oneeps) then
        excmin = 1.d0
        return
      endif
      cp2 = energy*(energy+twomc2)
      cpnew2 = (energy-excite)*(energy-excite+twomc2)
      excmin = (cp2+cpnew2-excite*(excite+twomc2))/
     &         (2.d0*dsqrt(cp2*cpnew2))
      end


      subroutine iniexc(Uatno,Umass,Udens,Uexcite)
c*******************************************************************
c*    Sets values used by other routines                           *
c*                                                                 *
c*    Input:                                                       *
c*      atno -> material atomic number (total)                     *
c*      mass -> material atomic mass (in atomic mass units)        *
c*      dens -> material density (g/cm^3)                          *
c*      excite -> mean excitation energy (eV)                      *
c*    Comments:                                                    *
c*      -> for compounds, the atomic number is the stoichiometric  *
c*         sum of all components                                   *
c*******************************************************************
      implicit none
      real*8 Uatno,Umass,Udens,Uexcite
      real*8 atno,atno2,atno21,mass,dens,excite
      common /mater/ atno,atno2,atno21,mass,dens,excite
      real*8 facion,facbre,facexc,faciom
      common /factor/ facion,facbre,facexc,faciom
      real*8 twopi,mc2,re2,navo,cfac,hfac
      parameter (twopi=2.d0*3.14159265358979d0)
      parameter (mc2=510.9991d3,re2=2.817941d-13**2,navo=6.022137d23)
      parameter (cfac=navo*twopi*re2*mc2,hfac=8.303582d2)
      
      atno = Uatno
      mass = Umass
      dens = Udens
      excite = Uexcite
      facexc = cfac*atno/(mass*excite)
      faciom = excite*excite*mass/(hfac*atno*dens)
      end
      
      
c* end of file *****************************************************




