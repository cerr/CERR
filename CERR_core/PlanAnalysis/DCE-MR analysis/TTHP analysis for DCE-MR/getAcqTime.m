function tMinV = getAcqTime(scanS)
% Returns DCE acquisition times
% AI 2/02/16

%Get trigger times
tDelC = arrayfun(@(x) x.scanInfo(1).DICOMHeaders.TriggerTime,scanS,'un',0); %Sorted at import
tDelV = [tDelC{:}];
tDel = tDelV(2)-tDelV(1);

%Convert to minutes
tmsV = (0:numel(tDelV)-1).*tDel;        %In ms
tMinV = tmsV./(1000*60);                %Convert to min


end