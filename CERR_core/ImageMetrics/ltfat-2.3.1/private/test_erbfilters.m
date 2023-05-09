function test_failed=test_erbfilters
%-*- texinfo -*-
%@deftypefn {Function} test_erbfilters
%@verbatim
%TEST_ERBFILTERS  Test the erbfilters filter generator
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_erbfilters.html}
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

warpname={'warped','symmetric'};
Ls = 10000;
%warpname={'symmetric'};

test_failed=0;

for realcomplexidx=1:2
    if realcomplexidx==1        
        realcomplex='real';
        isreal=1;
    else
        realcomplex='complex';
        isreal=0;
    end;    

    for warpidx=1:2
        warping=warpname{warpidx};
        
        for fracidx=2:-1:1
            if fracidx==1
                fractional={'regsampling'};
                fracname='regsamp';
            else
                fractional={'fractional'};
                fracname='fractional';
            end;
            
            for uniformidx=1:2
                if uniformidx==1                
                    isuniform=0;
                    uniform='regsampling';
                else
                    isuniform=1;
                    uniform='uniform';
                end;
                
                [g,a]=audfilters(16000,Ls,fractional{:},warping,uniform,...
                      'redmul',1,realcomplex,'nuttall30');
                L=filterbanklength(Ls,a);
                
                f=randn(L,1);
                % Test it
                if 0
                    f=[1;zeros(L-1,1)];
                    ff=fft(f);
                    ff(1999:2003)=0;
                    f=ifft(ff);
                end;
                
                if 0
                    % Inspect it: Dual windows, frame bounds and the response
                    disp('Frame bounds:')
                    [A,B]=filterbankrealbounds(g,a,L);
                    A
                    B
                    B/A
                    filterbankresponse(g,a,L,'real','plot');
                end;

                if isreal
                    gd=filterbankrealdual(g,a,L);
                else
                    gd=filterbankdual(g,a,L);
                end;
                
                if isuniform
                    c=ufilterbank(f,g,a);
                else
                    c=filterbank(f,g,a);
                end;
                
                cind = cell(numel(g),1);
                for ii = 1:numel(g)
                    %clear comp_filterbank_fftbl;
                    cind{ii} = pfilt(f,g{ii},a(ii,:));
                end

                if isuniform
                    cind = cell2mat(cind);
                    res = norm(c(:) - cind(:));
                else
                    res =  sum(cellfun(@(c1El,c2El) norm(c1El-c2El),cind,c));
                end

                [test_failed,fail]=ltfatdiditfail(res,test_failed);
                s=sprintf(['ERBFILTER PFILT  %s %s %s %s L:%3i %0.5g %s'],realcomplex,warping,fracname,uniform,L,res,fail);    
                disp(s);                
                
                
                
                r=ifilterbank(c,gd,a);
                if isreal
                    r=2*real(r);
                end;
                
                res=norm(f-r);
                
                [test_failed,fail]=ltfatdiditfail(res,test_failed);
                s=sprintf(['ERBFILTER DUAL  %s %s %s %s L:%3i %0.5g %s'],realcomplex,warping,fracname,uniform,L,res,fail);    
                disp(s);
                
                  if isreal
                     gt=filterbankrealtight(g,a,L);
                 else
                     gt=filterbanktight(g,a,L);
                 end;
                 
                if isuniform
                    c=ufilterbank(f,gt,a);
                else
                    c=filterbank(f,gt,a);
                end;
                 
                 rt=ifilterbank(c,gt,a);
                 if isreal
                     rt=2*real(rt);
                 end;
                 
                 res=norm(f-rt);
                 
                 [test_failed,fail]=ltfatdiditfail(res,test_failed);
                 s=sprintf(['ERBFILTER TIGHT %s %s %s %s L:%3i %0.5g %s'],realcomplex,warping,fracname,uniform,L,res,fail);    
                 disp(s);
                
            end;
            
        end;
        
    end;
    
end;

