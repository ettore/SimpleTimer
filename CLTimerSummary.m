//
//  TimerSummary.m
//  SimpleTimer
//  Created by ep on 12/4/04.
//  Copyright 2004 Cubelogic. All rights reserved.
//

#import "CLTimerSummary.h"
#import "CLSimpleTimerModel.h"
#import "CLTableViewRecord.h"
#import "MyDocument.h"

NSString *CLTimerSummaryChanged = @"CLTimerSummaryChanged";

@implementation CLTimerSummary
/*" 
This class is kind of a surrogate of MyDocument when the document is
closed.
"*/

// #####################################################################
// ##############      INIT / DEALLOC METHODS             ##############
// #####################################################################

- (id)init
{
    return [self initWithName:@"" countdown:@"" repeat:@"" 
                     autoFlag:@"" reminder:@""];
}

/*" Designated initializer. "*/
- (id)initWithName:(NSString *)n countdown:(NSString *)con repeat:(NSString *)r 
          autoFlag:(NSString *)a reminder:(NSString *)rem
{
    if ((self = [super init]))
    {
        [self setName:n];
        [self setCountdown:con];
        [self setRepeat:r];
        [self setAutoFlag:a];
        [self setReminder:rem];
        doc = nil;
        timer = nil;
        updatingTimer = nil;
        remainingTimes = -1;
        isDirty = YES;
    }
    return self;
}

- (id)initWithSimpleTimerDocument:(MyDocument *)d
{
    NSString *s, *time, *times, *yes, *no, *sec, *min;
    CLSimpleTimerModel *tm;
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    if ((self = [super init]))
    {
        tm = [d timerModel];
        [self setDoc:d];
        
        time = [mainBundle localizedStringForKey:@"Time" 
                                           value:@"time"
                                           table:@"Localizable"];
        times = [mainBundle localizedStringForKey:@"Times" 
                                            value:@"times"
                                            table:@"Localizable"];
        s = [mainBundle localizedStringForKey:@"SummaryRepeat"
                                        value:@"%d %@, every %d:%d:%d"
                                        table:@"Localizable"];
        s = ([tm repeatFlag] == NSOffState ? 
             @"" : [NSString stringWithFormat: s, 
                 [tm cycleTimesLeft], 
                 ([tm cycleTimesLeft] == 1 ? time : times),
                 [tm cycleHrs], [tm cycleMins], [tm cycleSecs]]);
        [self setRepeat:s];
        
        sec = [mainBundle localizedStringForKey:@"SecAbbr" 
                                          value:@"sec"
                                          table:@"Localizable"];
        min = [mainBundle localizedStringForKey:@"MinAbbr" 
                                          value:@"min"
                                          table:@"Localizable"];
        yes = [mainBundle localizedStringForKey:@"Yes" 
                                          value:@"Yes"
                                          table:@"Localizable"];
        no  = [mainBundle localizedStringForKey:@"No" 
                                          value:@"No"
                                          table:@"Localizable"];
        
        [self setName:[tm msg]];
        [self setCountdown: @""];
        [self setAutoFlag:(([tm autoFlag] == NSOnState) ? yes : no)];
        [self setReminder:[self generateActionsMeld]];
        timer = nil;
        updatingTimer = nil;
        remainingTimes = -1;
        isDirty = [d isDocumentEdited];
        [self startObservingTimerModel:tm];
    }
    return self;
}


- (void)dealloc
{
    debug_enter("CLTimerSummary -dealloc");
    [self stopObservingTimerModel:[doc timerModel]];
    [name release];
    [countdown release];
    [repeat release];
    [autoFlag release];
    [reminder release];
    [doc release];
    [timer invalidate]; // harmless if timer is already invalid
    [timer release];
    [updatingTimer invalidate]; // harmless if timer is already invalid
    [updatingTimer release];
    [super dealloc];
    debug_exit("CLTimerSummary -dealloc");
}


// #####################################################################
// ##############       KEY VALUE OBSERVING METHODS       ##############
// #####################################################################

