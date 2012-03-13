function SPCETCell = dicomrt_loadSPECT(filename)
% dicomrt_loadSPECT(filename)
%
% Read dicom SPECT for a case using MATLAB native function dicomread. Light Version.
%
% filename contains a single multiformat SPECT to import
%
% Output SPCETCell
%         SPCETCell{1} = info;
%         SPCETCell{2} = 3D Data;
%         SPCETCell{3} = X Vector;
%         SPCETCell{4} = Y Vector;
%         SPCETCell{5} = Z Slice;
%
% Writte DK

% Retrieve the number of images
nlines=dicomrt_nASCIIlines(filename);

if nlines == 1
    disp('Loading multiframe SPECT study')
    fid=fopen(filename);
    SPECT_file_location=fgetl(fid);
    % check if end of file is reached
    if isnumeric(SPECT_file_location),return,end
    info = dicominfo(SPECT_file_location);
    temp = squeeze(dicomread(info));
    temp(temp<0) = 0;
    try
        ImagePatientPosition = info.ImagePatientPosition;
        zStart = ImagePatientPosition(3);
    catch
        if isfield(info,'SliceLocation')
            zStart = info.SliceLocation;
        else
            zStart = 0;
        end
        xStart = 1;
        yStart = 1;
    end
    zSlice = (info.SliceVector * info.SliceThickness )+ zStart;
else
    hWarn = warndlg('This is a non-multiframe study !work in progress!');
end
patientPosition = getPatientPosition(info);
info.PatientPosition = patientPosition;
pixel_spacing_x=info.PixelSpacing(1);
pixel_spacing_y=info.PixelSpacing(2);

if strcmpi(patientPosition,'HFS')| strcmpi(patientPosition,'FFS')

    [xVec] = dicomrt_create1dmesh(xStart,pixel_spacing_x,size(temp,2),0);
    [yVec] = dicomrt_create1dmesh(yStart,pixel_spacing_y,size(temp,1),0);

else
    [xVec] = dicomrt_create1dmesh(xStart,pixel_spacing_x,size(temp,1),1);
    [yVec] = dicomrt_create1dmesh(yStart,pixel_spacing_y,size(temp,2),1);
end

% zoomFactor = info.DetectorInformationSequence.Item_1.ZoomFactor;
% zoomCenter = info.DetectorInformationSequence.Item_1.ZoomCenter;

SPCETCell{1} = info;
SPCETCell{2} = temp;
% SPCETCell{3} = (xVec*zoomFactor(1))-zoomCenter(1);
% SPCETCell{4} = (yVec*zoomFactor(2))-zoomCenter(2);
SPCETCell{3} = xVec;
SPCETCell{4} = yVec;
SPCETCell{5} = double(zSlice);


function patientPosition = getPatientPosition(info)
% getPatientPosition
% Extracts Patient Postition information from dicom info

Part1 = info.PatientGantryRelationshipCodeSequence.Item_1.CodeMeaning;
if strcmpi(Part1,'HEAD_IN')
    Part1 = 'HF';
else
    Part1 = 'FF';
end

try
    Part2 = info.PatientOrientationCodeSequence.Item_1.CodeMeaning;   
catch
    Part2 = info.PatientOrientationCodeSequence.Item_1.PatientOrientationModifierCodeSequence.Item_1.CodeMeaning;
end

switch upper(Part2)
    case 'SUPINE'
        Part2 = 'S';
    otherwise
        Part2 = 'P';
end

patientPosition = [Part1 Part2];

return