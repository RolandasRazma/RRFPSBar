//
//  RRFPSBar.m
//
//  Created by Rolandas Razma on 07/03/2013.
//  Copyright 2013 Rolandas Razma. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//



#import "RRFPSBar.h"
#import <QuartzCore/QuartzCore.h>


@implementation RRFPSBar {
    CADisplayLink          *_displayLink;
    NSUInteger              _historyDTLength;
    CFTimeInterval          _historyDT[320];
    CFTimeInterval          _displayLinkTickTimeLast;
    CFTimeInterval          _lastUIUpdateTime;
    
    CATextLayer            *_fpsTextLayer;
    CAShapeLayer           *_linesLayer;
    CAShapeLayer           *_chartLayer;
    
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [_displayLink setPaused:YES];
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}


- (id)init {
    if( (self = [super initWithFrame:[[UIApplication sharedApplication] statusBarFrame]]) ){
        _historyDTLength           = 0;
        _displayLinkTickTimeLast    = CACurrentMediaTime();
        
        [self setWindowLevel: UIWindowLevelStatusBar +1.0f];
        [self setBackgroundColor:[UIColor blackColor]];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];

        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick)];
        [_displayLink setPaused:YES];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        if( [self.layer respondsToSelector:@selector(setDrawsAsynchronously:)] ){
            [self.layer setDrawsAsynchronously:YES];
        }
        
        _chartLayer = [CAShapeLayer layer];
        _linesLayer = [CAShapeLayer layer];
        _fpsTextLayer = [CATextLayer layer];
        
        _chartLayer.frame = self.bounds;
        _linesLayer.frame = self.bounds;
        _fpsTextLayer.frame = CGRectMake(0, CGRectGetHeight(self.frame)/2.0, 100, CGRectGetHeight(self.frame)/2.0);
        
        
        //configure the layer containing the lines
        UIBezierPath *path = [UIBezierPath bezierPath];
        //60fps
        [path moveToPoint:CGPointMake(0, 0)];
        [path addLineToPoint:CGPointMake(CGRectGetWidth(self.frame), 0)];
        //30fps
        [path moveToPoint:CGPointMake(0, 10)];
        [path addLineToPoint:CGPointMake(CGRectGetWidth(self.frame), 10)];
        
        [path closePath];
        
        [_linesLayer setPath:path.CGPath];
        [_linesLayer setStrokeColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5].CGColor];
        _linesLayer.contentsScale = [UIScreen mainScreen].scale;
        

        //configure text layer
        _fpsTextLayer.fontSize = 10.0;
        _fpsTextLayer.foregroundColor = [UIColor redColor].CGColor;
        _fpsTextLayer.contentsScale = [UIScreen mainScreen].scale;
        
        //configure the chart layer
        
        [_chartLayer setStrokeColor:[UIColor redColor].CGColor];
        _chartLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.layer addSublayer:_linesLayer];
        [self.layer addSublayer:_fpsTextLayer];
        [self.layer addSublayer:_chartLayer];
        
        
        self.desiredChartUpdateInterval = 1.0/60.0;
    }
    return self;
}


#pragma mark -
#pragma mark RRFPSBar


+ (RRFPSBar *)sharedInstance {
    static RRFPSBar *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[RRFPSBar alloc] init];
    });
    return _sharedInstance;
}


- (void)applicationDidBecomeActiveNotification {
    [_displayLink setPaused:NO];
}


- (void)applicationWillResignActiveNotification {
    [_displayLink setPaused:YES];
}


- (void)displayLinkTick {
    
    // Shift up the buffer
    for ( int i = _historyDTLength; i >= 1; i-- ) {
        _historyDT[i] = _historyDT[i -1];
    }
    
    // Store new state
    _historyDT[0] = 1.0/(arc4random()%60 +1);//_displayLink.timestamp -_displayLinkTickTimeLast;

    // Update length if there is more place
	if ( _historyDTLength < 319 ) _historyDTLength++;
    
    // Store last timestamp
    _displayLinkTickTimeLast = _displayLink.timestamp;
    
    CFTimeInterval _timeSinceLastUpdate = _displayLinkTickTimeLast - _lastUIUpdateTime;
    
    if( _historyDT[0] < 0.1f && _timeSinceLastUpdate >= self.desiredChartUpdateInterval ){
        [self updateChartAndText];
    }
}

- (void)updateChartAndText{
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CFTimeInterval maxDT = CGFLOAT_MIN;
    
    [path moveToPoint:CGPointMake(0, 0)];
    for( NSUInteger i=0; i<=_historyDTLength; i++ ){
        maxDT = MAX(maxDT, _historyDT[i]);

        [path addLineToPoint:CGPointMake(i+1, CGRectGetHeight(_chartLayer.frame) *(float)_historyDT[i])];

    }
    [path closePath];
    _chartLayer.path = path.CGPath;
    
    NSString *text  = [NSString stringWithFormat:@"low: %.f", MAX(0.0f, roundf(60.0f -60.0f *(float)maxDT))];
    _fpsTextLayer.string = text;
    _lastUIUpdateTime =  _displayLinkTickTimeLast;
    


}


@end