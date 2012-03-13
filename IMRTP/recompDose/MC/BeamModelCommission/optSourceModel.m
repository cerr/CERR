function [p ener a enerFF aFF max_doseV doseV_wt] = optSourceModel_depth6cm_blurring(planC, energy, numBin, extraBin, depth, dose, ...
    depth1, x1, profile1,  depth2, x2, profile2, depth3, x3, profile3, depth4, x4, profile4, LB, UB);
% JC Dec 09,2005
% Optimize photon spectrum, using (Fatigue-life)*Fermi distribution
% Usage:
% energy = energy of the photon beam
% numBin = number of bins to divide the energy range [0 energy]
% depth is a row vector as the depth
% dose is the corresponding dose at each depth
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

% Underline assumptions:
% The calculated dose sets are the same size as the uniformizedCTscan. 
% 1. Interpolation the calculated dose on to the respectively dose profiles
% coordinates may cause problem: Since the individual dose profile
% measurements do not necessarily have the same coordinates/# of points,
% 

% 2. The input depth/x coordinates are in cm
%    The depth dose (PDD) is normalized. dmax = 1
%    The lateral dose profiles at various depth are also normalized. Each
%       has a maximal value as 1. It will be scaled according to PDD.

% 3. The phantom is at least 25cm in the depth direction. Otherwise, the
% interpolation of PDD will have out-flow, meaning the non-meaningful
% values, N/A. An error will be thrown out.
%   Also, the input PDD's depth may not start from zero, this may generate
%   N/A if the yVals starts from zero. So chop yVals according to PDD's
%   depth.

% 4. All input measured data are in a nx1 vector, i.e. a column vector

% 5 Add more input parameters: adjustable to different machines
% LB=[0.6  -0.1 1.2   100  1  0.1  0.005    0.005];
% UB=[1.5  0.1   10  1000  4   0.25  0.05  0.05];

