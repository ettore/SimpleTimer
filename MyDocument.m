//
//  MyDocument.m
//  Copyright (c) 2003 Ettore Pasquini.
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

#import "MyDocument.h"
#import "CLSimpleTimerModel.h"
#import "AppController.h"
#import "CLTableViewUserDefaultsController.h"
#import "CLFileManagerCateg.h"
#import "CLURLCateg.h"
#import "PreferenceController.h";

@implementation MyDocument

// ##############################################################
//           INITIALIZERS... & C.... & DEALLOC-ers
// ##############################################################

// .1.
- (id)init
{
    debug_enter("[MyDocument init]");
    if ((self = [super init])) {
        NSMutableArray *urls, *msgs;
        NSString *dir;
        
        debug0msg("initializing....");
        // recall: URLs and Msgs are saved as arrays of CLSingleStringRecords
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        urls = [NSKeyedUnarchiver unarchiveObjectWithData:
            [userDefaults objectForKey:CLUrlPresetsKey]];
        msgs = [NSKeyedUnarchiver unarchiveObjectWithData:
            [userDefaults objectForKey:CLMsgPresetsKey]];
        dir = [userDefaults objectForKey:CLDefaultSoundDirKey];
        willEnd = @"";
        //appController = [NSDocumentController sharedDocumentController];
        
        // init the model
        timerModel = [[CLSimpleTimerModel alloc] initWithMsgs:msgs 
                                                         urls:urls
                                                       sndDir:dir ];
    }
    debug_exit("[MyDocument init]");
    return self;
}

// .2. This should be defined by classes who are owners of a Nib.
// After being brought to life but before any events are handled, all objects 
// are sent awakeFromNib.
- (void)awakeFromNib
{
    debug_enter("[MyDocument awakeFromNib]");
    NSArray *ftypes = [CLSimpleTimerModel allowedSndExtensions];
    NSFileManager *fman = [NSFileManager defaultManager];
    appController = (AppController *)[NSApp delegate];
    NSArray *fnames = [fman listOfFilenamesAt:[appController defaultSoundDir]
                                      withExt:ftypes
                                    removeExt:NO];
    //NSFont *cnt_down_font = [ctrl countdownFont];
    //if (cnt_down_font)
    //    debug0cocoa(@"cnt_down_font=%@", [cnt_down_font description]);
	//[statusInfoField setFont:cnt_down_font];
	
    [sndPresets removeAllItems];
    [sndPresets addItemWithTitle:@"--"];
    [sndPresets addItemsWithTitles:fnames];
	NSMenu *sndMenu = [sndPresets menu];
	[sndMenu addItem: [NSMenuItem separatorItem]];
	[sndPresets addItemWithTitle:
		[[NSBundle mainBundle] localizedStringForKey:@"ChooseSound"
											   value:@"Choose Sound..."
											   table:@"Localizable"]];
    debug_exit("[MyDocument awakeFromNib]");
}

// .3.
/*" 
Here lies code (such as the reading user defaults code) that need to be
executed once the windowController has loaded the document's window. 
"*/
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    NSNotificationCenter *ncenter;
    
    debug_enter("[MyDocument windowControllerDidLoadNib]");
    [super windowControllerDidLoadNib:aController];
    
    // set up radio buttons. NB: can't do this in init! NIB isn't loaded yet 
    [dateRadio setMode:NSRadioModeMatrix];
    [dateRadio setAllowsEmptySelection:NO];
    //[warnmeRadio setMode:NSRadioModeMatrix];
    //[warnmeRadio setAllowsEmptySelection:NO];
    
    // posts notification to tell AppController there's a new timer
    ncenter = [NSNotificationCenter defaultCenter];
    [ncenter postNotificationName:CLSimpleTimerNew object:self];
    
    // when window appears, update the UI in case this is NOT a revert
    [self updateUI];
    
    debug_exit("[MyDocument windowControllerDidLoadNib]");
}


