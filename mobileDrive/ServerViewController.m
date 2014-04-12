//
//  ServerViewController.m
//  mobileDrive
//
//  Created by Sebastian Sanchez on 3/12/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "ServerViewController.h"
#import "MobileDriveAppDelegate.h"
// Used to get IP
#import <ifaddrs.h>
#import <arpa/inet.h>


#define kTrialMaxUploads 50

@interface ServerViewController ()
@end

@implementation ServerViewController{
    __block GCDWebServer* webServer;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id) init{
    NSLog(@"viewDidLoad ServerViewController.m");
    _current_ip_address = [NSMutableString stringWithString: @"test"];
    
    @autoreleasepool {
        // Create server
         webServer = [[GCDWebServer alloc] init];

        // Get the path to the website directory
        NSString* websitePath = [[NSBundle mainBundle] pathForResource:@"Website" ofType:nil];
        
        [webServer addGETHandlerForBasePath:@"/" directoryPath:websitePath indexFilename:nil cacheAge:3600 allowRangeRequests:YES];

        // Redirect root website to index.html
        [webServer addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
            
        }];
        
        //NSString* myFile = [[NSBundle mainBundle] pathForResource:@"arrow_down" ofType:@"png" inDirectory:@"Website/img"];
        /*
        [webServer addHandlerForMethod:@"GET" path:@"/download" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            GCDWebServerResponse* response = nil;
            
            NSMutableString* content = [[NSMutableString alloc] init];
            //[_appDelegate.model getJsonContentsIn: "/"];
            //[getJsonContentsIn
         
//            [content appendFormat:@"<html><body><p>/download?id=%@&name=%@</p></body></html>",
//             [request.query objectForKey:@"id"],
//             [request.query objectForKey:@"name"]
//             ];
            //response = [GCDWebServerFileResponse responseWithFile:myFile isAttachment:YES];
            //response = [GCDWebServerResponse responseWithStatusCode:403];
            //return response;
            return [GCDWebServerDataResponse :[_appDelegate.model getJsonContentsIn: @"/"]];
        }];*/
        
        [webServer addHandlerForMethod:@"GET" path:@"/directory.json" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            NSString * pathArg = [request.query objectForKey:@"path"];
            if ( pathArg == NULL){
                return [GCDWebServerResponse responseWithStatusCode:403];
            }else{
                NSData * json_in_NSData =[[ [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model] getJsonContentsIn: pathArg ] dataUsingEncoding:NSUTF8StringEncoding];
                return [GCDWebServerDataResponse responseWithData: json_in_NSData contentType: @"application/json"];
            }
        }];
        
        [webServer addHandlerForMethod:@"GET" path:@"/createDir.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            NSString * pathArg = [request.query objectForKey:@"path"];
            if ( pathArg == NULL){
                return [GCDWebServerResponse responseWithStatusCode:403];
            }else{
                NSMutableString* content = [[NSMutableString alloc] init];
                if ( ![[(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model] createDirectory:pathArg] ){
                                [content appendFormat:@"<html><body><p>Folder %@ was created.</p></body></html>",
                                  pathArg
                                ];
                    NSLog(@"Server added to model");
                    // Calling Refresh Function
                    [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: ADD_MODEL_TAG
                                                                                                       From: pathArg To: nil];
                    
                }else{
                    [content appendFormat:@"<html><body><p>Folder %@ was not created.</p></body></html>",
                     pathArg];
                }
                return [GCDWebServerDataResponse responseWithHTML:content];
            }
        }];

        [webServer addHandlerForMethod:@"GET" path:@"/rename.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            NSString * oldPath = [request.query objectForKey:@"old"];
            NSString * newPath = [request.query objectForKey:@"new"];
            
            if ( oldPath == NULL || newPath == NULL ){
                return [GCDWebServerResponse responseWithStatusCode:403];
            }else{
                NSMutableString* content = [[NSMutableString alloc] init];
                if ( ![[(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model] renameDirectory:oldPath to:newPath] ){
                    [content appendFormat:@"<html><body><p>Path %@ was renamed to %@.</p></body></html>",
                     oldPath, newPath];
                    
                    // Calling Refresh Function
                    [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: RENAME_MODEL_TAG
                                                                                                       From: oldPath To: newPath];
                }else{
                    [content appendFormat:@"<html><body><p>Path %@ was NOT renamed to %@.</p></body></html>",
                     oldPath, newPath];
                }
                return [GCDWebServerDataResponse responseWithHTML:content];
            }
        }];

        [webServer addHandlerForMethod:@"POST" path:@"/upload.html" requestClass:[GCDWebServerMultiPartFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest * request) {
            GCDWebServerMultiPartFormRequest *mpReq = (GCDWebServerMultiPartFormRequest *)request;
            GCDWebServerMultiPartFile *file = [mpReq.files objectForKey:@"upload-file"];
            NSString *uploadDir = [[mpReq.arguments objectForKey:@"upload-dir"] string];
            NSString *fileName = [file fileName];
            NSString *filePath = [NSString stringWithFormat:@"%@%@", uploadDir, fileName];

            FILE *fp = fopen([[file temporaryPath] cStringUsingEncoding:NSASCIIStringEncoding], "r");

            // If temp file wasn't uploaded, respond with error JSON
            if (!fp) {
                NSString *response = @"{\n\t\"type\": \"error\",\n\t\"msg\": \"Upload failed\"\n}";
                return [GCDWebServerDataResponse responseWithData: [response dataUsingEncoding:NSUTF8StringEncoding] contentType: @"application/json"];
            }

            // Get file size
            fseek(fp, 0, SEEK_END);
            int sz = ftell(fp);
            rewind(fp);

            // Overwrite/put file
            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];
            NSDictionary *contents = [model getDirectoryListIn:uploadDir];
            if ([contents objectForKey:fileName]) {
                [model overwriteFile:filePath from:fp];
            } else {
                [model putFile:filePath from:fp withSize:sz];
            }

            fclose(fp);

            // Refresh the iPad view
            [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: ADD_MODEL_TAG
                                                                                               From: uploadDir To: nil];

            // Respond with success JSON
            NSString *response = @"{\n\t\"type\": \"success\",\n\t\"msg\": \"Upload succeeded\"\n}";
            return [GCDWebServerDataResponse responseWithData: [response dataUsingEncoding:NSUTF8StringEncoding] contentType: @"application/json"];
        }];

        [webServer addHandlerForMethod:@"GET" path:@"/download.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {

            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];

            NSString *uuid = [[NSUUID UUID] UUIDString];
            NSString *path = [request.query objectForKey:@"path"];
            NSString *tempPath = NSTemporaryDirectory();
            NSString *tempFile = [tempPath stringByAppendingPathComponent:uuid];

            FILE *fp = fopen([tempFile cStringUsingEncoding:NSASCIIStringEncoding], "w");
            if (!fp) {
                return [GCDWebServerDataResponse responseWithHTML:@"<html><body>Failed to create temporary file.</body></html>"];
            }
            
            int sz;
            if ([model getFile:path to:fp withSize:&sz] != DBFS_OKAY) {
                return [GCDWebServerDataResponse responseWithHTML:@"<html><body>Failed to get file from DB.</body></html>"];
            }

            fclose(fp);

            NSData *data = [[NSFileManager defaultManager] contentsAtPath:tempFile];
            NSString *fnHeader = [NSString stringWithFormat:@"attachment; filename=%@", [path lastPathComponent]];

            GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData:data contentType:@"application/octet-stream"];
            [response setValue:fnHeader forAdditionalHeader:@"Content-Disposition"];
            return response;
        }];

        [webServer start];
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad ServerViewController.m");
    //	webServer = [[GCDWebServer alloc] init];
	// Do any additional setup after loading the view.

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) turnOnServer{
    [webServer start];
}

-(void) turnOffServer{
    [webServer stop];
}

// Get IP Address
// Source: http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}
@end
