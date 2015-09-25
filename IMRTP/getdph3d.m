function DosesV = getdph3d(PosU, zV, WidthUX, WidthUY, QIBDataS ,A_zV,a_zV, B_zV, b_zV, Energy);

% CZ july 16, 2003
% CZ july 23, 2003  modified for Ahnesjo's full Gaussian and exponential model
%                   and computation time
% CZ july 25, 2003 bug fix for Modified A -term coefficient
% CZ august 10, 2003 speed up the B - term calculation time
% JOD 29 Oct 03, changed notation to use QBDataS structure.
% JOD 29 Oct 03, bug fix in kGauss expression.
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

sigma_zV = zV*(QIBDataS.sigma_100/100);                     % Gaussian spread parameter sigmaZ, sigma_100 = 0.5

s_sqr = (QIBDataS.k1./a_zV.^2)+sigma_zV.^2;                    % Gaussian sz

tzV = a_zV./(1 + QIBDataS.k2.*a_zV.^2 .* sigma_zV.^2);             % Gaussian tz

wzV = 1./(1+(sigma_zV.^2+a_zV.^2)./...                 % Gaussian wz
        (sigma_zV.^2+(QIBDataS.k3+QIBDataS.k4./sigma_zV).^2));


kGauss = 2*(1-wzV).*A_zV./(a_zV.*sigma_zV.^2);           % Gaussian term coefficient

kA = wzV.*A_zV./a_zV;                                % Modified A -term coefficient


kB = B_zV./b_zV;                                    % B - term coefficient


xVa=PosU(:,1);
yVa=PosU(:,2);

xS = length(xVa);
yS = length(yVa);


rV = (xVa.^2 + yVa.^2).^0.5;

s = ((WidthUX/2).^2 + (WidthUY/2).^2).^0.5;

nearField = [rV < (s + (1./a_zV) * 5)] | [ rV < (sigma_zV * 3)];


nearField = ones(size(nearField)); %Compute all points for now

Index = find(nearField);

%if ~isempty(Index)

xStart = Index(1);
xStop  = Index(end);

yStart = xStart;
yStop = xStop;

% xVV = xVa(xStart:xStop);
% yVV = yVa(xStart:xStop);

xVV = xVa;
yVV = yVa;

%DosesBV = zeros(xS,yS);

xRel1V=xVV-WidthUX/2;
xRel2V=xVV+WidthUX/2;
yRel1V=yVV-WidthUY/2;
yRel2V=yVV+WidthUY/2;


%----------------Get dose component B------------------------%

UPrime1VX=abs(xRel1V.*b_zV);
UPrime2VX=abs(xRel2V.*b_zV);
UPrime1VY=abs(yRel1V.*b_zV);
UPrime2VY=abs(yRel2V.*b_zV);

UPrime1VX=UPrime1VX.*[UPrime1VX>-QIBDataS.QBMIndexOffsetX]-...
    (QIBDataS.QBMIndexOffsetX).*[UPrime1VX<=-QIBDataS.QBMIndexOffsetX];

UPrime2VX=UPrime2VX.*[UPrime2VX>-QIBDataS.QBMIndexOffsetX]-...
    (QIBDataS.QBMIndexOffsetX).*[UPrime2VX<=-QIBDataS.QBMIndexOffsetX];

UPrime1VY=UPrime1VY.*[UPrime1VY>-QIBDataS.QBMIndexOffsetY]-...
    (QIBDataS.QBMIndexOffsetY).*[UPrime1VY<=-QIBDataS.QBMIndexOffsetY];

UPrime2VY=UPrime2VY.*[UPrime2VY>-QIBDataS.QBMIndexOffsetY]-...
    (QIBDataS.QBMIndexOffsetY).*[UPrime2VY<=-QIBDataS.QBMIndexOffsetY];

