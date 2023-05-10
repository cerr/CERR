function [test_failed_s, test_failed_b, test_failed_l]=test_waveletfilters
%TEST_WAVELETFILTERS  Test the erbfilters filter generator
%
%   Url: http://ltfat.github.io/doc/testing/test_waveletfilters.html

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

[f, fs] = gspi;
f=f(1:1000);
Ls = length(f);
scales = linspace(10,0.1,100);
scales = flip(scales);
fmin = 250;
fmax = 20000;
bins = 8;
M=100;
alpha = 1-2/(1+sqrt(5)); % 1-1/(goldenratio) delay sequence
delays = @(n,a) a*(mod(n*alpha+.5,1)-.5);

wavelettypes = {{'cauchy', 300},{'fbsp', 4, 3}, {'morse'} };

for ii = 1:numel(wavelettypes)
    %first call includes the option to set a starting frequency for the wavelet
    %frequency range (can be applied to others too)
    [g_scales,a_scales,~,L_scales, info_scales]=waveletfilters(Ls,scales, 'delay', delays, wavelettypes{ii}, 'single', 'uniform', 'redtar', 4, 'complex');
    [g_bins,a_bins,~,L_bins,info_bins] = waveletfilters(Ls,'bins', fs,fmin, fmax, bins,'delay', delays, wavelettypes{ii}, 'repeat', 'uniform', 'startfreq', 800);
    [g_linear,a_linear,~,L_linear,info_linear] = waveletfilters(Ls,'linear', fs,fmin, fmax, M,'delay', delays, wavelettypes{ii}, 'uniform');


    Lscales = filterbanklength(L_scales, a_scales);
    Lbins = filterbanklength(L_bins, a_bins);
    Llinear = filterbanklength(L_linear, a_linear);


    gd_scales=filterbankdual(g_scales,a_scales,Lscales, 'asfreqfilter');
    gd_bins_asf=filterbankrealdual(g_bins,a_bins,Lbins, 'asfreqfilter');
    %gd_bins_e=filterbankrealdual(g_bins,a_bins,Lbins, 'econ');
    gd_linear=filterbankrealdual(g_linear,a_linear,Llinear, 'asfreqfilter');

    if 0
        % Inspect it: Dual windows, frame bounds and the response
        disp('Frame bounds scales:')
        [A,B]=filterbankbounds(g_scales,a_scales,Lscales);
        A
        B
        B/A
        filterbankresponse(g_scales,a_scales,Lscales,'real','plot');
        disp('Frame bounds bins:')
        [A,B]=filterbankrealbounds(g_bins,a_bins,Lbins);
        A
        B
        B/A
        filterbankresponse(g_bins,a_bins,Lbins,'real','plot');
        disp('Frame bounds linear:')
        [A,B]=filterbankrealbounds(g_linear,a_linear,Llinear);
        A
        B
        B/A
        filterbankresponse(g_scales,a_scales,Lscales,'real','plot');
        hold on
        filterbankresponse(g_bins,a_bins,Lbins,'real','plot');
        filterbankresponse(g_linear,a_linear,Llinear,'real','plot');
        figure; filterbankfreqz(g_scales,a_scales,Ls,fs,'plot','linabs','posfreq');
        figure; filterbankfreqz(g_bins,a_bins,Ls,fs,'plot','linabs','posfreq');
        figure; filterbankfreqz(g_linear,a_linear,Ls,fs,'plot','linabs','posfreq');
    end

    %reconstruct them all and calculate the norm to input
    c_scales = filterbank(f, g_scales, a_scales);
    fhat_scales = 2*real(ifilterbank(c_scales, gd_scales, a_scales));

    c_bins = filterbank(f, g_bins, a_bins);
    fhat_bins = 2*real(ifilterbank(c_bins, gd_bins_asf, a_bins));

    c_linear = filterbank(f, g_linear, a_linear);
    fhat_linear = 2*real(ifilterbank(c_linear, gd_linear, a_linear));

    if length(fhat_scales) > length(f)
        res_scales=norm(fhat_scales(1:length(f)) - f);
    else
        res_scales=norm(f(1:length(fhat_scales)) - fhat_scales);
    end
    if length(fhat_bins) > length(f)
        res_bins=norm(fhat_bins(1:length(f)) - f);
    else
        res_bins=norm(f(1:length(fhat_bins)) - fhat_bins);
    end
    if length(fhat_linear) > length(f)
        res_linear=norm(fhat_linear(1:length(f)) - f);
    else
        res_linear=norm(f(1:length(fhat_linear)) - fhat_linear);
    end

    %[test_failed_s,fail_s]=ltfatdiditfail(res_scales,0, 400);
    test_failed_s = 0;
    [test_failed_b,fail_b]=ltfatdiditfail(res_bins,0, 0.00001);
    [test_failed_l,fail_l]=ltfatdiditfail(res_linear,0, 0.00001);
    %s_scales=sprintf(['WAVELETFILTER DUAL SCALES:%3i %0.5g %s'],res_scales,fail_s); 
    s_bins=sprintf(['WAVELETFILTER DUAL BINS:%3i %0.5g %s'],res_bins,fail_b);
    s_linear=sprintf(['WAVELETFILTER DUAL LINEAR:%3i %0.5g %s'],res_linear,fail_l);
    %disp(s_scales);
    disp(s_bins);
    disp(s_linear);
end
