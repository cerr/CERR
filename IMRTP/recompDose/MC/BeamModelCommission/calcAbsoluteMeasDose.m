function [varargout] = calcAbsoluteMeasDose(calbDepth, calbDose, varargin)
% [FS10x10 FS20x20 FS30x30] = calcAbsoluteMeasDose(calDepth, calDose, FS10x10, FS20x20, FS30x30)
% calibration point:
% calbDepth = 1.5;     %Calibration depth is for field size == 10x10cm2, 100SSD, depth = 1.5cm for 6MV.
% calbDose = 1;        %Calibration point is 1cGy/MU
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

for j = 1: length(varargin),
    names = fieldnames(varargin{j});
    for i = 1: length(names)
        if (strcmp(names{i},'PDD'));
            % Normalize dose to the calibration depth, calDepth.
            calbPoint = find(abs(varargin{j}.PDD(:,1) - calbDepth) == min(abs(varargin{j}.PDD(:,1) - calbDepth)));
            % Get the absolute dose
            % Scaled by the output factor.
            if (length(calbPoint) ==1) 
                varargin{j}.PDD(:,2) = varargin{j}.outputFactor * varargin{j}.PDD(:,2) * calbDose ...
                    /varargin{j}.PDD(calbPoint,2);
            else
                varargin{j}.PDD(:,2) = varargin{j}.outputFactor * varargin{j}.PDD(:,2) * calbDose...
                    *2.0/(varargin{j}.PDD(calcPoint(1),2)+varargin{j}.PDD(calcPoint(2),2));
            end
            % plot
            figure; plot(varargin{j}.PDD(:,1), varargin{j}.PDD(:,2))
            break;
        end
    end
    
    for i = 1: length(names)
        if (strcmp(names{i},'PDD')); break;
        else
            field = varargin{j}.(['profile', num2str(i)]);
            depth = field.depth;
            % If there's no exact match of the depth under ad
            depthPoint = find(abs(varargin{j}.PDD(:,1) - depth) == min(abs(varargin{j}.PDD(:,1) - depth)));
            %midPoint = find(abs(varargin{j}.(['profile', num2str(i)]).profile(midPoint,1) - 0) == min(abs(varargin{j}.(['profile', num2str(i)]).profile(midPoint,1) - 0)));
            midPoint = ((length(varargin{j}.(['profile', num2str(i)]).profile))+1)/2;
            if (length(depthPoint) ==1)            
    varargin{j}.(['profile', num2str(i)]).profile(:,2) = varargin{j}.PDD(depthPoint,2)*...
    (varargin{j}.(['profile', num2str(i)]).profile(:,2)/(varargin{j}.(['profile', num2str(i)]).profile(midPoint,2)));   
            else % length must be 2
                % equally weight the two points
    varargin{j}.(['profile', num2str(i)]).profile(:,2) = (varargin{j}.PDD(depthPoint(1),2)+varargin{j}.PDD(depthPoint(2),2))*0.5*...
    (varargin{j}.(['profile', num2str(i)]).profile(:,2)/(varargin{j}.(['profile', num2str(i)]).profile(midPoint,2)));
            end           
   
        end
    hold on; plot(varargin{j}.(['profile', num2str(i)]).profile(:,1), varargin{j}.(['profile', num2str(i)]).profile(:,2))
    
    end

    % Add legend and title to the figure.
    string{1} = 'PDD';
    for i = 1: length(names)
        try
            string{i+1} = [num2str( varargin{j}.(['profile', num2str(i)]).depth ), 'cm'];
        catch
            break
        end
    end
    legend(string);
    title(['FS = ' num2str(varargin{j}.fieldsize), 'cm^2', ' OF = ', num2str(varargin{j}.outputFactor)]);
    
    % Assigin values to output variables
   % nout = max(narg
end

% Assigin values to output variables
nout = nargin - 2;
for i = 1: nout
    varargout{i} = varargin{i};
end

return;
