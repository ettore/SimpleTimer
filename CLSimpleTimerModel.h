//
//  CLSimpleTimerModel.h
//  SimpleTimer
//  Created by ep on 11/17/04.
//  Copyright 2004 Cubelogic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CLSimpleTimerGlobals.h"

extern const int CL_SIMPLETIMER_START_AFTER;
extern const int CL_SIMPLETIMER_START_AT_DATE;
extern const int CL_SIMPLETIMER_WARNME_SEC;
extern const int CL_SIMPLETIMER_WARNME_MIN;

@interface CLSimpleTimerModel : NSObject {
    NSString *name; /*"Used to store the filename of this timer."*/
    NSString *firingDateString;//date it'll fire if atDateNow=CLSimpleTimerAtDate
    NSString *url;
    NSString *sndName;
    NSString *sndDir;// must include a final `/'
    NSString *msg;
    NSMutableArray *msgList;
    NSMutableArray *urlList;
    int atDateNow;//indicates if timer starts now or at a certain date
    int afterHrs;
    int afterMins;
    int afterSecs;
    int urlFlag; // NSOnState or NSOffState
    int sndFlag; // NSOnState or NSOffState
    int sndTimes;
    int msgFlag; // NSOnState or NSOffState
    int appLaunchFlag; // NSOnState or NSOffState
    int repeatFlag; // NSOnState or NSOffState
    int autoFlag; // NSOnState or NSOffState
    BOOL timerStarted;/*"Tells whether the timer is active or stopped."*/
    int warnFlag; // NSOnState or NSOffState
    float warnAmount;
    int warnUOM;
    int cycleTimes;
    int cycleTimesLeft;
    int cycleWarnTimesLeft;
    int cycleHrs;
    int cycleMins;
    int cycleSecs;
    NSString *statusInfo;
}

// ################################################################
// ##############        DESIGNATED INIT           ################
// ################################################################

- (id)initWithMsgs:(NSMutableArray *)msgs 
              urls:(NSMutableArray *)urls 
            sndDir:(NSString *)dir;

// ################################################################
// ##############       UTILITY METHODS           #################
// ################################################################

/*" Returns an array containing the sound file types handled by this timer. 
Currently this is the result of [NSSound soundUnfilteredFileTypes].
"*/
+ (NSArray *)allowedSndExtensions;
- (void)addMsg: (NSString *)s;
- (void)addUrl: (NSString *)s;
- (NSDate *)fireDate;
- (CLSimpleTimerModel *)timerModel;
- (NSString *)fileName;

// ################################################################
// ##########    GETTER AND SETTER METHODS     ####################
// ################################################################

- (NSString *) name;
- (NSString *) firingDateString;
- (NSString *) url;
- (NSString *) sndName;
- (NSString *) sndName;
- (NSString *) sndDir;
- (NSString *) msg;
- (void) setName:(NSString *)newName;
- (void) setFiringDateString:(NSString *)newFiringDateString;
- (void) setUrl:(NSString *)newUrl;
- (void) setSndName:(NSString *)newSndName;
- (void) setSndDir:(NSString *)newSndDir;
- (void) setMsg:(NSString *)newMsg;
- (int) atDateNow;
- (void) setAtDateNow:(int)newAtDateNow;
- (int) cycleHrs;
- (void) setCycleHrs:(int)newCycleHrs;
- (int) cycleMins;
- (void) setCycleMins:(int)newCycleMins;
- (int) cycleSecs;
- (void) setCycleSecs:(int)newCycleSecs;
- (int) urlFlag;
- (void) setUrlFlag:(int)newUrlFlag;
- (int) sndFlag;
- (void) setSndFlag:(int)newSndFlag;
- (int) sndTimes;
- (void) setSndTimes:(int)newSndTimes;
- (int) msgFlag;
- (void) setMsgFlag:(int)newMsgFlag;
- (int) appLaunchFlag;
- (void) setAppLaunchFlag:(int)newAppLaunchFlag;
- (int) repeatFlag;
- (void) setRepeatFlag:(int)newRepeatFlag;
- (int) autoFlag;
- (void) setAutoFlag:(int)newAutoFlag;
- (BOOL) timerStarted;
- (void) setTimerStarted:(BOOL)newTimerStarted;
- (NSMutableArray *)urlList;
- (void) setUrlList: (NSMutableArray *)arr;
- (NSMutableArray *)msgList;
- (void) setMsgList: (NSMutableArray *)arr;
- (int) warnFlag;
- (void) setWarnFlag:(int)flag;
- (float) warnAmount;
- (void) setWarnAmount:(float)amt;
- (int) warnUOM;
- (void) setWarnUOM:(int)x;
- (int)cycleTimes;
- (void)setCycleTimes:(int)_t_m_p_;
- (int)cycleTimesLeft;
- (void)setCycleTimesLeft:(int)_t_m_p_;
- (int)cycleWarnTimesLeft;
- (void)setCycleWarnTimesLeft:(int)_t_m_p_;
- (int)afterHrs;
- (void)setAfterHrs:(int)_t_m_p_;
- (int)afterMins;
- (void)setAfterMins:(int)_t_m_p_;
- (int)afterSecs;
- (void)setAfterSecs:(int)_t_m_p_;
- (NSString *)statusInfo;
- (void)setStatusInfo:(NSString *)_t_m_p_;

@end
