/*
 Copyright 2015 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "LoginController.h"
#import <SpotifyAuthentication/SpotifyAuthentication.h>
#import <SpotifyMetadata/SpotifyMetadata.h>
#import <SpotifyAudioPlayback/SpotifyAudioPlayback.h>
#import "Config.h"

#import <SafariServices/SafariServices.h>
#import <WebKit/WebKit.h>
#import "WebViewController.h"

@interface LoginController () <SFSafariViewControllerDelegate, WebViewControllerDelegate, SPTStoreControllerDelegate>

@property (atomic, readwrite) UIViewController *authViewController;
@property (atomic, readwrite) BOOL firstLoad;

@end

@implementation LoginController


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionUpdatedNotification:) name:@"sessionUpdated" object:nil];
    self.firstLoad = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    SPTAuth *auth = [SPTAuth defaultInstance];
    // Uncomment to turn off native/SSO/flip-flop login flow
    //auth.allowNativeLogin = NO;

    
    // Check if we have a token at all
    if (auth.session == nil) {
        return;
    }

    // Check if it's still valid
    if ([auth.session isValid] && self.firstLoad) {
        // It's still valid, show the player.
        [self showPlayer];
        return;
    }

    // Oh noes, the token has expired, if we have a token refresh service set up, we'll call tat one.
    if (auth.hasTokenRefreshService) {
        [self renewTokenAndShowPlayer];
        return;
    }

    // Else, just show login dialog
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIViewController *)authViewControllerWithURL:(NSURL *)url
{
    UIViewController *viewController;
    if ([SFSafariViewController class]) {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
        safari.delegate = self;
        viewController = safari;
    } else {
        WebViewController *webView = [[WebViewController alloc] initWithURL:url];
        webView.delegate = self;
        viewController = [[UINavigationController alloc] initWithRootViewController:webView];
    }
    viewController.modalPresentationStyle = UIModalPresentationPageSheet;
    return viewController;
}

- (void)sessionUpdatedNotification:(NSNotification *)notification
{

    SPTAuth *auth = [SPTAuth defaultInstance];
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    
    if (auth.session && [auth.session isValid]) {
        [self showPlayer];
    } else {
        NSLog(@"*** Failed to log in");
    }
}

- (void)showPlayer
{
    self.firstLoad = NO;
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"MenuViewController"];
    [self presentViewController:vc animated:YES completion:nil];
    //[self performSegueWithIdentifier:@"showMenu" sender:nil];
}

#pragma mark - SPTStoreControllerDelegate

- (void)productViewControllerDidFinish:(SPTStoreViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)openLoginPage
{
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if ([SPTAuth supportsApplicationAuthentication]) {
        UIWebView *webView = [[UIWebView alloc]init];
        NSURLRequest *urlRequest = [auth spotifyAppAuthenticationURL];
        [webView loadRequest:urlRequest];
        //[[UIApplication sharedApplication] openURL:[auth spotifyAppAuthenticationURL]];
    } else {
        self.authViewController = [self authViewControllerWithURL:[[SPTAuth defaultInstance] spotifyWebAuthenticationURL]];
        self.definesPresentationContext = YES;
        [self presentViewController:self.authViewController animated:YES completion:nil];
    }
}

- (void)renewTokenAndShowPlayer
{
    SPTAuth *auth = [SPTAuth defaultInstance];

    [auth renewSession:auth.session callback:^(NSError *error, SPTSession *session) {
        auth.session = session;

        if (error) {
            NSLog(@"*** Error renewing session: %@", error);
            return;
        }

        [self showPlayer];
    }];
}

#pragma mark WebViewControllerDelegate

- (void)webViewControllerDidFinish:(WebViewController *)controller
{
    // User tapped the close button. Treat as auth error
}

#pragma mark SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    // User tapped the close button. Treat as auth error
}

#pragma mark - IBActions
- (IBAction)loginClicked:(id)sender {
    [self openLoginPage];
}
- (IBAction)logoutClicked:(id)sender {
    NSLog(@"%s", "logout called");
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
