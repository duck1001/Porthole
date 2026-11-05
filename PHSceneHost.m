//
//  PHSceneHost.m
//

#import "PHSceneHost.h"
#import "PHCommon.h"
#import "PHLog.h"

@interface PHSceneHost ()
@property (nonatomic, strong) UIView *hostView;
@property (nonatomic, strong) id scene;
@property (nonatomic, strong) id app;
@property (nonatomic, strong) id handle;
@property (nonatomic, strong) id presenter;
@property (nonatomic, strong) id sceneView;
@property (nonatomic, copy)   NSString *bundleID;
@property (nonatomic, copy)   NSString *strategyName;
@property (nonatomic, copy)   NSString *lastError;
@property (nonatomic, assign) NSInteger strategy;
@property (nonatomic, assign) BOOL started;
@end

@implementation PHSceneHost

+ (void)probeEnvironment {
    NSArray *classes = @[@"SBApplicationController", @"SBApplication", @"SBApplicationSceneView",
                         @"SBSceneView", @"FBScene", @"FBSceneManager", @"FBSceneWorkspace",
                         @"UIScenePresentationManager", @"_UISceneHostingView", @"UISceneHostingView",
                         @"FBSSceneSettings", @"UIMutableApplicationSceneSettings"];
    for (NSString *n in classes) {
        PHLog(@"探测: class %@ = %@", n, NSClassFromString(n) ? @"有" : @"无");
    }
    id scene = nil;
    NSArray *scenes = @[@"uiPresentationManager", @"settings", @"updateSettings:withTransitionContext:completion:",
                        @"activateWithTransitionContext:", @"invalidate", @"clientProcess"];
    for (NSString *sel in scenes) {
        PHLog(@"探测: FBScene %@ = %d", sel, (int)[scene respondsToSelector:NSSelectorFromString(sel)]);
    }
}

+ (instancetype)hostForBundle:(NSString *)bundleID strategy:(NSInteger)strategy {
    PHSceneHost *h = [PHSceneHost new];
    h.bundleID = bundleID;
    h.strategy = strategy;
    h.verbose = YES;
    return h;
}

#pragma mark - 找 App

- (id)findApplication {
    Class ctrlCls = NSClassFromString(@"SBApplicationController");
    id ctrl = PHCall0(ctrlCls, @"sharedInstance");
    if (!ctrl) {
        self.lastError = @"SBApplicationController 不可用";
        PHLog(@"场景: SBApplicationController 不可用");
        return nil;
    }
    id app = PHCall1(ctrl, @"applicationWithBundleIdentifier:", self.bundleID);
    if (!app) app = PHCall1(ctrl, @"applicationWithBundleID:", self.bundleID);
    if (!app) {
        self.lastError = [NSString stringWithFormat:@"找不到运行中的 %@", self.bundleID];
        PHLog(@"场景: 找不到运行中的 App %@（先把它启动到前台）", self.bundleID);
    }
    return app;
}

- (id)findScene {
    id app = self.app;
    id handle = PHCall0(app, @"mainSceneHandle");
    if (!handle) handle = PHCall0(app, @"sceneHandle");
    self.handle = handle;
    if (self.verbose) PHLog(@"场景: mainSceneHandle = %@", handle ? NSStringFromClass([handle class]) : @"nil");

    id scene = PHCall0(handle, @"scene");
    if (!scene) scene = PHCall0(app, @"scene");
    if (!scene) scene = PHCall0(app, @"_scene");
    if (self.verbose) PHLog(@"场景: FBScene = %@", scene ? NSStringFromClass([scene class]) : @"nil");
    return scene;
}

#pragma mark - 三条托管路径

- (UIView *)viewByPresenter {
    id pm = PHCall0(self.scene, @"uiPresentationManager");
    if (!pm) {
        self.lastError = @"scene 没有 uiPresentationManager";
        PHLog(@"呈现器: scene.uiPresentationManager 不存在");
        return nil;
    }
    id presenter = PHCall1Int(pm, @"createPresenterWithIdentifier:priority:", @"Porthole", 0);
    if (!presenter) presenter = PHCall1(pm, @"createPresenterWithIdentifier:", @"Porthole");
    if (!presenter) {
        self.lastError = @"createPresenter 失败";
        PHLog(@"呈现器: createPresenter 失败");
        return nil;
    }
    PHVoid0(presenter, @"activate");
    UIView *v = PHCall0(presenter, @"presentationView");
    if (!v) {
        self.lastError = @"presentationView 为空";
        PHLog(@"呈现器: presentationView 为空");
        return nil;
    }
    self.presenter = presenter;
    self.strategyName = @"presenter";
    PHLog(@"呈现器: 成功 %@", NSStringFromClass([v class]));
    return v;
}

