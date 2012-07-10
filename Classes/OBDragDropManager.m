//
//  OBDragDropManager.m
//  OBUserInterface
//
//  Created by Zai Chang on 2/23/12.
//  Copyright (c) 2012 Oblong Industries. All rights reserved.
//

#import "OBDragDropManager.h"
#import "UIView+OBDropZone.h"
#import "OBLongPressDragDropGestureRecognizer.h"


@implementation OBOvum

@synthesize source;
@synthesize dataObject;
@synthesize tag;
@synthesize dropAction;
@synthesize currentDropHandlingView;

@synthesize dragView;
@synthesize dragViewInitialCenter;


-(void) dealloc
{
  DLog(@"%@ dealloc", [self class]);
  
  self.dataObject = nil;
  self.tag = nil;
  self.source = nil;
  self.dragView = nil;
  
  [super dealloc];
}

@end



@interface OBDragDropManager (Private)

-(void) handleApplicationOrientationChange:(NSNotification*)notification;
-(void) cleanupOvum:(OBOvum*)ovum;

@end



@implementation OBDragDropManager

@synthesize overlayWindow;


+(OBDragDropManager *) sharedManager
{
  static OBDragDropManager *_sharedManager = nil;
  if (_sharedManager == nil)
  {
    _sharedManager = [[OBDragDropManager alloc] init];
  }
  return _sharedManager;
}


-(id) init
{
  self = [super init];
  if (self)
  {
    __block id __self = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification
                                                      object:[UIApplication sharedApplication]
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification) {
                                                    [__self handleApplicationOrientationChange:notification];
                                                  }];
  }
  return self;
}


-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:[UIApplication sharedApplication]];
  
  [super dealloc];
}


// Utility function from http://stackoverflow.com/questions/6697605/iphone-uiwindow-rotating-depending-on-current-orientation
//
- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation 
{
  switch (orientation) 
  {
    case UIInterfaceOrientationLandscapeLeft:
      return CGAffineTransformMakeRotation(-90.0 * M_PI / 180);
    case UIInterfaceOrientationLandscapeRight:
      return CGAffineTransformMakeRotation(90.0 * M_PI / 180);
    case UIInterfaceOrientationPortraitUpsideDown:
      return CGAffineTransformMakeRotation(M_PI);
    case UIInterfaceOrientationPortrait:
    default:
      return CGAffineTransformIdentity;
  }
}

-(void) handleApplicationOrientationChange:(NSNotification*)notification
{
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  self.overlayWindow.transform = [self transformForOrientation:orientation]; //self.mainWindow.transform;
}


-(void) prepareOverlayWindowUsingMainWindow:(UIWindow*)mainWindow
{
  if (self.overlayWindow)
  {
    [self.overlayWindow removeFromSuperview];
    self.overlayWindow = nil;
  }
    
  self.overlayWindow = [[[UIWindow alloc] initWithFrame:mainWindow.frame] autorelease];
  self.overlayWindow.windowLevel = UIWindowLevelAlert;
  self.overlayWindow.hidden = YES;
}



#pragma mark - DropZoneHandler

-(UIView *) findDropTargetHandler:(UIView*)view
{
  if (view.dropZoneHandler)
    return view;
  
  UIView *superview = [view superview];
  if (superview)
    return [self findDropTargetHandler:superview];
  
  return nil;
}


-(UIView *) findDropZoneHandlerInWindow:(UIWindow*)window atLocation:(CGPoint)locationInWindow
{
  UIView *furthestView = [window hitTest:locationInWindow withEvent:nil];
  if (!furthestView)
  {
    DLog(@"OBDragDropManager findDropZoneHandlerInWindow: Furthest view is nil!");
    return nil;
  }
  
  UIView *handlingView = [self findDropTargetHandler:furthestView];
  return handlingView;
}


#pragma mark - Ovum Handling

