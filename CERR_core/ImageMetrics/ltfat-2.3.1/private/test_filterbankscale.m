function test_failed=test_filterbankscale()
test_failed = 0;

disp('----------FILTERBANKSCALE-----------');

 gr{1}=randn(20,1);
 gr{2}=randn(21,1);
 gr{3}=firfilter('hanning',19);
 gr{4}=firfilter('hanning',20);
 gr{5}=randn(4,1);
 gr{6}=firfilter('hanning',20,'causal');
 gr{7}=firfilter('hanning',20,'delay',13); 
 gr{8}=firfilter('hanning',20,'delay',-13); 
 gr{7}=firfilter('hanning',20,'delay',14); 
 gr{8}=firfilter('hanning',20,'delay',-14); 
 gr{9}=firfilter('hamming',19,.3); 
 gr{10}=firfilter('hamming',19,.3,'real');
 gr{11}=blfilter('hanning',.19);
 gr{12}=blfilter('hanning',.2);
 gr{13}=blfilter('hanning',.132304);
 gr{14}=blfilter('hanning',.23,'delay',13);
 gr{15}=blfilter('hamming',.23,.3);
 gr{16}=blfilter('hamming',.23,.3,'real');
 % (almost) Allpass filter
 gr{17}=blfilter('hanning',2);
 gr{18}=blfilter('hanning',1);
 gr{19}=blfilter('hanning',2,1);
 gr{20}=blfilter('hanning',1,-1);
 gr{21}=blfilter('hamming',.1,-.3);
 gr{22}=blfilter('hanning',1.7);
 gr{23}=struct('H',randn(10,1),'L',100);
 gr{24}=crand(40,1);
 gr{25}=struct('h',crand(40,1));
 gr{26}=struct('h',crand(40,1),'realonly',1);
 
 Larr = [100, 211];
 norms = {'1','2','inf'};
 
 for L = Larr
     gr{23}=struct('H',randn(10,1),'L',L);
     for ii = 0:1
         if ii==0, freqstr = ''; freqflag = 'nofreq';
         else freqstr = 'FREQ'; freqflag = 'freq'; end
             
         for nId = 1:numel(norms)
             g = filterbankscale(gr,L,norms{nId},freqflag);
             if ii == 0
                 [~,n] = normalize(ifft(filterbankfreqz(g,1,L)),norms{nId});
             else
                [~,n] = normalize(filterbankfreqz(g,1,L),norms{nId});
             end

             res = sum(abs(n-1));
             [test_failed,fail]=ltfatdiditfail(res,test_failed);  
             fprintf('NORM: %s %s L=%d %s\n',upper(norms{nId}),freqstr,L,fail);
         end
     end
 end
 
 scal = 0.1;
  for L = Larr
     gr{23}=struct('H',randn(10,1),'L',L);
 
         for nId = 1:numel(norms)
             grfreqz = filterbankfreqz(gr,1,L);
             g = filterbankscale(gr,scal);

             gfreqz = filterbankfreqz(g,1,L);
             
             res = sum(sum(scal*grfreqz-gfreqz));
             [test_failed,fail]=ltfatdiditfail(res,test_failed);  
             fprintf('SCALE %f L=%d %s\n',scal,L,fail);

         end
 end
 

%-*- texinfo -*-
%@deftypefn {Function} test_filterbankscale
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_filterbankscale.html}
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

