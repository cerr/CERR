import sys, os
import numpy as np
from matplotlib import pyplot as plt
from scipy.io import loadmat
from skimage import io

#os.environ['KERAS_BACKEND'] = 'theano'  
#os.environ['THEANO_FLAGS'] = 'mode=FAST_RUN, device=gpu0, floatX=float32,optimizer=fast_compile,assert_no_cpu_op=raise,#print_global_stats=True'#pycuda.init=true'
from keras.preprocessing.image import (transform_matrix_offset_center, apply_transform, Iterator,
                                       random_channel_shift, flip_axis)
from scipy.ndimage.interpolation import map_coordinates
from scipy.ndimage.filters import gaussian_filter
import scipy

_dir = os.path.join(os.path.realpath(os.path.dirname(__file__)), '')
data_path = os.path.join(_dir, '../')
aug_data_path = os.path.join(_dir, 'aug_data')
aug_pattern = os.path.join('/lila/home/jiangj1/data/data_tianchi_test/train_out/images_train1.npy')
aug_mask_pattern = os.path.join('/lila/home/jiangj1/data/data_tianchi_test/train_out/label_train1.npy')

#X = np.load('/lila/home/jiangj1/data/nlsl_5fold/val/val_fold_3_img.npy') # fine
#Y = np.load('/lila/home/jiangj1/data/nlsl_5fold/val/val_fold_3_label.npy') # fine
    ##print(X[1389:].shape)
#X1=X[1380:1381]
#Y1=Y[1380:1381]
#xx=np.reshape(X1,(256,256))
#yy=np.reshape(Y1,(256,256))
#scipy.misc.toimage(xx, cmin=0.0, cmax=255).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_ori.png')
#scipy.misc.toimage(yy).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_ori.png')
#img_noisy = xx + 0.15 * xx.std() * np.random.random(xx.shape)
#scipy.misc.toimage(img_noisy).save('/lila/home/jiangj1/data/data_tianchi_test/img_noise.png')
#img=np.array(loadmat('/lila/home/jiangj1/data/data_tianchi_test/img_LUNG1-001_12.mat')['cImg_ori']).astype('float32')
#img=scipy.misc.imresize(img,(256,256))
def random_zoom(x, y, zoom_range, row_index=1, col_index=2, channel_index=0,
                fill_mode='nearest', cval=0.):
    if len(zoom_range) != 2:
        raise Exception('zoom_range should be a tuple or list of two floats. '
                        'Received arg: ', zoom_range)

    if zoom_range[0] == 1 and zoom_range[1] == 1:
        zx, zy = 1, 1
    else:
        zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
    zoom_matrix = np.array([[zx, 0, 0],
                            [0, zy, 0],
                            [0, 0, 1]])

    h, w = x.shape[row_index], x.shape[col_index]
    transform_matrix = transform_matrix_offset_center(zoom_matrix, h, w)
    x = apply_transform(x, transform_matrix, channel_index, fill_mode, cval)
    y = apply_transform(y, transform_matrix, channel_index, fill_mode, cval)
    return x, y


def random_rotation(x, y, rg, row_index=1, col_index=2, channel_index=0,
                    fill_mode='nearest', cval=0.):
    theta = np.pi / 180 * np.random.uniform(-rg, rg)
    rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                [np.sin(theta), np.cos(theta), 0],
                                [0, 0, 1]])

    h, w = x.shape[row_index], x.shape[col_index]
    transform_matrix = transform_matrix_offset_center(rotation_matrix, h, w)
    x = apply_transform(x, transform_matrix, channel_index, fill_mode, cval)
    y = apply_transform(y, transform_matrix, channel_index, fill_mode, cval)
    return x, y


def random_shear(x, y, intensity, row_index=1, col_index=2, channel_index=0,
                 fill_mode='constant', cval=0.):
    shear = np.random.uniform(-intensity, intensity)
    shear_matrix = np.array([[1, -np.sin(shear), 0],
                             [0, np.cos(shear), 0],
                             [0, 0, 1]])

    h, w = x.shape[row_index], x.shape[col_index]
    transform_matrix = transform_matrix_offset_center(shear_matrix, h, w)
    x = apply_transform(x, transform_matrix, channel_index, fill_mode, cval)
    y = apply_transform(y, transform_matrix, channel_index, fill_mode, cval)
    return x, y


