//
//  QBVolume.h
//  QuickBoot
//
//  Created by Jeremy Knope on 8/4/10.
//  Copyright 2010 Buttered Cat Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BCDisk.h"

@interface QBVolume : NSObject
{
	// cache values (name can be custom)
	NSString *name;
	NSImage *icon;
	NSString *bsdName;
	NSString *volumePath;
	
	BCDisk *disk;
	NSString *systemName;
	NSString *systemVersion;
	NSString *systemBuildNumber;
	BOOL legacyOS;
}

@property (copy) NSString *name;
@property (copy) NSImage *icon;
@property (copy) NSString *bsdName;
@property (copy) NSString *volumePath;

@property (retain) BCDisk *disk;
@property (copy) NSString *systemName;
@property (copy) NSString *systemVersion;
@property (copy) NSString *systemBuildNumber;
@property (assign) BOOL legacyOS;

+ (QBVolume *)volumeWithDisk:(BCDisk *)aDisk;
- (id)initWithDisk:(BCDisk *)newDisk;

@end
