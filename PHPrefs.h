//
//  PHPrefs.h — 配置读取
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PHPrefsChangedNotification;

@interface PHPrefs : NSObject
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, copy, readonly)   NSString *targetBundle;
@property (nonatomic, assign, readonly) CGFloat width;
@property (nonatomic, assign, readonly) CGFloat height;
@property (nonatomic, assign, readonly) CGFloat cornerRadius;
@property (nonatomic, assign, readonly) BOOL showDock;
@property (nonatomic, assign, readonly) BOOL shadow;
@property (nonatomic, assign, readonly) BOOL followOrientation;
@property (nonatomic, assign, readonly) NSInteger dockEdge;      // 0 右 1 左
@property (nonatomic, assign, readonly) NSInteger hostStrategy;  // 0 自动 1 呈现器 2 场景视图 3 宿主视图
@property (nonatomic, assign, readonly) NSInteger windowLevel;   // 0 普通 1 高 2 最高

+ (instancetype)shared;
+ (void)setValue:(id)value forKey:(NSString *)key;
- (void)reload;
@end

NS_ASSUME_NONNULL_END
