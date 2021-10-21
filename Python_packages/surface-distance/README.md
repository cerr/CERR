# Surface distance metrics

## Summary
When comparing multiple image segmentations, performance metrics that assess how closely the surfaces align can be a useful difference measure. This group of surface distance based measures computes the closest distances from all surface points on one segmentation to the points on another surface, and returns performance metrics between the two. This distance can be used alongside other metrics to compare segmented regions against a ground truth.

Surfaces are represented using surface elements with corresponding area, allowing for more consistent approximation of surface measures.

## Metrics included
This library computes the following performance metrics for segmentation:

- Average surface distance (see `compute_average_surface_distance`)
- Hausdorff distance (see `compute_robust_hausdorff`)
- Surface overlap (see `compute_surface_overlap_at_tolerance`)
- Surface dice (see `compute_surface_dice_at_tolerance`)
- Volumetric dice (see `compute_dice_coefficient`)

## Dependecies
- numpy  
- scipy  
- math  

## Installation
First clone the repo, then install dependencies 

```shell
$ git clone https://github.com/cerr/CERR.git
```

## Usage  
  
1. Example 1: 3D surface dice  
  
mask_gt = np.zeros((128, 128, 128), np.bool)  
mask_pred = np.zeros((128, 128, 128), np.bool)  
mask_gt[50, 60, 70] = 1  
mask_pred[50, 60, 72] = 1  
spacing_mm=(3, 2, 1)  
tol = 1  
  
val = get_surf_dist3d.main(mask_gt, mask_pred, spacing_mm, tol)  #Expected val: 0.5  
  
  
  
For other usage examples, see `surface_distance_test.py`.
