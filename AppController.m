//
//  AppController.m
//  Copyright (c) 2003 Ettore Pasquini.
//  $Id: AppController.m,v 1.2 2005/10/21 11:22:58 ettorep Exp $ 
//

/*
 This file is part of SimpleTimer.

 SimpleTimer is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 SimpleTimer is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with SimpleTimer; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "AppController.h"
#import "CLSimpleTimerModel.h"
#import "CLTimerSummary.h"
#import "MyDocument.h"
#import "CLSimpleTimerGlobals.h"
#import "PreferenceController.h"
#import "CLTimerSummaryTvController.h"
#import "CLFileManagerCateg.h"
#import <objc/objc-runtime.h>

@implementation AppController
/*" AppController is a generic class that manages all custom resources,
    panels, windows, method calls from the main menu. It serves as a
    dispatch center for the entire application. It holds no status
    and no model data, just references to other controllers.
    It is istantiated in the MainMenu.nib. 
"*/

int TIMER_STARTED = 0x00;
int TIMER_WITH_FIREDATE = 0x01;
int TIMER_WITH_NOW = 0x02;

// ##############################################################
//              INITIALIZATION AND DEALLOCATION
// ########**####################################################

/*" Register the defaults, i.e. creates the factory default set of 
the application defaults. "*/
+ (void) initialize
{
    debug0cocoa(@"AppController.initialize - entering....");
    NSBundle *mainBundle = [NSBundle mainBundle];

    // create a dictionary
    NSMutableDictionary *defs = [NSMutableDictionary dictionary];

    // create the objects to be stored as defaults
    NSString *msg1 = [mainBundle localizedStringForKey:@"msg1" 
                                                 value:@"Pick up laundry"
                                                 table:@"Localizable"];
    NSString *msg2 = [mainBundle localizedStringForKey:@"msg2" 
                                                 value:@"Wash dishes"
                                                 table:@"Localizable"];
    NSString *msg3 = [mainBundle localizedStringForKey:@"msg3" 
                                                 value:@"Wipe crumbs from table"
                                                 table:@"Localizable"];
    NSString *msg4 = [mainBundle localizedStringForKey:@"msg4" 
                                                 value:@"Vacuum"
                                                 table:@"Localizable"];
    NSString *msg5 = [mainBundle localizedStringForKey:@"msg5" 
                                                 value:@"Do some physical exercises"
                                                 table:@"Localizable"];
    NSString *msg6 = [mainBundle localizedStringForKey:@"msg6" 
                                                 value:@"Water the plants"
                                                 table:@"Localizable"];
    NSString *msg7 = [mainBundle localizedStringForKey:@"msg7" 
                                                 value:@"Meditate"
                                                 table:@"Localizable"];
    NSString *msg8 = [mainBundle localizedStringForKey:@"msg8" 
                                                 value:@"Stop looking at porn!"
                                                 table:@"Localizable"];
    
    // NB!! ogni rec ha retainCount=2: uno causa l'alloc, l'altro causa 
    // `arrayWithObjects:'
    NSMutableArray *msgPresets = [NSMutableArray arrayWithObjects:
        [[CLSingleStringRecord alloc] initWithString:msg1],
        [[CLSingleStringRecord alloc] initWithString:msg2],
        [[CLSingleStringRecord alloc] initWithString:msg3],
        [[CLSingleStringRecord alloc] initWithString:msg4],
        [[CLSingleStringRecord alloc] initWithString:msg5],
        [[CLSingleStringRecord alloc] initWithString:msg6],
        [[CLSingleStringRecord alloc] initWithString:msg7],
        [[CLSingleStringRecord alloc] initWithString:msg8],
        nil];
    
    msg1 = [mainBundle localizedStringForKey:@"url1" 
                                       value:@"http://localhost"
                                       table:@"Localizable"];
    msg2 = [mainBundle localizedStringForKey:@"url2" 
                                       value:@"http://gnu.org"
                                       table:@"Localizable"];
    msg3 = [mainBundle localizedStringForKey:@"url3" 
                                       value:@"http://cubelogic.org"
                                       table:@"Localizable"];
    msg4 = [mainBundle localizedStringForKey:@"url4" 
                                       value:@"http://news.ycombinator.com"
                                       table:@"Localizable"];
    
    NSMutableArray *urlPresets = [NSMutableArray arrayWithObjects:
        [[CLSingleStringRecord alloc] initWithString:msg1],
        [[CLSingleStringRecord alloc] initWithString:msg2],
        [[CLSingleStringRecord alloc] initWithString:msg3],
        [[CLSingleStringRecord alloc] initWithString:msg4],
        nil];
    
    // read the default sound directory
    msg1 = [mainBundle localizedStringForKey:CLDefaultSoundDirKey
                                       value:@"/System/Library/Sounds/"
                                       table:@"Localizable"];
    
    // archive the objects to be stored as defaults
    NSData *archUrlPresets = 
        [NSKeyedArchiver archivedDataWithRootObject: urlPresets];
    NSData *archMsgPresets = 
        [NSKeyedArchiver archivedDataWithRootObject: msgPresets];
    
    // store the values in the dict
    [defs setObject:archUrlPresets forKey:CLUrlPresetsKey];
    [defs setObject:archMsgPresets forKey:CLMsgPresetsKey];
    [defs setObject:[NSNumber numberWithInt:CL_SIMPLETIMER_PREFS_APPL_SAVES]
             forKey:CLSaveButtonScopeKey];
    [defs setObject:[NSNumber numberWithInt:NSOffState]
             forKey:CLSimpleTimerAlwaysRemoveKey];
    [defs setObject:msg1 forKey:CLDefaultSoundDirKey];
    
    // register the dictionary of factory defaults, so the system knows the
    // differences between the user prefs and the factory defaults (system 
    // only stores the differences)
    [[NSUserDefaults standardUserDefaults] registerDefaults: defs];
    debug0cocoa(@"Registered User Defaults.");
    debug0cocoa(@"AppController.initialize - returning....");
}


