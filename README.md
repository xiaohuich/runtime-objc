# Material Motion Runtime for Apple Devices

[![Build Status](https://travis-ci.org/material-motion/runtime-objc.svg?branch=develop)](https://travis-ci.org/material-motion/runtime-objc)
[![codecov](https://codecov.io/gh/material-motion/runtime-objc/branch/develop/graph/badge.svg)](https://codecov.io/gh/material-motion/runtime-objc)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/MaterialMotionRuntime.svg)](https://cocoapods.org/pods/MaterialMotionRuntime)
[![Platform](https://img.shields.io/cocoapods/p/MaterialMotionRuntime.svg)](http://cocoadocs.org/docsets/MaterialMotionRuntime)
[![Docs](https://img.shields.io/cocoapods/metrics/doc-percent/MaterialMotionRuntime.svg)](http://cocoadocs.org/docsets/MaterialMotionRuntime)

The Material Motion Runtime is a tool for describing motion declaratively.

## Declarative motion: motion as data

This library does not do much on its own. What it does do, however, is enable the expression of
motion as discrete units of data that can be introspected, composed, and sent over a wire.

This library encourages you to describe motion as data, or what we call *plans*. Plans are committed
to a *motion runtime*, or runtime for short. A runtime coordinates the creation of *performers*,
objects responsible for translating plans into concrete execution.

## Installation

### Installation with CocoaPods

> CocoaPods is a dependency manager for Objective-C and Swift libraries. CocoaPods automates the
> process of using third-party libraries in your projects. See
> [the Getting Started guide](https://guides.cocoapods.org/using/getting-started.html) for more
> information. You can install it with the following command:
>
>     gem install cocoapods

Add `MaterialMotionRuntime` to your `Podfile`:

    pod 'MaterialMotionRuntime'

Then run the following command:

    pod install

### Usage

Import the Material Motion Runtime framework:

    @import MaterialMotionRuntime;

You will now have access to all of the APIs.

## Example apps/unit tests

Check out a local copy of the repo to access the Catalog application by running the following
commands:

    git clone https://github.com/material-motion/runtime-objc.git
    cd runtime-objc
    pod install
    open MaterialMotionRuntime.xcworkspace

# Guides

1. [Architecture](#architecture)
1. [How to define a new plan and performer type](#how-to-create-a-new-plan-and-performer-type)
1. [How to commit a plan to a runtime](#how-to-commit-a-plan-to-a-runtime)
1. [How to commit a named plan to a runtime](#how-to-commit-a-named-plan-to-a-runtime)
1. [How to handle multiple plan types in Swift](#how-to-handle-multiple-plan-types-in-swift)
1. [How to configure performers with named plans](#how-to-configure-performers-with-named-plans)
1. [How to use composition to fulfill plans](#how-to-use-composition-to-fulfill-plans)
1. [How to indicate continuous performance](#how-to-indicate-continuous-performance)
1. [How to trace internal runtime events](#how-to-trace-internal-runtime-events)
1. [How to log runtime events to the console](#how-to-log-runtime-events-to-the-console)
1. [How to observe timeline events](#how-to-observe-timeline-events)

## Architecture

The Material Motion Runtime consists of two groups of APIs: a runtime/transaction object and a
constellation of protocols loosely consisting of plan and performing types.

### MotionRuntime

The MotionRuntime object is a coordinating entity whose primary responsibility is to fulfill plans
by creating performers. You can create many runtimes throughout the lifetime of your application. A
good rule of thumb is to have one runtime per interaction or transition.

### Plan + Performing types

The Plan and Performing protocol each define the minimal characteristics required for an object to
be considered either a plan or a performer, respectively, by the runtime.

Plans and performers have a symbiotic relationship. A plan is executed by the performer it defines.
Performer behavior is configured by the provided plan instances.

Learn more about the Material Motion Runtime by reading the
[Starmap](https://material-motion.github.io/material-motion/starmap/specifications/runtime/).

## How to create a new plan and performer type

The following steps provide copy-pastable snippets of code.

### Step 1: Define the plan type

Questions to ask yourself when creating a new plan type:

- What do I want my plan/performer to accomplish?
- Will my performer need many plans to achieve the desired outcome?
- How can I name my plan such that it clearly communicates either a **behavior** or a
  **change in state**?

As general rules:

1. Plans with an *-able* suffix alter the **behavior** of the target, often indefinitely. Examples:
   Draggable, Pinchable, Tossable.
2. Plans that are *verbs* describe some **change in state**, often over a period of time. Examples:
   FadeIn, Tween, SpringTo.

Code snippets:

***In Objective-C:***

```objc
@interface <#Plan#> : NSObject
@end

@implementation <#Plan#>
@end
```

***In Swift:***

```swift
class <#Plan#>: NSObject {
}
```

### Step 2: Define the performer type

Performers are responsible for fulfilling plans. Fulfillment is possible in a variety of ways:

- [Performing](https://material-motion.github.io/material-motion-runtime-objc/Protocols/MDMPerforming.html): [How to configure performers with plans](#how-to-configure-performers-with-plans)
- [NamedPlanPerforming](https://material-motion.github.io/material-motion-runtime-objc/Protocols/MDMNamedPlanPerforming.html): [How to configure performers with named plans](#how-to-configure-performers-with-named-plans)
- [ContinuousPerforming](https://material-motion.github.io/material-motion-runtime-objc/Protocols/MDMContinuousPerforming.html): [How to indicate continuous performance](#how-to-indicate-continuous-performance)
- [ComposablePerforming](https://material-motion.github.io/material-motion-runtime-objc/Protocols/MDMComposablePerforming.html): [How to use composition to fulfill plans](#how-to-use-composition-to-fulfill-plans)

See the associated links for more details on each performing type.

> Note: only one instance of a type of performer **per target** is ever created. This allows you to
> register multiple plans to the same target in order to configure a performer. See
> [How to configure performers with plans](#how-to-configure-performers-with-plans) for more details.

Code snippets:

***In Objective-C:***

```objc
@interface <#Performer#> : NSObject <MDMPerforming>
@end

@implementation <#Performer#> {
  UIView *_target;
}

- (instancetype)initWithTarget:(id)target {
  self = [super init];
  if (self) {
    assert([target isKindOfClass:[UIView class]]);
    _target = target;
  }
  return self;
}

- (void)addPlan:(id<MDMPlan>)plan {
  <#Plan#>* <#casted plan instance#> = plan;

  // Do something with the plan.
}

@end
```

***In Swift:***

```swift
class <#Performer#>: NSObject, Performing {
  let target: UIView
  required init(target: Any) {
    self.target = target as! UIView
    super.init()
  }

  func addPlan(_ plan: Plan) {
    let <#casted plan instance#> = plan as! <#Plan#>

    // Do something with the plan.
  }
}
```

### Step 3: Make the plan type a formal Plan

Conforming to Plan requires:

1. that you define the type of performer your plan requires, and
2. that your plan be copyable.

Code snippets:

***In Objective-C:***

```objc
@interface <#Plan#> : NSObject <MDMPlan>
@end

@implementation <#Plan#>

- (Class)performerClass {
  return [<#Plan#> class];
}

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] init];
}

@end
```

***In Swift:***

```swift
class <#Plan#>: NSObject, Plan {
  func performerClass() -> AnyClass {
    return <#Performer#>.self
  }
  func copy(with zone: NSZone? = nil) -> Any {
    return <#Plan#>()
  }
}
```

## How to commit a plan to a runtime

### Step 1: Create and store a reference to a runtime instance

Code snippets:

***In Objective-C:***

```objc
@interface MyClass ()
@property(nonatomic, strong) MDMMotionRuntime* runtime;
@end

- (instancetype)init... {
  ...
  self.runtime = [MDMMotionRuntime new];
  ...
}
```

***In Swift:***

```swift
class MyClass {
  let runtime = MotionRuntime()
}
```

### Step 2: Associate plans with targets

Code snippets:

***In Objective-C:***

```objc
[runtime addPlan:<#Plan instance#> to:<#View instance#>];
```

***In Swift:***

```swift
runtime.addPlan(<#Plan instance#>, to:<#View instance#>)
```

## How to commit a named plan to a runtime

### Step 1: Create and store a reference to a runtime instance

Code snippets:

***In Objective-C:***

```objc
@interface MyClass ()
@property(nonatomic, strong) MDMMotionRuntime* runtime;
@end

- (instancetype)init... {
  ...
  self.runtime = [MDMMotionRuntime new];
  ...
}
```

***In Swift:***

```swift
class MyClass {
  let runtime = MotionRuntime()
}
```

### Step 2: Associate named plans with targets

Code snippets:

***In Objective-C:***

```objc
[runtime addPlan:<#Plan instance#> named:<#name#> to:<#View instance#>];
```

***In Swift:***

```swift
runtime.addPlan(<#Plan instance#>, named:<#name#>, to:<#View instance#>)
```

## How to handle multiple plan types in Swift

Make use of Swift's typed switch/casing to handle multiple plan types.

```swift
func addPlan(_ plan: Plan) {
  switch plan {
  case let <#plan instance 1#> as <#Plan type 1#>:
    ()

  case let <#plan instance 2#> as <#Plan type 2#>:
    ()

  case is <#Plan type 3#>:
    ()

  default:
    assert(false)
  }
}
```

## How to configure performers with named plans

Code snippets:

***In Objective-C:***

```objc
@interface <#Performer#> (NamedPlanPerforming) <MDMNamedPlanPerforming>
@end

@implementation <#Performer#> (NamedPlanPerforming)

- (void)addPlan:(id<MDMNamedPlan>)plan named:(NSString *)name {
  <#Plan#>* <#casted plan instance#> = plan;

  // Do something with the plan.
}

- (void)removePlanNamed:(NSString *)name {
  // Remove any configuration associated with the given name.
}

@end
```

***In Swift:***

```swift
extension <#Performer#>: NamedPlanPerforming {
  func addPlan(_ plan: NamedPlan, named name: String) {
    let <#casted plan instance#> = plan as! <#Plan#>

    // Do something with the plan.
  }

  func removePlan(named name: String) {
    // Remove any configuration associated with the given name.
  }
}
```

## How to use composition to fulfill plans

A composition performer is able to emit new plans using a plan emitter. This feature enables the
reuse of plans and the creation of higher-order abstractions.

### Step 1: Conform to ComposablePerforming and store the plan emitter

Code snippets:

***In Objective-C:***

```objc
@interface <#Performer#> ()
@property(nonatomic, strong) id<MDMPlanEmitting> planEmitter;
@end

@interface <#Performer#> (Composition) <MDMComposablePerforming>
@end

@implementation <#Performer#> (Composition)

- (void)setPlanEmitter:(id<MDMPlanEmitting>)planEmitter {
  self.planEmitter = planEmitter;
}

@end
```

***In Swift:***

```swift
// Store the emitter in your class' definition.
class <#Performer#>: ... {
  ...
  var emitter: PlanEmitting!
  ...
}

extension <#Performer#>: ComposablePerforming {
  var emitter: PlanEmitting!
  func setPlanEmitter(_ planEmitter: PlanEmitting) {
    emitter = planEmitter
  }
}
```

### Step 2: Emit plans

Performers are only able to emit plans for their associated target.

Code snippets:

***In Objective-C:***

```objc
[self.planEmitter emitPlan:<#(nonnull id<MDMPlan>)#>];
```

***In Swift:***

```swift
emitter.emitPlan<#T##Plan#>)
```

## How to indicate continuous performance

Performers will often perform their actions over a period of time or while an interaction is
active. These types of performers are called continuous performers.

A continuous performer is able to affect the active state of the runtime by generating activity
tokens. The runtime is considered active so long as an activity token is active. Continuous
performers are expected to activate and deactivate tokens when ongoing work starts and finishes,
respectively.

For example, a performer that registers a platform animation might activate a token when the
animation starts. When the animation completes the token would be deactivated.

### Step 1: Conform to ContinuousPerforming and store the token generator

Code snippets:

***In Objective-C:***

```objc
@interface <#Performer#> ()
@property(nonatomic, strong) id<MDMPlanTokenizing> tokenizer;
@end

@interface <#Performer#> (Composition) <MDMComposablePerforming>
@end

@implementation <#Performer#> (Composition)

- (void)givePlanTokenizer:(id<MDMPlanTokenizing>)tokenizer {
  self.tokenizer = tokenizer;
}

@end
```

***In Swift:***

```swift
// Store the emitter in your class' definition.
class <#Performer#>: ... {
  ...
  var tokenizer: PlanTokenizing!
  ...
}

extension <#Performer#>: ContinuousPerforming {
  func givePlanTokenizer(_ tokenizer: PlanTokenizing) {
    self.tokenizer = tokenizer
  }
}
```

### Step 2: Generate a token

If your work completes in a callback then you will likely need to store the token in order to be
able to reference it at a later point.

Code snippets:

***In Objective-C:***

```objc
id<MDMTokenized> token = [self.tokenizer tokenForPlan:<#plan#>];
tokenMap[animation] = token;
```

***In Swift:***

```swift
let token = tokenizer.generate(for: <#plan#>)!
tokenMap[animation] = token
```

### Step 3: Activate the token when work begins

Code snippets:

***In Objective-C:***

```objc
id<MDMIsActiveTokenable> token = tokenMap[animation];
token.active = true;
```

***In Swift:***

```swift
tokenMap[animation].isActive = true
```

### Step 4: Deactivate the token when work has completed

Code snippets:

***In Objective-C:***

```objc
id<MDMTokenized> token = tokenMap[animation];
token.active = false;
```

***In Swift:***

```swift
tokenMap[animation].isActive = false
```

## How to trace internal runtime events

Tracing allows you to observe internal events occurring within a runtime. This information may be
used for the following purposes:

- Debug logging.
- Inspection tooling.

Use for other purposes is unsupported.

### Step 1: Create a tracer class

Code snippets:

***In Objective-C:***

```objc
@interface <#Custom tracer#> : NSObject <MDMTracing>
@end

@implementation <#Custom tracer#>
@end
```

***In Swift:***

```swift
class <#Custom tracer#>: NSObject, Tracing {
}
```

### Step 2: Implement methods

The documentation for the Tracing protocol enumerates the available methods.

Code snippets:

***In Objective-C:***

```objc
@implementation <#Custom tracer#>

- (void)didAddPlan:(id<MDMPlan>)plan to:(id)target {

}

@end
```

***In Swift:***

```swift
class <#Custom tracer#>: NSObject, Tracing {
  func didAddPlan(_ plan: Plan, to target: Any) {

  }
}
```

## How to log runtime events to the console

Code snippets:

***In Objective-C:***

```objc
[runtime addTracer:[MDMConsoleLoggingTracer new]];
```

***In Swift:***

```swift
runtime.addTracer(ConsoleLoggingTracer())
```

## How to observe timeline events

### Step 1: Conform to the TimelineObserving protocol

Code snippets:

***In Objective-C:***

```objc
@interface <#SomeClass#> () <MDMTimelineObserving>
@end

@implementation <#SomeClass#>

- (void)timeline:(MDMTimeline *)timeline didAttachScrubber:(MDMTimelineScrubber *)scrubber {

}

- (void)timeline:(MDMTimeline *)timeline didDetachScrubber:(MDMTimelineScrubber *)scrubber {

}

- (void)timeline:(MDMTimeline *)timeline scrubberDidScrub:(NSTimeInterval)timeOffset {

}

@end
```

***In Swift:***

```swift
extension <#SomeClass#>: TimelineObserving {
  func timeline(_ timeline: Timeline, didAttach scrubber: TimelineScrubber) {
  }

  func timeline(_ timeline: Timeline, didDetach scrubber: TimelineScrubber) {
  }

  func timeline(_ timeline: Timeline, scrubberDidScrub timeOffset: TimeInterval) {
  }
}
```

### Step 2: Add your observer to a timeline

Code snippets:

***In Objective-C:***

```objc
[timeline addTimelineObserver:<#(nonnull id<MDMTimelineObserving>)#>];
```

***In Swift:***

```swift
timeline.addObserver(<#T##observer: TimelineObserving##TimelineObserving#>)
```

## Contributing

We welcome contributions!

Check out our [upcoming milestones](https://github.com/material-motion/runtime-objc/milestones).

Learn more about [our team](https://material-motion.github.io/material-motion/team/),
[our community](https://material-motion.github.io/material-motion/team/community/), and
our [contributor essentials](https://material-motion.github.io/material-motion/team/essentials/).

## License

Licensed under the Apache 2.0 license. See LICENSE for details.

