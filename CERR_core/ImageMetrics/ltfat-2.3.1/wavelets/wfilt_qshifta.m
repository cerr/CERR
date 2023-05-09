function [h,g,a,info] = wfilt_qshifta(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_qshifta
%@verbatim
%WFILT_QSHIFTA  Improved Orthogonality and Symmetry properties 
%
%   Usage: [h,g,a] = wfilt_qshifta(N);
%
%   [h,g,a]=wfilt_qshift(N) with N in {1,2,3,4,5,6,7} returns
%   Kingsbury's Q-shift wavelet filters for tree A.
%
%   Examples:
%   ---------
%   :
%     figure(1);
%     wfiltinfo('qshifta3');
% 
%   References:
%     N. G. Kingsbury. A dual-tree complex wavelet transform with improved
%     orthogonality and symmetry properties. In ICIP, pages 375--378, 2000.
%     
%     N. Kingsbury. Design of q-shift complex wavelets for image processing
%     using frequency domain energy minimization. In Image Processing, 2003.
%     ICIP 2003. Proceedings. 2003 International Conference on, volume 1,
%     pages I--1013--16 vol.1, Sept 2003.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_qshifta.html}
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

% AUTHOR: Zdenek Prusa

info.istight = 1;
a = [2;2];

switch(N)
 case 1
    % Example 1. from the reference 1. Symmetric near-orthogonal
    % More precise values (more decimal places) were taken from
    % the Python DTCWT package
    hlp = [
        0.0351638365714947     % z^4
        0                                 
       -0.0883294244510729     % z^2    
        0.233890320607236      % z^1
        0.760272369066126      % z^0 <-- origin
        0.587518297723561      % z^-1
        0                    
       -0.114301837144249      % z^-3
        0                    
        0                    
    ];
case 2
    % 
    hlp = [
       0.0511304052838317
      -0.0139753702468888
      -0.109836051665971
       0.263839561058938
       0.766628467793037
       0.563655710127052
       0.000873622695217097
      -0.100231219507476
      -0.00168968127252815
      -0.00618188189211644
    ];


case 3
    % Example 2. From the reference 1. 
    hlp = [
        0.00325314276365318
       -0.00388321199915849
        0.0346603468448535
       -0.0388728012688278
       -0.117203887699115
        0.275295384668882
        0.756145643892523 % <-- origin
        0.568810420712123
        0.0118660920337970
       -0.106711804686665
        0.0238253847949203
        0.0170252238815540
       -0.00543947593727412
       -0.00455689562847549
    ];
case 4
    % 
    hlp = [
      -0.00476161193845591
      -0.000446022789262285
      -7.14419732796501e-05
       0.0349146123068422
      -0.0372738957998980
      -0.115911457427441
       0.276368643133032
       0.756393765199037
       0.567134484100133
       0.0146374059644734
      -0.112558884257522
       0.0222892632669227
       0.0184986827241562
      -0.00720267787825835
      -0.000227652205897772
       0.00243034994514868
    ];
case 5
    % Example 3. From the reference 1. 
    hlp = [
      -0.00228412744027053 % z^8
       0.00120989416307344 % z^7  
      -0.0118347945154308  % z^6
       0.00128345699934440 % z^5
       0.0443652216066170  % z^4
      -0.0532761088030473  % z^3
      -0.113305886362143   % z^2
       0.280902863222187   % z^1
       0.752816038087856   % z^0 <-- origin
       0.565808067396459   % z^-1
       0.0245501524336666  % z^-2
      -0.120188544710795   % z^-3
       0.0181564939455465  % z^-4
       0.0315263771220847  % z^-5
      -0.00662879461243006 % z^-6
      -0.00257617430660079 % z^-7
       0.00127755865380700 % z^-8
       0.00241186945666628 % z^-9          
    ];

case 6
    % From reference 2
    % Generated using software by Prof. Nick Kingsbury
    % http://sigproc.eng.cam.ac.uk/foswiki/pub/Main/NGK/qshiftgen.zip
    % hlp = qshiftgen([26,1/3,1,1,1]); hlp = hlp/norm(hlp);
    hlp = [9.69366641745754e-05;3.27432154422329e-05;...
          -0.000372508343063683;0.000265822010615719;0.00420106192587724;...
          -0.000851685012123638;-0.0194099330331787;0.0147647107515980;...
           0.0510823932256706;-0.0665925933116249;-0.111697066192884;...
           0.290378669551088;0.744691179589718;0.565900493333378;...
           0.0350864022239272;-0.130600567220340;0.0106673205278386;...
           0.0450881734744377;-0.0116452911371123;-0.0119726865351617;...
           0.00464728269258923;0.00156428519208473;-0.000193257944314871;...
           -0.000997377567082884;-4.77392249288136e-05;0.000126793092000602];

case 7
    % hlp = qshiftgen([38,1/3,1,1,1]); hlp = hlp/norm(hlp);
    hlp = [-5.60092763439975e-05;5.48406024854987e-05;...
           9.19038839527110e-05;-8.70402717115631e-05;...
           -0.000220539629671714;0.000281927965110883;...
           0.000785261918054103;-0.000284818785208508;...
           -0.00347903355232634;0.00106170047948173;0.0112918523131508;...
           -0.00661418560030456;-0.0275662474083655;0.0256353066092428;...
           0.0558968886331913;-0.0797279144129786;-0.109398280267440;...
           0.299471557624693;0.735969669961052;0.565697237934440;...
           0.0456103326499340;-0.139358668718518;0.00372525621820399;...
           0.0578449676250133;-0.0102649107519070;-0.0227204202705973;...
           0.00707541881254841;0.00739220672191233;-0.00294716840272524;...
           -0.00194108140290843;0.000711544068828577;0.000568969033823645;...
           -0.000141696506233205;-0.000156935421570824;...
           -9.35020254608262e-07;-2.40218618976427e-05;...
           2.34727799564078e-05;1.31525730967674e-05];
  otherwise
        error('%s: No such filters.',upper(mfilename)); 

end

    % numel(hlp) must be even
    offset = -(numel(hlp)/2); 
    range = (0:numel(hlp)-1) + offset;
    
    % Create the filters according to the reference paper.
    %
    % REMARK: The phase of the alternating +1 and -1 is crucial here.
    %         
    harr = [...
            hlp,...
            (-1).^(range).'.*flipud(hlp),...
        %    flipud(hlp),...
        %    (-1).^(range).'.*hlp,...
            ];
        

htmp=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));

h(1:2,1) = cellfun(@(hEl)struct('h',hEl,'offset',offset),htmp(1:2),...
                   'UniformOutput',0);
g = h;





