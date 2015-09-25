%show_dose_temp.m

global planC
indexS = planC{end};

planC{indexS.IM}(1).IMDosimetry.beams = [IMwQIB.beams];

planC{indexS.IM}.IMDosimetry.goals = IMwQIB(1).goals;

planC{indexS.IM}.IMDosimetry.params = IMwQIB(1).params;

planC{indexS.IM}.IMDosimetry.isFresh = 1;

planC{indexS.IM}.IMDosimetry.name = 'Eclipse Leaf Seq';

planC{indexS.IM}.IMDosimetry.solutions = [];

planC{indexS.IM}.IMDosimetry.assocScanUID = planC{indexS.scan}(1).scanUID;

planC{indexS.IM}.IMDosimetry.solutions = [beamletWeightC{:}];

[dose3D] = getIMDose(planC{indexS.IM}(1).IMDosimetry, [beamletWeightC{:}], structNumsV);

showIMDose(dose3D,'QIB reCalc')


