#All Imports


input_size = 512

#function to look for h5 files in the given directory
def find(pattern, path):
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
    return result


#main function takes in 2 arguments; path of input data h5 files and the path to save segmented mask output in H5 format
#name of the input h5 file cantains "SCAN" in it
def main(argv):

    inputH5Path = sys.argv[1][5:]
    outputH5Path = sys.argv[2][5:]

    #print contents of inputH5Path
    print()
    #this looks for all the h5 files that contain "SCAN" in the provided input H5 directory
    keyword = 'SCAN'
    files = find(keyword + '*.h5', inputH5Path)


    #load model and weights here
    model3 = get_incr_FRRN()

    with open(
            '/software/model_5l_lung-frrn_incremental_up_res_all_tf_drop_weight_residual_512.json') as model_file:
        model3 = models.model_from_json(model_file.read())
    print('weight test:OK')

    model3.load_weights('/software/weights.15--0.71.hdf5')
    print('finish tesing loading weight')


    #loop over the h5 files in the directory specified, run the prediction, and save the final 3d mask here
    for filename in files:

        s = h5py.File(filename, 'r')
        original_scan = s['scan'][:]
        original_scan = np.flipud(np.rot90(original_scan, axes=(0, 2)))
        print('Loaded SCAN array...')

        #data resizing, augmentation, etc happens here
        height, width, length = np.shape(original_scan)
        scan = original_scan

        scan = np.expand_dims(scan, 0)
        scan = np.moveaxis(scan, 3, 0)
        scan = np.moveaxis(scan, 1, 3)
        scan = scan.reshape(len(scan), 1, input_size, input_size)

        len_scan = scan.shape[0]

        final_mask = np.zeros((input_size, input_size, length), dtype=np.uint8)
        result_color = np.zeros((csize, csize, 3), dtype=np.uint8)

        print('start inference')

        for id in range(1, len_scan):

            aa = np.zeros((input_size, input_size))
            aa = scan[id]
            b = aa.reshape(1, input_size, input_size, 1)
            res = model3.predict([b], verbose=0,
                                 batch_size=1)  # predict the label/segmentation, below code is just showing and saving
            imgs_mask_test = res[0]
            imgs_mask_test1 = imgs_mask_test.reshape(csize, csize)
            result_color[:, :, 0] = imgs_mask_test1 * 255
            imgs_mask_test1 = np.where(imgs_mask_test1 > 0.1, 1, 0)
            final_mask[:, :, id] = imgs_mask_test1

        #save the final 3d mask at the provided location
        path, file = os.path.split(filename)
        maskfilename = file.replace(keyword, 'MASK')

        #write result to h5 file
        with h5py.File(os.path.join(outputH5Path, maskfilename), 'w') as hf:
            hf.create_dataset("mask", data=final_mask)


if __name__ == "__main__":
    main(sys.argv)