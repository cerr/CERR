function surfDice = calcSurfaceDice(gtStrName,predStrName,tol_cm,planC)
%surfDice = calcSurfaceDice(gtStrName,predStrName,tol,mode,planC);
%Compute surface dice between 2 structures in 2D/3D at specified tolerance
%-------------------------------------------------------------------------
%INPUTS
%gtStrName   : Ground-truth structure name
%predStrName : Auto-generated structure name
%tol_cm      : Tolerance (cm)
%planC
%-------------------------------------------------------------------------
% AI 10/08/2021

%% Get structure masks
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};

gtStrNum = getMatchingIndex(gtStrName,strC,'exact');
gtMask3M = getStrMask(gtStrNum,planC);

predStrNum = getMatchingIndex(predStrName,strC,'exact');
predMask3M = getStrMask(predStrNum,planC);
    
%% Get voxel spacing 
scanNumV = getStructureAssociatedScan([gtStrNum,predStrNum],planC);
assert(isequal(scanNumV(1),scanNumV(2)));
voxSizV = getScanXYZSpacing(scanNumV(1),planC);
voxSizV = voxSizV*10; %Convert to mm

tol_mm = tol_cm*10;   %Convert to mm'

%% Add module to Python search path
P = py.sys.path;
currDir = pwd;
CERRpath = getCERRPath;
sepIdxV = strfind(CERRpath,filesep);
pkgDir = fullfile(CERRpath(1:sepIdxV(end-1)-1),'Python_packages',...
     'surface-distance');
cd(pkgDir)
pyModule = 'get_surf_dist3d';
pyModPath = fullfile(pkgDir,pyModule);

try
    if count(P,pyModPath) == 0
        insert(P,int32(0),pyModPath);
    end
    py.importlib.import_module(pyModule);
catch e
    cd(currDir)
    error(['Failed to import Python module ',pyModule]);
end
cd(currDir)

%% Compute surface distance
try
    gtMask3M = py.numpy.array(gtMask3M);
    predMask3M = py.numpy.array(predMask3M);
    voxSizV = py.tuple(voxSizV);
    tol_mm = py.float(tol_mm);
    surfDice = py.(pyModule).main(gtMask3M, predMask3M,...
        voxSizV, tol_mm);
catch e
    error('Surface dice calculation failed with message: %s',e.message)
end

end