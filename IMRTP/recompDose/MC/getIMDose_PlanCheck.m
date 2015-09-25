function [dose3D] = getIMDose(IM, PBWeightsV, structsV, MCflag)
%Create 3D dose matrix from PB weigths (PBWeightsV) and
%a list of structures to have dose computed to (structsV).
%JOD, 14 Nov 03.
%JRA, 27 Feb 04.

global planC
indexS = planC{end};

if exist('MCflag') & strcmpi(MCflag, 'MC')
    beamlets = IM.beamletsMonteCarlo;            
else
    beamlets = IM.beamlets;
    MCflag = '';
end

dose3D = [];

%If PBWeights is empty, go to default: evenly weighted
if isempty(PBWeightsV)
    numPBs = size(beamlets,2);
    PBWeightsV = ones(numPBs,1);
end

%Make sure PB is a column vector, for matrix multiplication.
PBWSize = size(PBWeightsV);
if PBWSize(1) == 1;
    PBWeightsV = PBWeightsV';    
end

%Shuffle structs to always add highest resolution
%structures first, and don't overwrite - this way hi-res structures are never
%overwritten by low-res structures:
ratesV = [];
for i = 1 : length(structsV)
    ratesV = [ratesV, beamlets(structsV(i),1).sampleRate];
end
[ratesV, iV] = sort(ratesV);
structsV = structsV(iV)

%For each struct...
for structNum = structsV
    if isempty(dose3D)
        s = getUniformizedSize(planC);
        dose3D = zeros(s);
    end
   
    doseInStruct = zeros(s);
    
    sampleRate = beamlets(structNum,1).sampleRate;
    
    disp('Getting influence matrix...');
    doseV = getMCDose(IM, PBWeightsV, structNum);
%     [inflM] = getGlobalInfluenceM(IM, structNum, MCflag);
%     doseV = inflM * PBWeightsV;
    doseInStruct(find(doseV)) = doseV(find(doseV));
     
    %If sub-sampled, use 3-D interpolation to fill out dose.
    if sampleRate ~= 1
        
        disp('Inflating downsampled dose distribution...')
        if rem(log2(sampleRate),1) ~= 0
            error('Sample factor must (currently) be a power of 2.')
        end
        
        %Get interpolation coords.
        maskSample3D = getDown3Mask(dose3D, sampleRate, 1);         
        maskStruct3D = getUniformStr(structNum);
        [rInterpV, cInterpV, sInterpV] = find3d(maskStruct3D & ~maskSample3D);        

        %Now do 3-D interpolation:
        sizeV = size(dose3D);
        
        doseInterp = doseInStruct;
        whereV = find(maskSample3D(:));
        clear maskSample3D;
        doseInterp = doseInterp(whereV);
        doseInterp = reshape(doseInterp,[sizeV(1)/2^log2(sampleRate),sizeV(2)/2^log2(sampleRate),sizeV(3)]);
                       
        rDownV = (rInterpV + 2^log2(sampleRate) - 1)/2^log2(sampleRate);
        cDownV = (cInterpV + 2^log2(sampleRate) - 1)/2^log2(sampleRate);
        
        fillsV = matInterp3(rDownV,cDownV,sInterpV,doseInterp);
        clear doseInterp;
        
        ind3V = sub2ind(sizeV,rInterpV,cInterpV,sInterpV);  %index for interpolated values
        doseInStruct(ind3V) = fillsV;
        doseInStruct(~maskStruct3D) = 0;
        clear maskStruct3D;
        disp('Finished inflating.')
    end
    
    for i = 1:size((dose3D),3),     
        tmp = [dose3D(:,:,i)==0];
        tmp1 = doseInStruct(:,:,i) .* tmp;  %voxel over-adding avoided
        tmp2 = dose3D(:,:,i) + tmp1;
        dose3D(:,:,i) = tmp2;
    end
    clear doseInStruct;
    % dose3D = dose3D + doseInStruct.* [dose3D==0];
end