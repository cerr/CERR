function regQAPlanC(planC, scanNumV, structNumV, viewV, marginS)

% function imgFilesC = regQAPlanC(planC, scanNumV, structNumV, viewV)
% Usage: outputs image file (s) with review of segmented regions between
% coregistered scans
% Inputs
% planC: CERR object
% scanNumV: list of scan numbers of coregistered scans for comparison, 1xN array
% structNumV: list of structure numbers for comparison. A new image will be
%                output for each struct
% viewV: 1x3 array, indicating how many slices in each view you want to see
% marginS: padding zoom around ROI view

if ischar(planC)
    if exist(planC,'file')
        disp('String filename of planC passed.');
        planC = loadPlanC(planC);
    else
        error('planC filename is not valid path');
    end
end

indexS = planC{end};

if ~exist('marginS','var')
    marginS = 20;
end

if nargin < 2
    scanNumV = 1;
end

scanC = {};



structureListC = {planC{indexS.structures}.structureName};

% get structure mask(s), add error handling for no mask
for i = 1:numel(structNumV)
    structIndex = structNumV(i);
    maskC{i} = getStrMask(structIndex,planC);
    structNameC{i} = structureListC{structIndex};
    cmapC{i} = [rand rand rand];
end

viewNameC = {'sagittal','coronal','axial'};

maskNet3M = zeros(size(maskC{1}));

for i = 1:numel(structNumV)
    mask3M = maskC{i};
    maskNet3M = maskNet3M + mask3M;
end

% get scans
Nscan = numel(scanNumV);
for i = 1:Nscan
    scanIndex = scanNumV(i);
    scanC{i} = getScanArray(scanIndex, planC);
    cmean{i} = mean(scanC{i}(find(maskNet3M)));
    cstd{i} = std(scanC{i}(find(maskNet3M)));
end

for k = 1:3 %views x-,y-,z-plane
    if viewV(k)~=0
        N = viewV(k);
        
        if k == 1
            for j = 1:numel(scanC)
                rscanC{j} = permute(scanC{j},[2 3 1]);
                rmaskC{j} = permute(maskC{j},[2 3 1]);
            end
            rmaskNet3M = permute(maskNet3M,[2 3 1]);
        elseif k == 2
            for j = 1:numel(scanC)
                rscanC{j} = permute(scanC{j},[3 1 2]);
                rmaskC{j} = permute(maskC{j},[3 1 2]);
            end
            rmaskNet3M = permute(maskNet3M,[3 1 2]);
        else
            rscanC = scanC;
            rmaskC= maskC;
            rmaskNet3M = maskNet3M;
        end
        
        idx = find(rmaskNet3M);
        [x,y,z] = ind2sub(size(rmaskNet3M),idx);
        minV = [min(x) min(y) min(z)];
        maxV = [max(x) max(y) max(z)];
        
        
        incr = floor((maxV(3) - minV(3))/(N + 1));
        if incr < 1
            sliceV = minV(3):maxV(3);
            N = numel(sliceV);
        else
            sliceV = minV(3) + incr*(1:N);
        end
        %get extents
        r1 = [minV(1) - marginS,maxV(1) + marginS];
        if r1(1) < 0
            r1(1) = 0;
        end
        if r1(2) > size(rmaskNet3M,1)
            r1(2) = size(rmaskNet3M,1);
        end
        r2 = [minV(2) - marginS,maxV(2) + marginS];
        if r2(1) < 0
            r2(1) = 0;
        end
        if r2(2) > size(rmaskNet3M,2)
            r2(2) = size(rmaskNet3M,2);
        end
        
        if N > 5
            ha = [];
            for o = 1:floor(N/5)
                figure;
                ha0 = tight_subplot(5,Nscan,[.01 .03],[.1 .01],[.01 .01]);
                ha = [ha; ha0];
            end
            figure;
            ha0 = tight_subplot(mod(N,5),Nscan,[.01 .03],[.1 .01],[.01 .01]);
            ha = [ha; ha0];
        else
            figure;
            ha = tight_subplot(N,Nscan,[.01 .03],[.1 .01],[.01 .01]);
        end
        
        for n = 1:N
            
            for j = 1:Nscan
                rscan3M = rscanC{j};
                slice2M = rscan3M(r1(1):r1(2),r2(1):r2(2),sliceV(n));
                rmaskNet2M = rmaskNet3M(r1(1):r1(2),r2(1):r2(2),sliceV(n));
                
%                 cmean = mean(slice2M(find(rmaskNet2M)));
%                 cstd = std(slice2M(find(rmaskNet2M)));
                
                %                 subplot(N,Nscan,(n-1)*Nscan + j); image       sc(slice2M);
                axes(ha((n-1)*Nscan + j)); imagesc(slice2M);
                axis equal; axis off; colormap(gray); caxis([cmean{j} - cstd{j},cmean{j}+cstd{j}]); hold on;
                
                for z = 1:numel(rmaskC)
                    rmask3M = rmaskC{z};
                    mask2M = rmask3M(r1(1):r1(2),r2(1):r2(2),sliceV(n));
                    [B,~,Nb,~] = bwboundaries(mask2M);
                    for b = 1:Nb
                        bd = B{b};
                        plot(bd(:,2), bd(:,1),'Color',cmapC{z},'LineWidth',2);
                    end
                end                
            end
        end
        
    end
end

