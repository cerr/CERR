function DosesV = getQIBDose(PosU, zV, WidthUX, WidthUY, QIBDataS ,A_zV,a_zV, B_zV, b_zV, Energy, how2Compute, gaussSigma_100, distV);
% function getQIBDose
%
% PURPOSE:
% Fast pencil-beam dose calculation for photon beams.
%
% ALGORITHM DESCRIPTION:
%  This is based on an analytical fit of MC-generated PB data
%  due to Ahnesjo et al. [Med. Phys., Vol. 19, 263-273 (1992)].
%  The basic idea is to use a precomputed table of values for the
%  function  exp(-r)/r, and compute the expression
%  A[r,z]exp(-a[r,z]r)/r+B[r,z]exp(-b[r,z]r)/r, where the constants
%  are a function of the depth and the radial distance.  A variation, also
%  due to Ahnesjo, smears the incident fluence with a Gaussian.
%  The input data was supplied to me by Ahnesjo;  some data used by
%  Ahnesjo was obtained for the mixed energy beams from the University
%  Hospital, Lund, Sweden.
%
%  Fast table-lookup is used based on computed tables of
%  quandrant infinite integrals (integrals of the Gaussian or exponential kernel over,
%  say, the lower-right infinite 2-D quadrant).
%
%
% OUTPUTS:
%  'DosesV', the vector of doses associated with the input points.
%  Units are relative energy deposited per
%  (g/cm^3) from a point-monodirectional beam.
%
% GLOBAL VARIABLES MODIFIED:
% None
%
%
% LIMITATIONS:
%  Does not currently account for charged-particle contamination.
%  Uses nearest-neighbor interpolation into (a high resolution)
%  lookup table.
%
% COMPILED VERSION AVAILABLE?
%  No
%
% MODIFICATION HISTORY:
% 17 May 97         Original version, JOD (was getdph.m)
% CZ july 23, 2003  modified for Ahnesjo's full Gaussian and exponential model
%                   and computation time
% CZ july 25, 2003 bug fix for Modified A -term coefficient
% CZ august 10, 2003 speed up the B - term calculation time
% JOD 29 Oct 03, changed notation to use QBDataS structure.
% JOD 29 Oct 03, bug fix in kGauss expression.
% JOD Nov 03, modified structure considerably, renamed to getQIBDose.m
% JOD 4 July 06, 1st use of Gauss; *bugfix in kA expression*.
%              Re-organized; added header info.  Changed call options for how2Compute to one of:
%              {'primary','primary+scatter','scatter','GaussPrimary', or
%              'GaussPrimary+scatter'}.
%              Added input gaussSigma, which is the projected sigma at 100 cm from the source.
%              Fixed bug in kGauss expression.
%              Added input which is the distance to the source to the depth of the calculation
%              (needed to implement the Gaussian smearing).
% JJW 5 July 06, Testing.
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

Lim=size(QIBDataS.QIB);

LimG=size(QIBDataS.QIBGauss);

lowDoseCutoff = 10e-5;  %cut all doses below this value.


