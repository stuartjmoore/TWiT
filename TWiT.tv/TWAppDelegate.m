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

#import "NSManagedObjectContext+ConvenienceMethods.h"
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
  
  
    NSString *lastVersionString = [NSUserDefaults.standardUserDefaults objectForKey:@"settings-version"];
    NSString *currVersionString = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    
    if(lastVersionString && ![lastVersionString isEqualToString:currVersionString])
    {
        NSArray *lastVersionNumbers = [lastVersionString componentsSeparatedByString:@"."];
        NSArray *checkVersionNumbers = [@"4.1" componentsSeparatedByString:@"."];
        
        BOOL isUpdated = NO;
        
        for(int i = 0; i < lastVersionNumbers.count || i < checkVersionNumbers.count; i++)
        {
            int lastNumber = (i < lastVersionNumbers.count)?[lastVersionNumbers[i] intValue]:0;
            int checkNumber = (i < checkVersionNumbers.count)?[checkVersionNumbers[i] intValue]:0;
            
            if(lastNumber < checkNumber)
            {
                isUpdated = YES;
                break;
            }
        }
        
        if(isUpdated)
        {
            NSLog(@"Delete error data.");
            for(NSString *file in [NSFileManager.defaultManager contentsOfDirectoryAtPath:self.applicationDocumentsDirectory.path error:nil])
            {
                NSString *filePath = [self.applicationDocumentsDirectory.path stringByAppendingPathComponent:file];
                [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
            }
        }
    }

    [self deleteUserDataIfSet];
    
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"paid"]; // TODO: Delete when you enable in-app.
    [NSUserDefaults.standardUserDefaults setObject:currVersionString forKey:@"settings-version"];
    [NSUserDefaults.standardUserDefaults synchronize];
  
    
    NSURL *ubiq = [NSFileManager.defaultManager URLForUbiquityContainerIdentifier:nil];
    
    if(ubiq)
    {
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateiCloud:)
                                                   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                 object:store];
        /*
        NSArray *keys = store.dictionaryRepresentation.allKeys;
        
        for(NSString *key in keys)
            [store removeObjectForKey:key];
         
        NSLog(@"Deleted all of iCloud");
        */
        [store setBool:YES forKey:@"paid"]; // TODO: Delete when you enable in-app.
        [store synchronize];
    }
    else
    {
        NSLog(@"No iCloud access");
    }
    
    
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
        
        UIImage *buttonImage = [[UIImage imageNamed:@"navbar-button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:15];
        [[UIBarButtonItem appearance] setBackgroundImage:buttonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        
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
        
        if([showsController respondsToSelector:@selector(transitionToLive:)])
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
        
        if([showsController respondsToSelector:@selector(transitionToLive:)])
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
    
    [self deleteUserDataIfSet];
    
    
    for(Show *show in self.channel.shows)
        if(show.favorite)
            [show updateEpisodes];
    
    if(self.channel.schedule.days.count > 0 && [self.channel.schedule.days[0] count] > 0)
    {
        Event *firstShow = (Event*)self.channel.schedule.days[0][0];
        
        if(!firstShow.start.isToday)
            [self.channel reloadSchedule];
    }
    else
    {
        [self.channel reloadSchedule];
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
    
    [self saveContext];
}
- (void)applicationDidEnterBackground:(UIApplication*)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if([self.nowPlaying isKindOfClass:Enclosure.class])
    {
        [NSNotificationCenter.defaultCenter addObserver:[self.nowPlaying episode]
                                               selector:@selector(updatePoster:)
                                                   name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                 object:nil];
        [self.player requestThumbnailImagesAtTimes:@[@(self.player.currentPlaybackTime)] timeOption:MPMovieTimeOptionNearestKeyFrame];
        
        [[self.nowPlaying episode] setLastTimecode:self.player.currentPlaybackTime];
    }
    
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Helpers

- (void)deleteUserDataIfSet
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL deleteAll = [defaults boolForKey:@"delete-all"];
    BOOL deleteDownloads = [defaults boolForKey:@"delete-downloads"];
    BOOL deletePosters = [defaults boolForKey:@"delete-posters"];
    
    if(deleteAll)
    {
        for(NSString *file in [NSFileManager.defaultManager contentsOfDirectoryAtPath:self.applicationDocumentsDirectory.path error:nil])
        {
            NSString *filePath = [self.applicationDocumentsDirectory.path stringByAppendingPathComponent:file];
            [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
        }
    }
    else
    {
        if(deleteDownloads)
        {
            NSString *filePath = [self.applicationDocumentsDirectory.path stringByAppendingPathComponent:@"Downloads.nosync"];
            [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
        }
        
        if(deletePosters)
        {
            NSString *filePath = [self.applicationCachesDirectory.path stringByAppendingPathComponent:@"Posters"];
            [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
        }
    }
    
    [defaults setBool:NO forKey:@"delete-all"];
    [defaults setBool:NO forKey:@"delete-downloads"];
    [defaults setBool:NO forKey:@"delete-posters"];
    [defaults synchronize];
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
    {
        if(nowPlaying)
        {
            [NSNotificationCenter.defaultCenter addObserver:[self.nowPlaying episode]
                                                   selector:@selector(updatePoster:)
                                                       name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                     object:nil];
            [self.player requestThumbnailImagesAtTimes:@[@(self.player.currentPlaybackTime)] timeOption:MPMovieTimeOptionNearestKeyFrame];
        }
        
        [[_nowPlaying episode] setLastTimecode:self.player.currentPlaybackTime];
    }
    
    if(nowPlaying && [nowPlaying isKindOfClass:Enclosure.class])
    {
        Enclosure *enclosure = (Enclosure*)nowPlaying;
        
        NSURL *url = enclosure.path ? [NSURL fileURLWithPath:enclosure.path] : [NSURL URLWithString:enclosure.url];
        self.player.contentURL = url;
        self.player.initialPlaybackTime = enclosure.episode.lastTimecode;
        [self play];
    }
    else if(nowPlaying && [nowPlaying isKindOfClass:Stream.class])
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
    if([self.nowPlaying isKindOfClass:Enclosure.class])
        [[self.nowPlaying episode] setLastTimecode:self.player.currentPlaybackTime];
    
    [self.player pause];
}

- (void)stop
{
    [UIApplication.sharedApplication endReceivingRemoteControlEvents];
    [self resignFirstResponder];
 
    self.nowPlaying = nil;
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nil;
    
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

#pragma mark - Rotation

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

#pragma mark - iCloud

- (void)updateiCloud:(NSNotification*)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    
    if(reasonForChange
    &&(reasonForChange.integerValue == NSUbiquitousKeyValueStoreServerChange
    || reasonForChange.integerValue == NSUbiquitousKeyValueStoreInitialSyncChange))
    {
        NSManagedObjectContext *context = self.managedObjectContext;
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        
        for(NSString *key in changedKeys)
        {
            NSDictionary *episodeDict = [store dictionaryForKey:key];
            
            NSString *showTitleAcronym = [episodeDict valueForKey:@"show.titleAcronym"];
            NSString *title = [episodeDict valueForKey:@"title"];
            NSNumber *number = [episodeDict valueForKey:@"number"];
            
            bool watched = [[episodeDict valueForKey:@"watched"] boolValue];
            int lastTimecode = [[episodeDict valueForKey:@"lastTimecode"] intValue];
            
            NSSet *fetchedEpisodes = [context fetchEntities:@"Episode"
                                              withPredicate:@"show.titleAcronym == %@ && title == %@ && number == %@",
                                                              showTitleAcronym, title, number];
            Episode *episode = fetchedEpisodes.anyObject;
            
            if(episode)
            {
                if(lastTimecode >= episode.lastTimecode)
                {
                    [episode willChangeValueForKey:@"watched"];
                    [episode setPrimitiveValue:@(watched) forKey:@"watched"];
                    [episode didChangeValueForKey:@"watched"];
                    
                    [episode willChangeValueForKey:@"lastTimecode"];
                    [episode setPrimitiveValue:@(lastTimecode) forKey:@"lastTimecode"];
                    [episode didChangeValueForKey:@"lastTimecode"];
                }
            }
            else
            {
                NSSet *fetchedShows = [context fetchEntities:@"Show" withPredicate:@"titleAcronym == %@", showTitleAcronym];
                Show *show = fetchedShows.anyObject;
                
                if(show)
                {
                    episode = [context insertEntity:@"Episode"];
                    
                    episode.title = title;
                    episode.number = number.intValue;
                    [show addEpisodesObject:episode];
                    
                    [episode willChangeValueForKey:@"watched"];
                    [episode setPrimitiveValue:@(watched) forKey:@"watched"];
                    [episode didChangeValueForKey:@"watched"];
                    
                    [episode willChangeValueForKey:@"lastTimecode"];
                    [episode setPrimitiveValue:@(lastTimecode) forKey:@"lastTimecode"];
                    [episode didChangeValueForKey:@"lastTimecode"];
                }
            }
        }
        [context save:nil];
    }
    else if(reasonForChange && reasonForChange.integerValue == NSUbiquitousKeyValueStoreQuotaViolationChange)
    {
        NSLog(@"Empty out iCloud");
        
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSDictionary *storeDict = store.dictionaryRepresentation;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@ AND pubDate != nil", NSDictionary.class];
        NSArray *episodesArray = [storeDict.allValues filteredArrayUsingPredicate:predicate];
        NSArray *sortedArray = [episodesArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *episode1, NSDictionary *episode2)
        {
            NSDate *date1 = episode1[@"pubDate"];
            NSDate *date2 = episode2[@"pubDate"];
            
            return [date1 compare:date2];
        }];
        
        for(int i = 0; i < sortedArray.count/3; i++)
        {
            NSDictionary *episode = sortedArray[i];
            NSString *key = [NSString stringWithFormat:@"%@:%@", episode[@"show.titleAcronym"], episode[@"number"]];
            
            [store removeObjectForKey:key];
        }
    }
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

- (NSURL*)applicationCachesDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}


- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
