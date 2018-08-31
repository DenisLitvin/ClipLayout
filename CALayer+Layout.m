//
//  CALayer+Layout.m
//  ClipLayout
//
//  Created by Denis Litvin on 30.08.2018.
//

#import "CALayer+Layout.h"
#import <ClipLayout/ClipLayout-Swift.h>
#import <objc/runtime.h>

static const void *kLayoutAssociatedKey = &kLayoutAssociatedKey;

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
    self.clip.enable = YES;
    if (block != nil) {
        block(self.clip);
    }
}
@end
