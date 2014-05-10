//
//  BCDiskArbitration.h
//  QuickBoot
//
//  Created by Jeremy Knope on 10/17/09.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiskArbitration/DiskArbitration.h>
#import "BCDisk.h"

@protocol BCDiskArbitrationDelegate

@optional
- (void)diskDidAppear:(BCDisk *)disk;
- (void)diskDidDisappear:(BCDisk *)disk;

@end


@interface BCDiskArbitration : NSObject
{
	DASessionRef session;
	NSObject<BCDiskArbitrationDelegate> *delegate;
}

@property (assign) NSObject <BCDiskArbitrationDelegate> *delegate;

- (id)initWithDelegate:(NSObject <BCDiskArbitrationDelegate> *)newDelegate;

/**
 * Returns a disk object for a given device path
 */
- (BCDisk *)diskForBSDName:(NSString *)bsdName;

@end
