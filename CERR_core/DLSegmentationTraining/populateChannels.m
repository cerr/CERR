function scanC = populateChannels(scanC,channelS)
%populateChannels.m
%
% Returns cell array of transformed images corresponding to channels.
%
% AI 9/4/19

C = channelS.number;

%% Transform images as required
imgType = channelS.imageType;
switch imgType
    
    case 'coronal'
        for c = 1:C
            scan3M = scanC{c};
            scan3M = permute(scan3M,[3,2,1]);
            scanC{c} = scan3M;
        end
        
    case 'sagittal'
        for c = 1:C
            scan3M = scanC{c};
            scan3M = permute(scan3M,[3,1,2]);
            scanC{c} = scan3M;
        end
        
    case 'original'
        %Do nothing
end

%% Populate channels
method = channelS.append.method;

switch method
    
    case 'repeat'
        
        scan3M = scanC{1};
        for c = 2:C
            scanC{c} = scan3M;
        end
        
    case '2.5D'
        
        scan3M = scanC{1};
        prevSlice3M = circshift(scan3M,1,3);
        prevSlice3M(:,:,1) = scan3M(:,:,1);
        nextSlice3M = circshift(scan3M,-1,3);
        nextSlice3M(:,:,end) = scan3M(:,:,end);
        scanC{1} = prevSlice3M;
        scanC{2} = scan3M;
        scanC{3} = nextSlice3M;
        
        
    case 'multiscan'
        %Same as input
        
    case 'none'
        %Do nothing
        
end

end