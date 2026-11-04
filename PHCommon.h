//
//  PHCommon.h
//  Porthole — 公共宏与运行时帮助函数
//

#ifndef PHCommon_h
#define PHCommon_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>

#define PH_DOMAIN @"com.milkway.porthole"
#define PH_NOTIFY CFSTR("com.milkway.porthole/prefs-changed")
#define PH_LOG_PATH @"/var/mobile/Library/Porthole/porthole.log"
#define PH_FALLBACK_LOG @"/tmp/porthole.log"

static inline BOOL PHHas(id o, NSString *sel) {
    return o && [o respondsToSelector:NSSelectorFromString(sel)];
}

static inline id PHCall0(id o, NSString *sel) {
    if (!PHHas(o, sel)) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(o, NSSelectorFromString(sel));
}

static inline id PHCall1(id o, NSString *sel, id a) {
    if (!PHHas(o, sel)) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(o, NSSelectorFromString(sel), a);
}

static inline id PHCall2(id o, NSString *sel, id a, id b) {
    if (!PHHas(o, sel)) return nil;
    return ((id (*)(id, SEL, id, id))objc_msgSend)(o, NSSelectorFromString(sel), a, b);
}

static inline id PHCall1Int(id o, NSString *sel, id a, NSInteger i) {
    if (!PHHas(o, sel)) return nil;
    return ((id (*)(id, SEL, id, NSInteger))objc_msgSend)(o, NSSelectorFromString(sel), a, i);
}

static inline void PHVoidBool(id o, NSString *sel, BOOL v) {
    if (!PHHas(o, sel)) return;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(o, NSSelectorFromString(sel), v);
}

static inline void PHVoidInt(id o, NSString *sel, NSInteger v) {
    if (!PHHas(o, sel)) return;
    ((void (*)(id, SEL, NSInteger))objc_msgSend)(o, NSSelectorFromString(sel), v);
}

static inline void PHVoid0(id o, NSString *sel) {
    if (!PHHas(o, sel)) return;
    ((void (*)(id, SEL))objc_msgSend)(o, NSSelectorFromString(sel));
}

static inline void PHVoid1(id o, NSString *sel, id a) {
    if (!PHHas(o, sel)) return;
    ((void (*)(id, SEL, id))objc_msgSend)(o, NSSelectorFromString(sel), a);
}

static inline void PHVoid2(id o, NSString *sel, id a, id b) {
    if (!PHHas(o, sel)) return;
    ((void (*)(id, SEL, id, id))objc_msgSend)(o, NSSelectorFromString(sel), a, b);
}

static inline void PHVoid3(id o, NSString *sel, id a, id b, id c) {
    if (!PHHas(o, sel)) return;
    ((void (*)(id, SEL, id, id, id))objc_msgSend)(o, NSSelectorFromString(sel), a, b, c);
}

static inline void PHVoidRect(id o, NSString *sel, CGRect r) {
    if (!PHHas(o, sel)) return;
    ((void (*)(id, SEL, CGRect))objc_msgSend)(o, NSSelectorFromString(sel), r);
}

static inline UIWindowScene *PHActiveWindowScene(void) {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class]) continue;
        if (s.activationState == UISceneActivationStateForegroundActive) return (UIWindowScene *)s;
    }
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:UIWindowScene.class]) return (UIWindowScene *)s;
    }
    return nil;
}

#endif /* PHCommon_h */
