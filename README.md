# WearableGemini   - Gemini API competition
# buildwithgemini
Welcome to the Wearable Gemini repository! This project aims to develop a comprehensive wearable technology solution that seamlessly integrates an Apple Watch and an iPhone application using SwiftUI, along with a Python server backend. The system leverages Firebase for data communication and storage. The core functionalities include:

# Core Functionalities
1. Transform IMU Signals: Captures and processes IMU signals from the Apple Watch to detect user motion.
2. Embed Motion Signals: Embeds the motion signals for further analysis.
3. Label Signals with Natural Language: Allows users to label recent signals using natural language.
4. Auto-Detection of Similar Signals: Automatically detects if there are similar paired signals.
5. Motion to Text Conversion: This method uses a model to convert motion to language descriptions and employs Gemini to extract current actions and corresponding meta-information.
6. Generate Daily Summaries: Compile a daily summary based on the detected motions.


# Features
## Apple Watch Application (SwiftUI):

## Captures real-time IMU signals (accelerometer, gyroscope, etc.).
Sends sensor data to the iPhone application.
Displays motion-related data to the user.
iPhone Application (SwiftUI):

## Receives IMU data from the Apple Watch.
Allows users to label motion signals with natural language.
Communicates with the Python server for motion prediction and text conversion.
Displays predictions, daily summaries, and other relevant information to the user.
Provides a user-friendly interface for managing settings and viewing motion data.
Python Server:

## Hosted on a server, interfacing with Firebase for real-time data exchange.
Processes IMU signals using machine learning models.
Predicts user motion and converts it to text descriptions.
Sends motion predictions and text descriptions back to the iPhone application.
Firebase Integration:

## Stores and synchronizes data between the Apple Watch, iPhone app, and Python server.
Manages authentication, real-time database updates, and cloud functions.

# Getting Started
## Prerequisites
coming soon~
