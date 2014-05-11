//
//  main.m
//  QuickBoot
//
//  Created by Jeremy Knope on 10/17/09.
//  Copyright 2009 Buttered Cat Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <stdlib.h>
#import <stdio.h>
#include <getopt.h>
#include <syslog.h>
#import "QBVolumeManager.h"

//static QBVolumeManagerError _runBless(const char *devicePath, BOOL nextBootOnly, BOOL legacy)
//{
//	QBVolumeManagerError ret = kQBVolumeManagerSuccess;
//
//}

static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    syslog(LOG_NOTICE, "Received event in helper.");
    
	xpc_type_t type = xpc_get_type(event);
    
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
            
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
        
	} else {
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
		
		const char *devicePath = xpc_dictionary_get_string(event, "devicePath");
		BOOL nextBootOnly = xpc_dictionary_get_bool(event, "nextBootOnly");
		BOOL legacy = xpc_dictionary_get_bool(event, "legacy");
		
		syslog(LOG_NOTICE, "Booting: %s legacy: %i", devicePath, legacy);
		if(devicePath)
		{
			
		}
		else
		{
			syslog(LOG_NOTICE, "No device path specified");
			xpc_object_t reply = xpc_dictionary_create_reply(event);
			xpc_dictionary_set_int64(reply, "result", kQBVolumeManagerUnknownError);
			xpc_connection_send_message(remote, reply);
			return;
		}
		//goto proc_exit;
		
		NSMutableArray *blessArguments = [NSMutableArray array];
		[blessArguments addObject:@"--device"];
		[blessArguments addObject:[NSString stringWithUTF8String:devicePath]];
		if(nextBootOnly)
			[blessArguments addObject:@"--nextonly"];
		[blessArguments addObject:@"--setBoot"];
		if(legacy)
			[blessArguments addObject:@"--legacy"];
		
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:@"/usr/sbin/bless"];
		[task setArguments:blessArguments];
		
		[task setTerminationHandler:^(NSTask *task) {
			syslog(LOG_NOTICE, "Bless finished, sending reply");
			xpc_object_t reply = xpc_dictionary_create_reply(event);
			xpc_dictionary_set_int64(reply, "result", ([task terminationStatus] != 0) ? kQBVolumeManagerSetBootError : kQBVolumeManagerSuccess);
			xpc_connection_send_message(remote, reply);
			double delayInSeconds = 2.0;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				syslog(LOG_NOTICE, "Quitting");
				exit(0);
			});
		}];
		
		[task launch];
	}
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring message event handler for helper.");
    
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		__XPC_Peer_Event_Handler(connection, event);
	});
	
	xpc_connection_resume(connection);
}

int main(int argc, char *argv[])
{
	xpc_connection_t service = xpc_connection_create_mach_service("com.buttered-cat.QuickBootHelper",
                                                                  dispatch_get_main_queue(),
                                                                  XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if (!service) {
        syslog(LOG_NOTICE, "Failed to create service.");
        exit(EXIT_FAILURE);
    }
    
    syslog(LOG_NOTICE, "Configuring connection event handler for helper");
    xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
        __XPC_Connection_Handler(connection);
    });
    
    xpc_connection_resume(service);
    
    dispatch_main();
    
    return EXIT_SUCCESS;
}
