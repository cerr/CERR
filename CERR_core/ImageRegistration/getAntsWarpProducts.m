function antsWarpProducts = getAntsWarpProducts(outPrefix)

affineMat = [outPrefix '0GenericAffine.mat'];
warpField = [outPrefix '1Warp.nii.gz'];
inverseWarpField = [outPrefix '1InverseWarp.nii.gz'];
warpedImgPrefix = [outPrefix 'Warped.*'];
warpedImg = ls(warpedImgPrefix);
inverseWarpedImgPrefix = [outPrefix 'InverseWarped.*'];
inverseWarpedImg = ls(inverseWarpedImgPrefix);

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
if exist(warpedImg(1:end-1), 'file')
    antsWarpProducts.Warped = warpedImg(1:end-1);
else
    antsWarpProducts.Warped = '';
end
if exist(inverseWarpedImg(1:end-1), 'file')
    antsWarpProducts.InverseWarped = inverseWarpedImg(1:end-1);
else
    antsWarpProducts.InverseWarped = '';
end