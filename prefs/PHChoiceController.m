//
//  PHChoiceController.m
//

#import "PHChoiceController.h"
#import "PHPreferences.h"

@interface PHChoiceController ()
@property (nonatomic, copy) NSString *key;
@property (nonatomic, strong) NSArray<NSDictionary *> *options;
@end

@implementation PHChoiceController

- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key options:(NSArray<NSDictionary *> *)options {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        self.title = title;
        _key = [key copy];
        _options = options;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 46;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"c"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
    NSDictionary *o = self.options[indexPath.row];
    cell.textLabel.text = o[@"title"];
    id current = PHValueOrDefault(self.key);
    cell.accessoryType = [o[@"value"] isEqual:current] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *o = self.options[indexPath.row];
    PHSetValue(self.key, o[@"value"]);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
