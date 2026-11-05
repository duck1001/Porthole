//
//  PHManager.m
//

#import "PHManager.h"
#import "PHCommon.h"
#import "PHLog.h"
#import "PHPrefs.h"
#import "PHDock.h"
#import "PHWindow.h"
#import "PHSceneHost.h"

@interface PHManager () <PHDockDelegate, PHWindowDelegate>
@property (nonatomic, strong, nullable) PHDock *dock;
@property (nonatomic, strong, nullable) PHWindow *window;
@property (nonatomic, strong, nullable) PHSceneHost *host;
@property (nonatomic, assign) BOOL started;
@end

@implementation PHManager

+ (instancetype)shared {
    static PHManager *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ m = [PHManager new]; });
    return m;
}

- (void)start {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self start]; });
        return;
    }
    if (self.started) return;
    self.started = YES;

    PHLog(@"启动 Porthole 0.1.0，SpringBoard 进程");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onOrientation)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [self prefsChanged];
}

- (void)onOrientation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.dock && !self.dock.hidden) {
            [self.dock presentEdge:PHPrefs.shared.dockEdge bundleID:PHPrefs.shared.targetBundle];
        }
        if (self.window && self.host) {
            [self.host applyFrame:self.window.contentContainer.bounds];
        }
    });
}

#pragma mark - 配置

- (void)prefsChanged {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self prefsChanged]; });
        return;
    }
    PHPrefs *p = PHPrefs.shared;
    [p reload];

    if (!p.enabled) {
        [self.dock hide];
        [self closeWindowIfNeeded];
        PHLog(@"配置: 已关闭，收起把手");
        return;
    }

    if (p.showDock) {
        if (!self.dock) self.dock = [PHDock new];
        self.dock.dockDelegate = self;
        [self.dock presentEdge:p.dockEdge bundleID:p.targetBundle];
        PHLog(@"配置: 把手显示，edge=%ld target=%@", (long)p.dockEdge, p.targetBundle);
    } else {
        [self.dock hide];
    }
}

#pragma mark - 开关浮窗

- (void)toggleTargetBundle {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self toggleTargetBundle]; });
        return;
    }
    if (self.window) {
        [self closeWindowIfNeeded];
    } else {
        [self openTargetBundle];
    }
}

- (void)openTargetBundle {
    PHPrefs *p = PHPrefs.shared;
    NSString *bundle = p.targetBundle;
    PHLog(@"打开目标: %@", bundle);

    self.window = [[PHWindow alloc] initWithBundleID:bundle];
    self.window.phDelegate = self;
    self.window.titleText = bundle;
    [self.window presentWithSize:CGSizeMake(p.width, p.height)
                            edge:p.dockEdge
                    cornerRadius:p.cornerRadius
                          shadow:p.shadow];

    self.host = [PHSceneHost hostForBundle:bundle strategy:p.hostStrategy];
    BOOL ok = [self.host start];
    if (ok && self.host.hostView) {
        UIView *v = self.host.hostView;
        v.frame = self.window.contentContainer.bounds;
        v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.window.contentContainer addSubview:v];
        [self.host applyFrame:self.window.contentContainer.bounds];
    } else {
        UILabel *tip = [[UILabel alloc] initWithFrame:self.window.contentContainer.bounds];
        tip.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tip.numberOfLines = 0;
        tip.textAlignment = NSTextAlignmentCenter;
        tip.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
        tip.font = [UIFont systemFontOfSize:12];
        tip.text = [NSString stringWithFormat:@"场景托管失败\n%@\n把目标 App 启动到前台后重试\n详情见设置里的黑匣子日志", self.host.lastError ?: @"未知原因"];
        [self.window.contentContainer addSubview:tip];
    }
}

- (void)closeWindowIfNeeded {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self closeWindowIfNeeded]; });
        return;
    }
    if (self.host) { [self.host stop]; self.host = nil; }
    if (self.window) { [self.window close]; self.window = nil; }
}

#pragma mark - PHDockDelegate

- (void)phDockDidTap:(PHDock *)dock {
    [self toggleTargetBundle];
}

- (void)phDockDidLongPress:(PHDock *)dock {
    [self closeWindowIfNeeded];
    PHLog(@"把手长按: 关闭浮窗");
}

#pragma mark - PHWindowDelegate

- (void)phWindowDidRequestClose:(PHWindow *)window {
    [self closeWindowIfNeeded];
}

- (void)phWindowDidChangeFrame:(PHWindow *)window {
    if (self.host) [self.host applyFrame:window.contentContainer.bounds];
}

@end

void PHOpenBundle(NSString *bundleID) {
    dispatch_async(dispatch_get_main_queue(), ^{
        PHPrefs *p = PHPrefs.shared;
        if (!p.enabled) return;
        PHWindow *w = [[PHWindow alloc] initWithBundleID:bundleID];
        w.titleText = bundleID;
        [w presentWithSize:CGSizeMake(p.width, p.height) edge:p.dockEdge cornerRadius:p.cornerRadius shadow:p.shadow];
        PHSceneHost *h = [PHSceneHost hostForBundle:bundleID strategy:p.hostStrategy];
        if ([h start] && h.hostView) {
            h.hostView.frame = w.contentContainer.bounds;
            [w.contentContainer addSubview:h.hostView];
            [h applyFrame:w.contentContainer.bounds];
        }
    });
}