/*" Designated initialiazer. "*/
- init
{
    NSNotificationCenter *ncenter;
    NSBundle *mainBundle;
    NSUserDefaults *defs;
    
    debug0cocoa(@"AppController.init - entering....");
    
    if ((self = [super init]) == nil) 
        return nil;
    
    // initialize date formats strings
    mainBundle = [NSBundle mainBundle];
    samedayDateFormat = [mainBundle localizedStringForKey:@"SamedayDateFormat" 
                                                    value:@"at %1I:%M:%S %p"
                                                    table:@"Localizable"];
    sameyearDateFormat= [mainBundle localizedStringForKey:@"SameyearDateFormat" 
                                                    value:@"%b %e at %1I:%M:%S %p"
                                                    table:@"Localizable"];
    fullDateFormat = 
        [mainBundle localizedStringForKey:@"FullDateFormat" 
                                    value:@"%b %e, %Y at %1I:%M:%S %p"
                                    table:@"Localizable"];
    
    // init the default snd location
    defs = [NSUserDefaults standardUserDefaults];
    defaultSoundDir = [defs objectForKey:CLDefaultSoundDirKey];
    debug0cocoa(@"AppController.init : defaultSoundDir == %@", defaultSoundDir);
    
    // register itself to be notified of newly created documents
    ncenter = [NSNotificationCenter defaultCenter];
    [ncenter addObserver:self
                selector:@selector(handleNewSimpleTimerDocument:)
                    name:CLSimpleTimerNew
                  object:nil];
    preferenceController = nil;
    countdownFont = [NSFont boldSystemFontOfSize:10.0];
    countdownEndedFont = [NSFont boldSystemFontOfSize:10.0];
    
    // when app starts up it automatically creates a doc from scratch
    currentOperation = CLCreatingNewTimerFromScratch;

    [self loadPreferencesNib];
    didReviewChanges = NO;
    
    debug0cocoa(@"AppController.init - returning....");
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSTableView *t;

    debug_enter("AppController: applicationDidFinishLaunching:");
    t = [sumAllController tableView];
    // set double click
    [t setDoubleAction:@selector(editTimer:)];
    [t setTarget:self];
    debug_exit("AppController: applicationDidFinishLaunching:");
}

- (void) dealloc
{
    debug0cocoa(@"AppController.dealloc - entering....");
    if (preferenceController)
        [preferenceController release];
    [sumAllController release];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    [super dealloc];
    debug0cocoa(@"AppController.dealloc - returning");
}


// ##############################################################
//                    HANDLING DOCUMENTS
// ##############################################################

/*" 
Creates a new document initializing it with the data of the selected 
row. This method is called only by the UI (Summary window, "New" button).
"*/
- (IBAction) newDoc:(id)sender
{
    MyDocument *d;
    
    debug_enter("AppController -newDoc:");
    d = [self openUntitledDoc:CLCreatingNewTimerFromScratch];
    currentOperation = CLDefaultOpeningOperation;
    debug_exit("AppController -newDoc:");
}


- (id)openUntitledDoc:(int)operation
{
    currentOperation = operation;
    // `openUntitledDocumentOfType:' behaves like `newDocument:'
    return [super openUntitledDocumentOfType:CLSimpleTimerDocType display:YES];
}


- (id)openUntitledDocumentOfType:(NSString *)docType display:(BOOL)display
{
    currentOperation = CLCreatingNewTimerFromScratch;
    return [super openUntitledDocumentOfType:docType display:display];
}


- (IBAction) editTimer:(id)sender
{
    debug_enter("AppController -editTimer:");
    
    int tid;
    id row, rowIndex;
    id doc_tm; // can either be a MyDocument or a CLSimpleTimerModel
    NSEnumerator *selRows;
    
    // `selectedRowEnumerator' is deprecated; 
    // should use `selectedRowIndexes' but it's Panther only
    selRows = [[sumAllController tableView] selectedRowEnumerator];
    
    // if rows 0 and 2 were selected, selRows contains 0 and 2
    while ((rowIndex = [selRows nextObject]))
    {
        tid = [rowIndex intValue];
        row  = [[sumAllController model] objectAtIndex: tid];
        doc_tm = [row doc];
        if ( ([doc_tm isKindOfClass:[MyDocument class]]) )
        {
            // if we have a reference to the doc, then the doc is already open
            [[doc_tm myWindow] makeKeyAndOrderFront:sender];
        }
        else {
            // if we DON'T have the doc, it has been closed: must open a doc 
            // stub using the timerModel. doc_tm holds a ref. to the timerModel.
            [self reopenDoc:tid];
        }
        [sumAllController updatePerChanges];
        [sumAllController updateUI];
    }
    debug_exit("AppController -editTimer:");
}


- (IBAction) removeTimer:(id)sender
{
    debug_enter("AppController -removeTimer:");
    
    BOOL isDirty;
    int tid, count;
    CLTimerSummary *row;
    id doc_tm;
    MyDocument *d;
    NSMutableArray *tvmodel = [sumAllController model];
    
    count = [tvmodel count];
    tid = count - 1;
    while (tid >= 0)
    {
        if (![sumTableAll isRowSelected:tid])
        {
            tid--;
            continue;
        }
        
        row = [tvmodel objectAtIndex: tid];
        doc_tm = [row doc];
        isDirty = [row isDirty];
        
        if ([doc_tm isKindOfClass:[MyDocument class]])
        {
            // try to close the document
            [[doc_tm myWindow] performClose:sender];
            // at this point 2 things could have happened:
            // 1. doc was closed cos it was saved AND timer was inactive
            // 2. doc is still open and will wait for the user input. In this
            // case the doc will eventually be closed, but LATER, not now.
            //if (count != [tvmodel count])
            //    count--;
        }
        else if ([doc_tm timerStarted] || isDirty)
        {
            if ([preferenceController alwaysRemove] == NSOnState)
            {
                if (isDirty)
                {
                    // give the user a chance to save the timer
                    d = [self reopenDoc:tid];
                    // attempt to close, the normal warning will come out
                    [[d myWindow] performClose:sender];
                }
                else 
                {
                    // if not dirty, simply close (ignore timerStarted status)
                    [self removeTimerWithId:tid];
                }
            }
            else{
                d = [self reopenDoc:tid];
                // attempt to close, normal warning will come out
                [[d myWindow] performClose:sender];
                
            }
        }
        else {
            // document was already closed and not active and not dirty
            // NB: if [row retainCount] > 1, a [row release] doesn't 
            // release the members of row!
            [self removeTimerWithId:tid];
            //count--;
        }
            
        tid--;
    }
    [sumAllController updatePerChanges];
    [sumAllController updateUI];
    debug_exit("AppController -removeTimer:");
}


