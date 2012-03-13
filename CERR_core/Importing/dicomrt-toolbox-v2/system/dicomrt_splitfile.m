function [fname_1,fname_2]=dicomrt_splitfile(filename)
% dicomrt_splitfile(filename)
%
% Split input filename so that dose/ct volume can be loaded in 2 steps.
% This can overcome some memory problem.
% 
% See also dicomrt_DICOMimport
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

fid=fopen(filename);
nlines=0;
A=[];

while (feof(fid)~=1);
    nlines=nlines+1;
    temp=fgetl(fid);
    A=char(A,temp);
end
A(1,:)=[];

fname_1=[filename,'p1.txt'];
fname_2=[filename,'p2.txt'];

first_slot=fix(nlines/2);

A_1=A(1:first_slot,:);
A_2=A(first_slot+1:end,:);

fid_1=fopen(fname_1,'w');
for i=1:size(A_1,1)-1;
    fprintf(fid_1,'%s\n',deblank(A_1(i,:)));
end
fprintf(fid_1,'%s',deblank(A_1(end,:)));
    
fid_2=fopen(fname_2,'w');
for i=1:size(A_2,1)-1;
    fprintf(fid_2,'%s\n',deblank(A_2(i,:)));
end
fprintf(fid_2,'%s',deblank(A_2(end,:)));

fclose all;


