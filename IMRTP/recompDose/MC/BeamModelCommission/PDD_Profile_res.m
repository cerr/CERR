function res = PDD_Profile_res(params, doseV_obj, doseV_array,doseV_arrayFF, doseV_e, ...
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

    doseProfile1_obj, doseP1p5cm_array, doseP1p5cm_arrayFF, doseP1p5cm_e, ...
    doseProfile2_obj, doseP5cm_array, doseP5cm_arrayFF,  doseP5cm_e, ...
    doseProfile3_obj, doseP10cm_array, doseP10cm_arrayFF, doseP10cm_e, ...
    doseProfile4_obj, doseP20cm_array, doseP20cm_arrayFF, doseP20cm_e, ...
    energy, numBin, extraBin, numBinFF)

%Start the function.
%Calculate the residue of the PDD and dose profile difference between DPM and the measurement.

doseV_sum = zeros(size(doseV_obj));

ener = energy/numBin: energy/numBin:energy*(1+extraBin/numBin);
a = Fatigue(params(1:4), ener);
a(find(isnan(a))) = 0;

cutoff = 0.85;
Ef = energy*cutoff;
kt = energy*0.15;  % change kt
f = 1./(1+exp((ener-Ef)/kt));
a = a.*f;

% Sum the contribution of primary and "OnlyHorn" effect
doseV_sum = (doseV_array) * real(a)';
doseProfile1_sum = (doseP1p5cm_array) * real(a)';
doseProfile2_sum = (doseP5cm_array) * real(a)';
doseProfile3_sum = (doseP10cm_array)  * real(a)';
doseProfile4_sum = (doseP20cm_array) * real(a)';


% Get the weights/spectrum for the flattening filter
enerFF = energy/numBin : energy/numBin : numBinFF*energy/numBin;
aFF = Fatigue(params(1:4), params(5)* enerFF);
aFF(find(isnan(aFF))) = 0;

% Get modified Flattening filter spectrum/weights 
f = 1./(1+exp((params(5)*enerFF-Ef)/kt));
aFF = aFF.* f;
aFF = aFF * (sum(a)/sum(aFF)*params(6)) ;  % scale FF weight respect to sum(a)

%calculate the dose contribution of the flattening filter
doseV_sumFF = doseV_arrayFF * real(aFF)';
doseProfile1_sumFF = doseP1p5cm_arrayFF * real(aFF)';
doseProfile2_sumFF = doseP5cm_arrayFF * real(aFF)';
doseProfile3_sumFF = doseP10cm_arrayFF * real(aFF)';
doseProfile4_sumFF = doseP20cm_arrayFF * real(aFF)';

% Nov. 1 2006 
% Add the asd
filterSize = 7;
filterWindow = [-3 -2 -1 0 1 2 3];
G1 = gauss(filterWindow, params(9));  %p(9) is sigma
G1 = G1/sum(G1);   % normalize, to make sum(G1)==1;

doseV_DPM = doseV_sum + doseV_sumFF + params(8) * sum(a)* doseV_e;
doseProfile1_DPM = doseProfile1_sum + doseProfile1_sumFF + params(8) * sum(a)* doseP1p5cm_e;
doseProfile1_DPM = conv(G1, doseProfile1_DPM);
doseProfile2_DPM = doseProfile2_sum + doseProfile2_sumFF + params(8) * sum(a)* doseP5cm_e;
doseProfile2_DPM = conv(G1, doseProfile2_DPM);
doseProfile3_DPM = doseProfile3_sum + doseProfile3_sumFF + params(8) * sum(a)* doseP10cm_e;
doseProfile3_DPM = conv(G1, doseProfile3_DPM);
doseProfile4_DPM = doseProfile4_sum + doseProfile4_sumFF + params(8) * sum(a)* doseP20cm_e;
doseProfile4_DPM = conv(G1, doseProfile4_DPM);
 
% Use relative weight for PDD as 5; for lateral dose profile, use weight
% as 1. 
% for doseV_obj, dose different absolute dose value make a difference?
% Should it be weighed by the dose values at those points?

diffsqr = 1.0*sum ((doseV_obj - doseV_DPM).^2) ...
      + sum((doseProfile1_obj - doseProfile1_DPM(4:end-3)).^2) ...
    + sum((doseProfile2_obj - doseProfile2_DPM(4:end-3)).^2) ...
    + sum((doseProfile3_obj - doseProfile3_DPM(4:end-3)).^2) ...
      + sum((doseProfile4_obj - doseProfile4_DPM(4:end-3)).^2);
res = sqrt(diffsqr);
return;