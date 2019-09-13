function maskOut3M = undoResizeMask(label3M,originImageSizV,rcsM,method)
                                   
% undoResizeMask.m
% Script to resize images and masks for deep learning.
%
% AI 8/28/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M       : Cropped scan array
% label3M      : Autosegmented mask
% method       : Supported methods: 'none','pad2d',
%                'bilinear', 'sinc'
%--------------------------------------------------------------------------
% RKP 9/13/19

switch(lower(method))
    
    case 'pad2d'
        maskOut3M = false(originImageSizV);
        mins = min(rcsM(5));
        maxs = max(rcsM(end));
        iSlc = 0;
        for slcNum = mins:maxs
            iSlc = iSlc + 1;
            rMin = rcsM(iSlc,1);
            rMax = rcsM(iSlc,2);
            cMin = rcsM(iSlc,3);
            cMax = rcsM(iSlc,4);
            maskOut3M(rMin:rMax,cMin:cMax,slcNum) = label3M(:,:,iSlc);            
        end        
        
    case 'bilinear'
        
        maskOut3M = imresize(label3M, size(scan3M), 'bilinear');
        
    case 'sinc'
        
        maskOut3M = imresize(label3M, size(scan3M), 'nearest');   
        
    case 'none'
        maskOut3M = label3M;
        
end


end