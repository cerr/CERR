function maskOut3M = undoResizeMask(scan3M,label3M,method)
% undoResizeMask.m
% Script to resize images and masks for deep learning.
%
% AI 8/28/19
%--------------------------------------------------------------------------
%INPUTS:
% scan3M       : Cropped scan array
% label3M      : Autosegmented mask
% method       : Supported methods: 'none','pad',
%                'bilinear', 'sinc'
%--------------------------------------------------------------------------

switch(lower(method))
    
    case 'pad'
        xPad = floor((size(scan3M,1) - size(label3M,1))/2);
        yPad = floor((size(scan3M,2) - size(label3M,2))/2);
        
        maskOut3M = label3M(xPad+1:xPad+size(scan3M,1), yPad+1:yPad+size(scan3M,2), : );
        
    case 'bilinear'
        
        maskOut3M = imresize(label3M, size(scan3M), 'bilinear');
        
    case 'sinc'
        
        maskOut3M = imresize(label3M, size(scan3M), 'nearest');
        
    case 'special_self_attention_pad'
        
        
        % x-direction must be <256
        if size(scan3M,1)>256
            diff = size(scan3M,1) - 256;
            maskOut3M = padarray(label3M,[diff,0],0,'post');
        else
            %<256
            if mod(size(scan3M,1),2)==1
                origSiz = size(scan3M,1)-1;
            else
                origSiz = size(scan3M,1);
            end
            xPad = abs(floor((origSiz - size(label3M,1))/2));
            maskOut3M = label3M(xPad+1:xPad+size(scan3M,1),:,:);
%             if mod(size(scan3M,1),2)==1
%                maskOut3M = padarray(maskOut3M,[1,0],0,'post');   
%             end
        end
        
        % y-direction must be <256 and must be even
        if size(scan3M,2)>256
            diff = size(scan3M,2) - 256;
            maskOut3M = padarray(maskOut3M,[0,diff],0,'post');
        else
            %<255
            if mod(size(scan3M,2),2)==1
                origSiz = size(scan3M,2)-1;
            else
                origSiz = size(scan3M,2);
            end
            yPad = floor((origSiz - size(label3M,2))/2);
            maskOut3M = maskOut3M(:,yPad+1:yPad+size(scan3M,2),:);
            if mod(size(scan3M,2),2)==1
               maskOut3M = padarray(maskOut3M,[0,1],0,'post');   
            end
        end
        
        
    case 'none'
        %Skip
        
end


end