class CustomNumpyArrayIterator(Iterator):

    def __init__(self, X, y, image_data_generator,
                 batch_size=32, shuffle=False, seed=None,
                 dim_ordering='th'):
        self.X = X
        self.y = y
        self.image_data_generator = image_data_generator
        self.dim_ordering = dim_ordering
        super(CustomNumpyArrayIterator, self).__init__(X.shape[0], batch_size, shuffle, seed)


    def next(self):
        with self.lock:
            index_array, _, current_batch_size = next(self.index_generator)
        #batch_x = np.zeros(tuple([current_batch_size] + list(self.X.shape)[1:]))
        batch_x   =  []
        batch_y_1 =  []
        for i, j in enumerate(index_array):
            ##print ( ' i is ', i)
            ##print (' j is ',j)
            x = self.X[j]
            
            y1 = self.y[j]
            #y2 = self.y[1]
            ##print (y1.shape)
            ##print (y2.shape)
            ##print (x.shape)
            _x, _y1 = self.image_data_generator.random_transform(x.astype('float32'), y1.astype('float32'))
            _x_resp=np.array(_x)
            np.reshape(_x_resp,(1,1,256,256))
            _y_resp=np.array(_y1)
            np.reshape(_y_resp,(1,1,256,256))
            batch_x.append(_x_resp)
            batch_y_1.append(_y_resp)
            #batch_y_2.append(y2)
            ##print (batch_x.shape)
            ##print ('....')
            ##print (batch_y_1.shape)
        batch_x=np.array(batch_x)
        batch_y_1=np.array(batch_y_1)
        #batch_y_1=np.array(batch_y_1)
        batch_x=np.reshape((batch_x),(len(batch_x),256,256,1))
        batch_y_1=np.reshape((batch_y_1),(len(batch_y_1),256,256,1))
        #print (batch_x.shape)
        ##print ('....')
        #print (batch_y_1.shape)     
        return batch_x, batch_y_1
    

