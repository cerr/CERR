function [arearatio] = dicomrt_segmentsarearatio(areas)
% dicomrt_segmentsarearatio(areas)
%
% Calculate the ratio between the MLC segments area and beam area 
% as defined by secondary collimators.
%
% areas is a cell array as generated with dicomrt_segmentsarea 
% and has the following structure:
%
%   beam name    beam area        individual segment area
%                  
%  -----------------------------------------------------------
%  | [beam 1] |  beam area   | (area s1 area s2 ... area sm) | 
%  |          |              |                               |
%  -----------------------------------------------------------
%  |               ...                     ...               |                
%  -----------------------------------------------------------
%  | [beam n] |  beam area   | (area s1 area s2 ... area sp) | 
%  |          |              |                               |
%  -----------------------------------------------------------
% 
% See also dicomrt_mcwarm, dicomrt_segmentsarea
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

arearatio=cell(size(areas,1),2);

for i=1:size(areas,1) % loop over beams
    arearatio{i,1}=areas{i,1};
    for j=1:size(areas{i,2},2) % loop over segments
        arearatio{i,2}(j)=areas{i,3}(j)./areas{i,2}(j);
    end
end

        