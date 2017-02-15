function [D50, gamma50] = appeltMod(s,OR,D50,gamma50)
%
% function [D50, gamma50] = appeltMod(s,OR,D50,gamma50)
%
% This function applies modification to D50 and gamma50 values by taking
% into account the prevalence (s) and the odds ratio (OR).
%
% The modification is based on Appelt et al.
%
% Ane L. Appelt, Ivan R. Vogelius, Katherina P. Farr, Azza A. Khalil & Søren
% M. Bentzen (2014) Towards individualized dose constraints: Adjusting the QUANTEC
% radiation pneumonitis model for clinical risk factors, Acta Oncologica, 53:5, 605-612,
% DOI: 10.3109/0284186X.2013.820341
%
% APA, 2/15/2017

P = 1/2 * (1 + s * (OR-1)/(OR+1));

D50 = (1 + 1/4 * log(P/(1-P))/gamma50) * D50;

gamma50 = s*P*(1-P)/(s-(2*P-1)^2) * (log(P/(1-P)) + 4*gamma50);