/*" This method invalidates the timer, among other things. "*/
-(void) dealloc
{
    fprintf(stderr, "MyDocument -dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [timerModel release];
    [super dealloc];
    debug_exit("MyDocument -dealloc");
}


// ##############################################################
//                  CLOSING THE DOCUMENT
// ##############################################################


/*" :: 1 ::
Called by NSWindow before windowShouldClose:. This implementation completely 
replaces the call to canCloseDocumentWithDelegate:shouldCloseSelector: done 
by the `super' implementation, which would open a default sheet allowing the 
user to Save an
edited document. This method opens a replacement sheet that takes also into 
consideration the status of the timer, among with the edited status of the 
document. However, if timer is inactive or the "alwaysReturn" user default 
preferences option is currently selected, the default Cocoa save warning sheet
is opened instead.
"*/
- (void)shouldCloseWindowController:(NSWindowController *)windowController
                           delegate:(id)delegate 
                shouldCloseSelector:(SEL)shouldCloseSelector 
                        contextInfo:(void *)contextInfo
{
    // If I open the sheet in windowWillClose: and the document is dirty, 
    // my sheet would be opened AFTER the sheet that asks to save/dismiss 
    // the document.

    debug_enter("MyDocument -shouldCloseWindowController:");
    BOOL alwaysRemove = 
        ([[appController preferenceController] alwaysRemove] == NSOnState);
    BOOL tstart = [timerModel timerStarted];
        

    if (alwaysRemove)
    {
        // no warnings whatsoever
        [appController doc: self
               shouldClose: YES
               contextInfo: (void *)&CLRemoveOnCloseSheetCode];
    }
    /*else if ([appController isQuittingOperation] && tstart)
    {
        [NSApp beginSheet:docQuitSheet
           modalForWindow:myWindow
            modalDelegate:self
    didEndSelector:@selector(timerStillRunSheetDidEnd:returnCode:contextInfo:)
              contextInfo:NULL];      
    }*/
    else if (tstart)
    {
        [NSApp beginSheet:closeSheet
           modalForWindow:myWindow
            modalDelegate:self
    didEndSelector:@selector(timerStillRunSheetDidEnd:returnCode:contextInfo:)
              contextInfo:NULL];
    }
    else {
        [self canCloseDocumentWithDelegate:appController 
                    shouldCloseSelector:@selector(doc:shouldClose:contextInfo:)
                               contextInfo:NULL];
    }
    debug_exit("MyDocument -shouldCloseWindowController:");
}

/*" :: 2 ::
This is the delegate callback method called when the modal session of the 
sheet - opened when a close operation was attempted while the timer was still 
counting - has ended (I.e. user selected a button).
Receives the return code associated with the buttons of the sheet, and an
optional context information, which is always NULL.
"*/
- (void)timerStillRunSheetDidEnd:(NSWindow *)sheet
                      returnCode:(int)code
                     contextInfo:(void *)info
{
    debug_enter("MyDocument -timerStillRunSheetDidEnd:");
    debug0cocoa(@"MyDocument -timerStillRunSheetDidEnd: code= %d", code);
    
    if (code == CLSaveOnCloseSheetCode)
    {
        // Case: "Save" button
        [self saveDocumentWithDelegate:appController
                    didSaveSelector:@selector(docOnClose:didSave:contextInfo:)
                           contextInfo:(void *)&CLSaveOnCloseSheetCode];
    }
    else if (code == CLKeepOnCloseSheetCode)
    {
        // Case: "Keep Timer but Close window": must close doc but keep t.model
        [appController doc: self
               shouldClose: YES
               contextInfo: (void *)&CLKeepOnCloseSheetCode];
    } 
    else if (code == CLRemoveOnCloseSheetCode)
    {
        // Case: "Remove Timer": must close doc and remove timerModel
        [appController doc: self
               shouldClose: YES
               contextInfo: (void *)&CLRemoveOnCloseSheetCode];
    }
    
    debug0msg("MyDocument -timerStillRunSheetDidEnd: doc rtnCnt = %d", 
			[self retainCount]);
    debug_exit("MyDocument -timerStillRunSheetDidEnd:");
}


// ************************************************
//     ACTION METHODS RELATED TO WINDOW CLOSING
// ************************************************

/*" Called when the user clicks on the "Cancel" alert sheet button. "*/
- (IBAction)cancelTimerStillRunningSheet:(id)sender
{
    [closeSheet orderOut:sender];
    [NSApp endSheet:closeSheet returnCode:CLCancelOnCloseSheetCode];
}

/*" Called when the user clicks on the "Save Timer" sheet button. "*/
- (IBAction)saveTimerStillRunningSheet:(id)sender
{
    [closeSheet orderOut:sender];
    [NSApp endSheet:closeSheet returnCode:CLSaveOnCloseSheetCode];
}

/*" Called when the user clicks on the "Remove Timer" button. "*/
- (IBAction)removeTimerStillRunningSheet:(id)sender
{
    [closeSheet orderOut:sender];
    [NSApp endSheet:closeSheet returnCode:CLRemoveOnCloseSheetCode];
}

/*"Called when the user clicks on the "Close Window but Keep Timer" button."*/
- (IBAction)keepTimerStillRunningSheet:(id)sender
{
    [closeSheet orderOut:sender];
    [NSApp endSheet:closeSheet returnCode:CLKeepOnCloseSheetCode];
}

/*" Called when the user clicks on the "Cancel" alert sheet button. "*/
- (IBAction)cancelDocQuitSheet:(id)sender
{
    [docQuitSheet orderOut:sender];
    [NSApp endSheet:docQuitSheet returnCode:CLCancelOnCloseSheetCode];
}

/*" Called when the user clicks on the "Save Timer" sheet button. "*/
- (IBAction)saveDocQuitSheet:(id)sender
{
    [docQuitSheet orderOut:sender];
    [NSApp endSheet:docQuitSheet returnCode:CLSaveOnCloseSheetCode];
}

/*" Called when the user clicks on the "Remove Timer" button. "*/
- (IBAction)removeDocQuitSheet:(id)sender
{
    [docQuitSheet orderOut:sender];
    [NSApp endSheet:docQuitSheet returnCode:CLRemoveOnCloseSheetCode];
}

// #################################################################
//                 NOTIFICATION (DELEGATE) METHODS
// #################################################################

/*" MyDocument is the delegate for all the text fields.
 *  Since the delegate implements this method, it's automatically registered
 *  to receive the NSControlTextDidChangeNotification notification: infact,
 *  if a standard Cocoa object (NSTextField) has a delegate and posts
 *  notifications (through textDidChange:), the delegate is automatically
 *  registered  as an observer for the methods it implements.
 *  i.e. MyDocument is the observer
 *       the NSTextField is the poster  
 * Called for every simgle change on the src TextFields. Even if we just 
modify a letter without changing focus, this method is called.
"*/
- (void)controlTextDidChange:(NSNotification *)notif
{
    debug_enter("controlTextDidChange:");
    [self updateChangeCount:NSChangeDone];
    debug_exit("controlTextDidChange:");
}

/*" Called before controlTextDidEndEditing. "*/
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    debug_enter("control:textShouldEndEditing:");
    debug_exit("control:textShouldEndEditing:");
    return YES;
}


