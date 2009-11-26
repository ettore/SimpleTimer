//
//  CLSimpleTimerModel.m
//  SimpleTimer
//  Created by ep on 11/17/04.
//  Copyright 2004 Cubelogic. All rights reserved.
//

#import "CLSimpleTimerModel.h"
#import "CLURLCateg.h"

const int CL_SIMPLETIMER_START_AT_DATE = 0;
const int CL_SIMPLETIMER_START_AFTER = 1;
const int CL_SIMPLETIMER_WARNME_SEC = 0;
const int CL_SIMPLETIMER_WARNME_MIN = 1;

@implementation CLSimpleTimerModel

// #####################################################################
// ##############      INIT / DEALLOC METHODS             ##############
// #####################################################################


/*" This is the designated init. "*/
- (id)initWithMsgs:(NSMutableArray *)msgs 
              urls:(NSMutableArray *)urls
            sndDir:(NSString *)dir
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *s;
    
    self = [super init];
    s = [mainBundle localizedStringForKey:@"UntitledDoc" 
                                    value:@"Untitled"
                                    table:@"Localizable"];
    [self setName: s];
    atDateNow = CL_SIMPLETIMER_START_AFTER;
    [self setFiringDateString: 
        [[NSDate date]  descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S"
                                            timeZone:nil
                                              locale:nil]];
    
    if (urls == nil)
        urls = [NSMutableArray array];

    if (msgs == nil) 
        msgs = [NSMutableArray array];

    afterHrs = 0;
    afterMins = 0;
    afterSecs = 0;
    statusInfo = [[NSBundle mainBundle] localizedStringForKey:@"IdleTimerStatusInfo"
														value:@"Idle"
														table:@"Localizable"];
    [self setUrlList: urls];
    [self setMsgList: msgs];
    urlFlag = NSOffState;
    [self setUrl:@""];
    sndFlag = NSOffState;
    [self setSndName:@"--"];
    [self setSndDir:dir];
    sndTimes = 1;
    msgFlag = NSOnState;
    s = [mainBundle localizedStringForKey:@"DefaultReminder" 
                                    value:@"Timer Alert!"
                                    table:@"Localizable"];
    [self setMsg: s];
    appLaunchFlag = NSOffState;
    repeatFlag = NSOffState;
    autoFlag = NSOnState;
    timerStarted = NO;
    warnFlag = NSOffState;
    warnAmount = 5.0;
    warnUOM = CL_SIMPLETIMER_WARNME_MIN;
    cycleHrs = 0;
    cycleMins = 0;
    cycleSecs = 0;
    cycleTimes = 1;
    cycleTimesLeft = cycleWarnTimesLeft = cycleTimes;
    return self;
}


- (id)init
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *s = [mainBundle localizedStringForKey:@"CLDefaultSoundDirKey"
                                              value:@"/System/Library/Sounds/"
                                              table:@"Localizable"];
    self = [self initWithMsgs:nil urls:nil sndDir:s];
    return self;
}

- (void)dealloc
{
    [name release];
    [firingDateString release];
    [url release];
    [sndName release];
    [sndDir release];
    [msg release];
    [msgList release];
    [urlList release];
    [statusInfo release];
    [super dealloc];
}

// #########################################################################
// ##################    KEY-VALUE CODING METHODS        ###################
// #########################################################################

- (void)setNilValueForKey:(NSString *)key
{    
    if ([key isEqual:@"sndTimes"] || [key isEqual:@"cycleTimes"])
        [self setSndTimes: 1];
    else if ([key isEqual:@"timerStarted"]) 
        [self setTimerStarted: NO];
    else {
        NSArray *stringKeys = [[NSArray alloc] initWithObjects:@"atDateNow", 
            @"cycleHrs", @"cycleMins", @"cycleSecs", @"afterHrs", @"afterMins",
            @"afterSecs", @"cycleTimesLeft", @"cycleWarnTimesLeft"];
        if ([stringKeys indexOfObject: key]) 
            [self setValue: [[NSNumber alloc] initWithInt:0] forKey: key];
        else {
            [stringKeys release];    
            stringKeys = [[NSArray alloc] initWithObjects:@"urlFlag", 
                @"sndFlag", @"msgFlag", @"appLaunchFlag", 
                @"repeatFlag", @"autoFlag"];
            if ([stringKeys indexOfObject: key]) 
                [self setValue: [[NSNumber alloc] initWithInt:NSOffState] 
                        forKey: key];
            else 
                [super setNilValueForKey: key];
        }
        [stringKeys release];
    }
}

