# TO-DO.md

Postponed features for the personal app (Loopd).

Nothing in this file is part of the roadmap. No phase allocates time to it. An item moves into the plan only when you decide to schedule it.

Last updated: 2026-11-16

## Postponed

### 1. Multi-device sync
- **What:** Keep the same data on more than one device.
- **Why it waits:** Needs user accounts, a server and conflict handling. The app is single-device and fully offline by design.
- **Before starting:** Decide whether a server and its running cost are acceptable. The database already uses UUID keys, so no re-keying is needed.

### 2. Google Play release
- **What:** Publish a store build.
- **Why it waits:** SMS access on Play needs the "SMS-based money management" exception, which is reviewed case by case and is not assumed. Usage access and the overlay bubble also need store review and disclosures.
- **Before starting:** The store flavour without SMS code exists from Phase 0. Write a privacy policy and complete the permission declarations.

### 3. iOS verification on a real iPhone
- **What:** Run and verify every feature currently marked "Not Yet Verified" or "Coming Soon".
- **Why it waits:** No iPhone is available.
- **Covers:** Reminders and their actions, the 64-pending-notification scheduler, sharing into the app (Swift share extension), the app-switcher cover screen, biometric lock, file import, home-screen widgets (Swift).

### 4. iOS Shortcuts bridge for bank messages
- **What:** A user-made Shortcuts automation that passes a matching message's text to the app, which then shows the usual transaction card.
- **Why it waits:** Cannot be built or verified without an iPhone. It is set up by the user and is not automatic SMS detection.

### 5. Tracking money you owe
- **What:** Record money borrowed from others, as the mirror of lending.
- **Why it waits:** Not requested. Lending covers money owed to you.

### 6. Journey chip in the status bar (Android 16 Live Updates)
- **What:** A live chip and lock-screen card while a journey is under way.
- **Why it waits:** Needs Android 16. Your Tecno Pova Curve 5G runs Android 16 (HiOS 16.3, confirmed 17 Nov 2026), so it is possible; it waits until you schedule it. The final ticket notification already meets the requirement.

### 7. Bank statement CSV import
- **What:** Import past transactions from a bank's CSV export.
- **Why it waits:** Useful for history, not needed for daily use.

### 8. App timers or a focus mode in Digital Wellbeing
- **What:** Limits or blocking on top of the usage figures.
- **Why it waits:** Needs heavier permissions (accessibility or overlay control) and is a separate feature.

### 9. Images and rich formatting in notes
- **What:** Pictures, headings and styled text inside notes.
- **Why it waits:** Notes are plain text first to stay fast and simple.

### 10. About screen
- **What:** A screen in More with the version, the privacy promise and the iOS status.
- **Why it waits:** Not needed yet (owner's decision in the design review, 16 Nov 2026). The README covers it meanwhile.

## Removed, not postponed

These are out of scope and must not come back under another name:

- Payment hand-off to Google Pay or other payment apps
- Google Sheets as a live backend
- PNR scraping
- Paid booking APIs
- Custom keyboard
- Interest calculations
- Unsupported SMS access techniques (notification scraping, accessibility reading)
- Paid AI integrations and any cloud AI dependency (including a proxy, API keys, usage metering)
- Global Search
- Parser Health and Reminder Health screens
- Automatic saving of detected transactions without confirmation
- A 30-minute final travel reminder, and clearing the ticket notification by the clock
- Archived accounts and cards
- Folders in Notes
- Due dates and overdue states in Lending
- "Choose" pickers and a disabled Looks Good on unclear review cards
- On-device AI text features (ML Kit GenAI proofreading, rewriting, summarising), declined on 16 Nov 2026
- Fixed clock times for travel reminders, and a travel reminder time setting (stages follow the departure time)

## Optional enhancements that are in the roadmap

For reference only. These sit in Phase 10 and can be dropped without affecting the core:

- Monthly and category budgets
- Spending trends
- Recurring items
- Upcoming debits
- On-device text recognition to pre-fill a ticket from an image