/*" 
Called after control:textShouldEndEditing:, when the editing 
of a TextField ends (move to another GUI element. 
"*/
- (void)controlTextDidEndEditing:(NSNotification *)notif
{
    debug_enter("controlTextDidEndEditing:");
    
    id sender = [notif object];
    NSString *senderVal = [sender stringValue];
    NSString *senderContent = [senderVal stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (sender == fireDateField) 
    {
        if (![senderContent isEqual:[timerModel firingDateString]])
            [self changeFireDate:sender];
    
    }
    else if (sender == hourField)
    {
        if (![senderContent isEqual:[NSString stringWithFormat:@"%d",
                [timerModel cycleHrs]]])
            [self changeCycleHour:sender];
    }   
    else if (sender == minField)
    {
        if (![senderContent isEqual:[NSString stringWithFormat:@"%d",
                [timerModel cycleMins]]])
            [self changeCycleMin:sender];
    }   
    else if (sender == secField)
    {
        if (![senderContent isEqual:[NSString stringWithFormat:@"%d",
                [timerModel cycleSecs]]])
            [self changeCycleSec:sender];
    }   
    else if (sender == actualUrl)
    {
        if (![senderContent isEqual:[timerModel url]])
            [self changeUrl:sender];
    }   
    else if (sender == actualMsg)
    {
        if (![senderVal isEqual:[timerModel msg]])
            [self changeMsg:sender];
    }
    else if (sender == sndTimesField)
    {
        if (![senderContent isEqual:[NSString stringWithFormat:@"%d",
                [timerModel sndTimes]]])
            [self changeSndTimes:sender];
    }
    
    debug_exit("controlTextDidEndEditing:");
}


// ************************************************
// NOTIFICATION METHODS
// ************************************************

/*" 
Replaces the `popUpMenu' on the timer documents with the contents of 
`arrayOfRecords'. In general, `arrayOfRec' can be an array of 
CLTableViewRecords: in SimpleTimer, it is an array of 
CLSingleStringRecords. It can also be an array of NSStrings.
`Title' is the pop up menu title to be used. 
Dependeing which popup menu is passed (`urlPresets'/`msgPresets'),
this method empties the content of `urlList'/`msgList' on the timerModel,
and removes all objects from the `popUpMenu'.
"*/
- (void)replacePopupMenu: (NSPopUpButton*)popUpMenu
        withRecordsArray: (NSMutableArray*)arrayOfRec
                   title: (NSString*)title
{
    debug_enter("replacePopupMenu:withRecordsArray:title:");
    NSString *s;
    int i, n = [arrayOfRec count];;
    //NSMutableArray *timerModelArr;
    NSArray *arrayOfRecCopy;
    SEL addToTimerModel;
    
    // it is possible that arrayofRec == [timerModel ***List]: in that case,
    // if we simply remove all records from the [timerModel ***List] also
    // all the records from `arrayOfRec' will be erased.
    arrayOfRecCopy = [[NSArray alloc] initWithArray:arrayOfRec
                                          copyItems:NO];
    
    // remove all itmes from popup-menu and related timerModel array
    [popUpMenu removeAllItems];
    if (popUpMenu == urlPresets)
    {
        //timerModelArr = [timerModel urlList];
        addToTimerModel = @selector(addUrl:);
        [[timerModel urlList] removeAllObjects];
    }
    else if (popUpMenu == msgPresets)
    {
        //timerModelArr = [timerModel msgList];
        addToTimerModel = @selector(addMsg:);
        [[timerModel msgList] removeAllObjects];
    }
    
    // add an item that will be the title of the pop up menu
    [popUpMenu addItemWithTitle:title];
    
    // `arrayOfRec' is made of CLTableViewRecords:
    // We must extract the title strings from the table view records
    for (i=0; i<n; i++) {
        s = [[arrayOfRecCopy objectAtIndex:i] description];
        [popUpMenu addItemWithTitle:s];
        [timerModel performSelector:addToTimerModel withObject:s];
        //[timerModelArr addObject: s];
    }
    [arrayOfRecCopy release];
    [popUpMenu setNeedsDisplay:YES];
    debug_exit("replacePopupMenu:withRecordsArray:title:");
}

/*" Adds the string `s' at the end of `popUpMenu'. "*/
- (void)updatePopupMenu: (NSPopUpButton*)popUpMenu
             withString: (NSString*)s
{
    debug_enter("updatePopupMenu:withString:");
    [popUpMenu addItemWithTitle: s];
    
    if (popUpMenu == urlPresets)
        [timerModel addUrl: s];
    else if (popUpMenu == msgPresets)
        [timerModel addMsg: s];
    
    [popUpMenu setNeedsDisplay:YES];
    debug_exit("updatePopupMenu:withString:");
}



// #####################################################################
// ##############           ACTION METHODS                ##############
// #####################################################################

/*" Updates the radio group selection for the fire-date option 
    (can be "At date" or "Now".) "*/
- (IBAction) changeFireDateRadio:(id)sender
{
	debug_enter("changeFireDateRadio:");
    int selRow = [dateRadio selectedRow]; // funziona
    [timerModel setAtDateNow: selRow];
    [self enableDateSectionWithModel];
    [self updateChangeCount:NSChangeDone];
    [myWindow makeFirstResponder: sender];
    debug_exit("changeFireDateRadio:");
}

/*" This action is called by the fire-date textfield. "*/
- (IBAction) changeFireDate:(id)sender
{
    NSString *s = [[fireDateField stringValue] stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ( ! [s isEqual:[timerModel firingDateString]])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setFiringDateString: s];
    }
}

