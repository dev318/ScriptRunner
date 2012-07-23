//
//  ScriptController.m
//  ScriptRunner
//
//  Created by Zack Smith on 2/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScriptController.h"


@implementation ScriptController

//@synthesize title;


- (id)init
{
    self = [super init];
    if (self)
	{
		// create the collection array
        arguments = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)awakeFromNib 
{
	[mainProgressIndicator stopAnimation:self];
	[self resetOutputBox];
	[self readInSettings ];
	[self setupInterface ];
	[self startUpArgumentArray ];
	BOOL runAsRootBool;
	runAsRootBool = [settings objectForKey:@"scriptSudo"];
	if(runAsRootBool){
		[runAsRoot setState:NSOnState];
	}
	else {
		[runAsRoot setState:NSOffState];

	}


	windowTitle = [settings objectForKey:@"windowTitle"];
	[ mainWindow setTitle:windowTitle];
	//[argumentsView setDataSource:self];



}

-(IBAction)insertFileNameAsArgument:(id)sender
{
	NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
	[openPanel setAllowsMultipleSelection:FALSE];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:@"Choose"]; // Should be localized
	[openPanel setCanChooseFiles:YES];
	[openPanel setShowsHiddenFiles:YES]; // Undocumented API
	
	[openPanel beginForDirectory:nil file:nil types:nil modelessDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSString *filePathChoosen = [panel filename];
	[addArgumentField setStringValue: [NSString stringWithFormat:@"'%@'",filePathChoosen] ];
}


- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return ([arguments count]);
}

- (id)tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
			row:(int)row{
	return [arguments objectAtIndex:row];
}



- (void)startUpArgumentArray{
	arguments = [settings objectForKey:@"scriptArguments"];
}

-(void)setupInterface
{
	scriptName = [settings objectForKey:@"scriptName"];
	scriptDescription = [settings objectForKey:@"scriptDescription"];
	[scriptNameField setStringValue:scriptName ];
	[scriptDescriptionField setStringValue:scriptDescription ];

}

- (IBAction)configureArguments:(id)sender
{
	arguments = [settings objectForKey:@"scriptArguments"];
	[argumentsView reloadData];
	[NSApp beginSheet:configureArgumentsPanel modalForWindow:mainWindow
        modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction)doneConfiguringArguments:(id)sender
{
    [configureArgumentsPanel orderOut:nil];
    [NSApp endSheet:configureArgumentsPanel];
}


- (void)readLogFile{
	NSString *path = @"/tmp/scriptoutput.log";
	NSError *error;
	NSString *stringFromFileAtPath = [[NSString alloc]
                                      initWithContentsOfFile:path
                                      encoding:NSUTF8StringEncoding
                                      error:&error];
	if (stringFromFileAtPath == nil) {
		// an error occurred
		NSLog(@"Error reading file at %@\n%@",
              path, [error localizedFailureReason]);
	}
}

- (void)runTask{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	
	scriptPath = [settings objectForKey:@"scriptPath"];
	
	scriptExtention = [settings objectForKey:@"scriptExtention"];
	
	if ([settings objectForKey:@"scriptIsInBundle"]){
		scriptPath = [thisBundle pathForResource:scriptPath ofType:scriptExtention];
		//scriptPath = [thisBundle pathForResource:scriptPath	ofType:@"sh" inDirectory:"@bin"];

		NSLog(@"Found script path:%@",scriptPath);
	}

	// Create a pool so we don't leak on our NSThread
	NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: scriptPath];

	

	[task setArguments: arguments];
	
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    [task launch];
    NSData *data;
    data = [file readDataToEndOfFile];
	
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	[ scriptOutputField setStringValue:string ];
	[mainProgressIndicator stopAnimation:self];	
	[pool drain];
	
}

