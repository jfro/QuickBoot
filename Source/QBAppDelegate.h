//
//  AppDelegate.h
//  QuickBoot
//
//  Created by Jeremy Knope on 7/12/07.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QBVolumeManager;
@class QBPreferencesController;
@class MainWindowController;
@class BCAboutBox;

@interface QBAppDelegate : NSObject {
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	
	IBOutlet MainWindowController *mainWindowController;
	QBVolumeManager *volumeManager;
	QBPreferencesController *preferencesController;
	BCAboutBox *aboutBox;
}

- (void)setupStatusItem;

- (IBAction)showAboutWindow:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)showApplicationWebsite:(id)sender;
- (IBAction)showCompanyWebsite:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

@end
