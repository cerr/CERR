function [outMask3M, planC] = getMaskForModelConfig(planC,...
                              mask4M,scanNum,cropS)
% getMaskForModelConfig.m
% Create mask for deep learning based on input configuration ftile.
%
% AI 7/23/19
%--------------------------------------------------------------------------
%INPUTS:
% planC
% mask4M       : 4-D array with 3D structure masks stacked along 
% scanNum        
% cropS        : Dictionary of parameters for cropping
%                Supported methods: 'crop_fixed_amt','crop_to_bounding_box',
%                'crop_around_center', 'crop_to_str', 'crop_to_str_on_scan', 
%                'crop_pt_outline', 'crop_pt_outline_on_scan',
%                'crop_around_structure_center',
%                'crop_around_center_of_mass_on_scan','none'.
%--------------------------------------------------------------------------
% AI 7/23/19
% RKP 9/13/19 

indexS = planC{end};

origMask4M = mask4M;
methodC = {cropS.method};
maskC = cell(length(methodC),1);

for m = 1:length(methodC)

    method = methodC{m};
    paramS = [];
    if isfield(cropS(m),'params')
        paramS = cropS(m).params;
    end
    
    switch(lower(method))
        
        case 'crop_fixed_amt'
            cropDimV = paramS.margins;
            outMask3M = false(size(getScanArray(scanNum,planC)));
            outMask3M(cropDimV(1):cropDimV(2),...
                cropDimV(3):cropDimV(4),cropDimV(5):cropDimV(6)) = true;
            maskC{m} = outMask3M;
            
        case {'crop_to_bounding_box','crop_to_bounding_box_2d'}
            %Use to crop around one of the structures to be segmented
            %(bounding box computed for 3D mask)
            label = paramS.label;
            outMask3M = false(size(getScanArray(scanNum,planC)));
            if ~isempty(origMask4M)
                outMask3M = squeeze(origMask4M(:,:,:,label));
            else
               warning(['Missing label = ', num2str(label)]); 
            end
            maskC{m} = outMask3M;

            
        case {'crop_to_str', 'crop_to_str_2d', 'crop_to_str_on_scan', 'crop_to_str_2d_on_scan'}
            %Use to crop around different structure
            %mask3M = []
            strName = paramS.structureName;
            numStructs = length(planC{indexS.structures});
            assocScanV = getStructureAssociatedScan(1:numStructs,planC);
            strC = {planC{indexS.structures}.structureName};
            strIdx = getMatchingIndex(strName,strC,'EXACT');
            
            if ~isempty(strfind(method,'scan')) %octave compatible
                %Crop around structure on (another) scan
                % specified through valid identifier
                idS = paramS.scanIdentifier;
                scanId = getScanNumFromIdentifiers(idS,planC);
            else
                scanId  = scanNum;
            end
            
            % Find structure associated with scanNum
            if ~isempty(strIdx)
                strIdx = strIdx(assocScanV(strIdx) == scanId);
            end
            if ~isempty(strIdx)
                [outMask3M, planC] = getStrMask(strIdx,planC);
            else
                warning(['Missing structure ', strName]); 
                outMask3M = false(size(getScanArray(scanId,planC)));
            end
            maskC{m} = outMask3M;
            
        case 'crop_around_center'
            % Use to crop around center
            cropDimV = paramS.margins;
            scanSizV = size(getScanArray(scanNum,planC));
            
            cx = ceil(scanSizV(1)/2);
            cy = ceil(scanSizV(2)/2);
            x = cropDimV(1)/2;
            y = cropDimV(2)/2;
            minr = cx - y;
            maxr = cx + y-1;
            minc = cy - x;
            maxc = cy + x-1;
            mins = 1;
            maxs = scanSizV(3);
            
            outMask3M = false(scanSizV);
            outMask3M(minr:maxr,minc:maxc,mins:maxs) = true;
            maskC{m} = outMask3M;

        case {'crop_around_structure_center', 'crop_around_structure_center_on_scan'}
            strName = paramS.structureName;
            cropDimV = paramS.margins;

            x = cropDimV(1)/2;
            y = cropDimV(2)/2;

            numStructs = length(planC{indexS.structures});
            assocScanV = getStructureAssociatedScan(1:numStructs,planC);
            strC = {planC{indexS.structures}.structureName};
            strIdx = getMatchingIndex(strName,strC,'EXACT');
            
            if ~isempty(strfind(method,'scan')) %octave compatible
                %Crop around structure on (another) scan
                % specified through valid identifier
                idS = paramS.scanIdentifier;
                scanId = getScanNumFromIdentifiers(idS,planC);
            else
                scanId  = scanNum;
            end
            
            % Find structure associated with scanNum
            if ~isempty(strIdx)
                strIdx = strIdx(assocScanV(strIdx) == scanId);
            end
            if ~isempty(strIdx)
                [strMask3M, planC] = getStrMask(strIdx,planC);
                [minr,maxr,minc,maxc,mins,maxs] = ...
                    compute_boundingbox(strMask3M);
                minr = floor((minr+maxr)/2) - x;
                minc = floor((minc+maxc)/2) - y;
                if length(cropDimV)==2
                    slcV = mins:maxs;
                else
                    z = floor(cropDimV(3)/2);
                    mids = floor((mins+maxs)/2);
                    mins = max(mids-z,1);
                    slcV = mins:mins+cropDimV(3)-1;
                end
                outMask3M = false(size(strMask3M));
                outMask3M(minr:minr+cropDimV(1)-1, ...
                    minc:minc+cropDimV(2)-1,slcV) = true;
            else
                warning(['Missing structure ', strName]);
                outMask3M = false(size(getScanArray(scanId,planC)));
            end
            
            maskC{m} = outMask3M;
            

        case {'crop_around_center_of_mass','crop_around_center_of_mass_on_scan'}

            cropStr = paramS.structureName;

            % Get margin units
            marginUnits = 'voxels'; %default if not specified
            if isfield(paramS,'marginUnits')
                marginUnits = paramS.marginUnits;
            end
            marginV = reshape(paramS.margins,1,[]);

            %Get structure-associated scan
            if ~isempty(strfind(method,'scan')) %octave compatible
                %Crop around structure on (another) scan
                % specified through valid identifier
                idS = paramS.scanIdentifier;
                scanId = getScanNumFromIdentifiers(idS,planC);
            else
                scanId  = scanNum;
            end

            %Compute output image dimensions
            if ismember(marginUnits,{'mm','cm'})
                %Convert input margins to voxel units
                [xValsV, yValsV, zValsV] = ...
                    getScanXYZVals(planC{indexS.scan}(scanId));
                if yValsV(1) > yValsV(2)
                    yValsV = fliplr(yValsV);
                end
                dx = median(diff(xValsV));
                dy = median(diff(yValsV));
                dz = median(diff(zValsV));
                inputResV = [dx,dy,dz];
                if strcmpi(marginUnits,'mm')
                    inputResV = inputResV*10; %Convert scan resolution to mm
                end
                outputImgSizeV = round(marginV./inputResV(1:length(marginV)));
            else
                outputImgSizeV = marginV;
            end

            if isfield(paramS,'assignBkgIntensity')
                bkgVal = paramS.assignBkgIntensity.assignVal;
            else
                bkgVal = [];
            end

            %Crop around COM
            [~,outMask3M] = cropAroundCOM(scanId,cropStr,...
                outputImgSizeV,bkgVal,planC);
            maskC{m} = outMask3M;

        case {'crop_pt_outline', 'crop_pt_outline_2d', 'crop_pt_outline_on_scan', 'crop_pt_outline_on_scan_2d'}
            
            structureName = paramS.structureName;
            outThreshold = paramS.outlineThreshold;  
            if isfield(paramS,'minMaskSize')
                minMaskSize = paramS.minMaskSize;
            else
                minMaskSize = [];
            end
            if isfield(paramS,'normFlag')
                normFlag = paramS.normFlag;
            else
                normFlag = 0;
            end
            
            if ~isempty(strfind(method,'scan')) %octave compatible
                %Crop around structure on (another) scan
                % specified through valid identifier
                idS = paramS.scanIdentifier;
                scanId = getScanNumFromIdentifiers(idS,planC);
            else
                scanId  = scanNum;
            end
            
            % Check for outline structure associated with scanId
            outlineIndex = getMatchingIndex(structureName,...
                {planC{indexS.structures}.structureName},'exact');
            numStructs = length(planC{indexS.structures});
            assocScanV = getStructureAssociatedScan(1:numStructs,planC);
            if ~isempty(outlineIndex)
                outlineIndex = outlineIndex(assocScanV(outlineIndex) == scanId);
                 if length(outlineIndex)>1
                    outlineIndex = outlineIndex(end);
                end
            end
            
            %Get mask of pt outline
            if isempty(outlineIndex)
                scan3M = getScanArray(scanId,planC);
                CToffset = double(planC{indexS.scan}(scanId).scanInfo(1).CTOffset);
                scan3M = double(scan3M);
                scan3M = scan3M - CToffset;
                sliceV = 1:size(scan3M,3);
                outMask3M = getPatientOutline(scan3M,sliceV,outThreshold,...
                            minMaskSize,normFlag);
                maskC{m} = outMask3M;
            else
                [maskC{m}, planC] = getStrMask(outlineIndex,planC);
            end
            
        case 'crop_shoulders'
            % Use to crop above shoulders
            % Use pt_outline structure generated in "crop_pt_outline" case
            strName = paramS.structureName;
            strNum = getMatchingIndex(strName,{planC{indexS.structures}.structureName},'exact');
            
            numStructs = length(planC{indexS.structures});
            assocScanV = getStructureAssociatedScan(1:numStructs,planC);
            % Find structure associated with scanNum
            if ~isempty(strNum)
                strNum = strNum(assocScanV(strIdx) == scanNum);
            end

            [pt_outline_mask3M, planC] = getStrMask(strNum,planC);
            
            % generate mask after cropping shoulder slices
            outMask3M = cropShoulder(pt_outline_mask3M,planC);
            maskC{m} = outMask3M;
            
        case 'crop_sup_inf'
            if ~isempty(origMask4M)
                sumMask3M = sum(origMask4M,4) > 0;
                [~, ~, ~, ~, mins, maxs] = ...
                    compute_boundingbox(sumMask3M);
                outMask3M = false(size(sumMask3M));
                outMask3M(:,:,mins:maxs) = true;
            else
                warning('Input ''mask3M'' is empty.'); 
                outMask3M = false(size(getScanArray(scanNum,planC)));
            end
            maskC{m} = outMask3M;
            
        case 'none'
            %Skip
            in
            maskC{m} = [];
            
        otherwise
            %Custom crop function
            [maskC{m},planC] = feval(method,planC,paramS,...
                               mask3M,scanNum);
    end
    
    %Save to planC if reqd
    if isfield(paramS,'saveStrToPlanCFlag') && ...
            paramS.saveStrToPlanCFlag

        if isfield(paramS,'outStrName')
            outStrName = paramS.outStrName;
        else
            outStrName = method;
        end
        if isfield(paramS,'scanIdentifier')
            idS = paramS.scanIdentifier;
            scanId = getScanNumFromIdentifiers(idS,planC);
        else
            scanId = scanNum;
        end
        planC = maskToCERRStructure(maskC{m}, 0, scanId,...
                outStrName,planC);
    end
    
    if m>1
        switch lower(cropS(m).operator)
            case 'union'
                outMask3M = or(maskC{m-1},maskC{m});
                maskC{m} = outMask3M;
            case 'intersection'
                outMask3M = and(maskC{m-1},maskC{m});
                maskC{m} = outMask3M;
            case 'latest'
                %Return latest resulting mask 
                %maskC{m} = maskC{m};
        end
    end
    
end


outMask3M = maskC{end};

end