class CustomImageDataGenerator(object):
    def __init__(self, zoom_range=(1,1), channel_shift_range=0, horizontal_flip=False, vertical_flip=False,
                 rotation_range=0,
                 width_shift_range=0.,
                 height_shift_range=0.,
                 shear_range=0.,
                 elastic=None,
                 trans_threshold=0.,
                 add_noise=0.,
):
        self.zoom_range = zoom_range
        self.channel_shift_range = channel_shift_range
        self.horizontal_flip = horizontal_flip
        self.vertical_flip = vertical_flip
        self.rotation_range = rotation_range
        self.width_shift_range = width_shift_range
        self.height_shift_range = height_shift_range
        self.shear_range = shear_range
        self.elastic = elastic
        self.trans_threshold = trans_threshold
        self.add_noise = add_noise
    def random_transform(self, x, y, row_index=1, col_index=2, channel_index=0):
        ##print (x.shape)
        ##print (y.shape)
        x=np.reshape(x,(x.shape[2],x.shape[1],x.shape[0]))
        y=np.reshape(y,(y.shape[2],y.shape[1],y.shape[0]))  #force to reshape 
        #print('s shape:',x.shape)
        
        if self.horizontal_flip:
            if np.random.random() < self.trans_threshold :
                ##print (' x shape is ', x.shape)
                ##print (' y shape is ', y.shape)
                x = flip_axis(x, 2)   # ori x=flip_axis(x,2)
                y = flip_axis(y, 2)   #  ori x=flip_axis(x,2)   #wrong
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_save, cmin=0.0, cmax=255).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        # use composition of homographies to generate final transform that needs to be applied
        if self.rotation_range:
            theta = np.pi / 180 * np.random.uniform(-self.rotation_range, self.rotation_range)
        else:
            theta = 0
        rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                    [np.sin(theta), np.cos(theta), 0],
                                    [0, 0, 1]])
        if self.height_shift_range:
            tx = np.random.uniform(-self.height_shift_range, self.height_shift_range) * x.shape[row_index]
        else:
            tx = 0

        if self.width_shift_range:
            ty = np.random.uniform(-self.width_shift_range, self.width_shift_range) * x.shape[col_index]
        else:
            ty = 0

        translation_matrix = np.array([[1, 0, tx],
                                       [0, 1, ty],
                                       [0, 0, 1]])
        if self.shear_range:
            shear = np.random.uniform(-self.shear_range, self.shear_range)
        else:
            shear = 0
        shear_matrix = np.array([[1, -np.sin(shear), 0],
                                 [0, np.cos(shear), 0],
                                 [0, 0, 1]])

        if self.zoom_range[0] == 1 and self.zoom_range[1] == 1:
            zx, zy = 1, 1
        else:
            zx, zy = np.random.uniform(self.zoom_range[0], self.zoom_range[1], 2)
        zoom_matrix = np.array([[zx, 0, 0],
                                [0, zy, 0],
                                [0, 0, 1]])

        transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
        
        h, w = x.shape[row_index], x.shape[col_index]
        ##print ('h is :',h,'ok')
        ##print ('w is :',w,'ok')
        ##print ('x shape is :',x.shape,'ok')
        ##print ('y shape is :',y.shape,'ok')
        
        transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        tep2=np.random.random() 
        ##print (tep2)
        if tep2 < self.trans_threshold :
            x = apply_transform(x, transform_matrix, channel_index,
                            fill_mode='constant')
            y = apply_transform(y, transform_matrix, channel_index,
                            fill_mode='constant')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        if self.vertical_flip:
            if np.random.random() < self.trans_threshold :
                x = flip_axis(x, 1)
                y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        if self.channel_shift_range != 0:
            x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if self.elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < self.trans_threshold :
                x, y = elastic_transform(x.reshape(h,w), y.reshape(h,w), *self.elastic)
                x, y = x.reshape(1, h, w), y.reshape(1, h, w)
        tep3=np.random.random()
        #print(tep3)
        if self.add_noise>0:
            if  tep3< self.trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y
    
    

        
def elastic_transform(image, mask, alpha, sigma, alpha_affine=None, random_state=None):
    """Elastic deformation of images as described in [Simard2003]_ (with modifications).
    .. [Simard2003] Simard, Steinkraus and Platt, "Best Practices for
         Convolutional Neural Networks applied to Visual Document Analysis", in
         Proc. of the International Conference on Document Analysis and
         Recognition, 2003.
     Based on https://gist.github.com/erniejunior/601cdf56d2b424757de5
    """
    if random_state is None:
        random_state = np.random.RandomState(None)

    shape = image.shape

    dx = gaussian_filter((random_state.rand(*shape) * 2 - 1), sigma) * alpha
    dy = gaussian_filter((random_state.rand(*shape) * 2 - 1), sigma) * alpha
    
    x, y = np.meshgrid(np.arange(shape[1]), np.arange(shape[0]))
    indices = np.reshape(y+dy, (-1, 1)), np.reshape(x+dx, (-1, 1))


    res_x = map_coordinates(image, indices, order=1, mode='reflect').reshape(shape)
    #scipy.misc.toimage(image).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_elsc_deform.png')
    #print(np.max(image))
    res_y = map_coordinates(mask, indices, order=1, mode='reflect').reshape(shape)
    #print(res_x.shape)
    #print(np.max(res_x))
    #scipy.misc.toimage(res_x).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_elsc_deform.png')
    #scipy.misc.toimage(res_y).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_elsc_deform.png')   
    return res_x, res_y


def test():
    
    #xx
    X2=np.reshape(X1, (1, 160, 160, 1))
    Y2=np.reshape(Y1, (1, 160, 160, 1))
    cid = CustomImageDataGenerator(zoom_range=(1,1),rotation_range=5,height_shift_range=0.08,width_shift_range=0.08,horizontal_flip=False, vertical_flip=False,elastic=(150,20),trans_threshold=0.4,add_noise=0.3)
    gen = cid.flow(X2, Y2, batch_size=1, shuffle=False)
    n = gen.next()[0]
    #print ('finish:OK')
    
    
