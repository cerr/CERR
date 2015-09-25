function xV = runOptimExample(varargin)
%Script runOptimExample(show)
%Runs a simple weighted least-squares IMRT fluence map optimization optimization problem.
%JOD, first version 7 Sept 05.
%The user should edit the following several lines to specify the prescription
%doses and the relevant anatomical structures, and relative weights (normalized by
%the number of voxels per structure).  To be replaced by a GUI.
%If input 'show' is specified as 1, dose will be computed and re-imported
%into CERR.
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

global planC optimS

%-----------parse inputs---------------------%


show  = 0;
IMIndex = 1;
if length(varargin) == 2
  IMIndex = varargin{1};
  show = varargin{2};
end

disp('Begin building input data...')
tic
%=======Specify the prescription============%


% structNamesC = {'CTV 7200_3mm','CTV 5400_3mm',30, ...
%    'brainstem_3mm', 'cord_3mm', 27, 28, 29,31,32};
structNamesC = {30,...
   'brainstem_3mm', 'cord_3mm', 27, 28, 29,31,32};

%Note: capitalization is ignored
%Numbers or names are used.
%Names are less error-prone unless the name is a
%complicated derived name.

%27 = anchor zone
%28 = lt parotid - ctv
%29 = rt parotid - ctv
%30 = CTV 4950 - CTV 7200

relWeightsV = [30,5,5,5,5,0.01,0.01,0.01,0.01,0.01];
%relative weights of terms.  These represent my
%last guess.

desiredDoseV = [72 * 1.03,54 * 1.03,49.5 * 1.03,0,0,0,0,0,0,0];  %put desired doses here
%Desired doses.  Bumped up to reduce the size of cold spots.

doseScale = max(desiredDoseV);

desiredDoseScaledV = desiredDoseV/doseScale;

startC = 10;  %starting point for beam weights.

optimS.maxBeamVal = 18; %Put a limit on beam values.
%The problem is scaled such that values over this
%represent mostly noise.

indexS = planC{end};

%numBeams = length(planC{indexS.IM}(IMIndex).IMSetup(end).beams);
numBeams = length(planC{indexS.IM}(IMIndex).IMDosimetry(end).beams);

%=========Match structure names to indices============%

%dumpmemmex

%loop to match structure names

ind = indexS.structures;
numStructs = length(planC{ind});

for i = 1 : length(structNamesC)
  match = 0;
  for j = 1 : numStructs
    toMatch = structNamesC{i};
    if ischar(toMatch)
      strName = planC{ind}(j).structureName;
      if strcmpi(toMatch,strName)==1
        structIndicesV(i) = j;
        match = 1;
      end
    else
      structIndicesV(i) = toMatch; %using number instead
      match = 1;
    end
  end
  if match ~=1
    error('Structure not found')
  end
end

optimS.structIndicesV = structIndicesV;

%========Build the influence matrices===========%

IM = planC{indexS.IM};
IM = IM(IMIndex);  %takes the last computed plan.

if length(IM) > 1
  warning('More than one IM structure.  Using the last computed...')
end

%disp('Assembling influence matrix...')

%Assemble inflM:
%optimS.inflM = [];
%numVoxelsV = [];
%for i = 1 : length(structIndicesV)
%  inflTmp = getInfluenceM(IM.IMDosimetry, structIndicesV(i));
%  numVoxelsV(i) = size(inflTmp,1);
%  optimS.inflM = [optimS.inflM; inflTmp];
%  dumpmemmex
%end
%clear inflTmp
%optimS.scaleFactor = max(optimS.inflM(:));
%optimS.inflM = optimS.inflM/optimS.scaleFactor;

%Assemble voxel prescription doses:
%optimS.desiredVoxelDosesV = [];
%for i = 1 : length(structIndicesV)
%  optimS.desiredVoxelDosesV = [optimS.desiredVoxelDosesV; desiredDoseV(i) * ones(numVoxelsV(i),1)];
%end

%Assemble voxel weights:
%optimS.voxelWeightsV = [];
%for i = 1 : length(structIndicesV)
%  optimS.voxelWeightsV = [optimS.voxelWeightsV; relWeightsV(i) * ones(numVoxelsV(i),1)/numVoxelsV(i)];
%end

%Get scale factor to make good beamlet weights on the order of 1.
%
highestMean = 0;
for i = 1 : length(structIndicesV)
  inflTmp = getInfluenceM(IM.IMDosimetry, structIndicesV(i));
  %Get all contributions above median dose for beamlets = 1.
  doseV = inflTmp * ones(size(inflTmp,2),1);
  [row,col,vals] = find(doseV([doseV > 0.5 * max(doseV)]));
  highestMean = mean(vals) * [highestMean < mean(vals)] + [highestMean >= mean(vals)] * highestMean;
  %dumpmemmex
end

inflScaleFactor = highestMean  * numBeams;
%inflScaleFactor = 1;
%Scale so that good optimization solution vectors have 'on' beamlet values of about 1.

%------Construct matrices for quadratic programming------%

%Construct weighted Hessian and 'f'/linear term
optimS.HessM = 0;
optimS.fV    = 0;
for i = 1 : length(structIndicesV)
  inflTmp = getInfluenceM(IM.IMDosimetry, structIndicesV(i));
  numVoxels = size(inflTmp,1);
  optimS.HessM = optimS.HessM + relWeightsV(i) * inflTmp' * inflTmp / (numVoxels * inflScaleFactor^2);
  optimS.fV = optimS.fV - relWeightsV(i) * desiredDoseScaledV(i) * ones(1,numVoxels) * inflTmp ...
              / (inflScaleFactor * numVoxels);
  %dumpmemmex
end


numPBs = size(inflTmp,2);

%add upper and lower bounds to pencil beam variables

LB = zeros(numPBs,1);

UB = ones(numPBs,1) * optimS.maxBeamVal;

%optimset('tolfun',0.00000000001,'maxiter',500,'display','on')

options = optimset('tolfun',1e-11,'maxiter',500,'display','on');

Aeq = [];
beq = [];
A = [];
b = [];

x0V = startC * ones(numPBs,1);

disp('Begin optimization...')
%dumpmemmex

[xV, feval, exit, outputflag, lambda] = quadprog(optimS.HessM,optimS.fV,A,b,Aeq,beq,LB,UB,x0V,options);

outputflag

figure
bar(xV)

if show == 1
  dose3D = getIMDose(IM.IMDosimetry, xV * doseScale / inflScaleFactor,'skin');
  showIMDose(dose3D,'LSQ demo1 JOD')
end

%put solution into planC
planC{indexS.IM}(IMIndex).IMDosimetry.solutions = xV;


toc