URel1VX=((UPrime1VX+QIBDataS.QBMIndexOffsetX)/QIBDataS.deltaQBM+1).*sign(xRel1V);
URel2VX=((UPrime2VX+QIBDataS.QBMIndexOffsetX)/QIBDataS.deltaQBM+1).*sign(xRel2V);

URel1VY=((UPrime1VY+QIBDataS.QBMIndexOffsetY)/QIBDataS.deltaQBM+1).*sign(yRel1V);
URel2VY=((UPrime2VY+QIBDataS.QBMIndexOffsetY)/QIBDataS.deltaQBM+1).*sign(yRel2V);

clear UPrime1VX UPrime2VX UPrime1VY UPrime2VY

%Nearest neighbor interpolation:
U1VX=URel1VX+QIBDataS.QBMidIndexX;
U2VX=URel2VX+QIBDataS.QBMidIndexX;
U1VY=URel1VY+QIBDataS.QBMidIndexY;
U2VY=URel2VY+QIBDataS.QBMidIndexY;

%U1VX=round(URel1VX+QIBDataS.QBMidIndexX);
%U2VX=round(URel2VX+QIBDataS.QBMidIndexX);
%U1VY=round(URel1VY+QIBDataS.QBMidIndexY);
%U2VY=round(URel2VY+QIBDataS.QBMidIndexY);

%Check for out-of-bounds values:
U1VX=U1VX.*[U1VX<=Lim(1)].*[U1VX>0]+1*[U1VX<=0]+Lim(1).*[U1VX>Lim(1)];
U2VX=U2VX.*[U2VX<=Lim(1)].*[U2VX>0]+1*[U2VX<=0]+Lim(1).*[U2VX>Lim(1)];
U1VY=U1VY.*[U1VY<=Lim(2)].*[U1VY>0]+1*[U1VY<=0]+Lim(2).*[U1VY>Lim(2)];
U2VY=U2VY.*[U2VY<=Lim(2)].*[U2VY>0]+1*[U2VY<=0]+Lim(2).*[U2VY>Lim(2)];

if U1VX == U2VX | U1VY == U2VY
    warning('Interpolation was too fine for QIB matrix, dose calculation is inaccurate')
end

%S = size(QIBDataS.QIB);
%ind1 = sub2ind(S,U1VX,U1VY);
%ind2 = sub2ind(S,U2VX,U1VY);
%ind3 = sub2ind(S,U1VX,U2VY);
%ind4 = sub2ind(S,U2VX,U2VY);

%QI = interp2(QIBDataS.QIB,U1VX,U1VY,'linear');
%QII = interp2(QIBDataS.QIB,U2VX,U1VY,'linear');
%QIII = interp2(QIBDataS.QIB,U1VX,U2VY,'linear');
%QIV = interp2(QIBDataS.QIB,U2VX,U2VY,'linear');

QI = linear2(QIBDataS.QIB,U1VX,U1VY);
QII = linear2(QIBDataS.QIB,U2VX,U1VY);
QIII = linear2(QIBDataS.QIB,U1VX,U2VY);
QIV = linear2(QIBDataS.QIB,U2VX,U2VY);

%DosesBVV = (QIBDataS.QIB(ind1)-QIBDataS.QIB(ind2)-QIBDataS.QIB(ind3)+QIBDataS.QIB(ind4));

DosesBVV = QI-QII-QIII+QIV;


DosesBVV = DosesBVV .* kB;

clear U1VX U2VX URel1VX URel2VX U1VY U2VY URel1VY URel2VY

clear xRel1V xRel2V yRel1V yRel2V

% DosesBV(xStart:xStop,yStart:yStop) = DosesBVV;

DosesBV = DosesBVV;
% Cut off the calculation time

if Energy == 6
    cutoff = 1;          %For 6MV the cutoff distance is 1 cm from PB edge
elseif Energy == 18      %For 18MV the cutoff distance is 3 cm from PB edge
    cutoff = 3;
elseif Energy == 8
    cutoff = 2;
end

%DosesAG = zeros(xS,yS);

