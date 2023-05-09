function test_failed=test_purefreq
  
disp(' ===============  TEST_PUREFREQ ================');

disp('--- Used subroutines ---');

which comp_fftreal
which comp_ifftreal
which comp_dct
which comp_dst

%-*- texinfo -*-
%@deftypefn {Function} test_purefreq
%@verbatim
% This script test all the pure frequency routines.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_purefreq.html}
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

% This is a list or pairs. The two functions in each pair
% will be evaluated with the same parameters, and the output
% should be the same.
ref_funs={{'ref_dcti','dcti'},...
          {'ref_dcti','ref_dcti_1'},...
	  {'ref_dctii','dctii'},...
	  {'ref_dctiii','dctiii'},...
	  {'ref_dctii','ref_dctii_1'},...
	  {'ref_dctiii','ref_dctiii_1'},...	  	  	  
	  {'ref_dctiv','dctiv'},...
	  {'ref_dsti','dsti'},...
	  {'ref_dsti','ref_dsti_1'},...
	  {'ref_dstii','dstii'},...
	  {'ref_dstiii','dstiii'},...
	  {'ref_dstii','ref_dstii_1'},...
	  {'ref_dstiii','ref_dstiii_1'},...
	  {'ref_dstiv','dstiv'},...
	  {'ref_dft','ref_dft_1'},...
	  {'ref_rdft','ref_rdft_1'},...
	  {'ref_irdft','ref_irdft_1'},...
	  };

% This is a list or pairs. The two functions in each pair will be evaluated
% on purely real input with the same parameters, and the output should be
% the same.
ref_realfuns={{'ref_dcti','dcti'},...
          {'ref_dcti','ref_dcti_1'},...
	  {'ref_dctii','dctii'},...
	  {'ref_dctiii','dctiii'},...
	  {'ref_dctii','ref_dctii_1'},...
	  {'ref_dctiii','ref_dctiii_1'},...	  	  	  
	  {'ref_dctiv','dctiv'},...
	  {'ref_dsti','dsti'},...
	  {'ref_dsti','ref_dsti_1'},...
	  {'ref_dstii','dstii'},...
	  {'ref_dstiii','dstiii'},...
	  {'ref_dstii','ref_dstii_1'},...
	  {'ref_dstiii','ref_dstiii_1'},...
	  {'ref_dstiv','dstiv'},...
	  {'ref_dft','ref_dft_1'},...
          {'ref_fftreal','fftreal'},...          
	  {'ref_rdft','ref_rdft_1'},...
	  {'ref_irdft','ref_irdft_1'},...
	  };


  %	  {'ref_dftii','ref_dftii_1'},...
%	  {'ref_dftii','ref_dftii_2'},...
%	  {'ref_idftii','ref_idftii_1'},...
%	  {'ref_dftiv','ref_dftiv_1'},...
%	  {'ref_rdftiii','ref_rdftiii_1'},...
%	  {'ref_irdftiii','ref_irdftiii_1'},...

% Each row is the size of a matrix. All the functions
% mentioned above will be executed with input matrixes
% of sizes mentioned below.
ref_sizes=[1 1;...
	   2 1;...
	   3 2;...
	   4 3;...
	   5 3
           100 1];
	   
% As ref_funs, these functions should be inverses of each other.
inv_funs={{'dcti','dcti'},...
	  {'dctii','dctiii'},...
	  {'dctiv','dctiv'},...
	  {'ref_dsti','ref_dsti'},...
	  {'dstii','dstiii'},...
	  {'dstiv','dstiv'},...
	  {'dft','idft'},...
	  {'ref_rdft','ref_irdft'},...
	  };

% As ref_funs, these functions should be inverses of each other.
realinv_funs={{'fftreal','ifftreal'}};
  
  %	  {'ref_rdftiii','ref_irdftiii'},...
%	  {'ref_dftii','ref_idftii'},...
%	  {'ref_dftiii','ref_idftiii'},...
%	  {'ref_rdftiii','ref_irdftiii'},...
%	  {'ref_dftiv','ref_idftiv'},...

% Each function in the list should be unitary. They will be tested on
% matrix of sizes correspondin to the first column in ref_sizes 

nrm_funs={'dctii','dctiii','dctiv','ref_dft','ref_rdft'};

% ---------- reference testing --------------------
% Test that the transforms agree on values.

ref_failed=0;

