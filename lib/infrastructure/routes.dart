import 'dart:developer';

class Routes {
  static const splashPage = "/splash";
  static Future<String> get splashPageRoute async {
    return splashPage;
  }

  static const onboardingPage = "/onboarding";
  static Future<String> get onboardingPageRoute async {
    return onboardingPage;
  }

  static const verifyPendingPage = "/verifyPending";
  static Future<String> get verifyPendingPageRoute async {
    return verifyPendingPage;
  }

  static const loginPage = "/login";
  static Future<String> get loginPageRoute async {
    return loginPage;
  }

  static const forgotPasswordPage = "/forgotPassword";
  static Future<String> get forgotPasswordPageRoute async {
    log("Fogot password pressed");
    return forgotPasswordPage;
  }

  static const emailSentSplashPage = "/emailSentSplash";
  static Future<String> get emailSentSplashPageRoute async {
    log("Email Sent Splash");
    return emailSentSplashPage;
  }

  static const registerPage = "/register";
  static Future<String> get registerPageRoute async {
    return registerPage;
  }

  static const homePage = "/home";
  static Future<String> get homePageRoute async {
    return homePage;
  }

  static const addRequestPage = "/addRequest";
  static Future<String> get addRequestPageRoute async {
    return addRequestPage;
  }

  static const requestDetailsPage = "/requestDetails";
  static Future<String> get requestDetailsPageRoute async {
    return requestDetailsPage;
  }

  static const editAddRequestPage = "/editAddRequest";
  static Future<String> get editAddRequestPageRoute async {
    return editAddRequestPage;
  }

  static const profilePage = "/profile";
  static Future<String> get profilePageRoute async {
    return profilePage;
  }

  static const myHelpsPage = "/myHelps";
  static Future<String> get myHelpsPageRoute async {
    return myHelpsPage;
  }

  static const privacyandsecurityPage = "/privacyandsecurity";
  static Future<String> get privacyandsecurityPageRoute async {
    return privacyandsecurityPage;
  }

  static const contactUsPage = "/contactUs";
  static Future<String> get contactUsPageRoute async {
    return contactUsPage;
  }

  static const notificationsPage = "/notifications";
  static Future<String> get notificationsPageRoute async {
    return notificationsPage;
  }

  static const feedbackPage = "/feedback";
  static Future<String> get feedbackPageRoute async {
    return feedbackPage;
  }

  static const addfeedbackPage = "/addfeedbackpage";
  static Future<String> get addfeedbackPageRoute async {
    return addfeedbackPage;
  }

  
  static const chatPage = "/chatpage";
  static Future<String> get chatPageRoute async {
    return chatPage;
  }

  static const myApplicationsPage = "/myApplications";
  static Future<String> get myApplicationsPageRoute async {
    return myApplicationsPage;
  }
}
