//
//  QBVolumeManager.m
//  QuickBoot
//
//  Created by Jeremy Knope on 5/7/09.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import "QBVolumeManager.h"
//#import "FMNSFileManagerAdditions.h"
#import "BCSystemInfo.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import "QBVolume.h"

#define kQBHelperIdentifier "com.buttered-cat.QuickBootHelper"

@interface QBVolumeManager()
{
	xpc_connection_t helperConnection;
}
@property (nonatomic, strong) BDDisk *efiDisk;
@end


@implementation QBVolumeManager
- (id)init
{
	if((self = [super init]))
	{
		volumes = [NSMutableArray array];
		diskArb = [[BDDiskArbitrationSession alloc] initWithDelegate:self];
		volumeCheckQueue = [[NSOperationQueue alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
			   selector:@selector(refresh:)
				   name:@"QBRefreshVolumes"
				 object:nil];
        NSError *error = nil;
		if(![self installHelperIfNeeded:&error] && error)
			[NSApp presentError:error];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	volumes = nil;
	diskArb = nil;
	volumeCheckQueue = nil;
}

#pragma mark -

- (void)refresh:(NSNotification *)notification
{
	//[self scanVolumes];
}

- (void)setVolumes:(NSArray *)newVolumes
{
	[self willChangeValueForKey:@"volumes"];
	if(newVolumes != volumes)
	{
		volumes = [newVolumes mutableCopy];
	}
	[self didChangeValueForKey:@"volumes"];
}

- (NSArray *)volumes
{
	return volumes;
}

- (BDDisk *)currentBootDisk
{
	// do we use bless or maybe ask nvram
	return nil;
}

#pragma mark -

- (void)detectOperation:(QBOSDetectOperation *)operation finishedScanningVolume:(QBVolume *)aVolume
{	
	if(aVolume.systemName)
	{
		[self willChangeValueForKey:@"volumes"];
		[volumes addObject:aVolume];
		[self didChangeValueForKey:@"volumes"];
	}
}

- (void)diskDidAppear:(BDDisk *)disk
{
	if([[disk volumeName] isEqualToString:@"EFI"]) {
		self.efiDisk = disk;
	}
	else if([disk filesystem] && ![disk isNetwork] && [disk isMountable])
	{
//		NSLog(@"Disk appeared: %@ - %lu", disk, (unsigned long)[disk hash]);
		
		QBOSDetectOperation *op = [QBOSDetectOperation detectOperationWithVolume:[QBVolume volumeWithDisk:disk]];
		op.delegate = self;
		[volumeCheckQueue addOperation:op];
		
		/*NSDictionary *info = [self volumeDictionaryForDisk:disk];
		if(info)
		{
			NSLog(@"System disk, adding");
			[self willChangeValueForKey:@"volumes"];
			//[self setVolumes:[[self volumes] arrayByAddingObject:info]];
			[mVolumes addObject:info];
			[self didChangeValueForKey:@"volumes"];
		}*/
	}
//	else
//		NSLog(@"Ignored disk: %@", disk);
}

- (void)diskDidDisappear:(BDDisk *)disk
{
//	NSLog(@"Disk disappeared: %@ - %lu", disk, (unsigned long)[disk hash]);
	//NSDictionary *info = [note userInfo];
	//[self setVolumes:[[self volumes] arrayByAddingObject:[self volumeDictionaryAtPath:[info objectForKey:@"NSDevicePath"]]]];
	[self willChangeValueForKey:@"volumes"];
	[volumes removeObject:[QBVolume volumeWithDisk:disk]];
	[self didChangeValueForKey:@"volumes"];
}

#pragma mark -

- (void)setBootVolume:(QBVolume *)volume nextOnly:(BOOL)nextOnly withCompletionHandler:(QBVolumeManagerSetBootCompletionBlock)handler
{
	if(!helperConnection)
		helperConnection = xpc_connection_create_mach_service(kQBHelperIdentifier, NULL, 0);
    
    if (!helperConnection) {
		NSLog(@"Failed to create connection to helper");
		//        [self appendLog:@"Failed to create XPC connection."];
        return;
    }
    
    xpc_connection_set_event_handler(helperConnection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        
        if (type == XPC_TYPE_ERROR) {
            
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
				NSLog(@"Connection interrupted");
                
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
				NSLog(@"Connection invalid, discarding");
				helperConnection = nil;
                
            } else {
				NSLog(@"Unexpected XPC connection error");
            }
            
        } else {
			NSLog(@"Unepxected XPC event");
        }
    });
    
    xpc_connection_resume(helperConnection);
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(message, "devicePath", [volume.disk.devicePath UTF8String]);
	xpc_dictionary_set_bool(message, "nextBootOnly", nextOnly);
	xpc_dictionary_set_bool(message, "legacy", volume.legacyOS);
    
    xpc_connection_send_message_with_reply(helperConnection, message, dispatch_get_main_queue(), ^(xpc_object_t event) {
        
        xpc_type_t type = xpc_get_type(event);
        if (type == XPC_TYPE_ERROR) {
            char *desc = xpc_copy_description(event);
            NSLog(@"Error: %s", desc);
            free(desc);
            handler(kQBVolumeManagerUnknownError);
            return;
        }
        QBVolumeManagerError response = xpc_dictionary_get_int64(event, "result");
		handler(response);
    });
}

