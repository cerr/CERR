%% 3D printing
% Rules for making VoxelPrint bitmaps:
% - The bitmaps must be in 1-bit BMP format.
% - There must be three bitmaps per layer. (One for each printing material.) Thus, the number of
% bitmaps must be identical for each material, and equal to 3 x the number of layers.
% - A value of 1 on the bitmap indicates a voxel with material; a value of 0 on the bitmap indicates a
% voxel without material.
% - None of the three bitmaps per layer may overlap. It is impossible to print more than one material
% in one voxel.
% - The number of pixels in the X-axis of the bitmap (i.e. the number of columns in the bitmap) must
% be divisible by 32. Crop or pad the bitmaps with empty columns, if necessary.
% - All bitmaps associated with a given print must be the same size.
% - The names of the bitmaps must follow a fixed convention: [name]_xxxx.bmp, where [name]
% indicates the material used and xxxx is a 4-digit number, starting at 0000. If 4 digits are not
% enough for the number of layers, 5 digits may be used, as shown below.
% Example: Material1_00000.bmp, Material1_00001.bmp, … Material1_05432.bmp
% 
% The printing resolution is 600 x 300 dpi. (dpi = dots per inch. Read: bitmap-entry-per-inch.) In
% the printer coordinates, this is defined as X by Y. If you are standing in front of the printer and looking
% into the window at the print platform: the origin is in the top left corner; the X axis goes along the top of
% the print platform, increasing toward the right; and the Y axis along the left side, increasing toward the
% bottom. In the bitmap, this means that 300 rows of the bitmap will print to one inch, and 600 columns of
% the bitmap will print to one inch. Thus, you will have to “stretch” your object slice to have a 2:1 aspect
% ratio (width:height, columns:rows, x:y).
% 
% Each layer is 0.03 mm thick. This is fixed. Divide desired print height by 0.03mm to obtain the
% number of layers. Multiply that by 3 bitmaps per layer, and you will get the total number of bitmaps.

clear all

%% Load CT scan

% Load patients
low_risk = dir('G:\a.CT\3_3Dprints\p41_print\Patient_8849_lowR');
low_risk(1:2) = [];

% define directory to save 3D print files.
SaveDirectory = 'G:\My Documents\MATLAB\PHD\3D Prints\';

fileNam = fullfile(low_risk(1).folder, low_risk(1).name);
planC = loadPlanC(fileNam, tempdir);
indexS = planC{end};

%% Crop scan to reduce size of data. 
% The 3D printer resolution is 0.04 mm x 0.08 mm x 0.03 mm. 
% So keep in mind that the larger the area, the longer the print will take.
% Also, the area selected needs to remain within the printer capability.  

scanNum    = 1;
structName  = 'GTV_MT'; % Structure name

% select cropped size according to memory contraints
margin = 2; %cm, based on surrounding tissue to include/size of the print.
% Printer allows for 10 inches max size.
planC = cropScan(scanNum,1,margin,planC);

% check the cropped scan to make sure the amount of surrounding tissue is
% satisfactory

cropImage = (getScanArray(planC{indexS.scan}(scanNum)));
% cropImage = double(cropImage) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;

%imtool3D(cropImage) % only for visualoization (remove from batch code)


%% Reslice area to the 3D printer resolution

% Since we are only interested in the structure of interest and the
% surrounding region, instead of the cropped scan area, replace
% scan in planC with volToEval. This helps control memory issues related to
% the reslicing of the phantom. 

% Perform check so that the scan extents do not exceed 25.5 x 25.2 x 20.0 cm x,y,z (max size
% allowed by the printer, 300(rows) x 600(cols) dpi)
% CERR units are in cm
x = 0.0085; %cm, fixed for VoxelPrint
y = 0.0042; %cm, fixed for VoxelPrint
z = 0.003; %cm, fixed for VoxelPrint
% sinc flag = 1

% Depending on the size of the area being resliced, this might take a while 
% and may require a lot of computer power. 
% Perform this in chunks instead of the entire volume.
planC = reSliceScan(scanNum,x,y,z,1,planC);

% % save resliced planC for future use.
% optFileName = 'rslice0_Patient_8849_low.mat';
% save_planC(planC,optFileName)


% Generate ellipse (Create ellipse for standalone CT phantom. Use structure
% boundary/mask to insert into another phantom). to-do: make it as an
% optional input to this function/script.
%% create ellipse manually from image
% imtool3D(scan3M(:,:,2:20))
% msk = mask.mask;
xdiv = 1:32:1e6;
xdiv = (xdiv - 1)';
if mod(out_size_x, 32) ~= 0
    id = xdiv(:) > out_size_x;
    k = find( id , 1 );
    out_size_x = xdiv(k, 1);
    x_new = out_size_x;    
end

