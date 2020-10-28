function transformParams = buildAntsTransform(antsWarpProducts)

% generate transform command
transformParams ='';
if ~isempty(antsWarpProducts.Warp)
    if exist(antsWarpProducts.Warp,'file')
        transformParams = [' -t ' antsWarpProducts.Warp ' '];
    else
        error(['Unable to complete transform, warp product missing: ' antsWarpProducts.Warp]);
    end
end
if ~isempty(deformS.algorithmParamsS.antsWarpProducts.Affine)
    if exist(deformS.algorithmParamsS.antsWarpProducts.Affine, 'file')
        transformParams = [transformParams ' -t ' antsWarpProducts.Affine ' '];
    else
        error(['Unable to complete transform, affine product missing: ' antsWarpProducts.Affine]);
    end
end
if isempty(transformParams)
    error('ANTs: No transformation products specified');
end