//
//  UserDefaultKeys.h
//  The Unarchiver
//
//  Created by C.W. Betts on 11/22/17.
//

#import <Foundation/Foundation.h>

// User defaults keys:

/*
 Keys -> type
 //importants:
 @"deleteExtractedArchive"
 @"openExtractedArchive"
 @"extractionDestinationPath" string

 @"createFolder" integer:
	1 : only …
	2 : always
	3 : never
 @"extractionDestination" integer
 @"changeDateOfFiles"
 */

extern NSString *const UDKDelete;
extern NSString *const UDKOpen;
extern NSString *const UDKDestination;
extern NSString *const UDKDestinationPath;
extern NSString *const UDKCreateFolderMode;
extern NSString *const UDKDetectionThreshold;
extern NSString *const UDKFileNameEncoding;
extern NSString *const UDKModifyFolderDates;
extern NSString *const UDKModifyFileDates;

typedef NS_ENUM(NSInteger, UDKDestinationType) {
	UDKDestinationCurrentFolder = 1,
	//! selected by user at pref panel, may be other
	//! than ~/Desktop
	UDKDestinationDesktop,
	//! Always let user select the path.
	UDKDestinationSelected,
	UDKDestinationUninitialized,
	//! Only used for scripting.
	UDKDestinationCustomPath = 10
};

typedef NS_ENUM(NSInteger, TUCreateEnclosingDirectory) {
	//! Enclose multiple items.
	TUCreateEnclosingDirectoryMutlipleFilesOnly = 1,
	//! Always enclose.
	TUCreateEnclosingDirectoryAlways,
	//! Never enclose.
	TUCreateEnclosingDirectoryNever
};
