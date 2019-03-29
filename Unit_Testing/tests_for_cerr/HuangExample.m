function HuangExample(planC,protocolS,model)

%Get list of structures
indexS = planC{end};
structListC = {planC{indexS.structures}.structureName};
origPlan = 1;

%a. 29.2318Gy in 15 frx, no clinical risk factors
testDose = 29.2318;
model1 = model;
nFrxIn = 15;
structure = fieldnames(model1.parameters.structures);
structure = structure{1};
strId = find(strcmp(structListC,structure));
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model1,nFrxIn,testD);
assertTOL = 1e-5;

%Compare expected and calculated corrected dose
expectedCorrDose = 32.0023;
assertAlmostEqual(correctedDose,expectedCorrDose,assertTOL);

% Compare expected and calculated NTCP
calcNTCP = feval(model1.function,model1.parameters,correctedDose,testV);
expectedNTCP = 0.63916;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);
%Delete test dose
planC{indexS.dose}(end) = [];


%b. 14.6125Gy in 15 frx, no clinical risk factors
testDose = 14.6125;
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model1,nFrxIn,testD);
assertTOL = 1e-5;

%Compare expected and calculated corrected dose
expectedCorrDose = 15.3618;
assertAlmostEqual(correctedDose,expectedCorrDose,assertTOL);


% Compare expected and calculated NTCP
calcNTCP = feval(model1.function,model1.parameters,correctedDose,testV);
expectedNTCP = 0.36051;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);
%Delete test dose
planC{indexS.dose}(end) = [];

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