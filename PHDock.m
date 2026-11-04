//
//  PHDock.m
//

#import "PHDock.h"
#import "PHCommon.h"
#import "PHLog.h"

static const CGFloat PHDockSize = 54.0;
static const CGFloat PHDockInset = 2.0;

@interface PHDock () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) NSInteger edge;
@property (nonatomic, assign) CGPoint startCenter;
@property (nonatomic, copy) NSString *bundleID;
@end

@implementation PHDock

- (BOOL)canBecomeKeyWindow { return NO; }

- (instancetype)init {
    UIWindowScene *scene = PHActiveWindowScene();
    self = scene ? [super initWithWindowScene:scene] : [super initWithFrame:UIScreen.mainScreen.bounds];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.windowLevel = UIWindowLevelAlert - 2;
        self.rootViewController = [UIViewController new];
        self.rootViewController.view.backgroundColor = UIColor.clearColor;
        self.frame = CGRectMake(0, 0, PHDockSize, PHDockSize);

        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = CGRectMake(0, 0, PHDockSize, PHDockSize);
        _button.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.92];
        _button.layer.cornerRadius = PHDockSize / 2.0;
        _button.layer.cornerCurve = kCACornerCurveContinuous;
        _button.layer.borderWidth = 0.5;
        _button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
        _button.layer.shadowColor = UIColor.blackColor.CGColor;
        _button.layer.shadowOpacity = 0.35;
        _button.layer.shadowRadius = 8;
        _button.layer.shadowOffset = CGSizeMake(0, 3);
        _button.clipsToBounds = NO;
        [_button addTarget:self action:@selector(onTap) forControlEvents:UIControlEventTouchUpInside];
        [self.rootViewController.view addSubview:_button];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(7, 7, PHDockSize - 14, PHDockSize - 14)];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.layer.cornerRadius = (PHDockSize - 14) / 4.0;
        _iconView.layer.cornerCurve = kCACornerCurveContinuous;
        _iconView.clipsToBounds = YES;
        _iconView.userInteractionEnabled = NO;
        [_button addSubview:_iconView];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        pan.delegate = self;
        [_button addGestureRecognizer:pan];

        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
        lp.minimumPressDuration = 0.6;
        [_button addGestureRecognizer:lp];
    }
    return self;
}

- (void)presentEdge:(NSInteger)edge bundleID:(NSString *)bundleID {
    self.edge = edge;
    self.bundleID = bundleID;
    [self refreshIconForBundle:bundleID];
    [self placeAtEdgeCenter];
    self.hidden = NO;
}

- (void)placeAtEdgeCenter {
    CGRect s = self.screen.bounds;
    CGFloat x = (self.edge == 1) ? (PHDockInset + PHDockSize / 2.0)
                                 : (s.size.width - PHDockInset - PHDockSize / 2.0);
    self.center = CGPointMake(x, s.size.height / 2.0);
}

- (void)refreshIconForBundle:(NSString *)bundleID {
    UIImage *icon = nil;
    Class ui = NSClassFromString(@"UIImage");
    SEL sel = NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:");
    if (ui && [ui respondsToSelector:sel]) {
        icon = ((id (*)(id, SEL, id, int, double))objc_msgSend)(ui, sel, bundleID, 0, 3.0);
    }
    if (!icon) {
        SEL sel2 = NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:");
        if (ui && [ui respondsToSelector:sel2]) {
            icon = ((id (*)(id, SEL, id, int))objc_msgSend)(ui, sel2, bundleID, 0);
        }
    }
    if (icon) {
        _iconView.image = icon;
        _iconView.hidden = NO;
    } else {
        _iconView.image = nil;
        _iconView.hidden = YES;
        [_button setTitle:@"舷" forState:UIControlStateNormal];
        [_button setTitleColor:[UIColor colorWithWhite:0.95 alpha:1.0] forState:UIControlStateNormal];
        _button.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    }
}

- (void)hide {
    self.hidden = YES;
}

#pragma mark - 手势

- (void)onTap {
    if ([self.dockDelegate respondsToSelector:@selector(phDockDidTap:)]) {
        [self.dockDelegate phDockDidTap:self];
    }
}

- (void)onLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    if ([self.dockDelegate respondsToSelector:@selector(phDockDidLongPress:)]) {
        [self.dockDelegate phDockDidLongPress:self];
    }
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:nil];
    if (g.state == UIGestureRecognizerStateBegan) self.startCenter = self.center;
    CGRect s = self.screen.bounds;
    CGFloat y = self.startCenter.y + t.y;
    y = MAX(PHDockSize / 2.0 + 20, MIN(s.size.height - PHDockSize / 2.0 - 20, y));
    CGFloat x = (self.edge == 1) ? (PHDockInset + PHDockSize / 2.0)
                                 : (s.size.width - PHDockInset - PHDockSize / 2.0);
    self.center = CGPointMake(x, y);
    [g setTranslation:CGPointZero inView:nil];
}

@end
