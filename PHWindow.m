//
//  PHWindow.m
//

#import "PHWindow.h"
#import "PHCommon.h"
#import "PHLog.h"

static const CGFloat PHBarHeight = 30.0;

@interface PHWindow () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *chrome;
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) UIView *bar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UIButton *expandBtn;
@property (nonatomic, strong) UIView *grip;
@property (nonatomic, copy)   NSString *bundleID;
@property (nonatomic, assign) CGRect restoreFrame;
@property (nonatomic, assign) BOOL fullscreen;
@property (nonatomic, assign) CGSize startSize;
@property (nonatomic, assign) CGPoint startOrigin;
@property (nonatomic, assign) CGFloat cornerRadius;
@end

@implementation PHWindow

- (void)setTitleText:(NSString *)titleText {
    _titleText = [titleText copy];
    _titleLabel.text = titleText.length ? titleText : @"舷窗";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutChrome];
    if ([self.phDelegate respondsToSelector:@selector(phWindowDidChangeFrame:)]) {
        [self.phDelegate phWindowDidChangeFrame:self];
    }
}

- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeVisibleWithoutLogin { return YES; }

- (instancetype)initWithBundleID:(NSString *)bundleID {
    UIWindowScene *scene = PHActiveWindowScene();
    if (scene) {
        self = [super initWithWindowScene:scene];
    } else {
        self = [super initWithFrame:UIScreen.mainScreen.bounds];
    }
    if (self) {
        _bundleID = [bundleID copy];
        _showsCloseButton = YES;
        self.backgroundColor = UIColor.clearColor;
        self.windowLevel = UIWindowLevelAlert - 1;
        self.rootViewController = [UIViewController new];
        self.rootViewController.view.backgroundColor = UIColor.clearColor;
        [self buildChrome];
    }
    return self;
}

- (void)buildChrome {
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;

    _chrome = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    _chrome.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _chrome.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
    _chrome.layer.cornerRadius = 22;
    _chrome.layer.cornerCurve = kCACornerCurveContinuous;
    _chrome.layer.masksToBounds = YES;
    _chrome.layer.borderWidth = 0.5;
    _chrome.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    [self.rootViewController.view addSubview:_chrome];

    _bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, PHBarHeight)];
    _bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _bar.backgroundColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    [_chrome addSubview:_bar];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, w - 84, PHBarHeight)];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _titleLabel.textColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    _titleLabel.text = @"舷窗";
    [_bar addSubview:_titleLabel];

    _closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _closeBtn.frame = CGRectMake(w - 30, 4, 22, 22);
    _closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_closeBtn setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    [_closeBtn setTintColor:[UIColor colorWithWhite:0.85 alpha:1.0]];
    _closeBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_closeBtn addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [_bar addSubview:_closeBtn];

    _expandBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _expandBtn.frame = CGRectMake(w - 58, 4, 22, 22);
    _expandBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_expandBtn setImage:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"] forState:UIControlStateNormal];
    [_expandBtn setTintColor:[UIColor colorWithWhite:0.85 alpha:1.0]];
    [_expandBtn addTarget:self action:@selector(onExpand) forControlEvents:UIControlEventTouchUpInside];
    [_bar addSubview:_expandBtn];

    _contentContainer = [[UIView alloc] initWithFrame:CGRectMake(0, PHBarHeight, w, h - PHBarHeight)];
    _contentContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _contentContainer.backgroundColor = UIColor.blackColor;
    _contentContainer.clipsToBounds = YES;
    [_chrome addSubview:_contentContainer];

    _grip = [[UIView alloc] initWithFrame:CGRectMake(w - 26, h - 26, 26, 26)];
    _grip.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _grip.backgroundColor = UIColor.clearColor;
    UIImageView *g = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.down.right"]];
    g.tintColor = [UIColor colorWithWhite:1 alpha:0.55];
    g.frame = CGRectMake(6, 6, 14, 14);
    [_grip addSubview:g];
    _grip.userInteractionEnabled = YES;
    [_chrome addSubview:_grip];

    UIPanGestureRecognizer *barPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onBarPan:)];
    [_bar addGestureRecognizer:barPan];

    UIPanGestureRecognizer *gripPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onGripPan:)];
    [_grip addGestureRecognizer:gripPan];

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [_bar addGestureRecognizer:doubleTap];

    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    pinch.delegate = self;
    [_chrome addGestureRecognizer:pinch];
}

#pragma mark - 手势

- (void)onBarPan:(UIPanGestureRecognizer *)g {
    if (self.fullscreen) return;
    CGPoint t = [g translationInView:self];
    if (g.state == UIGestureRecognizerStateBegan) {
        self.startOrigin = self.frame.origin;
    }
    CGRect f = self.frame;
    f.origin.x = self.startOrigin.x + t.x;
    f.origin.y = self.startOrigin.y + t.y;
    self.frame = [self clampFrame:f];
    [g setTranslation:CGPointZero inView:self];
}

