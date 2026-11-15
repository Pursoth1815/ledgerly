# Personal App — Product Proposal & Phased Roadmap

Nov 14, 2026 · @Pursoth

## Summary

This is revision 2 of the proposal, rewritten to your final instructions. It describes an Android-first, fully offline personal app built on capture, confirm, remember, with nine core modules and no paid or cloud dependency of any kind. No code is written until you approve it.

- **Modules.** Today, Expenses, Lending, Travel, Notes, Tasks, Document Vault, Digital Wellbeing and an offline assistant. Notes, Tasks and the Vault are core, not deferred.
- **Expenses.** Two payment methods only, UPI and Credit Card, with multiple bank accounts and cards, nicknames, last four digits and defaults.
- **SMS detection.** Feasible on Android in a build you install yourself. Every detected payment becomes a card with Review and Looks Good, and nothing is saved until you confirm. Google Play approval is not assumed, and iOS has no equivalent.
- **Travel.** Four reminder stages, with the final ticket notification 15 minutes before departure. It shows on the lock screen and stays until you press Done.
- **Digital Wellbeing.** Feasible on Android through usage access. Not currently feasible on iOS.
- **Assistant.** Rule-based commands, text tools and summaries of your own data. Every AI API, the proxy and all cost tracking are removed.
- **Platform.** Android is built and tested. iOS keeps compiling, and everything on it is marked Not Yet Verified because there is no iPhone to test on.
- **Plan.** Thirteen phases. Money with SMS capture at day 32, the full core at day 73, Android v1.0 at day 86, widgets and the floating bubble last at day 93.
- **Postponed.** Multi-device sync and eight other ideas are listed in TO-DO.md and have no time in the roadmap.
- **From you.** Nine open points in section 19, the first being how cash and non-UPI bank debits should be treated.

## 1. What changed from the original proposal

Every decision in your final instructions is applied below. Rejected features are gone from the scope, architecture, phases and estimates, not parked.

| Area | Original proposal | This revision |
| --- | --- | --- |
| Modules | Money, People, Trips, optional AI assistant | Nine core modules: Today, Expenses, Lending, Travel, Notes, Tasks, Document Vault, Digital Wellbeing, offline assistant |
| Payment methods | Cash, bank, card and wallet accounts | Only UPI and Credit Card, each with multiple accounts or cards, nicknames, last four digits and a default |
| SMS capture | High-confidence matches saved automatically with Undo | Every detected transaction shows a card with Review and Looks Good. Nothing is saved without your confirmation |
| Final travel reminder | 30 minutes before departure, cleared at arrival or by "Journey started" | 15 minutes before departure, stays until you press Done, never cleared by the clock |
| Assistant | Claude API behind a proxy with a spending cap | Offline and rule-based only. No AI API, no proxy, no key, no usage metering |
| Grammar fix, rewriting, free-text summaries | Core assistant features | Removed. They need a language model |
| Parser Health and Reminder Health screens | Planned in Settings | Removed. Digital Wellbeing takes their place as a real feature |
| Global Search | Enhancement | Removed |
| Home-screen widgets | Phase 6 | Final phase |
| Floating bubble | I advised against it | Included in the final phase as an opt-in, with its cost stated |
| Multi-device sync | Future | Postponed in TO-DO.md |
| Upcoming debits | Enhancement tied to recurring items | Optional enhancement; nothing depends on it |
| Lending | Lent and borrowed | Money you lend only. Tracking money you owe moves to TO-DO.md |
| iOS | A dedicated optional phase | No iOS phase. The build stays compiling and every iOS behaviour is labelled Not Yet Verified |
| Network | One dependency: the AI proxy | None. The app ships without the internet permission |
| Roadmap | 10 phases, Android v1.0 at day 74 | 13 phases, Android v1.0 at day 86, widgets and bubble at day 93 |
| Folder structure and portfolio sections | Included | Dropped, as you asked for a product and engineering plan only |

## 2. Product direction

The product stays built on one loop: **capture, confirm, remember**. Information arrives by typing, by a bank or ticket SMS, or by sharing a file into the app. The app turns it into a draft, you confirm it, and it is filed where it belongs.

It is an Android-first app for one person, working fully offline, with an Apple-like level of finish. Working name: **Kanakku**.

Your resume already covers what this needs, so the plan leans on it instead of adding technology for show.

| Your experience | Where the plan uses it |
| --- | --- |
| Two production Flutter apps owned end to end, one with 500K+ downloads | Sole ownership of a complete product, from schema to release |
| Clean Architecture, MVVM, modular restructuring | A modular design with written reasons for each decision |
| Native Android and iOS work for calling, picture-in-picture and call state | Kotlin for SMS, the ticket notification, app-usage access and the bubble; Swift only where iOS needs it |
| Push notifications, deep links, lifecycle handling | The four-stage reminder and notification actions that work with the app closed |
| SQLite and Hive | An encrypted relational database with tested migrations |
| Payments work on the Worldline POS app | Reference numbers, reversals and duplicate handling in the transaction matcher |
| Startup and API optimisation, CI on Codemagic and Appcircle | Measured performance budgets and an automated build pipeline |

Your real-time chat and calling experience is not used. Nothing in a single-user offline app needs it.

## 3. Today and navigation

Today is the home screen and shows only what needs your attention, in this order. A card that has nothing to say is not shown.

| Card | Shows | Fed by |
| --- | --- | --- |
| Waiting for confirmation | Detected transactions and ticket drafts, each with Review and Looks Good | Review Inbox |
| Next trip | Route, departure time and booking status, when a trip is within seven days | Travel |
| Tasks | Due today and overdue, tickable in place | Tasks |
| Repayments | Due and overdue amounts by person | Lending |
| Spending | Today and month so far, split into UPI and Credit Card | Expenses |
| Screen time | Today's total and the most-used app | Digital Wellbeing, Android only |
| Backup | A nudge when the last backup is more than seven days old | Backup |

Navigation has five tabs and one capture button.

- **Today**
- **Money**, with two segments: Expenses and Lending
- **Travel**
- **Notes**, with two segments: Notes and Tasks
- **Vault**

Digital Wellbeing and Settings open from the corner of Today. The capture button is reachable from every tab and opens one sheet for a new expense, loan, trip, note or task, plus the command line described in section 10.

The Review Inbox opens from the first Today card. It holds every item that is detected but not yet confirmed.

## 4. Expenses: UPI and Credit Card only

The app records expenses and never starts a payment. The entry screen offers exactly two payment methods, UPI and Credit Card, as in your mockup.

Adding an expense by hand:

