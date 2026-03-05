# Privacy Policy — MDF Education

**Last updated:** June 2025

## 1. Introduction

MDF Education ("the App") is a mobile and web application that connects to your institution's Moodle learning management system. This Privacy Policy explains how data is collected, used, and protected when you use the App.

## 2. Data We Collect

| Category | Examples | Purpose |
|----------|----------|---------|
| **Authentication** | Username, password, auth token | Logging in to your Moodle site |
| **Profile** | Name, email, profile photo URL | Displaying your identity in the app |
| **Academic** | Courses, grades, submissions, quiz attempts | Showing your learning progress |
| **Communication** | Messages, forum posts | Enabling peer and instructor interaction |
| **Device** | OS version, device model, push notification token | Delivering notifications, crash reporting |

## 3. How We Use Your Data

- **Authentication & Access:** Credentials are used solely to authenticate with your Moodle server via its REST API. Passwords are never stored on our servers.
- **Local Storage:** Your auth token and server URL are stored securely on-device using platform-native secure storage (Android Keystore / iOS Keychain).
- **Notifications:** Push notification tokens are registered with Firebase Cloud Messaging to deliver course reminders and messages.
- **Offline Access:** Downloaded course content and files are cached locally on your device.

## 4. Data Sharing

- We do **not** sell, rent, or share your personal data with third parties.
- All academic data flows exclusively between your device and your institution's Moodle server.
- Firebase services (Analytics, Crashlytics, Cloud Messaging) may collect anonymized usage data per Google's privacy policy.

## 5. Data Retention

- Your data is stored on your institution's Moodle server and governed by their data retention policies.
- Local app data (cached files, tokens) is removed when you log out or uninstall the app.

## 6. Security

- All network communication uses HTTPS/TLS encryption.
- Tokens are stored in platform secure storage (Android Keystore / iOS Keychain).
- No sensitive data is logged or transmitted to external analytics.

## 7. Your Rights

Depending on your jurisdiction, you may have the right to:

- Access, correct, or delete your personal data
- Export your data in a portable format
- Withdraw consent for data processing

To exercise these rights, contact your institution's Moodle administrator.

## 8. Children's Privacy

The App does not knowingly collect data from children under 13. Access is governed by your educational institution's policies.

## 9. Changes to This Policy

We may update this policy periodically. Changes will be communicated through the App or its distribution channels.

## 10. Contact

For privacy questions, contact your institution's IT department or the MDF development team at the repository's issue tracker.