def augmentation_pytorch_jj_tp (x,y,p_threshold=0):
    if np.random.random() > p_threshold: # larger then transform
        # start to flip the image while change the label since the image is symetric
        x = np.fliplr(x)
        y = np.fliplr(y)
        y_tp=np.zeros((256,256),dtype=int8)
        y_tp[y==7]=7
        y_tp[y==8]=8
        y_tp[y==1]==2
        y_tp[y==2]==1
        y_tp[y==3]==4
        y_tp[y==4]==3
        y_tp[y==5]==6
        y_tp[y==6]==5                
        # finish flip image and change image label

    return  x,y_tp

def augmentation_pytorch_jj( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                y_tp=np.zeros((1,256,256),dtype='uint8')
                y_tp[y==7]=7
                y_tp[y==8]=8
                y_tp[y==1]=2
                y_tp[y==2]=1
                y_tp[y==3]=4
                y_tp[y==4]=3
                y_tp[y==5]=6
                y_tp[y==6]=5  
                y=y_tp
                #print ('after flip max ',np.max(y_tp))
                #scipy.misc.toimage(y_tp.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
                #print ('image horizontal fliped')
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0,
                            fill_mode='nearest')

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            y_tp_3=np.zeros((1,256,256),dtype='uint8')
            y_tp_4=np.zeros((1,256,256),dtype='uint8')
            y_tp_5=np.zeros((1,256,256),dtype='uint8')
            y_tp_6=np.zeros((1,256,256),dtype='uint8')
            y_tp_7=np.zeros((1,256,256),dtype='uint8')
            y_tp_8=np.zeros((1,256,256),dtype='uint8')

            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            y_tp_3[y==3]=1
            y_tp_4[y==4]=1
            y_tp_5[y==5]=1
            y_tp_6[y==6]=1
            y_tp_7[y==7]=1
            y_tp_8[y==8]=1

            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_6 = apply_transform(y_tp_6, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_7 = apply_transform(y_tp_7, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_8 = apply_transform(y_tp_8, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            y_tp[y_tp_3==1]=3
            y_tp[y_tp_4==1]=4
            y_tp[y_tp_5==1]=5
            y_tp[y_tp_6==1]=6
            y_tp[y_tp_7==1]=7
            y_tp[y_tp_8==1]=8
            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y


def augmentation_pytorch_jj_only_image( x,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                
                #print ('after flip max ',np.max(y))
                
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
 
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0,
                            fill_mode='nearest')

            
        
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, x = elastic_transform(x.reshape(256,256), x.reshape(256,256), *elastic)
                x = x.reshape(1, 256, 256)#, y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x
		
def augmentation_pytorch_jj_123456( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                y_tp=np.zeros((1,256,256),dtype='uint8')
                #y_tp[y==7]=7
                #y_tp[y==8]=8
                y_tp[y==1]=2
                y_tp[y==2]=1
                y_tp[y==3]=4
                y_tp[y==4]=3
                y_tp[y==5]=5
                y_tp[y==6]=6  
                y=y_tp
                #print ('after flip max ',np.max(y_tp))
                #scipy.misc.toimage(y_tp.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
                #print ('image horizontal fliped')
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0,
                            fill_mode='nearest')

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            y_tp_3=np.zeros((1,256,256),dtype='uint8')
            y_tp_4=np.zeros((1,256,256),dtype='uint8')
            y_tp_5=np.zeros((1,256,256),dtype='uint8')
            y_tp_6=np.zeros((1,256,256),dtype='uint8')
            #y_tp_7=np.zeros((1,256,256),dtype='uint8')
            #y_tp_8=np.zeros((1,256,256),dtype='uint8')

            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            y_tp_3[y==3]=1
            y_tp_4[y==4]=1
            y_tp_5[y==5]=1
            y_tp_6[y==6]=1
            #y_tp_7[y==7]=1
            #y_tp_8[y==8]=1

            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_6 = apply_transform(y_tp_6, transform_matrix, 0,
                            fill_mode='nearest')
            #y_tp_7 = apply_transform(y_tp_7, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_8 = apply_transform(y_tp_8, transform_matrix, 0,
            #                fill_mode='nearest')
            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            y_tp[y_tp_3==1]=3
            y_tp[y_tp_4==1]=4
            y_tp[y_tp_5==1]=5
            y_tp[y_tp_6==1]=6
            #y_tp[y_tp_7==1]=7
            #y_tp[y_tp_8==1]=8
            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y

def augmentation_pytorch_jj_lung( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0,
                            fill_mode='nearest')
            y = apply_transform(y, transform_matrix, 0,
                            fill_mode='nearest')


            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y

def augmentation_pytorch_jj_hd_nk_t2w( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                y_tp=np.zeros((1,256,256),dtype='uint8')
                #y_tp[y==7]=7
                y_tp[y==5]=5
                y_tp[y==1]=2
                y_tp[y==2]=1
                y_tp[y==3]=4
                y_tp[y==4]=3
                #y_tp[y==5]=6
                #y_tp[y==6]=5  
                y=y_tp
                #print ('after flip max ',np.max(y_tp))
                #scipy.misc.toimage(y_tp.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
                #print ('image horizontal fliped')
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0)

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            y_tp_3=np.zeros((1,256,256),dtype='uint8')
            y_tp_4=np.zeros((1,256,256),dtype='uint8')
            y_tp_5=np.zeros((1,256,256),dtype='uint8')
            #y_tp_6=np.zeros((1,256,256),dtype='uint8')
            #y_tp_7=np.zeros((1,256,256),dtype='uint8')
            #y_tp_8=np.zeros((1,256,256),dtype='uint8')

            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            y_tp_3[y==3]=1
            y_tp_4[y==4]=1
            y_tp_5[y==5]=1
            #y_tp_6[y==6]=1
            #y_tp_7[y==7]=1
            #y_tp_8[y==8]=1

            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
                            fill_mode='nearest')
            #y_tp_6 = apply_transform(y_tp_6, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_7 = apply_transform(y_tp_7, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_8 = apply_transform(y_tp_8, transform_matrix, 0,
            #                fill_mode='nearest')
            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            y_tp[y_tp_3==1]=3
            y_tp[y_tp_4==1]=4
            y_tp[y_tp_5==1]=5
            #y_tp[y_tp_6==1]=6
            #y_tp[y_tp_7==1]=7
            #y_tp[y_tp_8==1]=8
            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y


def augmentation_pytorch_jj_hd_nk_t2w_nolabel( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                y_tp=np.zeros((1,256,256),dtype='uint8')
                #y_tp[y==7]=7
                #y_tp[y==5]=5
                y_tp[y==1]=2
                y_tp[y==2]=1
                y_tp[y==3]=4
                y_tp[y==4]=3
                #y_tp[y==5]=6
                #y_tp[y==6]=5  
                y=y_tp
                #print ('after flip max ',np.max(y_tp))
                #scipy.misc.toimage(y_tp.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
                #print ('image horizontal fliped')
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0)

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            y_tp_3=np.zeros((1,256,256),dtype='uint8')
            y_tp_4=np.zeros((1,256,256),dtype='uint8')
            #y_tp_5=np.zeros((1,256,256),dtype='uint8')
            #y_tp_6=np.zeros((1,256,256),dtype='uint8')
            #y_tp_7=np.zeros((1,256,256),dtype='uint8')
            #y_tp_8=np.zeros((1,256,256),dtype='uint8')

            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            y_tp_3[y==3]=1
            y_tp_4[y==4]=1
            #y_tp_5[y==5]=1
            #y_tp_6[y==6]=1
            #y_tp_7[y==7]=1
            #y_tp_8[y==8]=1

            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
                            fill_mode='nearest')
            #y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_6 = apply_transform(y_tp_6, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_7 = apply_transform(y_tp_7, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_8 = apply_transform(y_tp_8, transform_matrix, 0,
            #                fill_mode='nearest')
            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            y_tp[y_tp_3==1]=3
            y_tp[y_tp_4==1]=4
            #y_tp[y_tp_5==1]=5
            #y_tp[y_tp_6==1]=6
            #y_tp[y_tp_7==1]=7
            #y_tp[y_tp_8==1]=8
            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y


def augmentation_pytorch_jj_hd_nk_t2w_nolabel_5( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                y_tp=np.zeros((1,256,256),dtype='uint8')
                #y_tp[y==7]=7
                #y_tp[y==5]=5
                y_tp[y==1]=2
                y_tp[y==2]=1
                y_tp[y==3]=4
                y_tp[y==4]=3
                #y_tp[y==5]=6
                #y_tp[y==6]=5  
                y=y_tp
                #print ('after flip max ',np.max(y_tp))
                #scipy.misc.toimage(y_tp.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
                #print ('image horizontal fliped')
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0)

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            y_tp_3=np.zeros((1,256,256),dtype='uint8')
            y_tp_4=np.zeros((1,256,256),dtype='uint8')
            y_tp_5=np.zeros((1,256,256),dtype='uint8')
            #y_tp_6=np.zeros((1,256,256),dtype='uint8')
            #y_tp_7=np.zeros((1,256,256),dtype='uint8')
            #y_tp_8=np.zeros((1,256,256),dtype='uint8')

            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            y_tp_3[y==3]=1
            y_tp_4[y==4]=1
            y_tp_5[y==5]=1
            #y_tp_6[y==6]=1
            #y_tp_7[y==7]=1
            #y_tp_8[y==8]=1

            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
                            fill_mode='nearest')
            #y_tp_6 = apply_transform(y_tp_6, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_7 = apply_transform(y_tp_7, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_8 = apply_transform(y_tp_8, transform_matrix, 0,
            #                fill_mode='nearest')
            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            y_tp[y_tp_3==1]=3
            y_tp[y_tp_4==1]=4
            y_tp[y_tp_5==1]=5
            #y_tp[y_tp_6==1]=6
            #y_tp[y_tp_7==1]=7
            #y_tp[y_tp_8==1]=8
            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y
		
