function lawsMasksS = getLawsMasks(direction,size)
% function lawsMasksS = getLawsMasks()
%
% direction: '2d', '3d' or 'All'
% size : '3', '5', 'all'
% APA, 10/18/2016


if ~exist('direction','var')
    direction = 'all';
end

L3  =  [ 1,  2,   1];
E3  =  [-1,  0,   1];
S3  =  [-1,  2,  -1];

L5   =  [ 1,   4,   6,   4,   1]; % GauSSian: giveS centeR-Weighted LocaL aveRage
E5   =  [-1,  -2,   0,   2,   1]; % GRadient: ReSpondS to RoW oR coLumn Step edgeS
S5   =  [-1,   0,   2,   0,  -1]; % LOG: detectS SpotS
R5   =  [ 1,  -4,   6,  -4,   1]; % GaboR: detectS RippLeS
W5  =   [-1,   2,   0,  -2,   1];


% 2-d (Length 3)
lawsMasksS.L3E3 = L3'*E3;
lawsMasksS.L3S3 = L3'*S3;

lawsMasksS.E3E3 = E3'*E3;
lawsMasksS.E3L3 = E3'*L3;
lawsMasksS.E3S3 = E3'*S3;

lawsMasksS.S3S3 = S3'*S3;
lawsMasksS.S3L3 = S3'*L3;
lawsMasksS.S3e3 = S3'*E3;

% 2-d (Length 5)
lawsMasksS.L5L5 = L5'*L5;
lawsMasksS.L5e5 = L5'*E5;
lawsMasksS.L5S5 = L5'*S5;
lawsMasksS.L5R5 = L5'*R5;
lawsMasksS.L5W5 = L5'*W5;

lawsMasksS.E5E5 = E5'*E5;
lawsMasksS.E5L5 = E5'*L5;
lawsMasksS.E5S5 = E5'*S5;
lawsMasksS.E5R5 = E5'*R5;
lawsMasksS.E5W5 = E5'*W5;

lawsMasksS.S5S5 = S5'*S5;
lawsMasksS.S5L5 = S5'*L5;
lawsMasksS.S5e5 = S5'*E5;
lawsMasksS.S5R5 = S5'*R5;
lawsMasksS.S5W5 = S5'*W5;

lawsMasksS.R5R5 = R5'*R5;
lawsMasksS.R5S5 = R5'*S5;
lawsMasksS.R5L5 = R5'*L5;
lawsMasksS.R5e5 = R5'*E5;
lawsMasksS.R5W5 = R5'*W5;

lawsMasksS.W5W5 = W5'*W5;
lawsMasksS.W5R5 = W5'*R5;
lawsMasksS.W5S5 = W5'*S5;
lawsMasksS.W5L5 = W5'*L5;
lawsMasksS.W5e5 = W5'*E5;

% 3-d (Length 3)
lawsMasksS.E3E3E3 = get3dLawsText(E3,E3,E3);
lawsMasksS.E3E3L3 = get3dLawsText(E3,E3,L3);
lawsMasksS.E3E3S3 = get3dLawsText(E3,E3,S3);
lawsMasksS.E3L3E3 = get3dLawsText(E3,L3,E3);
lawsMasksS.E3L3L3 = get3dLawsText(E3,L3,L3);
lawsMasksS.E3L3S3 = get3dLawsText(E3,L3,S3);
lawsMasksS.E3S3E3 = get3dLawsText(E3,S3,E3);
lawsMasksS.E3S3L3 = get3dLawsText(E3,S3,L3);
lawsMasksS.E3S3S3 = get3dLawsText(E3,S3,S3);
lawsMasksS.L3E3E3 = get3dLawsText(L3,E3,E3);
lawsMasksS.L3E3L3 = get3dLawsText(L3,E3,L3);
lawsMasksS.L3E3S3 = get3dLawsText(L3,E3,S3);
lawsMasksS.L3L3E3 = get3dLawsText(L3,L3,E3);
lawsMasksS.L3L3L3 = get3dLawsText(L3,L3,L3);
lawsMasksS.L3L3S3 = get3dLawsText(L3,L3,S3);
lawsMasksS.L3S3E3 = get3dLawsText(L3,S3,E3);
lawsMasksS.L3S3L3 = get3dLawsText(L3,S3,L3);
lawsMasksS.L3S3S3 = get3dLawsText(L3,S3,S3);
lawsMasksS.S3E3E3 = get3dLawsText(S3,E3,E3);
lawsMasksS.S3E3L3 = get3dLawsText(S3,E3,L3);
lawsMasksS.S3E3S3 = get3dLawsText(S3,E3,S3);
lawsMasksS.S3L3E3 = get3dLawsText(S3,L3,E3);
lawsMasksS.S3L3L3 = get3dLawsText(S3,L3,L3);
lawsMasksS.S3L3S3 = get3dLawsText(S3,L3,S3);
lawsMasksS.S3S3E3 = get3dLawsText(S3,S3,E3);
lawsMasksS.S3S3L3 = get3dLawsText(S3,S3,L3);
lawsMasksS.S3S3S3 = get3dLawsText(S3,S3,S3);


