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
#import <Carbon/Carbon.h>
#import <BCAppKit/BCSystemInfo.h>
#import <BCAppKit/BCAboutBox.h>

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
		if(statusItem)
		{
			[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
			[statusItem release];
			statusItem = nil;
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
	if(statusItem)
	{
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		[statusItem release];
		statusItem = nil;
	}
	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:24.0f];
	[statusItem retain];
	[statusItem setImage:[NSImage imageNamed:@"StatusItemIcon"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"StatusItemIconAlt"]];
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:statusMenu];
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
		[[mainWindowController window] makeKeyAndOrderFront:nil];
		
	volumeManager = [[QBVolumeManager alloc] init];
	[mainWindowController setVolumeManager:volumeManager];
}

- (void)dealloc
{
	[statusItem release];
	[volumeManager release];
	[preferencesController release];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ShowStatusIcon"];
//	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ShowIconInDock"];
	[super dealloc];
}

- (IBAction)showAboutWindow:(id)sender
{
	if(!aboutBox) {
		aboutBox = [[BCAboutBox alloc] init];
		aboutBox.logoImageName = @"QuickBoot-logo";
	}
	[aboutBox display:sender];
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
	if(!preferencesController)
		preferencesController = [[QBPreferencesController alloc] init];
	
	[NSApp activateIgnoringOtherApps:YES]; // needed when in background mode
	[preferencesController showWindow:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowStatusIcon"]);
}

#pragma mark -


@end
