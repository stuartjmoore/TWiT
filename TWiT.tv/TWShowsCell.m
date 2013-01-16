//
//  TWShowsCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowsCell.h"
#import "Show.h"

@implementation TWShowsCell

/*
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
dispatch_async(queue, ^{
    dispatch_sync(dispatch_get_main_queue(), ^{
    });
    
});
*/
 
- (void)setShows:(NSArray*)shows
{
    if([_shows isEqualToArray:shows])
        return;
        
    _shows = shows;
    self.icons = nil;
    
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
 
    if(!self.shows)
        return;
    
    if(self.icons.size.width == self.frame.size.width)
        return;
    
    NSMutableArray *albumArtPathes = [NSMutableArray array];
    // weakSelf?
    
    for(Show *show in self.shows)
        [albumArtPathes addObject:show.albumArt.path];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        UIGraphicsBeginImageContextWithOptions(self.frame.size, YES, UIScreen.mainScreen.scale);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:245/255.0 alpha:1].CGColor);
        CGContextFillRect(context, self.bounds);
        
        for(Show *show in self.shows)
        {
            int column = [self.shows indexOfObject:show];
            float x = self.spacing+column*(self.size+self.spacing);
            CGRect frame = CGRectMake(x, self.spacing/2, self.size, self.size);
            
            CGContextSetShadow(context, CGSizeMake(0, 2), 4);
            
            UIImage *image =  [UIImage imageWithContentsOfFile:albumArtPathes[column]] ?: [UIImage imageNamed:@"generic.jpg"];
            [image drawInRect:frame];
        }
        
        self.icons = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.visibleColumns = self.shows.count;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self didDrawIcons];
        });
    });
}

- (void)didDrawIcons
{
    [self.delegate showsCell:self didDrawIcons:self.icons AtIndexPath:self.indexPath];
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)drawRect:(CGRect)rect
{
    [self.icons drawInRect:self.bounds];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = touches.anyObject;
    CGPoint location = [touch locationInView:self];
    
    for(int column = 0; column < self.visibleColumns; column++)
    {
        float x = self.spacing+column*(self.size+self.spacing);
        if(CGRectContainsPoint(CGRectMake(x, self.spacing/2, self.size, self.size), location))
        {
            [self.delegate tableView:self.table didSelectColumn:column AtIndexPath:self.indexPath];
        }
    }
}

@end
