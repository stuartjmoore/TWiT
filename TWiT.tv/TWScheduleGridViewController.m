//
//  TWScheduleGridViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NSDate+comparisons.h"

#import "TWScheduleGridViewController.h"

#import "Schedule.h"
#import "Show.h"

#define timeHeight 20.0f
#define hourWidth 250.0f

@implementation TWScheduleGridViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *liveGradient = [CAGradientLayer layer];
    liveGradient.anchorPoint = CGPointMake(0, 0);
    liveGradient.position = CGPointMake(0, 0);
    liveGradient.startPoint = CGPointMake(0, 0);
    liveGradient.endPoint = CGPointMake(1, 0);
    liveGradient.bounds = self.gradientView.bounds;
    liveGradient.colors = [NSArray arrayWithObjects:
                           (id)[UIColor colorWithWhite:0.96f alpha:1].CGColor,
                           (id)[UIColor colorWithWhite:0.96f alpha:0.6f].CGColor,
                           (id)[UIColor colorWithWhite:0.96f alpha:0].CGColor, nil];
    [self.gradientView.layer addSublayer:liveGradient];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.scrollView.contentSize = CGSizeMake(250*24, self.scrollView.bounds.size.height);
    [self drawSchedule];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(drawSchedule)
                                               name:@"ScheduleDidUpdate"
                                             object:nil];
}

