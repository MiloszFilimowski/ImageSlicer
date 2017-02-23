//
//  ImageTailor.m
//  ImageSlicer
//
//  Created by Miłosz Filimowski on 21/02/2017.
//  Copyright © 2017 Miłosz Filimowski. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "ImageTailor.h"

static const NSUInteger pixelsInMB = 1024 * 1024 / 4; //assuming RGBA for now

@implementation ImageTailor

- (instancetype)init {
    self = [super init];
    if (!self) {
        return self;
    }
    _maxTileSizeInMB = 40;
    _maxImageSizeInMB = 120;

    return self;
}

- (UIImage *)scaleDownImage:(UIImage *)image {

    CGFloat imageOverlap = 2.0;

    CGImageRef originalImage = image.CGImage;

    NSUInteger originalWidth = CGImageGetWidth(originalImage);
    NSUInteger originalHeight = CGImageGetHeight(originalImage);

    NSUInteger originalTotalPixels = (NSUInteger) originalWidth * originalHeight;
    CGFloat finalTotalPixels = self.maxImageSizeInMB * pixelsInMB;

    CGFloat scale = finalTotalPixels / originalTotalPixels;

    CGSize finalResolution = CGSizeMake(
        (originalWidth * scale),
        (originalHeight * scale)
    );

    CGContextRef drawingContext = [self createBitmapContextForImage:originalImage withSize:finalResolution];
    CGContextSetInterpolationQuality(drawingContext, kCGInterpolationHigh);
    NSUInteger tileTotalPixels = self.maxTileSizeInMB * pixelsInMB;

    CGFloat originalImageOverlap = (imageOverlap / finalResolution.height) * originalHeight;

    NSUInteger originalTileHeight = (NSUInteger)(tileTotalPixels / originalWidth);

    NSUInteger numberOfRows = (NSUInteger)(originalHeight / originalTileHeight);
    NSUInteger reminder = originalHeight % originalTileHeight;
    numberOfRows += reminder ? 1 : 0;

    for(NSUInteger row = 0; row < numberOfRows; row++) {
        @autoreleasepool {
            NSUInteger rowPosition = row * originalTileHeight;
            CGRect originalImageTileRect = CGRectMake(0, rowPosition + originalImageOverlap, originalWidth, originalTileHeight);
            CGRect finalImageTileRect = CGRectMake(0, finalResolution.height - ((row + 1) * originalTileHeight * scale + imageOverlap), finalResolution.width, (originalTileHeight * scale));
            CGImageRef originalTile = CGImageCreateWithImageInRect(originalImage, originalImageTileRect);
            CGContextDrawImage(drawingContext, finalImageTileRect, originalTile);
            CGImageRelease(originalImage);
        }
    }

    CGImageRef finalImageRef = CGBitmapContextCreateImage(drawingContext);
    CGContextRelease(drawingContext);
    UIImage *finalImage = [UIImage imageWithCGImage:finalImageRef];
    return finalImage;
}


- (CGContextRef)createBitmapContextForImage:(CGImageRef)image withSize:(CGSize)size {

    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    NSUInteger imageWidth = size.width;
    NSUInteger imageHeight = size.height;

    NSUInteger bitmapBytesPerRow = imageWidth * 4;
    NSUInteger bitmapByteCount = bitmapBytesPerRow * imageHeight;
    void* bitmapData = malloc(bitmapByteCount);

    if (bitmapData == NULL) {
        return NULL;
    }

    CGContextRef  context = CGBitmapContextCreate(bitmapData,
                                                  imageWidth,
                                                  imageHeight,
                                                  8,
                                                  bitmapBytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaNoneSkipLast);
    if (context == NULL) {
        free(bitmapData);
        return NULL;
    }

    CGColorSpaceRelease(colorSpace);
    return context;
    
}


@end
