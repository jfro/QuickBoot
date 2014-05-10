/*
 *  MainWindowController.h
 *  QuickBoot
 *
 *  Created by Jeremy Knope on 7/12/07.
 *  Copyright 2009 Buttered Cat Software. All rights reserved.
 *
 */
 
#import <Cocoa/Cocoa.h>

@class QBVolumeManager;

@interface MainWindowController : NSWindowController
{
	NSMutableArray *volumes;
	IBOutlet NSArrayController *volumesController;
	IBOutlet NSMenu *statusMenu;
	QBVolumeManager *volumeManager;
	NSButton *bootLaterButton;
	NSButton *bootNowButton;
}
@property (assign) IBOutlet NSButton *bootLaterButton;
@property (assign) IBOutlet NSButton *bootNowButton;

- (QBVolumeManager *)volumeManager;
- (void)setVolumeManager:(QBVolumeManager *)volManager;

- (void)refreshStatusMenu;

- (IBAction)bootSelectedDriveNow:(id)sender;
- (IBAction)bootSelectedDriveLater:(id)sender;

- (IBAction)restart:(id)sender;
- (IBAction)shutdown:(id)sender;
@end
