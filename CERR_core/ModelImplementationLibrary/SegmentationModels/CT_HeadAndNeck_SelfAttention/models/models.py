
def create_model(opt):
    model = None
    print(opt.model)
    if opt.model == 'cycle_gan_unet_ct_seg_headneck_PSA':
        assert(opt.dataset_mode == 'unaligned')
        from .cycle_gan_Unet_ctSeg_headneck_PSA import cycle_gan_unet_ct_seg_baseline
        model=cycle_gan_unet_ct_seg_baseline()
    else:
        raise ValueError("Model [%s] not recognized." % opt.model)
    
    print (opt.model)
    print (model)
    model.initialize(opt)
    print("model [%s] was created" % (model.name()))
    return model