// ##############################################################
//                    NOTIFICATION METHODS
// ##############################################################


/*" Called by [MyDocument windowControllerDidLoadNib:] "*/
- (void)handleNewSimpleTimerDocument:(NSNotification *)note
{
    MyDocument *d;
    NSString *fname;
    CLTimerSummary *rec;
    CLSimpleTimerModel *tm;
    int pos, tvmcount, i;
    NSMenuItem *docki;
    NSMutableArray *tvm;

    debug_enter("AppController -handleNewSimpleTimerDocument");

    d = [note object];
    fname = [d fileName]; //fname will be nil for a timer created from scratch
    if (fname != nil)
        currentOperation = CLOpeningTimerFromDisk;

    if (currentOperation == CLOpeningTimerFromDisk)
    {
        // we already have a doc opened by the framework. We need to understand
        // if we've to populate this doc with a timer already existing or not,
        // and that happens if the filename of the newly opened file is already
        // between the ones that are currently handled by AppController, inside
        // [sumAllController model].
                
        debug0msg0("AppController -handleNewSimpleTimerDocument: checking if opening timer from disk or from memory");
        
        tvm = [sumAllController model];
        tvmcount = [tvm count];
        i = 0;
        
        // will create new doc (not from scratch) unless we find doc matching
        // the filename in the list of all open timers
        while (i < tvmcount)
        {
            tm = [[[tvm objectAtIndex:i] doc] timerModel];
            if ([fname isEqual:[tm name]])
            {
                currentOperation = CLReopeningTimer;
                // copy the model of the found timer in the new "shell" doc
                [self updateDoc:d withTimerId:i];
                break;
            }
            i++;
        }
    }
    
    debug0cocoa(@"currentOperation=%d  CLAddingNewTimer=%d", 
                currentOperation, CLAddingNewTimer);
    if (currentOperation & CLAddingNewTimer)
    {
        //
        // includes CLCreatingNewTimerFromScratch and remaining part of
        //  CLOpeningTimerFromDisk (in case it was not found in memory)
        //
        
        debug0cocoa(@"AppController -handleNewSimpleTimerDocument: adding new timer: %@", [d description]);
        
        // set timerId of the new doc
        pos = [[sumAllController model] count];
        [d setTimerId: pos];
        
        // add document to list of simpleTimer documents
        rec = [[CLTimerSummary alloc] initWithSimpleTimerDocument:d];
        [sumAllController addRecord: rec];
        
        // set a ref to AppController in the doc, to be able to start a NSTimer
        //[d setAppController: self];
        //[self release];
        
        // add item to dock menu
        docki = [[NSMenuItem alloc] init];
        [docki setTitle: [rec shortDescr]];
        [dockMenu addItem: docki];
        
        // start the timer if autostart was on
        tm = [d timerModel];
        if ( ![tm timerStarted]
            && [tm autoFlag] == NSOnState
            && (currentOperation != CLCreatingNewTimerFromScratch) 
            )
        {
            [d startTimer:d];
        }
        
        // release what we just allocated
        [docki release];
        [rec release];
        
        // reset current operation status
        currentOperation = CLOpeningTimerFromDisk;
    }
    
    // if a timer ws found, we're done, & we can reset currentOperation
    if (currentOperation == CLReopeningTimer)
        currentOperation = CLDefaultOpeningOperation;    
    
    debug_exit("AppController -handleNewSimpleTimerDocument");
}

// ##############################################################
//                     UTILITY METHODS
// ##############################################################

- (void) invalidateAllTimers
{
    CLTimerSummary *ts;
    NSArray *arr = [sumAllController model];
    int tid = [arr count] - 1;
    
    while (tid>=0)
    {
        ts = [arr objectAtIndex:tid];
        if ([ts timer] || [[[ts doc] timerModel] timerStarted])
            [self invalidateTimer: tid
                             code: CLSimpleTimerMainExpMask];
        tid--;
    }
}

/*"Removes timer `tid' from the list of open timers. Before removing, 
invalidates the timer is active."*/
- (void)removeTimerWithId:(int)tid
{
    debug_enter("AppController -removeTimerWithId:");

    NSMutableArray *tvmodel = [sumAllController model];
    CLTimerSummary *ts = [tvmodel objectAtIndex:tid];
    
    if ([ts timer] || [[[ts doc] timerModel] timerStarted])
        [self invalidateTimer: tid 
                         code: CLSimpleTimerMainExpMask];
    
    [tvmodel removeObjectAtIndex: tid];
    [self recomputeTimerIdsFromId:tid];
    [sumAllController updatePerChanges];
    [sumAllController updateUI];
    [dockMenu removeItemAtIndex:(tid+1)];
    
    debug_exit("AppController -removeTimerWithId:");
}

/*" 
Opens an untitled document (of class MyDocument) and populates it with the 
data of timer `timerId', whose timerModel is assumed to be present on 
sumAllController model object at position `timerId'.
"*/
- (MyDocument *)reopenDoc:(int)timerId
{
    debug_enter("AppController -reopenDoc:");
    
    MyDocument *d;
    NSString *fname, *untitledDoc;
    
    fname = [[[[sumAllController model] objectAtIndex:timerId] doc] fileName];
    d = [self openUntitledDoc:CLReopeningTimer];
    [d setFileName: fname];
    //[doc retain];//no need to retain, doc's being added to list of open docs
    
    untitledDoc= [[NSBundle mainBundle] localizedStringForKey:@"UntitledDoc" 
                                                        value:@"Untitled"
                                                        table:@"Localizable"];
    if (fname && ![@"" isEqual:fname] && ![untitledDoc isEqual:fname])
        [d readFromFile:fname ofType:CLSimpleTimerDocType];
    
    [self updateDoc:d withTimerId:timerId];
    
    // restore the current operation status flag 
    currentOperation = CLDefaultOpeningOperation;
    debug0cocoa(@"AppController -reopenDoc: [doc retainCount] = %d", 
                    [d retainCount]);
    debug_exit("AppController -reopenDoc:");
    return d;
}

