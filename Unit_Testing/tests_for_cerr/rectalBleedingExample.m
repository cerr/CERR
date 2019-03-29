function rectalBleedingExample(planC,protocolS,model)

%Get list of structures
indexS = planC{end};
structListC = {planC{indexS.structures}.structureName};
origPlan = 1;

%a. 35Gy in 5 frx
testDose = 35;
model1 = model;
nFrxIn = protocolS.numFractions;
structure = model1.parameters.structures;
strId = find(strcmp(structListC,structure));
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model1,nFrxIn,testD);
% Compare expected and calculated frx-corrected dose
assertTOL = 1e-5;
expectedDose = 70;
assertAlmostEqual(correctedDose,expectedDose,assertTOL);
% Compare expected and calculated NTCP
calcNTCP = feval(model1.function,model1.parameters,correctedDose,testV);
assertTOL = 1e-5;
expectedNTCP = 0.24503;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);
%Delete test dose
planC{indexS.dose}(end) = [];


% --- Sub-functions --- %
    function correctedDose = frxCorrect(modelParS,numFractions,inDose)
        if strcmpi(modelParS.fractionCorrect,'yes')
            switch lower((modelParS.correctionType))
                case 'fsize'
                    
                    %Convert to EQD in std fraction size
                    stdFrxSize = modelParS.stdFractionSize;
                    scaledFrxSizeV = inDose/numFractions;
                    correctedDose = inDose .*(scaledFrxSizeV+modelParS.abRatio)./(stdFrxSize + modelParS.abRatio);
                    
                case 'nfrx'
                    %Convert to standard no. fractions
                    Na = numFractions;
                    Nb = modelParS.stdNumFractions;
                    a = Na;
                    b = Na*Nb*modelParS.abRatio;
                    c = -inDose.*(b + inDose*Nb);
                    correctedDose= (-b + sqrt(b^2 - 4*a*c))/(2*a);
            end
        else
            correctedDose = inDose;
        end
        
    end

    function planC = createDose(scaleFactor,planC)
        indexS = planC{end};
        origDose = 1;
        dA = getDoseArray(origDose, planC);
        dAtest = dA * scaleFactor;
        %Add to planC
        planC{indexS.dose}(origDose+1) = planC{indexS.dose}(origDose);
        %Set new dose UID
        planC{indexS.dose}(origDose+1).doseUID = createUID('DOSE');
        %Rename
        planC{indexS.dose}(origDose+1).fractionGroupID = ['Test dose - rectal bleeding model'];
        %Update doseArray in dose struct.
        planC = setDoseArray(origDose+1, dAtest, planC);
    end


end

