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
void calcTextureFeatureImage (OffsetType offset,
    InternalImageType::Pointer inputImage, InternalImageType::Pointer outEnergy,
	InternalImageType::Pointer outEntropy, InternalImageType::Pointer outCorrelation,
	InternalImageType::Pointer outDiffMoment, InternalImageType::Pointer outInertia,
	InternalImageType::Pointer outClustShade, InternalImageType::Pointer outClustProm,
	InternalImageType::Pointer outHaralCorr, int numBins, float minVal, float maxVal, int patchRadius)

{
    //allocate output images
    
	outEnergy->CopyInformation(inputImage);
    outEnergy->SetRegions(inputImage->GetLargestPossibleRegion());
    outEnergy->Allocate();
    outEnergy->FillBuffer(0);

	outEntropy->CopyInformation(inputImage);
    outEntropy->SetRegions(inputImage->GetLargestPossibleRegion());
    outEntropy->Allocate();
    outEntropy->FillBuffer(0);

    outCorrelation->CopyInformation(inputImage);
    outCorrelation->SetRegions(inputImage->GetLargestPossibleRegion());
    outCorrelation->Allocate();
    outCorrelation->FillBuffer(0);    

	outDiffMoment->CopyInformation(inputImage);
    outDiffMoment->SetRegions(inputImage->GetLargestPossibleRegion());
    outDiffMoment->Allocate();
    outDiffMoment->FillBuffer(0);

	outInertia->CopyInformation(inputImage);
    outInertia->SetRegions(inputImage->GetLargestPossibleRegion());
    outInertia->Allocate();
    outInertia->FillBuffer(0);

	outClustShade->CopyInformation(inputImage);
    outClustShade->SetRegions(inputImage->GetLargestPossibleRegion());
    outClustShade->Allocate();
    outClustShade->FillBuffer(0);

	outClustProm->CopyInformation(inputImage);
    outClustProm->SetRegions(inputImage->GetLargestPossibleRegion());
    outClustProm->Allocate();
    outClustProm->FillBuffer(0);

	outHaralCorr->CopyInformation(inputImage);
    outHaralCorr->SetRegions(inputImage->GetLargestPossibleRegion());
    outHaralCorr->Allocate();
    outHaralCorr->FillBuffer(0);

    Image2CoOccuranceType::Pointer glcmGenerator=Image2CoOccuranceType::New();
    glcmGenerator->SetOffset(offset);
    glcmGenerator->SetNumberOfBinsPerAxis(numBins); //reasonable number of bins
    glcmGenerator->SetPixelValueMinMax(minVal, maxVal); //for input UCHAR pixel type
    Hist2FeaturesType::Pointer featureCalc=Hist2FeaturesType::New();

    typedef itk::RegionOfInterestImageFilter<InternalImageType,InternalImageType> roiType;
    roiType::Pointer roi=roiType::New();
    roi->SetInput(inputImage);

    InternalImageType::RegionType window;
    InternalImageType::RegionType::SizeType size;
	int windowSize;
	windowSize = 2*patchRadius + 1;
    size.Fill(windowSize); //window size=3x3x3
    window.SetSize(size);
    InternalImageType::IndexType pi; //pixel index
    
    //slide window over the entire image
    for (unsigned x=patchRadius; x<inputImage->GetLargestPossibleRegion().GetSize(0)-patchRadius; x++)
    {
        pi.SetElement(0,x);
        window.SetIndex(0,x-patchRadius);
        for (unsigned y=patchRadius; y<inputImage->GetLargestPossibleRegion().GetSize(1)-patchRadius; y++)
        {
            pi.SetElement(1,y);
            window.SetIndex(1,y-patchRadius);
            for (unsigned z=patchRadius; z<inputImage->GetLargestPossibleRegion().GetSize(2)-patchRadius; z++)
            {
                pi.SetElement(2,z);
                window.SetIndex(2,z-patchRadius);
                roi->SetRegionOfInterest(window);
                roi->Update();
                glcmGenerator->SetInput(roi->GetOutput());
                glcmGenerator->Update();
                featureCalc->SetInput( glcmGenerator->GetOutput() );
                featureCalc->Update();

                outEnergy->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::Energy));
				outEntropy->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::Entropy));
				outCorrelation->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::Correlation));
				outDiffMoment->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::InverseDifferenceMoment));
				outInertia->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::Inertia));                
				outClustShade->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::ClusterShade)); 
				outClustProm->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::ClusterProminence)); 
				outHaralCorr->SetPixel(pi, featureCalc->GetFeature(Hist2FeaturesType::HaralickCorrelation));
				
            }
        }
        std::cout<<'.';
    }
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
  std::string patchRadStr = argv[5];
  int patchRadius = atoi(patchRadStr.c_str());
  
  typedef itk::ImageFileReader<InternalImageType> ReaderType;
  ReaderType::Pointer reader=ReaderType::New();
  reader->SetFileName(fileName);
  reader->Update();
  InternalImageType::Pointer image=reader->GetOutput();

  NeighborhoodType neighborhood;
  neighborhood.SetRadius(1);
  unsigned int centerIndex = neighborhood.GetCenterNeighborhoodIndex();
  OffsetType offset;

  typedef itk::ImageFileWriter<InternalImageType> WriterType;
  WriterType::Pointer writer=WriterType::New();

  for ( unsigned int d = 0; d < centerIndex; d++ )
  {
      offset = neighborhood.GetOffset(d);

	  // initialize all 8 texture features
      InternalImageType::Pointer energy = InternalImageType::New();
	  InternalImageType::Pointer entropy = InternalImageType::New();	  
      InternalImageType::Pointer correlation = InternalImageType::New();
	  InternalImageType::Pointer diffMoment = InternalImageType::New();
	  InternalImageType::Pointer inertia = InternalImageType::New();
	  
	  InternalImageType::Pointer clusterShade = InternalImageType::New();
	  InternalImageType::Pointer clusterProm = InternalImageType::New();
	  InternalImageType::Pointer haralickCorrelation = InternalImageType::New();

      calcTextureFeatureImage(offset, image, energy, entropy, correlation, 
		  diffMoment, inertia, clusterShade, clusterProm, 
		  haralickCorrelation, numBins, minVal, maxVal,patchRadius);
            
//	snprintf(buf, 100, "Inertia%u.mha", d); // Warning: call to int __builtin___snprintf_chk will always overflow destination buffer
      
      writer->SetInput(energy);
      std::stringstream ssEnergy;
      ssEnergy << "Energy" << d << ".mha";
      writer->SetFileName(ssEnergy.str());
      writer->Update();
      std::cout<<'\n';

      writer->SetInput(entropy);
      std::stringstream ssEntropy;
      ssEntropy << "Entropy" << d << ".mha";
      writer->SetFileName(ssEntropy.str());
      writer->Update();
      std::cout<<'\n';
	  
      writer->SetInput(correlation);
      std::stringstream ssCorrelation;
      ssCorrelation << "Correlation" << d << ".mha";
      writer->SetFileName(ssCorrelation.str());
      writer->Update();
	  std::cout<<'\n';
	  
      writer->SetInput(diffMoment);
      std::stringstream ssdiffMoment;
      ssdiffMoment << "DiffMoment" << d << ".mha";
      writer->SetFileName(ssdiffMoment.str());
      writer->Update();
	  std::cout<<'\n';

	  writer->SetInput(inertia);
	  std::stringstream ssInertia;
      ssInertia << "Inertia" << d << ".mha";
      writer->SetFileName(ssInertia.str());
      writer->Update();
	  std::cout<<'\n';

      writer->SetInput(clusterShade);
      std::stringstream ssclusterShade;
      ssclusterShade << "ClusterShade" << d << ".mha";
      writer->SetFileName(ssclusterShade.str());
      writer->Update();
	  std::cout<<'\n';

      writer->SetInput(clusterProm);
      std::stringstream ssclusterProm;
      ssclusterProm << "ClusterProminence" << d << ".mha";
      writer->SetFileName(ssclusterProm.str());
      writer->Update();
	  std::cout<<'\n';

      writer->SetInput(haralickCorrelation);
      std::stringstream ssharalickCorrelation;
      ssharalickCorrelation << "HaralickCorrelation" << d << ".mha";
      writer->SetFileName(ssharalickCorrelation.str());
      writer->Update();
	  std::cout<<'\n';

  }

  return EXIT_SUCCESS;
}
