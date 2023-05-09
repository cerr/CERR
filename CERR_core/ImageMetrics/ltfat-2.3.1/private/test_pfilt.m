function test_failed=test_pfilt
Lr =[27,100,213];
%-*- texinfo -*-
%@deftypefn {Function} test_pfilt
%@verbatim
% 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_pfilt.html}
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



% REMARK: modcent is applied to fc

test_failed=0;

disp(' ===============  TEST_PFILT ==============');

disp('--- Used subroutines ---');
which comp_filterbank_td
which comp_filterbank_fft
which comp_filterbank_fftbl
which comp_filterbank

disp('--- Regular subsampling ---');
for ii=1:numel(gr)
  % Skip empry fields in gr
  g=gr{ii};
  if isempty(g)
      continue;
  end


  for a=1:3
      for jj=1:length(Lr)
          % Create input signal of proper length
          L=ceil(Lr(jj)/a)*a;
      
          for W=1:3
              
              for rtype=1:2
                  if rtype==1
                      rname='REAL ';	
                      f=tester_rand(L,W);
                  else
                      rname='CMPLX';	
                      f=tester_crand(L,W);
                  end;
                  
                                   
                  h2=ref_pfilt(f,g,a);
                  h1=pfilt(f,g,a);
				  
                   res=norm(h1-h2);
                  [test_failed,fail]=ltfatdiditfail(res,test_failed);        
                  s=sprintf('PFILT %3s  filtno:%3i L:%3i W:%3i a:%3i %0.5g %s',rname,ii,L,W,a,res,fail);
                  disp(s);
              end;
          end;
      end;
      
  end;
  
end;

disp('--- Fractional subsampling ---');

% Pick just bl filters
idx = cellfun(@(grEl) isfield(grEl,'H'),gr);
tmpRange = 1:numel(gr);
tmpRange = tmpRange(idx);


for ii=tmpRange
  g = gr{ii};
  for jj=1:length(Lr)
    L = Lr(jj);
    % Find support and offset of the filter
    tmpH = g.H(L);
    if numel(tmpH) == L
        % this is no longer a band pass filter
    end
        
    foff = g.foff(L);
    
    Nmin = numel(tmpH);
    
    for Nalt=[-3,-7,3,0];
        % Nalt==0 painless
        % Nalt>0 painless 
        % Nalt<0 not painless
        if Nmin + Nalt <=0
            a = [L,1];
        elseif Nmin + Nalt >= L
            % This is no longer fractional subsampling
            a = [L,L];    
        else
            a = [L,Nmin+Nalt];
        end
        
        
    for W=1:3
        for rtype=1:2
              if rtype==1
                  rname='REAL ';	
                  f=tester_rand(L,W);
              else
                  rname='CMPLX';	
                  f=tester_crand(L,W);
              end;
              
              
                  h2=ref_pfilt(f,g,a);
                  h1=pfilt(f,g,a);
				  
                   res=norm(h1-h2);
                  [test_failed,fail]=ltfatdiditfail(res,test_failed);        
                  s=sprintf('PFILT %3s  filtno:%3i L:%3i W:%3i a:[%3i,%3i], fb: %i, %0.5g %s',...
                            rname,ii,L,W,a(1),a(2),Nmin,res,fail);
                  disp(s);
              
        end
    end
    end
  end
  
end






