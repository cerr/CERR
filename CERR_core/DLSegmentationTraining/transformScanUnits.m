function scan3M = transformScanUnits(scanIdx,planC,imageUnits)
% scan3M = transformScanUnits(scanIdx,planC,imageUnits)
%-----------------------------------------------------------------------
% INPUTS
% scanIdx
% planC
% imageUnits : Supported values include 'mm^2/s' and 'k mm^2/s',
%              where 'k' is a numeric scale factor. (ADC scans)
%-----------------------------------------------------------------------

% Get current scan units
indexS = planC{end};

scan3M = double(getScanArray(scanIdx,planC));
CTOffset = double(planC{indexS.scan}(scanIdx).scanInfo(1).CTOffset);
scan3M = scan3M - CTOffset;

if isfield(planC{indexS.scan}(scanIdx).scanInfo(1),'philipsImageUnits') && ...
        ~isempty(planC{indexS.scan}(scanIdx).scanInfo(1).philipsImageUnits)
    currScaleUnits =  planC{indexS.scan}(scanIdx).scanInfo(1).philipsImageUnits;
elseif  isfield(planC{indexS.scan}(scanIdx).scanInfo(1),'imageUnits') && ...
        ~isempty(planC{indexS.scan}(scanIdx).scanInfo(1).imageUnits)
    currScaleUnits =  planC{indexS.scan}(scanIdx).scanInfo(1).imageUnits;
end

%Transofrm to desired units
if ~isempty(imageUnits)

    if contains(imageUnits,'mm^2/s')
        sepIdx  = find(isletter(currScaleUnits),1);
        currUnits = strtok(currScaleUnits(sepIdx:end), '_');
        currScale = str2num(strtok(currScaleUnits(1:sepIdx-1), '_'));
        sepIdx  = find(isletter(imageUnits),1);
        desiredScale = str2num(strtok(imageUnits(1:sepIdx-1), '_'));
        if ~ismember(currUnits,{'mm2/s','mm^2/s'})
            error('Invalid intensity units %s. Expected units: mm^2/s',imageUnits);
        else
            scaleFactor = currScale/desiredScale;
        end
        scan3M = scan3M .* scaleFactor;
    else
        error('Image units %s not supported.',imageUnits);
    end

end