/*" 
Adds all the needed observers for the member variables of the timerMmodel.
"*/
- (void)startObservingTimerModel:(CLSimpleTimerModel *)tm
{
    /*[tm addObserver: self
         forKeyPath: @"name"
            options: NSKeyValueObservingOptionNew
            context: NULL];*/
    [tm addObserver: self
         forKeyPath: @"repeatFlag"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"cycleTimesLeft"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"cycleHrs"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"cycleMins"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"cycleSecs"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"autoFlag"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"msgFlag"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"msg"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"urlFlag"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"url"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"sndFlag"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"sndName"
            options: NSKeyValueObservingOptionNew
            context: NULL];
    [tm addObserver: self
         forKeyPath: @"sndTimes"
            options: NSKeyValueObservingOptionNew
            context: NULL];
}

/*" Removes all the observers for the member variables of the timerMmodel."*/
- (void)stopObservingTimerModel:(CLSimpleTimerModel *)tm
{
    //[tm removeObserver:self forKeyPath:@"name"];
    [tm removeObserver:self forKeyPath:@"repeatFlag"];
    [tm removeObserver:self forKeyPath:@"cycleTimesLeft"];
    [tm removeObserver:self forKeyPath:@"cycleHrs"];
    [tm removeObserver:self forKeyPath:@"cycleMins"];
    [tm removeObserver:self forKeyPath:@"cycleSecs"];
    [tm removeObserver:self forKeyPath:@"autoFlag"];
    [tm removeObserver:self forKeyPath:@"msgFlag"];
    [tm removeObserver:self forKeyPath:@"msg"];
    [tm removeObserver:self forKeyPath:@"urlFlag"];
    [tm removeObserver:self forKeyPath:@"url"];
    [tm removeObserver:self forKeyPath:@"sndFlag"];
    [tm removeObserver:self forKeyPath:@"sndName"];
    [tm removeObserver:self forKeyPath:@"sndTimes"];
    
}

/*" When a change occurs, this method is called. The observer (this class)
is told which `object' has changed and what change has occurred. "*/
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)tm
                        change:(NSDictionary *)change
                       context:(void *)context
{
    debug_enter("CLTimerSummary -observeValueForKeyPath:");
    
    NSString *s, *time, *times, *yes, *no;
    id newVal = [change objectForKey:NSKeyValueChangeNewKey];
    NSBundle *mainBundle = [NSBundle mainBundle];
        
    if ([@"msg" isEqual:keyPath])
    {
        [self setValue:newVal forKeyPath:@"name"];
    }
    else if ([@"repeatFlag" isEqual:keyPath])
    {
        time = [mainBundle localizedStringForKey:@"Time" 
                                           value:@"time"
                                           table:@"Localizable"];
        times = [mainBundle localizedStringForKey:@"Times" 
                                            value:@"times"
                                            table:@"Localizable"];
        s = [mainBundle localizedStringForKey:@"SummaryRepeat"
                                        value:@"%d %@, every %d:%d:%d"
                                        table:@"Localizable"];
        
        if ([newVal intValue] == NSOffState)
            [self setRepeat:@""];
        else
            [self setRepeat:
                [NSString stringWithFormat: s, [tm cycleTimesLeft], 
                    ([tm cycleTimesLeft]==1 ? time:times),
                    [tm cycleHrs], [tm cycleMins], [tm cycleSecs]]];
    }
    else if (([tm repeatFlag] == NSOnState) &&
             ([@"cycleTimesLeft" isEqual:keyPath] || 
              [@"cycleHrs" isEqual:keyPath]       ||
              [@"cycleMins" isEqual:keyPath]      ||
              [@"cycleSecs" isEqual:keyPath]        ))
    {
        time = [mainBundle localizedStringForKey:@"Time" 
                                           value:@"time"
                                           table:@"Localizable"];
        times = [mainBundle localizedStringForKey:@"Times" 
                                            value:@"times"
                                            table:@"Localizable"];
        s = [mainBundle localizedStringForKey:@"SummaryRepeat"
                                        value:@"%d %@, every %d:%d:%d"
                                        table:@"Localizable"];
        [self setRepeat:
            [NSString stringWithFormat: s, [tm cycleTimesLeft], 
                ([tm cycleTimesLeft] == 1 ? time : times),
                [tm cycleHrs], [tm cycleMins], [tm cycleSecs]]];
    }
    else if ([@"autoFlag" isEqual:keyPath])
    {
        yes = [mainBundle localizedStringForKey:@"Yes" 
                                          value:@"Yes"
                                          table:@"Localizable"];
        no  = [mainBundle localizedStringForKey:@"No" 
                                          value:@"No"
                                          table:@"Localizable"];
        [self setValue:([newVal intValue] == NSOnState ? yes : no)
            forKeyPath: keyPath];
    }
    else if ([@"urlFlag" isEqual:keyPath] || [@"url" isEqual:keyPath]      ||
             [@"msgFlag" isEqual:keyPath] || [@"sndTimes" isEqual:keyPath] ||
             [@"sndFlag" isEqual:keyPath] || [@"sndName" isEqual:keyPath]  )
    {
        [self setReminder:[self generateActionsMeld]];
    }

    debug_exit("CLTimerSummary -observeValueForKeyPath:");
}


