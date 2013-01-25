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
    
    for(int hour = 0; hour < 24; hour++)
    {
        CGRect frame = CGRectMake(hour*hourWidth, 0, hourWidth, timeHeight);
        
        NSString *timeTitle = (hour <= 12) ? [NSString stringWithFormat:@"%d:00am", hour] : [NSString stringWithFormat:@"%d:00pm", hour-12];
        
        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor colorWithWhite:0.96f alpha:1];
        
        CGRect titleFrame = CGRectMake(10, 0, view.frame.size.width-20, view.frame.size.height);
        UILabel *title = [[UILabel alloc] initWithFrame:titleFrame];
        title.backgroundColor = [UIColor clearColor];
        title.textColor = [UIColor darkGrayColor];
        title.font = [UIFont systemFontOfSize:14];
        title.text = timeTitle;
        [view addSubview:title];
        
        [self.scrollView addSubview:view];
        
    }
    
    // TODO: name days
    
    float minX = self.scrollView.contentSize.width, maxX = 0;
    
    for(NSArray *day in self.schedule.days)
    {
        int i = [self.schedule.days indexOfObject:day];
        for(Event *event in day)
        {
            float height = (self.scrollView.bounds.size.height-timeHeight)/7.0f;
            CGRect frame = CGRectMake(event.start.floatTime*hourWidth, timeHeight+i*height, event.duration/60.0f*hourWidth, height);
            
            if(frame.origin.x < minX)
                minX = frame.origin.x;
            
            if(frame.origin.x+frame.size.width > maxX)
                maxX = frame.origin.x+frame.size.width;
            
            UIView *view = [[UIView alloc] initWithFrame:frame];
            view.backgroundColor = [UIColor colorWithWhite:0.96f alpha:1];
            
            
            UIView *topLineOut = [[UIView alloc] initWithFrame:CGRectMake(-1, -1, frame.size.width+2, 1)];
            topLineOut.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:topLineOut];
            
            UIView *rightLineOut = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width, -1, 1, frame.size.height+2)];
            rightLineOut.backgroundColor = [UIColor whiteColor];
            [view addSubview:rightLineOut];
            
            UIView *leftLineOut = [[UIView alloc] initWithFrame:CGRectMake(-1, -1, 1, frame.size.height+2)];
            leftLineOut.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:leftLineOut];
            
            UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, frame.size.height)];
            leftLine.backgroundColor = [UIColor whiteColor];
            [view addSubview:leftLine];
            
            UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-1, frame.size.width, 1)];
            botLine.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:botLine];
            UIView *botLineOut = [[UIView alloc] initWithFrame:CGRectMake(-1, frame.size.height, frame.size.width+2, 1)];
            botLineOut.backgroundColor = [UIColor whiteColor];
            [view addSubview:botLineOut];
            
            UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 1)];
            topLine.backgroundColor = [UIColor whiteColor];
            [view addSubview:topLine];
            
            UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width-1, 0, 1, frame.size.height)];
            rightLine.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:rightLine];
            
            
            CGRect titleFrame = CGRectMake(10, 10, view.frame.size.width-20, view.frame.size.height-20);
            UILabel *title = [[UILabel alloc] initWithFrame:titleFrame];
            title.backgroundColor = [UIColor clearColor];
            title.font = [UIFont boldSystemFontOfSize:14];
            title.text = event.title;
            [view addSubview:title];
            
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
    self.nowLine.backgroundColor = [UIColor colorWithRed:61/255.0 green:122/255.0 blue:155/255.0 alpha:0.75f];
    float height = (self.scrollView.bounds.size.height-timeHeight)/7.0f;
    self.nowLine.frame = CGRectMake(now.floatTime*hourWidth, timeHeight/2.0f, 1, height+timeHeight);
    [self.scrollView addSubview:self.nowLine];
    
    
    CGRect nowFrame = self.nowLine.frame;
    nowFrame.size.width = self.scrollView.bounds.size.width;
    nowFrame.origin.x -= self.scrollView.bounds.size.width/2.0f;
    
    float minX = -self.scrollView.contentInset.left;
    float maxX = self.scrollView.contentInset.right+self.scrollView.contentSize.width;
    
    if(nowFrame.origin.x < minX)
        minX = nowFrame.origin.x;
    
    if(nowFrame.origin.x+nowFrame.size.width > maxX)
        maxX = nowFrame.origin.x+nowFrame.size.width;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(0, -minX, 0, maxX-self.scrollView.contentSize.width);
    
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawNowLine) object:nil];
    [self performSelector:@selector(drawNowLine) withObject:nil afterDelay:60];
}

#pragma mark - Actions

- (IBAction)scrollToNow:(UIButton*)sender
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Leave

- (IBAction)close:(UIBarButtonItem*)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"ScheduleDidUpdate" object:nil];
    [super viewWillDisappear:animated];
}

@end