-(void)runTaskAsRoot{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	scriptPath = [settings objectForKey:@"scriptPath"];
	
	scriptExtention = [settings objectForKey:@"scriptExtention"];
	
	if ([settings objectForKey:@"scriptIsInBundle"]){
		scriptPath = [thisBundle pathForResource:scriptPath ofType:scriptExtention];
		//scriptPath = [thisBundle pathForResource:scriptPath	ofType:@"sh" inDirectory:"@bin"];
		
		NSLog(@"Found script path:%@",scriptPath);
	}
	NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
	NSString *appleScriptShell = [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges",scriptPath];
	NSLog(@"Built AppleScript:%@",appleScriptShell);
	
	NSAppleScript *scriptObject = [[NSAppleScript alloc]initWithSource:appleScriptShell];
	returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
	//NSLog(@"Return Discriptor,%@",returnDescriptor);
	[ scriptOutputField setStringValue:[returnDescriptor stringValue]];
	[scriptObject release];
	[mainProgressIndicator stopAnimation:self];
	[pool drain];
	
}


-(IBAction)runMainScript:(id)sender
{	
	[mainProgressIndicator startAnimation:self];
	if([runAsRoot state] == NSOnState){
		[NSThread detachNewThreadSelector:@selector(runTaskAsRoot) toTarget:self withObject:nil];
	}
	else{
		[NSThread detachNewThreadSelector:@selector(runTask) toTarget:self withObject:nil];
	}

}

- (IBAction)disclosureTrianglePressed:(id)sender {
    NSWindow *window = [sender window];
    NSRect frame = [window frame];
    // The extra +14 accounts for the space between the box and its neighboring views
    CGFloat sizeChange = [outputBox frame].size.height + 14;
    switch ([sender state]) {
        case NSOnState:
            // Show the extra box.
			[outputBox setHidden:NO];
            // Make the window bigger.
            frame.size.height += sizeChange;
            // Move the origin.
            frame.origin.y -= sizeChange;
            break;
        case NSOffState:
            // Hide the extra box.
            [outputBox setHidden:YES];
            // Make the window smaller.
            frame.size.height -= sizeChange;
            // Move the origin.
            frame.origin.y += sizeChange;
            break;
        default:
            break;
    }
    [window setFrame:frame display:YES animate:YES];
}

- (void)resetOutputBox{
    NSRect frame = [mainWindow frame];
	CGFloat sizeChange = [outputBox frame].size.height + 14;
	// Hide the extra box.
	[outputBox setHidden:YES];
	// Make the window smaller.
	frame.size.height -= sizeChange;
	// Move the origin.
	frame.origin.y += sizeChange;
	[mainWindow setFrame:frame display:YES animate:NO];
	return;
}

- (IBAction)sendEmail:(id)sender
{
	
	NSString *emailBody	 = [scriptOutputField stringValue];
	
	NSString *emailAddress = [settings objectForKey:@"emailAddress"];
	
	NSString *subject = [NSString stringWithFormat:@"%@ Output",scriptName];

	NSString *body = [NSString stringWithFormat:@"%@\n%@\n%@",scriptName,scriptDescription,emailBody];
	
//	NSLog(@"Subject: %@ ",subject);

//	NSLog(@"Body: %@ ",body);
	
	
	NSString *encodedSubject = [self urlEncode:[subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	body = [body stringByReplacingOccurrencesOfString: @"\n" withString: @"\r"];

	NSString *encodedBody = [self urlEncode:[body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//	NSLog(@"Encoded Body: %@ ",encodedBody);
	
	
	NSString *encodedURLString = [NSString stringWithFormat:@"SUBJECT=%@&BODY=%@", encodedSubject, encodedBody];
	
	NSString *sendEmailComplete = [NSString stringWithFormat:@"mailto:%@?%@",emailAddress,encodedURLString];
	NSLog(@"Encoded URL string: %@",sendEmailComplete);

	NSURL *sendEmailURL = [NSURL URLWithString:sendEmailComplete];
	
	NSLog(@"Generated URL: %@ ",sendEmailURL);
	
	if ([[NSWorkspace sharedWorkspace] openURL:sendEmailURL])
	{
		//NSLog(@"Opened %@ successfully.",sendEmailURL);
	}
}

- (void)readInSettings 
{ 	
	thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [thisBundle pathForResource:@"settings" ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:path];
}

-(IBAction)copyToClipboard:(id)sender
{
	NSString *clipBoard = [scriptOutputField stringValue];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
    [pb declareTypes:types owner:self];
    [pb setString: clipBoard forType:NSStringPboardType];
}

//simple API that encodes reserved characters according to:
//RFC 3986
//http://tools.ietf.org/html/rfc3986
-(NSString *) urlEncode: (NSString *) url
{
    NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
							@"@" , @"&" , @"=" , @"+" ,
							@"$" , @"," , @"[" , @"]",
							@"#", @"!", @"'", @"(", 
							@")", @"*", @"\n",@" ",@"\\",@">",@"<",@"_",@"-",@".",@"™",nil];
	
    NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" ,
							 @"%3A" , @"%40" , @"%26" ,
							 @"%3D" , @"%2B" , @"%24" ,
							 @"%2C" , @"%5B" , @"%5D", 
							 @"%23", @"%21", @"%27",
							 @"%28", @"%29", @"%2A",@"%0D",@"%20",@"%5C",@"%3E",@"%3C",@"%5F",@"%2D",@"%2E",@"%0D",nil];
	
    int len = [escapeChars count];
	
    NSMutableString *temp = [url mutableCopy];
	
    int i;
    for(i = 0; i < len; i++)
    {
		
        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
							  withString:[replaceChars objectAtIndex:i]
								 options:NSLiteralSearch
								   range:NSMakeRange(0, [temp length])];
    }
	
    NSString *out = [NSString stringWithString: temp];
	
    return out;
}


- (IBAction)addArgument:(id)sender {
	[ arguments addObject:[commandLine stringValue]];
    [argumentsView reloadData];
}

- (IBAction)removeSelectedArgument:(id)sender {
    // Remove the selected row from the data set, then reload the table contents.
    [arguments removeObjectAtIndex:[argumentsView selectedRow]];
    [argumentsView reloadData];
}

@end
