//
//  AppDelegate.m
//  QuickBoot
//
//  Created by Jeremy Knope on 7/12/07.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import "QBAppDelegate.h"
#import "QBVolumeManager.h"
#import "QBPreferencesController.h"
#import "MainWindowController.h"
#import "BCSystemInfo.h"
#import "BCAboutBox.h"

@implementation QBAppDelegate

- (void)awakeFromNib
{

	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.ShowStatusIcon"
																 options:0
																 context:NULL];
//	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
//															  forKeyPath:@"values.ShowIconInDock"
//																 options:0
//																 context:NULL];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"values.ShowStatusIcon"])
	{
		if(self.statusItem)
		{
			[[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
			self.statusItem = nil;
		}
		else
			[self setupStatusItem];
	}
//	else if([keyPath isEqualToString:@"values.ShowIconInDock"])
//	{
//		[self setDockIcon:[[NSUserDefaults standardUserDefaults] boolForKey:@"ShowIconInDock"]];
//	}
}

- (void)setupStatusItem
{
	if(self.statusItem)
	{
		[[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
		self.statusItem = nil;
	}
	
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:24.0f];
	[self.statusItem setImage:[NSImage imageNamed:@"StatusItemIcon"]];
	[self.statusItem setAlternateImage:[NSImage imageNamed:@"StatusItemIconAlt"]];
	[self.statusItem setHighlightMode:YES];
	[self.statusItem setMenu:self.statusMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
							  //							  [NSNumber numberWithBool:YES], @"SUCheckAtStartup",
							  //							  [NSNumber numberWithInt:86400], @"SUScheduledCheckInterval",
							  [NSNumber numberWithBool:YES], @"ShowIconInDock",
							  [NSNumber numberWithBool:YES], @"ShowStatusIcon",
							  [NSNumber numberWithBool:NO], @"ShowOSXBuildNumber",
							  nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// work around for 10.4, force status item only mode
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowStatusIcon"] || ![[BCSystemInfo sharedSystemInfo] isLeopardOrBetter])
		[self setupStatusItem];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowIconInDock"] && [[BCSystemInfo sharedSystemInfo] isLeopardOrBetter])
		[[self.mainWindowController window] makeKeyAndOrderFront:nil];
		
	self.volumeManager = [[QBVolumeManager alloc] init];
	[self.mainWindowController setVolumeManager:self.volumeManager];
}

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ShowStatusIcon"];
//	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ShowIconInDock"];
}

- (IBAction)showAboutWindow:(id)sender
{
	if(!self.aboutBox) {
		self.aboutBox = [[BCAboutBox alloc] init];
		self.aboutBox.logoImageName = @"QuickBoot-logo";
	}
	[self.aboutBox display:sender];
}

- (IBAction)sendFeedback:(id)sender
{
	NSURL *url = [NSURL URLWithString:@"http://buttered-cat.com/support/contact/quickboot"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)showApplicationWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://buttered-cat.com/products/QuickBoot"]];
}

- (IBAction)showCompanyWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://buttered-cat.com/"]];
}

- (IBAction)showPreferences:(id)sender
{
	if(!self.preferencesController)
		self.preferencesController = [[QBPreferencesController alloc] init];
	
	[NSApp activateIgnoringOtherApps:YES]; // needed when in background mode
	[self.preferencesController showWindow:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowStatusIcon"]);
}

#pragma mark -


@end
