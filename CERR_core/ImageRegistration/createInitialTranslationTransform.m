function createInitialTranslationTransform(transformFileName,deltaXYX)
% function createInitialTranslationTransform(transformFileName,deltaXYX)
%
% deltaXYX:vector containing difference between moving and base scan x,y,z
% coords
%
% APA, 8/13/2021

alignC{1,1} = '#Insight Transform File V1.0';
alignC{end+1,1} = '';
alignC{end+1,1} = '#Transform 0';
alignC{end+1,1} = '';
alignC{end+1,1} = 'Transform: TranslationTransform_double_3_3';
alignC{end+1,1} = '';

deltaX = deltaXYX(1) * 10;
deltaY = deltaXYX(2) * 10;
deltaZ = deltaXYX(3) * 10;

alignC{end+1,1} = ['Parameters:',' ',num2str(deltaX),' ',num2str(deltaY),' ',num2str(deltaZ)];
alignC{end+1,1} = '';
alignC{end+1,1} = ['FixedParameters:'];
cell2file(alignC,transformFileName);