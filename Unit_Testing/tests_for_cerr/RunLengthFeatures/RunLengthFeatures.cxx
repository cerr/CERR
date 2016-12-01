/* 

- This is an ITK Wrapper to calculate Run Length texture features for an image within the mask.
- This wrapper calculates Run Length Matrix (RLM) from all the voxels within the mask and hence
we obtain one set of texture features (SRE, LRE, GLN, RLN, ...) for each of the 13 directions.
- These features are written to a file named RunLengthfeatures.txt in the same directory
as the executable.
The order of the features written is: ShortRunEmphasis, LongRunEmphasis, GreyLevelNonuniformity,
RunLengthNonuniformity, LowGreyLevelRunEmphasis, HighGreyLevelRunEmphasis, ShortRunLowGreyLevelEmphasis,
ShortRunHighGreyLevelEmphasis, LongRunLowGreyLevelEmphasis, LongRunHighGreyLevelEmphasis
- Also see: testRunLength.m distributed with CERR to test features between ITK and CERR.

Author: Aditya P. Apte, Ph.D.
Memorial Sloan Kettering Cancer Center
11/30/2016

*/

#include <iostream>
#include <fstream>
#include "itkImage.h"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include <itkDenseFrequencyContainer2.h>
#include "itkRegionOfInterestImageFilter.h"
#include "itkScalarImageToRunLengthFeaturesFilter.h"
//#include "itkOffset.h"
//#include "itkImageBase.h"
//#include "itkIndex.h"
#include <cmath>

//definitions of used types
typedef itk::Image<float, 3> InternalImageType;
typedef itk::Neighborhood<float, 3> NeighborhoodType;
typedef itk::Statistics::ScalarImageToRunLengthMatrixFilter<InternalImageType>
    Image2runLengthType;
typedef Image2runLengthType::HistogramType HistogramType;
typedef itk::Statistics::HistogramToRunLengthFeaturesFilter<HistogramType> Hist2FeaturesType;
typedef InternalImageType::OffsetType OffsetType;
typedef InternalImageType::SpacingType SpacingType;

//calculate features for one offset
float * calcTextureFeatureImage (OffsetType offset,
    InternalImageType::Pointer inputImage, int numBins,
	float minVal, float maxVal, InternalImageType::Pointer maskImage)

{
    
	// Initialize an array of floats to store global features
	static float featuresV[10];

	// create an rlm generator
    Image2runLengthType::Pointer rlGenerator = Image2runLengthType::New();	

	// set offset
	rlGenerator->SetOffset(offset);
    rlGenerator->SetNumberOfBinsPerAxis(numBins); //reasonable number of bins
    rlGenerator->SetPixelValueMinMax(minVal, maxVal); //for input UCHAR pixel type  	

	// create pointer to histogram object
	Hist2FeaturesType::Pointer featureCalc = Hist2FeaturesType::New();	

	// assign image and mask to the rlm generator
	rlGenerator -> SetInput(inputImage);
	rlGenerator -> SetMaskImage(maskImage);
	
	// Assign input to the Histogram object
	featureCalc -> SetInput (rlGenerator->GetOutput());
    featureCalc -> Update();

	// set correct max distance for this direction		
	double voxelLength = 0;
	SpacingType spacing = inputImage -> GetSpacing();
	if (abs(offset[0]) == 1){
		voxelLength = spacing[0];
	}
	if (abs(offset[1]) == 1){
		voxelLength = pow(voxelLength,2) + pow(spacing[1],2);
		voxelLength = sqrt(voxelLength);
	}
	
	//if (abs(offset[2]) == 1){
	if ((offset[0]==0 || offset[1]==0) && (abs(offset[2]) == 1)){	
		voxelLength = pow(voxelLength,2) + pow(spacing[2],2);
		voxelLength = sqrt(voxelLength);
	}
	double dMax = voxelLength * numBins;
	
	// display distance set for square RLM matrix
	std::cout << "Maximum distance for: ";
	std::cout << offset << std::endl;
	std::cout << " is: ";
	std::cout << dMax << std::endl;
	

	rlGenerator -> SetDistanceValueMinMax (0,dMax);
	featureCalc -> Update();

	featuresV[0] = featureCalc->GetFeature(Hist2FeaturesType::ShortRunEmphasis); 
	featuresV[1] = featureCalc->GetFeature(Hist2FeaturesType::LongRunEmphasis); 
	featuresV[2] = featureCalc->GetFeature(Hist2FeaturesType::GreyLevelNonuniformity); 
	featuresV[3] = featureCalc->GetFeature(Hist2FeaturesType::RunLengthNonuniformity); 
	featuresV[4] = featureCalc->GetFeature(Hist2FeaturesType::LowGreyLevelRunEmphasis); 
	featuresV[5] = featureCalc->GetFeature(Hist2FeaturesType::HighGreyLevelRunEmphasis); 
	featuresV[6] = featureCalc->GetFeature(Hist2FeaturesType::ShortRunLowGreyLevelEmphasis); 
	featuresV[7] = featureCalc->GetFeature(Hist2FeaturesType::ShortRunHighGreyLevelEmphasis); 
	featuresV[8] = featureCalc->GetFeature(Hist2FeaturesType::LongRunLowGreyLevelEmphasis); 
	featuresV[9] = featureCalc->GetFeature(Hist2FeaturesType::LongRunHighGreyLevelEmphasis); 
    
	return featuresV;

}