def augmentation_pytorch_jj_hd_nk_t2w_parotid( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                y_tp=np.zeros((1,256,256),dtype='uint8')
                #y_tp[y==7]=7
                #y_tp[y==5]=5
                y_tp[y==1]=2
                y_tp[y==2]=1
                #y_tp[y==3]=4
                #y_tp[y==4]=3
                #y_tp[y==5]=6
                #y_tp[y==6]=5  
                y=y_tp
                #print ('after flip max ',np.max(y_tp))
                #scipy.misc.toimage(y_tp.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
                #print ('image horizontal fliped')
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0)

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            #y_tp_3=np.zeros((1,256,256),dtype='uint8')
            #y_tp_4=np.zeros((1,256,256),dtype='uint8')
            #y_tp_5=np.zeros((1,256,256),dtype='uint8')
            #y_tp_6=np.zeros((1,256,256),dtype='uint8')
            #y_tp_7=np.zeros((1,256,256),dtype='uint8')
            #y_tp_8=np.zeros((1,256,256),dtype='uint8')

            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            #y_tp_3[y==3]=1
            #y_tp_4[y==4]=1
            #y_tp_5[y==5]=1
            #y_tp_6[y==6]=1
            #y_tp_7[y==7]=1
            #y_tp_8[y==8]=1

            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            #y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_6 = apply_transform(y_tp_6, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_7 = apply_transform(y_tp_7, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_8 = apply_transform(y_tp_8, transform_matrix, 0,
            #                fill_mode='nearest')
            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            #y_tp[y_tp_3==1]=3
            #y_tp[y_tp_4==1]=4
            #y_tp[y_tp_5==1]=5
            #y_tp[y_tp_6==1]=6
            #y_tp[y_tp_7==1]=7
            #y_tp[y_tp_8==1]=8
            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y
		
		
		
