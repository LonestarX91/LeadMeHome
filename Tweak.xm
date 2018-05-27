//Created by LonestarX © 2018
#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBFolderView.h>
#import <libcolorpicker.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioServices.h>

FOUNDATION_EXTERN void AudioServicesPlaySystemSoundWithVibration(unsigned long, objc_object*, NSDictionary*);

#define kIdentifier @"com.lnx.leadmehome"
#define kSettingsChangedNotification (CFStringRef)@"com.lnx.leadmehome/ReloadPrefs"
#define kColorChangedNotification (CFStringRef)@"com.lnx.leadmehome/colorChanged"
#define kSettingsResetNotification (CFStringRef)@"com.lnx.leadmehome/settingsReset"

#define kColorPath @"/var/mobile/Library/Preferences/com.lnx.leadmehome.color.plist"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.lnx.leadmehome.plist"

@interface SBIcon : NSObject
-(id)applicationBundleID;
@end

@interface SBFolderIcon
-(id)children;
-(id)folder;
-(id)rootFolder;
@end

@interface SBFolder : NSObject
-(SBFolder *)parentFolder;
-(void)setOpen:(BOOL)arg1 ;
-(SBFolderIcon *)icon;
@end

@interface SBRootFolder : SBFolder
-(id)children;
-(id)nodeIdentifier;
-(NSString *)displayName;
@end

@interface SBRootFolderWithDock : SBRootFolder
@end

@class SBRootFolder;
@interface SBRootFolderView
@property (nonatomic,retain) SBRootFolderWithDock * folder;
-(id)iconListViewAtIndex:(unsigned long long)arg1 ;
-(NSArray *)iconListViews;
-(unsigned long long)iconListViewCount;
@end

@interface SPUISearchHeader
-(void)cancelButtonClicked:(id)arg1 ;
@end

@interface SPUISearchViewController : UIViewController
@end

@interface SBSpotlightNavigationController : UINavigationController
@end

@interface SBIsolationTankController : UIViewController
@end

@interface SBHomeScreenViewController : UIViewController
@end

@interface SFSearchResult : NSObject
@property (nonatomic,copy) NSString * identifier;
@end

@interface SBIconView : UIView
+(id)_jitterPositionAnimation;
+(id)_jitterTransformAnimation;
+(id)_jitterXTranslationAnimation;
+(id)_jitterYTranslationAnimation;
-(SBIcon *)icon;
@end

@interface SBIconViewMap : NSObject
-(id)mappedIconViewForIcon:(id)arg1 ;
-(id)_iconViewForIcon:(id)arg1 ;
@end

@interface SBIconController : UIViewController
+(id)sharedInstance;
-(void)openFolderIcon:(id)arg1 animated:(BOOL)arg2 withCompletion:(/*^block*/id)arg3;
-(id)_rootFolderController;
-(id)_currentFolderController;
@end

@interface SBRootFolderController
@property (nonatomic,readonly) SBRootFolderView * contentView;
-(BOOL)setCurrentPageIndex:(long long)arg1 animated:(BOOL)arg2 completion:(/*^block*/id)arg3 ;
-(BOOL)setCurrentPageIndex:(long long)arg1 animated:(BOOL)arg2;
@end

@interface SBIconIndexMutableList : NSObject
@end

@interface SBRootIconListView : UIView
@end

@interface SBIconListModel : NSObject
@end

@interface SBApplicationIcon : SBIcon
-(id)applicationBundleID;
@end

@interface SBSearchEtceteraNavigationController : UINavigationController
@end

@interface SBSearchEtceteraIsolatedViewController : UIViewController
@end

@interface SBFolderController
-(BOOL)setCurrentPageIndex:(long long)arg1 animated:(BOOL)arg2 ;
-(void)setOpen:(BOOL)arg1 ;
-(SBIconViewMap *)viewMap;
-(BOOL)setCurrentPageIndex:(long long)arg1 animated:(BOOL)arg2 completion:(/*^block*/id)arg3 ;

@end

static NSInteger wantedFolderPageIndex = 0;
static SBFolderIcon *wantedFolder = nil;
static NSInteger wantedScreenIndex = 0;
static NSString *searchedBundle;
static SBIcon *desiredIcon;
static NSTimer *nukeAnimTimer;
static UIColor *glowColor;
static BOOL slamVibration;
static BOOL glowEnabled;
static NSInteger animType;
static SBIconView *targetIV;

