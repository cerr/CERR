% LTFAT - Filterbanks
%
%  Peter L. Soendergaard, 2011 - 2018
%
%  Transforms and basic routines
%    FILTERBANK             - Filter bank
%    UFILTERBANK            - Uniform Filter bank
%    IFILTERBANK            - Inverse normal/uniform filter bank
%    IFILTERBANKITER        - Iteratively inverse filter bank 
%    FILTERBANKWIN          - Evaluate filter bank window
%    FILTERBANKLENGTH       - Length of filter bank to expand signal
%    FILTERBANKLENGTHCOEF   - Length of filter bank to expand coefficients
%
%  Auditory inspired filter banks
%    CQT                    - Constant-Q transform
%    ICQT                   - Inverse constant-Q transform
%    ERBLETT                - Erb-let transform
%    IERBLETT               - Inverse Erb-let transform
%
%  Filter generators
%    CQTFILTERS             - Logarithmically spaced filters
%    ERBFILTERS             - ERB-spaced filters
%    WARPEDFILTERS          - Frequency-warped filters 
%    AUDFILTERS             - Filters based on auditory scales
%  
%  Window construction and bounds
%    FILTERBANKDUAL         - Canonical dual filters
%    FILTERBANKTIGHT        - Canonical tight filters
%    FILTERBANKREALDUAL     - Canonical dual filters for real-valued signals
%    FILTERBANKREALTIGHT    - Canonical tight filters for real-valued signals
%    FILTERBANKBOUNDS       - Frame bounds of filter bank
%    FILTERBANKREALBOUNDS   - Frame bounds of filter bank for real-valued signals
%    FILTERBANKRESPONSE     - Total frequency response (a frame property)
%
%  Auxilary
%    FILTERBANKFREQZ        - Frequency responses of filters
%    FILTERBANKSCALE        - Scaling and normalization of filters
%    NONU2UFILTERBANK       - Non-uni. to uniform filter bank transformation
%    U2NONUCFMT             - Change format of coefficients
%    NONU2UCFMT             - Change format of coefficients back
%
%  Plots
%    PLOTFILTERBANK         - Plot normal/uniform filter bank coefficients
%
%  Reassignment and phase gradient
%    FILTERBANKPHASEGRAD      - Instantaneous time/frequency from signal
%    FILTERBANKREASSIGN       - Reassign filterbank spectrogram
%    FILTERBANKSYNCHROSQUEEZE - Synchrosqueeze filterbank spectrogram  
%    
%
%  For help, bug reports, suggestions etc. please visit 
%  http://github.com/ltfat/ltfat/issues
%
%   Url: http://ltfat.github.io/doc/filterbank/Contents.html

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


