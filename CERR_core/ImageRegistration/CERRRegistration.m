function CERRRegistration(command, varargin)
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

global planC stateS

indexS = planC{end};

hFig = stateS.handle.CERRSliceViewer;

switch command

    case 'rigid'
        
    case 'deformable'
        switch (varargin{1})
            case 'Deshan'
                prompt={'Enter the method ID:',...
                        'Enter the MultiRes levels:'};
                name='Input for deformable registration function';
                numlines=1;
                defaultanswer={'1','2'};
                answer=inputdlg(prompt,name,numlines,defaultanswer);
                if isempty(answer), return; end;
                
                MImg = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray;
                FImg = planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
                
                rx = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).grid1Units;
                ry = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).grid2Units;
                rz = planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).sliceThickness;
                ratio = [rx,ry,rz];
                
%                 MImg=imdesample3d(MImg,2,1);
%                 FImg=imdesample3d(FImg,2,1);
                MImg=GPReduce2D(MImg,0);
                FImg=GPReduce2D(FImg,0);
                
                [M MPre] = padImage(MImg, 3);
                F = padImage(FImg, 3);

                [mvy,mvx,mvz,im]=multigrid_nogui5(              str2num(answer{1}), ... %method,
                                                                M, ...%Moving Image,
                                                                F, ...%Fixed Image,
                                                                ratio,   ...%ratio,
                                                                str2num(answer{2}));    %steps,
                dimmv = size(MImg);
                mvy = mvy(MPre(1)+(1:dimmv(1)),MPre(2)+(1:dimmv(2)),MPre(3)+(1:dimmv(3)));
                mvx = mvx(MPre(1)+(1:dimmv(1)),MPre(2)+(1:dimmv(2)),MPre(3)+(1:dimmv(3)));
                mvz = mvz(MPre(1)+(1:dimmv(1)),MPre(2)+(1:dimmv(2)),MPre(3)+(1:dimmv(3)));
                im =  im (MPre(1)+(1:dimmv(1)),MPre(2)+(1:dimmv(2)),MPre(3)+(1:dimmv(3)));
                maxv = max(max(M(:)),max(F(:)));
                im = im * maxv;
            end
    
end

imp3D_planC(im);
