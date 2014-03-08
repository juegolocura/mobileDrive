//
//  IPadTableViewController.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobileDriveAppDelegate.h"

@interface IPadTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

typedef enum {HELP_TAG, ADD_DIR_TAG} buttonTag;

typedef struct {

   char *currentDir;
   char *currentPath;

}state;

//FIXME change the type of fsModel from id to class name of the iPad file system model class.
-(id)initWithState:(state)currentState model:(id)fsModel target:(MobileDriveAppDelegate *)respond switchAction:(SEL)action forEvents:(UIControlEvents)events;
-(void)buttonPressed:(id)sendr;

@end