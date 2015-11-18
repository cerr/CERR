function UID = createUID(modality)
% createUID
% The UID will be created for Scan, Dose OR Structure based on the
% "command" passed to the function. Command can be "CT" or "DOSE" etc. The
% UID is created based on the following logic.
% Field1 = S (stands for scan )
% Field2 = date (date that UID was created)
% Field3 = Time (Its the instance of plan creation/Merge)
% Field4 = Add a random 3 digit number after milliseconds
%
% Example UID = 'CT.1072006.181516.24'
% Where date is 10/07/2006 and time is 6:15pm (1815 Hours)16 sec and 24
% milliseconds
%
% DK 07/11/2006
% copyright (c) 2001-2008, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).


dateTimeV = clock;
% dateTimeV = [year month day hour minute seconds]

switch upper(modality)
    case 'SCAN'
        modality = 'CT';
    case 'STRUCTURE'
        modality = 'RS';
    case 'DOSE'
        modality = 'RD';
    case 'DVH'
        modality = 'DH';
    case 'STRUCTURESET'
        modality = 'SA'; %structure Array
    case 'IVH' % Intensity Volume Histogram
        modality = 'IH';        
    case 'BEAMS'
        modality = 'RP';
    case 'CERR'
        modality = 'CERR';
    case 'DEFORM'
        modality = 'DIR';
    case 'ANNOTATION'
        modality = 'PR';
    case 'REGISTRATION'
        modality = 'REG';
    case 'IM'
        modality = 'IM';
    case 'BEAM'
        modality = 'BM';
    case 'TEXTURE'
        modality = 'TXTR';
end
% randNum = ceil(1000 + (9999-1000).*rand);
randNum = 1000.*rand;
UID = [upper(modality) '.' num2str(dateTimeV(3)) num2str(dateTimeV(2)) num2str(dateTimeV(1)) '.' ...
    num2str(dateTimeV(4)) num2str(dateTimeV(5)) num2str(dateTimeV(6)) num2str(randNum)];

