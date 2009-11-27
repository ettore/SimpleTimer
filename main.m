//  main.m
//  Created by ep on Thu Jun 05 2003.
//  Copyright 2003, 2004 Ettore Pasquini.

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

#import <Cocoa/Cocoa.h>
#include "CLCommonConst.h"

const char *kOurProductName = "SimpleTimer";

/* Names of the User Defaults keys (for User Preferences). */
const NSString *CLUrlPresetsKey = @"CLUrlPresetsKey";
const NSString *CLMsgPresetsKey = @"CLMsgPresetsKey";
const NSString *CLSaveButtonScopeKey = @"CLSaveButtonScopeKey";
const NSString *CLDefaultSoundDirKey = @"CLDefaultSoundDirKey";
const NSString *CLSimpleTimerAlwaysRemoveKey = @"CLSimpleTimerAlwaysRemoveKey";

/* Names of the notifications used by SimpleTimer. */
const NSString *CLTableViewChanged = @"CLTableViewChanged";
const NSString *CLSaveBtnScopeChanged = @"CLSaveBtnScopeChanged";
const NSString *CLAddDefaultTvEntry = @"CLAddDefaultTvEntry";
const NSString *CLSimpleTimerNew = @"CLSimpleTimerNew";
const NSString *CLSimpleTimerWindowClosing = @"CLSimpleTimerWindowClosing";

/* Keys used in notifications' userInfo dictionaries.*/
const NSString *CLDefaultsEntryKey = @"CLDefaultsEntryKey";
const NSString *CLTableViewKey = @"CLTableViewKey";

/* Const for AppController operations on opening new documents. */
const int CLOpeningTimerFromDisk        = 1; // default
const int CLCreatingNewTimerFromScratch = 2;
const int CLAddingNewTimer              = 3; // includes 1 and 2
const int CLReopeningTimer              = 4;
const int CLSimpleTimerQuitting         = 5;
const int CLDefaultOpeningOperation     = 1;

const int CLCancelOnCloseSheetCode = 1;
const int CLSaveOnCloseSheetCode = 2;
const int CLRemoveOnCloseSheetCode = 3;
const int CLKeepOnCloseSheetCode = 4;
NSString *CLCancelOnCloseSheetStringCode = @"1";
NSString *CLSaveOnCloseSheetStringCode = @"2";
NSString *CLRemoveOnCloseSheetStringCode = @"3";
NSString *CLKeepOnCloseSheetStringCode = @"4";


/* Other constants */
const NSString *CLDefaultSoundMenuTitle = @"Sosumi.aiff";
const NSString *CLSimpleTimerDocType = @"SimpleTimer Document";
// means the main timer must be invalidated
const int CLSimpleTimerMainExpMask = 1;
// DEPRECATED means the warn timer must be invalidated
const int CLSimpleTimerWarnExpMask = 2;
// means the timer was invalidated by the user
const int CLSimpleTimerUserInvMask = 4;

int main(int argc, const char *argv[])
{
    return NSApplicationMain(argc, (const char **) argv);
}

