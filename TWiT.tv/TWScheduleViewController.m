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

- (float)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *day = self.schedule[indexPath.section];
    NSDictionary *show = day[indexPath.row];
    
    float duration = [[show objectForKey:@"duration"] floatValue];
    float height = 50.0f*(duration/60.0f);
    /*
    if(indexPath.row+1 < day.count)
    {
        NSDictionary *nextShow = [day objectAtIndex:(indexPath.row+1)];
        NSDate *startDate = [nextShow objectForKey:@"startDate"];
        NSDate *endDate = [show objectForKey:@"endDate"];
        
        if(![startDate isEqualToDate:endDate])
        {
            height += 10;
        }
    }
    */
    return height;
}

- (float)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 21;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    float width = tableView.frame.size.width;
    NSDate *startTime = self.schedule[section][0][@"startDate"];
    
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
    title.text = [dateFormatter stringFromDate:startTime];
    
    if(startTime.isToday)
        title.text = @"Today";
    else if(startTime.isTomorrow)
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
