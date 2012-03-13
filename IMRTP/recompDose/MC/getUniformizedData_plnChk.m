function [indicesM, structBitsM, planC] = getUniformizedData(planC, scanNum, makeUniform)
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
%   function [indicesM, structBitsM, planC] = getUniformizedData(planC, scanNum, makeUniform)

indexS = planC{end};
optS = planC{indexS.CERROptions};

if ~exist('makeUniform')
    makeUniform = 'yes';
elseif ~strcmpi(makeUniform, 'yes') & ~strcmpi(makeUniform, 'no') & ~strcmpi(makeUniform, 'prompt')
    error(['Invalid call to getUniformizedData, legal flags are ''yes'', ''no'', or ''prompt''.']);
end

indicesM    = planC{indexS.structureArray}(scanNum).indicesArray;
structBitsM = planC{indexS.structureArray}(scanNum).bitsArray;

if ~isempty(indicesM) | ~isempty(structBitsM)
    return;
else
    switch lower(makeUniform)
        case 'yes'
            %Generate the uniformized data.
            planC       = setUniformizedData(planC, optS);
            indicesM    = planC{indexS.structureArray}(scanNum).indicesArray;
            structBitsM = planC{indexS.structureArray}(scanNum).bitsArray;    
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
                    wantToSave = questdlg('Would you like to save the new data generated for future sessions?', 'Save Option','Yes','No','Yes');
%                     if strcmp(wantToSave, 'Yes')
%                         sliceCallBack('saveplanc');
%                     end
                case 'No'
                    return;
            end       
            
    end
end