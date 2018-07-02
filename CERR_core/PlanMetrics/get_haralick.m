function [haralickFeatures] = get_haralick(dirctn, voxelOffset, cooccurType, quantizedM, numGrLevels, glcmFlagS)
  % Get directional offsets
  offsetsM = getOffsets(dirctn)*voxelOffset;

  % Calculate Cooccurrance
  cooccurM = calcCooccur(quantizedM, offsetsM, numGrLevels, cooccurType);

  if cooccurType==1
    % calculate scalar features
    haralickFeatureCombS = cooccurToScalarFeatures(cooccurM, glcmFlagS);

    % save
    haralickFeatures = struct;
    haralickFeatures.CombS = haralickFeatureCombS;

  elseif cooccurType==2
    % calculate scalar features
    haralickFeatureAllDirS = cooccurToScalarFeatures(cooccurM, glcmFlagS);
    haralickFeatures = struct; 

    featureReduceType = 'avg';
    haralickFeatures.AvgS = reduceDirFeatures(haralickFeatureAllDirS,featureReduceType);

    featureReduceType = 'max';
    haralickFeatures.MaxS = reduceDirFeatures(haralickFeatureAllDirS,featureReduceType);

    featureReduceType = 'min';
    haralickFeatures.MinS = reduceDirFeatures(haralickFeatureAllDirS,featureReduceType);

    featureReduceType = 'std';
    haralickFeatures.StdS = reduceDirFeatures(haralickFeatureAllDirS,featureReduceType);

    featureReduceType = 'mad';
    haralickFeatures.MadS = reduceDirFeatures(haralickFeatureAllDirS,featureReduceType);
  end
