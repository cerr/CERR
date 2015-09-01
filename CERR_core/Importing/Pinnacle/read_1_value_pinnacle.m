function [fieldname,val] = read_1_value_pinnacle(fid,tl)
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

fieldname = '';
val = [];
if tl(1) == '/' && tl(2) == '*'
	% This is a comment line
	return;
end

if tl(end)==';'
	% removing the trailing ';'
	tl = tl(1:end-1);
end

k = strfind(tl,'=');
if isempty(k)
	k = strfind(tl,':');
end
if isempty(k)
	if ~isempty(tl)
		if tl(end) ~= ';' && sum(isletter(tl)) == 0
			% all numbers
			fieldname = '';
			val = str2num(tl);
			return;
		else
			fieldname = 'Data_Wrong_Format';
			val = tl;
		end
	end
	return;
end

outl{1} = tl(1:(k-1));
outl{2} = tl((k+1):end);

% outl = strsplit_cerr('=',tl);
fieldname = ddeblank(outl{1});
fieldname = strrep(fieldname,' ','_');
fieldname = strrep(fieldname,'.','_');
if fieldname(1) == '#'
	fieldname = ['Item_' fieldname(2:end)];
end
val = ddeblank(outl{2});

if isempty(val)
	%% Do nothing?
elseif val(1) == '"'
	if strcmp(val,'""') == 1
		val = '';
	else
		val = val(2:end);
		if isempty(val)
			tl2 = read_additional_lines(fid);
			val = [val tl2];
		end

		if val(end) == ';'
			val = val(1:(end-1));
		end
		
		if val(end) ~= '"'
			tl2 = read_additional_lines(fid);
			val = [val tl2];
			if val(end) == ';'
				val = val(1:(end-1));
			end
		end
		
		if val(end) == '"'
			val = val(1:(end-1));
		end		
	end
else
	val2 = str2double(val);
	if ~isnan(val2)
		val = val2;
	end
end

return;


function tlout = read_additional_lines(fid)
tlout = '';
while 1
	tl = read_1_line_pinnacle(fid);
	if ~ischar(tl)
		break;
	elseif isempty(tl)
		continue;
	else
		tlout = [tlout tl];
		if tl(end) == ';' || tl(end) == '"'
			break;
		end
	end
end
return;


