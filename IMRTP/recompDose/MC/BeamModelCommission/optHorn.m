function [p,FVAL,EXITFLAG] = optHorn(planC, calbDepth, calbDose, initParams, ICsigma, hornOffAxis, fractionEF, varargin)
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

% LM: JC, May 17, 2007

% 
% The input 'varargin' is: IM20x20, FS20x20, ...
% Flexiable with the number of input variables.
% where IM are the calculated IM structures for openField
% FS10x10 etc. are the measured data for the openField

% How to Use:
% optHorn(planC, 1.5, 1, LB, UB, ICsigma, hornOffaxis, 0.16, IM10x10, FS10x10, IM20x20, FS20x20)

% calbDepth = 1.5 cm;  % It is the calibration depth.  for 6 MV, it is
% usually 1.5 cm.
% calbDose = 1 cGy/MU;   % means the treatment machine is calibrated for
% 10x10 cm^2 field size, at depth 1.5cm (calbDepth) to get 1 cGy/MU.

% ICsigma = 1.3385
% * 0.1875(cm) = 0.25cm. to account for the IC blurring.
% hornOffAxis = [0   2.5000e+00   5.0000e+00   7.5000e+00   1.0000e+01   1.2500e+01   1.5000e+01   1.7500e+01   2.0000e+01   2.2500e+01   2.5000e+01   2.8500e+01];

