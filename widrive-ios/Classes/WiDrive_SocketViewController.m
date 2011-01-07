//
//  WiDrive_SocketViewController.m
//  WiDrive-Socket
//
//  Created by Gavin Williams on 01/03/2010.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import "WiDrive_SocketViewController.h"

@implementation WiDrive_SocketViewController

@synthesize accelerometer;
@synthesize speedSlider, reverseSlider;
@synthesize btnStop, btnStart;
@synthesize flags, dial;
@synthesize handbrakeIcon, indicatorLeftIcon, indicatorRightIcon;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {2
}
*/

 
long map(long x, long in_min, long in_max, long out_min, long out_max)
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.accelerometer = [UIAccelerometer sharedAccelerometer];
	self.accelerometer.updateInterval = 1.0f/120.0f;
	self.accelerometer.delegate = self;
	
	car = [[Car alloc] init:@"192.168.0.50" carDelegate: self];
	
	
	UIImage *minImage = [UIImage imageNamed:@"slider-reverse-empty.png"];
	UIImage *maxImage = [UIImage imageNamed:@"slider-reverse-full.png"];
	UIImage *tumbImage= [UIImage imageNamed:@"slider.png"];
	UIImage *thumbImageActive = [UIImage imageNamed:@"slider-active.png"];
	
	reverseSlider = [[UISlider alloc] initWithFrame:CGRectMake(280, 125, 255, 78)];
	reverseSlider.transform = CGAffineTransformMakeRotation(degreesToRadians(90));
	
	[reverseSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
	[reverseSlider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
	[reverseSlider setThumbImage:tumbImage forState:UIControlStateNormal];
	[reverseSlider setThumbImage:thumbImageActive forState:UIControlStateHighlighted];
	
	reverseSlider.minimumValue = 0;
	reverseSlider.maximumValue = 90;
	reverseSlider.continuous = YES;
	reverseSlider.value = 90;
	reverseSlider.opaque = true;
	reverseSlider.hidden = true;
	
	[reverseSlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
	[reverseSlider addTarget:self action:@selector(sliderActionLetGo:) forControlEvents:UIControlEventTouchUpInside];
	[reverseSlider addTarget:self action:@selector(sliderActionLetGo:) forControlEvents:UIControlEventTouchUpOutside];
	
	[self.view insertSubview:reverseSlider atIndex: 1];
	[reverseSlider release];
	
	minImage = [UIImage imageNamed:@"slider-forward-full.png"];
	maxImage = [UIImage imageNamed:@"slider-forward-empty.png"];
	tumbImage= [UIImage imageNamed:@"slider.png"];
	thumbImageActive = [UIImage imageNamed:@"slider-active.png"];
	
	forwardSlider = [[UISlider alloc] initWithFrame:CGRectMake(280, 125, 255, 78)];
	forwardSlider.transform = CGAffineTransformMakeRotation(degreesToRadians(90));
	
	[forwardSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
	[forwardSlider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
	[forwardSlider setThumbImage:tumbImage forState:UIControlStateNormal];
	[forwardSlider setThumbImage:thumbImageActive forState:UIControlStateHighlighted];
	
	forwardSlider.minimumValue = 90;
	forwardSlider.maximumValue = 180;
	forwardSlider.continuous = YES;
	forwardSlider.value = 90;
	forwardSlider.opaque = true;
	
	[forwardSlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
	[forwardSlider addTarget:self action:@selector(sliderActionLetGo:) forControlEvents:UIControlEventTouchUpInside];
	[forwardSlider addTarget:self action:@selector(sliderActionLetGo:) forControlEvents:UIControlEventTouchUpOutside];
	
	[self.view insertSubview:forwardSlider atIndex: 1];
	[forwardSlider release];
	
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
}

-(void)sliderAction:(id)sender {
	UISlider *slider = (UISlider *)sender;
	int value = (int)(slider.value + 0.5f);
	[self setSpeed:value];
}

-(void)sliderActionLetGo:(id)sender {
	UISlider *slider = (UISlider *)sender;
	int value = 0;
	if(slider.maximumValue == 90){
		value = 90;
	}
	//[slider setValue:value animated: true];
}

-(void)rotateWheel:(int)degrees {
	steeringWheel.transform = CGAffineTransformMakeRotation(degreesToRadians(degrees));
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	NSUInteger tapCount = [touch tapCount];
	if(tapCount == 2){
		
		reverseSlider.value = 90;
		forwardSlider.value = 90;
		
		[self setSpeed:90];
		
		if(reverseSlider.hidden == true){
			reverseSlider.hidden = false;
			forwardSlider.hidden = true;
		} else {
			reverseSlider.hidden = true;
			forwardSlider.hidden = false;
		}
	}
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	
	accelerationY = acceleration.y * kFilteringFactor + accelerationY * (1.0 - kFilteringFactor);
	accelerationX = acceleration.x * kFilteringFactor + accelerationX * (1.0 - kFilteringFactor);
	
	long Ydegrees;
	
	if(accelerationY >= 0.75){
		Ydegrees = -90;
	} else if (accelerationY <= -0.75) {
		Ydegrees = 90;
	} else {
		Ydegrees = map(100.0 - (accelerationY + 1.0) * 100.0, -75, 75, -90, 90);
	}
	
	[self rotateWheel:Ydegrees];
	car.heading = (NSInteger *) map(Ydegrees, -90, 90, 180, 0);			
}

-(IBAction)start:(id)sender {
	[car connect];
}

-(IBAction)stop:(id)sender {
	[car disconnect];
}

-(IBAction)changeSpeed:(id)sender {
	UISlider *slider = (UISlider *)sender;
	int value = (int)(slider.value + 0.5f);
	[self setSpeed:value];
}

-(void)setSpeed:(int)speed {
	int degrees = 0;
	if(speed >= 90){
		degrees = map(speed, 90, 180, 0, 240);
	} else {
		degrees = map(speed, 90, 0, 0, 240);
	}
	
	dial.transform = CGAffineTransformMakeRotation(degreesToRadians(degrees));
	car.speed = (NSInteger *) speed;
}

-(void)indicate:(NSTimer *)timer {
	
}

-(void)onCarConnect:(Car *)carobj{
	btnStart.hidden = true;
	btnStop.hidden = false;
	CGRect goalBarRect = CGRectMake(189, 276, 0, 0);
	[UIView beginAnimations:@"flags" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationDelegate:self];
	flags.frame = goalBarRect;
	flags.alpha = 0;
	[UIView commitAnimations];
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.distanceFilter = kCLDistanceFilterNone;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	[locationManager startUpdatingHeading];
	handbrakeIcon.image = [UIImage imageNamed:@"handbrake-off.png"];
}

-(void)onCarDisconnect:(Car *)carobj {
	btnStart.hidden = false;
	btnStop.hidden = true;
	CGRect goalBarRect = CGRectMake(85, 236, 208, 81);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationBeginsFromCurrentState:YES];
	flags.frame = goalBarRect;
	flags.alpha = 1;
	[UIView commitAnimations];
	/*
	CABasicAnimation *fullRotation;
	fullRotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	fullRotation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * -1];
	fullRotation.duration = 0.5;
	fullRotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	[dial.layer addAnimation:fullRotation forKey:@"fullRotation"];*/
	speedSlider.value = 0;
	[locationManager stopUpdatingHeading];
	handbrakeIcon.image = [UIImage imageNamed:@"handbrake-on.png"];
}


-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	float heading = [newHeading trueHeading];
	float adjustedHeading;
	
	if(!startHeading){
		startHeading = heading;
	}
	
	adjustedHeading = (heading - startHeading);  //90 is because North is now east.
	
	//Better to have things running from 0 to 360 degrees.
	if(adjustedHeading < 0)
	{
		adjustedHeading = adjustedHeading + 360;
	}
	
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

/* Callbacks for connecting to socket */


- (void)dealloc {
	[super dealloc];
	[car release];
}

@end
