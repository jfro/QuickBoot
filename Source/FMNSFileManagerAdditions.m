//
//  FMNSFileManagerAdditions.m
//  fmkit
//
//  Created by August Mueller on 4/5/06.
//  Copyright 2006 Flying Meat Inc.. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <sys/param.h>
#include <sys/ucred.h>
#include <sys/mount.h>

#import "FMNSFileManagerAdditions.h"


@implementation NSFileManager (FMNSFileManagerAdditions)

+ (NSString*) fileSystemTypeForPath:(NSString*)path {
    
    struct statfs* mnts;
    int i, mnt_count;
    
    mnt_count = getmntinfo(&mnts, MNT_WAIT);
    
    if (mnt_count <= 0) {
        fprintf(stderr, "Could not get mount info\n");
        return nil;
    }
    
    NSString *ret = nil;
    
    for (i = 0; i < mnt_count; i++) {
        NSString *localPath = [NSString stringWithUTF8String:mnts[i].f_mntonname];
        NSString *type      = [NSString stringWithUTF8String:mnts[i].f_fstypename];
        
        if ([path hasPrefix:localPath]) {
            ret = type;
            // don't break!  remember, / is always going to match.
        }
    }
    
    return ret;
}

+ (NSString*) fromMountNameForPath:(NSString*)path {
    
    struct statfs* mnts;
    int i, mnt_count;
    
    mnt_count = getmntinfo(&mnts, MNT_WAIT);
    
    if (mnt_count <= 0) {
        fprintf(stderr, "Could not get mount info\n");
        return nil;
    }
    
    NSString *ret = nil;
    
    for (i = 0; i < mnt_count; i++) {
        NSString *localPath = [NSString stringWithUTF8String:mnts[i].f_mntonname];
        NSString *fromPath  = [NSString stringWithUTF8String:mnts[i].f_mntfromname];
        
        if ([path hasPrefix:localPath]) {
            ret = fromPath;
            // don't break!  remember, / is always going to match.
        }
    }
    
    return ret;
}

+ (NSData *)copyIconDataForUrl:(NSURL *)url {
	CFDataRef data = NULL;

	if (url) {
		FSRef ref;
		if (CFURLGetFSRef((CFURLRef)url, &ref)) {
			IconRef icon = NULL;
			SInt16 label_noOneCares;
			OSStatus err = GetIconRefFromFileInfo(&ref,
												  /*inFileNameLength*/ 0U, /*inFileName*/ NULL,
												  kFSCatInfoNone, /*inCatalogInfo*/ NULL,
												  kIconServicesNoBadgeFlag | kIconServicesUpdateIfNeededFlag,
												  &icon,
												  &label_noOneCares);
			if (err != noErr) {
				NSLog(@"in copyIconDataForURL in CFGrowlAdditions: could not get icon for %@: GetIconRefFromFileInfo returned %li\n", url, (long)err);
			} else {
				IconFamilyHandle fam = NULL;
				err = IconRefToIconFamily(icon, kSelectorAllAvailableData, &fam);
				if (err != noErr) {
					NSLog(@"in copyIconDataForURL in CFGrowlAdditions: could not get icon for %@: IconRefToIconFamily returned %li\n", url, (long)err);
				} else {
					HLock((Handle)fam);
					data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*(Handle)fam, GetHandleSize((Handle)fam));
					HUnlock((Handle)fam);
					DisposeHandle((Handle)fam);
				}
				ReleaseIconRef(icon);
			}
		}
	}
	return (NSData *)CFBridgingRelease(data);
}

+ (NSData *)copyIconDataForPath:(NSString *)path {
	NSData *data = NULL;

	//false is probably safest, and is harmless when the object really is a directory.
	CFURLRef URL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, /*isDirectory*/ false);
	if (URL) {
		data = [NSFileManager copyIconDataForUrl:(NSURL *)CFBridgingRelease(URL)];
	}

	return data;
}

@end
