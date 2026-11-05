//
//  PHChoiceController.h
//

#import <UIKit/UIKit.h>

@interface PHChoiceController : UITableViewController
- (instancetype)initWithTitle:(NSString *)title
                          key:(NSString *)key
                      options:(NSArray<NSDictionary *> *)options;
@end
