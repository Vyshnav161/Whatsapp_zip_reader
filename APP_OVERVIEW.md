# WhatsApp ZIP Reader: Overview and Monetisation Discussion

## What the app is

A Flutter Android app (published on Google Play, package `com.wolfex161.wzipchat`) that opens WhatsApp chat exports. WhatsApp's "Export chat" feature produces a ZIP file containing a text file of messages and, optionally, the media. That ZIP is hard to read on a phone. This app turns it into a WhatsApp-style chat view.

## The problem it solves

- An exported chat is a raw `.txt` file plus a folder of loose media files.
- There is no easy way to read it as a conversation, search it, or see which media belonged to which message.
- People export chats to keep records of old conversations, change phones, keep memories of someone, or save evidence for legal or work purposes.

## Current features

- Import a WhatsApp export ZIP from device storage.
- Extract the ZIP to a temporary directory and parse the messages (timestamp, sender, text).
- Chat tab: messages in chronological order in a WhatsApp-like interface.
- Media tab: grid of media grouped by type (images, videos, audio, documents).
- Search across messages.
- In-app preview of images, video and audio.
- Download or save media files to the device.
- Export the chat to a PDF (WhatsApp-style colours), saved to Downloads/WZipChat. This already exists in the free app.
- Tappable links in messages (link detection and `url_launcher`).
- Fully local processing. No chat data is uploaded to any server.

## Tech

Flutter and Dart, version 1.0.3+4. Provider for state, `archive` for ZIP handling, `pdf` for export, `file_picker`, `permission_handler`, `path_provider`, `video_player`, `audioplayers`.

## Who uses it (assumptions to challenge)

- Someone who got a chat export from a friend or relative and wants to read it.
- Someone moving phones or backing up a chat who wants to view it without restoring it into WhatsApp.
- Someone keeping a chat as a record (family, legal, business).
- Usage is probably occasional and task-based: open one chat, read, leave. This affects which pricing model fits.

## Constraints

- Privacy is a selling point: all data stays on the device. Any feature that needs a server or an ad SDK weakens that claim.
- The app is a utility, not a daily-use app, so retention is low by nature.
- No server infrastructure exists today, so running costs are near zero.
- Android only at the moment. The repo has no iOS folder.
- Chats are not saved after import. The app holds one chat in memory per session, and no database or local storage package is in `pubspec.yaml`.
- No ads, billing or app lock code exists yet.

## Monetisation options (proposed, none implemented yet)

### Option A: Freemium with a one-time "Pro" purchase (current favourite)

Free:
- Read one chat at a time, browse media, search within the current chat.
- Banner ad on the chat list screen only (optional, see questions).

Pro (one-time, about $3 to $5):
- No ads.
- Saved chat library (chats persist after import, no re-importing).
- Better export: HTML, PDF with media or date ranges, printable transcripts. (Basic PDF export exists today and is free, so it would need to be limited or upgraded to justify Pro.)
- Bulk "save all media".
- Search across all saved chats.
- Date-range filters, jump to date, per-sender statistics.
- Themes and dark mode.
- App lock (PIN or biometric).

### Option B: Subscription

Monthly or yearly (for example $9.99 per year). It only makes sense if the app gains ongoing value:
- Cloud backup or sync of the chat library.
- AI features: summaries, "find where we talked about X", sentiment or timeline views.
- Both cost money to run and conflict with the local-only privacy promise.

### Option C: Ads only

Banner and interstitial ads, with rewarded ads to unlock a single export. Low revenue for a low-frequency app, and ad SDKs add data collection.

### Option D: Pay per use

Free to read. A small fee or rewarded ad for each export or bulk download. Matches the occasional usage pattern but is awkward to explain.

## Features that would have to be built first

The current app has none of these. Pro depends on them.
1. Persistent chat library (storage and a chat list).
2. Upgraded export (HTML, date ranges, media in PDF). Basic PDF export already exists.
3. Paywall screen and Play Billing integration (`in_app_purchase` or RevenueCat).
4. Ads integration, if ads are used (`google_mobile_ads`).
5. App lock and themes.

## Open questions for discussion

1. Does a subscription make sense for an app used a few times per user, or is one-time better?
2. Is a price of about $3 to $5 right? What would you pay to export a chat you care about?
3. Should the free tier include ads, given the privacy positioning? Is paid-only with a free trial better?
4. Which Pro feature would actually make someone pay: library, export, bulk media, search, app lock?
5. Is there a paying audience we are missing (lawyers, HR, investigators, journalists, family archivists)? Would they need features such as verified or tamper-evident exports?
6. Should AI features exist, and can they run on-device to keep the privacy claim?
7. Would supporting iOS, or other chat apps (Telegram, Signal, iMessage exports), grow the market more than monetising the current one?
8. How should the app be found? Play Store keywords, a landing page, short videos showing how to read a WhatsApp export?
9. Are there policy risks? Play Store rules on ads, data safety forms, and WhatsApp trademark use in the name and icon.

## Practical notes

- The release build is still signed with the debug key. A real upload key is needed before further Play releases.
- The version code must be bumped for every upload.
- Adding ads or billing requires updating the Play Console Data safety form and the privacy policy.
