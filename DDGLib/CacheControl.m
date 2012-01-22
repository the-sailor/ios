//
//  CacheControl.m
//
//  Created by Chris Heimark on 12/12/08.
//  Copyright 2008 © DuckDuckGo, Inc. All rights reserved.
// 
 
#import "CacheControl.h"
#import "NetworkActivityStatus.h" 

@implementation CacheControl

NSString *cacheBasePath = nil;
NSMutableDictionary *caches = nil;

#pragma mark - Cache management

+ (void)initialize
{
	cacheBasePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	caches = [[NSMutableDictionary alloc] initWithCapacity:4];
}

+ (void)addCache:(NSString *)cacheID lifetimeSeconds:(NSInteger)lifetimeSeconds {
    if([caches objectForKey:cacheID] != nil)
        NSLog(@"WARNING: trying to add cache '%@', but it already exists!",cacheID);
    else
        [caches setObject:[NSNumber numberWithInt:lifetimeSeconds] forKey:cacheID];
}

+ (void)initializeCaches
{
	// create the cache directories if they don't already exist
	for(NSString *cacheID in caches)
	{
		NSString *cachePath = [self pathForCache:cacheID];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
			[[NSFileManager defaultManager] createDirectoryAtPath:cachePath 
									  withIntermediateDirectories:YES 
													   attributes:nil 
															error:nil];
	}
}

#pragma mark - Purging caches

+ (void)purgeCache:(NSString *)cacheID flushAll:(BOOL)flushAll
{
	// go through and purge the caches
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSDate *fileModDate;
	NSString *file;
	NSDictionary *fileAttributes;
	
	NSString *cachePath = [self pathForCache:cacheID];
	
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:cachePath];
	NSDate *oldestDate = [NSDate dateWithTimeIntervalSinceNow:-[self lifetimeSecondsForCache:cacheID]];
	
	// look for candidates to delete
	while (file = [dirEnum nextObject])
	{
		fileAttributes = [fileManager attributesOfItemAtPath:[cachePath stringByAppendingPathComponent:file] error:nil];
		
		if ([[fileAttributes fileType] isEqualToString:NSFileTypeDirectory])
			continue;
		
		NSError *error = nil;
		
        fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
        // delete if flushAll or file is stale
        if(flushAll || ([fileModDate compare:oldestDate] == NSOrderedAscending))
            [fileManager removeItemAtPath:cachePath error:&error];
	}
}

+ (void)purgeAllCaches
{
	// purge all the caches except the first one which is always emptied completely
	for(NSString *cacheID in caches) {
        // if lifetimeSeconds == 0, everything will be flushed anyway, so there's no need to set flushAll here
        [CacheControl purgeCache:cacheID flushAll:NO];
    }
}

#pragma mark - Accessing cache properties

+ (NSInteger)lifetimeSecondsForCache:(NSString *)cacheID
{
	return [[caches objectForKey:cacheID] intValue];
}

+ (NSString *)pathForCache:(NSString *)cacheID {
	return [cacheBasePath stringByAppendingPathComponent:cacheID];
}

+ (NSString *)pathForCache:(NSString *)cacheID entry:(NSString*)cacheEntry {
	return [[CacheControl pathForCache:cacheID] stringByAppendingPathComponent:cacheEntry];
}

@end
