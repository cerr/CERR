function test_failed = test_ufwt(verbose)
%-*- texinfo -*-
%@deftypefn {Function} test_ufwt
%@verbatim
%TEST_COMP_FWT_ALL
%
% Checks perfect reconstruction of the wavelet transform of different
% filters
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_ufwt.html}
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
disp('========= TEST UFWT ============');
global LTFAT_TEST_TYPE;
tolerance = 1e-8;
if strcmpi(LTFAT_TEST_TYPE,'single')
   tolerance = 1e-5;
end


test_failed = 0;
if(nargin>0)
   verbose = 1;
   which comp_ufwt -all
   which comp_iufwt -all
else
   verbose = 0;
end

%  curDir = pwd;
%  mexDir = [curDir(1:strfind(pwd,'\ltfat')+5),'\mex'];
% 
%  rmpath(mexDir);
%  which comp_fwt_all
%  addpath(mexDir)
%  which comp_fwt_all


type = {'undec'};
ext = {'per'};

prefix = 'wfilt_';
test_filters = {
               {'db',1}
               {'db',3}
               {'db',10}
               {'spline',4,4}
               %{'lemaire',80} % not exact reconstruction
               {'hden',3} % only one with 3 filters and different
               %subsampling factors, not working
               {'algmband',2} % 4 filters, subsampling by the factor of 4!, really long identical lowpass filter
               %{'symds',1}
               {'algmband',1} % 3 filters, sub sampling factor 3, even length
               {'sym',4}
               {'sym',9}
               %{'symds',2}
%               {'symds',3}
%               {'symds',4}
%               {'symds',5}
               {'spline',3,5}
               {'spline',3,11}
               %{'spline',11,3} % error too high
               %{'maxflat',2}
               %{'maxflat',11}
               %{'optfs',7} % bad precision of filter coefficients
               %{'remez',20,10,0.1} % no perfect reconstruction
               {'dden',1}
               {'dden',2}
%               {'dden',3}
               {'dden',4}
               {'dden',5}
%               {'dden',6}
               {'dgrid',1}
               {'dgrid',2}
               {'dgrid',3}
               %{'algmband',1} 
               {'mband',1}
               {'symorth',1}
               {'symtight',2}
               %{'hden',3}
               %{'hden',2}
               %{'hden',1}
               %{'algmband',2}
               %{'apr',1} % complex filter values, odd length filters, no perfect reconstruction
               };
%ext = {'per','zpd','sym','symw','asym','asymw','ppd','sp0'};

scaling = {'scale','sqrt','noscale'};
scalingInv = scaling(end:-1:1);


J = 4;
%testLen = 10*2^J-1;%(2^J-1);
testLen = 53;


for scIdx = 1:numel(scaling)

for extIdx=1:length(ext)  
%for inLenRound=0:2^J-1
for inLenRound=0:0
%f = randn(14576,1);
f = tester_rand(testLen+inLenRound,1);
%f = 1:testLen-1;f=f';
%f = 0:30;f=f';
% multiple channels
%f = [2*f,f,0.1*f];
    
for typeIdx=1:length(type)
  typeCur = type{typeIdx};

     extCur = ext{extIdx};  
     
     
     for tt=1:length(test_filters)
         actFilt = test_filters{tt};
         %fname = strcat(prefix,actFilt{1});
         %w = fwtinit(test_filters{tt});  

     for jj=1:J
           if verbose, fprintf('J=%d, filt=%s, inLen=%d\n',jj,actFilt{1},length(f)); end; 
           
           [c,info] = ufwt(f,test_filters{tt},jj,scaling{scIdx});
           %[cvec ,Lc] = cell2pack(c);
           %c = pack2cell(cvec,Lc);
            fhat = iufwt(c,test_filters{tt},jj,scalingInv{scIdx});
            err = norm(f-fhat,'fro');
            [test_failed,fail]=ltfatdiditfail(err,test_failed,tolerance);
            
            if(~verbose)
              fprintf('J=%d, %5.5s, %s, L=%d, err=%.4e %s \n',jj,actFilt{1},scaling{scIdx},length(f),err,fail);
            end
            if strcmpi(fail,'FAILED')
               if verbose
                 fprintf('err=%d, J=%d, filt=%s, inLen=%d',err,jj,actFilt{1},testLen+inLenRound);
                 figure(1);clf;stem([f,fhat]);
                 figure(2);clf;stem([f-fhat]);
                 break; 
               end

            end
            
            fhat2 = iufwt(c,info);
            err = norm(f-fhat2,'fro');
            [test_failed,fail]=ltfatdiditfail(err,test_failed,tolerance);
            fprintf('INFO J=%d, %5.5s, %s, L=%d, err=%.4e %s \n',jj,actFilt{1},scaling{scIdx},length(f),err,fail);
            
     end
      if test_failed && verbose, break; end;
     end
     if test_failed && verbose, break; end;
  end 
   if test_failed && verbose, break; end;
end
 if test_failed && verbose, break; end;
end
end

 
 
   

