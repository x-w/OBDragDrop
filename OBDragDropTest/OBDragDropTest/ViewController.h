//
//  ViewController.h
//  OBDragDropTest
//
//  Created by Zai Chang on 2/23/12.
//  Copyright (c) 2012 Oblong Industries. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBDragDrop.h"


@interface ViewController : UIViewController <OBOvumSource, OBDropZone>
{
  UIScrollView *leftView;
  NSMutableArray *leftViewContents;
  UIScrollView *rightView;
  NSMutableArray *rightViewContents;
}

@end
