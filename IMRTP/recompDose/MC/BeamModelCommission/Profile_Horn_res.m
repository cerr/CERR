function res = Profile_Horn_res(p,  doseProfile1, xIndexStart, xIndexEnd, yIndex, s, ICsigma, hornOffAxis, fractionEF, varargin)
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

% p(1) := calibration constant = 25. (to scale DPM dose to 1cGy/MU at
% depth = 1.5cm for field size 10x10cm2, at 100SSD.

% p(2) := horn at atan( 2.5/100);
% p(3) := horn at atan( 5.0/100);
% p(4) := horn at atan( 7.5/100);
% p(5) := horn at atan(10.0/100);
% p(6) := horn at atan(15.0/100);
% p(7) := horn at atan(20.0/100);
% p(8) := horn at atan(28.5/100);

if length(varargin) == 2
    IM = varargin{1};
    FS = varargin{2};
else
    % When called by 'fimsearch(FUN, x0)', varargin's elements turns into cell from struct.
    IM = varargin{1}{1};
    FS = varargin{1}{2};
end

% Get the horn based on
hornCoef = [0, p(2:end)];
offAxis = [0:0.1:28.5];
test = interp1(hornOffAxis, hornCoef, offAxis);

% get off-axis-distance at 100 cm SSD.
PBOffAxis = sqrt(IM.beams.xPBPosV.^2 + IM.beams.yPBPosV.^2);
w_field = 1 + interp1(offAxis, test, PBOffAxis);
% Correction for isotropic derive
% IM2isoCorrection = (cos(atan(PBOffAxis/IM.beams.isodistance)).^2);
% w_field = w_field .* IM2isoCorrection;

% Now this is only Primary photon contribution.
IM.beamlets = IM.beamletsPrimary;
tic; [dose3D] = getIMDose(IM, w_field, 1); toc
% Use Issam's code to do the denoising.
% Denoising part.
%! dose3D = max(dose3D(:))*anisodiff3d_miao_exp(dose3D/max(dose3D(:)), 0.03, 4);

 % Get the Extra-focal contribution.
IM.beamlets = IM.beamletsFF;
tic; [dose3D_FF] = getIMDose(IM,[], 1); toc
% Denoising.
%! dose3D_FF = max(dose3D_FF(:))*anisodiff3d_miao_exp(dose3D_FF/max(dose3D_FF(:)), 0.03, 4);

% Add dose3D and dose3D_FF together.
dose3D = dose3D + fractionEF * dose3D_FF;

% Scale dose up by p(1) to match with the measurements.
doseProfile1_DPM = p(1)*dose3D(yIndex, xIndexStart:xIndexEnd, int16(s));

%Start the function.
%Calculate the residue of the PDD and dose profile difference between DPM and the measurement.
diffsqr = sum((doseProfile1 - doseProfile1_DPM).^2);
res = sqrt(diffsqr)
return;