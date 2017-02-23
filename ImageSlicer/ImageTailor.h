//
//  ImageTailor.h
//  ImageSlicer
//
//  Created by Miłosz Filimowski on 21/02/2017.
//  Copyright © 2017 Miłosz Filimowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageTailor : NSObject

@property (nonatomic, assign) NSUInteger maxImageSizeInMB;
@property (nonatomic, assign) NSUInteger maxTileSizeInMB;

- (UIImage *)scaleDownImage:(UIImage *)image;

@end
