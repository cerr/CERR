function test_failed = test_filterbankconstphase()
test_failed = 0;
disp(' ===============  TEST_FILTERBANKCONSTPHASE  ================');
disp('--- Used subroutines ---');

which comp_filterbankheapint
which comp_filterbankmaskedheapint
which comp_ufilterbankheapint
which comp_ufilterbankmaskedheapint
which comp_filterbankphasegradfrommag


firwinflags=getfield(arg_firwin,'flags','wintype');
freqwinflags=getfield(arg_freqwin,'flags','wintype');

[f,fs] = gspi;


global LTFAT_TEST_TYPE;
if strcmp(LTFAT_TEST_TYPE,'single')
    f=single(f);
end

%f = postpad(f,2048*40);
%
%   Url: http://ltfat.github.io/doc/testing/test_filterbankconstphase.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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
Ls = numel(f);

win = {'gauss','blackman','hann'};
tol = [1e-10];

for winId = 1:numel(win)
    bwmul = 1/4;
    [g,a,fc,L,info]=audfilters(fs,numel(f),'fractional','bwmul',bwmul,'spacing',1/9,'redtar',8,win{winId},'subprec');
    aud_red = sum(a(:,2))/L;

    corig = filterbank(f,g,a);

    c=filterbankconstphase(cellfun(@abs,corig,'UniformOutput',0),a,info.fc,info.tfr,'tol',tol);

    cproj = filterbank(ifilterbankiter(c,g,a,'pcg','tol',1e-6),g,a);
    Cdb = 20*log10( norm(abs(cell2mat(corig)) - abs(cell2mat(cproj)) )/norm( abs(cell2mat(corig))) );
    res = ~( Cdb < -30 );
    [test_failed,fail]=ltfatdiditfail(res,test_failed);

    %figure(1);plotfilterbankphasediff(corig,c,1e-4,a);

    fprintf('AUDFILTERS win=%8s red=%.2f, C=%.2f dB %s\n', win{winId}, aud_red, Cdb, fail);

    redmul=2;
    switch win{winId}
    case firwinflags
        redmul=1;
    end

    [g,a,fc,L,info]=cqtfilters(fs,100,fs/2 - 100,48,numel(f),'fractional',win{winId},'redmul',redmul,'Qvar',4,'subprec');
    cqt_red = sum(a(:,2))/L;

    corig = filterbank(f,g,a);
    c=filterbankconstphase(cellfun(@abs,corig,'UniformOutput',0),a,info.fc,info.tfr,'tol',tol);
    %figure(2);plotfilterbankphasediff(corig,c,1e-4,a);

    cproj = filterbank(ifilterbankiter(c,g,a,'pcg','tol',1e-6),g,a);
    Cdb = 20*log10( norm(abs(cell2mat(corig)) - abs(cell2mat(cproj)) )/norm( abs(cell2mat(corig))) );
    
    res = ~( Cdb < -30 );
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    fprintf('CQTFILTERS win=%8s red=%.2f, C=%.2f dB %s\n', win{winId}, cqt_red, Cdb, fail);
    
    a = 256; M = 2048; M2 = floor(M/2) + 1;
    [~,~,~,L,info] = gabfilters(Ls,win{winId},a,M);
    gab_red = M2/a;
    
    corig = dgtreal(f,win{winId},a,M,'timeinv').';
    c=filterbankconstphase(abs(corig),a,info.fc,info.tfr,'tol',tol);
    %figure(3);plotfilterbankphasediff(corig,c,1e-4,a);

    cproj = dgtreal(idgtreal(c.',{'dual',win{winId}},a,M,'timeinv'),win{winId},a,M,'timeinv').';
    Cdb = 20*log10( norm(abs(corig) - abs(cproj) )/norm( abs(corig)) );
    
    res = ~( Cdb < -30 );
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    fprintf('GABOR      win=%8s red=%.2f, C=%.2f dB %s\n', win{winId}, gab_red, Cdb, fail);
    
end