/*" This action is called by the "after" hours textfield. "*/
- (IBAction) changeAfterHour:(id)sender
{
    if ([afterHrsField intValue] != [timerModel afterHrs])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setAfterHrs: [afterHrsField intValue]];
    }
}

/*" This action is called by the "after" minutes textfield. "*/
- (IBAction) changeAfterMin:(id)sender
{
    if ([afterMinsField intValue] != [timerModel afterMins])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setAfterMins: [afterMinsField intValue]];
    }
}

/*" This action is called by the "after" seconds textfield. "*/
- (IBAction) changeAfterSec:(id)sender
{
    if ([afterSecsField intValue] != [timerModel afterSecs])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setAfterSecs: [afterSecsField intValue]];
    }
}

/*" The URL Checkbox has been modified. "*/
- (IBAction) changeURLCheck:(id)sender
{
    debug_enter("changeURLCheck:");
    int state = [sender state];
    [timerModel setUrlFlag: state];
    [openUrlCheckbox setState:state];
    [self enableUrlSectionWithModel];
    [myWindow makeFirstResponder: sender];
    [self updateChangeCount:NSChangeDone];
    debug_exit("changeURLCheck:");
}

/*" Updates the actualUrl textField with the content of the drop-down 
    menu selection "*/
- (IBAction) changeUrlPreset:(id)sender
{
    debug_enter("changeUrlPreset:");
    NSString *s = [[sender selectedItem] title];
    [myWindow makeFirstResponder: sender];
    [self modifyUrlWith:s];
    debug_exit("changeUrlPreset:");
}

/*" This action is called by the URL textfield. "*/
- (IBAction) changeUrl:(id)sender
{
    debug_enter("SimpleTimer: [MyDocument changeUrl]");
    if ( ! [[actualUrl stringValue] isEqual:[timerModel url]])
    {
        [myWindow makeFirstResponder: sender];
        [self modifyUrlWith:[actualUrl stringValue]];
    }
    debug_exit("SimpleTimer: [MyDocument changeUrl]");
}

- (void)modifyUrlWith:(NSString *)s
{
    NSString *adjustedUrl = [NSURL adjustUrlString:s];
    [actualUrl setStringValue:adjustedUrl];
    [timerModel setUrl:adjustedUrl];
    [self updateChangeCount:NSChangeDone];    
}

/*" This action is called by the URL save button. "*/
- (IBAction) saveUrl:(id)sender
{
    debug_enter("SimpleTimer: [MyDocument saveUrl]");
    [myWindow makeFirstResponder: sender];
    NSString *s = [actualUrl stringValue];
    NSString *adjustedUrl = [NSURL adjustUrlString:s];
    [actualUrl setStringValue:adjustedUrl];
    [timerModel setUrl:adjustedUrl];
    [self updatePopupMenu:urlPresets 
               withString:adjustedUrl];
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    int saveBtnScope = [defs integerForKey:CLSaveButtonScopeKey];

    // save the new URL in the defaults
    if (saveBtnScope == CL_SIMPLETIMER_PREFS_APPL_SAVES)
    {
        NSMutableDictionary *dict;
        // must send a notification to the Pref. Contr. to update the defaults
        NSNotificationCenter *ncenter = [NSNotificationCenter defaultCenter];
        dict = [NSMutableDictionary dictionaryWithObject:CLUrlPresetsKey
                                                  forKey:CLTableViewKey];
        [dict setObject:adjustedUrl
                 forKey:CLDefaultsEntryKey];
        
        // post a notification to the tableView controller
        [ncenter postNotificationName:CLAddDefaultTvEntry
                               object:nil
                             userInfo:dict];
    }
    [self updateChangeCount:NSChangeDone];
    debug_exit("SimpleTimer: [MyDocument saveUrl]");
}

/*" Updates the "Play Sound" checkbox status. "*/
- (IBAction) changePlaySndCheck:(id)sender
{
    debug_enter("changePlaySndCheck:");
    NSString *s;
    int state = [sender state];
    [timerModel setSndFlag:state];
    [self enableSnd:state];
    s = [timerModel sndName];
    if (([s isEqual:@""] || [s isEqual:@"--"]) && (state == NSOnState))
    {
        [timerModel setSndName:CLDefaultSoundMenuTitle];
        [timerModel setSndDir:[appController defaultSoundDir]];
        [sndPresets selectItemWithTitle:CLDefaultSoundMenuTitle];
    }
    [myWindow makeFirstResponder: sender];
    [self updateChangeCount:NSChangeDone];
    debug_exit("changePlaySndCheck:");
}

