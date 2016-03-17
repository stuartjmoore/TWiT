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
#import "TWShowsViewController.h"
#import "TWWatchListController.h"
#import "TWPlaybarViewController.h"

#import "NSManagedObjectContext+ConvenienceMethods.h"
#import "NSDate+comparisons.h"

#import "Channel.h"
#import "Show.h"
#import "Episode.h"
#import "Enclosure.h"
#import "Stream.h"


@interface TWAppDelegate ()

@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


@implementation TWAppDelegate

- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    return YES;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    NSDictionary *appDefaults = @{ @"settings-show-badge" : @YES };
    [NSUserDefaults.standardUserDefaults registerDefaults:appDefaults];
    
    
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    [AVAudioSession.sharedInstance setActive:YES error:nil];
  
    
    [self deleteUserDataIfSet];
    
    NSString *currVersionString = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    [NSUserDefaults.standardUserDefaults setObject:currVersionString forKey:@"settings-version"];
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"paid"];
    [NSUserDefaults.standardUserDefaults synchronize];
  
    
    NSURL *ubiq = [NSFileManager.defaultManager URLForUbiquityContainerIdentifier:nil];
    BOOL iCloudDisabled = [NSUserDefaults.standardUserDefaults boolForKey:@"icloud-disabled"];
  
    if(ubiq && !iCloudDisabled)
    {
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateiCloud:)
                                                   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                 object:store];

        [store setBool:YES forKey:@"paid"];
        [store synchronize];
    }
    else if(ubiq && iCloudDisabled)
    {
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *keys = store.dictionaryRepresentation.allKeys;
        
        for(NSString *key in keys)
            [store removeObjectForKey:key];
        
        NSLog(@"Deleted all of iCloud");
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
        
        TWWatchListController *episodesController = (TWWatchListController*)splitViewContainer.masterController.topViewController;
        episodesController.managedObjectContext = self.managedObjectContext;
        episodesController.channel = self.channel;
        
        TWShowsViewController *showsController = (TWShowsViewController*)splitViewContainer.detailController.topViewController;
        showsController.managedObjectContext = self.managedObjectContext;
        showsController.channel = self.channel;
    }
    else
    {
        NSMutableDictionary *titleBarAttributes = [NSMutableDictionary dictionaryWithDictionary:[UINavigationBar.appearance titleTextAttributes]];
        [titleBarAttributes setValue:[UIFont fontWithName:@"Vollkorn-BoldItalic" size:18] forKey:NSFontAttributeName];
        [UINavigationBar.appearance setTitleTextAttributes:titleBarAttributes];
        
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        navigationContainer.view = navigationContainer.view;
      
        TWWatchListController *mainController = (TWWatchListController*)navigationContainer.masterController.topViewController;
        mainController.managedObjectContext = self.managedObjectContext;
        mainController.channel = self.channel;
    }
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
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
        TWShowsViewController *showsController = (TWShowsViewController*)detailController.topViewController;
        
        if([showsController respondsToSelector:@selector(redrawSchedule:)])
            [showsController redrawSchedule:nil];
    }
    else
    {
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
        TWWatchListController *controller = (TWWatchListController*)navigationController.topViewController;
        
        if([controller respondsToSelector:@selector(redrawSchedule:)])
            [controller redrawSchedule:nil];
    }
}

