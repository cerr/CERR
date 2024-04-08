function ans = calc_V_Dlx(doseBinsV, volsHistV, doseCutoff, volType)
% Return volume receiving dose less than "x" Gy

if isstruct(doseCutoff)  %for use with ROE
    temp = doseCutoff;
    volumeType = temp.volumeType.val;
    doseCutoff = temp.x.val;
end

if ~exist('volType','var')
    volumeType = 0;
end

% Add 0 to the beginning to account for the fact that the first bin must
% correspond to the entire volume.
volsHistV = [0 volsHistV(:)'];
cumVolsV = cumsum(volsHistV);
cumVols2V  = cumVolsV(end) - cumVolsV;
ind = find(doseBinsV <= doseCutoff, 1 );

if isempty(ind)
    ans = 0;
else
    ans = cumVols2V(ind);
end

end