/*" NS: this must be invoked only by the popup menu cos it resets the 
sndDir for the timerModel. "*/
- (IBAction) changeSndPreset:(id)sender
{
    int selIndex;
    debug_enter("changeSndPreset:");
    [myWindow makeFirstResponder: sender];
    [timerModel setSndName: [[sndPresets selectedItem] title]];
    selIndex = [sndPresets indexOfSelectedItem];
    if (selIndex == 0)
    {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        NSString *userDefaultDir = [defs objectForKey:CLDefaultSoundDirKey];
        [timerModel setSndDir: userDefaultDir];
    }   
    else if (selIndex == [sndPresets numberOfItems] - 1)
	{
		// must open the "open file" panel
		[self loadSoundOpenPanel:self];
	} 
	else
        [timerModel setSndDir: [appController defaultSoundDir]];
    [self updateChangeCount:NSChangeDone];
    debug_exit("changeSndPreset:");
}

/*" This action is called by the "# of play sound Times" textfield. "*/
- (IBAction) changeSndTimes:(id)sender
{
    if ([sndTimesField intValue] != [timerModel sndTimes])
    {
        [timerModel setSndTimes: [sndTimesField intValue]];
        [self updateChangeCount:NSChangeDone];
    }
}

/* Opens a OpenPanel allowing only the sound extensions identified by 
[CLSimpleTimerModel allowedSndExtensions]. The selected filename and its
directory are saved in the timerModel and the directory is saved in the user
defaults. The sound popup menu is updated with the selected filename.
This method is the only method that updates the sound directory in the 
user defaults. */
- (IBAction)loadSoundOpenPanel:(id)sender
{
    int result;
    debug_enter("loadSoundOpenPanel:");
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSArray *filesToOpen;
    NSString *selFileName;

    // All file types NSSound understands
    NSArray *fileTypes = [CLSimpleTimerModel allowedSndExtensions];
    
    [oPanel setAllowsMultipleSelection:NO];
    // dir = NSHomeDirectory()
    result = [oPanel runModalForDirectory:[timerModel sndDir] 
                                     file:nil
                                    types:fileTypes];
    if (result == NSOKButton) 
    {
        // `filenames' returns the absolute paths of the selected files
        filesToOpen = [oPanel filenames];
        selFileName = [filesToOpen objectAtIndex:0];
        debug0cocoa(@"SimpleTimer: loadSoundOpenPanel returned: %@", selFileName);
        NSArray *arr = [NSFileManager extractFromAbsPath: selFileName
                                               removeExt: NO];
        NSString *sndDir = [arr objectAtIndex:0];
        NSString *snd = [arr objectAtIndex:1];
        [timerModel setSndName: snd];
        [timerModel setSndDir: sndDir];
        
        // save the currently used sndDir in the user defaults
        //[[NSUserDefaults standardUserDefaults] setObject:sndDir 
        //                                          forKey:CLDefaultSoundDirKey];
        
        // update popup menu
        [sndPresets selectItemAtIndex:0];
        [[sndPresets itemAtIndex:0] setTitle: snd];
        
    }
    debug_exit("loadSoundOpenPanel:");
}

/*" The Message Checkbox has been modified. "*/
- (IBAction) changeAlertCheck:(id)sender
{
    debug_enter("changeAlertCheck:");
    int state = [sender state];
    [openAlertCheckbox setState:state];
    [myWindow makeFirstResponder: sender];
    [self updateChangeCount:NSChangeDone];
    [timerModel setMsgFlag: state];
    debug_exit("changeAlertCheck:");
}

/*" Updates the actualMsg textField with the content of the drop-down menu selection "*/
- (IBAction) changeMsgPreset:(id)sender
{
    debug_enter("changeMsgPreset:");
    [myWindow makeFirstResponder: sender];
    [self updateChangeCount:NSChangeDone];
    NSString *s = [[sender selectedItem] title];
    [actualMsg setStringValue: s];
    [timerModel setMsg: s];
    debug_exit("changeMsgPreset:");
}

/*" This action is called by the Message textfield. "*/
- (IBAction) changeMsg:(id)sender
{
    debug_enter("SimpleTimer: [MyDocument changeMsg]");
    if ( ! [[actualMsg stringValue] isEqual:[timerModel msg]])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setMsg: [actualMsg stringValue]];
    }
    debug_exit("SimpleTimer: [MyDocument changeMsg]"); 
}

/*" This action is called by the message save button. "*/
- (IBAction) saveMsg:(id)sender
{
    debug_enter("SimpleTimer: [MyDocument saveMsg]");
    [myWindow makeFirstResponder: sender];
    NSString *s = [actualMsg stringValue];
    [timerModel setMsg:s];
    [self updatePopupMenu:msgPresets 
               withString:s];
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    int saveBtnScope = [defs integerForKey:CLSaveButtonScopeKey];

    // save the new URL in the defaults
    if (saveBtnScope == CL_SIMPLETIMER_PREFS_APPL_SAVES)
    {
        NSMutableDictionary *dict;
        // must send a notification to the Pref. Contr. to update the defaults
        NSNotificationCenter *ncenter = [NSNotificationCenter defaultCenter];
        dict = [NSMutableDictionary dictionaryWithObject:CLMsgPresetsKey
                                                  forKey:CLTableViewKey];
        [dict setObject:s forKey:CLDefaultsEntryKey];
        
        // post a notification to the tableView controller
        [ncenter postNotificationName:CLAddDefaultTvEntry
                               object:nil
                             userInfo:dict];
    }
    [self updateChangeCount:NSChangeDone];
    debug_exit("SimpleTimer: [MyDocument saveMsg]");
}


