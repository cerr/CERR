function featS = calcRadiomicsFeatUsingPyradiomics(planC,structIn,...
                 paramFilePath,pyradPath)
% Compute radiomic features from PlanC using Pyradiomics
% ----------------------------------------------------------------------
% planC
% structIn      :  structure index (numeric) or structure name (string)
% paramFilePath : Path to .yaml settings
% pyradPath     : Path to Radiomics pkg installation
%----------------------------------------------------------------------
% AI 06/12/2020

%% Get scan & mask
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
if isnumeric(structIn)
    strNum = structIn;
else
    strNum = getMatchingIndex(structIn,strC,'exact');    
end
scanNum = getStructureAssociatedScan(strNum,planC);

%% Calc features
featS = PyradWrapper(scanNum, strNum, paramFilePath, pyradPath, planC);
fieldsC = fieldnames(featS);
for n=1:length(fieldsC)
   if isa(featS.(fieldsC{n}),'py.numpy.ndarray')
       featS.(fieldsC{n}) = double(featS.(fieldsC{n}));
   end
end
       

end
