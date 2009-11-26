//
//  CLTimerSummaryTvController.h
//  Created by ep on 12/5/04.
//  Copyright 2004 Cubelogic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CLTableViewController.h"

@interface CLTimerSummaryTvController : CLTableViewController 
{
    IBOutlet NSButton *editButton;
}

- (void)resetCountdown:(NSString *)s
              withFont:(NSFont *)font
               timerId:(int)tid;

@end
