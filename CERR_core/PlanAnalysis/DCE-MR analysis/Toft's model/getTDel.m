function tDel = getTDel(planC)

 indexS = planC{end};
 tDelC = arrayfun(@(x) x.scanInfo(1).DICOMHeaders.TriggerTime,planC{indexS.scan},'un',0);
 nonZeroTDelV = [tDelC{:}]>0;
 n = find(nonZeroTDelV,1,'first');
 tDel = tDelC{n};


end