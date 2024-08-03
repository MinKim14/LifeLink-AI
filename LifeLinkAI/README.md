# LifeLinkAI
![LifeLinkAI Banner](./banner.png)

LifeLinkAI is an iOS application utilizing Firebase for storage, real-time database, authentication, and Firestore database functionalities. This project is built using SwiftUI and includes a Watch App companion.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [iOS Setup](#ios-setup)
- [Usage](#usage)


## Features

- Firebase Authentication (Email/Password)
- Firebase Realtime Database
- Firebase Firestore Database
- Firebase Storage
- SwiftUI-based iOS App
- Watch App companion

## Installation

### Firebase Setup

1. **Create a Firebase Project**
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Click on "Add project" and name it `LifeLinkAI`
   - Follow the on-screen instructions to create the project

2. **Enable Firebase Services**
   - **Storage**: Go to the Storage section, and enable it.
   - **Realtime Database**: Go to the Realtime Database section, and enable it.
   - **Firestore Database**: Go to the Firestore Database section, and enable it.
   - **Authentication**: Go to the Authentication section, enable it, and set up Email/Password as the sign-in provider.

3. **Set Firebase Rules**
   - For initial testing, set the read and write rules to true:
     - **Realtime Database Rules**:
       ```json
         {
           "rules": {
             "$user_id": {
               "question":{
                 ".read": "$user_id === auth.uid",
                  ".write": "$user_id === auth.uid"
               },
               "response":{
                 ".read": "$user_id === auth.uid",
                  ".write": "$user_id === auth.uid"
               },
               "overview":{
                 ".read": "$user_id === auth.uid",
               },
               "chats":{
                 ".read": "$user_id === auth.uid",
               },
               "model_answer":{
                 ".read": "$user_id === auth.uid",
               },
               "model_message":{
                 ".read": "$user_id === auth.uid",
               },
               "summaries":{
                 ".read": "$user_id === auth.uid",
               },
             }
           }
         }
       ```
     - **Firestore Database Rules**:
       ```json
         service firebase.storage {
           match /b/{bucket}/o {
             // Match files within the user's directory
             match /{userId}/{allPaths=**} {
               // Allow read access if the request is authenticated and the user is accessing their own directory
               allow read: if request.auth != null && request.auth.uid == userId;
               // Allow write access if the request is authenticated and the user is accessing their own directory
               allow write: if request.auth != null && request.auth.uid == userId;
             }
           }
         }
       ```

4. **Download Configuration File**
   - Download the `GoogleService-Info.plist` file from the Firebase Console.
   - Place the `GoogleService-Info.plist` file into the `LifeLinkAI/LifeLinkAI` directory of your Xcode project.

## Open the Project in Xcode
Open LifeLinkAI.xcodeproj or LifeLinkAI.xcworkspace in Xcode.

## Change Bundle Identifier
Go to Project > LifeLinkAI > Targets > LifeLinkAI
Change the Bundle Identifier to m-kim-kaist.ac.kr.LifeLinkAI or your preferred bundle identifier.

## Change Watch App Bundle Identifier
Go to Project > LifeLinkAI > Targets > LifeLinkAI Watch App
Change the Bundle Identifier to match your new identifier.
Update WKCompanionAppBundleIdentifier in Info.plist of the watch app.

## App Groups and Keychain Sharing (Optional)
Update App Groups and Keychain Sharing group names if needed.

# Usage
## Run the App
Build and run the app on your iOS device or simulator.
## Sign In
Use the Email/Password authentication to sign in.
## Test Firebase Integration

Verify that you can read and write data to Firebase Storage, Realtime Database, and Firestore Database.
