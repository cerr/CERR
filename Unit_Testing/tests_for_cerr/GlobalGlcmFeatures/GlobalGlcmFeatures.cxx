/* 

- This is an ITK Wrapper to calculate GLCM texture features for an image within the mask.
- This wrapper calculates GLCM matrix from all the voxels within the mask and hence
we obtain one set of Haralick texture features (energy, entropy, inverseDiffMoment, ...)
for each of the 13 directions.
- These features are written to a file named GlobalGlCMfeatures.txt in the same directory
as the executable.
The order of the features written is: Energy, Entropy, Correlation, InverseDifferenceMoment,
Inertia, ClusterShade, ClusterProminence, HaralickCorrelation
- Also see: testGlobalGLCM.m distributed with CERR to test features between ITK and CERR.

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
#include "itkHistogramToTextureFeaturesFilter.h"
#include "itkScalarImageToCooccurrenceMatrixFilter.h"
#include "itkVectorContainer.h"
#include "itkAddImageFilter.h"
#include "itkMultiplyImageFilter.h"
#include "itkRegionOfInterestImageFilter.h"

//definitions of used types
typedef itk::Image<float, 3> InternalImageType;
typedef itk::Image<float, 3> VisualizingImageType;
typedef itk::Neighborhood<float, 3> NeighborhoodType;
typedef itk::Statistics::ScalarImageToCooccurrenceMatrixFilter<InternalImageType>
    Image2CoOccuranceType;
typedef Image2CoOccuranceType::HistogramType HistogramType;
typedef itk::Statistics::HistogramToTextureFeaturesFilter<HistogramType> Hist2FeaturesType;
typedef InternalImageType::OffsetType OffsetType;
typedef itk::AddImageFilter <InternalImageType> AddImageFilterType;
typedef itk::MultiplyImageFilter<InternalImageType> MultiplyImageFilterType;

//calculate features for one offset
float * calcTextureFeatureImage (OffsetType offset,
    InternalImageType::Pointer inputImage, int numBins, float minVal, float maxVal, InternalImageType::Pointer mask)

{
    
	// Initialize an array of floats to store global features
	static float featuresV[8];

    Image2CoOccuranceType::Pointer glcmGenerator=Image2CoOccuranceType::New();
    glcmGenerator->SetOffset(offset);
    glcmGenerator->SetNumberOfBinsPerAxis(numBins); //reasonable number of bins
    glcmGenerator->SetPixelValueMinMax(minVal, maxVal); //for input UCHAR pixel type
    Hist2FeaturesType::Pointer featureCalc=Hist2FeaturesType::New();

    typedef itk::RegionOfInterestImageFilter<InternalImageType,InternalImageType> roiType;
    roiType::Pointer roi=roiType::New();
    roi->SetInput(inputImage);

	glcmGenerator -> SetInput(inputImage);
	glcmGenerator -> SetMaskImage(mask);
    glcmGenerator->Update();
    featureCalc->SetInput( glcmGenerator->GetOutput() );
    featureCalc->Update();

	featuresV[0] = featureCalc->GetFeature(Hist2FeaturesType::Energy); // Energy
	featuresV[1] = featureCalc->GetFeature(Hist2FeaturesType::Entropy); // Entropy
	featuresV[2] = featureCalc->GetFeature(Hist2FeaturesType::Correlation); // Correlation
	featuresV[3] = featureCalc->GetFeature(Hist2FeaturesType::InverseDifferenceMoment); // InverseDifferenceMoment
	featuresV[4] = featureCalc->GetFeature(Hist2FeaturesType::Inertia); // Inertia
	featuresV[5] = featureCalc->GetFeature(Hist2FeaturesType::ClusterShade); // ClusterShade
	featuresV[6] = featureCalc->GetFeature(Hist2FeaturesType::ClusterProminence); // ClusterProminence
	featuresV[7] = featureCalc->GetFeature(Hist2FeaturesType::HaralickCorrelation); // HaralickCorrelation
 
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

  // create 13 offsets
  NeighborhoodType neighborhood;
  neighborhood.SetRadius(1);
  unsigned int centerIndex = neighborhood.GetCenterNeighborhoodIndex();

  // initialize offset var
  OffsetType offset;

  // initialize stream for file output
  std::ofstream outFile;
  outFile.open ("GlobalGlCMfeatures.txt");

  // Loop over all 13 directions and write features to file
  for ( unsigned int d = 0; d < centerIndex; d++ )
  {
      offset = neighborhood.GetOffset(d);

	  float * featuresV;

	  featuresV = calcTextureFeatureImage(offset, image, numBins, minVal, maxVal, mask);

	  std::cout << "Offset: " << offset << ") : ";
	  outFile << offset[0] << " " << offset[1] << " " << offset[2] << std::endl;

	  for ( int i = 0; i < 8; i++ )
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
