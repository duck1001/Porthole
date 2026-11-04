//
//  PHWindow.h — 舷窗窗口
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PHWindow;

@protocol PHWindowDelegate <NSObject>
- (void)phWindowDidRequestClose:(PHWindow *)window;
- (void)phWindowDidChangeFrame:(PHWindow *)window;
@end

@interface PHWindow : UIWindow

@property (nonatomic, weak, nullable) id<PHWindowDelegate> phDelegate;
@property (nonatomic, copy, readonly) NSString *bundleID;
@property (nonatomic, strong, readonly) UIView *contentContainer;
@property (nonatomic, copy, nullable) NSString *titleText;
@property (nonatomic, assign) BOOL showsCloseButton;

- (instancetype)initWithBundleID:(NSString *)bundleID;
- (void)presentWithSize:(CGSize)size edge:(NSInteger)edge cornerRadius:(CGFloat)radius shadow:(BOOL)shadow;
- (void)close;
- (void)setContentSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