// #########################################################################
// ##################    NSCODING (ARCHIVING) METHODS    ###################
// #########################################################################

/*" unarchiving (read from coder) method. "*/
- (id) initWithCoder: (NSCoder *) coder
{
    // if superclass implemented NSCoding, it would have called:
    //[super initWithCoder: coder]; // instead of [super init]
    self = [super init];
    
    [self setName: [coder decodeObjectForKey:@"name"]];
	[self setFiringDateString: [coder decodeObjectForKey:@"firingDateString"]];
	[self setUrl: [coder decodeObjectForKey:@"url"]];
	[self setSndName: [coder decodeObjectForKey:@"sndName"]];
	[self setSndDir: [coder decodeObjectForKey:@"sndDir"]];
	[self setMsg: [coder decodeObjectForKey:@"msg"]];
	[self setAtDateNow: [coder decodeIntForKey:@"atDateNow"]];
	[self setCycleHrs: [coder decodeIntForKey:@"cycleHrs"]];
	[self setCycleMins: [coder decodeIntForKey:@"cycleMins"]];
	[self setCycleSecs: [coder decodeIntForKey:@"cycleSecs"]];
	[self setUrlFlag: [coder decodeIntForKey:@"urlFlag"]];
	[self setSndFlag: [coder decodeIntForKey:@"sndFlag"]];
	[self setSndTimes: [coder decodeIntForKey:@"sndTimes"]];
	[self setMsgFlag: [coder decodeIntForKey:@"msgFlag"]];
	[self setAppLaunchFlag: [coder decodeIntForKey:@"appLaunchFlag"]];
	[self setRepeatFlag: [coder decodeIntForKey:@"repeatFlag"]];
	[self setAutoFlag: [coder decodeIntForKey:@"autoFlag"]];
	[self setTimerStarted: [coder decodeBoolForKey:@"timerStarted"]];
    [self setMsgList: [coder decodeObjectForKey:@"msgList"]];
	[self setUrlList: [coder decodeObjectForKey:@"urlList"]];
    [self setWarnFlag: [coder decodeIntForKey:@"warnFlag"]];
	[self setWarnAmount: [coder decodeFloatForKey:@"warnAmount"]];
	[self setWarnUOM: [coder decodeIntForKey:@"warnUOM"]];
    [self setCycleTimes: [coder decodeIntForKey:@"cycleTimes"]];
    [self setCycleTimesLeft: [coder decodeIntForKey:@"cycleTimesLeft"]];
	[self setCycleWarnTimesLeft:[coder decodeIntForKey:@"cycleWarnTimesLeft"]];
	[self setAfterHrs: [coder decodeIntForKey:@"afterHrs"]];
	[self setAfterMins: [coder decodeIntForKey:@"afterMins"]];
	[self setAfterSecs: [coder decodeIntForKey:@"afterSecs"]];
	[self setStatusInfo: [coder decodeObjectForKey:@"statusInfo"]];    
    return self;
}

/*" archiving (write from coder) method "*/
- (void) encodeWithCoder: (NSCoder *) coder
{
    // if superclass implemented NSCoding, we would have also called:
    //[super encodeWithCoder: coder];
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:firingDateString forKey:@"firingDateString"];
	[coder encodeObject:url forKey:@"url"];
	[coder encodeObject:sndName forKey:@"sndName"];
	[coder encodeObject:sndDir forKey:@"sndDir"];
	[coder encodeObject:msg forKey:@"msg"];
	[coder encodeInt:atDateNow forKey:@"atDateNow"];
	[coder encodeInt:cycleHrs forKey:@"cycleHrs"];
	[coder encodeInt:cycleMins forKey:@"cycleMins"];
	[coder encodeInt:cycleSecs forKey:@"cycleSecs"];
	[coder encodeInt:urlFlag forKey:@"urlFlag"];
	[coder encodeInt:sndFlag forKey:@"sndFlag"];
	[coder encodeInt:sndTimes forKey:@"sndTimes"];
	[coder encodeInt:msgFlag forKey:@"msgFlag"];
	[coder encodeInt:appLaunchFlag forKey:@"appLaunchFlag"];
	[coder encodeInt:repeatFlag forKey:@"repeatFlag"];
	[coder encodeInt:autoFlag forKey:@"autoFlag"];
	[coder encodeBool:NO/*timerStarted*/ forKey:@"timerStarted"];
	[coder encodeObject:msgList forKey:@"msgList"];
	[coder encodeObject:urlList forKey:@"urlList"];
	[coder encodeInt:warnFlag forKey:@"warnFlag"];
	[coder encodeFloat:warnAmount forKey:@"warnAmount"];
	[coder encodeInt:warnUOM forKey:@"warnUOM"];
    [coder encodeInt:cycleTimes forKey:@"cycleTimes"];
    [coder encodeInt:cycleTimes forKey:@"cycleTimesLeft"];
    [coder encodeInt:cycleTimes forKey:@"cycleWarnTimesLeft"];
	[coder encodeInt:afterHrs forKey:@"afterHrs"];
	[coder encodeInt:afterMins forKey:@"afterMins"];
	[coder encodeInt:afterSecs forKey:@"afterSecs"];
	[coder encodeObject:@"" forKey:@"statusInfo"];
}

