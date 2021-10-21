import surface_distance


def main(mask_gt, mask_pred, spacing_mm, tolerance_mm):
    surf_dists = surface_distance.compute_surface_distances(
        mask_gt, mask_pred, spacing_mm)
    surf_dists_tol = surface_distance.compute_surface_dice_at_tolerance(surf_dists, tolerance_mm)
    return surf_dists_tol
