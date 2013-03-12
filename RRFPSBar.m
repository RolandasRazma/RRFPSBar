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


typedef struct _rrVertex4F {
	GLfloat x1;
	GLfloat y1;
	GLfloat x2;
	GLfloat y2;
} rrVertex4F;


@implementation RRFPSBar {
    CADisplayLink          *_displayLink;
    CFTimeInterval          _displayLinkTickTimeLast;

    rrVertex4F              _historyVertices[640];
    
    GLKView                 *_view;
    EAGLContext             *_glContext;
    GLKBaseEffect           *_effect;
    
    dispatch_semaphore_t    _renderingSemaphore;
    dispatch_queue_t        _renderingQueue;
}


#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_displayLink setPaused:YES];
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    dispatch_release(_renderingQueue);
}


- (id)init {
    if( (self = [super initWithFrame:[[UIApplication sharedApplication] statusBarFrame]]) ){
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];

        // EAGLContext
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

        // GLKView
        _view = [[GLKView alloc] initWithFrame:self.bounds context:_glContext];
        [_view setDrawableColorFormat: GLKViewDrawableColorFormatRGB565];
        [_view setDrawableDepthFormat: GLKViewDrawableDepthFormat16];
        [self addSubview:_view];
        
        // GLKBaseEffect
        _effect = [[GLKBaseEffect alloc] init];
        [_effect setUseConstantColor: GL_TRUE];
        [_effect setConstantColor: GLKVector4Make( 1.0f, 0.0f, 0.0f, 1.0f)];
        [_effect.transform setProjectionMatrix: GLKMatrix4MakeOrtho(0.0f, _view.frame.size.width, 0.0f, 60.0f, 1.0f, -1.0f)];

        // Display link
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick)];
        [_displayLink setPaused:YES];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        // Initial values
        _historyVertices[0]         = (rrVertex4F){0, 0, 0, 60};
        _displayLinkTickTimeLast    = _displayLink.timestamp;
        _renderingSemaphore         = dispatch_semaphore_create(1);
        _renderingQueue             = dispatch_queue_create("RRFPSBarRenderingQueue", DISPATCH_QUEUE_SERIAL);

        [self setWindowLevel: UIWindowLevelStatusBar +1.0f];
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

    // Move old records
    for ( int i = 639; i >= 1; i-=1 ) {
        // Move vector >>
        _historyVertices[i] = _historyVertices[i -1];
        
        // Move x >>
        _historyVertices[i].x1++;
        _historyVertices[i].x2++;
    }
    
    // Store new state
    _historyVertices[0] = (rrVertex4F){
        _historyVertices[1].x2,
        _historyVertices[1].y2,
        _historyVertices[1].x2 -1,
        MIN(60.0f, 1.0f /(_displayLink.timestamp -_displayLinkTickTimeLast))
    };

    _displayLinkTickTimeLast = _displayLink.timestamp;

    
    // Wait for awailable renderer
    if ( dispatch_semaphore_wait(_renderingSemaphore, DISPATCH_TIME_NOW) != 0 ) return;

    // Render
    dispatch_async(_renderingQueue, ^{
        EAGLContext *oldContext = [EAGLContext currentContext];
        
        [EAGLContext setCurrentContext:_glContext];
        
        // Render here
        glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        // Prepare the effect for rendering
        [_effect prepareToDraw];
        
        // Draw
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, _historyVertices);
        glDrawArrays(GL_LINES, 0, 640);

        // Update view
        [_view display];
        
        // Signal a semaphore
        dispatch_semaphore_signal(_renderingSemaphore);
        
        // Restore context
        [EAGLContext setCurrentContext:oldContext];
    });

}


@end