/*" 
Given a document `d', this method updates the document with the timer model
information related to `timerId', which is assumed to be saved on the 
sumAllController model object at position `timerId'.
"*/
- (void)updateDoc:(MyDocument *)d withTimerId:(int)timerId
{
    BOOL isDirty;
    CLTimerSummary *row;
    CLSimpleTimerModel *tm;
    //NSMutableArray *fileinfo;
    
    debug_enter("AppController -updateDoc:withTimerId:");
    
    row  = [[sumAllController model] objectAtIndex: timerId];
    tm = [row doc]; // it's a timer model in this case
    NSAssert1(([tm retainCount] == 1), 
        @"AppController -updateDoc: timerModel has weird retainCount: %d",
        [tm retainCount]);
    
    // set timerId of the new doc
    //[d setAppController: self];
    
    // set timerId of the new doc
    [d setTimerId: timerId];
    
    // load the document with the timer model data
    [d setTimerModel: tm];

    // make sure the window name is set when we reopen a document
    //fileinfo = [NSFileManager extractFromAbsPath:[tm name] removeExt:NO];
    //[[d myWindow] setTitle:[fileinfo objectAtIndex:1]];
    //[d setFileName: [tm name]];
    
    // restore the "isEdited" status of the document
    isDirty = [row isDirty];
    [[d myWindow] setDocumentEdited:isDirty];
    if (isDirty)
        [d updateChangeCount:NSChangeDone];
    
    [d setFileName: [tm name]];
    
    // updateUI cos windowControllerDidLoadNib has already been called
    [d updateUI];
    
    // restore the document reference in the list of all open timers
    [row setDoc: d];
    debug_exit("AppController -updateDoc:withTimerId:");
}

/*" 
Recompute all timerIds of records of [sumAllController model] starting from 
element index `tid' and up.
"*/
- (void) recomputeTimerIdsFromId:(int)tid
{
    debug_enter("AppController -recomputeTimerIds");
    
    NSMutableArray *tvmodel = [sumAllController model];
    int n = [tvmodel count];
    int i;
    id doc;
    
    for (i=tid; i<n; i++)
    {
        doc = [[tvmodel objectAtIndex:i] doc];
        if ([doc isKindOfClass:[MyDocument class]])
            [doc setTimerId:i];
    }
    
    debug_exit("AppController -recomputeTimerIds");
}

