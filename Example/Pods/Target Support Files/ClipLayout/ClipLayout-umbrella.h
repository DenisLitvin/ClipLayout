#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UIView+Layout.h"
#import "UIView+Swizzle.h"
#import "CALayer+Layout.h"
#import "CALayer+Swizzle.h"

FOUNDATION_EXPORT double ClipLayoutVersionNumber;
FOUNDATION_EXPORT const unsigned char ClipLayoutVersionString[];

