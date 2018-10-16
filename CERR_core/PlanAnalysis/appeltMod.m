function [D50Risk, gamma50Risk] = appeltMod(D50_0, gamma50_0,OR)
%
% Usage :  [D50, gamma50] = appeltMod(paramS)
%
% This function applies modification to D50_0 and gamma50_0 values by taking
% into account the odds ratio (OR).
%
% The modification is based on Appelt et al.
%
% Ane L. Appelt, Ivan R. Vogelius, Katherina P. Farr, Azza A. Khalil & Søren
% M. Bentzen (2014) Towards individualized dose constraints: Adjusting the QUANTEC
% radiation pneumonitis model for clinical risk factors, Acta Oncologica, 53:5, 605-612,
% DOI: 10.3109/0284186X.2013.820341
%
% APA, 2/15/2017
% AI 2/21/17
% AI 10/8/18 : Added inputs: D50_0, gamma50_0.

%Return modified D50, gamma50
D50Risk = (1 - log(OR)/(4*gamma50_0)) * D50_0;

gamma50Risk = gamma50_0 - log(OR)/4;

