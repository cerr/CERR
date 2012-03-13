function [CTUniform3D, CTUniformInfoS] = getUniformizedCTScan(native,planC)
%function CTUniform3D = getUniformizedCTScan
%Return the uniformized (constant slice spacing) CT scan.
%CTUniformA is a 3D double matrix.
%JOD, 17 Oct 03.

% global planC

indexS=planC{end};

CTUniformInfoS = planC{indexS.scan}(1).uniformScanInfo;

scanData = planC{indexS.scan}(1);
scanInfo = scanData.scanInfo(1);
clear scanData;

scanArraySup = planC{indexS.scan}(1).scanArraySuperior;
scanArrayInf = planC{indexS.scan}(1).scanArrayInferior;
uniformScanInfo = planC{indexS.scan}(1).uniformScanInfo;
sliceNumSup  = uniformScanInfo.sliceNumSup;
sliceNumInf  = uniformScanInfo.sliceNumInf;

%creation options:
origOpts = planC{indexS.CERROptions};
 % this code uses the superior and inferior matrices as well as the original CT scan to graph the CT image.
if isfield(origOpts,'uniformizedDataType')
  if strcmpi(planC{indexS.CERROptions}.uniformizedDataType,'uint8')
    CTMin = planC{indexS.scan}(1).uniformScanInfo.minCTValue;
    CTMax = planC{indexS.scan}(1).uniformScanInfo.maxCTValue;
    CTScale = 255 / (CTMax - CTMin);
  elseif strcmpi(planC{indexS.CERROptions}.uniformizedDataType,'uint16')
    CTMin = planC{indexS.scan}(1).uniformScanInfo.minCTValue;
    CTMax = planC{indexS.scan}(1).uniformScanInfo.maxCTValue;
    CTScale = 65535 / (CTMax - CTMin);
  end
else %scaling wasn't used to create the arrays.  This is here to retain backwards compatibility.
    CTScale = 1;
    CTMin = 0;
end

emptySup = isempty(scanArraySup);
emptyInf = isempty(scanArrayInf);

if exist('native') & native == 1
	if emptySup & emptyInf
      CTUniform3D = single(planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf));
	elseif emptySup & ~emptyInf
      infM = single((double(scanArrayInf) / CTScale) + CTMin);
      CTUniform3D = cat(3, single(planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf)),infM);
	elseif ~emptySup & emptyInf
      supM = single((double(scanArraySup) / CTScale) + CTMin);
      CTUniform3D = cat(3, supM, single(planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf)));
	else % ~emptySup & ~emptyInf
      infM = single((double(scanArrayInf) / CTScale) + CTMin);
      supM = single((double(scanArraySup) / CTScale) + CTMin);
      CTUniform3D = cat(3, supM, single(planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf)), ...
                           infM);
	end     
else
	if emptySup & emptyInf
      CTUniform3D = planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf);
	elseif emptySup & ~emptyInf
      infM = ((double(scanArrayInf) / CTScale) + CTMin);
      CTUniform3D = cat(3, planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf), uint16(infM));
	elseif ~emptySup & emptyInf
      supM = ((double(scanArraySup) / CTScale) + CTMin);
      CTUniform3D = cat(3, uint16(supM), planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf));
	else % ~emptySup & ~emptyInf
      infM = (double(scanArrayInf) / CTScale) + CTMin;
      supM = (double(scanArraySup) / CTScale) + CTMin;
      clear scanArrayInf, scanArraySup;
      CTUniform3D = cat(3, uint16(supM), planC{indexS.scan}(1).scanArray(:, :, sliceNumSup:sliceNumInf), ...
                           uint16(infM));
	end
end

CTUniformInfoS.size = size(CTUniform3D);

