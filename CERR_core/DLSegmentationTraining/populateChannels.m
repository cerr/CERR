function channelC = populateChannels(scanC,channelS)
%populateChannels.m
%
% Returns cell array of images corresponding to channels.
%
% AI 9/4/19

numChannels = length(channelS);


%% Populate channels
channelC = cell(numChannels,1);

for c = 1:numChannels
    
    slice = channelS(c).slice;
    
    if contains(slice,'current-')
        
        scan3M = scanC{c};
        idx = strfind(slice,'-');
        shift = str2num(slice(idx+1:end));
        shiftSlice3M = circshift(scan3M,shift,3);
        shiftSlice3M(:,:,1:shift) = repmat(scan3M(:,:,1),[1,1,shift]);
        channelC{c} = shiftSlice3M;
        
    elseif contains(slice,'current+')
        
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