1. Enter the amount.
2. Choose UPI or Credit Card.
3. Choose the bank account (for UPI) or the card (for Credit Card). Your default is already selected.
4. Choose a category.
5. Save. Merchant, note and date are optional; the date defaults to today.

### Accounts and cards

You can add any number of each from the first build.

| Field | Bank account, used for UPI | Credit card |
| --- | --- | --- |
| Bank | HDFC Bank, SBI, ICICI Bank and so on | HDFC, SBI, ICICI and so on |
| Nickname | For example "Salary account" | For example "Travel card" |
| Last four digits | Of the account number | Of the card number |
| Default | One default bank account | One default card |

The last four digits are how an SMS is tied to the right account or card. There is no archived state: removing an account or card keeps its past transactions under the name they were saved with.

### Tracking and correction

- Totals by day, week and month, by category, by method, and separately for each bank account and each card.
- Any saved expense can be edited: method, account or card, category, amount, date and merchant. This is the manual correction for a wrong automatic guess.
- Categories come with a default set and can be added, renamed, coloured and given an icon.

### Rules that keep the totals right

- Paying a credit card bill is not an expense. The purchases were counted when they were made, so the app records the payment as a settlement outside spending.
- A refund reduces the original expense.
- Money moved between your own bank accounts is not an expense.
- Money lent and repaid follows the transfer rules in section 6.
- Money received, such as salary, is recorded against the bank account as income and never mixed into spending.

### Two consequences to confirm

Having only two methods leaves two kinds of spending without a home. I have not added a third method.

- **Cash.** Cash spending is not recorded.
- **Other bank debits.** ATM withdrawals, debit-card swipes, net banking and auto-debits still arrive by SMS. I propose they appear in the Review Inbox against the right bank account, where you either save them under that account or dismiss them. The entry screen keeps its two methods.

## 5. SMS detection and the transaction card

On Android, in a build you install yourself, the app can detect transaction SMS without any paid service. Every detection ends in a card you confirm. Nothing is saved silently.

### The flow