-(void) handleOvumMove:(OBOvum*)ovum inWindow:(UIWindow*)window atLocation:(CGPoint)locationInWindow
{
  UIView *handlingView = [self findDropZoneHandlerInWindow:window atLocation:locationInWindow];
  CGPoint locationInView = [window convertPoint:locationInWindow toView:handlingView];
  
  // Handle change in drop target
  if (ovum.currentDropHandlingView != handlingView)
  {
    if (ovum.currentDropHandlingView)
    {
      id<OBDropZone> dropZone = ovum.currentDropHandlingView.dropZoneHandler;
      [dropZone ovumExited:ovum inView:ovum.currentDropHandlingView atLocation:locationInView];
      ovum.dropAction = OBDropActionNone;
    }
    
    ovum.currentDropHandlingView = handlingView;
    
    if (ovum.currentDropHandlingView)
    {
      id<OBDropZone> dropZone = ovum.currentDropHandlingView.dropZoneHandler;
      OBDropAction action = [dropZone ovumEntered:ovum inView:handlingView atLocation:locationInView];
      ovum.dropAction = action;
    }
  }
  else
  {
    id<OBDropZone> dropZone = ovum.currentDropHandlingView.dropZoneHandler;
    if ([dropZone respondsToSelector:@selector(ovumMoved:inView:atLocation:)])
      ovum.dropAction = [dropZone ovumMoved:ovum inView:handlingView atLocation:locationInView];
  }
}


-(void) animateOvumReturningToSource:(OBOvum*)ovum
{
  CGPoint dragViewInitialCenter = ovum.dragViewInitialCenter;
  UIView *dragView = ovum.dragView;
  
  [UIView animateWithDuration:0.25 animations:^{
    dragView.center = dragViewInitialCenter;
    //dragView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    dragView.transform = CGAffineTransformIdentity;
    //dragView.alpha = 0.0;
  } completion:^(BOOL finished) {
    [dragView removeFromSuperview];
    overlayWindow.hidden = YES;
  }];
}


-(void) animateOvumDrop:(OBOvum*)ovum withAnimation:(void (^)()) dropAnimation completion:(void (^)(BOOL completed))completion
{
  if (dropAnimation == nil)
    return;
  
  UIView *dragView = ovum.dragView;
  
  [UIView animateWithDuration:0.25
                   animations:dropAnimation 
                   completion:^(BOOL finished) {
                     if (completion)
                       completion(finished);
                     
                     [dragView removeFromSuperview];
                     overlayWindow.hidden = YES;
                   }];
}


#pragma mark - Gesture Recognizer Handling

-(OBLongPressDragDropGestureRecognizer*) createLongPressDragDropGestureRecognizerWithSource:(id<OBOvumSource>)source
{
  OBLongPressDragDropGestureRecognizer *recognizer = [[[OBLongPressDragDropGestureRecognizer alloc] init] autorelease];
  recognizer.ovumSource = source;
  [recognizer addTarget:self action:@selector(ovumSourceLongPressed:)];
  return recognizer;
}