- (NSString *)formattedStringForDate:(NSDate *)date
{
    NSString *s;
    NSCalendarDate *now, *d;
    int yearNow, yearDate, dayNow, dayDate;
    
    // generate calendar dates
    now = [NSCalendarDate calendarDate];
    s = [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"
                                   timeZone:nil
                                     locale:nil];
    
    d= [NSCalendarDate dateWithString:s calendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
    
    yearNow = [now yearOfCommonEra];
    yearDate = [d yearOfCommonEra];
    dayNow = [now dayOfYear];
    dayDate = [d dayOfYear];
    
    // determine format
    if (yearNow == yearDate && dayNow == dayDate)
        s = samedayDateFormat;
    else if (yearNow == yearDate)
        // Dec 12 at 3:45:46 PM
        s = sameyearDateFormat;
    else 
        // Dec 12, 2004 at 3:45:46 PM
        s = fullDateFormat;
    
    s = [date descriptionWithCalendarFormat:s
                                   timeZone:nil
                                     locale:nil];
    
    return s;
}

/*" Returns YES if loading was successful. "*/
- (BOOL) loadPreferencesNib
{
    BOOL res;
    if (preferenceController == nil)
        preferenceController = [[PreferenceController alloc] init];
    
    res = [NSBundle loadNibNamed:@"Preferences" 
                           owner:preferenceController];
    return res;
}


// ############################################################
//                    TIMER METHODS
// ############################################################

- (void)startTimer:(int)timerId
{
    debug_enter("AppController -startTimer:");

    NSTimeInterval repeatSecs;
    int cycleTimes;
    BOOL repeatFlag;
    NSDate *fireDate;
    NSString *ending, *willEndStr;
    NSMutableArray *userInfo;
    NSRunLoop *currRunLoop; // the current RunLoop where I register the timers
    NSTimer *t, *ut;
    CLTimerSummary *rec = [[sumAllController model] objectAtIndex: timerId];
    CLSimpleTimerModel *tm = [[rec doc] timerModel];
    
    // get localized strings
    willEndStr = [[NSBundle mainBundle] localizedStringForKey:@"WillEnd" 
                                                        value:@"Will end "
                                                        table:@"Localizable"];
    
    // determine timing info
    repeatSecs = [tm cycleHrs] * 3600 + [tm cycleMins] * 60 + [tm cycleSecs];
    repeatFlag = ([tm repeatFlag] == NSOnState);
    fireDate = [tm fireDate];
    ending = [self formattedStringForDate:fireDate];
    ending = [willEndStr stringByAppendingString:ending];
    [tm setStatusInfo:ending];
    [rec setPrecomputed:ending];
    
    // create userinfo array and add timer summary record to it
    userInfo = [NSMutableArray arrayWithCapacity:1];
    [userInfo addObject:rec];
    
    // eventually invalidate a previously running main timer
    t = [rec timer];
    if (t)
        [self invalidateTimer:timerId code:CLSimpleTimerMainExpMask];
    
    // allocate new timer
    t = [[NSTimer alloc] initWithFireDate:[fireDate copy]
                                 interval:repeatSecs
                                   target:self
                                 selector:@selector(doGestures:)
                                 userInfo:userInfo
                                  repeats:repeatFlag];

    // retain the timer in the tableView record
    [rec setTimer: t];
    
    // add updating timer for live countdown
    userInfo = [NSMutableArray arrayWithCapacity:1];
    [userInfo addObject:rec];
    ut = [NSTimer scheduledTimerWithTimeInterval:1 
                                          target:self 
                                        selector:@selector(updCountdown:)
                                        userInfo:userInfo
                                         repeats:YES];
    [rec setUpdatingTimer:ut];
    [sumAllController resetCountdown:@"" 
                            withFont:countdownFont
                             timerId:timerId];
    
    // add main timers to runloop and modal run loop
    currRunLoop = [NSRunLoop currentRunLoop];
    [currRunLoop addTimer:t forMode:NSDefaultRunLoopMode];
    [currRunLoop addTimer:t forMode:NSModalPanelRunLoopMode];
    [currRunLoop addTimer:ut forMode:NSModalPanelRunLoopMode];
    
    // release timer since I retained it (in set*Timer:)
    [t release];
    debug0cocoa(@"AppController -startTimer: main timer retainCnt=%d",
                    [t retainCount]);
    debug0cocoa(@"AppController -startTimer: main timer fireDate= %@", 
                    [[t fireDate] description]);
    t = nil;
    
    // update timer model (init counting of repetitions)
    [tm setTimerStarted: YES];
    cycleTimes = [tm cycleTimes];
    [tm setCycleTimesLeft: cycleTimes];
        
    debug_exit("AppController -startTimer:");
}


/*" Updates the summary table view with the countdown status. "*/
- (void)updCountdown:(NSTimer *)aTimer
{
    NSString *s;
    NSMutableArray *uinfo = [aTimer userInfo];
    CLTimerSummary *rec = [uinfo objectAtIndex:0];
    id doc = [rec doc];
    NSMutableArray *tvm = [sumAllController model];
    int timerId = [tvm indexOfObject:rec];
    
    // update the record on the summary tableview
    [rec updCountdown];
    [sumAllController updateTV];
    
    // update the dock menu item
    [[dockMenu itemAtIndex: (timerId+1)] setTitle:[rec shortDescr]];
    
    // update timer window if present
    if ([doc isKindOfClass:[MyDocument class]])
    {
        s = [NSString stringWithFormat:@"%@ - %@", [rec countdown], 
                [rec precomputed]];
        [doc setStatusInfo:s];
    }
}


/*" 
Invalidates the active main NSTimer related to `timerId', if instantiated. 
A release message is sent to the NSTimer and to the updating timer, 
which are therefore deallocated. 
The related timer model is updated to the reflect the new status, and if the 
related MyDocument is open, its UI is updated.
This method may be called by MyDocument or by the `doGestures' method
once the timer has completed. 
"*/
- (void)invalidateTimer:(int)timerId code:(int)code
{
    debug_enter("AppController -invalidateTimer:code:");

    NSDate *date;
    NSString *si, *dockInfo, *ls;
    NSTimer *t, *ut;
    BOOL isRepeatEnabled;
    CLTimerSummary *rec = [[sumAllController model] objectAtIndex: timerId];
    id doc = [rec doc]; // may be either the doc or the timermodel
    CLSimpleTimerModel *tm = [doc timerModel];
    NSBundle *mainBundle = [NSBundle mainBundle];
        
    if (code & CLSimpleTimerMainExpMask)
    {
        t = [rec timer];
        ut = [rec updatingTimer];
        date = [t fireDate];
        
        debug0cocoa(@"About to invalidate mainTimer: rtnCnt=%d", 
                        [t retainCount]);
        debug0cocoa(@"About to invalidate updatingTimer: rtnCnt=%d", 
                        [ut retainCount]);
        
        // harmless if timer is already invalid
        [t invalidate]; 
        [ut invalidate];

        [tm setTimerStarted: NO];
        [tm setCycleTimesLeft:[tm cycleTimes]];
        
        // sets nil and releases the timer once. If we accidentally send a msg
        // to timer & it's released but NOT nil, we've a crash
        [rec setTimer: nil];
        
        [rec setUpdatingTimer: nil];
        debug0cocoa(@"Timer and updating timer invalidated.");
        
        // determine statusInfo string to be displayed
        if (code & CLSimpleTimerUserInvMask)
        {
            // in this case the timer was invalidated by user
            ls = [mainBundle localizedStringForKey:@"Stopped" 
                                             value:@"Stopped"
                                             table:@"Localizable"];
            si = [NSString stringWithFormat:@"%@ - %@", [rec countdown], ls];
            
            // generate string for the timer window and the dock menu
            NSString *end = [self formattedStringForDate:[tm fireDate]];
            ls = [mainBundle localizedStringForKey:@"DockStoppedWouldHaveMsg" 
                                        value:@"STOPPED - Would have ended "
                                             table:@"Localizable"];
            dockInfo = [ls stringByAppendingString:end];
            [doc setStatusInfo: dockInfo];
            dockInfo = [mainBundle localizedStringForKey:@"DockStoppedMsg" 
                                                   value:@"STOPPED"
                                                   table:@"Localizable"];
        }
        else 
        {
            // in this case the timer was NOT invalidated by user
        
            /*NSRange range;
            NSMutableAttributedString *s1, *s2;
            NSDictionary *sd;
            NSMutableParagraphStyle *ps;*/
            
            si = [self formattedStringForDate:date];
            isRepeatEnabled = [tm repeatFlag];
            if (isRepeatEnabled)
            {
                ls = [mainBundle localizedStringForKey:@"AllEnded" 
                                            value:@"All repetitions ended %@"
                                                 table:@"Localizable"];
            }
            else {
                ls = [mainBundle localizedStringForKey:@"Ended" 
                                                 value:@"ENDED %@"
                                                 table:@"Localizable"];
            }
            si = [NSString stringWithFormat: ls, si];
            
            /*ps = [[[NSMutableParagraphStyle alloc] init] autorelease];
            [ps setAlignment:NSRightTextAlignment];
            sd = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor redColor], NSForegroundColorAttributeName, 
                ps, NSParagraphStyleAttributeName, nil];
            
            s1 = [[[NSAttributedString alloc] initWithString:s 
                                                  attributes:sd] autorelease];
            s2 = [[s1 copy] autorelease];
            [d setAttrStatusInfo: s1];*/
            
            [doc setStatusInfo: si];
            if ([doc isKindOfClass:[MyDocument class]])
            {
                // if doc is open, update timer UI as well
                [doc invalidateTimer:self];
            }
            dockInfo = si;
        }
        [sumAllController resetCountdown:si
                                withFont:countdownEndedFont
                                 timerId:timerId];
        dockInfo = [NSString stringWithFormat:@"%@ - %@!", dockInfo, [tm msg]];
        [[dockMenu itemAtIndex: (timerId+1)] setTitle:dockInfo];
    }
    
    debug_exit("AppController -invalidateTimer:code:");
}


/*" This is the method that is called when the timer fires. "*/
- (void)doGestures:(NSTimer *)aTimer
{   
    debug_enter("Appcontroller -doGestures:");
    
    // qui retainCount per il timer  giˆ 3 
    debug0cocoa(@"mainTimer: rtnCnt=%d", [aTimer retainCount]);
    
    NSDate *mfdate, *nextFdate;
    NSWorkspace *sharedWorkspace;
    BOOL must_open_alert = NO;
    NSURL *url;
    NSString *s, *alertTitle, *alertMsg, *mfdateDes, *nextFdateDes;
    NSTimeInterval t;
    NSSound *snd;
    int cycleTimesLeft, invalidationCode;
    NSMutableArray *uinfo = [aTimer userInfo];
    NSMutableArray *tvm = [sumAllController model];
    int tid = [tvm indexOfObject:[uinfo objectAtIndex:0]];
    CLTimerSummary *rec = [tvm objectAtIndex:tid];
    id d = [rec doc]; // may be a MyDocument or a CLSimpleTimerModel
    CLSimpleTimerModel *timerModel = [d timerModel];
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    debug0cocoa(@"Executing gestures for %@", self);
    
    invalidationCode = CLSimpleTimerMainExpMask;
    
    // check if we have to play a sound
    if (([timerModel sndFlag] == NSOnState) && ([timerModel sndTimes] > 0))
    {
        s = [[timerModel sndDir] stringByAppendingString:
            [timerModel sndName]];
        snd = [[NSSound alloc] initWithContentsOfFile: s
                                          byReference: YES];
        [snd setDelegate: rec];
        [snd play];
    }
    
    // check if I have to open an URL
    if ([timerModel urlFlag] == NSOnState)
    {
        s = [timerModel url];
        url = [NSURL URLWithString:s];
        sharedWorkspace = [NSWorkspace sharedWorkspace];
        [sharedWorkspace openURL:url];
    }

    cycleTimesLeft = [timerModel cycleTimesLeft];
    mfdate = [[rec timer] fireDate];
    mfdateDes = [self formattedStringForDate:mfdate];
    
    // calculate the next fire date.
    // must add the time interval (ie next repetition) of the timer cos
    // [timer fireDate] returns the fireDate that just happened (not
    // the next one) while we're inside dogestures (the fired method).
    t = [aTimer timeInterval];
    nextFdate = [mfdate addTimeInterval: t];
    nextFdateDes = [self formattedStringForDate:nextFdate];
    
    if (mfdate == nil || [mfdate timeIntervalSinceNow] < 0) 
    {
        // if this was the last or only repetition, make sure invalidate both timers
        if ((cycleTimesLeft == 1) || (cycleTimesLeft == 0))
        {
            invalidationCode = CLSimpleTimerMainExpMask;
        }
    }    
    
    // handle the case of opening an alert box
    if (([timerModel msgFlag] == NSOnState)) 
    {
        // we have to open an alert panel for the main timer
        s = [mainBundle localizedStringForKey:@"ReminderTitle" 
                                        value:@"Reminder: %@"
                                        table:@"Localizable"];
        alertTitle = [NSString stringWithFormat: s, [timerModel msg]];
        
        s = [mainBundle localizedStringForKey:@"ThisTimerExpired" 
                                        value:@"This timer expired %@."
                                        table:@"Localizable"];
        alertMsg = [NSString stringWithFormat: s, mfdateDes];
        
        if ([timerModel repeatFlag] == NSOnState)
        {
            if (cycleTimesLeft == 0)
            {
                s = [mainBundle localizedStringForKey:@"FinalReminder" 
                                                value:@"%@ This is the final reminder."
                                                table:@"Localizable"];
                alertMsg = [NSString stringWithFormat: s, alertMsg];
            } 
            else if (cycleTimesLeft == 1)
            {
                s = [mainBundle localizedStringForKey:@"OneMoreRepetition" 
                                                value:@"%@ There is 1 more repetition to go."
                                                table:@"Localizable"];
                alertMsg = [NSString stringWithFormat: s, alertMsg];
            }
            else 
            {
                s = [mainBundle localizedStringForKey:@"XMoreRepetitions" 
                                                value:@"%@ There are %d more repetitions to go."
                                                table:@"Localizable"];
                alertMsg = [NSString stringWithFormat: s, alertMsg, cycleTimesLeft];
            }
        }

        debug2cocoa(@"alertMsg == %@", alertMsg);
        must_open_alert = YES;
    }
    
    // invalidate timers if no more cycles has to be done
    if ([timerModel repeatFlag] == NSOffState || cycleTimesLeft == 0)
    {
        //
        // Repeat is OFF or this is the last cycle of the repetitions
        //
        
        [self invalidateTimer:tid code:invalidationCode];
    } 
    else 
    {
        //
        // Repeat is ON and this is not the last cycle of the repetitions
        //
        
        s = [mainBundle localizedStringForKey:@"NextRepStatusInfo" 
                                        value:@"Next (#%d) will end %@"
                                        table:@"Localizable"];
        
        s = [NSString stringWithFormat: s, 
            ([timerModel cycleTimes] - cycleTimesLeft + 1), nextFdateDes];
        
        [d setStatusInfo: s];
        [rec setPrecomputed:s]; // for the updCountdown method
    }
    
    // decrement cycleTimesLeft 
    if (cycleTimesLeft > 0)
        [timerModel setCycleTimesLeft: (--cycleTimesLeft)];

    if (must_open_alert)
        NSRunAlertPanel(alertTitle, @"%@", @"OK", nil, nil, alertMsg);
        
    debug_exit("doGestures:");
}


// ############################################################
//              DOCUMENT CONTROLLER METHODS
// ############################################################

/*"
Callback called by MyDocument timerStillRunSheetDidEnd:returnCode:contextInfo:
or canCloseDocumentWithDelegate:shouldCloseSelector:. The first opened a 
custom sheet, the 2nd the default Cocoa save/don't save warning sheet.
This callback is always invoked while closing a document `d'. `shouldClose' is
a hint on what to do (from the sheets). `c' is a pointer to int pointing at: 
 - CLKeepOnCloseSheetCode if "Close but Keep Timer" was chosen;
 - CLRemoveOnCloseSheetCode if "Remove Timer" was chosen; 
 - CLSaveOnCloseSheetCode
 - NULL if the custom sheet was not opened. This happens if timer is inactive
   or the "alwaysReturn" pref. user default option is currently selected. 
   In this case the default Cocoa save warning sheet was opened, and the 
   doc eventually saved.
In any case, after whatever sheet is closed, control goes to this method.
 "*/
- (void) document:(NSDocument *)document
      shouldClose:(BOOL)shouldClose 
      contextInfo:(void *)c
{
    debug_enter("AppController -document:shouldClose:contextInfo");
    MyDocument *d = (MyDocument *)document;
    
    if (c == NULL)
        c = (void *)&CLRemoveOnCloseSheetCode;
    
    if (CLKeepOnCloseSheetCode == *(int *)c)
    {
        // "Keep timer but close document" button was pressed
        [self handleClosingSimpleTimerDocument:d contextInfo:c];
        debug0cocoa(@"Closed MyDocument (keeping timer): %@", d);        
    }
    else
    {
        // "Remove Timer" button was pressed or do traditional behavior; 
        // typically, `shouldClose' is YES if doc is saved or user selected 
        // "Don't Save" (but this method could have been invoked with YES)
        if (shouldClose)
        {
            [self handleClosingSimpleTimerDocument:d contextInfo:c];
            debug0cocoa(@"Closed MyDocument (removing timer): %@", d);
        }
    }
    
    debug_exit("AppController -document:shouldClose:contextInfo");
}


/*" 
This is a callback method called by MyDocument method 
`saveToFile:saveOperation:delegate:didSaveSelector:contextInfo:'
after having saved the file from the custom `closeSheet' of MyDocument.
Basically calls handleClosingSimpleTimerDocument:contextInfo:.
"*/
- (void)docOnClose:(NSDocument *)d 
           didSave:(BOOL)didSave 
       contextInfo:(void *)c
{
    if (didSave && ( *((int*)c) == CLSaveOnCloseSheetCode))
        [self handleClosingSimpleTimerDocument:(MyDocument *)d contextInfo:c];
}

/*" 
This method handles the closing of a document consequent to a user request.
`d' is the document being closed, and `alertRetCode' is the alert response
code from the user input that determined it.
"*/
- (void)handleClosingSimpleTimerDocument:(MyDocument *)d
                             contextInfo:(void *)alertRetCode
{    
    int timerId = [d timerId];
    id rec = [[sumAllController model] objectAtIndex: timerId];
    
    if (CLKeepOnCloseSheetCode == *(int*)alertRetCode)
    {
        // ## "Keep timer but close document" button was pressed
        // retain the timer model since it'll be released by the doc
        [rec setDoc: [d timerModel]];
        [rec setIsDirty: [d isDocumentEdited]];
    }
    else
    {
        // ## "Remove Timer" sheet btn was pressed, or do tradit. doc behavior
        [self removeTimerWithId:timerId];
    }
    [d close];
}


// ############################################################
//               METHODS HANDLING APP TERMINATION      
// ############################################################

/*" 
Eventually calls -reviewDocsBeforeQuitting that will trigger the custom alert termination 
box. 
"*/
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    debug_enter("AppController -applicationShouldTerminate:");
    int choice = NSAlertAlternateReturn;
    
    if (!didReviewChanges)
        // eventually open the custom termination alert
        choice = [self reviewDocsBeforeQuitting];
    
    didReviewChanges = NO;
    // choice == NSAlertDefaultReturn   --> Cancel btn
    // choice == NSAlertAlternateReturn --> Quit anyway button was chosen
    debug_exit("AppController -applicationShouldTerminate:");
    if (choice == NSAlertAlternateReturn)
        return NSTerminateNow;
    else
        return NSTerminateCancel;
}