1. **Detect.** Android wakes a small receiver when an SMS arrives. Every app open also scans the inbox from the last checkpoint, so a late or missed message is still caught. No service runs in the background.
2. **Check it is a transaction.** The message must come from a commercial sender header and contain a transaction verb and an amount. Indian headers have carried a suffix since 6 May 2025: -P promotional, -S service, -T transactional, -G government ([reference](https://kb.smsalert.co.in/?p=2270)). It is a signal, not a guarantee, so the wording is checked too.
3. **Ignore the rest.** OTPs, promotions, failed payments and balance alerts are dropped. OTP text is never stored.
4. **Extract.** Amount, merchant or recipient, date and time, reference number and the last four digits.
5. **Identify the method.** UPI when the message carries UPI markers such as a UPI reference or a UPI ID. Credit Card when it names a credit card. Otherwise unknown.
6. **Identify the account or card.** The bank comes from the sender header and the last four digits are matched to your saved accounts and cards.
7. **Match existing records.** By reference number first, then by account, amount and date. A message for an expense you already typed in attaches to it as evidence. A repeat of the same payment is dropped.
8. **Show the card.**

&#91;embedded content: SMS to transaction card · 2 triggers, 5 steps, confirmation before saving\]

Both triggers feed the same scan. A new transaction always stops at the card and waits for you.

### The transaction card

The card follows your mockup.

| Element | Behaviour |
| --- | --- |
| Title and amount | "New transaction detected", the amount, then "Paid to Swiggy · 13 Nov 2026" |
| Category | Predicted from merchants you have categorised before; "Not set" when unknown |
| Payment method | UPI or Credit Card |
| Account | The bank account or card, by nickname |
| Review | Opens the transaction details, where every field can be edited |
| Looks Good ✓ | Confirms the details and saves the transaction to Money |
| An uncertain field | Shows "Choose". Looks Good stays disabled until you pick the method, bank or card |

The card appears in three places: on Today, in the Review Inbox, and as an Android notification with the same two actions, so you can confirm without opening the app. An unconfirmed card stays in the Review Inbox until you act on it. Inside Review you can also mark a message as "Not a transaction".

### Edge cases

| Case | Behaviour |
| --- | --- |
| SMS arrives hours or days late | The card is dated by the time written in the message, so it lands on the correct day and month |
| Bank changes its wording | The bank template misses, a generic extractor tries, and the card shows "Choose" for whatever it could not read |
| Unknown last four digits | The card offers to add the account or card |
| Credit card bill payment | Recorded as a settlement, not an expense |
| Refund or reversal | Linked to the original expense and shown as refunded |
| Transfer between your own accounts | The debit and credit pair into one transfer |
| Money from someone who owes you | The card offers "Record as repayment" |
| Reinstall or restore | Each message has an identity hash, so nothing is imported twice |
| SMS deleted before the next scan | The receiver saves a copy on arrival, which reduces this risk but cannot remove it |

### Feasibility and policy

| Question | Finding | Decision |
| --- | --- | --- |
| Personal build installed from an APK | SMS permissions work. On Android 15 and later, a sideloaded app must be given "Allow restricted settings" once ([explanation](https://androidauthority.com/android-15-restricted-settings-sideloading-3481098)) | This is the build you use daily. A one-time setup screen guides the step |
| Google Play | SMS permissions are restricted. "SMS-based money management" is a listed exception, reviewed case by case ([policy](https://support.google.com/googleplay/android-developer/answer/10208820?hl=en)) | Approval is not assumed. A Play release is in TO-DO.md |
| Alternative without SMS permission | Paste or share a message's text into the app. The same parser produces the same card | Built in Phase 3; works on every platform |
| Reading bank notifications instead | Play forbids deriving SMS data through other permissions ([policy](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en)) | Not used |
| Android's SMS verification APIs | Built for one-time codes, not for reading transaction messages | Not used |
| iOS | No SMS inbox access for any app | Manual entry and paste or share only. No automatic detection is promised |
| Paid parsing services | Not needed | The parser is your own Dart code, tested against your own messages with digits scrambled |

Reliability depends on a template per bank. The target, measured in Phase 3 on your own inbox, is that at least 95% of transaction messages from your main banks produce a complete card.

## 6. Money lent and repayments

The Lending segment answers three questions at a glance: who owes you, how much, and what is due.

| Feature | Detail |
| --- | --- |
| People list | Each person with their outstanding balance, overdue first |
| Recording a loan | Person, amount, date, purpose, notes, and the bank account it was paid from |
| Several loans per person | Each loan keeps its own balance; a repayment settles the oldest loan first unless you choose another |
| Repayments | Monthly instalments or ad hoc amounts, in full or in part |
| Schedules | None, monthly, or custom dates. "Whenever they can" shows no overdue state |
| Mark received | One tap from the list, the person page or the reminder notification |
| History | Every loan, repayment and note for a person, in date order. Corrections show as visible adjustments |
| Reminders | To you, about due and overdue repayments. Never sent to the other person |
| Statement | A plain-text summary you can share when someone asks what they owe |
| Suggested repayment | A bank credit SMS from a borrower is offered as a repayment on its card |
| Write off | Closes a balance without recording a false repayment |

The accounting rules are fixed:

- Money lent is a **transfer out**, not an expense.
- A repayment is a **transfer in**, not income.
- Both appear in the bank account's history and in neither spending nor income totals.

People are chosen with the system contact picker, which needs no contacts permission, or typed by name. There are no interest calculations.

## 7. Travel tickets and reminders

A ticket is typed in, detected from an SMS, or shared into the app as a file. Fifteen minutes before departure it is on your lock screen, and it stays there until you press Done.

### Getting a ticket into the app

| Path | How it works | Where |
| --- | --- | --- |
| Manual entry | A form; only date, time, from and to are required | Android and iOS |
| SMS detection | Booking messages from the railway and bus operators become a ticket draft with Review and Looks Good. Later messages for the same ticket, such as the bus number or crew contact, update it by ticket reference | Android personal build |
| Share to app | A PDF, image or text shared from any app creates a draft | Android; Coming Soon on iOS |

No paid booking API is used and no PNR status is scraped. A waitlist or RAC change is updated by hand.

### What is stored

| Group | Fields |
| --- | --- |
| Journey | Bus, train, flight or other; boarding point; destination; departure date and time; arrival time |
| Train | Train number and name, coach, seat or berth, class, PNR, booking status |
| Bus | Operator, bus number, seat, boarding time, conductor or driver name and phone where the operator sends them |
| Booking | Ticket reference, passengers, fare, where it was booked |
| Document | The ticket PDF or image, encrypted on the phone and readable offline |

A trip can also be saved as **Planned** before a ticket exists, with a "book by" reminder. That covers the case of forgetting whether you booked at all. The ticket screen opens full-screen at full brightness for QR checks.

### The four reminder stages

| Stage | Timing | Default clock time | Purpose |
| --- | --- | --- | --- |
| 1 | One day before travel | 19:00 the evening before | Prepare for the journey |
| 2 | Travel-day morning | 07:00 | Check the journey details |
| 3 | Three hours before departure | Departure minus 3 h | Prepare for boarding |
| 4 | 15 minutes before departure | Departure minus 15 min | The final ticket notification |

A stage whose time has already passed when the ticket is added is skipped, and so is one that would fall after the next stage. Editing a ticket reschedules every stage and cancelling it removes them.

### The final ticket notification

| Requirement | Android | iOS, Not Yet Verified |
| --- | --- | --- |
| Ticket details | Expanded layout: operator and number, route, departure time, coach and seat, reference | The same details as notification text |
| Visible on the lock screen | Yes, when your lock-screen setting allows notification content. An app setting can hide the details | Depends on the phone's notification preview setting |
| Stays until you dismiss it | Posted as an ongoing notification. On Android 14 and later it cannot be swiped away while the phone is locked and survives Clear all; unlocked, you can still swipe it ([docs](https://developer.android.com/about/versions/14/behavior-changes-all?hl=en)) | Stays in Notification Centre until cleared; it cannot be pinned |
| Not cleared at departure time | No timeout is set and the app never removes it by the clock | Same |
| Show Ticket | Opens the full ticket in the app after unlock | Opens the app |
| Done | Clears the notification without opening the app | An action clears it |
| After a restart | Posted again until you press Done | Not verified |
| One notification across stages | Yes. The same notification is updated at each stage | Each stage is a separate scheduled notification in one group. Replacing the earlier one needs the app to be running |

The ticket stays in Travel after the notification is gone.

One Android detail matters at a 15-minute lead. Exact alarms are off by default for new installs on Android 14 and later ([docs](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)). The app asks for that permission when you add your first ticket. If you refuse, stage 4 is scheduled ten minutes earlier so it cannot arrive late.

The earlier "Journey started" action is removed. Copy and share live on the ticket screen, and Android leaves one notification button free if you later want a Copy reference action.

## 8. Notes, Tasks and Document Vault

All three are core modules, kept deliberately small: quick to open, quick to add to, nothing to set up.

### Notes

| Feature | Detail |
| --- | --- |
| Create and edit | A title and a plain-text body with simple lists and checkboxes, saved as you type |
| Organise | Folders one level deep, pin to top, archive, delete with Undo |
| Quick capture | From the capture sheet, by sharing text into the app, or with "Save to Kanakku" in another app's text-selection menu on Android |
| Note to task | Long-press a line to turn it into a task |
| Order | Most recently edited first, filtered by folder |

Not included: images inside notes, rich formatting, shared notes.

### Tasks

| Feature | Detail |
| --- | --- |
| Create | Title, optional note, due date and optional time |
| Reminders | A notification at the due time or a lead you choose, with Done and Snooze |
| Repeat | None, daily, weekly or monthly |
| Views | Today, Upcoming and Completed, with overdue tasks marked |
| On Today | Tasks due today and overdue ones, tickable in place |

Not included: subtasks, priorities, projects.

### Document Vault

| Feature | Detail |
| --- | --- |
| Add | From files, from a camera photo, or by sharing into the app |
| Organise | Categories such as Identity, Finance, Insurance, Travel, Vehicle, Medical and Education, plus your own |
| View | PDFs and images open inside the app |
| Expiry date, optional | A reminder before a passport, licence or policy expires, through the shared reminder engine |
| Export | An explicit action that writes a readable copy where you choose |

How the vault is protected:

| Protection | How |
| --- | --- |
| Encryption at rest | Each file is encrypted with AES-256-GCM under its own key. Those keys are wrapped by a master key held in the Android Keystore. Thumbnails are encrypted too |
| Opening the vault | Fingerprint, face or device PIN each time, with a setting to rely on the app lock alone |
| On screen | Screenshots are blocked and the content is hidden in the app switcher on Android |
| Temporary files | Documents are decrypted in memory or into a private cache that is wiped on close |
| Backup | Vault files are part of the encrypted backup in section 11. Android's automatic cloud backup is switched off for the app, because Keystore keys do not travel to a new phone |

Two limits stated plainly. If the phone is lost and there is no backup, the documents are lost. If the backup passphrase is forgotten, the backup cannot be opened. The vault holds copies, not originals.

## 9. Digital Wellbeing

On Android the app can show screen-time figures much like the system's own, through a documented API and one special permission. On iPhone it cannot, and this plan does not promise it.

### What it shows

- Today's total screen time.
- Time per app, ranked, with each app's name and icon.
- Daily totals for the last seven days, and this week against last week.
- An hour-by-hour pattern for today.
- How many times each app was opened.
- A weekly summary: most-used apps and the heaviest day.
- A small card on Today with the total and the top app.

### How it works on Android

| Topic | Finding |
| --- | --- |
| API | Android's UsageStatsManager provides usage history aggregated by day, week, month and year ([reference](https://developer.android.com/reference/android/app/usage/UsageStatsManager)) |
| Permission | PACKAGE\_USAGE\_STATS is not a normal permission dialog. You switch it on for the app in Settings under Usage access, and the app opens that screen for you the first time you open Wellbeing |
| Sideloaded build on Android 15 and later | Usage access is one of the restricted settings, so it needs the same one-time "Allow restricted settings" step as SMS ([explanation](https://androidauthority.com/android-15-restricted-settings-sideloading-3481098)) |
| History | The system keeps only limited history. The app saves a small daily snapshot of minutes per app, so trends build up from the day you grant access |
| Battery | Figures are read when you open the screen, plus one daily job for the snapshot. No continuous monitoring, no accessibility service |
| App names and icons | Resolved for launchable apps only, without the broad "see all installed apps" permission |
| Accuracy | Totals can differ slightly from the system's own Digital Wellbeing screen, because the two aggregate differently |
| Privacy | The data stays in the app's encrypted database and never leaves the phone |

Not included: app timers, blocking or a focus mode. Those need accessibility or overlay control and are a different product.

### iPhone

Apple's Screen Time API needs a special entitlement, and usage figures are only available inside a sandboxed report extension. An Apple engineer has confirmed that the data cannot be moved out of that sandbox ([thread](https://developer.apple.com/forums/thread/727958)). The app could not store, total or summarise it, and none of it can be tested without an iPhone. Status: **not currently feasible**. The Wellbeing entry is hidden on iOS.

## 10. Offline assistant

The assistant is a command line inside the capture sheet. It understands a fixed set of phrases and answers from your own data. It is rule-based, needs no network, and is not presented as AI anywhere in the app.

Your section 8 is applied in full: no Claude API, no Claude Pro integration, no OpenAI, no other AI service, no free-tier cloud API and no subscription. The proxy, key handling, usage metering and cost tracking are removed from the architecture, the phases and the estimates.

### What it does

| You type | Result |
| --- | --- |
| spent 250 on lunch hdfc upi | An expense draft: 250 rupees, Food, UPI, HDFC Bank |
| lent 5000 to Arun for bike repair | A loan draft |
| Arun paid 2000 | A repayment draft against his oldest loan |
| task call electrician tomorrow 6pm | A task with a reminder |
| remind me to renew insurance on 5 Dec | A task due on 5 December |
| note gate code is 4471 | A note |
| how much did I spend on food this month | A figure calculated from Money |
| spend on HDFC card in October | A figure for that card |
| who owes me | Balances from Lending |
| next trip, tasks today, screen time today | The answer from that module |

Every command that creates something produces a draft you confirm.

- **Text tools.** Clean up spacing, change case, turn lines into a bulleted or numbered list, sort or de-duplicate lines, count words, and pull amounts, dates or phone numbers out of pasted text.
- **Local summaries.** Fixed templates filled from your data: the month so far, lending by person, and the week ahead. These are calculations, not text written by a model.
- **Unknown input.** The assistant says it did not understand and shows examples it does understand.

Under the hood it is a tokeniser, a small set of command patterns, a local parser for dates and amounts such as "tomorrow", "next Monday", "6pm" and "2.5k", and a lookup against your own people, accounts and categories. It is plain Dart with unit tests, and a new command is a new pattern.

### Removed because they need a language model

Grammar correction, rewriting in another tone, summarising arbitrary text, open-ended questions, and AI extraction from messages or tickets. A rule-based version of any of these would be poor, so none is offered.

### One fact for your decision, with nothing built on it

Android offers on-device proofreading, rewriting and summarising through ML Kit's GenAI APIs. They process text locally, work without a connection and carry no server cost, which is within every rule in your section 8. They exist only on specific phones, including Pixel 9 and later, Galaxy S25 and later, and selected OnePlus, Xiaomi, vivo and OPPO models ([device list](https://developers.google.com/ml-kit/genai)). This is not in the plan. If your phone is on the list and you want it, it would be a small add-on labelled as on-device AI. If not, nothing changes.

## 11. Privacy, backup and shared foundations

These apply to every module and are built before the modules that depend on them.

| Feature | Behaviour |
| --- | --- |
| Review Inbox | One place for every unconfirmed item from SMS, sharing or commands. Nothing leaves it without your decision |
| Encrypted database | SQLCipher from the first build, with the key held in the Android Keystore |
| Encrypted backup | One archive containing the database, vault files and ticket documents, encrypted with a key derived from a passphrase you choose |
| Where backups go | Wherever you pick in the system file picker. That can be a cloud-drive folder on the phone, with no account or API inside the app |
| Restore | Checks the archive's version and integrity before replacing anything |
| Backup reminders | A Today nudge after seven days, and an optional weekly automatic backup to a folder you choose |
| App lock | Fingerprint, face or device PIN on opening and after a timeout you set |
| App-switcher privacy | Content hidden and screenshots blocked on Android. On iOS a cover screen is shown when the app leaves the foreground, Not Yet Verified |
| Permissions in context | Each permission is asked at the moment its feature needs it, with a one-sentence reason. Every feature still works in a reduced way if you refuse |
| No internet permission | The app declares no network access, so it has no way to send your data anywhere |
| Logs | Kept on the phone with amounts and message text redacted. Settings has an Export logs button for debugging. There are no health screens |

When each permission is asked:

| Permission | Asked when |
| --- | --- |
| SMS | You switch on transaction or ticket detection |
| Notifications and exact alarms | You create your first reminder or ticket |
| Usage access | You open Digital Wellbeing |
| Camera | You photograph a document |
| Display over other apps | You switch on the floating bubble |
| Biometrics | You switch on the app lock |

### Three shared engines

- **Ledger.** Every money movement goes through it: expense, income, transfer, card settlement, loan and repayment. Modules never write money rows themselves, so the totals cannot disagree.
- **Capture inbox.** Drafts from SMS, sharing and commands use one confirm-or-review flow.
- **Reminders.** Trips, tasks, repayments, document expiry and backup nudges use one scheduler. It rebuilds its schedule after a restart and whenever the app opens.

## 12. Removed and postponed

Removed features have no tasks, no time and no place in the architecture. Postponed ideas live only in TO-DO.md.

### Removed

| Feature or approach | Note |
| --- | --- |
| Payment hand-off to Google Pay or other payment apps | The app records payments and never starts one |
| Google Sheets as a live backend | Data lives in the local encrypted database |
| PNR scraping | Booking status is updated by hand |
| Paid booking APIs | Tickets come from manual entry, SMS and sharing |
| Custom keyboard |  |
| Interest calculations |  |
| Unsupported SMS access techniques | No notification scraping and no accessibility reading |
| Paid AI integrations and cloud AI dependencies | Includes the proxy, API key, usage metering and cost tracking |
| Global Search | No search across modules |
| Parser Health and Reminder Health screens | Logs can be exported from Settings; nothing more |
| Automatic saving of detected transactions | Replaced by the confirmation card |
| "Journey started" action and time-based clearing of the ticket reminder | Replaced by Done |

### Postponed in TO-DO.md

| Item | Why it waits |
| --- | --- |
| Multi-device sync | Needs accounts, a server and conflict handling |
| Google Play release | SMS access needs a policy exception; usage access and overlay need store review and disclosures |
| iOS verification on a real iPhone | No device available. Covers reminders, sharing into the app, the app-switcher cover and widgets |
| iOS Shortcuts bridge for bank messages | A user-made automation could pass message text to the app, but it cannot be verified without an iPhone |
| Tracking money you owe | Not requested; lending covers money owed to you |
| Journey chip in the status bar on Android 16 | Depends on your phone's Android version |
| Bank statement CSV import | Useful for history, not needed for daily use |
| App timers or a focus mode in Digital Wellbeing | A separate feature with heavier permissions |
| Images and rich formatting in notes | Keeps Notes simple for now |

Optional enhancements that are still in the roadmap sit in Phase 10: budgets, spending trends, recurring items, upcoming debits and ticket text recognition. None of the core modules depends on them.

## 13. Technical architecture and feasibility

The whole product runs on the phone: a Flutter app organised by feature, one encrypted database, one encrypted file store, and a thin layer of Kotlin for what Flutter cannot reach. There is no server.

&#91;embedded content: App architecture · 4 layers, no server\]

Each layer depends only on the one below. Features never touch the database, the file store or the operating system directly.

### Decisions and why they fit

| Area | Decision | Why it fits this app |
| --- | --- | --- |
| Structure | One app, organised by feature, with presentation, domain and data layers inside each feature | Nine modules built by one person. Each can be built and tested in its own phase |
| Shared logic | Ledger, capture inbox and reminders live in a core layer that every feature calls | One set of money rules and one scheduler, so modules cannot disagree |
| State management | Riverpod | The database emits live query results. Riverpod turns them into screen state with little glue and also provides dependency injection, so no second package is needed. BLoC is equally sound if you prefer it |
| Database | Drift on SQLite, encrypted with SQLCipher | A ledger is sums, joins and date ranges. Drift gives typed queries and tested migrations. Hive and Isar lack relational queries |
| Money values | Whole paise in integer columns; totals computed when read, never stored | An edit or a late SMS corrects every total automatically |
| Files | An encrypted file store for vault documents and ticket files; the database holds their details and wrapped keys | Large files stay out of the database; backup copies both |
| Native code | One in-repo plugin with a typed bridge. Kotlin for SMS, the ticket notification, usage access, sharing, the bubble and widgets. Swift only for iOS sharing and widgets, later | The risky parts are native. Writing them yourself uses your experience and avoids depending on small third-party plugins |
| Notifications | A scheduling package for timed reminders and action buttons; Kotlin for the final ticket layout. One notification per trip, one channel per kind | Meets the update-in-place and stay-until-Done requirements |
| Background work | Event-driven only: SMS broadcast, alarms, restart, and one daily job | No polling and no permanent service in the core app |
| SMS parser and command parser | Two plain-Dart packages with fixture tests | They hold the most logic and are the easiest parts to test thoroughly |
| Testing | Unit tests for parsers, ledger rules and reminder timing with a fake clock; database and migration tests; visual tests for components; a few end-to-end flows | Money and reminders must be provably right |
| Build pipeline | Analyse, test, build both Android flavours, and compile iOS without signing on every change | Keeps the iOS build from breaking without an iPhone |
| Backend | None | Nothing to host, pay for or secure |

### Feasibility summary

| Topic | Verdict | Condition or limit |
| --- | --- | --- |
| SMS detection | Feasible on Android in the personal build | Play approval not assumed; none on iOS |
| Ticket notification that stays until Done | Feasible on Android | iOS shows a standard notification that cannot be pinned |
| Digital Wellbeing | Feasible on Android | Needs usage access; not feasible on iOS |
| Document encryption | Feasible | Standard platform cryptography |
| Encrypted backup to a folder you choose | Feasible | Through the system file picker, with no cloud API |
| Offline assistant | Feasible as rules | Language features are out |
| Home-screen widgets | Feasible | Buttons and read-only figures; no typing inside a widget |
| Floating bubble | Feasible on Android, with a cost | Details below |
| Fully offline | Feasible | The app ships without the internet permission |

### The floating bubble, honestly

A bubble over other apps needs the "Display over other apps" permission, which is a restricted setting for sideloaded apps on Android 15 and later ([explanation](https://androidauthority.com/android-15-restricted-settings-sideloading-3481098)). It also needs a foreground service for as long as the bubble is shown, which Android displays as a permanent notification. That is the only always-on component in the product.

It is therefore opt-in, off by default, removed while the screen is off, and built last. Android's own Bubbles feature is reserved for conversations, so it is not used. A bubble is not possible on iOS.

### Battery and consistency

- Nothing polls. Work happens when an SMS arrives, an alarm fires, the phone restarts, or once a day.
- SMS parsing and import run off the main thread.
- Every money change is one database transaction through the ledger engine.
- Each SMS has a unique identity hash, so importing twice is harmless.
- Reminders are derived from records and can always be rebuilt from them.

Targets to measure, not results: a usable Today screen within 1.5 seconds of a cold start on a mid-range phone, and smooth scrolling with 10,000 transactions.

## 14. Android and iOS compatibility matrix

Android is where everything is built, tested and used. On iOS, "Not Yet Verified" means the feature comes from shared Flutter code and compiles, but has never run on a real iPhone. "Coming Soon" means it needs Swift work that waits for a device.

| Feature | Android | iOS | Class |
| --- | --- | --- | --- |
| Today dashboard | Yes | Not Yet Verified | Cross-platform |
| Expenses with accounts and cards | Yes | Not Yet Verified | Cross-platform |
| Lending and repayments | Yes | Not Yet Verified | Cross-platform |
| Notes | Yes | Not Yet Verified | Cross-platform |
| Tasks with reminders | Yes | Not Yet Verified; at most 64 pending notifications per app ([Apple engineer](https://developer.apple.com/forums/thread/811171)) | Cross-platform |
| Tickets and documents entered by hand | Yes | Not Yet Verified | Cross-platform |
| Offline assistant | Yes | Not Yet Verified | Cross-platform |
| Encrypted database, backup and restore | Yes | Not Yet Verified | Cross-platform |
| App lock | Yes | Not Yet Verified | Cross-platform |
| Paste a message to get a transaction card | Yes | Not Yet Verified | Cross-platform |
| Automatic SMS detection for payments and tickets | Yes, personal build | Not possible | Android-specific |
| Transaction card as a notification | Yes | Not applicable | Android-specific |
| "Save to Kanakku" from selected text | Yes | No equivalent | Android-specific |
| Floating bubble | Yes, opt-in, final phase | Not possible | Android-specific |
| Four-stage reminder as one updating notification | Yes | Separate notifications in one group | iOS-limited |
| Final ticket notification that stays until Done | Yes | A standard notification that cannot be pinned | iOS-limited |
| Sharing a file or text into the app | Yes | Coming Soon; needs a Swift share extension | iOS-limited |
| Hiding content in the app switcher | Yes, and screenshots are blocked | Cover screen only, Not Yet Verified | iOS-limited |
| Home-screen widgets | Yes, final phase | Coming Soon; needs a Swift widget | iOS-limited |
| Digital Wellbeing | Yes | Hidden | Not currently feasible on iOS |

## 15. Phased roadmap

Thirteen phases, core modules first, optional enhancements after them, and widgets with the floating bubble last. Estimates are focused days of about six hours and carry roughly 30% uncertainty either way. No time is allocated to anything removed in section 12.

&#91;embedded content: Roadmap · 13 phases, 4 release gates\]

Each diamond is a release gate reached when the phase before it passes its checks. Day counts are cumulative.

### Phase 0: Foundation and spikes (6 days)

| Item | Detail |
| --- | --- |
| Objective | Prove the riskiest native pieces on your own phone and set up the skeleton everything else builds on |
| Features | Project with personal and store flavours; build pipeline including an iOS compile check; encrypted database opening an empty schema; native bridge skeleton. Four spikes: SMS receiver and inbox read; a ticket notification that shows on the lock screen, stays until Done and survives a restart; reading app usage; encrypting a file with a Keystore key |
| Technical dependencies | Your phone model and Android version; about 200 real bank and ticket SMS for test fixtures; your answers in section 19 |
| Risks and platform restrictions | A manufacturer's battery policy may delay the receiver or alarms. The restricted-settings step differs between Android versions |
| Tested on Android | All four spikes, on your phone |
| Needs an iPhone | Nothing. The iOS project only has to compile |

### Phase 1: Design system and Today shell (7 days)

| Item | Detail |
| --- | --- |
| Objective | Make the look real before features exist, so later screens are assembled from finished parts |
| Features | Colour, type, spacing and motion tokens; core components; five-tab shell; Today with empty states; capture sheet shell; light and dark themes |
| Technical dependencies | Approved mockups of the key screens |
| Risks and platform restrictions | Custom components cost more than stock ones, so the component list is fixed up front |
| Tested on Android | Component gallery and visual tests in both themes |
| Needs an iPhone | A visual check on a real device. Until then, Not Yet Verified |

### Phase 2: Expenses with UPI and Credit Card (9 days)

| Item | Detail |
| --- | --- |
| Objective | A manual expense tracker you can use every day, with data that is safe |
| Features | Bank accounts and cards with nickname, last four digits and default; two-method entry; categories; totals by period, category, method, account and card; editing; settlement, refund, transfer and income rules; encrypted backup and restore; app lock; app-switcher privacy |
| Technical dependencies | Phase 1 components. The ledger engine is built here |
| Risks and platform restrictions | The backup format must carry a version from its first release |
| Tested on Android | Everything, including restore onto a clean install |
| Needs an iPhone | File picker, biometric lock and cover screen. Not Yet Verified |

### Phase 3: SMS capture and Review Inbox (10 days)

| Item | Detail |
| --- | --- |
| Objective | Payments arrive as cards that you confirm |
| Features | SMS setup with the restricted-settings guide; first-run import; receiver and inbox scan; templates for your banks; method and account identification; duplicate matching; the transaction card on Today, in the inbox and as a notification; "Choose" for uncertain fields; paste or share a message as the alternative; merchant memory |
| Technical dependencies | The SMS spike; your fixture messages; your list of banks and cards. The capture inbox engine is built here |
| Risks and platform restrictions | Formats from banks you do not use are untested. Templates break when a bank rewords. A message deleted before the scan is lost. This flavour is not for Google Play |
| Tested on Android | A replay over your own inbox, measured against the 95% target |
| Needs an iPhone | Only the paste path exists on iOS. Not Yet Verified |

### Phase 4: Lending and repayments (6 days)

| Item | Detail |
| --- | --- |
| Objective | Replace the mental list of who owes what |
| Features | Everything in section 6: people, loans, monthly and ad hoc repayments, balances, history, reminders, statement, suggested repayment from a bank credit |
| Technical dependencies | The ledger engine from Phase 2 and the SMS pipeline from Phase 3. The first version of the reminder engine is built here |
| Risks and platform restrictions | Matching a name in an SMS to a person is fuzzy, so it is only ever a suggestion |
| Tested on Android | Everything, including a check that lending never changes spending totals |
| Needs an iPhone | Reminder notifications. Not Yet Verified |

### Phase 5: Travel tickets and reminders (10 days)

| Item | Detail |
| --- | --- |
| Objective | Tickets are stored, and the final ticket is on your lock screen 15 minutes before departure |
| Features | Manual tickets and planned trips; ticket documents and the ticket screen; ticket detection from SMS, with later messages updating the same ticket; share to app; the four stages; the final notification with Show Ticket and Done; re-posting after a restart; the exact-alarm permission flow |
| Technical dependencies | The notification spike; the reminder engine; the SMS pipeline. The encrypted file store is built here and reused by the vault |
| Risks and platform restrictions | Refusal of exact alarms. Manufacturer battery policies. Ticket SMS wording varies far more than bank SMS. What shows on the lock screen depends on your phone's settings |
| Tested on Android | Stage timing with a fake clock in tests, then real trips on your phone and one other brand |
| Needs an iPhone | Reminder behaviour is Not Yet Verified. Sharing into the app is Coming Soon |

### Phase 6: Notes and Tasks (8 days)

| Item | Detail |
| --- | --- |
| Objective | Capture a thought or a to-do in seconds, and see what is due on Today |
| Features | Everything in section 8 for Notes and Tasks, including quick capture, share and text-selection entry, repeat rules and reminder actions |
| Technical dependencies | The reminder engine; the capture sheet; Kotlin entry points for share and selected text |
| Risks and platform restrictions | Scope creep is the main risk. Monthly repeats need care at month ends |
| Tested on Android | Everything |
| Needs an iPhone | Task reminders are Not Yet Verified. Sharing into the app is Coming Soon |

### Phase 7: Document Vault and backup completion (6 days)

| Item | Detail |
| --- | --- |
| Objective | Keep personal documents encrypted, viewable and recoverable |
| Features | Everything in section 8 for the vault; vault files added to the backup archive; optional weekly automatic backup; document expiry reminders |
| Technical dependencies | The encrypted file store from Phase 5; the app lock; the reminder engine |
| Risks and platform restrictions | Memory use when decrypting large files. A forgotten backup passphrase cannot be recovered |
| Tested on Android | Encryption round trips and a restore onto a clean install |
| Needs an iPhone | Key storage and file import. Not Yet Verified |

### Phase 8: Digital Wellbeing (6 days)

| Item | Detail |
| --- | --- |
| Objective | See where your phone time goes, inside the same app |
| Features | Everything in section 9: usage access setup, today and seven-day views, per-app breakdown, hourly pattern, weekly summary, the Today card, daily snapshots |
| Technical dependencies | The usage spike; the daily job; chart parts from the design system |
| Risks and platform restrictions | Usage access is a restricted setting for sideloaded apps. Manufacturers differ in what they report. History starts on the day access is granted |
| Tested on Android | A week of figures compared with the system's own screen-time view on your phone |
| Needs an iPhone | Not built for iOS |

### Phase 9: Offline assistant (5 days), completes the core product

| Item | Detail |
| --- | --- |
| Objective | Type one line to create or look up anything in the app |
| Features | Everything in section 10: create commands, questions about your own data, text tools, local summaries, examples for unknown input |
| Technical dependencies | All earlier modules, because commands create drafts in them and read from them |
| Risks and platform restrictions | People phrase things in many ways. The grammar stays small and the app shows what it understands |
| Tested on Android | A fixture file of phrases with expected results |
| Needs an iPhone | Not Yet Verified, though it is plain Dart with no platform code |

### Phase 10: Optional enhancements (6 days)

| Item | Detail |
| --- | --- |
| Objective | Add analysis on top of a finished core. Any item here can be dropped without affecting the rest |
| Features | Monthly and category budgets with alerts; spending trends; recurring items; upcoming debits; on-device text recognition to pre-fill a ticket from an image |
| Technical dependencies | Money and the reminder engine |
| Risks and platform restrictions | Chart polish can absorb unlimited time, so it is capped at three chart types. Text recognition is unreliable on photos of paper tickets |
| Tested on Android | Everything |
| Needs an iPhone | Not Yet Verified |

### Phase 11: Hardening and release (7 days)

| Item | Detail |
| --- | --- |
| Objective | Make the app trustworthy enough to rely on daily |
| Features | Performance pass against the targets; accessibility pass; first-run onboarding and permission walkthrough; signed personal APK from the pipeline; README and decision records; a review of TO-DO.md |
| Technical dependencies | All earlier phases |
| Risks and platform restrictions | Polish is time-boxed. Android developer verification for sideloaded apps is planned to roll out globally in 2027, and a free limited-distribution account covers a small number of devices ([guide](https://developer.android.com/developer-verification/guides)) |
| Tested on Android | A full regression checklist and a 24-hour battery check with detection switched on |
| Needs an iPhone | Nothing new. The app's About screen states that iOS is Not Yet Verified |

### Phase 12: Home-screen widgets and floating bubble (7 days), final phase

| Item | Detail |
| --- | --- |
| Objective | Reach the app's most-used actions without opening it |
| Features | Widgets for quick add, next trip, tasks today and month so far; the opt-in floating bubble that opens the capture sheet; a regression pass |
| Technical dependencies | Everything before it; Kotlin widget layouts; the overlay permission; a foreground service for the bubble |
| Risks and platform restrictions | Overlay is a restricted setting for sideloaded apps. The bubble's service shows a permanent notification and some manufacturers stop it. Widgets cannot contain a text field |
| Tested on Android | Everything |
| Needs an iPhone | Widgets are Coming Soon. A bubble is not possible on iOS |

## 16. Effort and milestones

The core product is complete at day 73 and Android v1.0 at day 86. A build worth using every day, Expenses with SMS capture, exists at day 32.

| Milestone | Phases | Focused days | At 15 hours a week | At 25 hours a week |
| --- | --- | --- | --- | --- |
| Money with SMS capture | 0 to 3 | 32 | 13 weeks | 8 weeks |
| Core product, all nine modules | 0 to 9 | 73 | 29 weeks | 18 weeks |
| v1.0 Android | 0 to 11 | 86 | 34 weeks | 21 weeks |
| v1.1 with widgets and bubble | 0 to 12 | 93 | 37 weeks | 22 weeks |

How Android v1.0 moved from 74 days to 86:

| Change | Days |
| --- | --- |
| Notes and Tasks, Document Vault and Digital Wellbeing added | +20 |
| Cloud assistant and proxy replaced by the offline assistant | -4 |
| Budgets and widgets phase reduced to optional enhancements, with widgets moved out | -2 |
| Global Search removed from the Money phase | -1 |
| Borrowing removed from the Lending phase | -1 |

The final phase adds 7 days for widgets and the bubble. The former 8-day iOS phase is gone; keeping the iOS build compiling is part of each phase.

Running cost is zero. There is no API, no server and no subscription. Fees arise only if you later publish to a store.

## 17. Risks and dependencies

The largest risks are device behaviour on Android and the size of the scope for one developer. Neither is a reason to change the plan, and each has a response built into a phase.

| Risk | Effect | Response |
| --- | --- | --- |
| A manufacturer's battery policy delays the SMS receiver or alarms | Late cards or a late reminder | The inbox scan catches missed messages. A missed reminder is detected on next open with a one-time guide to exempt the app. Proven on your phone in Phase 0 |
| Exact alarms refused | The 15-minute reminder loses precision | It is scheduled ten minutes earlier so it cannot be late |
| Restricted settings on a sideloaded build | SMS, usage access and the bubble stay off until allowed | One guided step covers all three |
| A bank rewords its SMS | The card shows "Choose" for some fields | Generic extractor, then a template update with new fixtures |
| Google Play refuses SMS access | No store version with detection | The personal build is the product. Play is in TO-DO.md |
| Android tightens sideloading | More friction installing your own build | Register a limited-distribution developer account before it applies in India |
| No iPhone | iOS problems go unnoticed | The build compiles on every change, and nothing on iOS is described as verified |
| Lost phone or forgotten backup passphrase | Permanent loss of data | Backup nudges, optional weekly backup, and a clear warning when the passphrase is set |
| Nine modules for one developer | Slipping dates | Fixed "not included" lists per module, one droppable optional phase, and approval after every phase |
| Only two payment methods | Cash and other bank debits fall outside spending totals | Your confirmation is requested in section 19 |
| Usage figures vary between manufacturers | Wellbeing totals differ from the system's | Compared over a week in Phase 8 and stated in the screen |
| The bubble's service is stopped by the system | The bubble disappears | Opt-in, restarted when the app opens, built last |

### Dependencies

- Your phone model and Android version.
- The banks, cards and ticket services that send you SMS.
- About 200 real messages, with digits scrambled, as parser fixtures.
- Approved mockups before Phase 1.
- Your answers in section 19.

The plan needs no account, API key, paid service or Mac.

## 18. Design direction

The interface stays quiet and lets numbers, tickets and documents be the decoration. Your two mockups set the reference: a dark surface, a large amount, right-aligned values, a two-part UPI and Credit Card control, an outlined Review button and a filled Looks Good button.

| Element | Direction |
| --- | --- |
| Type | One bundled typeface so Android and iOS match, with tabular figures for every amount |
| Colour | Neutral surfaces, text in three strengths, one accent per module. Red only for overdue; green only for money in |
| Shape and space | A 4-point grid, generous margins, rounded cards, depth through tonal layers instead of shadows |
| Motion | Short and purposeful: sheets, card-to-detail transitions, a haptic tick on Looks Good. Honours reduce-motion |
| Touch | A custom press state instead of the Material ripple; swipe on rows; 48 dp minimum targets |
| Themes | Dark and light designed separately, dark first |
| Accessibility | Text contrast of at least 4.5 to 1, text scaling to 130%, spoken labels on amounts |

| Module | Accent | Signature element |
| --- | --- | --- |
| Today | Neutral | A short stack of cards that is empty when nothing needs you |
| Money | Green | Large numerals over plain rows, with a UPI or CC chip on each |
| Lending | Amber | A person page that reads like a note with a running balance |
| Travel | Indigo | Pass-style ticket cards with the reference in monospace |
| Notes and Tasks | Warm grey | Plain text first; a checkbox is the only ornament |
| Vault | Slate | Document tiles behind a lock |
| Wellbeing | Teal | Bars for days, a ranked list for apps |
| Assistant | None | A plain command line. No sparkle icons and no gradient, because it is not AI |

After you approve this revision, the next step is mockups of the key screens in dark and light for your review. No code is written before that.

## 19. Questions that still need your answer

Your confirmed decisions are applied and are not reopened here. These are the points your instructions leave open. Each states what I will do if you say nothing.

- [ ] **Cash and other bank debits.** With only UPI and Credit Card, should cash stay untracked, and may ATM, debit-card, net-banking and auto-debit messages appear in the Review Inbox to be saved under their bank account or dismissed?

  If you say nothing: yes to both.
- [ ] **A filter box inside one list.** Global Search is removed. May the Notes list have its own text filter?

  If you say nothing: no text filter anywhere; lists filter by folder, category, account and date only.
- [ ] **Your phone and services.** Which phone and Android version do you use, and which banks, cards, bus operators and booking apps send you SMS?

  Phase 0 cannot start without this.
- [ ] **Test messages.** Can you export about 200 real bank and ticket messages for me to scramble into fixtures?
- [ ] **On-device language features.** If your phone is on the supported list in section 10, do you want proofreading and summarising as an add-on?

  If you say nothing: not built.
- [ ] **Reminder clock times.** Are 19:00 the evening before and 07:00 on the travel day right for stages 1 and 2?

  If you say nothing: those defaults, adjustable in Settings.
- [ ] **State management.** Riverpod, or BLoC if you prefer it.

  If you say nothing: Riverpod.
- [ ] **Name.** Kanakku.

  If you say nothing: Kanakku as a working name.
- [ ] **Your time.** How many hours a week can you give to review and device testing?

  This decides which column of the effort table applies.

## Sources

Pages opened on 13 and 14 Nov 2026. Platform policies change, so re-check before acting on them.

- [Google Play: use of SMS or Call Log permission groups](https://support.google.com/googleplay/android-developer/answer/10208820?hl=en)
- [Google Play: permissions and APIs that access sensitive information](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en)
- [Android Authority: restricted settings for sideloaded apps in Android 15](https://androidauthority.com/android-15-restricted-settings-sideloading-3481098)
- [Android Developers: Android 14 behaviour changes, non-dismissible notifications](https://developer.android.com/about/versions/14/behavior-changes-all?hl=en)
- [Android Developers: exact alarms denied by default](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- [Android Developers: UsageStatsManager reference](https://developer.android.com/reference/android/app/usage/UsageStatsManager)
- [Android Developers: developer verification](https://developer.android.com/developer-verification/guides)
- [Google: ML Kit GenAI APIs overview and device list](https://developers.google.com/ml-kit/genai)
- [Apple Developer Forums: Device Activity data cannot leave the extension sandbox](https://developer.apple.com/forums/thread/727958)
- [Apple Developer Forums: 64 pending notification limit](https://developer.apple.com/forums/thread/811171)
- [SMS Alert knowledge base: TRAI header suffixes](https://kb.smsalert.co.in/?p=2270)

Two caveats. The UsageStatsManager page did not load in full, so how long the system keeps usage history is to be measured in the Phase 0 spike. Statements about iOS notification behaviour come from platform knowledge and are untested, which is why they are marked Not Yet Verified.
