
#....................
# image used in tests
#....................

pth = system.file('images', 'Sugar_Cane_Bolivia_PlanetNICFI.png', package = "fastGLCM")

methods = c('mean',
            'std',
            'contrast',
            'dissimilarity',
            'homogeneity',
            'ASM',
            'energy',
            'max',
            'entropy')

im_3d = OpenImageR::readImage(pth)
im = OpenImageR::rgb_2gray(im_3d)
im = im * 255