XCatch = (WidthUX/2 + cutoff);

YCatch = (WidthUY/2 + cutoff);

%XLow  = xVa + XCatch;
%XHigh = xVa - XCatch;

%YLow  = yVa + YCatch;
%YHigh = yVa - YCatch;

%[xx,xStartI] = min(abs(XLow));
%[xx,xStopI]  = min(abs(XHigh));

%[yy,yStartI] = min(abs(YLow));
%[yy,yStopI]  = min(abs(YHigh));

%xStart = min(xStartI);
%yStart = min(yStartI);

%xStop = max(xStopI);
%yStop = max(yStopI);

%xV = xVa(xStart:xStop);
%yV = yVa(yStart:yStop);

compute = (xVa < XCatch & xVa > - XCatch) & (yVa < YCatch & yVa > - YCatch);

xRel1V = xVa(compute) - WidthUX(compute)/2;
xRel2V = xVa(compute) + WidthUX(compute)/2;
yRel1V = yVa(compute) - WidthUY(compute)/2;
yRel2V = yVa(compute) + WidthUY(compute)/2;


%-------------------Get dose modified component A----------------------%

UPrime1VX=abs(xRel1V.*tzV(compute));
UPrime2VX=abs(xRel2V.*tzV(compute));
UPrime1VY=abs(yRel1V.*tzV(compute));
UPrime2VY=abs(yRel2V.*tzV(compute));


UPrime1VX=UPrime1VX.*[UPrime1VX>-QIBDataS.QBMIndexOffsetX]-...
    (QIBDataS.QBMIndexOffsetX).*[UPrime1VX<=-QIBDataS.QBMIndexOffsetX];

UPrime2VX=UPrime2VX.*[UPrime2VX>-QIBDataS.QBMIndexOffsetX]-...
    (QIBDataS.QBMIndexOffsetX).*[UPrime2VX<=-QIBDataS.QBMIndexOffsetX];

UPrime1VY=UPrime1VY.*[UPrime1VY>-QIBDataS.QBMIndexOffsetY]-...
    (QIBDataS.QBMIndexOffsetY).*[UPrime1VY<=-QIBDataS.QBMIndexOffsetY];

UPrime2VY=UPrime2VY.*[UPrime2VY>-QIBDataS.QBMIndexOffsetY]-...
    (QIBDataS.QBMIndexOffsetY).*[UPrime2VY<=-QIBDataS.QBMIndexOffsetY];


URel1VX=((UPrime1VX+QIBDataS.QBMIndexOffsetX)/QIBDataS.deltaQBM+1).*sign(xRel1V);
URel2VX=((UPrime2VX+QIBDataS.QBMIndexOffsetX)/QIBDataS.deltaQBM+1).*sign(xRel2V);

URel1VY=((UPrime1VY+QIBDataS.QBMIndexOffsetY)/QIBDataS.deltaQBM+1).*sign(yRel1V);
URel2VY=((UPrime2VY+QIBDataS.QBMIndexOffsetY)/QIBDataS.deltaQBM+1).*sign(yRel2V);

clear UPrime1VX UPrime2VX UPrime1VY UPrime2VY

%Nearest neighbor interpolation:
U1VX=URel1VX+QIBDataS.QBMidIndexX;
U2VX=URel2VX+QIBDataS.QBMidIndexX;
U1VY=URel1VY+QIBDataS.QBMidIndexY;
U2VY=URel2VY+QIBDataS.QBMidIndexY;

%U1VX=round(URel1VX+QIBDataS.QBMidIndexX);
%U2VX=round(URel2VX+QIBDataS.QBMidIndexX);
%U1VY=round(URel1VY+QIBDataS.QBMidIndexY);
%U2VY=round(URel2VY+QIBDataS.QBMidIndexY);

