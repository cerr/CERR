function convertDICOMArchives(dirRoot, dirListC, storeHere, optionsFile)
%Convert and store series of RTOG directories.
%
%JOD, 6 Feb 03.
%AJH, 23 Jan 04.
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
%storeDir = 'C:\download\data\3dlung\CERROutput\';

%Attempting to make this memory failure resistant
% Save the initial options

save hardOptions.mat dirRoot dirListC storeHere optionsFile;

while(1)
    
    if isempty(dirRoot)
        load(hardOptions.mat)
    end
    
    output = fopen([storeHere 'importerrors.txt'], 'a');
    
    % Header block
    
    for i = 1 : length(dirListC)
        
        dirSt = dirListC{i};
        archiveDir = [dirRoot, dirSt, '\'];
        saveFile = [storeHere, dirSt, '.mat'];
        
        % Make sure we haven't tried to do this one already
        test = fopen(saveFile);
        
        % If we haven't, let's go
        if test == -1
            
            try
                %planC = CERRImport(optionsFile, archiveDir, saveFile);
                cerrImportDiCOM(archiveDir,saveFile,[1 1 1 1 1 1]);
            catch
                fprintf(['Error importing ' dirListC{i} char(10) lasterr char(10)]);
                fprintf(output, ['Error importing ' dirListC{i} char(10) lasterr char(10)]);
                fclose(output);
                %  Attempting to save this thing with a clear all...
                %  hopefully it hasn't burned before this.
                clear all;
            end
        else
            fprintf(['Save file exists: ' saveFile char(10)]);
            fprintf(output, ['Save file exists: ' saveFile char(10)]);
        end
        
    end
    
    
end

fclose(output);


