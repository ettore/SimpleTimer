//  MyDocument.h
//  Created by ep on $Date: 2005/10/16 21:39:58 $Revision: 1.1.1.1 $
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
#import "CLSimpleTimerGlobals.h"
#define CL_SIMPLETIMER_WARNING @"CL_SIMPLETIMER_WARNING"
@class AppController;
@class CLSimpleTimerModel;

@interface MyDocument : NSDocument
{
    IBOutlet NSWindow      *myWindow;
    IBOutlet NSMatrix      *dateRadio; /*" Radio btn for the fire date "*/
    IBOutlet NSTextField   *fireDateField; /*" Fire date, ie date the timer will fire. Uses the %Y-%m-%d %H:%M:%S format, which conforms to YYYY-MM-DD HH:MM:SS"*/
    IBOutlet NSTextField   *afterHrsField;
    IBOutlet NSTextField   *afterMinsField;
    IBOutlet NSTextField   *afterSecsField;
    IBOutlet NSTextField   *statusInfoField;
    IBOutlet NSTextField   *actualMsg;
    IBOutlet NSPopUpButton *msgPresets; 
    IBOutlet NSButton 	   *openAlertCheckbox; // message
    IBOutlet NSButton      *openUrlCheckbox;  // open URL
    IBOutlet NSPopUpButton *urlPresets;
    IBOutlet NSTextField   *actualUrl;
    IBOutlet NSButton      *playSndCheckbox;
    IBOutlet NSPopUpButton *sndPresets;
    IBOutlet NSTextField   *sndTimesField;
    IBOutlet NSButton      *saveUrlBtn;
    IBOutlet NSButton      *saveMsgBtn;
    IBOutlet NSButton 	   *repeatCheckbox; // repeat    
    IBOutlet NSTextField   *cycleTimesField;
    IBOutlet NSTextField   *hourField; /*" Hours of the Repeat cycle."*/
    IBOutlet NSTextField   *minField; /*" Minutes of the Repeat cycle."*/
    IBOutlet NSTextField   *secField; /*" Seconds of the Repeat cycle."*/
    IBOutlet NSButton 	   *autostartCheckbox; // autostart
    IBOutlet NSButton      *startButton;	// buttons
    IBOutlet NSButton      *invalidateButton;
    IBOutlet NSTextField   *repeatText1;
    IBOutlet NSTextField   *repeatText2;
    IBOutlet NSTextField   *repeatText3;
    IBOutlet NSTextField   *repeatText4;
    IBOutlet NSTextField   *dateText1;
    IBOutlet NSTextField   *dateText2;
    IBOutlet NSTextField   *dateText3;
    IBOutlet NSWindow      *closeSheet;
    IBOutlet NSWindow      *docQuitSheet;

    CLSimpleTimerModel *timerModel;/*"Collects all data of a SimpleTimer document. "*/
    AppController *appController;
    int timerId;
    NSString *willEnd;/*Used to display the countdown on the timer window.*/
}

- (int)timerId;
- (void)setTimerId:(int)_t_m_p_;
 

// actions
- (IBAction) changeFireDateRadio:(id)sender;
- (IBAction) changeFireDate:(id)sender;
- (IBAction) changeCycleHour:(id)sender;
- (IBAction) changeCycleMin:(id)sender;
- (IBAction) changeCycleSec:(id)sender;
- (IBAction) changeRepeatCheck:(id)sender;
- (IBAction) changeURLCheck:(id)sender;
- (IBAction) changeUrlPreset:(id)sender;
- (IBAction) changeUrl:(id)sender;
- (IBAction) saveUrl:(id)sender;
- (IBAction) changePlaySndCheck:(id)sender;
- (IBAction) changeSndPreset:(id)sender;
- (IBAction) changeSndTimes:(id)sender;
- (IBAction) changeAlertCheck:(id)sender;
- (IBAction) changeMsgPreset:(id)sender;
- (IBAction) changeMsg:(id)sender;
- (IBAction) saveMsg:(id)sender;
- (IBAction) changeAutostartCheck:(id)sender;
- (IBAction) startTimer:(id)sender;
- (IBAction) invalidateTimer:(id)sender;
- (IBAction) loadSoundOpenPanel:(id)sender;
//- (IBAction) changeWarnmeCheck:(id)sender;
//- (IBAction) changeWarnme:(id)sender;
//- (IBAction) changeWarnmeRadio:(id)sender;
- (IBAction) changeCycleTimes:(id)sender;
- (IBAction) changeAfterHour:(id)sender;
- (IBAction) changeAfterMin:(id)sender;
- (IBAction) changeAfterSec:(id)sender;
- (IBAction)cancelTimerStillRunningSheet:(id)sender;
- (IBAction)saveTimerStillRunningSheet:(id)sender;
- (IBAction)removeTimerStillRunningSheet:(id)sender;
- (IBAction)keepTimerStillRunningSheet:(id)sender;
- (IBAction)cancelDocQuitSheet:(id)sender;
- (IBAction)saveDocQuitSheet:(id)sender;
- (IBAction)removeDocQuitSheet:(id)sender;


// notification methods
- (void) controlTextDidChange:  (NSNotification *)aNotification;

// getter and setter methods
- (NSTextField *)fireDateField;
- (NSTextField *)actualUrl;
- (NSTextField *)actualMsg;
- (NSButton *)repeatCheckbox;
- (NSButton *)autostartCheckbox;
- (CLSimpleTimerModel *)timerModel;
- (void)setTimerModel:(CLSimpleTimerModel *)tmodel;
- (NSWindow *)myWindow;
//- (AppController *)appController;
//- (void)setAppController:(AppController *)_t_m_p_;
- (NSTextField *)statusInfoField;
- (NSString *)willEnd;
- (void)setWillEnd:(NSString *)_t_m_p_;

// other methods (recall: all methods are public)
- (void) updateUI;
- (void) updateUIWithTimerStatus;
- (void) enableDateSectionWithModel;
- (void) enableRepeatSectionWithModel;
- (void) enableUrlSectionWithModel;
- (void) enableSnd:(int)state;
//- (void) enableWarnmeSectionWithModel;
- (void) replacePopupMenu: (NSPopUpButton*)popUpMenu
        withRecordsArray: (NSMutableArray*)arrayOfRecords
                   title: (NSString*)title;
- (void) updatePopupMenu:(NSPopUpButton*)popUpMenu
             withString:(NSString*)title;
- (void) modifyUrlWith:(NSString *)s;
- (NSDate *)fireDate;
- (void)setStatusInfo:(NSString *)s;

// sheet methods
- (void) timerStillRunSheetDidEnd:(NSWindow *)sheet
                       returnCode:(int)code
                      contextInfo:(void *)info;
/*- (void)document:(NSDocument *)doc 
     shouldClose:(BOOL)shouldClose 
     contextInfo:(void *)contextInfo;*/
@end