-(void) ovumSourceLongPressed:(OBLongPressDragDropGestureRecognizer*)recognizer
{
  UIWindow *hostWindow = recognizer.view.window;
  CGPoint locationInHostWindow = [recognizer locationInView:hostWindow];
  CGPoint locationInOverlayWindow = [recognizer locationInView:overlayWindow];
  
  if (recognizer.state == UIGestureRecognizerStateBegan)
  {
    UIView *sourceView = recognizer.view;
    UIView *dragView = nil;
    id<OBOvumSource> ovumSource = recognizer.ovumSource;
    
    recognizer.ovum = [ovumSource createOvumFromView:sourceView];
    recognizer.ovum.source = ovumSource;
    
    if ([ovumSource respondsToSelector:@selector(createDragRepresentationOfSourceView:inWindow:)])
    {
      dragView = [ovumSource createDragRepresentationOfSourceView:recognizer.view inWindow:overlayWindow];
    }
    else
    {
      CGRect frameInOriginalWindow = [sourceView convertRect:sourceView.bounds toView:sourceView.window];
      CGRect frameInOverlayWindow = [overlayWindow convertRect:frameInOriginalWindow fromWindow:sourceView.window];
      dragView = [[[UIView alloc] initWithFrame:frameInOverlayWindow] autorelease];
      dragView.opaque = NO;
      dragView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.33];
    }
    
    overlayWindow.hidden = NO;
    [overlayWindow addSubview:dragView];
    recognizer.ovum.dragView = dragView;
    recognizer.ovum.dragViewInitialCenter = dragView.center;
    
    // Give the ovum source a change to manipulate or animate the drag view
    if ([ovumSource respondsToSelector:@selector(dragViewWillAppear:inWindow:atLocation:)])
      [ovumSource dragViewWillAppear:dragView inWindow:overlayWindow atLocation:locationInOverlayWindow];
    
    if ([ovumSource respondsToSelector:@selector(ovumDragWillBegin:)])
      [ovumSource ovumDragWillBegin:recognizer.ovum];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:recognizer.ovum, OBOvumDictionaryKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:OBDragDropManagerWillBeginDragNotification object:self userInfo:userInfo];
  }
  else if (recognizer.state == UIGestureRecognizerStateChanged)
  {
    OBOvum *ovum = recognizer.ovum;
    UIView *dragView = ovum.dragView;
    dragView.center = locationInOverlayWindow;
    
    [self handleOvumMove:ovum inWindow:hostWindow atLocation:locationInHostWindow];
  }
  else if (recognizer.state == UIGestureRecognizerStateEnded && recognizer.ovum.currentDropHandlingView)
  {
    // Handle the case that the ovum was dropped successfully onto a drop target
    OBOvum *ovum = recognizer.ovum;
    
    // Handle ovum movement since its location can be different than the last
    // UIGestureRecognizerStateChanged event
    [self handleOvumMove:ovum inWindow:hostWindow atLocation:locationInHostWindow];
    
    id<OBDropZone> dropZone = recognizer.ovum.currentDropHandlingView.dropZoneHandler;
    
    if (ovum.dropAction != OBDropActionNone && dropZone)
    {
      // Drop action is possible and drop zone is available
      UIView *handlingView = [self findDropZoneHandlerInWindow:hostWindow atLocation:locationInHostWindow];
      CGPoint locationInView = [hostWindow convertPoint:locationInHostWindow toView:handlingView];
      
      [dropZone ovumDropped:ovum inView:handlingView atLocation:locationInView];
      
      // For use in blocks below
      UIView *dragView = ovum.dragView;
      
      if ([dropZone respondsToSelector:@selector(handleDropAnimationForOvum:withDragView:dragDropManager:)])
      {
        [dropZone handleDropAnimationForOvum:ovum withDragView:dragView dragDropManager:self];
      }
      else
      {
        [self animateOvumDrop:ovum withAnimation:^{
          dragView.transform = CGAffineTransformMakeScale(0.01, 0.01);
          dragView.alpha = 0.0;
        } completion:nil];
      }
      
      // Inform the OBOvumSource that an ovum originating from it has been dropped successfully
      if ([ovum.source respondsToSelector:@selector(ovumWasDropped:withDropAction:)])
        [ovum.source ovumWasDropped:ovum withDropAction:ovum.dropAction];
    }
    else
    {
      // Ovum dropped in an non-active area or was rejected by the view, so time to do some cleanup
      UIView *handlingView = ovum.currentDropHandlingView;
      CGPoint locationInView = [hostWindow convertPoint:locationInHostWindow toView:handlingView];
      [dropZone ovumExited:ovum inView:handlingView atLocation:locationInView];
      
      // Drop is rejected, return the ovum to its source
      [self animateOvumReturningToSource:ovum];
    }
    
    [self cleanupOvum:ovum];
    
    // Reset the ovum recognizer
    recognizer.ovum = nil;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:recognizer.ovum, OBOvumDictionaryKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:OBDragDropManagerDidEndDragNotification object:self userInfo:userInfo];
  }
  else if (recognizer.state == UIGestureRecognizerStateCancelled ||
           recognizer.state == UIGestureRecognizerStateEnded)
  {
    // Handle the case where an ovum isn't dropped on a drop target
    OBOvum *ovum = recognizer.ovum;
    UIView *handlingView = ovum.currentDropHandlingView;
    CGPoint locationInView = [hostWindow convertPoint:locationInHostWindow toView:handlingView];
    
    // Tell current drop target to reset itself
    id<OBDropZone> dropZone = handlingView.dropZoneHandler;
    [dropZone ovumExited:ovum inView:handlingView atLocation:locationInView];
    
    [self animateOvumReturningToSource:ovum];
    
    [self cleanupOvum:ovum];
    
    // Reset the ovum recognizer
    recognizer.ovum = nil;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:recognizer.ovum, OBOvumDictionaryKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:OBDragDropManagerDidEndDragNotification object:self userInfo:userInfo];
  }
}


-(void) cleanupOvum:(OBOvum*)ovum
{
  if (ovum.source)
  {
    if ([ovum.source respondsToSelector:@selector(ovumDragEnded:)])
      [ovum.source ovumDragEnded:ovum];
    ovum.source = nil;
  }
  
  ovum.dragView = nil;
  ovum.currentDropHandlingView = nil;
}

@end