/*- (IBAction) changeWarnmeCheck:(id)sender
{
    debug_enter("changeWarnmeCheck:");
    int state = [warnmeCheckbox state];
    [timerModel setWarnFlag: state];
    [self enableWarnmeSectionWithModel];
    [myWindow makeFirstResponder: sender];
    [self updateChangeCount:NSChangeDone];
    debug_exit("changeWarnmeCheck:");    
}

- (IBAction) changeWarnme:(id)sender
{
    if ([warnmeField floatValue] != [timerModel warnAmount])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setWarnAmount: [warnmeField intValue]];
    }
}

- (IBAction) changeWarnmeRadio:(id)sender
{
    debug_enter("changeWarnmeRadio:");
    [timerModel setWarnUOM: [warnmeRadio selectedColumn]];
    [myWindow makeFirstResponder: sender];
    [self updateChangeCount:NSChangeDone];
    debug_exit("changeWarnmeRadio:");
}*/

/*" This action is called by the Autostart checkbox. "*/
- (IBAction) changeAutostartCheck:(id)sender
{
    [self updateChangeCount:NSChangeDone];
    [timerModel setAutoFlag: [sender state]];
}

- (IBAction) changeRepeatCheck:(id)sender
{
    debug_enter("changeRepeatCheck:");
    [myWindow makeFirstResponder: sender];
    [timerModel setRepeatFlag:[repeatCheckbox state]];
    [self enableRepeatSectionWithModel];
    [self updateChangeCount:NSChangeDone];
    debug_exit("changeRepeatCheck:");
}

/*" This action is called by the repeat cycle times textfield. "*/
- (IBAction) changeCycleTimes:(id)sender;
{
    if ([cycleTimesField intValue] != [timerModel cycleTimes])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setCycleTimes: [cycleTimesField intValue]];
    }
}

/*" This action is called by the cycle hours textfield. "*/
- (IBAction) changeCycleHour:(id)sender
{
    if ([hourField intValue] != [timerModel cycleHrs])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setCycleHrs: [hourField intValue]];
    }
}

/*" This action is called by the cycle minutes textfield. "*/
- (IBAction) changeCycleMin:(id)sender
{
    if ([minField intValue] != [timerModel cycleMins])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setCycleMins: [minField intValue]];
    }
}

/*" This action is called by the cycle seconds textfield. "*/
- (IBAction) changeCycleSec:(id)sender
{
    if ([secField intValue] != [timerModel cycleSecs])
    {
        [self updateChangeCount:NSChangeDone];
        [timerModel setCycleSecs: [secField intValue]];
    }
}

/*" Scoped out feature. "*/
/* - (IBAction) changeLaunchCheck:(id)sender
{
    debug_enter("changeLaunchCheck:");
    [myWindow makeFirstResponder: sender];
    [self updateChangeCount:NSChangeDone];
    [timerModel setAppLaunchFlag: [sender state]];
    debug_exit("changeLaunchCheck:");
}*/


/*" Reads the parameters from the UI fields, instantiates and starts an NSTimer.
 *  A retain message is sent to the newly created NSTimer.
 *  This method also disables the `Start' button and enables the `Invalidate' 
 *  button. 
"*/
- (IBAction) startTimer:(id)sender
{
    debug_enter("startTimer:");

    // it's self only when this method is started because of an autostart 
    // setting, from windowControllerDidLoadNib:.
    if (sender != self)
        [myWindow makeFirstResponder: sender];
    
    [appController startTimer:timerId];
    
    // update UI stuff
    [self updateUIWithTimerStatus];
    debug_exit("MyDocument -startTimer:");
}


/*" 
This method restores the status of the timer GUI after the timer has been
invalidated by method `invalidateTimer:code:' of class AppController. 
"*/
- (IBAction) invalidateTimer:(id)sender
{
    debug_enter("invalidateTimer:");
    if ([timerModel timerStarted]) {
        [appController invalidateTimer:timerId 
                                  code:(CLSimpleTimerUserInvMask | 
                                        CLSimpleTimerMainExpMask | 
                                        CLSimpleTimerWarnExpMask)];
    }
    [self updateUIWithTimerStatus];
    debug_exit("invalidateTimer:");
}


// ************************************************
//              LOAD AND SAVE METHODS
// ************************************************

/*"
 * SAVES the document. This method is called automatically when the "Save" 
 * options are selected from the menus. I could have also chosen to override 
 * -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
"*/
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    NSData *arc;
    debug_enter("dataRepresentationOfType:");
    // changing the focus saves the last changes in the model
    [myWindow makeFirstResponder: myWindow];
    arc = [NSKeyedArchiver archivedDataWithRootObject:timerModel];
    debug0cocoa(@"dataRepresentationOfType: filename=%@", [self fileName]);
    debug_exit("dataRepresentationOfType:");
    return arc;
}

