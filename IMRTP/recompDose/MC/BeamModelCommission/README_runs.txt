% For primary photon:
runBinEnergy 6 10 24 4 0 27 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166

% For flattening filter components.
runBinEnergy 6 10 24 0 0 13 0 0 1 -0.213 -0.1 9.5 0 1 4000000 256 256 166

% For electron contamination.
runBinEnergy 6 10 24 4 0 0 0 0 1 -0.213 -0.1 9.5 -1 1 4000000 256 256 166


%% Sept 25, 2007
====================
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 0 3 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin0_3.out &
[6] 30836
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 4 7 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin4_7.out &
[7] 30868
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 8 11 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin8_11.out &
[8] 30900
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 12 15 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin12_15.out &
[9] 30932
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 16 19 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin16_19.out &
[10] 30964
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 20 23 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin20_23.out &
[11] 30996
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 24 27 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin24_27.out &
[12] 31028
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 28 31 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin28_31.out &
[13] 31060
[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 32 35 0 0 0 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > Primary_Bin32_35.out &
[14] 31092
[jcui@bmp2 MC]$ date
Tue Sep 25 17:39:57 CDT 2007

[jcui@bmp2 MC]$ nohup ./runBinEnergy 6 10 24 20 0 3 0 0 1 -0.213 -0.1 9.5 0 1 4000000 256 256 166 > FF_Bin0_3.out &


% Run Electon 
[jcui@bmp2 MC]$ nohup ./runBinEnergy 18 10 12 28 0 0 0 0 1 -0.774 -0.00508 9.5 -1 1 4000000 256 256 166 > Elec_18MV.out &
[20] 5792