// #####################################################################
// ##############           ACCESSOR METHODS              ##############
// #####################################################################

- (NSString *)name { return name; }

/*" 
Sets the name of the receiver and posts a CLTimerSummaryChanged notification.
"*/
- (void)setName:(NSString *)_t_m_p_
{
	_t_m_p_ = [_t_m_p_ copy];
	[name release];
	name = _t_m_p_;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: CLTimerSummaryChanged
                      object: self];
}

- (NSString *)countdown { return countdown; }

/*" 
Sets the countdown of the receiver and posts a CLTimerSummaryChanged 
    notification.
"*/
- (void)setCountdown:(NSString *)_t_m_p_
{
	_t_m_p_ = [_t_m_p_ copy];
	[countdown release];
	countdown = _t_m_p_;
}

- (NSString *)repeat { return repeat; }

/*" 
Sets the repeat attribute of the receiver and posts a CLTimerSummaryChanged 
notification.
"*/
- (void)setRepeat:(NSString *)_t_m_p_
{
	_t_m_p_ = [_t_m_p_ copy];
	[repeat release];
	repeat = _t_m_p_;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: CLTimerSummaryChanged
                      object: self];
}

- (NSString *)autoFlag { return autoFlag; }

/*" 
Sets the autoStart-flag of the receiver and posts a CLTimerSummaryChanged 
notification.
"*/
- (void)setAutoFlag:(NSString *)_t_m_p_
{
	_t_m_p_ = [_t_m_p_ copy];
	[autoFlag release];
	autoFlag = _t_m_p_;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: CLTimerSummaryChanged
                      object: self];
}

- (NSString *)reminder { return reminder; }

/*" 
Sets the reminder description  of the receiver and posts a 
CLTimerSummaryChanged notification.
"*/
- (void)setReminder:(NSString *)_t_m_p_
{
	_t_m_p_ = [_t_m_p_ copy];
	[reminder release];
	reminder = _t_m_p_;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: CLTimerSummaryChanged
                      object: self];
}

- (id)doc { return doc; }

- (void)setDoc:(id)_t_m_p_
{
	[_t_m_p_ retain];
	[doc release];
	doc = _t_m_p_;
}

- (NSTimer *)timer { return timer; }

- (void)setTimer:(NSTimer *)_t_m_p_
{
	[_t_m_p_ retain];
	[timer release];
	timer = _t_m_p_;
}

- (NSTimer *)updatingTimer { return updatingTimer; }

- (void)setUpdatingTimer:(NSTimer *)_t_m_p_
{
	[_t_m_p_ retain];
	[updatingTimer release];
	updatingTimer = _t_m_p_;
}

- (int)remainingTimes { return remainingTimes; }

- (void)setRemainingTimes:(int)_t_m_p_ { remainingTimes = _t_m_p_; }

- (NSString *)precomputed { return precomputed; }

- (void)setPrecomputed:(NSString *)_t_m_p_
{
	[_t_m_p_ retain];
	[precomputed release];
	precomputed = _t_m_p_;
}

/*" 
If the class instance references a MyDocument instance  -as one can obtain
from [slef doc], this method also updates the change count of the doc. 
"*/
- (void)setIsDirty:(BOOL)_t_m_p_ 
{
    isDirty = _t_m_p_;
    if ([doc isKindOfClass:[MyDocument class]])
    {
        [[doc myWindow] setDocumentEdited:isDirty];
        if (isDirty)
            [doc updateChangeCount:NSChangeDone];
    }
}