#pragma mark - SMJobBless

- (BOOL)blessHelperWithLabel:(CFStringRef)label error:(CFErrorRef *)error {
    
	BOOL result = NO;
	
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				|
	kAuthorizationFlagInteractionAllowed	|
	kAuthorizationFlagPreAuthorize			|
	kAuthorizationFlagExtendRights;
	
	AuthorizationRef authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
	if (status != errAuthorizationSuccess) {
		NSLog(@"Failed to authorize helper installations: %d", status);
		//        [self appendLog:[NSString stringWithFormat:@"Failed to create AuthorizationRef. Error code: %ld", status]];
        
	} else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = SMJobBless(kSMDomainSystemLaunchd, label, authRef, error);
	}
	
	return result;
}

- (BOOL)uninstallHelperWithLabel:(CFStringRef)label error:(CFErrorRef *)error
{
	BOOL result = NO;
	
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				|
	kAuthorizationFlagInteractionAllowed	|
	kAuthorizationFlagPreAuthorize			|
	kAuthorizationFlagExtendRights;
	
	AuthorizationRef authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
	if (status != errAuthorizationSuccess) {
		NSLog(@"Failed to authorize helper uninstallations: %d", status);
		//        [self appendLog:[NSString stringWithFormat:@"Failed to create AuthorizationRef. Error code: %ld", status]];
        
	} else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = SMJobRemove(kSMDomainSystemLaunchd, label, authRef, YES, error);
		if(result)
			NSLog(@"Job removed");
	}
	
	return result;
}

- (BOOL)installHelperIfNeeded:(NSError **)outError
{
	BOOL result = YES;
	if([self needsToInstallHelper])
	{
		CFErrorRef error = NULL;
		CFStringRef label = CFSTR(kQBHelperIdentifier);
		NSLog(@"Need to install!");
		if(![self blessHelperWithLabel:label error:&error]) {
			if(error)
			{
				*outError = CFBridgingRelease(error);
			}
            result = NO;
        }
	}
	
    return result;
}

- (BOOL)needsToInstallHelper
{
	NSDictionary*  installedHelperJobData  = CFBridgingRelease(SMJobCopyDictionary( kSMDomainSystemLaunchd, CFSTR(kQBHelperIdentifier) ));
	BOOL            needToInstall          = YES;
	
	if ( installedHelperJobData )
	{
		NSString*      installedPath          = [[installedHelperJobData objectForKey:@"ProgramArguments"] objectAtIndex:0];
		NSURL*          installedPathURL        = [NSURL fileURLWithPath:installedPath];
		
		NSDictionary*  installedInfoPlist      = CFBridgingRelease(CFBundleCopyInfoDictionaryForURL( (__bridge CFURLRef)installedPathURL ));
		NSString*      installedBundleVersion  = [installedInfoPlist objectForKey:@"CFBundleVersion"];
        //		NSInteger      installedVersion        = [installedBundleVersion integerValue];
		
		NSBundle*      appBundle      = [NSBundle mainBundle];
		NSURL*          appBundleURL    = [appBundle bundleURL];
		
		NSURL*          currentHelperToolURL    = [appBundleURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Contents/Library/LaunchServices/%@", CFSTR(kQBHelperIdentifier)]];
		NSDictionary*  currentInfoPlist        = CFBridgingRelease(CFBundleCopyInfoDictionaryForURL( (__bridge CFURLRef)currentHelperToolURL ));
		NSString*      currentBundleVersion    = [currentInfoPlist objectForKey:@"CFBundleVersion"];
        //		NSInteger      currentVersion          = [currentBundleVersion integerValue];
		
		if ( [installedBundleVersion isEqualToString:currentBundleVersion] )
		{
			needToInstall = NO;
		}
	}
	return needToInstall;
}

@end
