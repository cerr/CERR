function T13M = getT1Maps(xSize, ySize, nSlices, slStart, workSlices)
% If using T1 maps, load T1 maps for all slices into a 3D array
% ---------------------------------------------------------------------------

%Get location
T13M = zeros(xSize, ySize, nSlices);
prompt = 'SINGLE Click on the file containing the T1 map for the first slice ' ;
[T1mapfName, T1mapfPath] = uigetfile([dirname '/*'],prompt);
T1mapFullName = [T1mapfPath T1mapfName];
fprintf('\nT1 map file: %s\n',T1mapFullName);
%infoT1 = dicominfo(T1mapFullName);
%T1Slice = dicomread(infoT1);

%Get the root name for the T1 images
%  Figure out the base name for all mask files (they all have the  extension _SL##)
%  Search for the period before the .dcm.  Then count backward from there
periodLoc = strfind(T1mapFullName, '.');
fullT1MapRoot = T1mapFullName(1:periodLoc-6);

for k = 1:workSlices
    
    sliceNum = slStart + k-1;
    sliceStr = num2str(sliceNum);
    len1 = length(sliceStr);
    if (len1 == 1)
        sliceStr = ['0' sliceStr];
    end
    ext = ['_SL' sliceStr '.dcm'];
    T1MapFile = [fullT1MapRoot ext];
    %temp_infoT1 = dicominfo(T1MapFile);
    tempT1 = dicomread(T1MapFile);
    T13M(:, :, k)  = tempT1;
    
end

end


