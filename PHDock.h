//
//  PHDock.h — 边缘把手
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PHDock;

@protocol PHDockDelegate <NSObject>
- (void)phDockDidTap:(PHDock *)dock;
- (void)phDockDidLongPress:(PHDock *)dock;
@end

@interface PHDock : UIWindow

@property (nonatomic, weak, nullable) id<PHDockDelegate> dockDelegate;

- (void)presentEdge:(NSInteger)edge bundleID:(NSString *)bundleID;
- (void)hide;
- (void)refreshIconForBundle:(NSString *)bundleID;

@end

NS_ASSUME_NONNULL_END
