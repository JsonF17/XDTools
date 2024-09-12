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

#import "LXControlDevice.h"
#import "LXDLNA.h"
#import "LXFindDevice.h"
#import "LXSubscribeDevice.h"
#import "LXUPnPDevice.h"
#import "LXUPnPStatusInfo.h"

FOUNDATION_EXPORT double XDToolsVersionNumber;
FOUNDATION_EXPORT const unsigned char XDToolsVersionString[];

