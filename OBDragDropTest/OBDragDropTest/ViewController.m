//
//  ViewController.m
//  OBDragDropTest
//
//  Created by Zai Chang on 2/23/12.
//  Copyright (c) 2012 Oblong Industries. All rights reserved.
//

#import "ViewController.h"
#import "UIView+OBDropZone.h"
#import <QuartzCore/QuartzCore.h>


static NSInteger kItemViewIndexStart = 100;


@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void) layoutScrollView:(UIScrollView*)scrollView withContents:(NSMutableArray*)contents
{
  CGRect bounds = scrollView.bounds;
  __block CGRect contentBounds = bounds;
  
  CGSize margin = CGSizeMake(12.0, 12.0);
  CGFloat itemWidth = bounds.size.width - 2 * margin.width;
  CGFloat itemHeight = itemWidth * 9 / 16.0;
  CGFloat y = margin.height;
  
  for (UIView *view in contents)
  {
    CGRect frame = CGRectMake(margin.width, y, itemWidth, itemHeight);
    view.frame = frame;
    
    y += itemHeight + margin.height;
    
    contentBounds = CGRectUnion(contentBounds, frame);
  }
  
  scrollView.contentSize = contentBounds.size;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
  self.view.backgroundColor = [UIColor blackColor];
  
  
  OBDragDropManager *dragDropManager = [OBDragDropManager sharedManager];
  
  CGRect viewFrame = self.view.frame;
  CGRect frame = CGRectMake(0, 0, viewFrame.size.width/2, viewFrame.size.height);
  frame = CGRectInset(frame, 20.0, 20.0);
  leftView = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
  leftView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
  leftView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
  [self.view addSubview:leftView];
  
  
  frame = CGRectMake(viewFrame.size.width/2, 0, viewFrame.size.width/2, viewFrame.size.height);
  frame = CGRectInset(frame, 20.0, 20.0);
  rightView = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
  rightView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
  rightView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
  [self.view addSubview:rightView];
  
  rightView.dropZoneHandler = self;

  
  leftViewContents = [[NSMutableArray alloc] init];
  rightViewContents = [[NSMutableArray alloc] init];
  
  for (NSInteger i=0; i<10; i++)
  {
    UIView *itemView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    CGFloat (^randFloat)(CGFloat, CGFloat) = ^(CGFloat min, CGFloat max) { return min + (max-min) * (CGFloat)random() / RAND_MAX; };
    itemView.backgroundColor = [UIColor colorWithHue:randFloat(0.0, 1.0) saturation:randFloat(0.5, 1.0) brightness:randFloat(0.3, 1.0) alpha:1.0];
    itemView.tag = kItemViewIndexStart + i;
    [leftViewContents addObject:itemView];
    [leftView addSubview:itemView];
    
    UIGestureRecognizer *recognizer = [dragDropManager createLongPressDragDropGestureRecognizerWithSource:self];
    [itemView addGestureRecognizer:recognizer];
  }
  
  [self layoutScrollView:leftView withContents:leftViewContents];
  [self layoutScrollView:rightView withContents:rightViewContents];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
      return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
      return YES;
  }
}

-(void) viewDidLayoutSubviews
{
  [self layoutScrollView:leftView withContents:leftViewContents];
  [self layoutScrollView:rightView withContents:rightViewContents];
}


-(NSInteger) insertionIndexForLocation:(CGPoint)location withContents:(NSArray*)contents
{
  CGFloat minDistance = CGFLOAT_MAX;
  NSInteger insertionIndex = 0;
  for (UIView *view in contents)
  {
    CGFloat locationToView = location.y - CGRectGetMidY(view.frame);
    if (locationToView > 0 && locationToView < minDistance)
    {
      minDistance = locationToView;
      insertionIndex = [contents indexOfObject:view] + 1;
    }
  }
  return insertionIndex;
}



#pragma mark - OBOvumSource

-(OBOvum *) createOvumFromView:(UIView*)sourceView
{
  OBOvum *ovum = [[[OBOvum alloc] init] autorelease];
  ovum.dataObject = [NSNumber numberWithInteger:sourceView.tag];
  return ovum;
}


-(UIView *) createDragRepresentationOfSourceView:(UIView *)sourceView inWindow:(UIWindow*)window
{
  CGRect frame = [sourceView convertRect:sourceView.bounds toView:sourceView.window];
  frame = [window convertRect:frame fromWindow:sourceView.window];
  
  UIView *dragView = [[[UIView alloc] initWithFrame:frame] autorelease];
  dragView.backgroundColor = sourceView.backgroundColor;
  dragView.layer.cornerRadius = 5.0;
  dragView.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:1.0].CGColor;
  dragView.layer.borderWidth = 1.0;
  dragView.layer.masksToBounds = YES;
  return dragView;
}


-(void) dragViewWillAppear:(UIView *)dragView inWindow:(UIWindow*)window atLocation:(CGPoint)location
{
  dragView.transform = CGAffineTransformIdentity;
  dragView.alpha = 0.0;
  
  [UIView animateWithDuration:0.25 animations:^{
    dragView.center = location;
    dragView.transform = CGAffineTransformMakeScale(0.80, 0.80);
    dragView.alpha = 0.75;
  }];  
}



