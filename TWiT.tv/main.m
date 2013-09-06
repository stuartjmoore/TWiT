#import <UIKit/UIKit.h>
#import "TWAppDelegate.h"

typedef int (*PYStdWriter)(void *, const char *, int);
static PYStdWriter _oldStdWrite;

int __pyStderrWrite(void *inFD, const char *buffer, int size)
{
    if ( strncmp(buffer, "AssertMacros:", 13) == 0 )
    {
        return 0;
    }
    return _oldStdWrite(inFD, buffer, size);
}

int main(int argc, char * argv[])
{
    _oldStdWrite = stderr->_write;
    stderr->_write = __pyStderrWrite;
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([TWAppDelegate class]));
    }
}

/*
 
 TODO: Remove, only a temp fix for the crazy NSLog error.
 
//
//  main.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TWAppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([TWAppDelegate class]));
    }
}
 
*/