//
//  QBOSDetectOperation.m
//  QuickBoot
//
//  Created by Jeremy Knope on 8/7/10.
//  Copyright (c) 2010 Ambrosia Software, Inc. All rights reserved.
//

#import "QBOSDetectOperation.h"
#import "QBVolume.h"

@implementation QBOSDetectOperation
@synthesize delegate, volume;

+ (QBOSDetectOperation *)detectOperationWithVolume:(QBVolume *)aVolume
{
	return [[[[self class] alloc] initWithVolume:aVolume] autorelease];
}

- (id)initWithVolume:(QBVolume *)aVolume
{
	if((self = [super init]))
	{
		self.volume = aVolume;
	}
	return self;
}

- (void)dealloc
{
	[volume release];
	volume = nil;
	[super dealloc];
}

- (void)main
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *osName = nil;
	NSString *osVersion = nil;
	NSString *osBuild = nil;
	BOOL legacy = YES;
	// I read this wasn't best but this is for a non-running system
	NSString *versionPath = [[[[volume.disk.volumePath stringByAppendingPathComponent:@"System"]
							   stringByAppendingPathComponent:@"Library"]
							  stringByAppendingPathComponent:@"CoreServices"]
							 stringByAppendingPathComponent:@"SystemVersion.plist"];
	NSString *serverVersionPath = [[[[volume.disk.volumePath stringByAppendingPathComponent:@"System"]
															   stringByAppendingPathComponent:@"Library"]
															  stringByAppendingPathComponent:@"CoreServices"]
															 stringByAppendingPathComponent:@"ServerVersion.plist"];
	BOOL isDir;
	if([fileManager fileExistsAtPath:[volume.disk.volumePath stringByAppendingPathComponent:@"Windows"] isDirectory:&isDir])
	{
		if(isDir)
		{
			osName = @"Windows";
			legacy = YES;
		}
	}
	else if([fileManager fileExistsAtPath:versionPath])
	{
		NSDictionary *version = [NSDictionary dictionaryWithContentsOfFile:versionPath];
		osName = @"Mac OS X";
		osVersion = [version objectForKey:@"ProductUserVisibleVersion"];
		osBuild = [version objectForKey:@"ProductBuildVersion"];
		legacy = NO;
	}
	else if([fileManager fileExistsAtPath:serverVersionPath])
	{
		NSDictionary *version = [NSDictionary dictionaryWithContentsOfFile:versionPath];
		osName = @"Mac OS X Server %@/%@";
		osVersion = [version objectForKey:@"ProductUserVisibleVersion"];
		osBuild = [version objectForKey:@"ProductBuildVersion"];
		legacy = NO;
	}
	else
	{
		osName = nil;
	}
	
	// update volume object
	self.volume.systemName = osName;
	self.volume.legacyOS = legacy;
	self.volume.systemVersion = osVersion;
	self.volume.systemBuildNumber = osBuild;
	
	[fileManager release];
	[pool release];
	
	
	if([self.delegate respondsToSelector:@selector(detectOperation:finishedScanningVolume:)])
	{
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[(NSObject *)self.delegate methodSignatureForSelector:@selector(detectOperation:finishedScanningVolume:)]];
		[inv setSelector:@selector(detectOperation:finishedScanningVolume:)];
		[inv setArgument:&self atIndex:2];
		[inv setArgument:&volume atIndex:3];
		[inv retainArguments];
		[inv performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self.delegate waitUntilDone:NO];
		//[self.delegate detectOperation:self finishedScanningVolume:self.volume];
	}
}

@end