/*" 
Triggers the custom alert termination box if there are unsaved or active
timers.
"*/
- (int)reviewDocsBeforeQuitting
{
    NSEnumerator *enumer;
    CLTimerSummary *rec;
    CLSimpleTimerModel *tm;
    id doc;
    int i = 0, choice;
    unsigned numUnsaved = 0, numActive = 0;
    
    // gather info (how many unsaved, active, etc.)
    enumer = [[sumAllController model] objectEnumerator];
    while (nil != (rec = [enumer nextObject]))
    {
        doc = [rec doc];
        tm = [doc timerModel];
        
        if ([tm timerStarted])
            numActive++;
        
        if ([rec isDocumentEdited])
        {
            numUnsaved++;
            BOOL isDocOpen = [doc isKindOfClass:[MyDocument class]];
            if (!isDocOpen)
                [self removeTimerWithId:[doc timerId]];
        }
        
        i++;
    }
    
    // all the unsaved non-active timers whose document is not even open 
    // can simply be deleted NOW
    
    // if the alert won't be opened, we quit anyway
    choice = NSAlertAlternateReturn;
    
    // if there're some unsaved || active, open dialog
    if (/*numUnsaved || */numActive)
        choice = [self openTerminationAlertWithActive:numActive 
                                              unsaved:numUnsaved];
    return choice;
}

