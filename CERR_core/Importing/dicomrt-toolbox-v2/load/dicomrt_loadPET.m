function PETCell = dicomrt_loadPET(filename)
% dicomrt_loadPET(filename)
%
% Read dicom PET for a case using MATLAB native function dicomread. Light Version.
%
% filename contains a list of PET slices to import
%
% Output PETCell
%         PETCell{1} = PET_Scan_Info;
%         PETCell{2} = PET_Scan;
%         PETCell{3} = xVec;
%         PETCell{4} = yVec;
%         PETCell{5} = sort(ZSlice);
%
% Writte DK

% Retrieve the number of images
nlines=dicomrt_nASCIIlines(filename);

if nlines == 1
    disp('Only one PET file available');
end

PETOffSet = 1000; nPET = 0;

h = waitbar(0,'Loading PET and Calculating SUV ....');
set(h,'Name','DICOM PET Import');

fid = fopen(filename); % Open file and read the contents
suvFlg = 1;
while feof(fid)~=1
    nPET = nPET +1;
    PETFileLocation = fgetl(fid);
    if isnumeric(PETFileLocation), break, end %end of line reached

    info = dicominfo(PETFileLocation);

    try
        %Check if PET is corrected for Scatter and attenuation
        if nPET == 1
            CorrectedImage = info.CorrectedImage;
            if ~strfind('ATTN',CorrectedImage)|| ~strfind('SCAT',CorrectedImage)
                wDlg = warndlg('PET imported is not corrected for Attenuation OR Scatter. The Intensities for SUV calculation will differ from PET scan with following correction');
                waitfor(wDlg);
            end
        end
    end
    
    temp = dicomread(info);
    ZSlice(nPET)= info.ImagePositionPatient(3);

    PET_Scan_Info{nPET} = info;
    try
        if suvFlg
            PET_Scan(:,:,nPET) = calc_suv(info,double(temp));
        else
            PET_Scan(:,:,nPET) = double(temp);
        end        
    catch
        suvFlg = 0;
        if nPET == 1
            warndlg('Calculation for SUV failed ! Storing Values as is');
        end
        PET_Scan(:,:,nPET) = double(temp);
    end
    
    waitbar(nPET/nlines,h)
end

close (h);

fclose(fid);

% PatientOrientation     ImageOrientationPatient
%
% HFS                    (1,0,0) (0,1,0)
% FFS                    (1,0,0) (0,1,0)
% HFP                    (-1,0,0) (0,-1,0)
% FFP                    (-1,0,0) (0,-1,0)
start_x=info.ImagePositionPatient(1);
pixel_spacing_x=info.PixelSpacing(1);

start_y=info.ImagePositionPatient(2);
pixel_spacing_y=info.PixelSpacing(2);
disp(['Patient Position is ' info.PatientPosition]);
%

if strcmpi(info.PatientPosition,'HFS')| strcmpi(info.PatientPosition,'FFS')
    [xVec] = createXYCoordVec(start_x,pixel_spacing_x,size(temp,2),'pos');
    [yVec] = createXYCoordVec(start_y,pixel_spacing_y,size(temp,1),'pos');
else
    [xVec] = createXYCoordVec(start_x,pixel_spacing_x,size(temp,1),'neg');
    [yVec] = createXYCoordVec(start_y,pixel_spacing_y,size(temp,2),'neg');
end


PETCell{1} = PET_Scan_Info;
PETCell{3} = xVec;
PETCell{4} = yVec;
[ZSlice, zOrder]   = sort(ZSlice,'descend');
PETCell{5} = ZSlice;
PETCell{2} = PET_Scan(:,:,zOrder);