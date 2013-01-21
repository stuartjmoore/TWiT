//
//  TWScheduleGridViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "NSDate+comparisons.h"

#import "TWScheduleGridViewController.h"

#import "Schedule.h"
#import "Show.h"

#define hourWidth 250.0f

@implementation TWScheduleGridViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    for(NSArray *day in self.schedule.days)
    {
        int i = [self.schedule.days indexOfObject:day];
        for(Event *event in day)
        {
            float height = self.scrollView.bounds.size.height/7.0f;
            CGRect frame = CGRectMake(event.start.floatTime*hourWidth, i*height, event.duration/60.0f*hourWidth, height);
            
            
            UIView *view = [[UIView alloc] initWithFrame:frame];
            view.backgroundColor = [UIColor colorWithWhite:0.96f alpha:1];
            
            UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, height-1, event.duration/60.0f*hourWidth, 1)];
            botLine.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:botLine];
            UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(event.duration/60.0f*hourWidth-1, 0, 1, height)];
            rightLine.backgroundColor = [UIColor colorWithWhite:0.87f alpha:1];
            [view addSubview:rightLine];
            UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, event.duration/60.0f*hourWidth, 1)];
            topLine.backgroundColor = [UIColor whiteColor];
            [view addSubview:topLine];
            UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, height)];
            leftLine.backgroundColor = [UIColor whiteColor];
            [view addSubview:leftLine];
            
            CGRect titleFrame = CGRectMake(10, 10, view.frame.size.width-20, view.frame.size.height-20);
            UILabel *title = [[UILabel alloc] initWithFrame:titleFrame];
            title.backgroundColor = [UIColor clearColor];
            title.font = [UIFont boldSystemFontOfSize:14];
            title.text = event.title;
            [view addSubview:title];
            
            [self.scrollView addSubview:view];
        }
    }
    
    NSDate *now = [NSDate date];
    CGRect nowFrame = CGRectMake(now.floatTime*hourWidth, 0, 1, self.scrollView.bounds.size.height);
    
    UIView *nowLine = [[UIView alloc] initWithFrame:nowFrame];
    nowLine.backgroundColor = [UIColor redColor];
    [self.scrollView addSubview:nowLine];
    
    nowFrame.size.width = self.scrollView.bounds.size.width;
    nowFrame.origin.x -= self.scrollView.bounds.size.width/2.0f;
    [self.scrollView scrollRectToVisible:nowFrame animated:NO];
    
    
    // timer to move now line
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
        return (interfaceOrientation == UIInterfaceOrientationMaskPortrait);
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