- (void)applicationWillResignActive:(UIApplication*)application
{
    if(self.player.playbackState == MPMoviePlaybackStatePlaying)
        [self performSelector:@selector(play) withObject:nil afterDelay:0.005f];
        
    [self updateBadgeCount];
    [self saveContext];
}
- (void)applicationDidEnterBackground:(UIApplication*)application
{
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

- (void)applicationWillTerminate:(UIApplication*)application
{
    [self saveContext];
}

#pragma mark - Downloads

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void(^)())completionHandler
{
    NSArray *identifierParts = [identifier componentsSeparatedByString:@"."];
    
    NSLog(@"%@", identifierParts);
    
    if(identifierParts.count == 8 && [identifierParts[4] isEqualToString:@"enclosure"])
    {
        NSString *titleAcronym = identifierParts[5];
        NSString *epNumber = identifierParts[6];
        NSString *enclosureQuality = identifierParts[7];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *enclosure = [NSEntityDescription entityForName:@"Enclosure" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"episode.show.titleAcronym ==[c] %@ AND episode.number == %@ AND quality == %@",
                                  titleAcronym, epNumber, enclosureQuality];
        
        request.entity = enclosure;
        request.predicate = predicate;
        request.includesSubentities = NO;
        request.fetchLimit = 1;
        
        NSError *error;
        
        NSArray *enclosures = [self.managedObjectContext executeFetchRequest:request error:&error];
        
        if(!error)
        {
            Enclosure *enclosure = enclosures.firstObject;
            enclosure.backgroundSessionCompletionHandler = completionHandler;
        }
        else
        {
            NSLog(@"error %@", error);
        }
    }
}

#pragma mark - Notifications

- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        //TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.window.rootViewController;
        //TWMainViewController *showsController = (TWMainViewController*)splitViewContainer.detailController.topViewController;
        
        // TODO: Use segue to load live, probably simular to below
        
        //if([showsController respondsToSelector:@selector(transitionToLive:)])
        //    [showsController transitionToLive:nil];
    }
    else
    {
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
        [navigationController popToRootViewControllerAnimated:NO];
        
        TWWatchListController *controller = (TWWatchListController*)navigationController.topViewController;
        [controller performSegueWithIdentifier:@"liveVideoDetail" sender:nil];
    }
}

#pragma mark - Fetch

- (void)application:(UIApplication*)application performFetchWithCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler
{
    for(Show *show in self.channel.shows)
        if(show.favorite)
            [show updateEpisodesWithCompletionHandler:completionHandler];
}

#pragma mark - URL Scheme

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        //TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.window.rootViewController;
        //TWMainViewController *showsController = (TWMainViewController*)splitViewContainer.detailController.topViewController;
        
        // TODO: Use segue to load live
        
        //if([showsController respondsToSelector:@selector(transitionToLive:)])
        //    [showsController transitionToLive:nil];
    }
    else
    {
        TWNavigationContainer *navigationContainer = (TWNavigationContainer*)self.window.rootViewController;
        TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
        [navigationController popToRootViewControllerAnimated:NO];
        
        TWWatchListController *controller = (TWWatchListController*)navigationController.topViewController;
        [controller performSegueWithIdentifier:@"liveVideoDetail" sender:nil];
    }
    
    return YES;
}

#pragma mark - Helpers

- (void)updateBadgeCount
{
    BOOL showBadge = [NSUserDefaults.standardUserDefaults boolForKey:@"settings-show-badge"];
    
    if(showBadge)
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"watched = NO OR ANY enclosures.path != nil"];
        
        [request setEntity:entity];
        [request setPredicate:predicate];
        request.includesSubentities = NO;
        
        NSError *err;
        NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&err];
        
        UIApplication.sharedApplication.applicationIconBadgeNumber = (count == NSNotFound) ? 0 : count;
    }
    else
    {
        UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
    }
}

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
        _player.scalingMode = MPMovieScalingModeAspectFit;
        _player.controlStyle = MPMovieControlStyleNone;
        _player.shouldAutoplay = YES;
        _player.allowsAirPlay = YES;
        
        _player.view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _player;
}

