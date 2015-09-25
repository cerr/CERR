function g2D = gamma2D(slice1,slice2);
% gamma2D
%
% Gamma 2D function return gamma calculated between 2D slice's passed to
% this function. This gamma2D calls meshgamma2d.dll (not meshgamma2d.exe) 
% written by Dr. Tao.This DLL can be found under the folder
% C:\CVSROOT\CERR\Mex\WindowsMex
%
% Written DK 19/01/07
%
% Usage g2D = gamma2D(slice1,slice2)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.


%% New code to call meshgamma2d.dll

g2D = meshgamma2d(slice1,slice2);




%% This is old code to call the meshgamma2d.exe. The new code calls the
%% meshgamma2d.dll 
% oldPath = pwd;
% 
% newPath = which('meshgamma2d.exe');
% 
% [pathstr] = fileparts(newPath);
% 
% cd(pathstr);
% siz1 = size(slice1);
% siz2 = size(slice2);
% 
% if siz1 == siz2
% 
%     % Create text files as input for meshgamma2d.exe
%     fileid1=fopen('array_test1.txt','w');
%     fprintf(fileid1,'%c', '1');
%     fprintf(fileid1,'\n');
%     fprintf(fileid1,'%c', num2str(siz1(1)));
%     fprintf(fileid1,'\n');
%     fprintf(fileid1,'%c', num2str(siz1(2)));
% 
%     fileid2=fopen(num2str('array_test2.txt'),'w');
%     fprintf(fileid2,'%c', '1');
%     fprintf(fileid2,'\n');
%     fprintf(fileid2,'%c', num2str(siz2(1)));
%     fprintf(fileid2,'\n');
%     fprintf(fileid2,'%c', num2str(siz2(2)));
% 
%     for i = 1:siz1(1)*siz1(2)
%         fprintf(fileid1,'\n');
%         fprintf(fileid1,'%c', num2str(slice1(i)));
% 
%         fprintf(fileid2,'\n');
%         fprintf(fileid2,'%c', num2str(slice2(i)));
%     end
% 
%     fclose(fileid1);
%     fclose(fileid2);
% 
%     % Calling meshgamma2D executable
%     !meshgamma2d.exe array_test1.txt array_test2.txt out1.txt
% 
%     delete('array_test1.txt');
%     delete('array_test2.txt');
% 
%     g2D = single(zeros(siz1));
% 
%     fileid=fopen('out1.txt','r');
% 
%     counter = 1;
%     i = 1;
%     while ~feof(fileid)
%         data = str2num(fgetl(fileid));
%         if counter < 4
%             counter = counter + 1;
%             continue
%         end
%         g2D(i) = data;
%         i = i+1;
%     end
% 
%     fclose(fileid);
%     delete('out.txt');
%     
%     cd(oldPath);
% else
%     warning('Two slices are of different size. Exiting gamma......!');
% end
% 
