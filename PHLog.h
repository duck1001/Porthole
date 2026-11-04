//
//  PHLog.h — 舷窗黑匣子
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void PHLog(NSString *fmt, ...) NS_FORMAT_FUNCTION(1, 2);
NSString *PHLogRead(void);
void PHLogClear(void);
NSString *PHLogPath(void);

NS_ASSUME_NONNULL_END
