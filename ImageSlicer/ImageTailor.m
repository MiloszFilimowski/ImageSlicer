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
    NSAssert(image != nil, @"Image cannot be nil");

    CGImageRef originalImage = image.CGImage;

    NSUInteger originalWidth = CGImageGetWidth(originalImage);
    NSUInteger originalHeight = CGImageGetHeight(originalImage);

    NSUInteger originalTotalPixels = originalWidth * originalHeight;
    CGFloat finalTotalPixels = self.maxImageSizeInMB * pixelsInMB;

    CGFloat scale = finalTotalPixels / originalTotalPixels;
    scale = scale > 1.0 ? 1.0 : scale;

    CGSize finalResolution = CGSizeMake(
                                        (NSUInteger)(originalWidth * scale),
                                        (NSUInteger)(originalHeight * scale)
                                        );

    CGContextRef drawingContext = [self createBitmapContextWithSize:finalResolution];
    NSAssert(drawingContext != NULL, @"Failed to create bitmap context");

    CGContextSetInterpolationQuality(drawingContext, kCGInterpolationHigh);
    NSUInteger tileTotalPixels = self.maxTileSizeInMB * pixelsInMB;

    NSUInteger originalTileHeight = tileTotalPixels / originalWidth;
    NSUInteger finalTileHeight = originalTileHeight * scale;

    NSUInteger numberOfRows = originalHeight / originalTileHeight;
    NSUInteger remainingOriginalHeight = originalHeight % originalTileHeight;
    numberOfRows += remainingOriginalHeight ? 1 : 0;

    for(NSUInteger row = 0; row <= numberOfRows; row++) {
        @autoreleasepool {
            NSUInteger rowPosition = row * originalTileHeight;
            CGRect originalImageTileRect = CGRectMake(
                                                      0,
                                                      rowPosition,
                                                      originalWidth,
                                                      originalTileHeight
                                                      );

            CGRect finalImageTileRect = CGRectMake(
                                                   0,
                                                   finalResolution.height - (row + 1) * finalTileHeight,
                                                   finalResolution.width,
                                                   finalTileHeight
                                                   );
            if (remainingOriginalHeight && row == numberOfRows) {
                originalImageTileRect = CGRectMake(
                                                   0,
                                                   originalHeight - remainingOriginalHeight,
                                                   originalWidth,
                                                   remainingOriginalHeight
                                                   );

                NSUInteger remainingHeight = finalResolution.height - finalTileHeight * (numberOfRows - 1);
                finalImageTileRect = CGRectMake(
                                                0,
                                                0,
                                                finalResolution.width,
                                                remainingHeight
                                                );
            }
            CGImageRef originalTile = CGImageCreateWithImageInRect(originalImage, originalImageTileRect);
            CGContextDrawImage(drawingContext, finalImageTileRect, originalTile);
            CGImageRelease(originalTile);
        }
    }

    CGImageRef finalImageRef = CGBitmapContextCreateImage(drawingContext);
    UIImage *finalImage = [UIImage imageWithCGImage:finalImageRef];
    
    CGContextRelease(drawingContext);
    CGImageRelease(finalImageRef);
    return finalImage;
}


- (CGContextRef)createBitmapContextWithSize:(CGSize)size {
    NSUInteger imageWidth = size.width;
    NSUInteger imageHeight = size.height;
    
    NSUInteger bitmapBytesPerRow = imageWidth * 4;
    NSUInteger bitmapByteCount = bitmapBytesPerRow * imageHeight;
    void* bitmapData = malloc(bitmapByteCount);
    //memset(bitmapData, 0, bitmapByteCount); // delete when finish debugging
    
    if (bitmapData == NULL) {
        return NULL;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef  context = CGBitmapContextCreate(
                                                  bitmapData,
                                                  imageWidth,
                                                  imageHeight,
                                                  8,
                                                  bitmapBytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaNoneSkipLast
                                                  );
    CGColorSpaceRelease(colorSpace);
    
    if (context == NULL) {
        free(bitmapData);
        return NULL;
    }
    
    return context;
}


@end