#pragma mark - OBDropZone

static NSInteger kLabelTag = 2323;

-(OBDropAction) ovumEntered:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
  NSLog(@"Ovum<0x%x> %@ Entered", (int)ovum, ovum.dataObject);
    
  CGFloat red = 0.33 + 0.66 * location.y / self.view.frame.size.height;
  view.layer.borderColor = [UIColor colorWithRed:red green:0.0 blue:0.0 alpha:1.0].CGColor;
  view.layer.borderWidth = 5.0;
  
  CGRect labelFrame = CGRectMake(ovum.dragView.bounds.origin.x, ovum.dragView.bounds.origin.y, ovum.dragView.bounds.size.width, ovum.dragView.bounds.size.height / 2);
  UILabel *label = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
  label.text = @"Ovum entered";
  label.tag = kLabelTag;
  label.backgroundColor = [UIColor clearColor];
  label.opaque = NO;
  label.font = [UIFont boldSystemFontOfSize:24.0];
  label.textAlignment = UITextAlignmentCenter;
  label.textColor = [UIColor whiteColor];
  [ovum.dragView addSubview:label];
  
  return OBDropActionMove;
}

-(OBDropAction) ovumMoved:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
//  NSLog(@"Ovum<0x%x> %@ Moved", (int)ovum, ovum.dataObject);
  
  CGFloat hiphopopotamus = 0.33 + 0.66 * location.y / self.view.frame.size.height;
  
  // This tester currently only supports dragging from left to right view
  if ([ovum.dataObject isKindOfClass:[NSNumber class]])
  {
    UIView *itemView = [self.view viewWithTag:[ovum.dataObject integerValue]];
    if ([rightViewContents containsObject:itemView])
    {
      view.layer.borderColor = [UIColor colorWithRed:hiphopopotamus green:0.0 blue:0.0 alpha:1.0].CGColor;
      view.layer.borderWidth = 5.0;
      
      UILabel *label = (UILabel*) [ovum.dragView viewWithTag:kLabelTag];
      label.text = @"Cannot Drop Here";
       
      return OBDropActionNone;
    }
  }
  
  view.layer.borderColor = [UIColor colorWithRed:0.0 green:hiphopopotamus blue:0.0 alpha:1.0].CGColor;
  view.layer.borderWidth = 5.0;
  
  UILabel *label = (UILabel*) [ovum.dragView viewWithTag:kLabelTag];
  label.text = [NSString stringWithFormat:@"Ovum at %@", NSStringFromCGPoint(location)];
  
  return OBDropActionMove;
}

-(void) ovumExited:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
  NSLog(@"Ovum<0x%x> %@ Exited", (int)ovum, ovum.dataObject);
  
  view.layer.borderColor = [UIColor clearColor].CGColor;
  view.layer.borderWidth = 0.0;
  
  UILabel *label = (UILabel*) [ovum.dragView viewWithTag:kLabelTag];
  [label removeFromSuperview];
}

-(void) ovumDropped:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
  NSLog(@"Ovum<0x%x> %@ Dropped", (int)ovum, ovum.dataObject);
  
  view.layer.borderColor = [UIColor clearColor].CGColor;
  view.layer.borderWidth = 0.0;
      
  UILabel *label = (UILabel*) [ovum.dragView viewWithTag:kLabelTag];
  [label removeFromSuperview];
  
  if ([ovum.dataObject isKindOfClass:[NSNumber class]])
  {
    UIView *itemView = [self.view viewWithTag:[ovum.dataObject integerValue]];
    if (itemView)
    {
      [itemView retain];
      [itemView removeFromSuperview];
      [leftViewContents removeObject:itemView];
      
      NSInteger insertionIndex = [self insertionIndexForLocation:location withContents:rightViewContents];
      [rightView insertSubview:itemView atIndex:insertionIndex];
      [rightViewContents insertObject:itemView atIndex:insertionIndex];
      
      [itemView release];
    }
  }
}


-(void) handleDropAnimationForOvum:(OBOvum*)ovum withDragView:(UIView*)dragView dragDropManager:(OBDragDropManager*)dragDropManager
{
  if ([ovum.dataObject isKindOfClass:[NSNumber class]])
  {
    UIView *itemView = [self.view viewWithTag:[ovum.dataObject integerValue]];
    
    // Set the initial position of the view to match that of the drag view
    CGRect dragViewFrameInTargetWindow = [ovum.dragView.window convertRect:dragView.frame toWindow:rightView.window];
    dragViewFrameInTargetWindow = [rightView convertRect:dragViewFrameInTargetWindow fromView:rightView.window];
    itemView.frame = dragViewFrameInTargetWindow;
    
    CGRect viewFrame = [ovum.dragView.window convertRect:itemView.frame fromView:itemView.superview];
    
    void (^animation)() = ^{
      dragView.frame = viewFrame;
      
      [self layoutScrollView:leftView withContents:leftViewContents];
      [self layoutScrollView:rightView withContents:rightViewContents];
    };
    
    [dragDropManager animateOvumDrop:ovum withAnimation:animation completion:nil];
  }
}


@end