static SBFolderIcon* findIcon(SBFolderIcon *fIcon) {
  SBFolder *ficonFolder = fIcon.folder;
  SBIconIndexMutableList *sbfIconList = [ficonFolder valueForKey:@"_lists"];
  NSMutableArray *folderNodesArray = [sbfIconList valueForKey:@"_nodes"];
  //searching all the pages in the current folder
  for (int k = 0; k < folderNodesArray.count; k++) {
    SBIconListModel *folderIconModel = folderNodesArray[k];
    SBIconIndexMutableList *folderIconIndexList = [folderIconModel valueForKey:@"_icons"];
    NSMutableArray *folderContentIcons = [folderIconIndexList valueForKey:@"_nodes"];
    //searching all the icons in the current page
    for (int m = 0; m < folderContentIcons.count; m++) {
      if (![folderContentIcons[m] isKindOfClass:%c(SBFolderIcon)]) {
        SBIcon *appIcon = folderContentIcons[m];
        if ([[appIcon applicationBundleID] isEqualToString:searchedBundle]) {
          desiredIcon = appIcon;
          wantedFolder = fIcon;
          wantedFolderPageIndex = k;
          return wantedFolder;
        }
      }
    }
    //no icon found in the current folder, searching inside folders
    for (int m = 0; m < folderContentIcons.count; m++) {
      if ([folderContentIcons[m] isKindOfClass:%c(SBFolderIcon)]) {
        findIcon(folderContentIcons[m]);
      }
    }
  }
  return nil;
}