- (void)setNowPlaying:(id)nowPlaying
{
    if(self.player && [_nowPlaying isKindOfClass:Enclosure.class] && self.player.currentPlaybackTime)
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
    
    self.player.contentURL = nil;
    
    if(nowPlaying && [nowPlaying isKindOfClass:Enclosure.class])
    {
        Enclosure *enclosure = (Enclosure*)nowPlaying;
        NSURL *url = enclosure.path ? [NSURL fileURLWithPath:enclosure.path] : [NSURL URLWithString:enclosure.url];
        
        self.player.movieSourceType = enclosure.path ? MPMovieSourceTypeFile : MPMovieSourceTypeStreaming;
        self.player.contentURL = url;
        self.player.initialPlaybackTime = enclosure.episode.lastTimecode;
        
        [self play];
    }
    else if(nowPlaying && [nowPlaying isKindOfClass:Stream.class])
    {
        Stream *stream = (Stream*)nowPlaying;
        
        self.player.movieSourceType = MPMovieSourceTypeStreaming;
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

- (UIInterfaceOrientationMask)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
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
        
        if([navigationContainer respondsToSelector:@selector(masterController)])
        {
            TWNavigationController *navigationController = (TWNavigationController*)navigationContainer.masterController;
            UIViewController *presented = navigationController.topViewController;
            res = presented.supportedInterfaceOrientations;
        }
    }
    
    return res;
}

#pragma mark - iCloud

- (void)updateiCloud:(NSNotification*)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
  
    NSLog(@"updateiCloud %@", userInfo);
    
    if(reasonForChange && reasonForChange.integerValue == NSUbiquitousKeyValueStoreInitialSyncChange)
    {
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSManagedObjectContext *context = self.managedObjectContext;
        NSSet *fetchedEpisodes = [context fetchEntities:@"Episode" withPredicate:@"watched == NO"];
        
        for(Episode *episode in fetchedEpisodes)
        {
            NSString *key = [NSString stringWithFormat:@"%@:%@", episode.show.titleAcronym, @(episode.number)];
            NSMutableDictionary *episodeDict = [[store dictionaryForKey:key] mutableCopy];
            
            if(!episode)
            {
                episodeDict = [NSMutableDictionary dictionary];
                [episodeDict setValue:episode.published forKey:@"pubDate"];
                
                [episodeDict setValue:episode.show.titleAcronym forKey:@"show.titleAcronym"];
                [episodeDict setValue:episode.title forKey:@"title"];
                [episodeDict setValue:@(episode.number) forKey:@"number"];
            }
            
            [episodeDict setValue:@(episode.watched) forKey:@"watched"];
            [episodeDict setValue:@(episode.lastTimecode) forKey:@"timecode"];
            [store setDictionary:episodeDict forKey:key];
        }
    }
  
    if(reasonForChange
    &&(reasonForChange.integerValue == NSUbiquitousKeyValueStoreServerChange
    || reasonForChange.integerValue == NSUbiquitousKeyValueStoreInitialSyncChange))
    {
        NSManagedObjectContext *context = self.managedObjectContext;
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        NSMutableSet *showsToUpdate = [NSMutableSet new];
        
        for(NSString *key in changedKeys)
        {
            NSDictionary *episodeDict = [store dictionaryForKey:key];
            
            NSString *showTitleAcronym = episodeDict[@"show.titleAcronym"];
            NSString *title = episodeDict[@"title"];
            NSNumber *number = episodeDict[@"number"];
            
            bool watched = [[episodeDict valueForKey:@"watched"] boolValue];
            NSInteger lastTimecode = [[episodeDict valueForKey:@"lastTimecode"] intValue];
            
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
                    
                    [showsToUpdate addObject:show];
                }
            }
        }
        [context save:nil];
        
        [showsToUpdate makeObjectsPerformSelector:@selector(updateEpisodes)];
    }
    else if(reasonForChange && reasonForChange.integerValue == NSUbiquitousKeyValueStoreQuotaViolationChange)
    {
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
        
        for(NSInteger i = 0; i < sortedArray.count/3; i++)
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

- (NSManagedObjectModel*)managedObjectModel
{
    if(_managedObjectModel != nil)
        return _managedObjectModel;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TWiT_tv" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    if(_persistentStoreCoordinator != nil)
        return _persistentStoreCoordinator;
    
    NSError *error = nil;
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"TWiT_tv.sqlite"];
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @YES,
                                     NSInferMappingModelAutomaticallyOption: @YES };
  
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
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
