//
//  ViewController.swift
//  AppleSignIn
//
//  Created by Prue Phillips on 15/9/20.
//  Copyright © 2020 Inspirare Tech. All rights reserved.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController {
    @IBOutlet weak var loginProviderStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoginProviderView()
    }

    func setupLoginProviderView() {
            if #available(iOS 13.0, *) {
                let authorizationButton = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
                authorizationButton.cornerRadius = 40
                authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
                self.loginProviderStackView.addArrangedSubview(authorizationButton)
            }
            else {
                // Fallback on earlier versions (< iOS13 not supported at this stage)
            }
    }
    
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()

            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
        else {
            // Fallback on earlier versions (< iOS13 not supported at this stage)
        }
    }
    
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        if #available(iOS 13.0, *) {
            let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]
            
            // Create an authorization controller with the given requests.
            let authorizationController = ASAuthorizationController(authorizationRequests: requests)
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
        else {
            // Fallback on earlier versions (< iOS13 not supported at this stage)
        }
        
    }
}

@available(iOS 13.0, *)
extension ViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:

                let defaults = UserDefaults.standard
                let userIdentifier = appleIDCredential.user
                let authCode = appleIDCredential.authorizationCode // Data type
                guard let code = String(data: authCode!, encoding: .utf8) else {return}
                defaults.set(userIdentifier, forKey: "id")
                defaults.set(code, forKey: "authCode")

                if appleIDCredential.fullName?.givenName != nil {
                    defaults.set(appleIDCredential.fullName?.givenName?.capitalized, forKey: "firstName")
                }
                if appleIDCredential.fullName?.familyName != nil {
                    defaults.set(appleIDCredential.fullName?.familyName?.capitalized, forKey: "lastName")
                }
                if appleIDCredential.email != nil {
                    defaults.set(appleIDCredential.email, forKey: "email")
                }
                
                do {
                    try KeychainItem(service: "tech.inspirare.AppleSignIn", account: userIdentifier).saveCode(code)
                }
                catch {
                    print("Unable to save userIdentifier to keychain.")
                }
                
                UserDefaults.standard.set("apple", forKey: "loginProvider")
                UserDefaults.standard.set(true, forKey: "hasLoggedIn")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let vc = storyboard.instantiateViewController(withIdentifier: "onboardingController") as? OnboardingController else {return}
                let navController = UINavigationController(rootViewController: vc)
                navController.willMove(toParent: self)
                self.addChild(navController)
                navController.view.frame = self.view.frame
                self.view.addSubview(navController.view)
                navController.didMove(toParent: self)
                self.dismiss(animated: false, completion: nil)
            case let passwordCredential as ASPasswordCredential: // Sign in using an existing iCloud Keychain credential.
                UserDefaults.standard.set("apple", forKey: "loginProvider")
                UserDefaults.standard.set(true, forKey: "hasLoggedIn")
                let username = passwordCredential.user
                let password = passwordCredential.password
                print("Apple sign in existing iCloud Keychain credential")
                print(username)
                print(password)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let vc = storyboard.instantiateViewController(withIdentifier: "onboardingController") as? OnboardingController else {return}
                    let navController = UINavigationController(rootViewController: vc)
                    navController.willMove(toParent: self)
                    self.addChild(navController)
                    navController.view.frame = self.view.frame
                    self.view.addSubview(navController.view)
                    navController.didMove(toParent: self)
                    self.dismiss(animated: false, completion: nil)
            default:
                break
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            let hasLoggedIn = UserDefaults.standard.bool(forKey: "hasLoggedIn")
            if hasLoggedIn {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "", message: "Apple login failed.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            print("Apple login didCompleteWithError: \(error.localizedDescription)")
        }
        
}
    

    @available(iOS 13.0, *)
    extension ViewController: ASAuthorizationControllerPresentationContextProviding {
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return self.view.window!
        }

}

