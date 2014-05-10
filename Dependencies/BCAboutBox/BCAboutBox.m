//
//  BCAboutBox.m
//  Parley
//
//  Created by Jeremy Knope on 5/15/11.
//  Copyright 2011 Buttered Cat Software. All rights reserved.
//

#import "BCAboutBox.h"
#import "NSApplication+BCAdditions.h"

@interface BCAboutBox()
- (void)updateWindowSize;
@end

@implementation BCAboutBox

@synthesize applicationName;
@synthesize versionString;
@synthesize copyright;
@synthesize logoImageName;
@synthesize creditsAttributedString;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	if([key isEqualToString:@"logoImage"]) {
		return [NSSet setWithObject:@"logoImageName"];
	}
	return [super keyPathsForValuesAffectingValueForKey:key];
}

- (id)init
{
	if((self = [super initWithWindowNibName:@"BCAboutBox"])) {
//		NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
		
		self.applicationName = [NSApp infoValueForKey:(NSString *)kCFBundleNameKey];
		self.versionString = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @"About box version string"), [NSApp infoValueForKey:@"CFBundleShortVersionString"], [NSApp infoValueForKey:(NSString *)kCFBundleVersionKey]];
		self.copyright = [NSApp infoValueForKey:@"NSHumanReadableCopyright"];
		NSString *creditsFile = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
		if(creditsFile) {
			NSData *data = [NSData dataWithContentsOfFile:creditsFile];
			self.creditsAttributedString = [[[NSAttributedString alloc] initWithRTF:data documentAttributes:nil] autorelease];
		}
	}
	return self;
}

- (void)dealloc
{
	[applicationName release];
	[versionString release];
	[copyright release];
	[logoImageName release];
	[creditsAttributedString release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	[self updateWindowSize];
}

- (NSImage *)logoImage {
	if(self.logoImageName)
		return [NSImage imageNamed:self.logoImageName];
	return nil;
}

- (void)updateWindowSize
{
	NSImage *logoImage = [self logoImage];
	if(logoImage && logoView) {
		NSSize currentSize = [logoView frame].size;
//		NSLog(@"Updating about box to fit logo: %@ from %@", NSStringFromSize([logoImage size]), NSStringFromSize(currentSize));
		CGFloat deltaX = [logoImage size].width - currentSize.width;
		CGFloat deltaY = [logoImage size].height - currentSize.height;
		
		NSRect newFrame = [[self window] frame];
		newFrame.size.width += deltaX;
		newFrame.size.height += deltaY;
		[[self window] setFrame:newFrame display:NO];
	}
}

- (void)setLogoImageName:(NSString *)newName
{
	if(logoImageName != newName) {
		[logoImageName release];
		logoImageName = [newName copy];
		[self updateWindowSize];
	}
}

- (void)display:(id)sender
{
	[[self window] center];
	[[self window] makeKeyAndOrderFront:nil];
}

@end
