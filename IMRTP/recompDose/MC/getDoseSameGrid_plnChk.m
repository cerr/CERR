function dose2 = getDoseSameGrid(setDoseNumber1, setDoseNumber2, planC);


dose1 = planC{planC{end}.dose}(setDoseNumber1).doseArray;

[xV yV zV] = getDoseXYZVals(planC{planC{end}.dose}(setDoseNumber1));

[x,y,z] = meshgrid(xV,yV,zV);

[dose2] = getDoseAt(setDoseNumber2, x, y, z);