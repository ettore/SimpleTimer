//
//  TimerSummary.h
//  SimpleTimer
//  Created by ep on 12/4/04.
//  Copyright 2004 Cubelogic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CLTableViewRecord.h";
@class CLSimpleTimerModel;
@class MyDocument;

extern NSString *CLTimerSummaryChanged;

@interface CLTimerSummary : CLTableViewRecord <NSSoundDelegate>
{
    NSString *name;
    NSString *countdown;/*"End date if timer not started."*/
    NSString *repeat;/*"Repeat cycle in HH:MM:SS."*/
    NSString *warn;/*" "*/
    NSString *autoFlag;/*" "Yes" or "No". "*/
    NSString *reminder;/*"A meld of the chosen msg/url/sound. "*/
    id doc; /*"Reference to the MyDocument; if the document has been closed but
        we're still olding onto the timer, this member variable is a 
        reference to the timerModel (of class CLSimpleTimerModel)."*/
    NSTimer *timer;
    NSTimer *updatingTimer;
    int remainingTimes; /*"Number of times the sound related to this timer 
        must be played still."*/
    NSString *precomputed; //an utility variable for `updCountdown' method
    BOOL isDirty;
}

// initializers
- (id)initWithName:(NSString *)n countdown:(NSString *)con 
            repeat:(NSString *)r warn:(NSString *)w
          autoFlag:(NSString *)a reminder:(NSString *)rem;
- (id)initWithSimpleTimerDocument:(MyDocument *)d;

// key-value observing methods
- (void)startObservingTimerModel:(CLSimpleTimerModel *)tm;
- (void)stopObservingTimerModel:(CLSimpleTimerModel *)tm;

// utility methods
- (NSString *)generateActionsMeld;
- (void)updCountdown;
- (NSString *)shortDescr;
- (BOOL)isDocumentEdited;

// NSSound delegate methods
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)successfulPLayback;

// accessors
- (NSString *)name;
- (void)setName:(NSString *)_t_m_p_;
- (NSString *)countdown;
- (void)setCountdown:(NSString *)_t_m_p_;
- (NSString *)repeat;
- (void)setRepeat:(NSString *)_t_m_p_;
- (NSString *)warn;
- (void)setWarn:(NSString *)_t_m_p_;
- (NSString *)autoFlag;
- (void)setAutoFlag:(NSString *)_t_m_p_;
- (NSString *)reminder;
- (void)setReminder:(NSString *)_t_m_p_;
- (id)doc;
- (void)setDoc:(id)_t_m_p_;
- (NSTimer *)timer;
- (void)setTimer:(NSTimer *)_t_m_p_;
- (NSTimer *)updatingTimer;
- (void)setUpdatingTimer:(NSTimer *)_t_m_p_;
- (void)updCountdown;
- (int)remainingTimes;
- (void)setRemainingTimes:(int)_t_m_p_;
- (BOOL)isDirty;
- (void)setIsDirty:(BOOL)_t_m_p_;
- (NSString *)precomputed;
- (void)setPrecomputed:(NSString *)_t_m_p_;

@end
