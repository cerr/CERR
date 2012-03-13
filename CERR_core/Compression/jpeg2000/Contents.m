% JPEG 20000 - A toolbox that adds JPEG2000 support to matlab.
% 
% This is just an inteface to the external program "jasper" that can code/decode
% JPEG 2000 images (.JP2/.JPC). Todays version of jasper (1.6) do not support
% all features folly in the full specification of JPEG 2000.
%
% You need to have the free available program "jasper" installed at your seach path
% to make it working. You can find it here:
%
%    http://www.jpeg.org/JPEG2000.html
%    http://www.ece.ubc.ca/~mdadams/jasper/
%    http://www.rpmfind.net/linux/rpm2html/search.php?query=jasper
%
% JP2IMFORMATS - Add and remove jp2/jpc as interface for imread/imwrite/imfinfo 
% JP2READ   - Reads JPEG 2000 image files from disk. Needs jasper installed
% JP2WRITE  - Writes images as JPEG 2000 files to disk. Needs jasper installed.
% ISJP2     - Support function to IMFORMATS, IMREAD ....
% JP2INFO   - Get information about the image in a JP2 or JPC file.
% PGXWRITE  - Writes images as PGX files to disk.
% PGXREAD   - Reads images as PGX files from disk.
% PETER.JP2 - JPEG 2000 Image of me just as am example of a "small" image file.
% PRIVATE/PARSE_PARAMETER_LIST  Read/convert/return argument lists in various formats.
%
%  This inteface to "jasper"
%
%  Copyright (C) 2002, Peter Rydesäter 2002-11-08
%
%  GNU Public License.
%
%  This program is free software; you can redistribute it and/or
%  modify it under the terms of the GNU General Public License
%  as published by the Free Software Foundation; either version 2
%  of the License, or (at your option) any later version.
%  
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%  
%  You should have received a copy of the GNU General Public License
%  along with this program; if not, write to the Free Software
%  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
