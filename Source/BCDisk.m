//
//  BCDisk.m
//  QuickBoot
//
//  Created by Jeremy Knope on 10/17/09.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import "BCDisk.h"
#import "FMNSFileManagerAdditions.h"

@implementation BCDisk

+ (BCDisk *)diskWithRef:(DADiskRef)disk
{
	return [[[BCDisk alloc] initWithDiskRef:disk] autorelease];
}

- (id)initWithDiskRef:(DADiskRef)disk
{
	self = [super init];
	if(self)
	{
		CFRetain(disk);
		diskRef = disk;
	}
	return self;
}

- (void)dealloc
{
	CFRelease(diskRef);
	diskRef = nil;
	[info release];
	info = nil;
	[super dealloc];
}

#pragma mark -

- (NSUInteger)hash
{
	if(![[self diskDescription] objectForKey:@"DAVolumeUUID"])
		return [[self volumeName] hash];
	return [[self volumeUUIDString] hash];
}

- (BOOL)isEqual:(id)anObject
{
	return ([anObject hash] == [self hash]);
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<BCDisk %p uuid=%@ device=%@ name=%@ fs=%@ mountPath=%@>", self, [self volumeUUIDString], [self devicePath], [self volumeName], [self filesystem], [self volumePath]];
}

- (NSDictionary *)diskDescription
{
	if(!info)
	{
		info = (NSDictionary *)DADiskCopyDescription(diskRef);
	}
	return info;
}

- (NSString *)BSDName
{
	return [[self diskDescription] objectForKey:@"DAMediaBSDName"];
}

- (NSString *)devicePath
{
	return [NSString stringWithFormat:@"/dev/%@", [self BSDName]];
}

- (NSString *)volumeName
{
	return [[self diskDescription] objectForKey:@"DAVolumeName"];
}

- (NSURL *)volumeURL
{
	return [[self diskDescription] objectForKey:@"DAVolumePath"];
}

- (NSString *)volumePath
{
	return [[self volumeURL] path];
}

- (NSString *)filesystem
{
	return [[self diskDescription] objectForKey:@"DAVolumeKind"];
}

- (NSString *)volumeUUIDString
{
	CFUUIDRef uuidRef = (CFUUIDRef)[[self diskDescription] objectForKey:@"DAVolumeUUID"];
	if(!uuidRef)
		return nil;
	NSString *string = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
	return [string autorelease];
}

- (NSImage *)icon
{
	if([self isMounted] && [self volumeURL])
	{
		NSData *iconData = [[NSFileManager copyIconDataForUrl:[self volumeURL]] autorelease];
		if(iconData)
		{
			NSImage *image = [[NSImage alloc] initWithData:iconData];
			return [image autorelease];
		}
	}
	return [[[NSImage alloc] initByReferencingFile:@"/System/Library/Extensions/IOStorageFamily.kext/Contents/Resources/Internal.icns"] autorelease];
}

#pragma mark -

- (BOOL)_boolForDescriptionKey:(NSString *)key
{
	if(![[self diskDescription] objectForKey:key])
		return NO;
	return [[[self diskDescription] objectForKey:key] boolValue];
}

- (BOOL)isWholeDisk
{
	return [self _boolForDescriptionKey:@"DAMediaWhole"];
}

- (BOOL)isMountable
{
	return [self _boolForDescriptionKey:@"DAVolumeMountable"];
}

- (BOOL)isNetwork
{
	return [self _boolForDescriptionKey:@"DAVolumeNetwork"];
}

- (BOOL)isMounted
{
	return ([self volumePath] != nil ? YES : NO);
}

- (BOOL)isCurrentSystem
{
	return ([[self volumePath] isEqualToString:@"/"]) ? YES : NO;
}

@end
