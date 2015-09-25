% Create new IM
newIndex = createNewIM();

% Compute dose for a beam
gantryAngle = 70;
isoCenter.x = 0;
isoCenter.y = -55;
isoCenter.z = -115;
newIndex = 2;
planC = batchCalcDose(newIndex,gantryAngle,isoCenter);
