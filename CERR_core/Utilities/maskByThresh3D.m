function[mask] = maskByThresh3D(img, varargin)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs: 3D image, optional - number of levels (default-2), change from
% 1-5

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[rows,cols,slices] = size(img);
midslice = round(slices*0.5);
mask2D = [];
cslice = midslice;

levels = 2;
if(nargin > 1)
    levels = varargin{1};
end;

thresh = 0;
while(isempty(mask2D) && cslice < slices && cslice > 1)
    try
        thresh = multithresh(img(:,:,cslice), levels);
        mask2D = img(:,:,cslice) > thresh(1);
        thresh = thresh(1);
    catch
        if(cslice+1 > slices-1)
            cslice = max(1, midslice-10);
        else
            cslice = cslice + 1;
        end;
    end;
end;


%I = find(mask2D);
mask = zeros(size(img));
try
    delete(gcp('nocreate'));
    parpool(16);
    parfor s = 1 : slices
        m = bwmorph(bwmorph(bwmorph(single(img(:,:,s)>thresh), 'thicken', 2), 'close'), 'open');
        mask(:,:,s) = m;
    end;
    delete(gcp('nocreate'));
catch
    for s = 1 : slices
        m = bwmorph(bwmorph(bwmorph(single(img(:,:,s)>thresh), 'thicken', 2), 'close'), 'open');
        mask(:,:,s) = m;
    end;
end;
end