def augmentation_pytorch_jj_heart_c0MRI_3structure( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))
                y_tp=np.zeros((1,256,256),dtype='uint8')
                #y_tp[y==7]=7
                #y_tp[y==5]=5
                y_tp[y==1]=2
                y_tp[y==2]=1
                #y_tp[y==3]=4
                #y_tp[y==4]=3
                #y_tp[y==5]=6
                #y_tp[y==6]=5  
                y=y_tp
                #print ('after flip max ',np.max(y_tp))
                #scipy.misc.toimage(y_tp.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_horizontal_flip.png')
                #print ('image horizontal fliped')
        #x_save=np.reshape(x,(256,256))
        #y_save=np.reshape(y,(256,256))
        
        #scipy.misc.toimage(y_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_horizontal_flip.png')
        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0)

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            y_tp_3=np.zeros((1,256,256),dtype='uint8')
            #y_tp_4=np.zeros((1,256,256),dtype='uint8')
            #y_tp_5=np.zeros((1,256,256),dtype='uint8')
            #y_tp_6=np.zeros((1,256,256),dtype='uint8')
            #y_tp_7=np.zeros((1,256,256),dtype='uint8')
            #y_tp_8=np.zeros((1,256,256),dtype='uint8')

            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            y_tp_3[y==3]=1
            #y_tp_4[y==4]=1
            #y_tp_5[y==5]=1
            #y_tp_6[y==6]=1
            #y_tp_7[y==7]=1
            #y_tp_8[y==8]=1

            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
                            fill_mode='nearest')
            #y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_6 = apply_transform(y_tp_6, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_7 = apply_transform(y_tp_7, transform_matrix, 0,
            #                fill_mode='nearest')
            #y_tp_8 = apply_transform(y_tp_8, transform_matrix, 0,
            #                fill_mode='nearest')
            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            y_tp[y_tp_3==1]=3
            #y_tp[y_tp_4==1]=4
            #y_tp[y_tp_5==1]=5
            #y_tp[y_tp_6==1]=6
            #y_tp[y_tp_7==1]=7
            #y_tp[y_tp_8==1]=8
            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y
		
