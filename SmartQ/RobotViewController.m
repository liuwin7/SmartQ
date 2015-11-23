//
//  ViewController.m
//  SmartQ
//
//  Created by tropsci on 15/11/18.
//  Copyright © 2015年 topsci. All rights reserved.
//

#import "RobotViewController.h"
#import "ChatRobotDB.h"
#import "ITPKRobot.h"
#import "RobotChatMessageViewController.h"

NSString *const ROBOT_CHAT_SEGUE_ID = @"showRobotChatRoomSegueID";

@interface RobotViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property(nonatomic, strong)NSArray <RobotProtocol> *robots;

@end

@implementation RobotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.061 green:0.557 blue:0.943 alpha:1.000]];
    [self initRobots];
}

#pragma mark -
- (void)initRobots {
    self.robots = [NSArray<RobotProtocol> arrayWithArray:[[ChatRobotDB sharedInstance] allRobots]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.robots.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableViewCellIdentifier = @"rebotTypeIdentify";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellIdentifier];
    id<RobotProtocol> robot = [self.robots objectAtIndex:indexPath.row];
    cell.textLabel.text = [robot robotName];
    cell.imageView.image = [UIImage imageNamed:[robot robotAvator]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"机器人";
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:ROBOT_CHAT_SEGUE_ID]) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForCell:sender];
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
        
        id<RobotProtocol> robot = [self.robots objectAtIndex:selectedIndexPath.row];
        ChatModelData *modelData = [[ChatModelData alloc] initWithRobot:robot];

        RobotChatMessageViewController *chatVC = (RobotChatMessageViewController *)segue.destinationViewController;
        
        chatVC.robot = robot;
        chatVC.chatData = modelData;
    }
}

@end
