import numpy as np
from PIL import Image
import os, fnmatch
from scipy.misc import toimage
from scipy import ndimage
import tensorflow as tf
import datetime
from skimage import measure
import h5py
import cv2
import time
import argparse
import sys




## Defined variables, flags
flags = tf.app.flags
FLAGS = flags.FLAGS

flags.DEFINE_integer('inference_size', 480,
                    'Size of input image in model')

flags.DEFINE_integer('num_classes', 8,
                    'Number of classes defined in model')

# flags.DEFINE_string('data_dir', '/lila/home/elguinds/DeepLab/deeplab/datasets/MRVAL',
#                     'absolute path where patient H5 scans are stored')

flags.DEFINE_string('H5_Name', 'SCAN',
                    'keyword string to find H5 files to run inference on in data_dir')

# flags.DEFINE_string('save_dir', '/lila/home/elguinds/DeepLab/deeplab/datasets/MRVAL/H5Output',
#                     'absolute path to save output MASKs, typically same folder')

flags.DEFINE_string('model_path', '/software/PROSTATE_DEEPLABV3_1.0.pb',
                    'absolute path to saved model DeepLab Model')

def normalize_array_8bit(arr):

    norm_arr = np.zeros(np.shape(arr), dtype='uint8')
    norm_arr = cv2.normalize(arr, norm_arr, 0, 255, cv2.NORM_MINMAX)
    return norm_arr

def normalize_array_16bit(arr):

    norm_arr = np.zeros(np.shape(arr), dtype='uint16')
    norm_arr = cv2.normalize(arr, norm_arr, 0, 65535, cv2.NORM_MINMAX)
    return norm_arr

def equalize_array(img, stacked_img, clahe):

    eq_img = clahe.apply(img)
    stacked_img[:, :, 0] = eq_img
    stacked_img[:, :, 1] = eq_img
    stacked_img[:, :, 2] = eq_img

    return eq_img, stacked_img.astype('uint8')

def find(pattern, path):
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
    return result

def pad_with(vector, pad_width, iaxis, kwargs):
    pad_value = kwargs.get('padder', 0)
    vector[:pad_width[0]] = pad_value
    vector[-pad_width[1]:] = pad_value
    return vector

def find_file(name, path):
    for root, dirs, files in os.walk(path):
        if name in files:
            return os.path.join(root, name)

def clean_mask(mask, class_num):

    i = 1
    height, width = np.shape(mask)
    for c in class_num:
        binary_img = np.where(mask == c, mask, 0)
        binary_img[binary_img > 0] = 1
        img_cleaned = ndimage.binary_opening(binary_img).astype(int)
        img_cleaned_smoothed = ndimage.gaussian_filter(img_cleaned, sigma=0.1)
        img_cleaned_smoothed[img_cleaned_smoothed > 0] = c
        if i == 1:
            mask_cleaned = img_cleaned_smoothed
        else:
            mask_cleaned = mask_cleaned + img_cleaned_smoothed
        i = i + 1

    return mask_cleaned

## DeepLabV3 class, uses frozen graph to load weights, make predictions
class DeepLabModel(object):
    """Class to load deeplab model and run inference."""

    INPUT_TENSOR_NAME = 'ImageTensor:0'
    OUTPUT_TENSOR_NAME = 'SemanticPredictions:0'
    INPUT_SIZE = FLAGS.inference_size

    def __init__(self, tarball_path):
        """Creates and loads pretrained deeplab model."""
        self.graph = tf.Graph()

        graph_def = None
        # Extract frozen graph from tar archive.
        file_handle = open(tarball_path, 'rb')
        print("tarball path")
        print(tarball_path)
        graph_def = tf.GraphDef.FromString(file_handle.read())

        if graph_def is None:
            raise RuntimeError('Cannot find inference graph in tar archive.')

        with self.graph.as_default():
            tf.import_graph_def(graph_def, name='')

        self.sess = tf.Session(graph=self.graph)

    def run(self, image):
        """Runs inference on a single image.

        Args:
            image: A PIL.Image object, raw input image.

        Returns:
            resized_image: RGB image resized from original input image.
            seg_map: Segmentation map of `resized_image`.
        """
        width, height = image.size
        resize_ratio = 1.0 * self.INPUT_SIZE / max(width, height)
        target_size = (int(resize_ratio * width), int(resize_ratio * height))
        resized_image = image.convert('RGB').resize(target_size, Image.ANTIALIAS)
        batch_seg_map = self.sess.run(
            self.OUTPUT_TENSOR_NAME,
            feed_dict={self.INPUT_TENSOR_NAME: [np.asarray(resized_image)]})
        seg_map = batch_seg_map[0]
        return resized_image, seg_map

