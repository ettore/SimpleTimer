/*
 *  CLSimpleTimerGlobals.h
 *  Created by ep on Tue Jun 10 2003.
 *  Copyright 2003, 2004 Ettore Pasquini.

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

#include "CLCommonConst.h"

/* Names of the User Defaults keys (for User Preferences). */
extern NSString *CLUrlPresetsKey;
extern NSString *CLMsgPresetsKey;
extern NSString *CLSaveButtonScopeKey;
extern NSString *CLDefaultSoundDirKey;
extern NSString *CLSimpleTimerAlwaysRemoveKey;

/* Names of the notifications used by SimpleTimer. */
extern NSString *CLTableViewChanged ;
extern NSString *CLSimpleTimerNew;
extern NSString *CLSimpleTimerWindowClosing;
extern NSString *CLSaveBtnScopeChanged;
extern NSString *CLAddDefaultTvEntry;

/* Keys used in notifications' userInfo dictionaries. */
extern NSString *CLTableViewKey;
extern NSString *CLDefaultsEntryKey;

/* Const for AppController operations on opening new documents. */
extern const int CLOpeningTimerFromDisk;
extern const int CLCreatingNewTimerFromScratch;
extern const int CLAddingNewTimer; // includes 1 and 2
extern const int CLReopeningTimer;
extern const int CLSimpleTimerQuitting;
extern const int CLDefaultOpeningOperation; // == CLOpeningTimerFromDisk

/* Const for alert sheet. */
extern const int CLCancelOnCloseSheetCode;
extern const int CLSaveOnCloseSheetCode;
extern const int CLRemoveOnCloseSheetCode;
extern const int CLKeepOnCloseSheetCode;
extern NSString *CLCancelOnCloseSheetStringCode;
extern NSString *CLSaveOnCloseSheetStringCode;
extern NSString *CLRemoveOnCloseSheetStringCode;
extern NSString *CLKeepOnCloseSheetStringCode;

/* Other */
extern NSString *CLDefaultSoundMenuTitle;
extern NSString *CLSimpleTimerDocType;
// means the main timer must be invalidated
extern const int CLSimpleTimerMainExpMask;
// means the timer was invalidated by the user
extern const int CLSimpleTimerUserInvMask;

