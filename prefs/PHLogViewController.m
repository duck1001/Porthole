//
//  PHLogViewController.m
//

#import "PHLogViewController.h"

@implementation PHLogViewController {
    UITextView *_text;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"黑匣子";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    _text = [[UITextView alloc] initWithFrame:self.view.bounds];
    _text.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _text.editable = NO;
    _text.alwaysBounceVertical = YES;
    _text.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    _text.textContainerInset = UIEdgeInsetsMake(8, 8, 24, 8);
    [self.view addSubview:_text];

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                      target:self
                                                      action:@selector(reload)];
    [self reload];
}

- (void)reload {
    NSString *p = @"/var/mobile/Library/Porthole/porthole.log";
    NSString *s = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:NULL];
    _text.text = s.length ? s : @"(空 — SpringBoard 侧还没写日志)";
    if (_text.text.length > 0) {
        [_text scrollRangeToVisible:NSMakeRange(_text.text.length - 1, 1)];
    }
}

@end
