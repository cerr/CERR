function test_failed=test_frames
%-*- texinfo -*-
%@deftypefn {Function} test_frames
%@verbatim
%TEST_FRAMES  Test the frames methods
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_frames.html}
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

test_failed=0;
  
disp(' ===============  TEST_FRAMES ================');
global LTFAT_TEST_TYPE;

tolchooser.double=1e-9;
tolchooser.single=2e-4;
tolerance = tolchooser.(LTFAT_TEST_TYPE);

% Iterative algorithms need a bigger tolerance
tolchooseriter.double=1e-1;
tolchooseriter.single=1e-1;
toleranceiter = tolchooseriter.(LTFAT_TEST_TYPE);

Fr=cell(1,32);

L=200;
Fr{1}  = frame('dgt','gauss',10,20);
Fr{2}  = frame('dgtreal','gauss',10,20);
Fr{3}  = frame('dwilt','gauss',20);
Fr{4}  = frame('wmdct','gauss',20);
Fr{5}  = frame('gen',tester_crand(200,300),20);

Fr{6}  = frametight(frame('dgt','gauss',10,20));
Fr{7}  = frametight(frame('dgtreal','gauss',10,20));
Fr{8}  = frametight(frame('dwilt','gauss',20));
Fr{9}  = frametight(frame('wmdct','gauss',20));
Fr{10} = frametight(frame('gen',tester_crand(200,300),20));

Fr{11} = frame('dft');
Fr{12} = frame('dcti');
Fr{13} = frame('dctii');
Fr{14} = frame('dctiii');
Fr{15} = frame('dctiv');
Fr{16} = frame('dsti');
Fr{17} = frame('dstii');
Fr{18} = frame('dstiii');
Fr{19} = frame('dstiv');

% Repeat generation of the filters until they have a nice condition number 
condnum = 1e10;
while condnum > 1e3
   gfilt={tester_rand(30,1),...
          tester_rand(20,1),...
          tester_rand(15,1),...
          tester_rand(10,1)};
      
   gfilt=cellfun(@(gEl) cast(gEl,'double'),gfilt,'UniformOutput',0);
   
   % These two frames might be badly conditioned, 
   Fr{20} = frame('ufilterbank',    gfilt,3,4);
   Fr{21} = frame('ufilterbankreal',gfilt,3,4);
   
   condnum = framebounds(Fr{20},128);
end 

Fr{22} = frame('dgt','gauss',4,6,'lt',[1 2]);
Fr{23} = frame('identity');
Fr{24} = frame('fusion',[1 1],Fr{1},Fr{1});
Fr{25} = frametight(frame('dgt','hamming',10,20));
Fr{26} = frametight(frame('wmdct','hamming',20));

g={randn(30,1),randn(50,1),randn(70,1),randn(90,1)};
a=[20,40,60,80];
M=[30,50,70,100];

Fr{27} = frametight(frame('nsdgt',g,a,M));
Fr{28} = frametight(frame('unsdgt',g,a,100));
Fr{29} = frametight(frame('nsdgtreal',g,a,M));
Fr{30} = frametight(frame('unsdgtreal',g,a,100));

Fr{31} = frametight(frame('dftreal'));

Fr{32} = frame('fwt','ana:spline2:2',5);
Fr{33} = frame('wfbt',{'syn:spline2:2',5});
%Fr{34} = frame('wpfbt',{'db4',5});
%Fr{35} = frame('wpfbt',{'db4',5});
%Fr{36} = frame('wpfbt',{'db4',5});

Fr{37} = frame('ufwt','db4',4);
Fr{38} = frame('ufwt','db4',4,'scale');
Fr{39} = frame('ufwt','db4',4,'noscale');

Fr{40} = frame('uwfbt',{'db4',4});
Fr{41} = frame('uwfbt',{'db4',4},'scale');
Fr{42} = frame('uwfbt',{'db4',4},'noscale');

Fr{43} = frame('uwpfbt',{'db4',4});
Fr{44} = frame('uwpfbt',{'db4',4},'scale');
Fr{45} = frame('uwpfbt',{'db4',4},'noscale');

%Fr{36} = frame('uwfbt',{'db4',5});
%Fr{37} = frame('uwpfbt',{'db4',5});

% The tensor frame implementation is currenly broken
%Fr{33} = frame('tensor',Fr{11});


%Fr{31} = frame('filterbank',     gfilt,[4 3 2 2],4);
%Fr{32} = frame('filterbankreal', gfilt,[4 3 2 2],4);


Fr{60} = frame('erbletfb',44100,L,'real','regsampling');
Fr{61} = frame('erbletfb',44100,L,'complex','regsampling');

Fr{62} = frame('erbletfb',44100,L,'real','fractional');
Fr{63} = frame('erbletfb',44100,L,'complex','fractional');

Fr{64} = frametight(Fr{60});
Fr{65} = frametight(Fr{62});