def main(argv):

    data_path = '/scratch/inputH5/'
    save_dir = '/scratch/outputH5/'

    print("assignment of paths successful")
    print(data_path)
    print(save_dir)

    #data_path = FLAGS.data_dir
    keyword = FLAGS.H5_Name
    files = find(keyword + '*.h5', data_path)

    #save_dir = FLAGS.save_dir
    infer_size = FLAGS.inference_size
    class_num = np.arange(1,FLAGS.num_classes,1)
    clahe = cv2.createCLAHE(clipLimit=10, tileGridSize=(8, 8))
    print("verifying model path")
    print(FLAGS.model_path)
    model = DeepLabModel(FLAGS.model_path)
    print(FLAGS.model_path)


    for filename in files:
        print(filename)
        s = h5py.File(filename, 'r')
        scan = s['scan'][:]
        scan = np.flipud(np.rot90(scan, axes=(0, 2)))
        print('Loaded SCAN array...')
        path, file = os.path.split(filename)
        print(file.replace(keyword,'MASK'))
        height, width, length = np.shape(scan)

        # crop is left, top, right bottom
        if infer_size == height:
            crop = np.zeros((1, 4)).astype(int)
            crop[0, :] = [0, 0, infer_size, infer_size]
            pad_size = 0

        elif infer_size < height:
            crop = np.zeros((1, 4)).astype(int)
            tp = int(height / 2) - int(infer_size / 2)
            btm = int(height / 2) + int(infer_size / 2)
            crop[0, :] = [tp, tp, btm, btm]
            pad_size = 0
        else:
            crop = np.zeros((1, 4)).astype(int)
            pad_size = int(infer_size / 2) - int(height / 2)
            crop[0, :] = [0, 0, infer_size, infer_size]

        num_crop = np.shape(crop)[0]

        ## Determine maximized WL for normalized scan
        scan_norm = normalize_array_16bit(scan).astype('uint16')
        scan_norm_8 = normalize_array_8bit(scan).astype('uint8')

        print('Computing DeepLab Model...')
        start_time = time.time()
        mask = np.zeros((height, width, length), dtype=np.uint8 )

        for i in range(0,length-1):
            img = scan_norm_8[:,:,i]
            img_16 = scan_norm[:,:,i]
            height, width = np.shape(img)
            stacked_img_1_mid = np.zeros((height, width, 3), dtype=np.uint8)
            stacked_img_1_org = np.zeros((height, width, 3), dtype=np.uint16)
            eq_img, stacked_img_1_mid = equalize_array(img.astype('uint8'), stacked_img_1_mid, clahe)

            ## Previous################################################################################################
            img_prv = scan_norm_8[:,:,i-1]
            stacked_img_1_prv = np.zeros((height, width, 3), dtype=np.uint8)
            eq_img, stacked_img_1_prv = equalize_array(img_prv.astype('uint8'), stacked_img_1_prv, clahe)
            ###################################################################################################

            ## Ahead#######################################################################################################
            img_ahd = scan_norm_8[:,:,i+1]
            stacked_img_1_ahd = np.zeros((height, width, 3), dtype=np.uint8)
            eq_img_ahd, stacked_img_1_ahd = equalize_array(img_ahd.astype('uint8'), stacked_img_1_ahd, clahe)
            ################################################################################################

            left = crop[0, 0]
            top = crop[0, 1]
            right = crop[0, 2]
            bottom = crop[0, 3]
            stacked_img_1 = np.zeros((infer_size, infer_size, 3), dtype=np.uint8)

            if infer_size <= height:
                stacked_img_1[:, :, 0] = toimage(img_ahd.astype('uint8')).crop( ( left, top, right, bottom ) )
                stacked_img_1[:, :, 1] = toimage(255 - img.astype('uint8')).crop( ( left, top, right, bottom ) )
                stacked_img_1[:, :, 2] = toimage(img_prv.astype('uint8')).crop( ( left, top, right, bottom ) )
            else:
                stacked_img_1[:, :, 0] = np.pad(img_ahd.astype('uint8'),pad_size,pad_with)
                stacked_img_1[:, :, 1] = np.pad(255 - img.astype('uint8'),pad_size,pad_with)
                stacked_img_1[:, :, 2] = np.pad(img_prv.astype('uint8'),pad_size,pad_with)

            image = toimage(stacked_img_1[:,:,:], cmin=0, cmax=255)
            ## Loop through parts of image, if image crop > 1
            for j in range(0,num_crop):
                left = crop[j,0]
                top = crop[j,1]
                right = crop[j,2]
                bottom = crop[j,3]
                image_crop = image
                height_resize, width, length = np.shape(image_crop)
                r_im, seg = model.run(image_crop)
                s = Image.fromarray(seg.astype('uint8'))
                m = s.resize((height_resize, width), Image.ANTIALIAS)
                if infer_size <= height:
                    mask[top:bottom,left:right, i] = m
                else:
                    mask[:, :, i] = m.crop((top+pad_size,left+pad_size, right-pad_size, bottom-pad_size))

        print("--- inference took %s seconds ---" % (time.time() - start_time))
        maskfilename = file.replace(keyword, 'MASK')
        with h5py.File(os.path.join(save_dir, maskfilename), 'w') as hf:
            hf.create_dataset("mask", data=mask)
        # os.remove(filename)
        sys.exit()
if __name__ == '__main__':
  tf.app.run()