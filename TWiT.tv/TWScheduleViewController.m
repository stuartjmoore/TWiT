//
//  TWScheduleViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWScheduleViewController.h"
#import "NSDate+comparisons.h"

@implementation TWScheduleViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.schedule.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.schedule[section] count];
}


- (float)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    float width = tableView.frame.size.width;
    NSDate *startTime = self.schedule[section][0][@"startDate"];
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(107, 0, width-107, 20)];
    
    headerLabel.backgroundColor = [UIColor clearColor];
    //headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont systemFontOfSize:12];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE"];
    headerLabel.text = [dateFormatter stringFromDate:startTime];
    
    if(startTime.isToday)
        headerLabel.text = @"Today";
    else if(startTime.isTomorrow)
        headerLabel.text = @"Tomorrow";
    
    [header addSubview:headerLabel];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifier = @"scheduleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *show = self.schedule[indexPath.section][indexPath.row];
    
    NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
    [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatterLocal setDateFormat:@"h:mm a"];
    cell.textLabel.text = [dateFormatterLocal stringFromDate:show[@"startDate"]];
    
    cell.detailTextLabel.text = show[@"title"];
    
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
