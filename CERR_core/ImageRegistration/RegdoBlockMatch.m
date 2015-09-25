function [offset, Nx, Ny] = RegdoBlockMatch(FixedImage, RegisterImage, Nx, Ny)
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

global planC
global stateS

indexS = planC{end};

dim = size(FixedImage);

subFixed = cell(Nx, Ny); subMoving = cell(Nx, Ny);
Lx = ceil(dim(2)/Nx); Ly = ceil(dim(1)/Ny);

offset = cell(Nx, Ny); subOrigin = cell(Nx, Ny);
out = cell(Nx, Ny);

for i = 0 : Nx - 1
    for j = 0 : Ny - 1

        x1 = i*Lx + 1; x2 = min( dim(2), (i+1)*Lx );
        y1 = j*Ly + 1; y2 = min( dim(1), (j+1)*Ly );

        subFixed{j+1, i+1} = FixedImage(y1:y2, x1:x2);
        subMoving{j+1, i+1} = RegisterImage(y1:y2, x1:x2);
        
        %MImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
        centerValue = RegisterImage(y1+ceil(abs(y2-y1)/2), x1+ceil(abs(x2-x1)/2));
        [n,x] = hist(double(RegisterImage(:)), 40);
        ind = find(x>=centerValue, 1, 'first');
        if ind>3


            %             switch get(handles.BMMetric,'Value')
            %                 case 1
            %
            %                     [out{j+1, i+1}, rotation, os] = MeanSquare2D(int16(subFixed{j+1, i+1}), [0 0 0], [1 1 1], ...
            %                                                                int16(subMoving{j+1, i+1}), [0 0 0], [1 1 1], ...
            %                                                                0.01, 4, 200);
            %                 case 2
            try
                [out{j+1, i+1}, rotation, os] = NormalizedCorrelation2D(int16(subFixed{j+1, i+1}), [0 0 0], [1 1 1], ...
                    int16(subMoving{j+1, i+1}), [0 0 0], [1 1 1], ...
                    0.01, 4, 200);
            catch
                [out{j+1, i+1}, rotation, os] = MeanSquare2D_64(int16(subFixed{j+1, i+1}), [0 0 0], [1 1 1], ...
                    int16(subMoving{j+1, i+1}), [0 0 0], [1 1 1], ...
                    0.01, 4, 200);
            end
            %             end

            os(2) = -os(2);
            offset{j+1, i+1} = os;
            subOrigin{j+1, i+1} = [(x2+x1)/2 (y2+y1)/2];
        else
            offset{j+1, i+1} = [0 0];
        end
    end

end


end