% InitParams = params.
% params(1) := calibration constant = 25. (to scale DPM dose to 1cGy/MU at depth = 1.5cm for field size 10x10cm2, at 100SSD.
% params(2) := horn at atan( 2.5/100);
% params(3) := horn at atan( 5.0/100);
% params(4) := horn at atan( 7.5/100);
% params(5) := horn at atan(10.0/100);
% params(6) := horn at atan(15.0/100);
% params(7) := horn at atan(20.0/100);
% params(8) := horn at atan(28.5/100);

% The relative fluence of the Extral-focal source to the primary source.
% fractionEF = 0.16;

% Scale the measured dose (PDD and lateral dose profiles) into "cGy/MU".
% This contains the object of the optimization.
[FS] = calcAbsoluteMeasDose(calbDepth, calbDose, varargin{2:2:end})

% Get the IM structure. The
IM = varargin{1};   % IM40x40 idealy (the biggest field size you're intersted in.)

% The input measured dose has already been scaled to the absolute dose,
% i.e. "cGy/MU"
% dose to the 'absolute' dose, assuming 1Gy/MU for 10x10cm2 field size, at
% depth = 1.5cm. Could be others though

bf = planC{7}.FractionGroupSequence.Item_1.ReferencedBeamSequence.Item_1;
bs = planC{7}.BeamSequence.Item_1;
iC = bs.ControlPointSequence.Item_1.IsocenterPosition;

position = {planC{7}.PatientSetupSequence.(['Item_' num2str(1)]).PatientPosition};

if strcmpi(position, 'HFP')
    isocenter.x = iC(1)/10;
    isocenter.y = iC(2)/10;
    isocenter.z = -iC(3)/10;
else
    isocenter.x = iC(1)/10;
    isocenter.y = -iC(2)/10;
    isocenter.z = -iC(3)/10;
end

[xVals, yVals, zVals] = getUniformScanXYZVals(planC{3});
% Need to confirm that iC(2), i.e. the y value is right on the skin
% surface. Thus, the depth for dose along the center ray can be determined.
j = find(strcmpi({planC{4}.structureName}, 'Skin'));

if isempty(j)
    j = find(strcmpi({planC{4}.structureName}, 'Body'));
end

if isempty(j)
    error('Skin structure must be defined to input to DPM.');
else
    j = j(1);
end

skinMask=getUniformStr(j,planC);

%confirm that the isocenter.y is right on the skin surface
bbox=boundingBox(skinMask);
%[r,c,s] = xyztom(isocenter.x,isocenter.y,isocenter.z, planC)
[r,c,s] = xyztom(isocenter.x,isocenter.y,isocenter.z, 1, planC);

dy = yVals(2)-yVals(1);  % dy is < 0, because of y increases as row number decreases
yDepth40cm = yVals(bbox(1)+uint16(-40/dy));

% Only calculate profile1, i.e. depth = 1.5cm, to optimize the horn effect.
for j = 1: [length(varargin)/2],
    names = fieldnames(varargin{2*j});
    %for i = 1: length(names)
    % For Horn, only use the first profile, at dmax = 1.5cm
    for i = 1: 1
        if (strcmp(names{i},'PDD'));
            %depthTPS can't start from 0, which will cause intepolated data N/A.
            % % % depthTPS = [ceil(min(depth)/(-dy))*(-dy) : -dy: yVals(bbox(1))-yDepth25cm];
            % % % PDD = interp1(depth, dose, depthTPS);
            % % % doseV_obj = PDD';

            break;
        else
            field = varargin{2*j}.(['profile', num2str(i)]);
            depth = field.depth;
            % get the yVals for different depth, to pick out the appropriate lateral dose profiles in the calcualted dose sets.
            dy = yVals(2)-yVals(1);  % dy is < 0, because of y increases as row number decreases
            yDepth0 = yVals(bbox(1));
            yDepth25cm = yVals(bbox(1)+int16(-25/dy));

            % GET the start and end indices objective for dose profile at depth 5cm
            %! xStart = min(field.profile(:,1));
            %! xEnd = max(field.profile(:,1));

            xStart = - FS.fieldsize/2;
            xEnd = FS.fieldsize/2;
            % use margin 1 to make sure the results xTPS is within the measured region.
            % JC May 20; Use less point, to exclude the penumbra region,
            % since it's not as critical as the in-beam region
            % And the disagreement in penumbra region may caused by other
            % reasons, such as 1. 
            xIndexStart = find(abs(xStart - xVals) == min(abs(xStart - xVals))) + 4;
            xIndexEnd = find(abs(xEnd - xVals) == min(abs(xEnd - xVals))) - 4 ;

            % Should correct xTPS for isocenter.x? Does, then xTPS maybe outside of the
            % valid region.
            xTPS = [xVals(xIndexStart)-isocenter.x : (xVals(2)-xVals(1)): xVals(xIndexEnd)-isocenter.x];

            doseProfile1 = interp1(field.profile(:,1), field.profile(:,2), xTPS);

            yIndex = bbox(1)+uint16(-depth/dy);

            hornCoef = [0, initParams(2:end)];
            offAxis = [0:0.1:28.5];
            test = interp1(hornOffAxis, hornCoef, offAxis);
            
            % get off-axis-distance at 100 cm SSD.
            PBOffAxis = sqrt(IM.beams.xPBPosV.^2 + IM.beams.yPBPosV.^2);
            w_field = 1 + interp1(offAxis, test, PBOffAxis);
           % Correction for isotropic derive
           % IM2isoCorrection = (cos(atan(PBOffAxis/IM.beams.isodistance)).^2);
           %  w_field = w_field .* IM2isoCorrection;
            
            % Now this is only Primary photon contribution.
            IM.beamlets = IM.beamletsPrimary;
            tic; [dose3D] = getIMDose(IM, w_field, 1); toc
            % Use Issam's code to do the denoising.
            % Denoising part.
            dose3D = max(dose3D(:))*anisodiff3d_miao_exp(dose3D/max(dose3D(:)), 0.03, 4);

            % Get the Extra-focal contribution.
            IM.beamlets = IM.beamletsFF;
            tic; [dose3D_FF] = getIMDose(IM, [], 1); toc
            % Denoising.
            dose3D_FF = max(dose3D_FF(:))*anisodiff3d_miao_exp(dose3D_FF/max(dose3D_FF(:)), 0.03, 4);

            % Add dose3D and dose3D_FF together.
            dose3D = dose3D + fractionEF * dose3D_FF;

            % This should be on the order of 1.
            doseProfile1_DPM = initParams(1)*dose3D(yIndex, xIndexStart:xIndexEnd, int16(s));
            figure; plot(field.profile(:,1), field.profile(:,2), '+-', xVals, initParams(1)*dose3D(yIndex,:, int16(s)), 'ro'); legend('meas', 'DPM');
            figure; plot(xTPS, doseProfile1, '+-', xTPS, doseProfile1_DPM, 'ro');
         
            diffsqr = sum((doseProfile1 - doseProfile1_DPM).^2);
            res = sqrt(diffsqr)
            
            
        end
    end
end

optnew = optimset('Display', 'notify','MaxFunEvals',80,'MaxIter',40,'TolX',1e-3,'TolFun', 1e-3);
tic;
[p,FVAL,EXITFLAG] = fminsearch('Profile_Horn_res', initParams, optnew, doseProfile1, xIndexStart, xIndexEnd, yIndex, s, ICsigma, hornOffAxis, fractionEF, varargin);
toc
p

figure; plot(field.profile(:,1), field.profile(:,2), '+-', xVals, initParams(1)*dose3D(yIndex,:, int16(s)), 'ro'); legend('meas', 'DPM');
figure; plot(xTPS, doseProfile1, '+-', xTPS, doseProfile1_DPM, 'ro');

return;