%Check for out-of-bounds values:
U1VX=U1VX.*[U1VX<=Lim(1)].*[U1VX>0]+1*[U1VX<=0]+Lim(1).*[U1VX>Lim(1)];
U2VX=U2VX.*[U2VX<=Lim(1)].*[U2VX>0]+1*[U2VX<=0]+Lim(1).*[U2VX>Lim(1)];
U1VY=U1VY.*[U1VY<=Lim(2)].*[U1VY>0]+1*[U1VY<=0]+Lim(2).*[U1VY>Lim(2)];
U2VY=U2VY.*[U2VY<=Lim(2)].*[U2VY>0]+1*[U2VY<=0]+Lim(2).*[U2VY>Lim(2)];

%-------------------Get dose modified component A----------------------%
                %S = size(QIBDataS.QIB);
%ind1 = sub2ind(S,U1VX,U1VY);
%ind2 = sub2ind(S,U2VX,U1VY);
%ind3 = sub2ind(S,U1VX,U2VY);
%ind4 = sub2ind(S,U2VX,U2VY);

%QI = interp2(QIBDataS.QIB,U1VX,U1VY,'linear');
%QII = interp2(QIBDataS.QIB,U2VX,U1VY,'linear');
%QIII = interp2(QIBDataS.QIB,U1VX,U2VY,'linear');
%QIV = interp2(QIBDataS.QIB,U2VX,U2VY,'linear');

QI = linear2(QIBDataS.QIB,U1VX,U1VY);
QII = linear2(QIBDataS.QIB,U2VX,U1VY);
QIII = linear2(QIBDataS.QIB,U1VX,U2VY);
QIV = linear2(QIBDataS.QIB,U2VX,U2VY);


%ind1 = sub2ind(S,U1VX,U1VY);
%ind2 = sub2ind(S,U2VX,U1VY);
%ind3 = sub2ind(S,U1VX,U2VY);
%ind4 = sub2ind(S,U2VX,U2VY);

DosesAV = QI-QII-QIII+QIV;

%DosesAV = (QIBDataS.QIB(ind1)-QIBDataS.QIB(ind2)-QIBDataS.QIB(ind3)+QIBDataS.QIB(ind4));
DosesAV = DosesAV .* kA(compute);

%DosesAV=kA*(QIBDataS.QIB(U1VX,U1VY)-QIBDataS.QIB(U2VX,U1VY)-QIBDataS.QIB(U1VX,U2VY)+QIBDataS.QIB(U2VX,U2VY));

clear U1VX U2VX URel1VX URel2VX U1VY U2VY URel1VY URel2VY

%----------------Get dose component Gauss------------------------%

UPrime1VX=abs(xRel1V./s_sqr(compute).^2);
UPrime2VX=abs(xRel2V./s_sqr(compute).^2);
UPrime1VY=abs(yRel1V./s_sqr(compute).^2);
UPrime2VY=abs(yRel2V./s_sqr(compute).^2);

UPrime1VX=UPrime1VX.*[UPrime1VX>-QIBDataS.QBMIndexOffsetX]-...
    (QIBDataS.QBMIndexOffsetX).*[UPrime1VX<=-QIBDataS.QBMIndexOffsetX];

UPrime2VX=UPrime2VX.*[UPrime2VX>-QIBDataS.QBMIndexOffsetX]-...
    (QIBDataS.QBMIndexOffsetX).*[UPrime2VX<=-QIBDataS.QBMIndexOffsetX];

UPrime1VY=UPrime1VY.*[UPrime1VY>-QIBDataS.QBMIndexOffsetY]-...
    (QIBDataS.QBMIndexOffsetY).*[UPrime1VY<=-QIBDataS.QBMIndexOffsetY];

UPrime2VY=UPrime2VY.*[UPrime2VY>-QIBDataS.QBMIndexOffsetY]-...
    (QIBDataS.QBMIndexOffsetY).*[UPrime2VY<=-QIBDataS.QBMIndexOffsetY];


