%% calculation of RMS error
%After putting breakpoint in DPMpcOneBeam_aavc line 284, run the following code:
[xGrid,yGrid,weightMap] = plotIntensityMap(whichBeam,planC);
wtAtPB = [];
for i=1:length(xPosV)
    wtAtPB(i) = interp2(xGrid,yGrid,weightMap,xPosV(i)/10,yPosV(i)/10,'nearest',0);
end
MUweight = sum(planC{indexS.IM}(end).IMDosimetry.LeafSeq.MU{whichBeam});
disp('RMS ERROR:')
disp(sqrt(sum((wtAtPB-w_field*MUweight).^2)/length(w_field))/max(w_field*MUweight))

disp(sqrt(sum((wtAtPB-w_field*MUweight).^2)/length(w_field))/max(w_field*MUweight))

indKeep = find(wtAtPB>max(wtAtPB)*0.1);
x = wtAtPB(indKeep);
y = w_field(indKeep)*MUweight;
sqrt(1/length(x)*sum(((x-y)./x).^2))


%% Calculate RMS error for dose
baseIndex = 5;
newIndex = 6;
indKeep = find(planC{indexS.dose}(baseIndex).doseArray>max(planC{indexS.dose}(baseIndex).doseArray(:))*0.5);
x = planC{indexS.dose}(baseIndex).doseArray(indKeep);
y = planC{indexS.dose}(newIndex).doseArray(indKeep);
sqrt(1/length(x)*sum(((x-y)./x).^2))



%% Scale beamletWeights
% for i=1:length(planC{indexS.IM}(end).IMDosimetry.beams)
%     for j=1:size(planC{indexS.IM}(end).IMDosimetry.beams(i).beamlets,1)
%         for k=1:size(planC{indexS.IM}(end).IMDosimetry.beams(i).beamlets,2)
%             planC{indexS.IM}(end).IMDosimetry.beams(i).beamlets(j,k).maxInfluenceVal = planC{indexS.IM}(end).IMDosimetry.beams(i).beamlets(j,k).maxInfluenceVal * 11.2/23.668;
%         end
%     end
% end
