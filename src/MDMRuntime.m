/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MDMRuntime.h"
#import "MDMRuntime+Private.h"

#import "MDMTracing.h"
#import "private/MDMIsActiveTokenGenerator.h"
#import "private/MDMPerformerGroup.h"

@interface MDMRuntime () <MDMIsActiveTokenGeneratorDelegate>

@property(nonatomic, strong) NSMapTable *targetToPerformerGroup;
@property(nonatomic, strong, readonly) NSMutableSet<id<MDMIsActiveTokenable>> *isActiveTokens;

@end

@implementation MDMRuntime {
  NSMutableOrderedSet *_tracers;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _tracers = [NSMutableOrderedSet orderedSet];
    _targetToPerformerGroup = [NSMapTable weakToStrongObjectsMapTable];
    _isActiveTokens = [NSMutableSet set];
  }
  return self;
}

#pragma mark - Private

- (MDMPerformerGroup *)performerGroupForTarget:(id)target {
  MDMPerformerGroup *performerGroup = [_targetToPerformerGroup objectForKey:target];
  if (!performerGroup) {
    performerGroup = [[MDMPerformerGroup alloc] initWithTarget:target runtime:self];
    [self.targetToPerformerGroup setObject:performerGroup forKey:target];
  }

  return performerGroup;
}

#pragma mark - MDMIsActiveTokenGeneratorDelegate

- (void)registerIsActiveToken:(nonnull id<MDMIsActiveTokenable>)token {
  BOOL wasInactive = self.isActiveTokens.count == 0;

  [self.isActiveTokens addObject:token];

  if (wasInactive) {
    if ([self.delegate respondsToSelector:@selector(runtimeActivityStateDidChange:)]) {
      [self.delegate runtimeActivityStateDidChange:self];
    }
  }
}

- (void)terminateIsActiveToken:(nonnull id<MDMIsActiveTokenable>)token {
  NSAssert([self.isActiveTokens containsObject:token],
           @"Token is not active. May have already been terminated by a previous invocation.");

  [self.isActiveTokens removeObject:token];

  if (self.isActiveTokens.count == 0) {
    if ([self.delegate respondsToSelector:@selector(runtimeActivityStateDidChange:)]) {
      [self.delegate runtimeActivityStateDidChange:self];
    }
  }
}

#pragma mark - Public

- (MDMRuntimeActivityState)activityState {
  return (self.isActiveTokens.count > 0) ? MDMRuntimeActivityStateActive : MDMRuntimeActivityStateIdle;
}

- (void)addPlan:(NSObject<MDMPlan> *)plan to:(id)target {
  id<MDMPlan> copiedPlan = [plan copy];
  [[self performerGroupForTarget:target] addPlan:copiedPlan to:target];
}

- (void)addPlans:(nonnull NSArray<NSObject<MDMPlan> *> *)plans to:(nonnull id)target {
  for (NSObject<MDMPlan> *plan in plans) {
    [self addPlan:plan to:target];
  }
}

- (void)addPlan:(NSObject<MDMNamedPlan> *)plan named:(NSString *)name to:(id)target {
  NSParameterAssert(name.length > 0);
  id<MDMNamedPlan> copiedPlan = [plan copy];
  [[self performerGroupForTarget:target] addPlan:copiedPlan named:name to:target];
}

- (void)removePlanNamed:(NSString *)name from:(id)target {
  NSParameterAssert(name.length > 0);
  [[self performerGroupForTarget:target] removePlanNamed:name from:target];
}

#pragma mark - Private

- (void)addTracer:(nonnull id<MDMTracing>)tracer {
  [_tracers addObject:tracer];
}

- (void)removeTracer:(nonnull id<MDMTracing>)tracer {
  [_tracers removeObject:tracer];
}

- (nonnull NSArray<id<MDMTracing>> *)tracers {
  return _tracers.array;
}

@end
