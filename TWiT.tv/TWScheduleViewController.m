//
//  TWScheduleViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWScheduleViewController.h"
#import "NSDate+comparisons.h"

#import "Schedule.h"

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
    return self.schedule.days.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.schedule.days[section] count];
}

- (float)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Event *show = self.schedule.days[indexPath.section][indexPath.row];
    float height = 50.0f*(show.duration/60.0f);

    return height;
}

- (float)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 21;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    float width = tableView.frame.size.width;
    Event *show = self.schedule.days[section][0];
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 21)];
    header.backgroundColor = [UIColor colorWithWhite:237/255.0 alpha:1];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 19)];
    
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont boldSystemFontOfSize:12];
    title.textAlignment = UITextAlignmentCenter;
    title.shadowColor = [UIColor colorWithWhite:1 alpha:1];
    title.shadowOffset = CGSizeMake(0, 1);
    title.textColor = [UIColor colorWithWhite:132/255.0 alpha:1];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE"];
    title.text = [dateFormatter stringFromDate:show.start];
    
    if(show.start.isToday)
        title.text = @"Today";
    else if(show.start.isTomorrow)
        title.text = @"Tomorrow";
    
    [header addSubview:title];
    
    
    UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height, width, 1)];
    botLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    botLine.backgroundColor = [UIColor whiteColor];
    [header addSubview:botLine];
    
    
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifier = @"scheduleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    float width = tableView.frame.size.width;
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 1)];
    topLine.backgroundColor = [UIColor whiteColor];
    [cell.contentView addSubview:topLine];
    
    UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height-1, width, 1)];
    botLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    botLine.backgroundColor = [UIColor colorWithWhite:222/255.0 alpha:1];
    [cell.contentView addSubview:botLine];
    
    Event *show = self.schedule.days[indexPath.section][indexPath.row];
    
    if(show.end.isBeforeNow)
    {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    else
    {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
    NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
    [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatterLocal setDateFormat:@"h:mm a"];
    cell.textLabel.text = [dateFormatterLocal stringFromDate:show.start];
    
    cell.detailTextLabel.text = show.title;
    
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
