function im = RegdoMirrCheckboard(Im1, Im2, numRows, numCols, orientation, metric)
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

      
    [m n p] = size(Im1);
    classname = class(Im1);
    %Im1 = cast(Im1, classname); 
    %Im2 = cast(Im2, classname); 

    m1 = fix(m/numRows); 
    n1 = fix(n/numCols);
    black = zeros(m1, n1, classname);    
    white = ones(m1, n1, classname);
    [ROW,COL] = ndgrid(1:m1,1:n1);
    %indKeepV = ((ROW-m1/2).^2)/(m1/2)^2 + ((COL-n1/2).^2)/(n1/2)^2 <= 1; % circle
    indKeepV = ((ROW-m1/2).^2)/(m1*0.58)^2 + ((COL-n1/2).^2)/(n1*0.58)^2 <= 1; % ellipse
    black(indKeepV) = 1;
    
    black_edge = ((ROW-m1/2).^2)/(m1*0.58)^2 + ((COL-n1/2).^2)/(n1*0.58)^2 > 0.97 & ((ROW-m1/2).^2)/(m1*0.58)^2 + ((COL-n1/2).^2)/(n1*0.58)^2 < 1.03;
    indColStart = min(find(black_edge(1,:)));
    indColStop = max(find(black_edge(1,:)));
    indRowStart = min(find(black_edge(:,1)));
    indRowStop = max(find(black_edge(:,1)));
    black_edge(:,round(size(black_edge,2)/2)) = 1;
    black_edge(1,indColStart:indColStop) = 1;
    black_edge(end,indColStart:indColStop) = 1;
    black_edge(indRowStart:indRowStop,1) = 1;
    black_edge(indRowStart:indRowStop,end) = 1;    
    highlightM = zeros(size(Im1),'single');
    highlightM(1:numRows*m1,1:numCols*n1) = repmat(black_edge,numRows, numCols);
    
%     %tile = [black white; white black];
%     tile = [black black; black black];
%     I = repmat(tile, [ceil(m/(2*m1)) ceil(n/(2*n1)) p]);
     
    %I = logical(size(Im1));
    I = ones(size(Im1),'single');
    I(1:numRows*m1,1:numCols*n1) = repmat(black,numRows, numCols);
        
    % Scale Im1 and Im2 between 0 and 1
    minIm1 = min(Im1(:));
    maxIm1 = max(Im1(:));
    Im1 = (Im1-minIm1)/(maxIm1-minIm1);
    minIm2 = min(Im2(:));
    maxIm2 = max(Im2(:));
    Im2 = (Im2-minIm2)/(maxIm2-minIm2);

    CA_Image = min(Im1(:))*I;
    Imov = I*0;
    ctEdge = I*0;
    
    
    for rowNum = 1:numRows
        
        for colNum = 1:numCols            
            
            indJv = 1:floor(n1/2);
            j1Start = (colNum-1)*n1 + n1 - floor(n1/2);
            j2Start = (colNum-1)*n1;
            jEnd   = colNum*n1;
            
            iStart = (rowNum-1)*m1+1;
            iEnd   = rowNum*m1;
            
            j1V = j1Start+indJv;
            j2V = j2Start+indJv;
            iV = iStart:iEnd;
            
            Iblock = CA_Image(iV,(j2Start+1):jEnd);            
            %IedgeBlock = CA_Image(iV,(j2Start+1):jEnd);
            
            %IblockMov = Imov(iV,1:floor(n1/2)); % for painting half block
            IblockMov = Imov(iV,1:n1); % for painting full block
           
            if strcmpi(orientation,'Left Mirror')
                Iblock(1:m1,1:floor(n1/2)) = Im1(iV,j2V);
                Iblock(1:m1,(n1-floor(n1/2)+1):n1) = flipdim(Im2(iV,j2V),2);
                %Im_edge = edge(Im1(iV,j2V),'canny');
                %IedgeBlock(1:m1,1:floor(n1/2)) = Im_edge;
                %Im_edge = edge(flipdim(Im2(iV,j2V),2),'canny');
                %IedgeBlock(1:m1,(n1-floor(n1/2)+1):n1) = Im_edge;
            else
                Iblock(1:m1,(n1-floor(n1/2)+1):n1) = Im1(iV,j1V);
                Iblock(1:m1,1:floor(n1/2)) = flipdim(Im2(iV,j1V),2);
                %Im_edge = edge(Im1(iV,j1V),'canny');
                %IedgeBlock(1:m1,(n1-floor(n1/2)+1):n1) = Im_edge;
                %Im_edge = edge(flipdim(Im2(iV,j1V),2),'canny');
                %IedgeBlock(1:m1,1:floor(n1/2)) = Im_edge;
            end
            
            
            CA_Image(iV,(j2Start+1):jEnd) = Iblock;
            %ctEdge(iV,(j2Start+1):jEnd) = IedgeBlock;
            
            % Calculate registration accuracy within each block
            %IblockMov(1:m1,1:floor(n1/2)) = 1; % for painting half block
            %IblockMov(1:m1,1:n1) = 1;  % for painting full block
            % MSE
            blockImage1M = Im1(iV,j1V);
            blockImage2M = Im2(iV,j1V);
            if metric == 2 % MSE
                blockMetric = sum((blockImage1M(:) - blockImage2M(:)).^2);
            elseif metric == 1 % MI
                minBlock1 = min(blockImage1M(:));
                minBlock2 = min(blockImage2M(:));
                blockImage1M = (blockImage1M-minBlock1)/(max(blockImage1M(:))+1e3*eps - minBlock1)*255;
                blockImage2M = (blockImage2M-minBlock2)/(max(blockImage2M(:))+1e3*eps - minBlock2)*255;
                blockMetric = get_mi(blockImage1M,blockImage2M,256);
            end
            IblockMov(1:m1,1:n1) = blockMetric;
            Imov(iV,(j2Start+1):j2Start+size(IblockMov,2)) = IblockMov;            
            
        end
        
    end
    
      
    CA_Image(I==0) = min(Im1(:));
    Imov = Imov.*I;
    