switch lower(how2Compute)

  case 'primary'


    %----------------Get A (primary) dose component------------------------%


    xVa=PosU(:,1);
    yVa=PosU(:,2);

    rV = (xVa.^2 + yVa.^2).^0.5;

    DosesV = zeros(size(rV));

    %Short cutoffs because this is the fast primary electron component.
    if Energy == 6
        cutoff = 1;
    elseif Energy == 18
        cutoff = 3;
    elseif Energy == 8
        cutoff = 2;
    end

    XCatch = (WidthUX/2 + cutoff);

    YCatch = (WidthUY/2 + cutoff);

    %These 4 replacements are for matlab 6.1 which treats 0x1 and [] as different types.
    if isempty(xVa)
        xVa = [];
    end
    if isempty(XCatch)
        XCatch = [];
    end
    if isempty(yVa)
        yVa = [];
    end
    if isempty(YCatch)
        YCatch = [];
    end
    compute2 = (xVa < XCatch & xVa > - XCatch) & (yVa < YCatch & yVa > - YCatch);

    if any(compute2)

        xRel1V = xVa(compute2) - WidthUX(compute2)/2;
        xRel2V = xVa(compute2) + WidthUX(compute2)/2;
        yRel1V = yVa(compute2) - WidthUY(compute2)/2;
        yRel2V = yVa(compute2) + WidthUY(compute2)/2;

        %Nearest neighbor interpolation

        %Convert to unscaled coords.
        UPrime1VX=xRel1V.*a_zV(compute2);
        UPrime2VX=xRel2V.*a_zV(compute2);
        UPrime1VY=yRel1V.*a_zV(compute2);
        UPrime2VY=yRel2V.*a_zV(compute2);

        %Convert to matrix coords
        U1VX=round(UPrime1VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U2VX=round(UPrime2VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U1VY=round(UPrime1VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);
        U2VY=round(UPrime2VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);

        %Check for out-of-bounds values:
        U1VX = clip(U1VX,1,Lim(1),'limits');
        U2VX = clip(U2VX,1,Lim(1),'limits');
        U1VY = clip(U1VY,1,Lim(1),'limits');    
        U2VY = clip(U2VY,1,Lim(1),'limits');

        S = size(QIBDataS.QIB);

        %For speed: equiv to sub2ind
        ind1 = U1VX + (U1VY-1) * S(1);
        ind2 = U2VX + (U1VY-1) * S(1);
        ind3 = U1VX + (U2VY-1) * S(1);
        ind4 = U2VX + (U2VY-1) * S(1);

        DosesAV = (QIBDataS.QIB(ind1)-QIBDataS.QIB(ind2)-QIBDataS.QIB(ind3)+QIBDataS.QIB(ind4));

        DosesAV = 2 * pi * DosesAV .* A_zV(compute2) ./ a_zV(compute2);

        DosesV(compute2) = DosesV(compute2) + DosesAV(:);

    end
    
  case 'scatter'


    %----------------Get B (scatter) dose component------------------------%


    xVa=PosU(:,1);
    yVa=PosU(:,2);

    rV = (xVa.^2 + yVa.^2).^0.5;

    DosesV = zeros(size(rV));

    if Energy == 6
        cutoff = 8;
    elseif Energy == 18
        cutoff = 8;
    elseif Energy == 8
        cutoff = 8;
    end

    XCatch = (WidthUX/2 + cutoff);

    YCatch = (WidthUY/2 + cutoff);

    %These 4 replacements are for matlab 6.1 which treats 0x1 and [] as different types.
    if isempty(xVa)
        xVa = [];
    end
    if isempty(XCatch)
        XCatch = [];
    end
    if isempty(yVa)
        yVa = [];
    end
    if isempty(YCatch)
        YCatch = [];
    end
    compute2 = (xVa < XCatch & xVa > - XCatch) & (yVa < YCatch & yVa > - YCatch);

    if any(compute2)

        xRel1V = xVa(compute2) - WidthUX(compute2)/2;
        xRel2V = xVa(compute2) + WidthUX(compute2)/2;
        yRel1V = yVa(compute2) - WidthUY(compute2)/2;
        yRel2V = yVa(compute2) + WidthUY(compute2)/2;

        %-------------------Get dose modified component B----------------------%
        %Nearest neighbor interpolation

        UPrime1VX=xRel1V.*b_zV(compute2);
        UPrime2VX=xRel2V.*b_zV(compute2);
        UPrime1VY=yRel1V.*b_zV(compute2);
        UPrime2VY=yRel2V.*b_zV(compute2);

        U1VX=round(UPrime1VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U2VX=round(UPrime2VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U1VY=round(UPrime1VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);
        U2VY=round(UPrime2VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);

        %Check for out-of-bounds values:
        U1VX = clip(U1VX,1,Lim(1),'limits');
        U2VX = clip(U2VX,1,Lim(1),'limits');
        U1VY = clip(U1VY,1,Lim(1),'limits');
        U2VY = clip(U2VY,1,Lim(1),'limits');

        %-------------------Get dose modified component B----------------------%
        S = size(QIBDataS.QIB);

        %For speed: equiv to sub2ind
        ind1 = U1VX + (U1VY-1) * S(1);
        ind2 = U2VX + (U1VY-1) * S(1);
        ind3 = U1VX + (U2VY-1) * S(1);
        ind4 = U2VX + (U2VY-1) * S(1);

        DosesBV = (QIBDataS.QIB(ind1)-QIBDataS.QIB(ind2)-QIBDataS.QIB(ind3)+QIBDataS.QIB(ind4));

        DosesBV = 2 * pi * DosesBV .* B_zV(compute2) ./ b_zV(compute2);

        DosesV(compute2) = DosesV(compute2) + DosesBV(:);

    end

  %case 'primary+scatter'
  case 'nogauss+scatter'

    DosesV = getQIBDose(PosU, zV, WidthUX, WidthUY, QIBDataS ,A_zV,a_zV, B_zV, b_zV, Energy, 'primary', gaussSigma_100, distV) + ...
             getQIBDose(PosU, zV, WidthUX, WidthUY, QIBDataS ,A_zV,a_zV, B_zV, b_zV, Energy, 'scatter', gaussSigma_100, distV);

  case 'gaussprimary'

    %---------Include Gaussian smear of primary alone-----------------------%


    sigma_zV = distV*(gaussSigma_100/100);                     % Gaussian spread, projected to distance zV.

    s_zV = ((QIBDataS.k1./a_zV.^2)+sigma_zV.^2).^0.5;                    % Gaussian sz

    tzV = a_zV./(1 + QIBDataS.k2.*a_zV.^2 .* sigma_zV.^2);             % Gaussian tz

    wzV = 1./(1+(sigma_zV.^2+a_zV.^2)./...                 % Gaussian wz
            (sigma_zV.^2+(QIBDataS.k3+QIBDataS.k4./sigma_zV).^2));

    kGauss =(1-wzV).*A_zV./a_zV;           % Gaussian term coefficient

    kAV = wzV .* A_zV ./a_zV;       % Modified A -term coefficient   

    %-----------First compute non-Gauss primary term---------------------%

    xVa=PosU(:,1);
    yVa=PosU(:,2);

    rV = (xVa.^2 + yVa.^2).^0.5;

    DosesV = zeros(size(rV));

    %Short cutoffs because this is the fast primary electron component.
    if Energy == 6
        cutoff = 1;
    elseif Energy == 18
        cutoff = 3;
    elseif Energy == 8
        cutoff = 2;
    end

    XCatch = (WidthUX/2 + cutoff);

    YCatch = (WidthUY/2 + cutoff);

    %These 4 replacements are for matlab 6.1 which treats 0x1 and [] as different types.
    if isempty(xVa)
        xVa = [];
    end
    if isempty(XCatch)
        XCatch = [];
    end
    if isempty(yVa)
        yVa = [];
    end
    if isempty(YCatch)
        YCatch = [];
    end
    compute2 = (xVa < XCatch & xVa > - XCatch) & (yVa < YCatch & yVa > - YCatch);

    if any(compute2)

        xRel1V = xVa(compute2) - WidthUX(compute2)/2;
        xRel2V = xVa(compute2) + WidthUX(compute2)/2;
        yRel1V = yVa(compute2) - WidthUY(compute2)/2;
        yRel2V = yVa(compute2) + WidthUY(compute2)/2;

        %Nearest neighbor interpolation

        %Convert to unscaled coords.
        UPrime1VX=xRel1V.*tzV(compute2);
        UPrime2VX=xRel2V.*tzV(compute2);
        UPrime1VY=yRel1V.*tzV(compute2);
        UPrime2VY=yRel2V.*tzV(compute2);

        %Convert to matrix coords
        U1VX=round(UPrime1VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U2VX=round(UPrime2VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U1VY=round(UPrime1VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);
        U2VY=round(UPrime2VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);

        %Check for out-of-bounds values:
        U1VX = clip(U1VX,1,Lim(1),'limits');
        U2VX = clip(U2VX,1,Lim(1),'limits');
        U1VY = clip(U1VY,1,Lim(1),'limits');
        U2VY = clip(U2VY,1,Lim(1),'limits');

        S = size(QIBDataS.QIB);

        %For speed: equiv to sub2ind
        ind1 = U1VX + (U1VY-1) * S(1);
        ind2 = U2VX + (U1VY-1) * S(1);
        ind3 = U1VX + (U2VY-1) * S(1);
        ind4 = U2VX + (U2VY-1) * S(1);

        DosesAV = (QIBDataS.QIB(ind1)-QIBDataS.QIB(ind2)-QIBDataS.QIB(ind3)+QIBDataS.QIB(ind4));

        %The following is modified to reflect just this component:
        DosesAV = 2 * pi * DosesAV .* kAV(compute2);

        DosesV(compute2) = DosesV(compute2) + DosesAV(:);

        %---------Compute GaussianPrimary dose----------------%

        %Note that Gauss matrix is same size

        %Convert to unscaled coords.: this time using scaling appropriate for Gaussian
        UPrime1VX=xRel1V./s_zV(compute2);
        UPrime2VX=xRel2V./s_zV(compute2);
        UPrime1VY=yRel1V./s_zV(compute2);
        UPrime2VY=yRel2V./s_zV(compute2);

        %Convert to matrix coords (same delta is used for Gaussian as for exponential)
        U1VX=round(UPrime1VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U2VX=round(UPrime2VX/QIBDataS.deltaQBM+QIBDataS.QBMidIndexX);
        U1VY=round(UPrime1VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);
        U2VY=round(UPrime2VY/QIBDataS.deltaQBM+QIBDataS.QBMidIndexY);

        %Check for out-of-bounds values:
        U1VX = clip(U1VX,1,Lim(1),'limits');
        U2VX = clip(U2VX,1,Lim(1),'limits');
        U1VY = clip(U1VY,1,Lim(1),'limits');
        U2VY = clip(U2VY,1,Lim(1),'limits');

        %For speed: equiv to sub2ind
        ind1 = U1VX + (U1VY-1) * S(1);
        ind2 = U2VX + (U1VY-1) * S(1);
        ind3 = U1VX + (U2VY-1) * S(1);
        ind4 = U2VX + (U2VY-1) * S(1);

        DosesGaussV = (QIBDataS.QIBGauss(ind1)-QIBDataS.QIBGauss(ind2)-...
                       QIBDataS.QIBGauss(ind3)+QIBDataS.QIBGauss(ind4));

        %The following is modified to reflect just this component
        DosesGaussV = 2 * pi * DosesGaussV .* kGauss(compute2);
       
        DosesV(compute2) = DosesV(compute2) + DosesGaussV(:);
    end

  case 'gaussprimary+scatter'

    DosesV = getQIBDose(PosU, zV, WidthUX, WidthUY, QIBDataS ,A_zV,a_zV, B_zV, b_zV, Energy, 'gaussprimary', gaussSigma_100, distV ) + ...
             getQIBDose(PosU, zV, WidthUX, WidthUY, QIBDataS ,A_zV,a_zV, B_zV, b_zV, Energy, 'scatter', gaussSigma_100, distV);


end  %end how2Compute cases

DosesV = DosesV .* [DosesV >= lowDoseCutoff];  %clip values at the specified limits.

%----------------------------End---------------------------------%
