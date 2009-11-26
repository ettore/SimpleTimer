//  AppController.h
//  Created by ep on $Date: 2005/10/21 11:22:58 $Revision: 1.2 $
//  Copyright (c) 2003 Ettore Pasquini.

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
@class PreferenceController;
@class CLTimerSummaryTvController;
@class MyDocument;

@interface AppController : NSDocumentController {
    PreferenceController *preferenceController;/*"Owner of Preferences.nib"*/
    IBOutlet NSWindow *sumTableAllWindow;
    IBOutlet NSTableView *sumTableAll;
    IBOutlet CLTimerSummaryTvController *sumAllController;
    IBOutlet NSMenu *dockMenu;
    int currentOperation;
    NSFont *countdownFont;
    NSFont *countdownEndedFont;
    BOOL didReviewChanges;
    NSString *samedayDateFormat;
    NSString *sameyearDateFormat;
    NSString *fullDateFormat;
    NSString *defaultSoundDir;
}

// actions
- (IBAction) showPreferencePanel:(id)sender;
- (IBAction) showSummaryOfAllTimers:(id)sender;
- (IBAction) newDoc:(id)sender;
- (IBAction) editTimer:(id)sender;
- (IBAction) removeTimer:(id)sender;
- (IBAction) makeDonation:(id)sender;
- (IBAction) emailFeedback:(id)sender;
- (IBAction) bugReport:(id)sender;

// notification methods
- (void)handleNewSimpleTimerDocument:(NSNotification *)note;

// timer methods
- (void)recomputeTimerIdsFromId:(int)tid;
- (void)startTimer:(int)timerId;
- (void)invalidateTimer:(int)timerId code:(int)code;

// document controller methods
- (void)docOnClose:(NSDocument *)doc 
           didSave:(BOOL)didSave 
       contextInfo:(void *)contextInfo;
- (void) doc:(NSDocument *)d shouldClose:(BOOL)b contextInfo:(void *)c;
- (void)handleClosingSimpleTimerDocument:(MyDocument *)doc
                             contextInfo:(void *)contextInfo;

// utility methods
- (MyDocument *)reopenDoc:(int)timerId;
- (void)removeTimerWithId:(int)timerId;
- (void)updateDoc:(MyDocument *)d withTimerId:(int)timerId;
- (NSString *)formattedStringForDate:(NSDate *)date;
- (BOOL) loadPreferencesNib;
- (id)openUntitledDoc:(int)operation;

// termination methods
- (int)openTerminationAlertWithActive:(int)numActive unsaved:(int)numUnsaved;
- (void) invalidateAllTimers;
- (int)reviewDocs;
// - (void)reviewAllDocsOnQuit;
// - (void)restoreDirtyStatusForIndexes:(NSSet *)set;

// delegate methods
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app;

// getter and setter methods
- (PreferenceController *)preferenceController;
- (void)setPreferenceController:(PreferenceController *)controller;
- (CLTimerSummaryTvController *)sumAllController;
- (NSString *)defaultSoundDir;
- (NSFont *)countdownFont;
- (void)setCountdownFont:(NSFont *)_t_m_p_;
- (NSFont *)countdownEndedFont;
- (void)setCountdownEndedFont:(NSFont *)_t_m_p_;

@end
