//
//  UIView+Swizzle.m
//  ClipLayout
//
//  Created by Denis Litvin on 20.06.2018.
//  Copyright © 2018 Denis Litvin. All rights reserved.
//

#import <objc/runtime.h>

#import <ClipLayout/ClipLayout-Swift.h>
#import "UIView+Swizzle.h"
#import "UIView+Layout.h"

static IMP __original_layoutSubviews_imp;

void __swizzle_layoutSubviews(id self, IMP _cmd) {
    ((void(*)(id self, IMP _cmd))__original_layoutSubviews_imp)(self, _cmd);
    UIView *view = (UIView *)self;
    if (view.clip.enable) {
        [view.clip layoutSubviews];
        view.clip.cache = CGSizeZero;
    }
}

@implementation UIView (Swizzle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL originalSelector = @selector(layoutSubviews);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        __original_layoutSubviews_imp = method_setImplementation(originalMethod, (IMP)__swizzle_layoutSubviews);
    });
}

@end