// #####################################################################
// ##############           UTILITY METHODS               ##############
// #####################################################################

- (void)addMsg: (NSString *)s
{
    if ([msgList indexOfObject:s] == NSNotFound)
        [msgList addObject: s];
}

- (void)addUrl: (NSString *)s
{
    if ([urlList indexOfObject:s] == NSNotFound)
        [urlList addObject: s];
}

+ (NSArray *)allowedSndExtensions
{
    return [NSSound soundUnfilteredFileTypes];
}

- (NSDate *)fireDate
{
    NSDate *fireDate;
    NSTimeInterval afterTotal;
    
    if (atDateNow == CL_SIMPLETIMER_START_AFTER) 
    {
        // case 0: timer fire from NOW in `afterSecs' seconds
        afterTotal = afterHrs * 3600 + afterMins * 60 + afterSecs;
        fireDate = [[NSDate date] addTimeInterval:afterTotal];
    }
    else {
        // case 1: timer will fire at user designated fire-date
        if ([firingDateString isEqual:@""]) 
        {
            fireDate = [NSDate date];
        } 
        else {
            NSString *localTZone;
            /* 
            int hrsFromGMT=[[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
             int minFromGMT=([[NSTimeZone localTimeZone] secondsFromGMT] % 3600)/60;
             localTZon=[NSString stringWithFormat:@"%d%d",hrsFromGMT,minFromGMT];
             */
            // [NSDate description] guarantees to return a 
            // `YYYY-MM-DD HH:MM:SS ±HHMM' string
            localTZone = [[[NSDate date] description] substringFromIndex:19];
            fireDate = [NSDate dateWithString:[firingDateString 
                stringByAppendingString: localTZone]];
        }
    }
    return fireDate;
}

- (CLSimpleTimerModel *)timerModel { return self; }
- (NSString *)fileName { return name; }

// #####################################################################
// ##############           ACCESSOR METHODS              ##############
// #####################################################################

- (NSString *) name
{
	return name;
}
- (void) setName:(NSString *)newName
{
    [newName retain];
	[name release];
	name= newName;
}

- (int) atDateNow
{
	return atDateNow;
}
- (void) setAtDateNow:(int)newAtDateNow
{
	atDateNow=newAtDateNow;
}

- (NSString *) firingDateString
{
	return firingDateString;
}
- (void) setFiringDateString:(NSString *)newFiringDateString
{
    [newFiringDateString retain];
	[firingDateString release];
	firingDateString=newFiringDateString;
}

- (int) cycleHrs
{
	return cycleHrs;
}
- (void) setCycleHrs:(int)newCycleHrs
{
	cycleHrs=newCycleHrs;
}

- (int) cycleMins
{
	return cycleMins;
}
- (void) setCycleMins:(int)newCycleMins
{
	cycleMins=newCycleMins;
}

- (int) cycleSecs
{
	return cycleSecs;
}
- (void) setCycleSecs:(int)newCycleSecs
{
	cycleSecs=newCycleSecs;
}

- (int) urlFlag
{
	return urlFlag;
}
- (void) setUrlFlag:(int)newUrlFlag
{
	urlFlag=newUrlFlag;
}

