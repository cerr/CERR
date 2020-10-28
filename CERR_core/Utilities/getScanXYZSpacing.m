function voxSizV = getScanXYZSpacing(scanNum,planC)

indexS = planC{end};

scanS = planC{indexS.scan}(scanNum);
[xV,yV,zV] = getScanXYZVals(scanS);
PixelSpacingX = median(abs(diff(xV)));
PixelSpacingY = median(abs(diff(yV)));
PixelSpacingZ = median(abs(diff(zV)));
voxSizV = [PixelSpacingX, PixelSpacingY, PixelSpacingZ];

end