URel1VX=((UPrime1VX+QIBDataS.QBMIndexOffsetX)/QIBDataS.deltaQBM+1).*sign(xRel1V);
URel2VX=((UPrime2VX+QIBDataS.QBMIndexOffsetX)/QIBDataS.deltaQBM+1).*sign(xRel2V);

URel1VY=((UPrime1VY+QIBDataS.QBMIndexOffsetY)/QIBDataS.deltaQBM+1).*sign(yRel1V);
URel2VY=((UPrime2VY+QIBDataS.QBMIndexOffsetY)/QIBDataS.deltaQBM+1).*sign(yRel2V);


clear UPrime1VX UPrime2VX UPrime1VY UPrime2VY


%Nearest neighbor interpolation:
U1VX=URel1VX+QIBDataS.QBMidIndexX;
U2VX=URel2VX+QIBDataS.QBMidIndexX;
U1VY=URel1VY+QIBDataS.QBMidIndexY;
U2VY=URel2VY+QIBDataS.QBMidIndexY;

%U1VX=round(URel1VX+QIBDataS.QBMidIndexX);
%U2VX=round(URel2VX+QIBDataS.QBMidIndexX);
%U1VY=round(URel1VY+QIBDataS.QBMidIndexY);
%U2VY=round(URel2VY+QIBDataS.QBMidIndexY);

%Check for out-of-bounds values:
U1VX=U1VX.*[U1VX<=LimG(1)].*[U1VX>0]+1*[U1VX<=0]+LimG(1).*[U1VX>LimG(1)];
U2VX=U2VX.*[U2VX<=LimG(1)].*[U2VX>0]+1*[U2VX<=0]+LimG(1).*[U2VX>LimG(1)];
U1VY=U1VY.*[U1VY<=LimG(2)].*[U1VY>0]+1*[U1VY<=0]+LimG(2).*[U1VY>LimG(2)];
U2VY=U2VY.*[U2VY<=LimG(2)].*[U2VY>0]+1*[U2VY<=0]+LimG(2).*[U2VY>LimG(2)];

%-------------------Get dose component Gauss----------------------%

%S = size(QIBDataS.QIBGauss);
%ind1 = sub2ind(S,U1VX,U1VY);
%ind2 = sub2ind(S,U2VX,U1VY);
%ind3 = sub2ind(S,U1VX,U2VY);
%ind4 = sub2ind(S,U2VX,U2VY);

%QI = interp2(QIBDataS.QIB,U1VX,U1VY,'linear');
%QII = interp2(QIBDataS.QIB,U2VX,U1VY,'linear');
%QIII = interp2(QIBDataS.QIB,U1VX,U2VY,'linear');
%QIV = interp2(QIBDataS.QIB,U2VX,U2VY,'linear');

QI = linear2(QIBDataS.QIB,U1VX,U1VY);
QII = linear2(QIBDataS.QIB,U2VX,U1VY);
QIII = linear2(QIBDataS.QIB,U1VX,U2VY);
QIV = linear2(QIBDataS.QIB,U2VX,U2VY);


%ind1 = sub2ind(S,U1VX,U1VY);
%ind2 = sub2ind(S,U2VX,U1VY);
%ind3 = sub2ind(S,U1VX,U2VY);
%ind4 = sub2ind(S,U2VX,U2VY);

DosesGauss = QI-QII-QIII+QIV;


%DosesGauss = (QIBDataS.QIBGauss(ind1)-QIBDataS.QIBGauss(ind2)-QIBDataS.QIBGauss(ind3)+QIBDataS.QIBGauss(ind4));
DosesGauss = DosesGauss .* kGauss(compute);


clear U1VX U2VX URel1VX URel2VX U1VY U2VY URel1VY URel2VY

%-------------------Get dose A component & component Gauss----------------------%


DosesAG = zeros(size(xVa));
DosesAG(compute) = DosesAV + DosesGauss;

%-------------------Get dose A component & component Gauss & B component---------%

DosesV = DosesAG + DosesBV;

%----------------------------End---------------------------------%
