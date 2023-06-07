function convertedM = convertCoordinates(coordM, imgOri)
% Function to convert between DICOM and CERR coordinates.
% Usage: converted3M = convertCoordinates(coordM, imgOri)
% ------------------------------------------------------------------------
% INPUTS
% coord3M : Input coordinates coordM = (xV,yV,zV)
% ptPos   : Pt. orientation. 
% ------------------------------------------------------------------------
% AI 10/24/19

convertedM = coordM;
convertedM(:,3) = -convertedM(:,3); %Z is always negative to match RTOG spec

% sign if z-coordinate is flippped based on slice normal (similar to
% populate_planC_scan_field). For FFS and FFP this results in original
% value from image position patient.
%sliceNormV = imgOri([2 3 1]) .* imgOri([6 4 5]) ...
%    - imgOri([3 1 2]) .* imgOri([5 6 4]);

if ~isempty(imgOri)
    if max(abs((imgOri(:) - [1 0 0 0 1 0]'))) < 1e-3
        %'HFS' %+x,-y,-z
        convertedM(:,2) = -convertedM(:,2);
    elseif max(abs((imgOri(:) - [-1 0 0 0 1 0]'))) < 1e-3
        %'FFS' %-x,-y,-z
        convertedM(:,2) = -convertedM(:,2);
        convertedM(:,1) = -convertedM(:,1);
        convertedM(:,3) = -convertedM(:,3);
    elseif max(abs((imgOri(:) - [-1 0 0 0 -1 0]'))) < 1e-3
        %'HFP' %-x,+y,-z
        convertedM(:,1) = -convertedM(:,1);
    elseif max(abs((imgOri(:) - [1 0 0 0 -1 0]'))) < 1e-3
        %'FFP' %+x,+y,-z
        convertedM(:,3) = -convertedM(:,3);
    else
        %OBLIQUE
        %skip
    end
    
else
    warning('In convertCoordinates.m: Empty image orientation.');
end

end