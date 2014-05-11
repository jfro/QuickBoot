//
//  QBOSDetectOperation.h
//  QuickBoot
//
//  Created by Jeremy Knope on 8/7/10.
//  Copyright (c) 2010 Ambrosia Software, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QBOSDetectOperation;
@class QBVolume;

@protocol QBOSDetectOperationDelegate <NSObject>
- (void)detectOperation:(QBOSDetectOperation *)operation finishedScanningVolume:(QBVolume *)aVolume;
@end
    

@interface QBOSDetectOperation : NSOperation {
@private
	QBVolume *volume;
	id<QBOSDetectOperationDelegate> __unsafe_unretained delegate;
}

@property (unsafe_unretained) id<QBOSDetectOperationDelegate> delegate;
@property (strong) QBVolume *volume;

+ (QBOSDetectOperation *)detectOperationWithVolume:(QBVolume *)aVolume;
- (id)initWithVolume:(QBVolume *)aVolume;

@end
