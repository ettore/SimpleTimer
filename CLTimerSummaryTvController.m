//
//  CLTimerSummaryTvController.m
//  Created by ep on 12/5/04.
//  Copyright 2004 Cubelogic. All rights reserved.
//

#import "CLTimerSummaryTvController.h"
#import "CLTimerSummary.h"

@implementation CLTimerSummaryTvController
/*" 
This class handles a tableView whose records are of class CLTimerSummary.
"*/

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(updateUIWith:)
               name:CLTimerSummaryChanged
             object:nil];
    return self;
}

- (void) dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    [super dealloc];
}

- (void) createAndAddNewEntry
{
    CLTimerSummary *s = [[CLTimerSummary alloc] init];
    [[super model] addObject:s];
    [s release];
}

- (void)updateBtnStatus
{
    [super updateBtnStatus];
    [editButton setEnabled:(([model count] > 0) &&
                              ([tableView selectedRow] != -1) ) ];
}


- (void)resetCountdown:(NSString *)s
              withFont:(NSFont *)font
               timerId:(int)tid
{
    //NSMutableAttributedString *s1;
    //NSMutableParagraphStyle *ps;
    //NSDictionary *sd;
    NSTableColumn *tc;
    
    tc = [tableView tableColumnWithIdentifier:@"countdown"];
    [[model objectAtIndex:tid] setCountdown:s];
    //[[tc dataCellForRow:tid] setFont:font];
    
    // to work with attrStrings we must have a model using attrStrings as well
    /*ps = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [ps setAlignment:NSRightTextAlignment];
    sd = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor redColor], NSForegroundColorAttributeName, 
        [NSFont boldSystemFontOfSize:10.0], NSFontAttributeName,
        ps, NSParagraphStyleAttributeName, nil];
    s1 = [[[NSAttributedString alloc] initWithString:[s string] 
                                          attributes:sd] autorelease];
    [cell setAttributedStringValue:s1];
    [[model objectAtIndex:tid] setAttrCountdown:s1];*/
    [tableView reloadData];
}

@end