for funpair=ref_funs
  for ii=1:size(ref_sizes,1);
    %a=tester_rand(ref_sizes(ii,:));
    a=tester_crand(ref_sizes(ii,1),ref_sizes(ii,2));

    c1=feval(funpair{1}{1},a);
    c2=feval(funpair{1}{2},a);

    res=norm(c1(:)-c2(:));

    [ref_failed,fail]=ltfatdiditfail(res,ref_failed);

    s=sprintf('REF %7s L:%2i W:%2i %0.5g %s',funpair{1}{2},ref_sizes(ii,1),ref_sizes(ii,2),res,fail);
    disp(s)
	
  end;
end;


% ---------- real valued reference testing --------------------
% Test that the transforms agree on values.

ref_failed=0;

for funpair=ref_realfuns
  for ii=1:size(ref_sizes,1);
    a=tester_rand(ref_sizes(ii,1),ref_sizes(ii,2));

    c1=feval(funpair{1}{1},a);
    c2=feval(funpair{1}{2},a);

    res=norm(c1(:)-c2(:));

    [ref_failed,fail]=ltfatdiditfail(res,ref_failed);
    s=sprintf('REA %7s L:%2i W:%2i %0.5g %s',funpair{1}{2},ref_sizes(ii,1),ref_sizes(ii,2),res,fail);
    disp(s)
  end;
end;

%------------ inversion testing -----------------
% Test that the transforms are invertible

inv_failed=0;

for funpair=inv_funs
  for ii=1:size(ref_sizes,1);
    %a=tester_rand(ref_sizes(ii,:));
    a=tester_crand(ref_sizes(ii,1),ref_sizes(ii,2));

    ar=feval(funpair{1}{2},feval(funpair{1}{1},a));

    res=norm(a(:)-ar(:));

    [inv_failed,fail]=ltfatdiditfail(res,inv_failed);
    s=sprintf('INV %7s L:%2i W:%2i %0.5g %s',funpair{1}{1},ref_sizes(ii,1),ref_sizes(ii,2),res,fail);
    disp(s)
  end;
end;


%----------- normalization test ----------------
% Test that the transforms are orthonormal

nrm_failed=0;

for funname=nrm_funs

  for ii=1:size(ref_sizes,1);

    L=ref_sizes(ii,1);

    F=feval(funname{1},eye(L));

    res=norm(F*F'-eye(L));

    [nrm_failed,fail]=ltfatdiditfail(res,nrm_failed);
    s=sprintf('NRM %7s L:%2i %0.5g %s',funname{1},ref_sizes(ii,1),res,fail);
    disp(s)

  end;
end;

%------------ test fftreal inversion ----------------
% Test that the transforms are invertible

realinv_failed=0;

for funpair=realinv_funs
  for ii=1:size(ref_sizes,1);
    a=tester_rand(ref_sizes(ii,1),ref_sizes(ii,2));

    ar=ifftreal(fftreal(a),ref_sizes(ii,1));

    res=norm(a(:)-ar(:));

    [realinv_failed,fail]=ltfatdiditfail(res,realinv_failed);
    s=sprintf('RIN %7s L:%2i W:%2i %0.5g %s',funpair{1}{1},ref_sizes(ii,1),ref_sizes(ii,2),res,fail);
    disp(s)

    
  end;
end;


%------------ test fftreal postpad ----------------
% Test that fftreal works with different lengths

realpostpad_failed=0;
postpad_sizes = {ref_sizes(:,1)*2, ceil(ref_sizes(:,1)/2), ceil(ref_sizes(:,1)/(3/4)) };

  for ii=1:size(ref_sizes,1);
    a=tester_rand(ref_sizes(ii,1),ref_sizes(ii,2));
    
    for jj=1:numel(postpad_sizes);
        postpad_size =  postpad_sizes{jj};
        ar = fftreal(a,postpad_size(ii));
        ar2 = fft(a,postpad_size(ii),1);
        M2 = floor(postpad_size(ii)/2) + 1;
        ar2 = ar2(1:M2,:);

        res=norm(ar(:)-ar2(:));

        [realpostpad_failed,fail]=ltfatdiditfail(res,realinv_failed);
        s=sprintf('RPOSTPAD fftreal L:%2i L2:%2i W:%2i %0.5g %s',ref_sizes(ii,1),postpad_size(ii),ref_sizes(ii,2),res,fail);
        disp(s)
    end
    
  end;


test_failed=ref_failed+inv_failed+nrm_failed + realpostpad_failed;