/*" 
Calls super and sets the timer name of the newly saved file in the timerModel.
"*/
- (void)saveToFile:(NSString *)fileName 
     saveOperation:(NSSaveOperationType)saveOperation 
          delegate:(id)delegate 
   didSaveSelector:(SEL)didSaveSelector 
       contextInfo:(void *)contextInfo
{
    [super saveToFile:fileName 
        saveOperation:saveOperation 
             delegate:delegate 
      didSaveSelector:didSaveSelector 
          contextInfo:contextInfo];
    debug0cocoa(@"saveToFile: filename=%@", fileName);
    debug0cocoa(@"saveToFile: doc filename=%@", [self fileName]);
    // update model immediately with the new filename (doc is still open). 
    // NB: the file on disc doesn't have the filename yet, but the filename 
    // will be retrieved and restored at load time by loadDataRepresentation:
    [timerModel setName: [self fileName]];
}

/*" 
LOADS the document from the given `data'.
This method is called automatically when the "Open" options are selected
from the menus.
"*/
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)docType
{   
    // The docType argument is the type name corresponding to the value of the 
    // CFBundleTypeName entry in the document type's Info.plist dictionary.
    // One can also choose to override -loadFileWrapperRepresentation:ofType: 
    // or -readFromFile:ofType: instead. 

    debug_enter("loadDataRepresentation:");
    // full name of the file being read from disk
    NSString *filename = [self fileName];
    CLSimpleTimerModel *tm = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (tm == nil)
        return NO;
    
    // keep `name' attr always in sync w/ the latest doc location on disk.
    [tm setName:filename];
    [self setTimerModel: tm];
    debug0cocoa(@"loadDataRepresentation: doc filename=%@", 
			  [self fileName]);
    debug_exit("loadDataRepresentation:");
    return YES;
}

// ************************************************
//            GETTER AND SETTER METHODS
// ************************************************

- (NSTextField *)fireDateField { return fireDateField;}
- (NSTextField *)actualUrl { return actualUrl;}
- (NSTextField *)actualMsg { return actualMsg;}
- (NSButton *) repeatCheckbox { return repeatCheckbox; }
- (NSButton *) autostartCheckbox { return autostartCheckbox; }
- (NSWindow *)myWindow { return myWindow; }
- (CLSimpleTimerModel *)timerModel {return timerModel;}
- (void)setTimerModel:(CLSimpleTimerModel *)tm 
{
    [tm retain];
    [timerModel release];
    timerModel = tm;
}
//- (AppController *)appController { return appController; }
/*- (void)setAppController:(AppController *)_t_m_p_
{
	[_t_m_p_ retain];
	[appController release];
	appController = _t_m_p_;
}*/
- (int)timerId { return timerId; }
- (void)setTimerId:(int)_t_m_p_ { timerId = _t_m_p_; }
- (NSTextField *)statusInfoField { return statusInfoField; }
- (NSString *)willEnd { return willEnd; }
- (void)setWillEnd:(NSString *)_t_m_p_
{
	[_t_m_p_ retain];
	[willEnd release];
	willEnd = _t_m_p_;
}

// ************************************************
//              OTHER UTILITY METHODS
// ************************************************

/*" 
Updates the timer window UI in relation to the activation status 
(started / not started) of the timer. This method only operates on the UI
widgets whose status is dependent on the timer activation status.
"*/
- (void)updateUIWithTimerStatus
{
    BOOL isStarted, isNotStarted;
    int buttonState;
    NSColor *col;
    
    isStarted = [timerModel timerStarted];
    if ((isNotStarted = (!isStarted)))
        col = [NSColor controlTextColor];
    else
        col = [NSColor disabledControlTextColor];
    
    // date section
    if (isNotStarted)
    {
        [dateRadio setEnabled:YES];
        [self enableDateSectionWithModel];
    }
    else { 
        [dateRadio setEnabled:NO];
        [fireDateField setEnabled:NO];
        [afterHrsField setEnabled:NO];
        [afterMinsField setEnabled:NO];
        [afterSecsField setEnabled:NO];
    }
    [dateText1 setTextColor:col];
    [dateText2 setTextColor:col];
    [dateText3 setTextColor:col];
    //[dateText4 setTextColor:col];
    
    // update warning section
    /*
    if (isNotStarted)
        [self enableWarnmeSectionWithModel];
    else {
        [warnmeRadio setEnabled:NO];
        [warnmeField setEnabled:NO];
    }
    [warnmeCheckbox setEnabled:isNotStarted];
    [warnText1 setTextColor:col];
    */
    
    // update repeat section
    if (isNotStarted)
        [self enableRepeatSectionWithModel];
    else {
        [cycleTimesField setEnabled:NO];
        [hourField setEnabled:NO];
        [minField setEnabled:NO];
        [secField setEnabled:NO];
    }
    [repeatCheckbox setEnabled:isNotStarted];
    [repeatText1 setTextColor:col];
    [repeatText2 setTextColor:col];
    [repeatText3 setTextColor:col];
    [repeatText4 setTextColor:col];
    buttonState = (isStarted ? NSOffState : [timerModel repeatFlag]);
    
    // update start/stop buttons
    [invalidateButton setEnabled: isStarted];
    [startButton setEnabled: isNotStarted];
    
    // status info
    [statusInfoField setStringValue:[timerModel statusInfo]];
}


