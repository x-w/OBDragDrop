//
//  OBDragDropManager.h
//  OBUserInterface
//
//  Created by Zai Chang on 2/23/12.
//  Copyright (c) 2012 Oblong Industries. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBDragDropProtocol.h"
#import "OBLongPressDragDropGestureRecognizer.h"


// OBOvum represents a data object that is being dragged around a UI window, named
// after the g-speak equivalent within the Ovipositor infrastructure.
// It also is responsible for keeping track of the drag view (a visual representation
// of the ovum)
@interface OBOvum : NSObject 
{
@private
  id<OBOvumSource> source;
  id dataObject;
  NSString *tag;
  
  // Current drop action and target
  OBDropAction dropAction;
  UIView *currentDropHandlingView;
  
  UIView *dragView; // View to represent the dragged object
  CGPoint dragViewInitialCenter;
}
@property (nonatomic, assign) id<OBOvumSource> source;
@property (nonatomic, retain) id dataObject;
@property (nonatomic, retain) NSString *tag;
@property (nonatomic, assign) OBDropAction dropAction;

// The drop target that the ovum is currenly over
@property (nonatomic, assign) UIView *currentDropHandlingView;
@property (nonatomic, retain) UIView *dragView;
@property (nonatomic, assign) CGPoint dragViewInitialCenter;

@end



@interface OBDragDropManager : NSObject <UIGestureRecognizerDelegate>
{
}
@property (nonatomic, retain) UIWindow *overlayWindow;

+(OBDragDropManager *) sharedManager;

// This should be called in during the initialization of the app to prepare the
// drag and drop overlay window
-(void) prepareOverlayWindowUsingMainWindow:(UIWindow*)mainWindow;

-(OBLongPressDragDropGestureRecognizer*) createLongPressDragDropGestureRecognizerWithSource:(id<OBOvumSource>)source;

-(void) animateOvumDrop:(OBOvum*)ovum withAnimation:(void (^)()) dropAnimation completion:(void (^)(BOOL completed))completion;

@end