def augmentation_pytorch_lung_nodule_jj( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :
            #if np.random.random() >-1 :
                #scipy.misc.toimage(y.reshape(256,256), cmin=0.0, cmax=8).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_before_horizontal_flip.png')
                #print ('before flip max ',np.max(y))
                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
                #print ('after flip max ',np.max(y))

        

        
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :
        #if 0 > 1 :
            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            
            #h, w = x.shape[0], x.shape[1]
            ##print ('h is :',h,'ok')
            ##print ('w is :',w,'ok')
            ##print ('x shape is :',x.shape,'ok')
            ##print ('y shape is :',y.shape,'ok')
            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0,
                            fill_mode='nearest')

            y_tp=np.zeros((1,256,256),dtype='uint8')
            y_tp_1=np.zeros((1,256,256),dtype='uint8')
            y_tp_2=np.zeros((1,256,256),dtype='uint8')
            y_tp_3=np.zeros((1,256,256),dtype='uint8')
            y_tp_4=np.zeros((1,256,256),dtype='uint8')
            y_tp_5=np.zeros((1,256,256),dtype='uint8')


            y_tp_1[y==1]=1
            y_tp_2[y==2]=1
            y_tp_3[y==3]=1
            y_tp_4[y==4]=1
            y_tp_5[y==5]=1


            y_tp_1 = apply_transform(y_tp_1, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_2 = apply_transform(y_tp_2, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_3 = apply_transform(y_tp_3, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_4 = apply_transform(y_tp_4, transform_matrix, 0,
                            fill_mode='nearest')
            y_tp_5 = apply_transform(y_tp_5, transform_matrix, 0,
                            fill_mode='nearest')

            y_tp[y_tp_1==1]=1
            y_tp[y_tp_2==1]=2
            y_tp[y_tp_3==1]=3
            y_tp[y_tp_4==1]=4
            y_tp[y_tp_5==1]=5

            y=y_tp
            #print ('image translated')
            #y_tp_1 = apply_transform(y, transform_matrix, 0,
            #                fill_mode='nearest')
        ##print(x.shape)
        #x_trans_save=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_trans_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_transfored.png')
        #        

        #if self.vertical_flip:
        #    if np.random.random() < self.trans_threshold :
        #        x = flip_axis(x, 1)
        #        y = flip_axis(y, 1)
        #x_verti_save=np.reshape(x,(256,256))
        #y_verti_save=np.reshape(y,(256,256))
        #scipy.misc.toimage(x_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_vertical_flip.png')
        #scipy.misc.toimage(y_verti_save).save('/lila/home/jiangj1/data/data_tianchi_test/test_label_vertical_flip.png')
        
        #if self.channel_shift_range != 0:
        #    x = random_channel_shift(x, self.channel_shift_range)

        #plt.show(x)
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x, y        


def augmentation_pytorch_tumor_jj( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(1,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :

                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
    
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :

            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            

            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0)#,fill_mode='nearest')

            

            y = apply_transform(y, transform_matrix, 0)#,
                           # fill_mode='nearest')
            #y=y_tp
            
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x.reshape(1,1,256,256), y.reshape(1,1,256,256)           


def augmentation_pytorch_Polop_jj( x, y,trans_threshold=0.0, horizontal_flip=None,rotation_range=None,height_shift_range=None,width_shift_range=None,shear_range=None,zoom_range=None,elastic=None,add_noise=None): # 2D image 

        x=np.reshape(x,(3,256,256))
        y=np.reshape(y,(1,256,256))  #force to reshape 
        h=256
        w=256
        row_index=1
        col_index=2
        
        if horizontal_flip:
            if np.random.random() < trans_threshold :

                x = flip_axis(x, 2)
                y = flip_axis(y, 2)
    
        
        tep2=np.random.random() 
        if tep2 < trans_threshold :

            if rotation_range:
                theta = np.pi / 180 * np.random.uniform(rotation_range, rotation_range)
            else:
                theta = 0
            rotation_matrix = np.array([[np.cos(theta), -np.sin(theta), 0],
                                        [np.sin(theta), np.cos(theta), 0],
                                        [0, 0, 1]])
            if height_shift_range:
                tx = np.random.uniform(-height_shift_range, height_shift_range) * x.shape[row_index]
            else:
                tx = 0

            if width_shift_range:
                ty = np.random.uniform(-width_shift_range, width_shift_range) * x.shape[col_index]
            else:
                ty = 0

            translation_matrix = np.array([[1, 0, tx],
                                        [0, 1, ty],
                                        [0, 0, 1]])
            if shear_range:
                shear = np.random.uniform(-shear_range, shear_range)
            else:
                shear = 0
            shear_matrix = np.array([[1, -np.sin(shear), 0],
                                    [0, np.cos(shear), 0],
                                    [0, 0, 1]])

            if zoom_range[0] == 1 and zoom_range[1] == 1:
                zx, zy = 1, 1
            else:
                zx, zy = np.random.uniform(zoom_range[0], zoom_range[1], 2)
            zoom_matrix = np.array([[zx, 0, 0],
                                    [0, zy, 0],
                                    [0, 0, 1]])

            transform_matrix = np.dot(np.dot(np.dot(rotation_matrix, translation_matrix), shear_matrix), zoom_matrix)
            

            
            transform_matrix = transform_matrix_offset_center(transform_matrix, h, w)
        
        ##print (tep2)
        
            x = apply_transform(x, transform_matrix, 0)#,fill_mode='nearest')

            

            y = apply_transform(y, transform_matrix, 0)#,
                           # fill_mode='nearest')
            #y=y_tp
            
        
        if elastic is not None:
            #tep=np.random.random()
            ##print(tep)
            if np.random.random() < trans_threshold :
                x, y = elastic_transform(x.reshape(256,256), y.reshape(256,256), *elastic)
                x, y = x.reshape(1, 256, 256), y.reshape(1, 256, 256)
        tep3=np.random.random()
        #print(tep3)
        if add_noise>0:
            if  tep3< trans_threshold :
                x = x + 0.15 * x.std() * np.random.random(x.shape)
        #x_noise=np.reshape(x,(256,256))
        #scipy.misc.toimage(x_noise).save('/lila/home/jiangj1/data/data_tianchi_test/test_feature_noise.png')
        return x.reshape(1,3,256,256), y.reshape(1,1,256,256)     		