%     % Apply different color for moving half of the image

    ctSize = size(CA_Image);

    colorCT = CERRColorMap('gray256');
    %CTLow = min(CA_Image(:));
    %CTHigh = max(CA_Image(:));
    %ctScaled = (CA_Image - CTLow) / ((CTHigh - CTLow) / size(colorCT,1)) + 1;
    %ctClip = uint32(ctScaled);
    ctScaled = uint32(CA_Image * (size(colorCT,1)-1)+1);
    colorCT(end+1,:) = colorCT(end,:);
    %ctClip = CA_Image;
    CTBackground3M = reshape(colorCT(ctScaled(1:ctSize(1),1:ctSize(2)),1:3),ctSize(1),ctSize(2),3);
    
    % Create Edge image
    colorEdge = CERRColorMap('yellow');
    %ctEdge = canny(CA_Image,[],[]);
    ctEdge = edge(CA_Image,'canny');
%     minEdge = min(ctEdge(:));
%     maxEdge = max(ctEdge(:));
%     ctEdgeScaled = (ctEdge - minEdge) / ((maxEdge - minEdge) / size(colorEdge,1)) + 1;
%     ctEdge = uint32(ctEdgeScaled);
    edgeScaled = uint32(ctEdge * (size(colorEdge,1)-1)+1);
    colorEdge(end+1,:) = colorEdge(end,:);
    CTEdge3M = reshape(colorEdge(edgeScaled(1:ctSize(1),1:ctSize(2)),1:3),ctSize(1),ctSize(2),3);
    
    % Create highlight edge
    colorEdge = CERRColorMap('green');
    highlightEdgeScaled = uint32(highlightM * (size(colorEdge,1)-1)+1);
    colorEdge(end+1,:) = colorEdge(end,:);
    highlightEdge3M = reshape(colorEdge(highlightEdgeScaled(1:ctSize(1),1:ctSize(2)),1:3),ctSize(1),ctSize(2),3);
    
    colorMSE = CERRColorMap('starinterp');    
    minBlocks = min(Imov(:));
    maxBlocks = max(Imov(:));
    Imov = (Imov - minBlocks)/((maxBlocks-minBlocks)/size(colorMSE,1)) + 1;
    mseClip = uint32(Imov);
    colorMSE(end+1,:) = colorMSE(end,:);
    mse3M = reshape(colorMSE(mseClip(1:ctSize(1),1:ctSize(2)),1:3),ctSize(1),ctSize(2),3);
        
    %CA_Image = CTBackground3M*0.8 + mse3M*0.2;
    CA_Image = CTBackground3M*0.5 + 0.35*CTEdge3M + mse3M*0.15;
    %CA_Image = CTBackground3M*0.6 + highlightEdge3M*0.4;
    
    I3M(:,:,1) = I;
    I3M(:,:,2) = I;
    I3M(:,:,3) = I;
    CA_Image(I3M==0) = NaN;
    
%     CA_Image(:,:,2) = CA_Image(:,:,1);
%     CA_Image(:,:,3) = CA_Image(:,:,1);
%     
%     CA_Image = (CA_Image - min(CA_Image(:))) / (max(CA_Image(:))-min(CA_Image(:)));
%     %CA_Image(:,:,2) = CA_Image(:,:,2) + Imov*0.136;
%     %CA_Image(:,:,2) = CA_Image(:,:,2) + Imov;
%     %CA_Image(:,:,3) = CA_Image(:,:,3) + Imov*0.136;
%     CA_Image(:,:,3) = CA_Image(:,:,3) + Imov;
%     CA_Image = min(CA_Image,1);
%     CA_Image = [Imov(:) CA_Image(:)] * [0.5 0.5]';
% %     % Apply different color for moving half of the image ends
    
    
%     c1 = I(1:m, 1:n, 1:p);
%     c2 = (1-c1);
% 
%     CA_Image = c1.*(Im2) + c2.*(Im1);
%     CA_Image(:,:,2) = CA_Image(:,:,1);
%     CA_Image(:,:,3) = CA_Image(:,:,1);
%     CA_Image = single(CA_Image);
%     
%     c1 = single(c1);
%     CA_Image = (CA_Image - min(CA_Image(:))) / (max(CA_Image(:))-min(CA_Image(:)));
%     CA_Image(:,:,2) = CA_Image(:,:,2) + c1*0.136;
%     CA_Image(:,:,3) = CA_Image(:,:,3) + c1*0.136;
%     CA_Image = min(CA_Image,1);
%     
    
    im = CA_Image;
    
end