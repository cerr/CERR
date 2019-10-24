function converted3M = convertCoordinates(coord3M, ptPos)
% Function to convert between DICOM and CERR coordinates.
% Usage: converted3M = convertCoordinates(coord3M, ptPos)
% ------------------------------------------------------------------------
% INPUTS
% coord3M : Input coordinates coord3M = (xV,yV,zV)
% ptPos   : String indicating pt. position. Supported optins include'HFS',
%           'FFS', 'HFP', 'FFP' and 'OBLIQUE'
% ------------------------------------------------------------------------
% AI 10/24/19

converted3M = coord3M;
converted3M(:,3) = -converted3M(:,3); %Z is always negative to match RTOG spec

switch upper(ptPos)
    case 'HFS' %+x,-y,-z
        converted3M(:,2) = -converted3M(:,2);
    case 'HFP' %-x,+y,-z
        converted3M(:,1) = -converted3M(:,1);
    case 'FFS' %-x,-y,-z
        converted3M(:,2) = -converted3M(:,2);
        converted3M(:,1) = -converted3M(:,1); 
    case 'FFP' %+x,+y,-z
        %skip
    case 'OBLIQUE'
        %Oblique
        warning('Defaulting to HFS .');
        converted3M(:,2) = -converted3M(:,2); 
    otherwise
        error('Invalid pt. position %s',ptPos)
end



end