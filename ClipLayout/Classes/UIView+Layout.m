//
//  UIView+Layout.m
//  ClipLayout
//
//  Created by Denis Litvin on 13.06.2018.
//  Copyright © 2018 Denis Litvin. All rights reserved.
//

#import <ClipLayout/ClipLayout-Swift.h>
#import <objc/runtime.h>

#import "UIView+Layout.h"

static const void *kLayoutAssociatedKey = &kLayoutAssociatedKey;

@implementation UIView (Layout)

- (ClipLayout *)clip
{
    ClipLayout *layout = objc_getAssociatedObject(self, kLayoutAssociatedKey);
    if (!layout) {
        layout = [[ClipLayout alloc] initWith:self];
        objc_setAssociatedObject(self, kLayoutAssociatedKey, layout, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layout;
}

- (void)configureWithBlock:(LayoutConfigurationBlock)block {
    self.clip.enabled = YES;
    if (block != nil) {
        block(self.clip);
    }
}
@end


@implementation CALayer (Layout)

- (ClipLayout *)clip
{
    ClipLayout *layout = objc_getAssociatedObject(self, kLayoutAssociatedKey);
    if (!layout) {
        layout = [[ClipLayout alloc] initWith:self];
        objc_setAssociatedObject(self, kLayoutAssociatedKey, layout, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layout;
}

- (void)configureWithBlock:(LayoutConfigurationBlock)block {
    self.clip.enabled = YES;
    if (block != nil) {
        block(self.clip);
    }
}
@end
