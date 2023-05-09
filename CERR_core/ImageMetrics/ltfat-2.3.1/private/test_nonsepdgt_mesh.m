ar=1:1:20;
Mr=1:1:20;
Lmodr=1:20; %[1 3 10 100 143];
lt1r=0:10;
lt2r=1:15;

test_failed=0;

for lt2=lt2r
    lt2
    for lt1=lt1r
        if lt1>=lt2
            continue;
        end;
        if gcd(lt1,lt2)>1
            continue
        end;
        for M=Mr            
            for a=ar
                if a>=M
                    continue;
                end;                
                for Lmod=Lmodr
                    
                    
                    L=dgtlength(1,a,M,[lt1,lt2])*Lmod;
                    lt=[lt1,lt2];

                    [s0,s1,br] = shearfind(L,a,M,lt);

                    f=tester_crand(L,1);                                        
                    g=tester_crand(L,1);
                    
                    if 0
                        gd       = gabdual(g,a,M,'lt',lt);
                        gd_shear = gabdual(g,a,M,'lt',lt,'nsalg',2);
                        
                        res=norm(gd-gd_shear)/norm(g);
                        [test_failed,fail]=ltfatdiditfail(res,test_failed);
                        stext=sprintf(['DUAL SHEAR L:%3i a:%3i M:%3i lt1:%2i lt2:%2i %0.5g ' ...
                                       '%s'], L,a,M,lt(1),lt(2),res,fail);
                        disp(stext)
                        
                        
                        if numel(fail)>0
                            error('Failed test');
                        end;
                    end;
                    
                    if 1
                        cc = comp_nonsepdgt_multi(f,g,a,M,lt);
                        
                        cc_shear = comp_nonsepdgt_shear(f,g,a,M,s0,s1,br);
                        
                        res = norm(cc(:)-cc_shear(:))/norm(cc(:));
                        [test_failed,fail]=ltfatdiditfail(res,test_failed);
                        stext=sprintf(['DGT  SHEAR L:%3i a:%3i M:%3i lt1:%2i lt2:%2i %0.5g ' ...
                                       '%s'], L,a,M,lt(1),lt(2),res,fail);
                        disp(stext)
                        
                        if numel(fail)>0
                            error('Failed test');
                        end;
                        
                    end;

                    
                    if 0
                        r=comp_idgt(cc_shear,gd,a,lt,0,1);  
                        res=norm(f-r,'fro')/norm(f,'fro');
                        
                        [test_failed,fail]=ltfatdiditfail(res,test_failed);
                        stext=sprintf(['REC  SHEAR L:%3i a:%3i M:%3i lt1:%2i lt2:%2i %0.5g ' ...
                                       '%s'], L,a,M,lt(1),lt(2),res,fail);
                        disp(stext)
                        
                        
                        if numel(fail)>0
                            error('Failed test');
                        end;
                    end;
                    
                    if 0
                        s0test=(L==noshearlength(L,a,M,lt));
                        s0inv=(s0==0);
                        if s0inv~=s0test
                            [L,a,M,s0==0, s0test]
                        end;
                        
                    end;
                        
                    
                end;
            end;
        end;
    end;
end;

%-*- texinfo -*-
%@deftypefn {Function} test_nonsepdgt_mesh
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_nonsepdgt_mesh.html}
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

