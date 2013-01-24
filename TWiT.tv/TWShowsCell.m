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

- (CGRect)frameForColumn:(int)column
{
    float x = self.spacing+column*(self.size+self.spacing);
    return CGRectMake(x, self.spacing/2, self.size, self.size);
}

- (void)setShows:(NSArray*)shows
{
    if([_shows isEqualToArray:shows])
        return;
    
    _shows = shows;
    //[self layoutSubviews];
}

- (void)setIcons:(UIImage*)icons
{
    _icons = icons;
    
    [self setNeedsDisplayInRect:self.bounds];
}

#pragma mark - Draw

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if(self.icons && self.icons.size.width == self.frame.size.width)
    {
        [self setNeedsDisplayInRect:self.bounds];
        return;
    }
    
    NSMutableArray *albumArtPathes = [NSMutableArray array];
    __block TWShowsCell *weak = self;
    
    for(Show *show in self.shows)
        [albumArtPathes addObject:show.albumArt.path.copy];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        UIGraphicsBeginImageContextWithOptions(weak.frame.size, YES, UIScreen.mainScreen.scale);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:245/255.0 alpha:1].CGColor);
        CGContextFillRect(context, weak.bounds);
        weak.icons = UIGraphicsGetImageFromCurrentImageContext();
        
        for(Show *show in weak.shows)
        {
            int column = [weak.shows indexOfObject:show];
            CGRect frame = [weak frameForColumn:column];
            
            CGContextSetShadow(context, CGSizeMake(0, 2), 4);
            
            if(column < albumArtPathes.count)
            {
                UIImage *image =  [UIImage imageWithContentsOfFile:albumArtPathes[column]] ?: [UIImage imageNamed:@"generic.jpg"];
                [image drawInRect:frame];
            }
        }
        
        weak.icons = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weak didDrawIcons];
        });
    });
}
- (void)didDrawIcons
{
    [self.delegate showsCell:self didDrawIconsAtIndexPath:self.indexPath];
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
    
    for(int column = 0; column < self.shows.count; column++)
    {
        if(CGRectContainsPoint([self frameForColumn:column], location))
        {   
            [self.delegate tableView:self.table didSelectColumn:column AtIndexPath:self.indexPath];
        }
    }
}

@end
