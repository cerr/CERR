function scan3M = transformScanUnits(scanIdx,planC,imageUnits)
% scan3M = transformScanUnits(scanIdx,planC,imageUnits)
%-----------------------------------------------------------------------
% INPUTS
% scanIdx
% planC
% imageUnits : '10^-3 mm^2/s' (ADC scans)
%-----------------------------------------------------------------------

indexS = planC{end};

scan3M = double(getScanArray(scanIdx,planC));
CTOffset = double(planC{indexS.scan}(scanIdx).scanInfo(1).CTOffset);
scan3M = scan3M - CTOffset;

if ~isempty(imageUnits)

    switch(imageUnits)

        case '10^-3 mm^2/s'
            if isfield(planC{indexS.scan}(scanIdx).scanInfo(1),'philipsImageUnits')
                currUnits =  planC{indexS.scan}(scanIdx).scanInfo(1).philipsImageUnits;
                sepIdx = strfind(currUnits,' ');
                val = str2num(currUnits(1:sepIdx-1));
                units = currUnits(sepIdx+1:end);
                if ~strcmp(units,'mm^2/s')
                    error('Invalid intensity units %s. Expected units: mm^2/s',units);
                else
                    scaleFactor = 10^-3/val;
                end
            else
                warning('Image units unknown. Skipping transformation.Expected ''10^-3 mm^2/s''.')
                scaleFactor = 1;
            end
            scan3M = scan3M .* scaleFactor;

        otherwise
            error('Image units %s not supported.',imageUnits);

    end

end

end