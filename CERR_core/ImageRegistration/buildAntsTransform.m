function transformParams = buildAntsTransform(antsWarpProducts,inverseFlag)

if ~exist('inverseFlag','var')
    inverseFlag = 0;
end

% generate transform command
transformParams ='';

if ~inverseFlag
    if ~isempty(antsWarpProducts.Warp)
        if exist(antsWarpProducts.Warp,'file')
            transformParams = [' -t ' antsWarpProducts.Warp ' '];
        else
            error(['Unable to complete transform, warp product missing: ' antsWarpProducts.Warp]);
        end
    end
    if ~isempty(antsWarpProducts.Affine)
        if exist(antsWarpProducts.Affine, 'file')
            transformParams = [transformParams ' -t ' antsWarpProducts.Affine ' '];
        else
            error(['Unable to complete transform, affine product missing: ' antsWarpProducts.Affine]);
        end
    end
    if isempty(transformParams)
        error('ANTs: No transformation products specified');
    end
else
    if ~isempty(antsWarpProducts.InverseWarp)
        if exist(antsWarpProducts.InverseWarp,'file')
            transformParams = [' -t ' antsWarpProducts.InverseWarp ' '];
        else
            error(['Unable to complete transform, warp product missing: ' antsWarpProducts.Warp]);
        end
    end
    if ~isempty(deformS.algorithmParamsS.antsWarpProducts.Affine)
        if exist(deformS.algorithmParamsS.antsWarpProducts.Affine, 'file')
            transformParams = [transformParams ' -t  [ ' antsWarpProducts.Affine ',1] '];
        else
            error(['Unable to complete transform, affine product missing: ' antsWarpProducts.Affine]);
        end
    end
    if isempty(transformParams)
        error('ANTs: No transformation products specified');
    end
end