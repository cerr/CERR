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
        for n = 1:length(scanC)
            scan3M = scanC{n};
            scan3M = permute(scan3M,[3,2,1]);
            scanC{n} = scan3M;
        end
        
    case 'sagittal'
        for n = 1:length(scanC)
            scan3M = scanC{n};
            scan3M = permute(scan3M,[3,1,2]);
            scanC{n} = scan3M;
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
        
        nPad = floor(C/2);
        shiftV = nPad:-1:-nPad;
        
        for c = 1:C
            shiftSlice3M = circshift(scan3M,shiftV(c),3);
            if shiftV(c)>0
                shiftSlice3M(:,:,1:shiftV(c)) = repmat(scan3M(:,:,1),[1,1,shiftV(c)]);
            elseif shiftV(c)<0
                shiftSlice3M(:,:,end+shiftV(c)+1:end) = repmat(scan3M(:,:,end),[1,1,-shiftV(c)]);
            end
            scanC{c} = shiftSlice3M;
        end
        
        
    case 'multiscan'
        %Same as input
        
    case 'none'
        %Do nothing
        
end

end