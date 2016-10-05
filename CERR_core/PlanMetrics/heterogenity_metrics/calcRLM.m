function rlmOut = calcRLM(quantizedM, offsetsM, nL, rlmType)
% function cooccurM = calcRLM(quantizedM, offsetsM, nL, cooccurType)
%
% This function calculates the Run-Length matrix for the passed quantized
% image.
%
% INPUTS:
%       quantizedM: quantized 3d matrix obtained, for example, by
%       imquantize_cerr.m
%       offsetsM: Offsets for directionality/neighbors, obtained by
%       getOffsets.m
%       nL: Number of gray levels.
%       rlmType: flag, 1 or 2.
%                   1: returns a single (nL x L) run-length matrix by
%                   combining contributions from all directions into one.
%                   2: returns a cell array with elements of the cell
%                   array containing the run-length matrices per direction.
% OUTPUT:
%       rlmM: run-length matrix of size (nL x L) for rlmType = 1,
%       cell array of size equal to the number of directions for rlmType = 2.
%
% EXAMPLE:
%
% numRows = 10;
% numCols = 10;
% numSlcs = 1;
% 
% % get directions
% offsetM = getOffsets(1);
% 
% % number of gray levels
% nL = 3;
% 
% % create an image with random numbers
% imgM = randi(nL,numRows,numCols,numSlcs);
% 
% % set option to add run lengths from all directions
% rlmType = 1;
% 
% % call the rlm calculator
% rlmM = calcRLM(imgM, offsetM, nL, rlmType);
%
%
% APA, 09/12/2016

% Default to building cooccurrence by combining all offsets
if ~exist('rlmType','var')
    rlmType = 1;
end

% Apply pading of 1 row/col/slc. This assumes offsets are 1. Need to
% parameterize this in case of offsets other than 2. Rarely used for
% medical images.
numColsPad = 1;
numRowsPad = 1;
numSlcsPad = 1;

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(quantizedM);

% Pad quantizedM
q = padarray(quantizedM,[numRowsPad numColsPad numSlcsPad],0,'both');

% Assign zeros to NaN voxels.
q(isnan(q)) = 0;

q = uint16(q); % q is the quantized image

% Number of offsets
numOffsets = size(offsetsM,1);

% Max run length in units of voxels
maxRunLen = 1000;

% Initialize the run-length matrix
rlmM = zeros(nL,maxRunLen);

% Loop over directions
for off = 1:numOffsets
    
    % re-initialize rlmM separately for each direction in case rlmType = 2.
    if rlmType == 2
        rlmM = zeros(nL,maxRunLen);
    end
    
    % Selected offset
    offset = offsetsM(off,:);
    
    % Get the image
    slc1M = q(numRowsPad+(1:numRows),numColsPad+(1:numCols),...
        numSlcsPad+(1:numSlices));
    
    % Get the circshifted image
    slc2M = circshift(q,offset);
    slc2M = slc2M(numRowsPad+(1:numRows),numColsPad+(1:numCols),numSlcsPad+(1:numSlices));
    
    % loop over all gray levels    
    for level = 1:nL
        
        % Take difference between the original and the circshifted image to
        % figure out start and the end of runs.
        diffM = (slc1M==level) - (slc2M==level);
        
        % 1's represent start of runs        
        startIndV = find(diffM(:) == 1);
        
        % -1's represent end of runs
        endIndV = find(diffM(:) == -1);
        
        % Get row,col,slice for the run-starts
        [rV,cV,sV] = ind2sub([numRows, numCols, numSlices],startIndV);
        
        lenV = [];
        % This is where the run lengths are accumulated. Loop over all the 
        % starting indices to calculate run lengths.
        for i = 1:length(startIndV)
            
            % ind is the current starting index in the loop
            ind = startIndV(i);
            
            % Figure out the voxel index for the end of the run.
            
            numRowSteps = inf;
            if offset(1) > 0
                numRowSteps = numRows - rV(i);
            elseif offset(1) < 0
                numRowSteps = rV(i) - 1;
            end
            
            numColSteps = inf;
            if offset(2) > 0
                numColSteps = numCols - cV(i);
            elseif offset(2) < 0
                numColSteps = cV(i) - 1;
            end
            
            numSlcSteps = inf;
            if offset(3) > 0
                numSlcSteps = numSlices - sV(i);
            elseif offset(3) < 0
                numSlcSteps = sV(i) - 1;
            end
            
            numStepsToEnd = min([numRowSteps numColSteps numSlcSteps]);
            
            rowEnd = rV(i) + offset(1)*numStepsToEnd;
            colEnd = cV(i) + offset(2)*numStepsToEnd;
            slcEnd = sV(i) + offset(3)*numStepsToEnd;
            
            endIndex = rowEnd + numRows*(colEnd-1) + numRows*numCols*(slcEnd-1);            
            
            % Figure out the step size in terms of linear index
            deltaIndex = offset(1) + numRows*offset(2) + numRows*numCols*offset(3);
            
            % these are all available indices to choose from
            availableIndV = ind+deltaIndex:deltaIndex:endIndex;
            
            % currentEndV contains the end indices for the current
            % situation.
            if ~ismember(endIndex,endIndV)
                currentEndV = [endIndV; endIndex];
                endFlag = 1;
            else
                currentEndV = endIndV;
                endFlag = 0;
            end
            
            % See if any of the currentEndV belong to availableIndV.
            assocIndV = find(ismember(currentEndV,availableIndV));
            
            % assocIndV will be empty for boundary starting index. Hence,
            % count that as 1, otherwise get the closest end index.
            if ~isempty(assocIndV)
                % try to speedup, get rid of "min"
                [~,minInd] = min((ind - currentEndV(assocIndV)).^2);
                endInd = currentEndV(assocIndV(minInd));
                len = abs(endInd-ind)/abs(deltaIndex);
                if endInd == endIndex && endFlag
                    len = len + 1;
                end
            else
                len = 1;
            end
            lenV = [lenV len];
        end
        
        % accumulate lengths into run length matrix
        rlmM(level,:) = rlmM(level,:) + accumarray(lenV',1,[maxRunLen 1])';
        
    end
    
    % rlmOut is cell array for rlmType == 2
    if rlmType == 2
        rlmOut{off} = rlmM;
    end
    
end

% assign rlmM to rlmOut for rlmType == 1
if rlmType == 1
    rlmOut = rlmM;
end

return;

