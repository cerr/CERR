function antsWarpProducts = getAntsWarpProducts(outPrefix)

affineMat = [outPrefix '0GenericAffine.mat'];
warpField = [outPrefix '1Warp.nii.gz'];
inverseWarpField = [outPrefix '1InverseWarp.nii.gz'];
warpedImg = [outPrefix 'Warped.mha'];
inverseWarpedImg = [outPrefix 'InverseWarped.mha'];

if exist(affineMat, 'file')
    antsWarpProducts.Affine = affineMat;
else
    antsWarpProducts.Affine = '';
end
if exist(warpField, 'file')
    antsWarpProducts.Warp = warpField;
else
    antsWarpProducts.Warp = '';
end
if exist (inverseWarpField,'file')
    antsWarpProducts.InverseWarp = inverseWarpField;
else
    antsWarpProducts.InverseWarp = '';
end
if exist(warpedImg, 'file')
    antsWarpProducts.Warped = warpedImg;
else
    antsWarpProducts.Warped = '';
end
if exist(inverseWarpedImg, 'file')
    antsWarpProducts.InverseWarped = inverseWarpedImg;
else
    antsWarpProducts.InverseWarped = '';
end