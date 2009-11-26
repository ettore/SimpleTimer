//
//  PreferenceController.m
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

#import "PreferenceController.h"
#import "CLSimpleTimerGlobals.h"
#import "CLTableViewRecord.h"
#import "CLTableViewUserDefaultsController.h"

const int CL_SIMPLETIMER_PREFS_INDIVIDUAL_SAVES = 0;
const int CL_SIMPLETIMER_PREFS_APPL_SAVES = 1;

/*" PreferenceController manages the Preferences Nib. The table views in the 
Preferences nib are controlled by their individual controllers. "*/
@implementation PreferenceController

-(id) init
{
    NSNotificationCenter *ncenter;
    
    // loads the nib file called "Preferences"
    debug0cocoa(@"SimpleTimer: initializing PreferenceController....");
    if ((self = [super initWithWindowNibName:@"Preferences"]))
	{
        [self setWindowFrameAutosaveName:@"PrefWindow"];
        // NB: i 2 controller ancora non sono istanziati 
        // (li ho istanziati nel nib)
        // register itself because the documents can update the prefs.
        ncenter = [NSNotificationCenter defaultCenter];
        [ncenter addObserver:self
                    selector:@selector(addTableViewEntryToDefaults:)
                        name:CLAddDefaultTvEntry
                      object:nil];
    }
    return self;
}

- (void) dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    [super dealloc];
}


/*" 
This method is called after the Nib ahs been loaded, either by selecting
"Preferences" from the menu bar or programmatically by AppController.
When the Nib is loaded, the preference controller needs to load its table
views with the user defaults data. 
After the awakeFromNib, and whenever the Preferences windows is open, the
PreferenceController will be sent windowDidLoad:. 
(If the Nib was loaded programmatically i.e. without opening the window, 
 windowDidLoad is not sent.)
"*/
-(void) awakeFromNib
{
    NSMutableArray *newUrls;
    NSMutableArray *newMsgs;
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    debug0cocoa(@"PreferencesController -awakeFromNib: Preferences Nib file loaded");
    [urlPresetsController setKey:CLUrlPresetsKey];
    [msgPresetsController setKey:CLMsgPresetsKey];
    
    // init the radio group
    int selRow = [defs integerForKey:CLSaveButtonScopeKey];
    [saveRadioBtnScope setMode:NSRadioModeMatrix];
    [saveRadioBtnScope setAllowsEmptySelection:NO];
    [saveRadioBtnScope selectCellAtRow:selRow column:0];
    [[saveRadioBtnScope cellAtRow:selRow column:0] setState:NSOnState];
    [[saveRadioBtnScope cellAtRow:abs(selRow-1) column:0] setState:NSOffState];
    
    // init the alwaysRemove default checkbox
    [alwaysRemoveBtn setState:[self alwaysRemove]];
    
    // read the user defaults for URLs and messages
    newUrls = [NSKeyedUnarchiver unarchiveObjectWithData:
        [defs objectForKey:CLUrlPresetsKey]];
    newMsgs = [NSKeyedUnarchiver unarchiveObjectWithData:
        [defs objectForKey:CLMsgPresetsKey]];
    
    // now we can load the prefs table views with the defaults
    [urlPresetsController setModel:newUrls];
    [msgPresetsController setModel:newMsgs];
    
    debug0cocoa(@"PreferencesController -awakeFromNib: defaults loaded into preferences controller.");
}


// #####################################################################
// ##############         GETTER / SETTER METHODS         ##############
// #####################################################################

- (CLTableViewUserDefaultsController *)urlPresetsController 
{ return urlPresetsController; }

- (CLTableViewUserDefaultsController *)msgPresetsController 
{ return msgPresetsController; }

- (int)alwaysRemove
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    return [defs integerForKey:CLSimpleTimerAlwaysRemoveKey];
}


// #####################################################################
// ##############           ACTION METHODS                ##############
// #####################################################################

/*" Updates the radio group selection for the save button scope. "*/
- (IBAction) changeSaveRadioBtnScope:(id)sender
{
    debug_enter("PreferenceController -changeSaveRadioBtnScope:");
    NSUserDefaults *udefs = [NSUserDefaults standardUserDefaults];
    //NSNotificationCenter *ncenter = [NSNotificationCenter defaultCenter];
    int selRow = [saveRadioBtnScope selectedRow]; // funziona
    [udefs setInteger:selRow forKey:CLSaveButtonScopeKey];
    // post notification for all the MyDocuments
    //[ncenter postNotificationName:CLSaveBtnScopeChanged object:self];
    debug_exit("PreferenceController -changeSaveRadioBtnScope:");
}

- (IBAction) changeAlwaysRemove: (id) sender
{
    debug_enter("PreferenceController -changeAlwaysRemove:");
    NSUserDefaults *udefs = [NSUserDefaults standardUserDefaults];
    int alwaysRemove = [sender state];
    [udefs setInteger:alwaysRemove forKey:CLSimpleTimerAlwaysRemoveKey];
    debug_exit("PreferenceController -changeAlwaysRemove:");
}


// #####################################################################
// ##############     METHODS CALLED BY NOTIFIERS          #############
// #####################################################################

/*" This method adds an entry to the list of user URLs and MSGs. It
checks the userinfo dict of the notification to see which one (among 
msgPresets and urlPresets) we have to update. Posted by MyDocument.saveMsg 
and MyDocument.saveUrl.
"*/
- (void) addTableViewEntryToDefaults:(NSNotification *)notif
{
    debug_enter("PreferenceController addTableViewEntryToDefaults:");
    NSArray *arr;
    CLSingleStringRecord *r;
    //NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [notif userInfo];
    // get the key to know which default we have to update
    NSString *prefForKey = [dict objectForKey:CLTableViewKey];
    // get the string we have to insert in the URL/msg list
    NSString *entryStr = [dict objectForKey:CLDefaultsEntryKey];
    
    if ([prefForKey isEqual:CLMsgPresetsKey])
    {
        // updates the user defaults if new entry is not there already
        arr = [msgPresetsController modelAsArray];
        r = [[CLSingleStringRecord alloc] initWithString:entryStr];
        if ([arr indexOfObject: r] == NSNotFound)
        {
            [msgPresetsController addRecord:r];
        }
        [r release];
    } 
    else if ([prefForKey isEqual:CLUrlPresetsKey])
    {
        // updates the user defaults if new entry is not there already
        arr = [urlPresetsController modelAsArray];
        r = [[CLSingleStringRecord alloc] initWithString:entryStr];
        if ([arr indexOfObject: r] == NSNotFound)
        {
            [urlPresetsController addRecord:r];
        }
        [r release];
    }
    debug_exit("PreferenceController addTableViewEntryToDefaults:");
}


@end