- (BOOL)isDirty { return isDirty; }

- (BOOL)isDocumentEdited
{
    if ([doc respondsToSelector:@selector(isDocumentEdited)])
        return [doc isDocumentEdited];
    else
        return isDirty;
}

// #####################################################################
// ##############           DELEGATE METHODS              ##############
// #####################################################################

/*" 
This class is also the delegate for the sound gestures related to the 
timer. 
"*/
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)successfulPLayback
{
    debug_enter("sound:didFinishPlaying");
    // if remainingTimes is not initialized (-1), we properly load it
    if (remainingTimes == -1)
        remainingTimes = [[doc timerModel] sndTimes];
    
    remainingTimes--;
    if (remainingTimes <= 0)
    {
        remainingTimes = -1;
        [sound release];
        sound = nil;
    }
    else
    {
        [sound play];
    }
    debug_exit("sound:didFinishPlaying:");
}


// #####################################################################
// ##############            UTILITY METHODS              ##############
// #####################################################################

- (NSString *)generateActionsMeld
{
    CLSimpleTimerModel *tm = [doc timerModel];
    NSString *time, *times, *openAlert, *open, *playFormat;
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    time = [mainBundle localizedStringForKey:@"Time" 
                                       value:@"time"
                                       table:@"Localizable"];
    times = [mainBundle localizedStringForKey:@"Times" 
                                        value:@"times"
                                        table:@"Localizable"];
    times = (([tm sndTimes] == 1) ? time : times);
    openAlert = [mainBundle localizedStringForKey:@"OpenAlertBox" 
                                            value:@"Open alert box; "
                                            table:@"Localizable"];
    open = [mainBundle localizedStringForKey:@"Open" 
                                       value:@"Open"
                                       table:@"Localizable"];
    playFormat = [mainBundle localizedStringForKey:@"SummaryPlaySnd" 
                                             value:@"Play %@ %d %@;"
                                             table:@"Localizable"];
    
    return [NSString stringWithFormat:@"%@%@%@",
        (([tm msgFlag] == NSOnState) ? openAlert : @""),
        (([tm urlFlag] == NSOnState) ? 
         [NSString stringWithFormat:@"%@ %@; ", open, [tm url]] : @""),
        (([tm sndFlag]== NSOnState) ? 
         [NSString stringWithFormat: playFormat,
             [tm sndName], [tm sndTimes], times] : @"")];
}

/*" Sets the countdown field as HH:MM:SS from now to the firedate. "*/
- (void)updCountdown
{
    NSDate *fireDate;
    NSString *s;
    NSTimeInterval remTime;
    // these are structs holding quotient and remainder of a division
    ldiv_t hrsAndSecs, minsAndSecs;
    
    // timer firedate or current date set on the document
    fireDate = [([timer isValid] ? timer : doc) fireDate];
    // seconds between the firedate and now
    remTime = [fireDate timeIntervalSinceNow];
    
    // `ldiv' returns quotient and remainder of a division
    hrsAndSecs = ldiv((long)remTime, 3600);
    minsAndSecs = ldiv(hrsAndSecs.rem, 60);
    s = [NSString stringWithFormat:@"%ldh:%ldm:%lds", hrsAndSecs.quot, 
        minsAndSecs.quot, minsAndSecs.rem];
    [self setCountdown: s];
}


/*" This is used for isEqual determination by CLTableViewRecord. "*/
/*- (NSString *)description
{
    //[NSString stringWithFormat:
    //    @"in %@: %@; repeat: %@; warning: %@; auto: %@; actions: %@; dirty:", 
    //    countdown, name, repeat, autoFlag, reminder, isDirty];
    return [super description];
}*/

- (NSString *)shortDescr
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *notStarted = [mainBundle localizedStringForKey:@"NotStarted" 
                                                       value:@"Not started"
                                                       table:@"Localizable"];
    
    return [NSString stringWithFormat:@"%@: %@", 
        ([@"" isEqual:countdown] ? notStarted : countdown), name];
}

@end
