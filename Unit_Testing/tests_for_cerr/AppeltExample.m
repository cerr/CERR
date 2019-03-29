function AppeltExample(planC,protocolS,model)

%Get list of structures
indexS = planC{end};
structListC = {planC{indexS.structures}.structureName};
origPlan = 1;

%a. 34.4Gy in 35 frx, no clinical risk factors
testDose = 34.4;
model1 = model;
nFrxIn = protocolS.numFractions;
structure = model1.parameters.structures;
strId = find(strcmp(structListC,structure));
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model1,nFrxIn,testD);
calcNTCP = feval(model1.function,model1.parameters,correctedDose,testV);
% Compare expected and calculated NTCP
assertTOL = 1e-5;
expectedNTCP = 0.5;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);
%Delete test dose
planC{indexS.dose}(end) = [];

%b. 37.8547Gy in 35 frx, current smoker
testDose = 37.8547;
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
nFrxIn = protocolS.numFractions;
model2 = model;
model2.parameters.currentSmoker.val = 1;
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model1,nFrxIn,testD);
calcNTCP = feval(model2.function,model2.parameters,correctedDose,testV);
% Compare expected and calculated NTCP
assertTOL = 1e-5;
expectedNTCP = 0.5;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);
%Delete test dose
planC{indexS.dose}(end) = [];

%c. 31.9303Gy in 35 frx, current smoker with pulmonary comorbidity
testDose = 31.9303;
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
nFrxIn = protocolS.numFractions;
model3 = model;
model3.parameters.currentSmoker.val = 1;
model3.parameters.pulmonaryComorbidity.val = 1;
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model1,nFrxIn,testD);
calcNTCP = feval(model3.function,model3.parameters,correctedDose,testV);
% Compare expected and calculated NTCP
assertTOL = 1e-5;
expectedNTCP = 0.5;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);



% -- Sub-functions -- %

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