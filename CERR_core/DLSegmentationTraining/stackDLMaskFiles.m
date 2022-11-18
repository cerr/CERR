function [outC,ptListC] = stackDLMaskFiles(outPath,outFmt,passedScanDim)
% stackDLMaskFiles.m Reads output mask files and returns 3D stack.
%--------------------------------------------------------------------------
%INPUTS:
% outPath       : Path to generated files
%                 Note: Assumes output filenames are of the form:
%                 prefix_slice# if  passedScanDim = '2D' and
%                 prefix_3D if passedScanDim = '3D'.
% outFmt        : Output format ('H5' or 'NRRD').
% passedScanDim : '2D' or '3D'.
%------------------------------------------------------------------------
% AI 6/29/21

switch outFmt
    
    case 'H5'
        [outC,ptListC] = stackHDF5Files(outPath,passedScanDim);
        
    case 'NRRD'
        
        dirS = dir(fullfile(outPath,'outputNRRD','*.nrrd'));
        fileNameC = {dirS.name};
        ptListC = unique(strtok(fileNameC,'_'));
        outC = cell(length(ptListC),1);
        
        for p = 1:length(ptListC)
            
            %Assumes 3D mask file
            fileName = fullfile(outPath,'outputNRRD',fileNameC{1});
            mask3M = nrrdread_opensrc(fileName);
            outC{p} = mask3M;
        end
        
    otherwise
        
        error('invalid output format %s',outFmt);
        
end
