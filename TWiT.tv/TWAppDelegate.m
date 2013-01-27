//
//  TWAppDelegate.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"
#import "TWSplitViewContainer.h"
#import "TWNavigationContainer.h"
#import "TWNavigationController.h"
#import "TWMainViewController.h"
#import "TWPlaybarViewController.h"

#import "NSDate+comparisons.h"

#import "Channel.h"
#import "Show.h"
#import "Episode.h"
#import "Enclosure.h"
#import "Stream.h"

@implementation TWAppDelegate

@synthesize managedObjectContext = _managedObjectContext, managedObjectModel = _managedObjectModel, persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    [AVAudioSession.sharedInstance setActive:YES error:nil];
    
    
    NSManagedObjectContext *context = self.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Channel" inManagedObjectContext:context]];
    
    NSArray *fetchedChannels = [context executeFetchRequest:fetchRequest error:nil];
    self.channel = fetchedChannels.lastObject ?: [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:context];
    
    [self.channel update];
    
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.window.rootViewController;
        splitViewContainer.view = splitViewContainer.view;
        
        UINavigationController *masterController = [splitViewContainer.storyboard instantiateViewControllerWithIdentifier:@"masterController"];
        TWMainViewController *episodesController = (TWMainViewController*)masterController.topViewController;
        episodesController.managedObjectContext = self.managedObjectContext;
        episodesController.channel = self.channel;
        episodesController.splitViewContainer = splitViewContainer;
        splitViewContainer.masterController = masterController;

        UINavigationController *detailController = [splitViewContainer.storyboard instantiateViewControllerWithIdentifier:@"detailController"];
        TWMainViewController *showsController = (TWMainViewController*)detailController.topViewController;
        showsController.managedObjectContext = self.managedObjectContext;
        showsController.channel = self.channel;
        showsController.splitViewContainer = splitViewContainer;
        splitViewContainer.detailController = detailController;
        
        UINavigationController *modalController = [splitViewContainer.storyboard instantiateViewControllerWithIdentifier:@"modalController"];
        splitViewContainer.modalController = modalController;
        
        TWPlaybarViewController *playbarController = (TWPlaybarViewController*)[splitViewContainer.storyboard instantiateViewControllerWithIdentifier:@"playbarController"];
        splitViewContainer.playbarController = playbarController;
        playbarController.splitViewContainer = splitViewContainer;
    }
    else
    {
        UIImage *navigationBarImage = [UIImage imageNamed:@"navbar-background.png"];
        [UINavigationBar.appearance setBackgroundImage:navigationBarImage forBarMetrics:UIBarMetricsDefault];
        
        UIImage *backButtonImage = [[UIImage imageNamed:@"navbar-back.png"] stretchableImageWithLeftCapWidth:14 topCapHeight:15];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        navigationContainer.view = navigationContainer.view;
        
        TWNavigationController *navigationController = [navigationContainer.storyboard instantiateViewControllerWithIdentifier:@"navigationController"];
        navigationContainer.masterController = navigationController;
        navigationController.navigationContainer = navigationContainer;
        TWMainViewController *controller = (TWMainViewController*)navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.channel = self.channel;
        
        TWPlaybarViewController *playbarController = (TWPlaybarViewController*)[controller.storyboard instantiateViewControllerWithIdentifier:@"playbarController"];
        navigationContainer.playbarController = playbarController;
        playbarController.navigationContainer = navigationContainer;
    }
    
    return YES;
}

- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.window.rootViewController;
        TWMainViewController *showsController = (TWMainViewController*)splitViewContainer.detailController.topViewController;

        [showsController transitionToLive:nil];
    }
    else
    {
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
        [navigationController popToRootViewControllerAnimated:NO];
        
        TWMainViewController *controller = (TWMainViewController*)navigationController.topViewController;
        [controller performSegueWithIdentifier:@"liveVideoDetail" sender:nil];
    }
}

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.window.rootViewController;
        TWMainViewController *showsController = (TWMainViewController*)splitViewContainer.detailController.topViewController;
        
        [showsController transitionToLive:nil];
    }
    else
    {
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
        [navigationController popToRootViewControllerAnimated:NO];
        
        TWMainViewController *controller = (TWMainViewController*)navigationController.topViewController;
        [controller performSegueWithIdentifier:@"liveVideoDetail" sender:nil];
    }
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    for(Show *show in self.channel.shows)
        if(show.favorite)
            [show updateEpisodes];
    
    if(self.channel.schedule.days.count > 0)
    {
        NSArray *firstDay = self.channel.schedule.days[0];
        
        if(firstDay.count > 0)
        {
            Event *firstShow = (Event*)firstDay[0];
            
            if(!firstShow.start.isToday)
                [self.channel reloadSchedule];
        }
        else
        {
            [self.channel reloadSchedule];
        }
    }
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.window.rootViewController;
        UINavigationController *detailController = splitViewContainer.detailController;
        TWMainViewController *showsController = (TWMainViewController*)detailController.topViewController;
        
        if([showsController respondsToSelector:@selector(redrawSchedule:)])
            [showsController redrawSchedule:nil];
    }
    else
    {
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
        TWMainViewController *controller = (TWMainViewController*)navigationController.topViewController;
        
        if([controller respondsToSelector:@selector(redrawSchedule:)])
            [controller redrawSchedule:nil];
    }
}

- (void)applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}
- (void)applicationDidEnterBackground:(UIApplication*)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if([self.nowPlaying isKindOfClass:Enclosure.class])
        [[self.nowPlaying episode] setLastTimecode:self.player.currentPlaybackTime];
    
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Controls

- (MPMoviePlayerController*)player
{
    if(_player == nil)
    {
        _player = [[MPMoviePlayerController alloc] init];
        _player.controlStyle = MPMovieControlStyleNone;
        _player.shouldAutoplay = YES;
        _player.allowsAirPlay = YES;
        _player.scalingMode = MPMovieScalingModeAspectFit;
    }
    
    return _player;
}

- (void)setNowPlaying:(id)nowPlaying
{
    if(self.player && [_nowPlaying isKindOfClass:Enclosure.class])
        [[_nowPlaying episode] setLastTimecode:self.player.currentPlaybackTime];
    
    if([nowPlaying isKindOfClass:Enclosure.class])
    {
        Enclosure *enclosure = (Enclosure*)nowPlaying;
        
        NSURL *url = enclosure.path ? [NSURL fileURLWithPath:enclosure.path] : [NSURL URLWithString:enclosure.url];
        self.player.contentURL = url;
        self.player.initialPlaybackTime = enclosure.episode.lastTimecode;
        [self play];
    }
    else if([nowPlaying isKindOfClass:Stream.class])
    {
        Stream *stream = (Stream*)nowPlaying;
        self.player.contentURL = [NSURL URLWithString:stream.url];
        [self play];
    }
    
    _nowPlaying = nowPlaying;
}

- (void)play
{
    [UIApplication.sharedApplication beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (void)stop
{
    [UIApplication.sharedApplication endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    self.nowPlaying = nil;
    
    [self.player stop];
    self.player = nil;
}

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
    if(event.type == UIEventTypeRemoteControl)
    {
        switch(event.subtype)
        {
            case UIEventSubtypeRemoteControlPlay:
                [self play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self pause];
                break;
            case UIEventSubtypeRemoteControlStop:
                [self stop];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if(self.player.playbackState == MPMoviePlaybackStatePlaying)
                    [self pause];
                else
                    [self play];
                break;
            default:
                break;
        }
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Settings

- (NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
    NSUInteger res = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)? UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskAll;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)window.rootViewController;
        res = splitViewContainer.supportedInterfaceOrientations;
    }
    else if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)window.rootViewController;
        TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
        UIViewController *presented = navigationController.topViewController;
        res = presented.supportedInterfaceOrientations;
    }
    
    return res;
}

#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if(managedObjectContext != nil)
    {
        if([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        } 
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if(_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if(coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel*)managedObjectModel
{
    if(_managedObjectModel != nil)
        return _managedObjectModel;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TWiT_tv" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    if(_persistentStoreCoordinator != nil)
        return _persistentStoreCoordinator;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"TWiT_tv.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*

         Typical reasons for an error here include:
       * The persistent store is not accessible;
       * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
       * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
       * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