% Input parameters descriptions:
% LB, UB. Upper and lower bound for the parameters.
% p, the optimazied parameters.
% p(1:4) The parameters for "Fagitue-Fermi" function, to model the primary photon
% spectrum.
% p(5) The parameter to "shrink" the primary photon spectrum
% to get the spectrum for the extra-focal (FF) components.
% p(6) The parameter to "scale" the extra-focal (FF) components,
% to determine the relative fluence contribution of the extra-focal (FF)
% to the primary photon.
% p(7) used to determine "the slope of the horn", not used anymor i.e. It is how many "pixels"/"grid".
% The dimension of the ICsigma in (cm) should be p(9)*e.
% p(8) the electron contamination (fluence relative to the primary photon.
% p(9) the "ICsigma", to convolve the MC dose, to model the spearing of the dose by IC chamber.
% If the resolution of the dose calc. grid changes, i.e. 
% The dimension of the sigma is p(9)*dx, where "dx" is the grid spacing for
% dose calc.


% 6. Add another parameter for the optimization, sigma. A gaussian filter
% to blur the penumbra.

% Sept 21, 2006
% Add electron contamination components.
% For PDD, includes depth < 5cm

% Nov 27, 2006
% correct 
% doseP2_arrayFF(:,i) = dose3D(find(yVals == yDepth3),[xIndexStart:xIndexEnd],int16(s));
% doseP2_arrayFF(:,i) = dose3D(find(yVals == yDepth2),[xIndexStart:xIndexEnd],int16(s));

% Get the isocenter coordinate
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
% So iC is the isocenter. Need to find indices from the (x, y, z) values.

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
bbox=boundingBox(skinMask)
%[r,c,s] = xyztom(isocenter.x,isocenter.y,isocenter.z, planC)
[r,c,s] = xyztom(isocenter.x,isocenter.y,isocenter.z, 1, planC)

%Get the indices of where yVals==depth(end)/10 ; Failed???
%[r,c,s] = xyztom(isocenter.x,yVals(find(yVals==isocenter.y-min(isocenter.y-yVals))),isocenter.z, planC)

% Get the objective dose from input(Golden Beam Data), not from planC.

% get the yVals for different depth, to pick out the appropriate lateral dose profiles in the calcualted dose sets. 
dy = yVals(2)-yVals(1);  % dy is < 0, because of y increases as row number decreases
yDepth0 = yVals(bbox(1));
yDepth1 = yVals(bbox(1)+int16(-depth1/dy)); 
yDepth2 = yVals(bbox(1)+int16(-depth2/dy));
yDepth3 = yVals(bbox(1)+int16(-depth3/dy));
yDepth4 = yVals(bbox(1)+int16(-depth4/dy));
yDepth25cm = yVals(bbox(1)+int16(-25/dy));

%depthTPS can't start from 0, which will cause intepolated data N/A.
depthTPS = [ceil(min(depth)/(-dy))*(-dy) : -dy: yVals(bbox(1))-yDepth25cm];
PDD = interp1(depth, dose, depthTPS);
doseV_obj = PDD';
doseV_array = zeros(length(PDD),numBin+extraBin);
max_doseV = zeros(numBin+extraBin,1);

% GET the start and end indices objective for dose profile at depth 5cm
xStart = max(min([x1 x2 x3 x4]));
xEnd = min(max([x1 x2 x3 x4]));
% use margin 1 to make sure the results xTPS is within the measured region.
xIndexStart = find(abs(xStart - xVals) == min(abs(xStart - xVals))) + 1;
xIndexEnd = find(abs(xEnd - xVals) == min(abs(xEnd - xVals))) - 1 ;

% Should correct xTPS for isocenter.x? Does, then xTPS maybe outside of the
% valid region.
 xTPS = [xVals(xIndexStart)-isocenter.x : (xVals(2)-xVals(1)): xVals(xIndexEnd)-isocenter.x];
% Currently, do not correct.
% xTPS = [xVals(xIndexStart): (xVals(2)-xVals(1)): xVals(xIndexEnd)];

doseProfile1 = interp1(x1, profile1, xTPS);
% Since the input measured data is the asdfScale it to be consistent with PDD
% Needed for Golden Beam data. Not for Murty's measurement.
doseProfile1_obj = doseProfile1' * PDD(find(abs(depth1-depthTPS) == min(abs(depth1-depthTPS))));
% Creat array to hold the dose profiles for the different energy bins.
doseP1_array = zeros(length(doseProfile1_obj), numBin+extraBin);


doseProfile2 = interp1(x2, profile2, xTPS);
% Scale it to be consistent with PDD
doseProfile2_obj = doseProfile2' * PDD(find(abs(depth2-depthTPS) == min(abs(depth2-depthTPS))));
doseP2_array = zeros(length(doseProfile2_obj), numBin+extraBin);

% GET the objective for dose profile at depth 10cm
doseProfile3 = interp1(x3, profile3, xTPS);
% Scale it to be consistent with PDD
doseProfile3_obj = doseProfile3' * PDD(find(abs(depth3-depthTPS) == min(abs(depth3-depthTPS))));
doseP3_array = zeros(length(doseProfile3_obj), numBin+extraBin);

% GET the objective for dose profile at depth 20cm
doseProfile4 = interp1(x4, profile4, xTPS);
% Scale it to be consistent with PDD
doseProfile4_obj = doseProfile4' * PDD(find(abs(depth4-depthTPS) == min(abs(depth4-depthTPS))));
doseP4_array = zeros(length(doseProfile4_obj), numBin+extraBin);

figure; plot(depthTPS, PDD);
% There's shift of doseProfile2_obj, x as half voxel size. 0.1875/2 =
% 0.094cm
hold on; plot(xTPS, doseProfile1, 'c', xTPS, doseProfile2, 'b', xTPS, doseProfile3, 'r', xTPS, doseProfile4, 'g');
legend('PDD', num2str(depth1), num2str(depth2), num2str(depth3), num2str(depth4));


% Read in the dose from the DPM calculation.
for i = 1:(numBin+extraBin),
    filename = ['dose3D_', num2str(i*energy/numBin),'MV.mat'];
    load (filename, 'dose3D');
    doseV_array(:,i) = dose3D([(bbox(1)+ceil(min(depth)/(-dy))):find(yVals == yDepth25cm)],int16(c),int16(s));
    doseP1_array(:,i) = dose3D(find(yVals == yDepth1),[xIndexStart:xIndexEnd],int16(s));
    doseP2_array(:,i) = dose3D(find(yVals == yDepth2),[xIndexStart:xIndexEnd],int16(s));
    doseP3_array(:,i) = dose3D(find(yVals == yDepth3),(xIndexStart:xIndexEnd),int16(s));
    doseP4_array(:,i) = dose3D(find(yVals == yDepth4),(xIndexStart:xIndexEnd),int16(s));
 
  end

% currentDir = pwd;
% cd ./FlatFilter
%NOW, for the flattenning filter part, need to do the exactly same thing,
%i.e. get PDD and doseP5cm, doseP10cm, doseP20cm....
numBinFF = ceil((numBin+extraBin)/2); %15
% JC. Use all energy bins.
numBinFF = numBin+extraBin; %15
doseV_arrayFF = zeros(length(PDD),numBinFF);
doseP1_arrayFF = zeros(length(doseProfile1), numBinFF);
doseP2_arrayFF = zeros(length(doseProfile2), numBinFF);
doseP3_arrayFF = zeros(length(doseProfile3), numBinFF);
doseP4_arrayFF = zeros(length(doseProfile4), numBinFF);
% Read in the dose from the DPM calculation, for the secondary source, i.e. Flattening Filter,FF.
for i = 1 : numBinFF,
    filename = ['dose3D_FF_', num2str((double(i*energy)/double(numBin))),'MV.mat'];
    load (filename, 'dose3D');
    doseV_arrayFF(:,i) = dose3D([(bbox(1)+ceil(min(depth)/(-dy))):find(yVals == yDepth25cm)],int16(c),int16(s));
    doseP1_arrayFF(:,i) = dose3D(find(yVals == yDepth1),[xIndexStart:xIndexEnd],int16(s));
    doseP2_arrayFF(:,i) = dose3D(find(yVals == yDepth2),[xIndexStart:xIndexEnd],int16(s));
    doseP3_arrayFF(:,i) = dose3D(find(yVals == yDepth3),(xIndexStart:xIndexEnd),int16(s));
    doseP4_arrayFF(:,i) = dose3D(find(yVals == yDepth4),(xIndexStart:xIndexEnd),int16(s));
end
% cd(currentDir);

% Read the dose of the electron contamination.
load dose3D_elec.mat dose3D
doseV_e = dose3D([(bbox(1)+ceil(min(depth)/(-dy))):find(yVals == yDepth25cm)],int16(c),int16(s));
% Need doseP5cm_e etc. is a collumn vector.
doseP1_e = dose3D(find(yVals == yDepth1),[xIndexStart:xIndexEnd],int16(s))';
doseP2_e = dose3D(find(yVals == yDepth2),[xIndexStart:xIndexEnd],int16(s))';
doseP3_e = dose3D(find(yVals == yDepth3),(xIndexStart:xIndexEnd),int16(s))';
doseP4_e = dose3D(find(yVals == yDepth4),(xIndexStart:xIndexEnd),int16(s))';


%%Need to pick the indices for dose profile at 5cm, 10cm, 20cm. And shift
%%the middle as x_coordinate = 0, as in the golden beam data.
%% Also need to scale the maximum dose at this depth according to the PDD
%% at this depth, because the profile dose is relative (max = 100).
%% Now only account the dose profile at depth 5cm.

%options = optimset('DISPLAY', 'notify', 'TolX', 1.e-12);
%%%% Using Ant Colony Opt. (api.m)
%%% O.K. parameters. JC

% Parameters: p(1) till p(4), the four parameters to determine the primary
% photon spectrum, sum(a) is the weight.
% p(5) "shrink" for the Flattening filter.
% p(6) is the weight of FF photon, aFF = aFF * p(6)
% p(7) is the Horn effect weight, respective to sum(a)
% p(8) is the electron contamination weight, respective to sum(a)

FUN='PDD_Profile_res';
% "working" LB, UB settings
% Add one more bounds for the penumbra
%LB=[0.6  -0.1 1.2   100  2  0.1  0.01    0.005 0.01];
%UB=[1.5  0.1   10  1000  4   0.2  0.05  0.04 5];

% expand the LB and UB by the suggesstions from JOD. On Oct 09, 2006
% LB=[0.6  -0.1 1.2   100  1  0.1  0.005    0.001];
% UB=[1.5  0.1   10  1000  4   0.25  0.05  0.05];

NumAnts=25;Nmoves=20;LocalMoves=30;
NONLNCON=[];rpmax=[]; RES=1e-8;
p=api(FUN,LB,UB,NumAnts,Nmoves,LocalMoves,NONLNCON,rpmax,RES, ...
    doseV_obj, doseV_array, doseV_arrayFF, doseV_e, ...
    doseProfile1_obj, doseP1_array, doseP1_arrayFF, doseP1_e, ...
    doseProfile2_obj, doseP2_array, doseP2_arrayFF, doseP2_e, ...
    doseProfile3_obj, doseP3_array, doseP3_arrayFF, doseP3_e, ...
    doseProfile4_obj, doseP4_array, doseP4_arrayFF, doseP4_e, ...
    energy, numBin, extraBin, numBinFF)

% Output results
ener = energy/numBin: energy/numBin:energy*(1+extraBin/numBin);
a = Fatigue(p(1:4), ener);
a(find(isnan(a))) = 0;

cutoff = 0.85;
Ef = energy*cutoff;
kt = energy*0.15;  % change kt
f = 1./(1+exp((ener-Ef)/kt));
a = a.*f;

doseV_wt = (doseV_array)  * real(a)';
doseProfile1_wt = (doseP1_array) * real(a)';
doseProfile2_wt = (doseP2_array) * real(a)';
doseProfile3_wt = (doseP3_array)  * real(a)';
doseProfile4_wt = (doseP4_array) * real(a)';

% Get the weights/spectrum for the flattening filter
enerFF = energy/numBin : energy/numBin : numBinFF*energy/numBin;
aFF = Fatigue(p(1:4), p(5)*enerFF);
aFF(find(isnan(aFF))) = 0;

% Get modified Flattening filter spectrum/weights 
f = 1./(1+exp((p(5)*enerFF-Ef)/kt));
aFF = aFF.* f;
aFF = aFF * (sum(a)/sum(aFF)*p(6)) ;  % scale FF weight respect to sum(a)

doseV_wtFF = doseV_arrayFF * real(aFF)';
doseProfile1_wtFF = doseP1_arrayFF * real(aFF)';
doseProfile2_wtFF = doseP2_arrayFF * real(aFF)';
doseProfile3_wtFF = doseP3_arrayFF * real(aFF)';
doseProfile4_wtFF = doseP4_arrayFF * real(aFF)';

filterSize = 7;
filterWindow = [-3 -2 -1 0 1 2 3];
G1 = gauss(filterWindow, p(9));  %p(9) is sigma
G1 = G1/sum(G1);   % normalize, to make sum(G1)==1;

doseV_DPM = doseV_wt + doseV_wtFF + p(8) * sum(a)* doseV_e;
doseProfile1_DPM = doseProfile1_wt + doseProfile1_wtFF + p(8) * sum(a)* doseP1_e;
doseProfile1_DPM = conv(G1, doseProfile1_DPM);
doseProfile2_DPM = doseProfile2_wt + doseProfile2_wtFF + p(8) * sum(a)* doseP2_e;
doseProfile2_DPM = conv(G1, doseProfile2_DPM);
doseProfile3_DPM = doseProfile3_wt + doseProfile3_wtFF + p(8) * sum(a)* doseP3_e;
doseProfile3_DPM = conv(G1, doseProfile3_DPM);
doseProfile4_DPM = doseProfile4_wt + doseProfile4_wtFF + p(8) * sum(a)* doseP4_e;
doseProfile4_DPM = conv(G1, doseProfile4_DPM);


figure;
subplot(2,1,1); plot(depth,dose, '.');
hold on;
plot(depthTPS,doseV_DPM, 'r');
legend('measured', 'DPM wt');
axis([0 25 0 1.1])
subplot(2,1,2); plot([0 ener], [0 a], '+-b')
hold on;  plot([0 enerFF], [0 aFF], '+-r')

% Note: There's shift in the measured dose. Now fix the display
figure; 
plot(xTPS, doseProfile1_obj, 'b', xTPS, doseProfile1_DPM(4:end-3), '-.r')
hold on; plot(xTPS, doseProfile3_obj, 'c', xTPS, doseProfile3_DPM(4:end-3), '-.m')
legend('measured', ['DPM ', num2str(depth1)], 'measured', ['DPM ', num2str(depth3)]);


figure; plot(xTPS, doseProfile2_obj, 'b', xTPS, doseProfile2_DPM(4:end-3), '-.r')
hold on; plot(xTPS, doseProfile4_obj, 'c', xTPS, doseProfile4_DPM(4:end-3), '-.m');
legend('measured', ['DPM ', num2str(depth2)], 'measured', ['DPM ', num2str(depth4)]);

filename = 'modelParameters';
save(filename, 'p', 'ener', 'a', 'enerFF', 'aFF', 'max_doseV', 'doseV_wt');
disp('ok');