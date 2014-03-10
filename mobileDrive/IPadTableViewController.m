//
//  IPadTableViewController.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

#import "IPadTableViewController.h"
#import <string.h>

@interface IPadTableViewController ()

@property(weak, atomic) id model;//FIXME chage type from id to pointer to iPad file system model

@end

@implementation IPadTableViewController {

    __weak MobileDriveAppDelegate *_iPadResponder;
    SEL _switchAction;
    UIControlEvents _switchEvents;
    state _iPadState;
    UISwitch *_conectSwitch;
    NSDictionary *_filesDictionary;
    NSArray *_fileKeys;
    UIScrollView *_helpScroll;
    UILabel *_helpView;

}

// We may need these inits for later but for right now they are useles
//-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
//
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//    
//    }
//    return self;
//}
//
//-(id)initWithStyle:(UITableViewStyle)style {
//
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//
//}

-(id)initWithState:(state)currentState
             model:(id)fsModel
            target:(MobileDriveAppDelegate *)respond
      switchAction:(SEL)action
         forEvents:(UIControlEvents)events {

    self = [super init];
    if (self) {

        // init state
        _iPadState.currentDir = currentState.currentDir;
        _iPadState.currentPath = currentState.currentPath;

        // init model
        _model = fsModel;

        // set up connection switch
        _iPadResponder = respond;
        _switchAction = action;
        _switchEvents = events;
        _conectSwitch = [[UISwitch alloc] init];
        [_conectSwitch addTarget:_iPadResponder
                          action:_switchAction
                forControlEvents:events];
        if (respond.isConnected)
            _conectSwitch.on = YES;
        else
            _conectSwitch.on = NO;

    }

    return self;

}

-(void)dealloc {

    //NSLog(@"dealloc");
    //This assumes that the strings were created on the heap
    if (_iPadState.currentDir != NULL)
        free(_iPadState.currentDir);
    if (_iPadState.currentPath != NULL)
        free(_iPadState.currentPath);

}

-(UIBarButtonItem *)makeButtonWithTitle:(NSString *)title
                                    Tag:(NSInteger)tag
                                  Color:(UIColor *)color
                                 Target:(id)target
                                 Action:(SEL)action {
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:title
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:target
                                                                  action:action];
    [backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:LARGE_FONT_SIZE],
                                                                                  NSFontAttributeName,
                                                                                  nil]
                              forState:UIControlStateNormal];
    backButton.tag = tag;
    backButton.tintColor = color;

    return backButton;

}

-(CGSize)sizeOfString:(NSString *)string withFont:(UIFont *)font {

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size];

}

-(void)loadView {

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.view = tableView;

}

- (void)viewDidLoad {

    [super viewDidLoad];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];

    // Set up directory Contents
    if(_filesDictionary == nil) {

        //FIXME change for grabing info from plist and instead grab data from model
        NSString *path = [[NSBundle mainBundle] pathForResource:@"files" ofType:@"plist"];
        _filesDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        _fileKeys = [[_filesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];

    }

    // Get colors
    UIColor *buttonColor = [UIColor colorWithRed:(220.0/255.0)
                                           green:(20.0/255.0)
                                            blue:(60.0/255.0)
                                           alpha:1.0f];
    UIColor *toolBarColor = [UIColor colorWithRed:0.65f
                                            green:0.65f
                                             blue:0.65f
                                            alpha:1.0f];
    UIColor *navBarColor = [UIColor colorWithRed:0.75f
                                           green:0.75f
                                            blue:0.75f
                                           alpha:1.0f];

    // Add a help button to the top right
    UIBarButtonItem *helpButton = [self makeButtonWithTitle:@"Need help?"
                                                        Tag:HELP_TAG
                                                      Color:buttonColor
                                                     Target:self
                                                     Action:@selector(buttonPressed:)];
    self.navigationItem.rightBarButtonItem = helpButton;

    // Add a add dir button to the bottom left
    UIBarButtonItem *addDirButton = [self makeButtonWithTitle:@"Add Directory"
                                                          Tag:ADD_DIR_TAG
                                                        Color:buttonColor
                                                       Target:self
                                                       Action:@selector(buttonPressed:)];

    // flexiable space holder
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil
                                                                          action:nil];

    // make lable for switch
    NSString *switchString = @"Turn on/off server:";
    UILabel *switchLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [self sizeOfString:switchString
                                                                                      withFont:[UIFont systemFontOfSize:LARGE_FONT_SIZE]].width, CELL_HEIGHT)];
    switchLable.text = switchString;
    switchLable.backgroundColor = [UIColor clearColor];
    switchLable.textColor = [UIColor blackColor];
    switchLable.font = [UIFont systemFontOfSize:LARGE_FONT_SIZE];
    [switchLable setTextAlignment:NSTextAlignmentCenter];
    UIBarButtonItem *switchButtonItem = [[UIBarButtonItem alloc] initWithCustomView:switchLable];

    // add switch to the bottom right
    UIBarButtonItem *cSwitch = [[UIBarButtonItem alloc] initWithCustomView:_conectSwitch];

    // put objects in toolbar
    NSArray *toolBarItems = [[NSArray alloc] initWithObjects:addDirButton, flex, switchButtonItem, cSwitch, nil];
    self.toolbarItems = toolBarItems;

    // set tool bar settings
    self.navigationController.toolbar.barTintColor = toolBarColor;
    [self.navigationController.toolbar setOpaque:YES];

    // set navbar settings
    self.navigationController.navigationBar.barTintColor = navBarColor;
    self.navigationController.navigationBar.tintColor = buttonColor;
    [self.navigationController setToolbarHidden:NO animated:YES];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

