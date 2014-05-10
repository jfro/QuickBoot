//
//  BCDisk.h
//  QuickBoot
//
//  Created by Jeremy Knope on 10/17/09.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiskArbitration/DiskArbitration.h>

@interface BCDisk : NSObject
{
	NSDictionary *info;
	DADiskRef diskRef;
	NSImage *icon;
}

@property (readonly) NSImage *icon;
@property (readonly) BOOL isCurrentSystem;

+ (BCDisk *)diskWithRef:(DADiskRef)disk;
- (id)initWithDiskRef:(DADiskRef)disk;

- (NSDictionary *)diskDescription;
- (NSString *)BSDName;
- (NSString *)devicePath;
- (NSString *)volumeName;
- (NSURL *)volumeURL;
- (NSString *)volumePath;
- (NSString *)filesystem;
- (NSString *)volumeUUIDString;

/**
 * Returns drive icon if any
 */
- (NSImage *)icon;

/**
 * Returns YES if receiver represents a physical drive 
 */
- (BOOL)isWholeDisk;

/**
 * Returns YES if the disk is mountable
 */
- (BOOL)isMountable;

/**
 * Returns YES if disk is a network volume like AFP/SMB
 */
- (BOOL)isNetwork;

/**
 * Returns YES if disk is mounted, mount path obtained by devicePath
 * @see -devicePath
 */
- (BOOL)isMounted;

@end
