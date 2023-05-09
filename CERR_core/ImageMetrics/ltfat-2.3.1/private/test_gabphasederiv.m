function test_failed = test_gabphasederiv()
test_failed = 0;

%-*- texinfo -*-
%@deftypefn {Function} test_gabphasederiv
%@verbatim
% Tests whether all the algorithms return the same values
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_gabphasederiv.html}
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
disp('-----------------test_gabphasederiv----------------------');

L = 100;
l = 0:L-1; l = l(:);

f1 = exp(1i*pi*0.1*l);
f2 = pchirp(L,1);
f3 = expchirp(L,0.2,2.2,'fc',-1.2);
f4 = exp(1i*pi*0.5*L*(l./(L)).^2);
f5 = exp(1i*pi*0.1*L*(l./(L)).^2);
f6 = zeros(L,1); f6(floor(L/2):floor(L/2)+5) = 1;



% Compare the pahse derivatives only for coefficients bigger than
% relminlvl*max(c(:)) and away from the borders..
relminlvldb = 20;
relminlvl = 10^(-relminlvldb/20);

a = [1,1,1,4,4,  1,  4,  2];
M = [L,L,L,L,L,L/4,L/2,L/2];


%g = {{'gauss',1},'gauss',{'hann',8}};
%g = {{'hann',8}};
g = {{'gauss',1},{'gauss',4},{'gauss',1/4},...
    'gauss',{'gauss',4},{'gauss',1/4},'gauss',{'hann',8}};

f = {f3,f3,f3,f3,f3,f3,f3,f3,f3};

phaseconvCell = {'relative','freqinv','timeinv','symphase'};

dflags = {'t','f','tt','ff','tf'};

for ii =1:numel(g)
    for phaseconvId=1:numel(phaseconvCell)
        phaseconv=phaseconvCell{phaseconvId};
        for dflagId = 1:numel(dflags)
            dflag = dflags{dflagId};
            
            c = dgt(f{ii},g{ii},a(ii),M(ii));
            [~,info]=gabwin(g{ii},a(ii),M(ii),dgtlength(numel(f{ii}),a(ii),M(ii)));
            
            minlvl = max(abs(c(:)))*relminlvl;
            algArgs = {
                {'dgt',f{ii},g{ii},a(ii),M(ii)}
                {'phase',angle(c),a(ii)}
                {'cross',f{ii},g{ii},a(ii),M(ii)} 
                {'abs',abs(c),g{ii},a(ii)}   
                };

            algRange = 1:numel(algArgs);
            if ~info.gauss
                algRange = 1:numel(algArgs)-1;
            end
            pderivs = cell(numel(algRange),1);
            
            for algId=algRange
                alg = algArgs{algId};
                pderivs{algId}=gabphasederiv(dflag,alg{:},phaseconv);
                
                % Make it independent of L
                if any(strcmp(dflag,{'t','f'}))
                    pderivs{algId} = pderivs{algId}./L;
                end
                % Mask by big enough coefficients
                pderivs{algId}(abs(c)<minlvl)=0;
            end
            % MSE
            
            N = L/a(ii);
            nfirst = ceil(N/3); nlast = ceil(2*N/3);
            pderivs = cellfun(@(pEl) pEl(:,nfirst:nlast),pderivs,'UniformOutput',0);
            
            % MSE
            res = (cellfun(@(pEl) norm(pEl(:)-pderivs{1}(:)).^2/numel(pEl(:)),pderivs(2:end)));
            [test_failed,failstring]=ltfatdiditfail( sum(res)/numel(algRange),...
                           test_failed,1e-3);
                       
             algStr = cellfun(@(cEl) cEl{1},algArgs(algRange),'UniformOutput',0);
                    

             fail2string = cellfun(@(aEl,rEl)sprintf('%s=%d, ',aEl,rEl),algStr(2:end),num2cell(res),'UniformOutput',0);
             fail2string = strcat(fail2string{:});
             fprintf('GABPHASEDERIV a=%d,M=%d, dflag:%2s pc:%8s MSE %d, %s,  %s\n',a(ii),M(ii),dflag,phaseconv,sum(res),fail2string,failstring);
             if ~isempty(failstring)
                 clim=1;figure(1);plotdgt(pderivs{1},1,'lin','clim',[-clim,clim]);figure(2);plotdgt(pderivs{2},1,'lin','clim',[-clim,clim]);figure(3);plotdgt(pderivs{3},1,'lin','clim',[-clim,clim]);
                 figure(4);plotdgt(pderivs{1}-pderivs{3},1,'lin','clim',[-clim,clim]);
                 prd = 2;
             end
        end
    end
end