-(void)viewWillAppear:(BOOL)animated {

    _conectSwitch.on = _iPadResponder.isConnected;
    [super viewWillAppear:animated];

}

- (void) orientationChanged:(NSNotification *)note {

    NSLog(@"Rotated!");
    CGFloat height = 0.0;

    if (_helpScroll && _helpView) {

        if (self.view.frame.size.width > self.view.frame.size.height)
            height = self.view.frame.size.width;

        else
            height = self.view.frame.size.height;

        NSLog(@"changing frames.");

        _helpScroll.contentSize = CGSizeMake(_helpScroll.frame.size.width, height + self.navigationController.navigationBar.frame.size.height + self.navigationController.toolbar.frame.size.height);
        [_helpScroll setNeedsDisplay];

    }

}

-(void)buttonPressed:(UIBarButtonItem *)sender {

    NSLog(@"buttonPressed: %d", sender.tag);
    //FIXME add code to handel a button press here
    switch (sender.tag) {

        case HELP_TAG:
        {
            NSString *helpMessagePath = [[NSBundle mainBundle] pathForResource:@"file" ofType:@"txt"];
            NSString *helpMessage = [NSString stringWithContentsOfFile:helpMessagePath encoding:NSUTF8StringEncoding error:NULL];

            CGFloat height = 0;
            if (self.view.frame.size.height > self.view.frame.size.width)
                height = self.view.frame.size.height;
            else
                height = self.view.frame.size.width;

            _helpView = [[UILabel alloc] initWithFrame:CGRectMake(LARGE_FONT_SIZE,
                                                                  0.0,
                                                                  self.view.frame.size.width,
                                                                  height)];
            _helpView.text = helpMessage;
            _helpView.backgroundColor = [UIColor clearColor];
            _helpView.textColor = [UIColor blackColor];
            _helpView.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
            _helpView.numberOfLines = 0;
            _helpView.tag = HELP_VIEW_TAG;
            [_helpView sizeToFit];

            _helpScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x,
                                                                         self.view.frame.origin.y + self.navigationController.navigationBar.frame.size.height,
                                                                         self.view.frame.size.width,
                                                                         height - self.navigationController.navigationBar.frame.size.height - self.navigationController.toolbar.frame.size.height)];
            [_helpScroll addSubview:_helpView];
            [_helpScroll setScrollEnabled:YES];
            [_helpScroll setBounces:NO];
            _helpScroll.tag = HELP_SCROLL_VIEW_TAG;

            _helpScroll.contentSize = CGSizeMake(_helpScroll.frame.size.width, height + self.navigationController.navigationBar.frame.size.height + self.navigationController.toolbar.frame.size.height);

            UIViewController *helpController = [[UIViewController alloc] init];
            helpController.title = @"Help Page.";
            [helpController.view addSubview:_helpScroll];
            [self.navigationController pushViewController:helpController animated:YES];
        }
            break;
        default:
            break;

    }

}

-(void)didReceiveMemoryWarning {

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}

#pragma mark - Table view data source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [_fileKeys count];

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return CELL_HEIGHT;

}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // fetch cell
    static NSString *cellID = @"filesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];

    // fecthc key and dict info
    NSString *key = [_fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [_filesDictionary objectForKey:key];

    // set up cell text and other atributes
    cell.detailTextLabel.text = [dict objectForKey:@"path"];
    if ([[dict objectForKey:@"isDir"] boolValue]) {

        cell.textLabel.text = [NSString stringWithFormat:@"📂 %@", key];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    }
    else
        cell.textLabel.text = [NSString stringWithFormat:@"📄 %@", key];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:LARGE_FONT_SIZE];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];

    return cell;

}

#pragma mark - Table View Delegate

-(char *)nsStringToCString:(NSString *)s {

    int len = [s length];
    char *c = (char *)malloc(len + 1);
    int i = 0;
    for (; i < len; i++) {

        c[i] = [s characterAtIndex:i];

    }
    c[i] = '\0';

    return c;

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Fetch data from keys and dictionary
    NSString *key = [_fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [_filesDictionary objectForKey:key];

    // if the dict object is a directory then...
    if ([[dict objectForKey:@"isDir"] boolValue]) {

        // set up state for subTableViewController
        NSString *subPath = [NSString stringWithFormat:@"%s/%@", _iPadState.currentPath, key];
        state newState;
        newState.currentDir = [self nsStringToCString:key];
        newState.currentPath = [self nsStringToCString:subPath];

        NSLog(@"%s", newState.currentPath);

        // Make subTableviewcontroller to push onto nav stack
        IPadTableViewController *subTableViewController = [[IPadTableViewController alloc] initWithState:newState
                                                                                                   model:self.model
                                                                                                  target:_iPadResponder
                                                                                            switchAction:_switchAction
                                                                                               forEvents:_switchEvents];
        subTableViewController.title = key;

        // Set up back button
        [subTableViewController.navigationItem setBackBarButtonItem:[self makeButtonWithTitle:key
                                                                                          Tag:BACK_TAG
                                                                                        Color:nil
                                                                                       Target:nil
                                                                                       Action:nil]];

        // push new controller onto nav stack
        [self.navigationController pushViewController:subTableViewController animated:YES];

    }

    // else dict object is a file then...
    else {

        //FIXME add code to handel the case when user clicks on a file.

    }

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end