int main(int argc, char*argv[])
{
  if(argc < 5)
    {
    std::cerr << "Usage: " << argv[0] << " Required image.mha" << std::endl;
    return EXIT_FAILURE;
    }
  
  std::string fileName = argv[1];
  std::string numBinsStr = argv[2];
  int numBins = atoi(numBinsStr.c_str());
  std::string minValStr = argv[3];
  float minVal = atof(minValStr.c_str());
  std::string maxValStr = argv[4];
  float maxVal = atof(maxValStr.c_str());
  std::string maskFileName = argv[5];

  // read image
  typedef itk::ImageFileReader<InternalImageType> ReaderType;
  ReaderType::Pointer reader=ReaderType::New();
  reader->SetFileName(fileName);
  reader->Update();
  InternalImageType::Pointer image=reader->GetOutput();

  // read mask
  ReaderType::Pointer maskReader=ReaderType::New();
  maskReader->SetFileName(maskFileName);
  maskReader->Update();
  InternalImageType::Pointer mask=maskReader->GetOutput();

  // neighborhood to get offset vectors
  NeighborhoodType neighborhood;
  neighborhood.SetRadius(1);
  unsigned int centerIndex = neighborhood.GetCenterNeighborhoodIndex();
  
  OffsetType offset;

  //typedef itk::ImageFileWriter<InternalImageType> WriterType;
  //WriterType::Pointer writer=WriterType::New();

  // initialize stream for file output
  std::ofstream outFile;
  outFile.open ("RunLengthfeatures.txt");

  // Loop over all 13 directions
  for ( unsigned int d = 0; d < centerIndex; d++ )
  {
      offset = neighborhood.GetOffset(d);

	  float * featuresV;

	  featuresV = calcTextureFeatureImage(offset, image, numBins, minVal, maxVal, mask);

	  std::cout << "Offset: " << offset << ") : ";
	  outFile << offset[0] << " " << offset[1] << " " << offset[2] << std::endl;

	  for ( int i = 0; i < 10; i++ )
	  {
		  std::cout << "*(featuresV + " << i << ") : ";
		  std::cout << *(featuresV + i) << std::endl;
		  outFile << *(featuresV + i) << "  ";
      }
	  outFile << std::endl;	
	
  }
  
  outFile.close();
  
  return EXIT_SUCCESS;
}
