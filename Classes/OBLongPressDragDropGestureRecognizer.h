//
//  OBLongPressDragDropGestureRecognizer.h
//  OBUserInterface
//
//  Created by Zai Chang on 3/1/12.
//  Copyright (c) 2012 Oblong Industries. All rights reserved.
//

#import "OBDragDropManager.h"


@interface OBLongPressDragDropGestureRecognizer : UILongPressGestureRecognizer <OBDragDropGestureRecognizer>

@property (nonatomic, retain) OBOvum *ovum;
@property (nonatomic, assign) id<OBOvumSource> ovumSource;

@end
