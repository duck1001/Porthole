//
//  PHLog.m
//

#import "PHLog.h"

static NSString *gLogPath = nil;
static NSLock *gLogLock = nil;

static void PHLogEnsurePath(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        gLogLock = [NSLock new];
        NSString *dir = @"/var/mobile/Library/Porthole";
        NSError *err = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:@{NSFilePosixPermissions: @0777}
                                                        error:&err];
        if (err) {
            gLogPath = PH_FALLBACK_LOG;
        } else {
            gLogPath = PH_LOG_PATH;
        }
        [[NSFileManager defaultManager] createFileAtPath:gLogPath contents:nil attributes:nil];
        [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0666}
                                         ofItemAtPath:gLogPath error:NULL];
    });
}

NSString *PHLogPath(void) {
    PHLogEnsurePath();
    return gLogPath;
}

void PHLog(NSString *fmt, ...) {
    PHLogEnsurePath();
    va_list ap;
    va_start(ap, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MM-dd HH:mm:ss.SSS";
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", [df stringFromDate:[NSDate date]], msg];

    [gLogLock lock];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:gLogPath];
    if (!fh) {
        [[NSFileManager defaultManager] createFileAtPath:gLogPath contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:gLogPath];
    }
    @try {
        [fh seekToEndOfFile];
        [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (__unused NSException *e) {}
    [fh closeFile];

    unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:gLogPath error:NULL] fileSize];
    if (size > 256 * 1024) {
        NSString *old = [gLogPath stringByAppendingString:@".1"];
        [[NSFileManager defaultManager] removeItemAtPath:old error:NULL];
        [[NSFileManager defaultManager] moveItemAtPath:gLogPath toPath:old error:NULL];
    }
    [gLogLock unlock];

    NSLog(@"[Porthole] %@", msg);
}

NSString *PHLogRead(void) {
    PHLogEnsurePath();
    NSString *s = [NSString stringWithContentsOfFile:gLogPath encoding:NSUTF8StringEncoding error:NULL];
    return s ?: @"(空)";
}

void PHLogClear(void) {
    PHLogEnsurePath();
    [[NSFileManager defaultManager] removeItemAtPath:gLogPath error:NULL];
    [[NSFileManager defaultManager] createFileAtPath:gLogPath contents:nil attributes:nil];
    [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0666}
                                     ofItemAtPath:gLogPath error:NULL];
}