/*" 
Open summarized alert box listing how many active and unsaved timers are 
present.
"*/
- (int)openTerminationAlertWithActive:(int)numActive unsaved:(int)numUnsaved
{
    debug_enter("AppController -openTerminationAlertWithActive:");
    
    NSString *s, *a, *title, *msg, *defaultBtn, *altBtn;
    int choice;
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    // build up the message for the user depending on the timers status
    title = @"You have ";
    msg = @"If you quit, ";
    if (numUnsaved > 0)
    {
        if (numUnsaved == 1)
            s = [mainBundle localizedStringForKey:@"UnsavedChangesTitle1"
                                            value:@"%@%d timer with unsaved changes%@"
                                            table:@"Localizable"];
        else
            s = [mainBundle localizedStringForKey:@"UnsavedChangesTitle"
                                            value:@"%@%d timers with unsaved changes%@"
                                            table:@"Localizable"];
        
        a = (numActive > 0 ? [mainBundle localizedStringForKey:@"and"
                                                         value:@" and "
                                                         table:@"Localizable"]
             : @"" );
        
        title = [NSString stringWithFormat: s, title, numUnsaved, a];
        
        s = [mainBundle localizedStringForKey:@"ChangesWillBeLost"
                                        value:@"%@all your unsaved changes will be lost%@"
                                        table:@"Localizable"];
        
        msg = [NSString stringWithFormat: s, msg, a];
    }
    
    if (numActive > 0)
    {
        if (numActive == 1)
            s = [mainBundle localizedStringForKey:@"OneTimerStillActive"
                                            value:@"%@%d timer still active"
                                            table:@"Localizable"];
        else
            s = [mainBundle localizedStringForKey:@"TimersStillActive"
                                            value:@"%@%d timers still active"
                                            table:@"Localizable"];
        
        title = [NSString stringWithFormat: s, title, numActive];
        
        s = [mainBundle localizedStringForKey:@"AllTimersWillBeRemoved"
                                        value:@"%@all your active timers will be stopped and removed"
                                        table:@"Localizable"];
        msg = [NSString stringWithFormat: s, msg];
    }
    
    if (numActive + numUnsaved == 1)
        s = [mainBundle localizedStringForKey:@"DoYouWannaReviewIt"
                                        value:@"%@. Do you want to review it before quitting?"
                                        table:@"Localizable"];
    else
        s = [mainBundle localizedStringForKey:@"DoYouWannaReviewThem"
                                        value:@"%@. Do you want to review them before quitting?"
                                        table:@"Localizable"];
    
    title = [NSString stringWithFormat: s, title];
    msg = [NSString stringWithFormat:@"%@.", msg];
    /*defaultBtn = [mainBundle localizedStringForKey:@"Review"
                                             value:@"Review"
                                             table:@"Localizable"];*/
    altBtn     = [mainBundle localizedStringForKey:@"QuitAnyway"
                                             value:@"Quit Anyway"
                                             table:@"Localizable"];
    defaultBtn   = [mainBundle localizedStringForKey:@"Cancel"
                                             value:@"Cancel"
                                             table:@"Localizable"];
    
    // give the user the chance to review unsaved changes & active timers
    //choice = NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
    debug0cocoa(@"alertMsg == %@", msg);
    choice = NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, nil, msg);
    debug_exit("AppController -openTerminationAlertWithActive:");
    return choice;
}