- (UIView *)viewBySceneView {
    Class cls = NSClassFromString(@"SBApplicationSceneView") ?: NSClassFromString(@"SBSceneView");
    if (!cls) {
        self.lastError = @"没有 SBApplicationSceneView / SBSceneView";
        PHLog(@"场景视图: 找不到 SBApplicationSceneView / SBSceneView");
        return nil;
    }
    id v = nil;
    if ([cls instancesRespondToSelector:NSSelectorFromString(@"initWithSceneHandle:")]) {
        v = ((id (*)(id, SEL, id))objc_msgSend)([cls alloc], NSSelectorFromString(@"initWithSceneHandle:"), self.handle);
    } else if ([cls instancesRespondToSelector:NSSelectorFromString(@"initWithScene:")]) {
        v = ((id (*)(id, SEL, id))objc_msgSend)([cls alloc], NSSelectorFromString(@"initWithScene:"), self.scene);
    }
    if (!v) {
        self.lastError = [NSString stringWithFormat:@"%@ 初始化失败", NSStringFromClass(cls)];
        PHLog(@"场景视图: %@ 初始化失败", NSStringFromClass(cls));
        return nil;
    }
    self.sceneView = v;
    self.strategyName = @"sceneView";
    PHLog(@"场景视图: 成功 %@", NSStringFromClass([v class]));
    return v;
}

- (UIView *)viewByHostingView {
    NSArray *names = @[@"_UISceneHostingView", @"UISceneHostingView", @"_UISceneHostingContentView", @"SBSceneHostingView"];
    for (NSString *n in names) {
        Class cls = NSClassFromString(n);
        if (!cls) continue;
        id v = nil;
        if ([cls instancesRespondToSelector:NSSelectorFromString(@"initWithScene:debugDescription:")]) {
            v = ((id (*)(id, SEL, id, id))objc_msgSend)([cls alloc],
                                                        NSSelectorFromString(@"initWithScene:debugDescription:"),
                                                        self.scene, @"Porthole");
        } else if ([cls instancesRespondToSelector:NSSelectorFromString(@"initWithScene:")]) {
            v = ((id (*)(id, SEL, id))objc_msgSend)([cls alloc], NSSelectorFromString(@"initWithScene:"), self.scene);
        }
        if (v) {
            self.strategyName = @"hostingView";
            PHLog(@"宿主视图: 成功 %@", n);
            return v;
        }
    }
    self.lastError = @"没有可用的宿主视图类";
    PHLog(@"宿主视图: 候选类全部不可用");
    return nil;
}

#pragma mark - 生命周期

- (BOOL)start {
    if (self.started) return YES;
    PHLog(@"—— 打开舷窗: %@ ——", self.bundleID);
    if (self.verbose) [PHSceneHost probeEnvironment];

    self.app = [self findApplication];
    if (!self.app) return NO;

    self.scene = [self findScene];
    if (!self.scene) {
        PHLog(@"场景: 拿不到 FBScene，App 可能没有活跃场景");
        return NO;
    }

    NSMutableArray<NSNumber *> *order = [NSMutableArray array];
    if (self.strategy == 0) [order addObjectsFromArray:@[@1, @2, @3]];
    else [order addObject:@(self.strategy)];

    UIView *v = nil;
    for (NSNumber *n in order) {
        NSInteger s = n.integerValue;
        if (s == 1) v = [self viewByPresenter];
        else if (s == 2) v = [self viewBySceneView];
        else if (s == 3) v = [self viewByHostingView];
        if (v) break;
    }
    if (!v) {
        self.lastError = @"三条托管路径都失败";
        PHLog(@"场景: 三条路径都失败");
        return NO;
    }

    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.hostView = v;
    self.started = YES;
    PHLog(@"场景: 托管方式 = %@", self.strategyName);
    return YES;
}

- (void)applyFrame:(CGRect)frame {
    if (!self.started) return;
    if (self.hostView) self.hostView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);

    id scene = self.scene;
    if (!PHHas(scene, @"updateSettings:withTransitionContext:completion:")) return;

    id settings = [PHCall0(scene, @"settings") mutableCopy];
    if (!settings) return;

    if (PHHas(settings, @"setFrame:")) PHVoidRect(settings, @"setFrame:", frame);
    if (PHHas(settings, @"setForeground:")) PHVoidBool(settings, @"setForeground:", YES);
    if (PHHas(settings, @"setInterfaceOrientation:")) {
        UIInterfaceOrientation o = UIApplication.sharedApplication.statusBarOrientation;
        PHVoidInt(settings, @"setInterfaceOrientation:", (NSInteger)o);
    }
    PHVoid3(scene, @"updateSettings:withTransitionContext:completion:", settings, nil, nil);
}

- (void)stop {
    if (!self.started) return;
    PHLog(@"—— 关闭舷窗: %@ ——", self.bundleID);
    if (self.presenter) {
        PHVoid0(self.presenter, @"deactivate");
        PHVoid0(self.presenter, @"invalidate");
        self.presenter = nil;
    }
    [self.hostView removeFromSuperview];
    self.hostView = nil;
    self.sceneView = nil;
    self.scene = nil;
    self.app = nil;
    self.handle = nil;
    self.started = NO;
}

@end
