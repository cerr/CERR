function MRCell = dicomrt_loadMR(filename)

% Retrieve the number of images
nlines=dicomrt_nASCIIlines(filename);

if nlines == 1
    disp('Only one MR file available');
end

nMR = 0;

h = waitbar(0,'Loading MR files','Name','DICOM MR Import');

fileid = fopen(filename);
while feof(fileid)~=1
    nMR = nMR + 1;    
    MRFileLocation = fgetl(fileid);
    
    % check if end of file is reached
    if isnumeric(MRFileLocation),break,end
    info = dicominfo(MRFileLocation);
    temp = dicomread(info);
    
    ZSlice(nMR) = info.ImagePositionPatient(3);    
    
    MR_Scan_Info{nMR} = info;
    
    MR_Scan(:,:,nMR) = temp;     
    
    waitbar(nMR/nlines,h)
end
close(h);
fclose(fileid);

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

if strcmpi(info.PatientPosition,'HFS')| strcmpi(info.PatientPosition,'FFS')
    [xVec] = createXYCoordVec(start_x,pixel_spacing_x,size(temp,2),'pos');
    [yVec] = createXYCoordVec(start_y,pixel_spacing_y,size(temp,1),'pos');
else
    [xVec] = createXYCoordVec(start_x,pixel_spacing_x,size(temp,1),'neg');
    [yVec] = createXYCoordVec(start_y,pixel_spacing_y,size(temp,2),'neg');% dont know why its done size(temp,2)
end

MRCell{1} = MR_Scan_Info;
MRCell{3} = xVec;
MRCell{4} = yVec;
[ZSlice, zOrder]   = sort(ZSlice,'descend');
MRCell{5} = ZSlice;
MRCell{2} = MR_Scan(:,:,zOrder);