// ##############################################################
//                        ACTIONS
// ##############################################################


/*" Opens an alert panel and redirects to
http://cubelogic.org/support/donations/paypal-SimpleTimer.html "*/
- (IBAction) makeDonation:(id)sender
{
    debug_enter("AppController: makeDonation:");
    
    NSURL *url;
    int res;
    NSString *t, *s, *gotoPaypal, *anotherTime;
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    t = [mainBundle localizedStringForKey:@"DonationAlertTitle" 
                                    value:@"Thank you for considering a donation!"
                                    table:@"Localizable"];
    s = [mainBundle localizedStringForKey:@"DonationAlertMsg" 
                                    value:@"Now you will be redirected to the PayPal website. Login into your PayPal account, use <e@cubelogic.org> as \"Recipient's Email\" (if not already filled in), and send an amount of your choice, in a currency of your choice.\n\nIf you have any questions or concerns regarding your donation, please feel free to contact Cubelogic at <support@cubelogic.org>.\nThanks for your support!"
                                    table:@"Localizable"];
    gotoPaypal = [mainBundle localizedStringForKey:@"GotoPayPal" 
                                             value:@"Go to PayPal"
                                             table:@"Localizable"];
    anotherTime = [mainBundle localizedStringForKey:@"AnotherTime" 
                                              value:@"Another time"
                                              table:@"Localizable"];
    
    debug0cocoa(@"alertMsg = %@",s);
    res = NSRunAlertPanel(t, @"%@", gotoPaypal, anotherTime, nil, s);
    
    if (res == NSAlertDefaultReturn) {
        url = [NSURL URLWithString:@"http://cubelogic.org/support/donations/paypal-SimpleTimer.html"];
        res = [[NSWorkspace sharedWorkspace] openURL:url];
        debug0cocoa(@"SimpleTimer makeDonation: result of opening URL %@: %d.", 
              url, res);
    }
    debug_exit("AppController: makeDonation:");
}

- (IBAction) emailFeedback:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"mailto:support@cubelogic.org?subject=SimpleTimer%20Feedback"]];
}

- (IBAction) bugReport:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"http://cubelogic.org/support/bugreport/"]];
}

/*" 
Opens the Preferences panel. It is called by the `Preferences...' main 
menu option.
"*/
- (IBAction) showPreferencePanel:(id)sender{
    debug_enter("AppController: showPreferencePanel:");
    // if the PreferenceController is nil, let's alloc-init it
    if (!preferenceController)
        preferenceController = [[PreferenceController alloc] init];
    [preferenceController showWindow:self];
    debug_exit("AppController: showPreferencePanel:");
}


/*" 
Opens a window with a summary of all open timers. It is called by the 
main menu.
"*/
- (IBAction) showSummaryOfAllTimers:(id)sender
{
    debug_enter("AppController: showSummaryOfAllTimers:");
    //[summaryAllTimers setString:[self computeSummaryOfAllTimers]];
    //[summaryAllTimersWindow makeKeyAndOrderFront:sender];
    [sumTableAllWindow makeKeyAndOrderFront:sender];
    [sumAllController updateUI];
    debug_exit("AppController: showSummaryOfAllTimers:");
}


// ##############################################################
//                  SETTER / GETTER METHODS
// ##############################################################

-(CLTimerSummaryTvController *)sumAllController { return sumAllController; }
-(PreferenceController *)preferenceController { return preferenceController; }
-(NSString *)defaultSoundDir { return defaultSoundDir; }
-(void)setPreferenceController:(PreferenceController *)controller
{
    [controller retain];
    [preferenceController release];
    preferenceController = controller;
}
- (NSFont *)countdownFont { return countdownFont; }
- (void)setCountdownFont:(NSFont *)_t_m_p_
{
	[_t_m_p_ retain];
	[countdownFont release];
	countdownFont = _t_m_p_;
}
- (NSFont *)countdownEndedFont { return countdownEndedFont; }
- (void)setCountdownEndedFont:(NSFont *)_t_m_p_
{
	[_t_m_p_ retain];
	[countdownEndedFont release];
	countdownEndedFont = _t_m_p_;
}

@end


