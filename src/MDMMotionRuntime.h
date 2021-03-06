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

#import <Foundation/Foundation.h>

@protocol MDMMotionRuntimeDelegate;
@protocol MDMPlan;
@protocol MDMNamedPlan;
@protocol MDMTracing;

/**
 An instance of MDMMotionRuntime acts as the mediating agent between plans and performers.

 Plans are objects that conform to the MDMPlan protocol.
 Performers are objects that conform to the MDMPerforming protocol.

 ## Usage

 Many runtime instances may be instantiated throughout the lifetime of an app. Generally-speaking,
 one runtime is created per interaction. An interaction might be a transition, a one-off animation,
 or a complex multi-state interaction.

 Plans can be associated with targets by using addPlan:to:.

 The runtime creates performer instances when plans are added. Performers are expected to fulfill
 the provided plans.

 ## Lifecycle

 When an instance of a runtime is deallocated its performers will also be deallocated.
 */
NS_SWIFT_NAME(MotionRuntime)
@interface MDMMotionRuntime : NSObject

#pragma mark Adding plans

/** Associate a plan with a given target. */
- (void)addPlan:(nonnull NSObject<MDMPlan> *)plan to:(nonnull id)target
    NS_SWIFT_NAME(addPlan(_:to:));

/** Associate plans with a given target. */
- (void)addPlans:(nonnull NSArray<NSObject<MDMPlan> *> *)plans to:(nonnull id)target
    NS_SWIFT_NAME(addPlans(_:to:));

/**
 Associates a named plan with a given target.

 @param plan The plan to add.
 @param name String identifier for the plan.
 @param target The target on which the plan can operate.
 */
- (void)addPlan:(nonnull id<MDMNamedPlan>)plan
          named:(nonnull NSString *)name
             to:(nonnull id)target
    NS_SWIFT_NAME(addPlan(_:named:to:));

/**
 Removes any plan associated with the given name on the given target.

 @param name String identifier for the plan.
 @param target The target on which the plan can operate.
 */
- (void)removePlanNamed:(nonnull NSString *)name
                   from:(nonnull id)target
    NS_SWIFT_NAME(removePlan(named:from:));

#pragma mark Tracing

/**
 Registers a tracer with the runtime.

 The tracer will be strongly held by the runtime.
 */
- (void)addTracer:(nonnull id<MDMTracing>)tracer
    NS_SWIFT_NAME(addTracer(_:));

/**
 Removes a tracer from the runtime.

 Does nothing if the tracer is not currently associated with the runtime.
 */
- (void)removeTracer:(nonnull id<MDMTracing>)tracer
    NS_SWIFT_NAME(removeTracer(_:));

/** Returns the list of registered tracers. */
- (nonnull NSArray<id<MDMTracing>> *)tracers;

#pragma mark State

/**
 Whether or not this runtime is active.

 A runtime is active only if at least performer currently owns a non-terminated token.
 */
@property(nonatomic, assign, readonly, getter=isActive) BOOL active;

#pragma mark Delegated events

/** A runtime delegate can listen to specific state change events. */
@property(nonatomic, weak, nullable) id<MDMMotionRuntimeDelegate> delegate;

@end

/**
 The MDMMotionRuntimeDelegate protocol defines state change events that may be sent from an instance of
 MDMMotionRuntime.
 */
NS_SWIFT_NAME(MotionRuntimeDelegate)
@protocol MDMMotionRuntimeDelegate <NSObject>

/** Informs the receiver that the runtime's current activity state has changed. */
- (void)motionRuntimeActivityStateDidChange:(nonnull MDMMotionRuntime *)runtime;

@end
