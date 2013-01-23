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
    
    float minX = self.scrollView.contentSize.width, maxX = 0;
    
    for(NSArray *day in self.schedule.days)
    {
        int i = [self.schedule.days indexOfObject:day];
        for(Event *event in day)
        {
            float height = self.scrollView.bounds.size.height/7.0f;
            CGRect frame = CGRectMake(event.start.floatTime*hourWidth, i*height, event.duration/60.0f*hourWidth, height);
            
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
    
    minX -= hourWidth/4.0f;
    maxX += hourWidth/4.0f;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(0, -minX, 0, maxX-self.scrollView.contentSize.width);
    
    [self drawNowLine];
    
    CGRect nowFrame = self.nowLine.frame;
    nowFrame.size.width = self.scrollView.bounds.size.width;
    nowFrame.origin.x -= self.scrollView.bounds.size.width/2.0f;
    [self.scrollView scrollRectToVisible:nowFrame animated:NO];
}
- (void)drawNowLine
{
    NSDate *now = [NSDate date];

    [self.nowLine removeFromSuperview];
    self.nowLine = [[UIView alloc] init];
    self.nowLine.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.75f];
    self.nowLine.frame = CGRectMake(now.floatTime*hourWidth, 0, 1, self.scrollView.bounds.size.height);
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