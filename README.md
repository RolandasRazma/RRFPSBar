RRFPSBar
=================

### Usage
```objc
// Include only if app is is not optimized (aka debug build)
#ifndef __OPTIMIZE__
  #import "RRFPSBar.h"
#endif

@implementation YourAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Show only if app is is not optimized (aka debug build)
#ifndef __OPTIMIZE__
    [[RRFPSBar sharedInstance] setHidden:NO];
#endif

}

@end
```

I don't have blog so...
============
I hate lagging apps and do my best to keep [FPS](http://en.wikipedia.org/wiki/Frame_rate) high on [@YPlan](http://yplanapp.com). 
Sometimes it's wery hard to say if [lag](http://en.wikipedia.org/wiki/Lag) is visual or real and Instruments IMO is bit ackward. 
I needed better "tool"... At first, I wrote quick FPS counter that showed FPS in `UILabel` but that wasn't werry convenient as it covered part of the app and you couldn't see history, 
so I decided to add graph. But where...? STATUSBAR!!! It's perfect place! I don't use it for nothing and it doesn't cover app - what can be better?

<a target='_blank' title='YPlan with RRFPSBar' href='http://img843.imageshack.us/img843/6739/img1067c.png'><img src='http://img843.imageshack.us/img843/6739/img1067c.png' border='0'/></a><br />