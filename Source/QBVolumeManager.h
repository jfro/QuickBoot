//
//  QBVolumeManager.h
//  QuickBoot
//
//  Created by Jeremy Knope on 5/7/09.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BCDiskArbitration.h"
#import "QBOSDetectOperation.h"

typedef enum {
	kQBVolumeManagerSuccess = 0,
	kQBVolumeManagerCanceled,
	kQBVolumeManagerAuthenticationDenied,
	kQBVolumeManagerAuthenticationError,
	kQBVolumeManagerSetBootError,
	kQBVolumeManagerUnknownError
} QBVolumeManagerError;


@interface QBVolumeManager : NSObject<BCDiskArbitrationDelegate, QBOSDetectOperationDelegate>
{
	NSMutableArray *volumes;
	BCDiskArbitration *diskArb;
	
	NSOperationQueue *volumeCheckQueue;
}

- (void)setVolumes:(NSArray *)newVolumes;
- (NSArray *)volumes;

- (BCDisk *)currentBootDisk;

//- (NSDictionary *)volumeDictionaryAtPath:(NSString *)path;
//- (void)scanVolumes;
//- (NSDictionary *)volumeInfoForPath:(NSString *)volumePath;
//- (NSString *)systemInfoForPath:(NSString *)volumePath;
//- (BOOL)legacyForVolumePath:(NSString *)volumePath;
//- (NSDictionary *)volumeDictionaryForDisk:(BCDisk *)disk;

- (QBVolumeManagerError)setBootDisk:(QBVolume *)volume nextOnly:(BOOL)nextOnly;

@end