- (NSString *) url
{
	return url;
}
- (void) setUrl:(NSString *)newUrl
{
    newUrl = [NSURL adjustUrlString: newUrl];
    [newUrl retain];
	[url release];
	url= newUrl ;
}

- (int) sndFlag
{
	return sndFlag;
}
- (void) setSndFlag:(int)newSndFlag
{
	sndFlag=newSndFlag;
}

- (NSString *) sndName
{
	return sndName;
}
- (void) setSndName:(NSString *)newSndName
{
    [newSndName retain];
	[sndName release];
	sndName=newSndName;
}

- (NSString *) sndDir
{
	return sndDir;
}
- (void) setSndDir:(NSString *)newSndDir
{
    newSndDir = [newSndDir stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![newSndDir hasSuffix: @"/"])
        newSndDir = [newSndDir stringByAppendingString:@"/"];
    [newSndDir retain];
	[sndDir release];
	sndDir=newSndDir;
}

- (int) sndTimes
{
	return sndTimes;
}
- (void) setSndTimes:(int)newSndTimes
{
	sndTimes=newSndTimes;
}

- (int) msgFlag
{
	return msgFlag;
}
- (void) setMsgFlag:(int)newMsgFlag
{
	msgFlag=newMsgFlag;
}

- (NSString *) msg
{
	return msg;
}
- (void) setMsg:(NSString *)newMsg
{
    [newMsg retain];
	[msg release];
	msg=newMsg;
}

- (int) appLaunchFlag
{
	return appLaunchFlag;
}
- (void) setAppLaunchFlag:(int)newAppLaunchFlag
{
	appLaunchFlag=newAppLaunchFlag;
}

- (int) repeatFlag
{
	return repeatFlag;
}
- (void) setRepeatFlag:(int)newRepeatFlag
{
	repeatFlag=newRepeatFlag;
}

- (int) autoFlag
{
	return autoFlag;
}
- (void) setAutoFlag:(int)newAutoFlag
{
	autoFlag=newAutoFlag;
}

- (BOOL) timerStarted { return timerStarted;}
- (void) setTimerStarted:(BOOL)t {timerStarted = t;}

- (NSMutableArray *) msgList
{
	return msgList;
}
- (void) setMsgList:(NSMutableArray *)newMsgList
{
    [newMsgList retain];
	[msgList release];
	msgList = newMsgList;
}

- (NSMutableArray *) urlList
{
	return urlList;
}
- (void) setUrlList:(NSMutableArray *)newUrlList
{
    [newUrlList retain];
	[urlList release];
	urlList = newUrlList;
}

- (int) warnFlag                  { return warnFlag;   }
- (void) setWarnFlag:(int)flag    { warnFlag = flag;   }
- (float) warnAmount              { return warnAmount; }
- (void) setWarnAmount:(float)a   { warnAmount = a;    }
- (int) warnUOM                   { return warnUOM;    }
- (void) setWarnUOM:(int)x        { warnUOM = x;       }

- (int)cycleTimes { return cycleTimes; }
- (void)setCycleTimes:(int)_t_m_p_ 
{ 
    cycleTimes = _t_m_p_;
    if (!timerStarted)
    {
        // need to call the setter to trigger the key/value observer
        [self setCycleTimesLeft:cycleTimes];
        [self setCycleWarnTimesLeft:cycleTimes];
    }
}
- (int)cycleTimesLeft { return cycleTimesLeft; }
- (void)setCycleTimesLeft:(int)_t_m_p_ { cycleTimesLeft = _t_m_p_; }
- (int)cycleWarnTimesLeft { return cycleWarnTimesLeft; }
- (void)setCycleWarnTimesLeft:(int)_t_m_p_ { cycleWarnTimesLeft = _t_m_p_; }
- (int)afterHrs { return afterHrs; }
- (void)setAfterHrs:(int)_t_m_p_ { afterHrs = _t_m_p_; }
- (int)afterMins { return afterMins; }
- (void)setAfterMins:(int)_t_m_p_ { afterMins = _t_m_p_; }
- (int)afterSecs { return afterSecs; }
- (void)setAfterSecs:(int)_t_m_p_ { afterSecs = _t_m_p_; }
- (NSString *)statusInfo { return statusInfo; }
- (void)setStatusInfo:(NSString *)_t_m_p_
{
	[_t_m_p_ retain];
	[statusInfo release];
	statusInfo = _t_m_p_;
}

@end