Fr{66} = frame('cqtfb',44100,200,20000,20,L,'real','regsampling');
Fr{67} = frame('cqtfb',44100,200,20000,20,L,'complex','regsampling');

Fr{68} = frame('cqtfb',44100,200,20000,20,L,'real','fractional');
Fr{69} = frame('cqtfb',44100,200,20000,20,L,'complex','fractional');

Fr{70} = frametight(Fr{66});
Fr{71} = frametight(Fr{67});

for cmpx = {'real','complex'}

    if strcmp(cmpx{1},'real')
        f=tester_rand(L,1);
    else
        f=tester_crand(L,1);
    end

for ii=1:numel(Fr)
  
  F=Fr{ii};
  
  % To avoid holes in Fr
  if isempty(F)
    continue;
  end;
  
  % Do not test real-only frames with complex arrays
  if strcmp(cmpx{1},'complex') && F.realinput
      continue;
  end
  
  Fd=framedual(F);
  
  c=frana(F,f);
  r=frsyn(Fd,c);
  res=norm(r(1:L)-f);
  
  lendiff = size(c,1) - frameclength(F,L);
  [test_failed,fail]=ltfatdiditfail(lendiff ,test_failed);
  s=sprintf(['FRAMES CLENGTH        frameno:%3i %s %0.5g %s'],ii,F.type,lendiff,fail);    
  disp(s);
  
  [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
  s=sprintf(['FRAMES DUAL REC       frameno:%3i %s %0.5g %s'],ii,F.type,res,fail);    
  disp(s); 
  
  % Checking equality F == framedual(framedual(F))
  Fdd = framedual(framedual(F));
  cdd = frana(Fdd,f);
  res_dd = norm(cdd-c);
  
  [test_failed,fail]=ltfatdiditfail(res_dd,test_failed,tolerance);
  s=sprintf(['FRAMES DUAL DUAL      frameno:%3i %s %0.5g %s'],ii,F.type,res_dd,fail);    
  disp(s); 
  
  
  F2=frameaccel(F,L);
  F2d=frameaccel(Fd,L);

  c=frana(F2,f);
  r=frsyn(F2d,c);
  res=norm(r(1:L)-f);
  
  [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
  s=sprintf(['FRAMES ACCEL DUAL REC frameno:%3i %s %0.5g %s'],ii,F.type,res,fail);    
  disp(s);
  
  % Checking equality F == framedual(framedual(F)) after acceleration
  F2dd = framedual(framedual(F2));
  c2dd = frana(Fdd,f);
  res2_dd = norm(c2dd-c);
  
  [test_failed,fail]=ltfatdiditfail(res2_dd,test_failed,tolerance);
  s=sprintf(['FRAMES ACCEL DUAL DUAL      frameno:%3i %s %0.5g %s'],ii,F.type,res2_dd,fail);    
  disp(s); 
  

  % Test that framebounds are able to run, not actual resting is done on
  % the values.
  [A,B]=framebounds(F,L);
  
  %% Test iterative analysis and synthesis
  r=frsyniter(F,c);
  
  res=norm(r(1:L)-f);
  [test_failed,fail]=ltfatdiditfail(res,test_failed,toleranceiter);
  s=sprintf(['FRSYNITER             frameno:%3i %s %0.5g %s'],ii,F.type,res,fail);    
  disp(s);
  
  c2=franaiter(Fd,f);
  res=norm(c2-c);
  [test_failed,fail]=ltfatdiditfail(res,test_failed,toleranceiter);
  s=sprintf(['FRANAITER             frameno:%3i %s %0.5g %s'],ii,F.type,res,fail);    
  disp(s);  
  
  %% Test matrix representations
  if (~F.realinput)
    LL=framelength(F,L);
    G=frsynmatrix(F,LL);
    res=norm(c-G'*postpad(f,LL));
    
    [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
    s=sprintf(['FRAMES ANA MATRIX     frameno:%3i %s %0.5g %s'],ii,F.type,res,fail);    
    disp(s);
    
    % We create a different set of coefficients here.
    % The old code used c and failed the test for some filterbank frames
    ctmp = tester_crand(numel(c),1);
    res=norm(frsyn(F,ctmp)-G*ctmp);
    [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
    s=sprintf(['FRAMES SYN MATRIX     frameno:%3i %s %0.5g %s'],ii,F.type,res,fail);    
    disp(s);
    
  end;
  
  %% Test the frame multipliers: test framemul, framemuladj and
  %% iframemul
  if F.realinput
      m=1+0.01*tester_rand(size(c,1),1);
  else
      m=1+1i+0.01*tester_crand(size(c,1),1);
  end;
  ff=framemul(f,F,Fd,m);
  fr=iframemul(ff,F,Fd,m);
  res=norm(f-fr(1:L))/norm(f);
  [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
  s=sprintf('IFRAMEMUL             frameno:%3i %s %0.5g %s',ii, ...
            F.type,res,fail);
  disp(s);
  
end;
end

