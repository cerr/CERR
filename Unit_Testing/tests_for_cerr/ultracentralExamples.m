function ultracentralExamples(planC,protocolS,model)
% Unit tests for NTCP models using ultracentral lung treatment protocols
%
% AI 02/03/21

%Get list of structures
indexS = planC{end};
structListC = {planC{indexS.structures}.structureName};
origPlan = 1;
expectedNTCP = 0.5;
assertTOL = 1e-4;

%% a. Esophagitis grade2+ logistic model
model1 = model{1};
testDose = 51.3609;
structure = fieldnames(model1.parameters.structures);
structure = structure{1};
strId = find(strcmp(structListC,structure));
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
planId = origPlan + 1;
[testDose, testVol] = getDVH(strId,planId,planC);

% Compare expected and calculated NTCP
calcNTCP = feval(model1.function,model1.parameters,testDose,testVol);
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);

%Delete test dose
planC{indexS.dose}(end) = [];

%% b.  Esophagitis grade2+ cox model
model2 = model{2};
testDose = 49.1008;
structure = fieldnames(model2.parameters.structures);
structure = structure{1};
strId = find(strcmp(structListC,structure));
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
planId = origPlan + 1;
[testDose,testVol] = getDVH(strId,planId,planC);

% Compare expected and calculated NTCP
calcNTCP = feval(model2.function,model2.parameters,testDose,testVol);
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);

%Delete test dose
planC{indexS.dose}(end) = [];

%% c. Bronchial stenosis logistic model
model3 = model{3};
testDose = 80.2771;
structure = fieldnames(model3.parameters.structures);
structure = structure{1};
strId = find(strcmp(structListC,structure));
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
planId = origPlan + 1;
[testDose, testVol] = getDVH(strId,planId,planC);

% Compare expected and calculated NTCP
calcNTCP = feval(model3.function,model3.parameters,testDose,testVol);
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);

%Delete test dose
planC{indexS.dose}(end) = [];

%% d. Bronchial stenosis cox model
model4 = model{4};
testDose = 69.2936;
structure = fieldnames(model4.parameters.structures);
structure = structure{1};
strId = find(strcmp(structListC,structure));
currentDose = getDVH(strId,origPlan,planC);
scaleFactor = testDose/currentDose;
planC = createDose(scaleFactor,planC);
planId = origPlan + 1;
[testDose, testVol] = getDVH(strId,planId,planC);

% Compare expected and calculated NTCP
calcNTCP = feval(model4.function,model4.parameters,testDose,testVol);
assertAlmostEqual(calcNTCP,expectedNTCP,assertTOL);

%% -- Sub-functions --

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