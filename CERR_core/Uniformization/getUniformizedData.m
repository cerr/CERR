function [indicesC, structBitsC, planC] = getUniformizedData(planC, scanNum, makeUniform)
%"getUniformizedData"
%   Data Access Function
%   Returns indicesM and structBitsM for given planC.
%
%   makeUniform is an optional parameter which determines if the
%   uniformized data should be generated in the case where it does not
%   already exist. 'yes' by default.
%       'no'        = do not generate.
%       'yes'       = generate.
%       'prompt'    = ask user if they want to generate.
%
%   This may change but:
%   Also, calls fixStructureZVals in order to repair any differences in zValues
%   between the CT scan and the rasterSegs/Contour of the structure.  These must be
%   consistent for uniformized data to function correctly.
%
% JRA 10/27/03
% JRA 04/19/04 -- added prompt and the makeUniform flag.
%
%Usage:
%   function [indicesC, structBitsC, planC] = getUniformizedData(planC, scanNum, makeUniform)
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
indexS = planC{end};
optS = planC{indexS.CERROptions};

if ~exist('makeUniform')
    makeUniform = 'yes';
elseif ~strcmpi(makeUniform, 'yes') & ~strcmpi(makeUniform, 'no') & ~strcmpi(makeUniform, 'prompt')
    error(['Invalid call to getUniformizedData, legal flags are ''yes'', ''no'', or ''prompt''.']);
end

indicesM    = planC{indexS.structureArray}(scanNum).indicesArray;
structBitsM = planC{indexS.structureArray}(scanNum).bitsArray;

indicesC    = planC{indexS.structureArrayMore}(scanNum).indicesArray;
structBitsC = planC{indexS.structureArrayMore}(scanNum).bitsArray;

indicesC = [{indicesM} indicesC];
structBitsC = [{structBitsM} structBitsC];

if ~isempty(indicesC) || ~isempty(structBitsC)
    return;
else
    switch lower(makeUniform)
        case 'yes'
            %Generate the uniformized data.
            planC       = setUniformizedData(planC, optS);
            indicesM    = planC{indexS.structureArray}(scanNum).indicesArray;
            structBitsM = planC{indexS.structureArray}(scanNum).bitsArray;
            indicesC    = planC{indexS.structureArrayMore}(scanNum).indicesArray;
            structBitsC = planC{indexS.structureArrayMore}(scanNum).bitsArray;
            indicesC = [{indicesM} indicesC];
            structBitsC = [{structBitsM} structBitsC];
        case 'no'
            %Return with the empty indicesM and structBitsM
            return;
        case 'prompt'
            generate=questdlg('Requested function requires uniformized data, which has not been generated.  Do you wish to generate now? (This may take a several minutes).', ...
                'Generate Uniformized Data?', 'Yes','No','Yes');
            switch generate
                case {'Yes' , []}
                    planC       = setUniformizedData(planC, optS);
                    indicesM    = planC{indexS.structureArray}(scanNum).indicesArray;
                    structBitsM = planC{indexS.structureArray}(scanNum).bitsArray;
                    indicesC    = planC{indexS.structureArrayMore}(scanNum).indicesArray;
                    structBitsC = planC{indexS.structureArrayMore}(scanNum).bitsArray;
                    indicesC = [{indicesM} indicesC];
                    structBitsC = [{structBitsM} structBitsC];
                    wantToSave = questdlg('Would you like to save the new data generated for future sessions?', 'Save Option','Yes','No','Yes');
                    if strcmp(wantToSave, 'Yes')
                        sliceCallBack('saveplanc');
                    end
                case 'No'
                    return;
            end       
            
    end
end