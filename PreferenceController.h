//
//  PreferenceController.h
//  Created by ep on $Date: 2005/10/16 21:40:01 $Revision: 1.1.1.1 $
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

#import <Cocoa/Cocoa.h>
//#import "CLTableViewUserDefaultsController.h"
@class CLTableViewUserDefaultsController;
extern const int CL_SIMPLETIMER_PREFS_INDIVIDUAL_SAVES;
extern const int CL_SIMPLETIMER_PREFS_APPL_SAVES;

@interface PreferenceController : NSWindowController {
    IBOutlet CLTableViewUserDefaultsController *urlPresetsController;
    IBOutlet CLTableViewUserDefaultsController *msgPresetsController;
    IBOutlet NSMatrix *saveRadioBtnScope; /*" Radio btn for save btn prefs. "*/
    IBOutlet NSButton *alwaysRemoveBtn;
}

- (IBAction) changeSaveRadioBtnScope: (id) sender;
- (IBAction) changeAlwaysRemove: (id) sender;

// getter and setter methods
- (CLTableViewUserDefaultsController *)urlPresetsController;
- (CLTableViewUserDefaultsController *)msgPresetsController;
- (int)alwaysRemove;

@end
