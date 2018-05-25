//Created by LonestarX © 2018

#include "LMHRootListController.h"

#define kColorPath @"/var/mobile/Library/Preferences/com.lnx.leadmehome.color.plist"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.lnx.leadmehome.plist"
#define kSettingsChangedNotification (CFStringRef)@"com.lnx.leadmehome/ReloadPrefs"
#define kColorChangedNotification (CFStringRef)@"com.lnx.leadmehome/colorChanged"

#define prefsAppID CFSTR("com.lnx.leadmehome")
#define prefsAppIDColor CFSTR("com.lnx.leadmehome.color")

@implementation LMHRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)viewDidLoad{
    [super viewDidLoad];

		UIButton *shareButton =  [UIButton buttonWithType:UIButtonTypeCustom];
		[shareButton addTarget:self action:@selector(shareAction)forControlEvents:UIControlEventTouchUpInside];
		[shareButton setFrame:CGRectMake(5, 5, 35, 35)];
		UIImageView *barButtonImageView = [[UIImageView alloc] initWithFrame:shareButton.bounds];
		barButtonImageView.image = [UIImage imageNamed:@"/Library/PreferenceBundles/leadmehome.bundle/heart"];
		barButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		[shareButton addSubview:barButtonImageView];

		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
		self.navigationItem.rightBarButtonItem = barButton;

}

- (void)presentActivityController:(UIActivityViewController *)controller {
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    controller.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
        if (error) {
            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
        }
    };
}
- (void)openPaypal {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/lonestarx1"] options:[NSDictionary new] completionHandler:nil];
}

- (void)openTwitter {
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=lonestarx"] options:[NSDictionary new] completionHandler:nil];
    else
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/LonestarX"] options:[NSDictionary new] completionHandler:nil];
}

- (void)sendMail {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:me@lonestarx.net"] options:[NSDictionary new] completionHandler:nil];
}

-(void)shareAction {
    NSString *shareMessage = @"Check out this cool icon finder tweak made by LonestarX !!! http://lonestarx.yourepo.com/pack/leadmehome";
    NSArray *items = @[shareMessage];
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    [self presentActivityController:controller];
}

- (void)resetSettings {
	[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath: kColorPath] error: nil];
	[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath: kSettingsPath] error: nil];
	CFPreferencesSetValue(CFSTR("glowColor"), NULL, prefsAppIDColor, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSetValue(CFSTR("glowEnabled"), NULL, prefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSetValue(CFSTR("slamVibration"), NULL, prefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSetValue(CFSTR("animType"), NULL, prefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

	CFPreferencesSynchronize(prefsAppID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(prefsAppIDColor, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

    [self reload];
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterPostNotification(r, kSettingsChangedNotification, NULL, NULL, true);
		CFNotificationCenterPostNotification(r, kColorChangedNotification, NULL, NULL, true);

}


@end