static void wiggleMe(SBIconView *targetIconView) {
  targetIV = targetIconView;
  NSString *iconImgvKey = @"_currentImageView";
  if ((kCFCoreFoundationVersionNumber >= 1443.00)) {
    iconImgvKey = @"currentImageView";
  }

  UIView *curImgv = [targetIconView valueForKey:iconImgvKey];
  __weak UIView *weakImgv = curImgv;

  dispatch_async(dispatch_get_main_queue(), ^{

    CALayer *iconImageLayer = weakImgv.layer;
    if (glowEnabled) {
      iconImageLayer.shadowColor = glowColor.CGColor;
      iconImageLayer.shadowRadius = 5;
      iconImageLayer.shadowOpacity = 1;
      iconImageLayer.shadowOffset = CGSizeZero;
    }

    nukeAnimTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
      [iconImageLayer removeAllAnimations];
      iconImageLayer.shadowOpacity = 0;
      iconImageLayer.shadowColor = [UIColor clearColor].CGColor;
      iconImageLayer.shadowRadius = 0;
     }];

    if (animType == 0) {
      [CATransaction begin];
      [CATransaction setCompletionBlock:^{
        CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
        radiusAnimation.beginTime = 0;
        radiusAnimation.duration = 0.7;
        radiusAnimation.fromValue = [NSNumber numberWithFloat:5.0f];
        radiusAnimation.toValue = [NSNumber numberWithFloat:40.0f];
        radiusAnimation.removedOnCompletion = NO;
        radiusAnimation.fillMode = kCAFillModeBoth;
        radiusAnimation.additive = NO;
        [weakImgv.layer addAnimation:radiusAnimation forKey:@"dustSpreadAnim"];

        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        opacityAnimation.beginTime = 0;
        opacityAnimation.duration = 0.6;
        opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0f];
        opacityAnimation.toValue = [NSNumber numberWithFloat:0.0f];
        opacityAnimation.removedOnCompletion = NO;
        opacityAnimation.fillMode = kCAFillModeBoth;
        opacityAnimation.additive = NO;
        [weakImgv.layer addAnimation:opacityAnimation forKey:@"dustFadeAnim"];

        if ((kCFCoreFoundationVersionNumber < 1443.00)) {
          if (![weakImgv.layer animationForKey:@"iconFoundTransformAnimation"]) {
              [weakImgv.layer addAnimation:[%c(SBIconView) _jitterTransformAnimation] forKey:@"iconFoundTransformAnimation"];
          }
          if (![weakImgv.layer animationForKey:@"iconFoundPositionAnimation"]) {
              [weakImgv.layer addAnimation:[%c(SBIconView) _jitterPositionAnimation] forKey:@"iconFoundPositionAnimation"];
          }
        }
        else {
          if (![weakImgv.layer animationForKey:@"iconFoundTransformAnimation"]) {
              [weakImgv.layer addAnimation:[%c(SBIconView) _jitterXTranslationAnimation] forKey:@"iconFoundTransformAnimation"];
          }
          if (![weakImgv.layer animationForKey:@"iconFoundPositionAnimation"]) {
              [weakImgv.layer addAnimation:[%c(SBIconView) _jitterYTranslationAnimation] forKey:@"iconFoundPositionAnimation"];
          }
        }
        if (slamVibration) {
          NSMutableDictionary* dict = [NSMutableDictionary dictionary];
          NSMutableArray* arr = [NSMutableArray array];
          [arr addObject:[NSNumber numberWithBool:YES]];
          [arr addObject:[NSNumber numberWithInt:50]];
          [arr addObject:[NSNumber numberWithBool:NO]];
          [arr addObject:[NSNumber numberWithInt:50]];
          [dict setObject:arr forKey:@"VibePattern"];
          [dict setObject:[NSNumber numberWithFloat:.35] forKey:@"Intensity"];
          AudioServicesPlaySystemSoundWithVibration(1352, nil, dict);
        }

        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:NO block:^(NSTimer * _Nonnull timer) {
          [weakImgv.layer removeAnimationForKey:@"iconFoundTransformAnimation"];
          [weakImgv.layer removeAnimationForKey:@"iconFoundPositionAnimation"];
        }];

       }];
      CAKeyframeAnimation * transformAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
      transformAnim.values                = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                                               [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.7, 1.7, 1)],
                                               [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)]];
      transformAnim.keyTimes              = @[@0, @0.8, @0.85];
      transformAnim.duration              = 0.85;
      [iconImageLayer addAnimation:transformAnim forKey:@"slamAnimation"];
      [CATransaction commit];

    }
    else if (animType == 1) {
      if ((kCFCoreFoundationVersionNumber < 1443.00)) {
        if (![weakImgv.layer animationForKey:@"iconFoundTransformAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterTransformAnimation] forKey:@"iconFoundTransformAnimation"];
        }
        if (![weakImgv.layer animationForKey:@"iconFoundPositionAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterPositionAnimation] forKey:@"iconFoundPositionAnimation"];
        }
      }
      else {
        if (![weakImgv.layer animationForKey:@"iconFoundTransformAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterXTranslationAnimation] forKey:@"iconFoundTransformAnimation"];
        }
        if (![weakImgv.layer animationForKey:@"iconFoundPositionAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterYTranslationAnimation] forKey:@"iconFoundPositionAnimation"];
        }
      }
    }
    else if (animType == 2) {
      CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
      radiusAnimation.beginTime = 0;
      radiusAnimation.duration = 1;
      radiusAnimation.fromValue = [NSNumber numberWithFloat:5.0f];
      radiusAnimation.toValue = [NSNumber numberWithFloat:30.0f];
      radiusAnimation.removedOnCompletion = NO;
      radiusAnimation.fillMode = kCAFillModeForwards;
      radiusAnimation.autoreverses = YES;
      radiusAnimation.repeatCount = HUGE_VALF;
      [iconImageLayer addAnimation:radiusAnimation forKey:@"dustSpreadAnim"];
    }
    else if (animType == 3) {
      CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
      radiusAnimation.beginTime = 0;
      radiusAnimation.duration = 1;
      radiusAnimation.fromValue = [NSNumber numberWithFloat:5.0f];
      radiusAnimation.toValue = [NSNumber numberWithFloat:30.0f];
      radiusAnimation.removedOnCompletion = NO;
      radiusAnimation.fillMode = kCAFillModeForwards;
      radiusAnimation.autoreverses = YES;
      radiusAnimation.repeatCount = HUGE_VALF;
      [iconImageLayer addAnimation:radiusAnimation forKey:@"dustSpreadAnim"];

      if ((kCFCoreFoundationVersionNumber < 1443.00)) {
        if (![weakImgv.layer animationForKey:@"iconFoundTransformAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterTransformAnimation] forKey:@"iconFoundTransformAnimation"];
        }
        if (![weakImgv.layer animationForKey:@"iconFoundPositionAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterPositionAnimation] forKey:@"iconFoundPositionAnimation"];
        }
      }
      else {
        if (![weakImgv.layer animationForKey:@"iconFoundTransformAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterXTranslationAnimation] forKey:@"iconFoundTransformAnimation"];
        }
        if (![weakImgv.layer animationForKey:@"iconFoundPositionAnimation"]) {
            [weakImgv.layer addAnimation:[%c(SBIconView) _jitterYTranslationAnimation] forKey:@"iconFoundPositionAnimation"];
        }
      }
    }
  });
}

static void doTheMagic(id self) {
  if ([nukeAnimTimer isValid]) {
    [nukeAnimTimer invalidate];
    nukeAnimTimer = nil;
  }
  searchedBundle = [[self result] identifier];
  SBIconController *iconCT = [%c(SBIconController) sharedInstance];
  SBRootFolderController *rootFolderCT = [iconCT valueForKey:@"_rootFolderController"];
  SBRootFolderView *rootFV = rootFolderCT.contentView;
  NSArray *iconLVs = [rootFV iconListViews];
  //searching all the pages on homescreen
  for (int i = 0; i < iconLVs.count; i++) {
    SBRootIconListView *lv = iconLVs[i];
    SBIconListModel *iconModel = [lv valueForKey:@"_model"];
    SBIconIndexMutableList *iconIndexList = [iconModel valueForKey:@"_icons"];
    NSMutableArray *nodesArray = [iconIndexList valueForKey:@"_nodes"];
    for (int j = 0; j < nodesArray.count; j++) {
      //searching all the icons in the current page
      SBIcon *icon = nodesArray[j];
      if (![icon isKindOfClass:%c(SBFolderIcon)]) {
        //icon is not folder, checking match
        if ([[icon applicationBundleID] isEqualToString:[[self result] identifier]]) {
          //icon found, done searching
          desiredIcon = icon;
          wantedScreenIndex = i;
          goto done;
        }
      }
    }
    //no icon match found in current page, searching folders
    for (int j = 0; j < nodesArray.count; j++) {
      SBIcon *icon = nodesArray[j];
      if ([icon isKindOfClass:%c(SBFolderIcon)]) {
        if(findIcon((SBFolderIcon *)icon)) {
          wantedScreenIndex = i;
          goto done;
        }
      }
    }
  }
  done:;
  //Magic done, going to the icon
  SBIsolationTankController *sbITC = (SBIsolationTankController *)[self window].rootViewController;
  if ((kCFCoreFoundationVersionNumber >= 1443.00)) {
    SBSpotlightNavigationController *sbSNC = [sbITC valueForKey:@"_isolatedViewController"];
    SPUISearchViewController *searchVC = (SPUISearchViewController *)sbSNC.topViewController;
    SPUISearchHeader *searchHeader = [searchVC valueForKey:@"_searchHeader"];
    [searchHeader cancelButtonClicked:nil];
  }
  else {
    SBSearchEtceteraNavigationController *sbSENC = [sbITC valueForKey:@"_isolatedViewController"];
    SBSearchEtceteraIsolatedViewController *sbSEIVC = (SBSearchEtceteraIsolatedViewController *)sbSENC.topViewController;
    SPUISearchViewController *searchVC = [sbSEIVC valueForKey:@"_searchViewController"];
    SPUISearchHeader *searchHeader = [searchVC valueForKey:@"_searchHeader"];
    [searchHeader cancelButtonClicked:nil];
  }

  [rootFolderCT setCurrentPageIndex:wantedScreenIndex animated:NO];
  if (wantedFolder) {
    SBFolder *iteratingFolder = [[wantedFolder folder] parentFolder];
    NSMutableArray *folderTreeArray = [NSMutableArray new];
    [folderTreeArray addObject:wantedFolder];
    while(iteratingFolder) {
      if (![iteratingFolder isKindOfClass:%c(SBRootFolderWithDock)]) {
        [folderTreeArray insertObject:[iteratingFolder icon] atIndex:0];
        iteratingFolder = [iteratingFolder parentFolder];
      }
      else iteratingFolder = nil;
    }
    for (SBFolderIcon *obj in folderTreeArray) {
      [iconCT openFolderIcon:obj animated:NO withCompletion:^{
        if (obj == [folderTreeArray lastObject]) {
          [[iconCT _currentFolderController] setCurrentPageIndex:wantedFolderPageIndex animated:NO];
          SBIconView *targetIconView = [[[iconCT _currentFolderController] viewMap] mappedIconViewForIcon:desiredIcon];
          wiggleMe(targetIconView);
        }
      }];
    }
  }
  else {
    SBIconView *targetIconView = [[[iconCT _currentFolderController] viewMap] mappedIconViewForIcon:desiredIcon];
    wiggleMe(targetIconView);
  }

  wantedScreenIndex = 0;
  wantedFolderPageIndex = 0;
  wantedFolder = nil;
  searchedBundle = nil;
  desiredIcon = nil;
}

@interface SearchUIIconView : UIView
@property (retain) SFSearchResult * result;                                                 //@synthesize result=_result - In the implementation block
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender;
@property (nonatomic, retain) UILongPressGestureRecognizer *searchIconGesture;
@end

%hook SearchUIIconView
%property (nonatomic, retain) UILongPressGestureRecognizer *searchIconGesture;

-(void)updateWithResult:(id)arg1 {
  %orig;
  NSLog(@"search UIIconView");
  if (!self.searchIconGesture) {
    self.searchIconGesture = [[UILongPressGestureRecognizer alloc]
                                                 initWithTarget:self
                                                 action:@selector(handleLongPress:)];
      self.searchIconGesture.minimumPressDuration = 1.0;
      [self addGestureRecognizer:self.searchIconGesture];
  }
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
  if (sender.state == UIGestureRecognizerStateBegan) {
      doTheMagic(self);
  }
}
%end

@interface SearchUISingleResultTableViewCell : UITableViewCell
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender;
@property (retain) SFSearchResult *result;                                //@synthesize result=_result - In the implementation block
@property (nonatomic, retain) UILongPressGestureRecognizer *searchIconGesture;
@end


%hook SearchUISingleResultTableViewCell
%property (nonatomic, retain) UILongPressGestureRecognizer *searchIconGesture;

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
  if (sender.state == UIGestureRecognizerStateBegan) {
      doTheMagic(self);
  }
}

-(void)setResult:(SFSearchResult *)arg1 {
  %orig;
  NSLog(@"search single");
  if (!self.searchIconGesture) {
    self.searchIconGesture = [[UILongPressGestureRecognizer alloc]
                                                 initWithTarget:self
                                                 action:@selector(handleLongPress:)];
      self.searchIconGesture.minimumPressDuration = 1.0;
      [self addGestureRecognizer:self.searchIconGesture];
  }
}

%end

%hook SBFolderController
-(BOOL)setCurrentPageIndex:(long long)arg1 animated:(BOOL)arg2 {
  if ([nukeAnimTimer isValid]) {
    NSString *iconImgvKey = @"_currentImageView";
    if ((kCFCoreFoundationVersionNumber >= 1443.00)) {
      iconImgvKey = @"currentImageView";
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      UIView *curImgv = [targetIV valueForKey:iconImgvKey];
      CALayer *iconImageLayer = curImgv.layer;
      [iconImageLayer removeAllAnimations];
      iconImageLayer.shadowOpacity = 0;
      iconImageLayer.shadowColor = [UIColor clearColor].CGColor;
      iconImageLayer.shadowRadius = 0;
    });
  }
  return %orig;
}
%end

static void reloadColorPrefs() {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kColorPath];
	glowColor = [preferences objectForKey:@"glowColor"] ? LCPParseColorString([preferences objectForKey:@"glowColor"], @"#FFFFFF") : [UIColor redColor];
}

static void reloadPrefs() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList != nil) {
			prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
			if (prefs == nil)
				prefs = [NSDictionary dictionary];
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}

	glowEnabled = [prefs objectForKey:@"glowEnabled"] ? [(NSNumber *)[prefs objectForKey:@"glowEnabled"] boolValue] : true;
	slamVibration = [prefs objectForKey:@"slamVibration"] ? [(NSNumber *)[prefs objectForKey:@"slamVibration"] boolValue] : true;
	animType = [prefs objectForKey:@"animType"] ? [[prefs objectForKey:@"animType"] integerValue] : 0;
}

%ctor {
	reloadPrefs();
	reloadColorPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadColorPrefs, kColorChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