- (void)onGripPan:(UIPanGestureRecognizer *)g {
    if (self.fullscreen) return;
    CGPoint t = [g translationInView:self];
    if (g.state == UIGestureRecognizerStateBegan) {
        self.startSize = self.frame.size;
    }
    CGFloat minW = 180, minH = 200;
    CGSize s = CGSizeMake(MAX(minW, self.startSize.width + t.x),
                          MAX(minH, self.startSize.height + t.y));
    CGRect f = self.frame;
    f.size = s;
    self.frame = [self clampFrame:f];
    [g setTranslation:CGPointZero inView:self];
}

- (void)onPinch:(UIPinchGestureRecognizer *)g {
    if (self.fullscreen) return;
    if (g.state == UIGestureRecognizerStateBegan) self.startSize = self.frame.size;
    CGFloat scale = g.scale;
    CGRect f = self.frame;
    f.size = CGSizeMake(MAX(180, self.startSize.width * scale),
                        MAX(200, self.startSize.height * scale));
    self.frame = [self clampFrame:f];
}

- (void)onDoubleTap {
    [self onExpand];
}

- (void)onClose {
    if ([self.phDelegate respondsToSelector:@selector(phWindowDidRequestClose:)]) {
        [self.phDelegate phWindowDidRequestClose:self];
    }
}

- (void)onExpand {
    if (self.fullscreen) {
        self.frame = self.restoreFrame;
        self.fullscreen = NO;
        [_expandBtn setImage:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"] forState:UIControlStateNormal];
    } else {
        self.restoreFrame = self.frame;
        CGRect b = self.screen.bounds;
        self.frame = CGRectInset(b, 10, 10);
        self.fullscreen = YES;
        [_expandBtn setImage:[UIImage systemImageNamed:@"arrow.down.right.and.arrow.up.left"] forState:UIControlStateNormal];
    }
    [self layoutChrome];
}

- (CGRect)clampFrame:(CGRect)f {
    CGRect b = self.screen.bounds;
    CGFloat minVisible = 60;
    if (f.origin.x + f.size.width < minVisible) f.origin.x = minVisible - f.size.width;
    if (f.origin.x > b.size.width - minVisible) f.origin.x = b.size.width - minVisible;
    if (f.origin.y < 0) f.origin.y = 0;
    if (f.origin.y + f.size.height > b.size.height) f.origin.y = b.size.height - f.size.height;
    return f;
}

- (void)layoutChrome {
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    _chrome.frame = CGRectMake(0, 0, w, h);
    _bar.frame = CGRectMake(0, 0, w, PHBarHeight);
    _titleLabel.frame = CGRectMake(10, 0, w - 84, PHBarHeight);
    _closeBtn.frame = CGRectMake(w - 30, 4, 22, 22);
    _expandBtn.frame = CGRectMake(w - 58, 4, 22, 22);
    _contentContainer.frame = CGRectMake(0, PHBarHeight, w, h - PHBarHeight);
    _grip.frame = CGRectMake(w - 26, h - 26, 26, 26);
}

#pragma mark - 生命周期

- (void)presentWithSize:(CGSize)size edge:(NSInteger)edge cornerRadius:(CGFloat)radius shadow:(BOOL)shadow {
    self.cornerRadius = radius;
    _chrome.layer.cornerRadius = radius;

    CGRect b = self.screen.bounds;
    CGFloat w = MIN(size.width, b.size.width - 20);
    CGFloat h = MIN(size.height, b.size.height - 80);
    CGFloat x = (edge == 1) ? 10 : (b.size.width - w - 10);
    CGFloat y = (b.size.height - h) / 2.0;
    self.frame = CGRectMake(x, y, w, h);

    if (shadow) {
        _chrome.layer.shadowColor = UIColor.blackColor.CGColor;
        _chrome.layer.shadowOpacity = 0.45;
        _chrome.layer.shadowRadius = 18;
        _chrome.layer.shadowOffset = CGSizeMake(0, 8);
        _chrome.layer.masksToBounds = NO;
        _contentContainer.layer.cornerRadius = MAX(0, radius - 6);
        _contentContainer.layer.masksToBounds = YES;
    } else {
        _chrome.layer.masksToBounds = YES;
    }

    [self layoutChrome];
    self.hidden = NO;

    PHLog(@"浮窗: frame = %@", NSStringFromCGRect(self.frame));
}

- (void)setContentSize:(CGSize)size {
    CGRect f = self.frame;
    f.size = size;
    self.frame = [self clampFrame:f];
    [self layoutChrome];
}

- (void)close {
    self.hidden = YES;
    [self resignKeyWindow];
}

@end
