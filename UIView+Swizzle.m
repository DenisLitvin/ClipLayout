//
//  UIView+Swizzle.m
//  ClipLayout
//
//  Created by Denis Litvin on 20.06.2018.
//  Copyright © 2018 Denis Litvin. All rights reserved.
//

#import "UIView+Swizzle.h"
#import <objc/runtime.h>
#import "UIView+Layout.h"
#import <ClipLayout/ClipLayout-Swift.h>

@implementation UIView (Swizzle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        {
            SEL originalSelector = @selector(layoutSubviews);
            SEL swizzledSelector = @selector(xxx_layoutSubviews);
            
            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)xxx_layoutSubviews {
    [self xxx_layoutSubviews];
    if (self.clip.enabled) {
        [self.clip layoutSubviews];
        self.clip.cache = CGSizeZero; //invalidate after layout cycle
    }
}

@end