- (void)drawSchedule
{
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for(NSInteger hour = 0; hour < 24; hour++)
    {
        CGRect frame = CGRectMake(hour*hourWidth, 0, hourWidth, timeHeight);
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
        NSDateComponents *comps = [gregorian components:unitFlags fromDate:[NSDate date]];
        [comps setHour:hour];
        NSDate *hourDate = [gregorian dateFromComponents:comps];
        
        NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
        [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
        [dateFormatterLocal setDateFormat:@"h:mma"];
        [dateFormatterLocal setPMSymbol:@"p"];
        [dateFormatterLocal setAMSymbol:@"a"];
        NSString *timeTitle = [dateFormatterLocal stringFromDate:hourDate];
        
        /*
        BOOL is24Hour = [NSDate is24Hour];
        NSString *suffix = is24Hour ? @"" : (hour < 12 ? @"a" : @"p");
        NSInteger maxHour = is24Hour ? 24 : 12;
        
        NSString *timeTitle = (hour < maxHour) ? [NSString stringWithFormat:@"%d:00%@", hour, suffix]
                                               : [NSString stringWithFormat:@"%d:00%@", hour-maxHour, suffix];
        
        if([timeTitle isEqualToString:@"0:00p"])
            timeTitle = @"Noon";
        */
        
        
        UIView *view = [[UIView alloc] initWithFrame:frame];
        
        CGRect titleFrame = CGRectMake(10, 0, view.frame.size.width-20, view.frame.size.height);
        UILabel *title = [[UILabel alloc] initWithFrame:titleFrame];
        title.backgroundColor = [UIColor clearColor];
        title.textColor = [UIColor darkGrayColor];
        title.font = [UIFont systemFontOfSize:14];
        title.text = timeTitle;
        [view addSubview:title];
        
        [self.scrollView addSubview:view];
        
    }
    
    CGFloat minX = self.scrollView.contentSize.width, maxX = 0;
    
    for(NSArray *day in self.schedule.days)
    {
        NSInteger i = [self.schedule.days indexOfObject:day];
        for(Event *event in day)
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"EEEE"];
            
            if(i == 2)
                self.day2Label.text = [dateFormatter stringFromDate:event.start];
            else if(i == 3)
                self.day3label.text = [dateFormatter stringFromDate:event.start];
            else if(i == 4)
                self.day4Label.text = [dateFormatter stringFromDate:event.start];
            else if(i == 5)
                self.day5Label.text = [dateFormatter stringFromDate:event.start];
            else if(i == 6)
                self.day6Label.text = [dateFormatter stringFromDate:event.start];
            
            CGFloat height = (self.scrollView.bounds.size.height-timeHeight)/7.0f;
            CGRect frame = CGRectMake(event.start.floatTime*hourWidth, timeHeight+i*height, event.duration/60.0f*hourWidth, height);
            
            if(frame.origin.x < minX)
                minX = frame.origin.x;
            
            if(frame.origin.x+frame.size.width > maxX)
                maxX = frame.origin.x+frame.size.width;
            
            UIView *view = [[UIView alloc] initWithFrame:frame];
            
            UIView *topLineOut = [[UIView alloc] initWithFrame:CGRectMake(-1, -1, frame.size.width+2, 1)];
            topLineOut.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:topLineOut];
            
            UIView *leftLineOut = [[UIView alloc] initWithFrame:CGRectMake(-1, -1, 1, frame.size.height+2)];
            leftLineOut.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:leftLineOut];
            
            UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-1, frame.size.width, 1)];
            botLine.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:botLine];
            
            UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width-1, 0, 1, frame.size.height)];
            rightLine.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:rightLine];
            
            CGRect titleFrame = CGRectMake(20, 10, view.frame.size.width-20, view.frame.size.height-20);
            UILabel *title = [[UILabel alloc] initWithFrame:titleFrame];
            title.backgroundColor = [UIColor clearColor];
            title.font = [UIFont systemFontOfSize:18];
            title.text = event.title;
            [view addSubview:title];
            
            CGRect subtitleFrame = CGRectMake(20, view.frame.size.height/2.0f, view.frame.size.width-20, view.frame.size.height/2.0f);
            UILabel *subtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
            subtitle.backgroundColor = [UIColor clearColor];
            subtitle.font = [UIFont systemFontOfSize:14];
            subtitle.textColor = [UIColor darkGrayColor];
            subtitle.text = event.subtitle;
            [view addSubview:subtitle];
            
            [self.scrollView addSubview:view];
        }
    }
    
    minX -= hourWidth/2.0f;
    maxX += hourWidth/2.0f;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(0, -minX, 0, maxX-self.scrollView.contentSize.width);
    
    [self drawNowLine];
    
    [self scrollToNow:nil];
}
- (void)drawNowLine
{
    NSDate *now = [NSDate date];

    [self.nowLine removeFromSuperview];
    self.nowLine = [[UIView alloc] init];
    self.nowLine.backgroundColor = [UIColor colorWithRed:52.0/255 green:170.0/255 blue:210.0/255 alpha:1];
    CGFloat height = (self.scrollView.bounds.size.height-timeHeight)/7.0f;
    self.nowLine.frame = CGRectMake(now.floatTime*hourWidth, timeHeight/2.0f, 1, height+timeHeight);
    [self.scrollView addSubview:self.nowLine];
    
    
    CGRect nowFrame = self.nowLine.frame;
    nowFrame.size.width = self.scrollView.bounds.size.width;
    nowFrame.origin.x -= self.scrollView.bounds.size.width/2.0f;
    
    CGFloat minX = -self.scrollView.contentInset.left;
    CGFloat maxX = self.scrollView.contentInset.right+self.scrollView.contentSize.width;
    
    if(nowFrame.origin.x < minX)
        minX = nowFrame.origin.x;
    
    if(nowFrame.origin.x+nowFrame.size.width > maxX)
        maxX = nowFrame.origin.x+nowFrame.size.width;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(0, -minX, 0, maxX-self.scrollView.contentSize.width);
    
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawNowLine) object:nil];
    [self performSelector:@selector(drawNowLine) withObject:nil afterDelay:60];
}

#pragma mark - Actions

- (IBAction)scrollToNow:(UIBarButtonItem*)sender
{
    CGRect nowFrame = self.nowLine.frame;
    nowFrame.size.width = self.scrollView.bounds.size.width;
    nowFrame.origin.x -= self.scrollView.bounds.size.width/2.0f;
    [self.scrollView scrollRectToVisible:nowFrame animated:(bool)sender];
}

#pragma mark - Rotate

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    self.scrollView.contentSize = CGSizeMake(250*24, self.scrollView.bounds.size.height);
    [self drawSchedule];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Leave

- (IBAction)close:(UIBarButtonItem*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"ScheduleDidUpdate" object:nil];
    [super viewWillDisappear:animated];
}

@end