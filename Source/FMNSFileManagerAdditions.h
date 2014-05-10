//
//  FMNSFileManagerAdditions.h
//  fmkit
//
//  Created by August Mueller on 4/5/06.
//  Copyright 2006 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFileManager (FMNSFileManagerAdditions)
+ (NSString*) fileSystemTypeForPath:(NSString*)path;
+ (NSString*) fromMountNameForPath:(NSString*)path;
+ (NSData *)copyIconDataForUrl:(NSURL *)url;
+ (NSData *)copyIconDataForPath:(NSString *)path;
@end
