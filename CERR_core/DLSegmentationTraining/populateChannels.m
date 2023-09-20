function scanViewC = populateChannels(scanViewC,channelS)
%populateChannels.m
%
% Returns cell array of images corresponding to channels.
%
% AI 9/4/19

nViews = length(scanViewC);
numChannels = length(channelS);


%% Populate channels

for i = 1:nViews
    
    scanC = scanViewC{i};
    channelC = cell(numChannels,1);
    
    for c = 1:numChannels
        
        slice = channelS(c).slice;
        
        if strfind(slice,'current-')
            
            scan3M = scanC{c};
            idx = strfind(slice,'-');
            shift = str2num(slice(idx+1:end));
            shiftSlice3M = circshift(scan3M,shift,3);
            shiftSlice3M(:,:,1:shift) = repmat(scan3M(:,:,1),[1,1,shift]);
            channelC{c} = shiftSlice3M;
            
        elseif strfind(slice,'current+')
            
            scan3M = scanC{c};
            idx = strfind(slice,'+');
            shift = -str2num(slice(idx+1:end));
            shiftSlice3M = circshift(scan3M,shift,3);
            shiftSlice3M(:,:,end+shift+1:end) = repmat(scan3M(:,:,end),[1,1,-shift]);
            channelC{c} = shiftSlice3M;
            
        elseif strcmpi(slice,'current')
            
            channelC{c} = scanC{c};
            
        else
            
            error(['Slice ', slice, ' not supported.']);
            
        end
        
    end
    scanViewC{i} = channelC;
    
    
end