function ccell=comp_fwtpack2cell(F,c)
%-*- texinfo -*-
%@deftypefn {Function} comp_fwtpack2cell
%@verbatim
%COMP_FWTPACK2CELL Change FWT coef. format from pack to cell
%   Usage: ccell=comp_fwtpack2cell(F,c)
%
%   Input parameters:
%         F      : FWT frame object
%         c      : Coefficients in pack format
%   Output parameters:
%         ccell  : Coefficients in cell format
%
%   COMP_FWTPACK2CELL(F,c) exctracts individual FWT subbands from 
%   coefficients in packed format c as elements of a cell array. F must
%   be of type 'fwt' e.g. obtained by F=frame('fwt',...) and c must
%   be a Lc xW matrix, obtained by FRANA or BLOCKANA.
%   
%   The inverse operation is mere c=cell2mat(ccel)
%
%   THE FUNCTION DOES NOT CHECK THE INPUT PARAMETERS IN ANY WAY!
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_fwtpack2cell.html}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

w = F.g;
filtNo = numel(w.g);
J = F.J;
subbNo = (filtNo-1)*J+1;
Lc = zeros(subbNo,1);

runPtr = 0;
levelLen = size(c,1)/F.red;

for jj=1:J
     for ff=filtNo:-1:2
        Lc(end-runPtr) = ceil(levelLen/w.a(ff));
        runPtr = runPtr + 1;
     end
     levelLen = ceil(levelLen/w.a(1));
end
Lc(1)=levelLen;

ccell = mat2cell(c,Lc);

% The following does not work for a not being all equal.
%
% filtNo = numel(F.g.g);
% a = F.g.a(1);
% J = F.J;
% 
% subbNo = (filtNo-1)*J+1;
% Lc = zeros(subbNo,1);
% 
% Lc(1:filtNo) = size(c,1)/(1+(filtNo-1)*(a^(J)-1)/(a-1));
% 
% Lc(filtNo+1:end) = kron(Lc(1).*a.^(1:J-1),ones(1,filtNo-1));
% 
% ccell = mat2cell(c,Lc);

