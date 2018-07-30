//
//  UIView+Layout.h
//  ClipLayout
//
//  Created by Denis Litvin on 13.06.2018.
//  Copyright © 2018 Denis Litvin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ClipLayout;

NS_ASSUME_NONNULL_BEGIN

typedef void(^LayoutConfigurationBlock)(ClipLayout *layout);

@interface UIView (Layout)
@property (nonatomic, readonly, strong) ClipLayout *clip;

/**
 In ObjC land, every time you access `view.layout.*` you are adding another `objc_msgSend`
 to your code. If you plan on making multiple changes to YGLayout, it's more performant
 to use this method, which uses a single objc_msgSend call.
 */
- (void)configureWithBlock: (LayoutConfigurationBlock)block
NS_SWIFT_NAME(configureLayout(layout:));

@end

NS_ASSUME_NONNULL_END
