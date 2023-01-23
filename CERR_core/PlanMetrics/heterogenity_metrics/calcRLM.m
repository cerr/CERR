function rlmOut = calcRLM(quantizedM, offsetsM, nL, rlmType)
% function cooccurM = calcRLM(quantizedM, offsetsM, nL, rlmType)
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

% Default to building RLM by combining all offsets
if ~exist('rlmType','var')
    rlmType = 1;
end

if exist('padarray.m','file')
    quantizedM = padarray(quantizedM,[1 1 1],0,'both');
else
    quantizedM = padarray_oct(quantizedM,[1 1 1],0,'both');
end

% Apply pading of 1 row/col/slc. This assumes offsets are 1. Need to
% parameterize this in case of offsets other than 2. Rarely used for
% medical images.
numColsPad = 1;
numRowsPad = 1;
numSlcsPad = 1;

% Pad quantizedM
q = padarray(quantizedM,[numRowsPad numColsPad numSlcsPad],0,'both');

% Assign zeros to NaN voxels.
q(isnan(q)) = 0;

q = uint16(q); % q is the quantized image

% Number of offsets
numOffsets = size(offsetsM,1);

% Max run length in units of voxels (consider parameterizing)
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
    
    % loop over all gray levels        
    for level = 1:nL
        
        % Take difference between the original and the circshifted image to
        % figure out start and the end of runs.
        diffM = (q==level) - (circshift(q,offset)==level);
        
        % 1's represent start of runs        
        startM = diffM == 1;
        
        startIndV = find(startM);
        
        prevM = uint16(q == level);
        convergedM = ~startM;        
        
        while ~all(convergedM(:))
                        
            nextM = circshift(prevM,-offset);
            
            addM = prevM + nextM;
            
            newConvergedM = addM == prevM;
            
            toUpdateM = ~convergedM & newConvergedM;
            
            prevM = nextM;
            prevM(startIndV) = addM(startIndV);
            
            lenV = addM(toUpdateM);
            
            % accumulate lengths into run length matrix
            rlmM(level,:) = rlmM(level,:) + accumarray(lenV,1,[maxRunLen 1])';    
            
            convergedM = convergedM | newConvergedM;
            
        end
        
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
