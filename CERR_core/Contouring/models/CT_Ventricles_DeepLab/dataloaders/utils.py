import matplotlib.pyplot as plt
import numpy as np
import torch

def decode_seg_map_sequence(label_masks, dataset='heart'):
    rgb_masks = []
    for label_mask in label_masks:
        rgb_mask = decode_segmap(label_mask, dataset)
        rgb_masks.append(rgb_mask)
    rgb_masks = torch.from_numpy(np.array(rgb_masks).transpose([0, 3, 1, 2]))
    return rgb_masks


def decode_segmap(label_mask, dataset, plot=False):
    """Decode segmentation class labels into a color image
    Args:
        label_mask (np.ndarray): an (M,N) array of integer values denoting
          the class label at each spatial location.
        plot (bool, optional): whether to show the resulting color image
          in a figure.
    Returns:
        (np.ndarray, optional): the resulting decoded color image.
    """
    if dataset == 'heart':
        n_classes = 10
        label_colours = get_heart_labels()
    elif dataset == 'validation':
        n_classes = 10
        label_colours = get_heart_struct_labels()
    elif dataset == 'heart_struct' or dataset == 'heart_peri' or dataset == 'heart_ventricles' or dataset == 'heart_atria':
        n_classes = 2
        label_colours = get_heart_labels()
    elif dataset == 'validation_struct' or dataset == 'validation_peri' or dataset == 'validation_ventricles' or dataset == 'validation_atria':
        n_classes = 2
        label_colours = get_heart_struct_labels()    
    else:
        raise NotImplementedError

    r = label_mask.copy()
    g = label_mask.copy()
    b = label_mask.copy()
    for ll in range(0, n_classes):
        r[label_mask == ll] = label_colours[ll, 0]
        g[label_mask == ll] = label_colours[ll, 1]
        b[label_mask == ll] = label_colours[ll, 2]
    rgb = np.zeros((label_mask.shape[0], label_mask.shape[1], 3))
    rgb[:, :, 0] = r / 255.0
    rgb[:, :, 1] = g / 255.0
    rgb[:, :, 2] = b / 255.0
    if plot:
        plt.imshow(rgb)
        plt.show()
    else:
        return rgb


def encode_segmap(mask):
    """Encode segmentation label images as pascal classes
    Args:
        mask (np.ndarray): raw segmentation label image of dimension
          (M, N, 3), in which the Pascal classes are encoded as colours.
    Returns:
        (np.ndarray): class map with dimensions (M,N), where the value at
        a given location is the integer denoting the class index.
    """
    mask = mask.astype(int)
    label_mask = np.zeros((mask.shape[0], mask.shape[1]), dtype=np.int16)
    for ii, label in enumerate(get_heart_labels()):
        label_mask[np.where(np.all(mask == label, axis=-1))[:2]] = ii
    label_mask = label_mask.astype(int)
    return label_mask

def get_heart_labels():
    # return np.array with dimensions (10,3)
    # [0,1,2,3,4,5,6,7,8,9]
    #['unlabelled', HEART', 'AORTA', 'LA', 'LV', 'RA', 'RV', 'IVC', 'SVC', 'PA']

    return np.asarray([[0, 0, 0], 
                       [128, 0, 0], [0, 128, 0], [128, 128, 0],
                       [0, 0, 128], [128, 0, 128], [0, 128, 128], [128, 128, 128],
                       [64, 0, 0], [192, 0, 0], [64, 128, 0]])

def get_heart_struct_labels():
    # return np.array with dimensions (2,3)
    # [0,1]
    #['unlabelled', HEART']

    return np.asarray([[0, 0, 0], 
                       [128, 0, 0]])
                       