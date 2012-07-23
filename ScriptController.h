//
//  ScriptController.h
//  ScriptRunner
//
//  Created by Zack Smith on 2/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArgumentArrayController.h"


@interface ScriptController : NSObject {
	ScriptController *ScriptController;
	ArgumentArrayController *myArgumentArrayController;
	IBOutlet NSWindow *mainWindow ;
	IBOutlet NSPanel *configureArgumentsPanel;
	IBOutlet NSBox *outputBox ;
	
	IBOutlet NSTextField *scriptNameField;
	IBOutlet NSTextField *scriptDescriptionField;
	IBOutlet NSTextField *scriptOutputField;
	IBOutlet NSTextField *commandLine ;
	IBOutlet NSTextField *addArgumentField;
	IBOutlet NSTableView *argumentsView;
	IBOutlet NSButton *runAsRoot;
	
	IBOutlet NSProgressIndicator *mainProgressIndicator;
	
	NSDictionary *settings;
	
	NSMutableArray *arguments;

	NSString *scriptName;
	NSString *scriptDescription;
	NSString *scriptPath;
	NSString *scriptExtention;
	NSString *windowTitle;
	
	NSBundle *thisBundle;

}

//@property (copy) NSString *title;


- (IBAction)runMainScript:(id)sender;
- (IBAction)disclosureTrianglePressed:(id)sender;
- (IBAction)copyToClipboard:(id)sender;
- (IBAction)configureArguments:(id)sender;
- (IBAction)doneConfiguringArguments:(id)sender;
- (IBAction)removeSelectedArgument:(id)sender;
- (IBAction)addArgument:(id)sender;
- (IBAction)sendEmail:(id)sender;
- (IBAction)insertFileNameAsArgument:(id)sender;

-(NSString *) urlEncode: (NSString *) url;

- (void)resetOutputBox;
- (void)runTask;
- (void)runTaskAsRoot;
- (void)readLogFile;

- (void)readInSettings;
- (void)setupInterface;
- (void)startUpArgumentArray;

@end
