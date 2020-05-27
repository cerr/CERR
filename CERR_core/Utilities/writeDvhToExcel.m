function writeDvhToExcel(xlSaveFile,filePathC,dvhC,strC)
% function writeDvhToExcel(xlSaveFile,filePathC,dvhC,strC)
%
% Function to write DVHs for a cohort to Excel file
%
% APA, 5/27/2020

[~,namC] = cellfun(@fileparts,filePathC,'un',0);
for iDvh = 1:size(dvhC,2)
    dvhM = [dvhC{:,iDvh}];
    doseHistV = unique(dvhM(1,:));
    dvhM = zeros(length(namC),length(doseHistV));
    doseHistC{iDvh} = doseHistV;
    for iFile = 1:size(dvhC,1)
        if ~isempty(dvhC{iFile,iDvh})
            indMin = findnearest(doseHistV,min(dvhC{iFile,iDvh}(1,:)));
            indMax = findnearest(doseHistV,max(dvhC{iFile,iDvh}(1,:)));
            dvhM(iFile,indMin:indMax) = dvhC{iFile,iDvh}(2,:);
        end
    end
    dvhToWriteC{iDvh} = dvhM;
end

for indStr = 1:length(strC)
    xlswrite(xlSaveFile,namC',strC{indStr},['A2:A',num2str(length(namC)+1)])
    colEnd = xlsColNum2Str(length(doseHistC{indStr})+1);
    xlswrite(xlSaveFile,doseHistC{indStr},strC{indStr},...
        ['B1:',colEnd{1},'1'])
    colEnd = xlsColNum2Str(size(dvhToWriteC{indStr},2)+1);
    xlswrite(xlSaveFile,dvhToWriteC{indStr},strC{indStr},...
        ['B2:',colEnd{1},num2str(size(dvhToWriteC{indStr},1)+1)])
end
