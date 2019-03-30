function WijsmanExample(planC,protocolS,model)

%Get list of structures
indexS = planC{end};
structListC = {planC{indexS.structures}.structureName};
origPlan = 1;

%a. 54.8547Gy in 2Gy/frx, male patient with stage I/II
testDose = 54.8547;
nFrxIn = testDose/2;
model1 = model;
model1.parameters.gender.val = 0;
model1.parameters.tumorStage.val = 0;
structS = model1.parameters.structures;
structure = fieldnames(structS);
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

%b. 44.5641Gy in 2Gy/frx, female patient with stage I/II
testDose = 44.5641;
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
nFrxIn = testDose/2;
model2 = model;
model2.parameters.gender.val = 1;
model2.parameters.tumorStage.val = 0;
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model1,nFrxIn,testD);
calcNTCP = feval(model2.function,model2.parameters,correctedDose,testV);
% Compare expected and calculated NTCP
assertTOL = 1e-5;
expectedNTCP = 0.5;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);
%Delete test dose
planC{indexS.dose}(end) = [];

%c. 46.3590Gy in 35 frx, male patient with stage III/IV
testDose = 46.3590;
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
nFrxIn = protocolS.numFractions;
model3 = model;
model3.parameters.gender.val = 0;
model3.parameters.tumorStage.val = 1;
model3.stdNumFractions = 35;
model3.correctionType = 'nfrx';
[testD, testV] = getDVH(strId,origPlan+1,planC);
correctedDose = frxCorrect(model3,nFrxIn,testD);
calcNTCP = feval(model3.function,model3.parameters,correctedDose,testV);
% Compare expected and calculated NTCP
assertTOL = 1e-5;
expectedNTCP = 0.5;
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);
%Delete test dose
planC{indexS.dose}(end) = [];

%d. 21.1928Gy in 35 frx, male patient with stage III/IV
testDose = 21.1928;
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
model4 = model;
model4.parameters.gender.val = 0;
model4.parameters.tumorStage.val = 1;
model4.stdNumFractions = 35;
model4.correctionType = 'nfrx';
[testD, testV] = getDVH(strId,origPlan+1,planC);
calcNTCP = feval(model4.function,model4.parameters,testD,testV);
% Compare expected and calculated NTCP
assertTOL = 1e-5;
expectedNTCP = 0.05;
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