if mod(out_size_y, 32) ~= 0
    id = xdiv(:) > out_size_y;
    k = find( id , 1 );
    out_size_y = xdiv(k, 1);
    y_new = out_size_y;
end


% Create a logical image of an ellipse with specified
% semi-major and semi-minor axes, center, and image size.
% First create the image.
imageSizeX = x_new;
imageSizeY = y_new;
[columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);



% Next create the ellipse in the image.
centerX = x_new/2;
centerY = y_new/2;
radiusX = 876; % manual input (to-do automate based on structure)
radiusY = 1683; % manual input (to-do automate based on structure)



ellipsePixels = (rowsInImage - centerY).^2 ./ radiusY^2 ...
+ (columnsInImage - centerX).^2 ./ radiusX^2 <= 1;



ellipsePixels=ellipsePixels';
%imtool3D(ellipsePixels) % commented for batch code



% get mask of object
% structNum =2;
% [rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
% [mask3M2, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
% imtool3D(mask3M2(:,:,20:22))


% % 
% % % Rescale intensities
% % scan3M = scan3M - min(scan3M(:));
% % scan3M = scan3M / max(scan3M(:));
% % 
% % 
% % 
% % fname_m1 = 'G:\a.CT\3_3Dprints\p41_print\Patient_11742_lowR\Mat1\';
% % fname_m2 = 'G:\a.CT\3_3Dprints\p41_print\Patient_11742_lowR\Mat2\';
% % fname_m3 = 'G:\a.CT\3_3Dprints\p41_print\Patient_11742_lowR\Mat3\';
% % 
% % 
% % 
% % 
% % % mkdir('G:\a.CT\3_3Dprints\p41_print\Patient_8849_lowR\ThD_Print\Mat1')
% % % mkdir('G:\a.CT\3_3Dprints\p41_print\Patient_8849_lowR\ThD_Print\Mat2')
% % % mkdir('G:\a.CT\3_3Dprints\p41_print\Patient_8849_lowR\ThD_Print\Mat3')
% % 
% % 
% % 
% % 
% % % 3rd mat will be all zedros - no material
% % %
% % % imSize = [y_new, x_new];
% % % Radius = 1000;
% % % Center = [y_new/2, x_new/2];
% % % imDisk = mipdiskimage(imSize,Radius,Center);
% % % imtool3D(imDisk)
% % 
% % 
% % 
% % c = zeros([x_new y_new]);
% % 
% % 
% % 
% % for t = 1:size(scan3M,3)
% % t
% % d = dither(scan3M(:,:,t));
% % b = (1-d);
% % 
% % % gmask = zeros([x_new y_new]);
% % 
% % 
% % 
% % g = zeros([x_new y_new]);
% % g1 = zeros([x_new y_new]);
% % 
% % 
% % 
% % [p,q] = size(d);
% % g(end-p+1:end, end-q+1:end) = d;
% % g1(end-p+1:end, end-q+1:end) = b;
% % 
% % g = g .*ellipsePixels;
% % g1 = g1 .*ellipsePixels;
% % 
% % % gmask(end-p+1:end, end-q+1:end) = single(mask);
% % % comment out during loop. look at 1 imge to make sure all is good
% % % imtool3D(d)
% % % imtool3D(b)
% % % imtool3D(gmask)
% % % imtool3D(g)
% % % imtool3D(newmsk(:,:,i))
% % 
% % 
% % 
% % imwrite(logical(c), [fname_m1, 'Mat1_' sprintf('%05d', t-1) '.bmp']);
% % imwrite(logical(g), [fname_m2, 'Mat2_' sprintf('%05d', t-1) '.bmp']);
% % imwrite(logical(g1), [fname_m3, 'Mat3_' sprintf('%05d', t-1) '.bmp']);
% % end



% % minj = minj + size(scan3M,3);
% % clear scan3M
% % clear mask3M2



%%% Ellipse generation ends

rslice_scan = (planC{indexS.scan}.scanArray); 
rslice_scan = double(rslice_scan);

%imtool(rslice_scan(:,:,33),'DisplayRange', []) % only for visualization (remove for batch code)

%% Save resliced scan array from planC to bitmap format

% The voxel print program needs 3 bitmap files, one for each material. One
% bitmap file needs to be all zeros or blanks. The other two will be based
% on the material loaded in the printer. This file assumes that bay 1 has
% tango plus and bay 2 has vero white. Bay 3 can by anything else. 

% Rescale intensities (between 0 and 1)
rslice_scan = rslice_scan - min(rslice_scan(:));
rslice_scan = rslice_scan / max(rslice_scan(:));


mkdir('G:\My Documents\MATLAB\PHD\3D Prints\Mat3')
material_3 = zeros(size(rslice_scan));

parfor i = 1:size(rslice_scan,3)
    
    % Check if divisible by 32
    % - The number of pixels in the X-axis of the bitmap (i.e. the number of columns in the bitmap) must
    % be divisible by 32. Crop or pad the bitmaps with empty columns, if necessary.
    
    img = rslice_scan(:,:,i);
    
    % to do
    % size(img, 2) and size(img, 1) must be a factor of 32. 
    % Crop or pad based on the extent used. 
%     if mod(size(img, 2), 32) ~= 0
%         sprintf('Need to reslice so divisible by 32')   
%         
%         y = size(img, 2);        
%         while mod(y, 32) ~= 0
%             y = y +1;        
%         end
%         
%         x = size(img, 1);       
%         while mod(x, 32) ~= 0
%             x = x +1;        
%         end
%     
%         img = imresize(img, [x y]);
%         sprintf('New size is: %d x %d', size(img))   
%     end

    % step 1 dither the resliced scan
    % [1] Floyd, R. W., and L. Steinberg, "An Adaptive Algorithm for Spatial Gray Scale," International Symposium Digest of Technical Papers, Society for Information Displays, 1975, p. 36.
    material_1 = dither(img);   % sets threshold automatically. 
                                % Tested to work for tumor and lung printing. 
%     imtool3D(material_1)

    % step 2 set areas equal to zero with NaN and then invert to get 
    % the second set of bitmaps
    material_2 = double(material_1);
    material_2(material_2==0) = NaN;
    material_2(material_2==1)=0;
    material_2(isnan(material_2)) = 1;
    %material_2 = ~material_1;
%     imtool3D(material_2)

    % Material 1 Tango+
    imwrite(logical(material_1), [SaveDirectory '\Mat1\Mat1_' sprintf('%04d', i-1) '.bmp']);    
    
    % Material 2 VeroWhite
    imwrite(material_2, [SaveDirectory '\Mat2\Mat2_' sprintf('%04d', i-1) '.bmp']); 
    
    % Material 3 -- anything -- blank file for our purposes
    imwrite(material_3(:,:,i), [SaveDirectory '\Mat3\Mat3_' sprintf('%04d', i-1) '.bmp']);
end

%% Create associated text file 
% 
% [Build]
% Format version = 1;
% Layer thickness = 0.03;
% Number of slices = 200;
% [Resin Type]
% Support = FullCure705;
% Color = VeroCyan;
% Resin2 = VeroMgnt;
% Resin3 = VeroYellow;
% [Materials]
% Material1 = C:\VoxelPrintDirectory\Material1\Mat1_xxxx.bmp;
% Material2 = C:\VoxelPrintDirectory\Material2\Mat2_xxxx.bmp;
% Material3 = C:\VoxelPrintDirectory\Material3\Mat3_xxxx.bmp;

num_slices = [(size(rslice_scan,3))];

fid = fopen( 'print.txt', 'wt' );
fprintf(fid,'%6s\n%12s\n','[Build]','Format version = 1;');
fprintf(fid,'%6s\n','Layer thickness = 0.03;');
fprintf(fid, 'Number of slices =  %.0f;\n\n', num_slices)


fprintf(fid,'%6s\n%12s\n','[Resin Type]','Support = FullCure705;');
fprintf(fid,'%6s\n%12s\n','Color = Tango+;','Resin2 = VeroWhite;');
fprintf(fid,'%6s\n\n','Resin3 = VeroYellow;');

fprintf(fid,'%6s\n','[Materials]');
fprintf(fid,'%12s\n','Material1 = C:\VoxelPrintDirectory\Mat1\Mat1_xxxx.bmp;'); % filename must be Mat1_xxxx.bmp etc.
fprintf(fid,'%12s\n','Material2 = C:\VoxelPrintDirectory\Mat2\Mat2_xxxx.bmp;');
fprintf(fid,'%12s\n','Material3 = C:\VoxelPrintDirectory\Mat3\Mat3_xxxx.bmp;');

fclose(fid);

%% Check all images
% there can be no overlap between each files in each folder. Check to make sure
% there is no overlap -- basically you can never have two materials in the
% same voxel. 

mat1 = dir(fullfile(SaveDirectory, '\Mat1'));
mat2 = dir(fullfile(SaveDirectory, '\Mat2'));

mat1(1:2) = [];
mat2(1:2) = [];

for p = 1:size(mat1,1)
    
    img_mat1 = imread(mat1(1).folder, '/', mat1(p).name);
    img_mat2 = imread(mat2(1).folder, '/', mat2(p).name);
    % all(img_mat2(:) ~= img_mat1(:)) % to-do use this instead of inf check
    % ?
    if sum(img_mat2(:) ./ img_mat1(:)) ~= Inf
        sprintf('Double Check bitmaps, there is an error')
        break
        
    else
        continue
        
    end
end

    
    
    