% 3-d (Length 5)
lawsMasksS.L5L5L5 = get3dLawsText(L5,L5,L5);
lawsMasksS.L5L5E5 = get3dLawsText(L5,L5,E5);
lawsMasksS.L5L5S5 = get3dLawsText(L5,L5,S5);
lawsMasksS.L5L5R5 = get3dLawsText(L5,L5,R5);
lawsMasksS.L5L5W5 = get3dLawsText(L5,L5,W5);
lawsMasksS.L5E5L5 = get3dLawsText(L5,E5,L5);
lawsMasksS.L5E5E5 = get3dLawsText(L5,E5,E5);
lawsMasksS.L5E5S5 = get3dLawsText(L5,E5,S5);
lawsMasksS.L5E5R5 = get3dLawsText(L5,E5,R5);
lawsMasksS.L5E5W5 = get3dLawsText(L5,E5,W5);
lawsMasksS.L5S5L5 = get3dLawsText(L5,S5,L5);
lawsMasksS.L5S5E5 = get3dLawsText(L5,S5,E5);
lawsMasksS.L5S5S5 = get3dLawsText(L5,S5,S5);
lawsMasksS.L5S5R5 = get3dLawsText(L5,S5,R5);
lawsMasksS.L5S5W5 = get3dLawsText(L5,S5,W5);
lawsMasksS.L5R5L5 = get3dLawsText(L5,R5,L5);
lawsMasksS.L5R5E5 = get3dLawsText(L5,R5,E5);
lawsMasksS.L5R5S5 = get3dLawsText(L5,R5,S5);
lawsMasksS.L5R5R5 = get3dLawsText(L5,R5,R5);
lawsMasksS.L5R5W5 = get3dLawsText(L5,R5,W5);
lawsMasksS.L5W5L5 = get3dLawsText(L5,W5,L5);
lawsMasksS.L5W5E5 = get3dLawsText(L5,W5,E5);
lawsMasksS.L5W5S5 = get3dLawsText(L5,W5,S5);
lawsMasksS.L5W5R5 = get3dLawsText(L5,W5,R5);
lawsMasksS.L5W5W5 = get3dLawsText(L5,W5,W5);
lawsMasksS.E5L5L5 = get3dLawsText(E5,L5,L5);
lawsMasksS.E5L5E5 = get3dLawsText(E5,L5,E5);
lawsMasksS.E5L5S5 = get3dLawsText(E5,L5,S5);
lawsMasksS.E5L5R5 = get3dLawsText(E5,L5,R5);
lawsMasksS.E5L5W5 = get3dLawsText(E5,L5,W5);
lawsMasksS.E5E5L5 = get3dLawsText(E5,E5,L5);
lawsMasksS.E5E5E5 = get3dLawsText(E5,E5,E5);
lawsMasksS.E5E5S5 = get3dLawsText(E5,E5,S5);
lawsMasksS.E5E5R5 = get3dLawsText(E5,E5,R5);
lawsMasksS.E5E5W5 = get3dLawsText(E5,E5,W5);
lawsMasksS.E5S5L5 = get3dLawsText(E5,S5,L5);
lawsMasksS.E5S5E5 = get3dLawsText(E5,S5,E5);
lawsMasksS.E5S5S5 = get3dLawsText(E5,S5,S5);
lawsMasksS.E5S5R5 = get3dLawsText(E5,S5,R5);
lawsMasksS.E5S5W5 = get3dLawsText(E5,S5,W5);
lawsMasksS.E5R5L5 = get3dLawsText(E5,R5,L5);
lawsMasksS.E5R5E5 = get3dLawsText(E5,R5,E5);
lawsMasksS.E5R5S5 = get3dLawsText(E5,R5,S5);
lawsMasksS.E5R5R5 = get3dLawsText(E5,R5,R5);
lawsMasksS.E5R5W5 = get3dLawsText(E5,R5,W5);
lawsMasksS.E5W5L5 = get3dLawsText(E5,W5,L5);
lawsMasksS.E5W5E5 = get3dLawsText(E5,W5,E5);
lawsMasksS.E5W5S5 = get3dLawsText(E5,W5,S5);
lawsMasksS.E5W5R5 = get3dLawsText(E5,W5,R5);
lawsMasksS.E5W5W5 = get3dLawsText(E5,W5,W5);
lawsMasksS.S5L5L5 = get3dLawsText(S5,L5,L5);
lawsMasksS.S5L5E5 = get3dLawsText(S5,L5,E5);
lawsMasksS.S5L5S5 = get3dLawsText(S5,L5,S5);
lawsMasksS.S5L5R5 = get3dLawsText(S5,L5,R5);
lawsMasksS.S5L5W5 = get3dLawsText(S5,L5,W5);
lawsMasksS.S5E5L5 = get3dLawsText(S5,E5,L5);
lawsMasksS.S5E5E5 = get3dLawsText(S5,E5,E5);
lawsMasksS.S5E5S5 = get3dLawsText(S5,E5,S5);
lawsMasksS.S5E5R5 = get3dLawsText(S5,E5,R5);
lawsMasksS.S5E5W5 = get3dLawsText(S5,E5,W5);
lawsMasksS.S5S5L5 = get3dLawsText(S5,S5,L5);
lawsMasksS.S5S5E5 = get3dLawsText(S5,S5,E5);
lawsMasksS.S5S5S5 = get3dLawsText(S5,S5,S5);
lawsMasksS.S5S5R5 = get3dLawsText(S5,S5,R5);
lawsMasksS.S5S5W5 = get3dLawsText(S5,S5,W5);
lawsMasksS.S5R5L5 = get3dLawsText(S5,R5,L5);
lawsMasksS.S5R5E5 = get3dLawsText(S5,R5,E5);
lawsMasksS.S5R5S5 = get3dLawsText(S5,R5,S5);
lawsMasksS.S5R5R5 = get3dLawsText(S5,R5,R5);
lawsMasksS.S5R5W5 = get3dLawsText(S5,R5,W5);
lawsMasksS.S5W5L5 = get3dLawsText(S5,W5,L5);
lawsMasksS.S5W5E5 = get3dLawsText(S5,W5,E5);
lawsMasksS.S5W5S5 = get3dLawsText(S5,W5,S5);
lawsMasksS.S5W5R5 = get3dLawsText(S5,W5,R5);
lawsMasksS.S5W5W5 = get3dLawsText(S5,W5,W5);
lawsMasksS.R5L5L5 = get3dLawsText(R5,L5,L5);
lawsMasksS.R5L5E5 = get3dLawsText(R5,L5,E5);
lawsMasksS.R5L5S5 = get3dLawsText(R5,L5,S5);
lawsMasksS.R5L5R5 = get3dLawsText(R5,L5,R5);
lawsMasksS.R5L5W5 = get3dLawsText(R5,L5,W5);
lawsMasksS.R5E5L5 = get3dLawsText(R5,E5,L5);
lawsMasksS.R5E5E5 = get3dLawsText(R5,E5,E5);
lawsMasksS.R5E5S5 = get3dLawsText(R5,E5,S5);
lawsMasksS.R5E5R5 = get3dLawsText(R5,E5,R5);
lawsMasksS.R5E5W5 = get3dLawsText(R5,E5,W5);
lawsMasksS.R5S5L5 = get3dLawsText(R5,S5,L5);
lawsMasksS.R5S5E5 = get3dLawsText(R5,S5,E5);
lawsMasksS.R5S5S5 = get3dLawsText(R5,S5,S5);
lawsMasksS.R5S5R5 = get3dLawsText(R5,S5,R5);
lawsMasksS.R5S5W5 = get3dLawsText(R5,S5,W5);
lawsMasksS.R5R5L5 = get3dLawsText(R5,R5,L5);
lawsMasksS.R5R5E5 = get3dLawsText(R5,R5,E5);
lawsMasksS.R5R5S5 = get3dLawsText(R5,R5,S5);
lawsMasksS.R5R5R5 = get3dLawsText(R5,R5,R5);
lawsMasksS.R5R5W5 = get3dLawsText(R5,R5,W5);
lawsMasksS.R5W5L5 = get3dLawsText(R5,W5,L5);
lawsMasksS.R5W5E5 = get3dLawsText(R5,W5,E5);
lawsMasksS.R5W5S5 = get3dLawsText(R5,W5,S5);
lawsMasksS.R5W5R5 = get3dLawsText(R5,W5,R5);
lawsMasksS.R5W5W5 = get3dLawsText(R5,W5,W5);
lawsMasksS.W5L5L5 = get3dLawsText(W5,L5,L5);
lawsMasksS.W5L5E5 = get3dLawsText(W5,L5,E5);
lawsMasksS.W5L5S5 = get3dLawsText(W5,L5,S5);
lawsMasksS.W5L5R5 = get3dLawsText(W5,L5,R5);
lawsMasksS.W5L5W5 = get3dLawsText(W5,L5,W5);
lawsMasksS.W5E5L5 = get3dLawsText(W5,E5,L5);
lawsMasksS.W5E5E5 = get3dLawsText(W5,E5,E5);
lawsMasksS.W5E5S5 = get3dLawsText(W5,E5,S5);
lawsMasksS.W5E5R5 = get3dLawsText(W5,E5,R5);
lawsMasksS.W5E5W5 = get3dLawsText(W5,E5,W5);
lawsMasksS.W5S5L5 = get3dLawsText(W5,S5,L5);
lawsMasksS.W5S5E5 = get3dLawsText(W5,S5,E5);
lawsMasksS.W5S5S5 = get3dLawsText(W5,S5,S5);
lawsMasksS.W5S5R5 = get3dLawsText(W5,S5,R5);
lawsMasksS.W5S5W5 = get3dLawsText(W5,S5,W5);
lawsMasksS.W5R5L5 = get3dLawsText(W5,R5,L5);
lawsMasksS.W5R5E5 = get3dLawsText(W5,R5,E5);
lawsMasksS.W5R5S5 = get3dLawsText(W5,R5,S5);
lawsMasksS.W5R5R5 = get3dLawsText(W5,R5,R5);
lawsMasksS.W5R5W5 = get3dLawsText(W5,R5,W5);
lawsMasksS.W5W5L5 = get3dLawsText(W5,W5,L5);
lawsMasksS.W5W5E5 = get3dLawsText(W5,W5,E5);
lawsMasksS.W5W5S5 = get3dLawsText(W5,W5,S5);
lawsMasksS.W5W5R5 = get3dLawsText(W5,W5,R5);
lawsMasksS.W5W5W5 = get3dLawsText(W5,W5,W5);

switch lower(direction)
    
    case '2d'
        fieldNameLen = 4;
        
    case '3d'    
        fieldNameLen = 6;
        
    otherwise
        fieldNameLen = 0;
    
end
if fieldNameLen > 0
    fieldNamC = fieldnames(lawsMasksS);
    indRemV = cellfun(@(x) length(x)~=fieldNameLen, fieldNamC, 'UniformOutput',true);
    lawsMasksS = rmfield(lawsMasksS,fieldNamC(indRemV));
end

fieldNamC = fieldnames(lawsMasksS);
switch size
    case '3'
        indRemV = contains(fieldNamC,'5');
        lawsMasksS = rmfield(lawsMasksS,fieldNamC(indRemV));
    case '5'
        indRemV = contains(fieldNamC,'3');
        lawsMasksS = rmfield(lawsMasksS,fieldNamC(indRemV));
end

function conved3M = get3dLawsText(x,y,z)
conved2M = x'*y;
numVoxels = length(x);
conved3M = zeros(numVoxels,numVoxels,numVoxels,'single');
for i = 1:numVoxels
    conved3M(:,:,i) = conved2M(i,:)' * z;
end


