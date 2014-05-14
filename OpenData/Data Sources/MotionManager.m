//
//  MotionManager.m
//  OpenData
//
//  Created by Michael Walker on 5/12/14.
//  Copyright (c) 2014 Lazer-Walker. All rights reserved.
//

#import "MotionManager.h"
#import "RawMotionActivity.h"

@import CoreMotion;

@interface MotionManager ()
@property (strong, nonatomic) CMMotionActivityManager *manager;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@end


@implementation MotionManager

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.manager = [CMMotionActivityManager new];
    self.operationQueue = [NSOperationQueue new];

    return self;
}

- (void)startMonitoring {
    if (![CMMotionActivityManager isActivityAvailable]) return;

    [self.manager startActivityUpdatesToQueue:NSOperationQueue.mainQueue withHandler:^(CMMotionActivity *activity) {

        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            RawMotionActivity *rawActivity = [RawMotionActivity MR_createInContext:localContext];
            [rawActivity setupWithMotionActivity:activity];
        }];
    }];
}

- (void)stopMonitoring {
    [self.manager stopActivityUpdates];
}

- (void)fetchUpdatesWhileInactive {
    if (![CMMotionActivityManager isActivityAvailable]) return;
    RawMotionActivity *mostRecent = [RawMotionActivity MR_findFirstOrderedByAttribute:@"timestamp" ascending:NO];
    NSDate *date = mostRecent.timestamp ?: [NSDate distantPast];

    [self.manager queryActivityStartingFromDate:date toDate:NSDate.date toQueue:self.operationQueue withHandler:^(NSArray *activities, NSError *error) {

        if (error) {
            NSLog(@"MOTION ERROR ================> %@", error);
            return;
        }

        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            for (CMMotionActivity *activity in activities) {
                RawMotionActivity *rawActivity = [RawMotionActivity MR_createInContext:localContext];
                [rawActivity setupWithMotionActivity:activity];
            }
        }];
    }];
}
@end
