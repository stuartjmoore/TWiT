//
//  TWScheduleViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWScheduleViewController.h"
#import "TWNavigationController.h"
#import "NSDate+comparisons.h"

#import "TWScheduleCell.h"

#import "Schedule.h"
#import "Show.h"

@implementation TWScheduleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [NSNotificationCenter.defaultCenter addObserver:self.tableView
                                           selector:@selector(reloadData)
                                               name:@"ScheduleDidUpdate"
                                             object:nil];
    
    if(self.schedule.days.count > 0)
    {
        NSInteger row = [self.schedule.days[0] indexOfObject:self.schedule.currentShow];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.schedule.days.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.schedule.days[section] count];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    Event *show = self.schedule.days[indexPath.section][indexPath.row];
    CGFloat height = 50.0f*(show.duration/60.0f);

    return height;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(self.schedule.days.count <= section)
        return 0;
    else if([self.schedule.days[section] count] == 0)
        return 0;
    
    return 21;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat width = tableView.frame.size.width;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 21)];
    header.backgroundColor = [UIColor colorWithWhite:237/255.0 alpha:1];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 19)];
    
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont systemFontOfSize:12];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [UIColor colorWithWhite:132/255.0 alpha:1];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE"];
    
    if(self.schedule.days.count <= section)
        title.text = @"";
    else if([self.schedule.days[section] count] == 0)
        title.text = @"";
    else
    {
        Event *show = self.schedule.days[section][0];
        
        title.text = [dateFormatter stringFromDate:show.start];
        
        if(show.start.isToday)
            title.text = @"Today";
        else if(show.start.isTomorrow)
            title.text = @"Tomorrow";
    }
    
    [header addSubview:title];
    
    UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height, width, 1)];
    botLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    botLine.backgroundColor = [UIColor colorWithWhite:228/255.0 alpha:1];
    [header addSubview:botLine];
    
    return header;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifier = @"scheduleCell";
    TWScheduleCell *cell = (TWScheduleCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    CGFloat width = tableView.frame.size.width;
    
    UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height-1, width, 1)];
    botLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    botLine.backgroundColor = [UIColor colorWithWhite:222/255.0 alpha:1];
    [cell.contentView addSubview:botLine];
    
    Event *show = self.schedule.days[indexPath.section][indexPath.row];
    cell.event = show;
    
    return cell;
}

#pragma mark - Settings

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Leave

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self.tableView name:@"ScheduleDidUpdate" object:nil];
    
    [super viewWillDisappear:animated];
}

@end
