function eqScaledDoseC = frxCorrectROE(modelParS,strNumV,numFrx,scaledDoseC)
% Function to perform fractionation correction for dosimetric models in ROE
%
% AI 12/16/2020
  
  if strcmpi(modelParS.fractionCorrect,'yes') 
    eqScaledDoseC = cell(1,numel(strNumV));
    switch lower((modelParS.correctionType))
      case 'fsize'
        %Convert to EQD in std fraction size
        stdFrxSize = modelParS.stdFractionSize;
        for s = 1:numel(strNumV)
          scaledFrxSizeV = scaledDoseC{s}/numFrx;
          eqScaledDoseC{s} = scaledDoseC{s} .*(scaledFrxSizeV+modelParS.abRatio)...
          ./(stdFrxSize + modelParS.abRatio);
        end
      case 'nfrx'
        %Convert to standard no. fractions
        Na = numFrx;
        Nb = modelParS.stdNumFractions;
        a = Na;
        b = Na*Nb*modelParS.abRatio;
        for s = 1:numel(strNumV)
          scaledDoseBinsV = scaledDoseC{s};
          c = -scaledDoseBinsV.*(b + scaledDoseBinsV*Nb);
          eqScaledDoseC{s}= (-b + sqrt(b^2 - 4*a*c))/(2*a);
        end 
      end
    else
      eqScaledDoseC = scaledDoseC;
    end
    
  end