/*" update the UI with the values stored in the data model. In this 
implementation this method is called only by windowControllerDidLoadNib:. "*/
- (void) updateUI
{
    int selRow;
    id list;
    NSString *s;
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    // init has already been done, the timer was loaded with the defaults
    debug_enter("updateUI:");

    // set date radio button
    selRow = [timerModel atDateNow];
    [dateRadio selectCellAtRow:selRow column:0];
    [[dateRadio cellAtRow:selRow column:0] setState:NSOnState];
    [[dateRadio cellAtRow:abs(selRow-1) column:0] setState:NSOffState];
    // [dateRadio setState:] has problems: setting NSOffState doesn't work
    // [dateRadio setState:NSOnState atRow:abs(selRow-1) column:0];
    // [dateRadio setState:NSOffState atRow:selRow        column:0];
    
    // set fireDate
    [fireDateField setStringValue:[timerModel firingDateString]];
    
    // set "after" time h/m/s
    [afterHrsField setIntValue:[timerModel afterHrs]];
    [afterMinsField setIntValue:[timerModel afterMins]];
    [afterSecsField setIntValue:[timerModel afterSecs]];
    
    // set status info temp save string (used by updCountdown:)
    [self setWillEnd: [timerModel statusInfo]];
    
    //set URL
    s = [mainBundle localizedStringForKey:@"MyUsualURLs"
                                    value:@"My usual URLs"
                                    table:@"Localizable"];
    list = [timerModel urlList];
    [self replacePopupMenu:urlPresets withRecordsArray:list title:s];
    [actualUrl setStringValue:[timerModel url]];
    [openUrlCheckbox setState:[timerModel urlFlag]];
    [self enableUrlSectionWithModel];
    //set SND
    [sndTimesField setIntValue:[timerModel sndTimes]];
    [self enableSnd:[timerModel sndFlag]];
    // set MSG
    s = [mainBundle localizedStringForKey:@"MyUsualDuties"
                                    value:@"My usual duties"
                                    table:@"Localizable"];
    list = [timerModel msgList];
    [self replacePopupMenu:msgPresets withRecordsArray:list title:s];
    [actualMsg setStringValue:[timerModel msg]];
    [openAlertCheckbox setState:[timerModel msgFlag]];
    
    /*
    // set WARNME
    flag = [timerModel warnFlag];
    [warnmeField setFloatValue:[timerModel warnAmount]];
    selRow = [timerModel warnUOM];
    [warnmeRadio selectCellAtRow:0 column:selRow];
    [[warnmeRadio cellAtRow:0 column:selRow] setState:NSOnState];
    [[warnmeRadio cellAtRow:0 column:abs(selRow-1)] setState:NSOffState];
    [warnmeCheckbox setState:flag];
    */

    // set AUTOSTART
    [autostartCheckbox setState:[timerModel autoFlag]];
    // set Repeat (Cycle)
    [hourField setIntValue:[timerModel cycleHrs]];
    [minField setIntValue:[timerModel cycleMins]];
    [secField setIntValue:[timerModel cycleSecs]];
    [cycleTimesField setIntValue:[timerModel cycleTimes]];
    [repeatCheckbox setState:[timerModel repeatFlag]];
    // set stuff dependent on timerStarted
    [self updateUIWithTimerStatus];
    [myWindow makeFirstResponder: actualMsg];
    debug_exit("updateUI:");
}

- (void)enableDateSectionWithModel
{
    BOOL isAfter = ([timerModel atDateNow] == CL_SIMPLETIMER_START_AFTER);
    [fireDateField setEnabled:(!isAfter)];
    [afterHrsField setEnabled:isAfter];
    [afterMinsField setEnabled:isAfter];
    [afterSecsField setEnabled:isAfter];
}

- (void)enableRepeatSectionWithModel
{
    BOOL flag = ([timerModel repeatFlag] == NSOnState);
    [hourField setEnabled:flag];
    [minField setEnabled:flag];
    [secField setEnabled:flag];
    [cycleTimesField setEnabled:flag];
}

- (void)enableUrlSectionWithModel
{
    BOOL flag = ([timerModel urlFlag] != NSOffState);
    [actualUrl setEnabled:flag];
    [urlPresets setEnabled:flag];
    [saveUrlBtn setEnabled:flag];
}

- (void)enableSnd:(int)state
{
    BOOL flag = (state != NSOffState);
    NSString *sndName = [timerModel sndName];
    [playSndCheckbox setState:state];
    [sndPresets setEnabled:flag];
    [sndPresets selectItemWithTitle: sndName];
    if ([sndPresets indexOfSelectedItem] == -1)
    {
        [sndPresets selectItemAtIndex:0];
        [[sndPresets itemAtIndex:0] setTitle: sndName];
    }
    [sndTimesField setEnabled:flag];
    //[sndBrowseBtn setEnabled:flag];
}

- (NSDate *)fireDate { return [timerModel fireDate]; }

- (void)setStatusInfo:(NSString *)s
{
    [timerModel setStatusInfo: s];
    [statusInfoField setStringValue: s];
}

- (NSString *)windowNibName
{
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (NSString *)description
{
    return [[timerModel name] stringByAppendingString:[super description]];
}

@end

