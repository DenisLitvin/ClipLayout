//
//  CALayer+Swizzle.m
//  ClipLayout
//
//  Created by Denis Litvin on 30.08.2018.
//

#import <objc/runtime.h>

#import <ClipLayout/ClipLayout-Swift.h>
#import "CALayer+Swizzle.h"
#import "CALayer+Layout.h"

static IMP __original_layoutSublayers_imp;

void __swizzle_layoutSublayers(id self, IMP _cmd) {
    ((void(*)(id self, IMP _cmd))__original_layoutSublayers_imp)(self, _cmd);
    CALayer *layer = (CALayer *)self;
    if (layer.clip.enable) {
        [layer.clip layoutSubviews];
        layer.clip.cache = CGSizeZero;
    }
}

@implementation CALayer (Swizzle)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL originalSelector = @selector(layoutSublayers);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        __original_layoutSublayers_imp = method_setImplementation(originalMethod, (IMP)__swizzle_layoutSublayers);
    });
}
@end
