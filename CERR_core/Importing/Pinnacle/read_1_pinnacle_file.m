function data = read_1_pinnacle_file(filename,display)
%
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

%
data = [];
if ~exist('display','var')
	display = 1;
end

if display == 1
	h = waitbar(0,sprintf('Reading file "%s" ...',filename));
end

fid = fopen(filename);
if fid < 0
	fprintf('File "%s" cannot be opened.\n',filename);
    if display == 1
        close(h);
    end
	return;
end

%try
	while 1
		[fieldname,val] = read_1_field_pinnacle(fid);
		if isempty(fieldname) && isempty(val)
			break;
		else
			data = add_1_field_to_struct(data,fieldname,val);
		end
	end
	fclose(fid);
% catch
% 	fclose(fid);
% 	disp(lasterr);
% end

if display == 1
	close(h);
end


