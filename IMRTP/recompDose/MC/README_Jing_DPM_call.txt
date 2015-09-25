DPM_call('/data/vanessa/work/results/prioptTuning/case43_1cmblts_QIBwMargin_0.005_0.015_slip0p005_wMinMeanPTVDose2_res_wLS.mat', 3, 400000, 100003, 1, 11.2)

% Apr. 9 2008
% To explore the speed issue.
DPM_call('/data/vanessa/AA_debug/LongTime/case43_1cmblts_QIBwMarginPTVOnly_downsample.mat', 3, 1000000, 100001, 1, 11.2)

mex -v -output dpm DPMgateway.f dpm.f getnam.f libeloss.f libgeom.f libmath.f libpenmath.f libphoton.f time.f

diary ('Jing_test_case43_bm3.out')
>> diary on
DPM_call('/data/vanessa/AA_debug/LongTime/case43_1cmblts_QIBwMarginPTVOnly_downsample.mat', 3, 1000000, 100001, 1, 11.2)
% Need to use diary off.

time: 11:30pm

diary ('Jing_test_case43_bm5.out')
>> diary on

test bm 1, 3, 5, nhist = 1M. batch = 100001;