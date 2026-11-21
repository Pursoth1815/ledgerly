# Personal App — Product Proposal & Phased Roadmap

Nov 16, 2026 · @Pursoth · Revision 3.2

## Summary

This is revision 3.2 of the proposal. It keeps revision 2's scope, folds in every decision from six rounds of design review on the mockups ([docs/mockups](docs/mockups/README.md)), adds your answers of 16 November (cash, reminder times, the capture sheet and your phone), and records the architecture agreed in Phase 0A (section 13). It describes an Android-first, fully offline personal app built on capture, confirm, remember, with nine core modules and no paid or cloud dependency of any kind.

- **Modules.** Today, Expenses, Lending, Travel, Notes, Tasks, Document Vault, Digital Wellbeing and an offline assistant. Notes, Tasks and the Vault are core, not deferred.
- **Navigation.** Five tabs: Today, Money, Travel, Planner (Notes and Tasks) and More (Vault, Screen time and settings).
- **Expenses.** Three payment methods: UPI, Credit Card and Cash. A credit card paid by UPI QR counts as Credit Card. Cash comes from one Cash in hand balance, filled by ATM withdrawals you confirm. Accounts and cards are added from a sheet with a searchable bank list.
- **SMS detection.** Feasible on Android in a build you install yourself. Every detected payment becomes a card you confirm, and nothing is saved until you do. Unclear items get a single Review button instead of half-filled choices. Google Play approval is not assumed, and iOS has no equivalent.
- **Lending.** Money lent to friends, with no due dates or overdue state.
- **Travel.** A trip list with train and bus filters, ticket details that match the real railway and bus SMS, and four reminder stages counted from departure, ending with a lock-screen ticket 15 minutes before departure that stays until you press Done.
- **Digital Wellbeing.** Feasible on Android through usage access. Not currently feasible on iOS.
- **Assistant.** One input in the capture sheet that shows what it understood as chips, plus fixed questions answered from your own data. No AI service of any kind.
- **Platform.** Android 15 (API 35) is the minimum. iOS keeps compiling, and everything on it is marked Not Yet Verified because there is no iPhone to test on.
- **Plan.** Thirteen phases. The first is an architecture discussion and the folder structure, then native spikes on your phone. Money with SMS capture at day 39, the full core at day 83, Android v1.0 at day 96, widgets and the floating bubble last at day 103. There are no deadlines; the days only size the work.
- **Postponed.** Multi-device sync and nine other ideas are listed in TO-DO.md and have no time in the roadmap.
- **Architecture.** Feature-first Flutter with Riverpod and go_router, a double-entry ledger in Drift on SQLCipher, Tink encryption with Keystore-protected keys, Kotlin in the app's own Android project, and a resumable encrypted backup (section 13).
- **From you.** Open points in section 19: the text tools and the architecture choices still pending.

## 1. What changed

### Revision 3.2: the architecture agreed in Phase 0A

| Area | Revision 3.1 | Revision 3.2 |
| --- | --- | --- |
| Native code | One in-repo plugin | Kotlin in the app's own Android project, with one typed Pigeon interface and per-flavour source sets |
| Notifications | A scheduling package plus Kotlin | Own Kotlin for alarms and notifications; the Dart reminder engine works out the schedule |
| Background work | Event-driven, no detail | A short-lived headless Flutter engine started by WorkManager, and only one copy of the app writing the database at a time |
| Ledger | Paise, totals computed when read | A double-entry ledger with signed postings, stored payment method, refunds linked to originals, opening and verified balances, edit history and undo (section 13) |
| SQLCipher | SQLCipher | The SQLCipher build bundled by the `sqlite3` Dart package; SQLite3MultipleCiphers in SQLCipher 4 mode as the documented fallback |
| File encryption | AES-256-GCM per file, keys wrapped in the Keystore | Tink streaming encryption (1.24.0), a derived key per file; `AndroidKeysetManager` is not used |
| Backup | One encrypted archive | A versioned index file plus parts, resumable after interruption, read back before it counts, never overwriting the last good backup |
| iOS encryption | Not Yet Verified | Backup and vault encryption are Coming Soon on iOS: they need iOS crypto work, Tink C++ first |
| Name | Not chosen | **Loopd**, from the app's capture → confirm → remember loop. App id `com.pursoth.loopd`, Dart package `loopd` |
| Effort | v1.0 at day 93 | v1.0 at day 96: one day each added to Phase 0B, Phase 2 and Phase 7 |

### Revision 3.1: your answers of 16 November

| Area | Revision 3 | Revision 3.1 |
| --- | --- | --- |
| Cash | Not recorded | A third method, **Cash**, spending from one **Cash in hand** balance. An ATM withdrawal moves money from a bank account to Cash in hand after you confirm it. "Update cash" corrects the balance |
| Travel reminder times | Stages 1 and 2 at 19:00 the evening before and 07:00 | All four stages are counted from departure: 24 hours, 12 hours, 3 hours and 15 minutes before. No travel time setting |
| Task reminders | Morning summary at 08:00 | A daily summary of overdue and today's tasks at a time you choose. Quiet hours apply to tasks only |
| Capture sheet | Open point | Stays on every tab, to be confirmed once the sheet is designed and tested |
| On-device AI text features | Open point | Not built |
| Your phone | Unknown | Tecno Pova Curve 5G |
| Your time | Hours a week asked | No time limit. Estimates size the work; they are not deadlines |
| Effort | v1.0 at day 92 | v1.0 at day 93: one day added to Phase 2 for cash |

### Revision 3: decisions from the design review

Each row comes from the owner's review of the mockups between 14 and 16 November 2026. The round-by-round record is in [docs/mockups/README.md](docs/mockups/README.md).

| Area | Revision 2 | Revision 3 |
| --- | --- | --- |
| Tabs | Today, Money, Travel, Notes, Vault | Today, Money, Travel, **Planner**, **More**. The Vault, Screen time and all settings live in More |
| Today header | Wellbeing and Settings in the corner | Wellbeing and a light or dark **theme switch**. Settings moved to More |
| Review on Today | One card with a link to the inbox | A stack of cards with a count badge ("4 New"). Tapping the stack opens the Review Inbox, which plays the opening animation |
| Unclear detected items | "Choose" in the field and a disabled Looks Good | An orange border and a single orange **Review** button. No pickers on the card |
| Deleting a detected item | Only "Not a transaction" inside Review | A red **delete** icon on every card, with Undo |
| Credit card paid by UPI QR | Would read as UPI | **Credit Card**, shown as "paid by UPI QR". The SMS rule checks for a card before UPI markers |
| SMS sender | Bank from the header | Matched on the six-letter bank code (for example YESBNK). The two-letter prefix is ignored |
| Add expense and transaction details | Two screens | **One shared form** with an add mode and a review mode, and one green "Save ₹amount" button. It opens as a tall sheet, not a page (owner, 18 Nov 2026) |
| Accounts | Active or archived | No archived state. Added from a **sheet** with a searchable bank list and a live card preview |
| Categories | Default set, editable | Managed from More in a sheet: name, twenty-five colours and twenty-five icons, none shared between categories; ones you added can be deleted, their expenses moving to Misc or another category |
| Lending | Due and overdue repayments | **No due dates** by default. Today shows what is still out and what came back |
| Travel | A ticket screen | A **trip list** with All, Train and Bus tabs, and separate train and bus ticket details |
| Notes | Folders, plain cards | **No folders**. Colour cards in two columns; tap shows Pin, Edit and Delete |
| Tasks | Today, Upcoming, Completed | Today shows only overdue and today. Adding a task or note uses a sheet |
| Task reminders | Lead time | Also snooze length, a morning summary and quiet hours |
| Settings screens | Not designed | Backup & restore, Task reminders and Export logs screens, and animated switches |
| About screen | Phase 11 | Postponed to TO-DO.md |
| Minimum Android | Not stated | Android 15 (API 35) |
| First phase | Foundation and spikes; folder structure left out of the plan | **Architecture discussion and folder structure first** (Phase 0A, no phone needed), then the native spikes (Phase 0B) |
| Effort | v1.0 at day 86 | v1.0 at day 92 |

### Revision 2: from the original proposal

Every decision in your final instructions is applied below. Rejected features are gone from the scope, architecture, phases and estimates, not parked.

| Area | Original proposal | Revision 2 |
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

It is an Android-first app for one person, working fully offline, with an Apple-like level of finish. Name: **Loopd** (chosen on 16 November 2026).

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
| Waiting for confirmation | The newest detected item in full, with the others stacked behind it. The badge reads "N New", or "New" for one. Tapping the stack opens the Review Inbox | Review Inbox |
| Trips this week | Each trip in the next seven days, with a train or bus icon. Trains show station codes, class, coach and berth, and chart status; buses show route, vehicle, platform and a call-conductor button | Travel |
| Tasks | Due today and overdue, ticked in place with a small circle that fills green | Tasks |
| Lent to friends | The total still out, each friend's balance and how much came back, and a suggested repayment when a matching bank credit arrives. No due dates | Lending |
| Spending | Today and month so far, split into UPI, Credit Card and Cash, with a Cash in hand row that opens Accounts and cards | Expenses |
| Screen time | Today's total and the top three apps with their icons | Digital Wellbeing, Android only |
| Backup | A nudge when the last backup is more than seven days old | Backup |

The header shows the date above the title, with two buttons on the title line: an hourglass that opens Digital Wellbeing, and a sun or moon that switches between dark and light.

Navigation has five tabs and one capture button.

- **Today**
- **Money**, with two segments: Expenses and Lending
- **Travel**
- **Planner**, with two segments: Notes and Tasks
- **More**, a flexible last tab. It holds the Document Vault, Digital Wellbeing and Settings, and has room for later additions

The capture button is reachable from every tab and opens one sheet for a new expense, loan, trip, note or task, plus the command line described in section 10. It stays on every tab (confirmed by you on 17 November 2026, after trying the sheet in Phase 1). It steps aside while any sheet or dialog is open, and on any full page listed as hiding it; none is listed yet (your decision, 18 November 2026).

The Review Inbox opens from the stack on Today. It holds every item that is detected but not yet confirmed. On opening, its cards start stacked and slide down one after another.

## 4. Expenses: UPI, Credit Card and Cash

The app records expenses and never starts a payment. The entry screen offers three payment methods: UPI, Credit Card and Cash.

Adding an expense by hand:

1. Enter the amount.
2. Choose UPI, Credit Card or Cash.
3. Choose the bank account (for UPI) or the card (for Credit Card). Your default, if you chose one, is already selected. Cash needs no choice: it is paid from Cash in hand, and the form shows what is left after this expense.
4. Choose a category.
5. Save with one green "Save ₹amount" button. Merchant, note and date are optional; the date defaults to today.

The method is where the money comes from. A credit card paid by scanning a UPI QR code is a **Credit Card** expense, shown as "paid by UPI QR".

Adding an expense and reviewing a detected one use **one form**. In review mode it also shows the name the SMS used, a delete icon, "Remember the name and category for this shop", the original message, and "Not a payment · ignore messages like this".

### Accounts and cards

You can add any number of each from the first build. Accounts and cards is a tall sheet, not a page (owner, 18 Nov 2026): More opens it, and Today's Cash in hand row and the Money tab will open the same sheet.

| Field | Bank account, used for UPI | Credit card |
| --- | --- | --- |
| Bank | Chosen from a searchable list (typing "hd" suggests HDFC Bank); a bank not in the list can be added by name | The same list |
| Nickname | For example "Primary", "Salary" or "Investments" | For example "Kiwi" or "Amazon Pay" |
| Last four digits | Of the account number | Of the card number |
| Default | At most one default bank account, only if you choose one | At most one default card, only if you choose one |

An account or card is added from a sheet with a live card preview. The sheet shows which SMS sender code it will be linked to, for example FEDBNK.

The last four digits are how an SMS is tied to the right account or card. There is no archived state: removing an account or card keeps its past transactions under the name they were saved with.

A card used by family members still counts fully in your spending. There is no shared-card state.

### Cash in hand

Cash is one balance, Cash in hand, shown at the top of Accounts and cards and as a row on Today's Spending card. It has no bank, nickname or last four digits.

| Event | What happens |
| --- | --- |
| ATM withdrawal SMS | A card in the Review Inbox: "ATM withdrawal ₹2,000 · HDFC Savings · Moves to Cash in hand". Looks Good records a **transfer** from the bank account to Cash in hand. It is not spending |
| Cash expense | Added by hand with Cash as the method, or from the capture line ("spent 40 on tea cash"). It counts as spending and lowers Cash in hand |
| Cash from someone | A loan repayment or other cash you receive can be recorded into Cash in hand |
| Update cash | You type what is really in your wallet (the button was named Update count until 18 Nov 2026), and that becomes Cash in hand. A new count replaces the last one. The difference is not spending, so the totals only hold what you entered |

The app cannot detect cash spending, because no SMS is sent for it. Cash in hand is therefore only as accurate as what you enter, and Update cash is the correction.

So the flow is: Cash in hand starts at ₹0. Update cash sets it. An ATM withdrawal moves money from the bank account to Cash in hand, and a cash expense lowers it. Anything dated before your latest count is already in that count, so an ATM SMS that Loopd reads after you counted does not add the money twice (your decision, 18 November 2026).

### Tracking and correction

- Totals by day, week and month, by category, by method, and separately for each bank account and each card.
- The Money tab shows them (mockup screens 5a to 5c, 18 November 2026): Day, Week or Month with earlier periods; the total with its UPI, Credit Card and Cash split (a method with ₹0 is left out); a "Spent from" row of mini cards that filters the tab to one account or card; the top five categories; and the expenses by day, each opening Edit expense. "Show all" opens a sheet with every category or every expense for the chosen account or card.
- Any saved expense can be edited: method, account or card, category, amount, date and merchant. This is the manual correction for a wrong automatic guess.
- Categories come with a default set of thirteen (the twelve plus Misc), each with a colour, an icon and this month's spend. From More, a sheet lets you add one with a name, one of twenty-five colours and one of twenty-five icons, or rename and recolour an existing one. No two categories share a colour or an icon, so there are at most twenty-five. Categories you added can be deleted, several at once; their expenses move to Misc unless you choose another. The defaults always stay (owner, 18 Nov 2026).

### Rules that keep the totals right

- Paying a credit card bill is not an expense. The purchases were counted when they were made, so the app records the payment as a settlement outside spending.
- A refund reduces the original expense.
- Money moved between your own bank accounts is not an expense. An ATM withdrawal is a transfer from a bank account to Cash in hand, and is not an expense either.
- Money lent and repaid follows the transfer rules in section 6.
- Money received, such as salary, is recorded against the bank account as income and never mixed into spending.

### Other bank debits

Debit-card swipes, net banking and auto-debits (such as your auto-pay account's) still arrive by SMS. They appear in the Review Inbox against the right bank account, where you either save them under that account or dismiss them. ATM withdrawals go to Cash in hand, as above.

## 5. SMS detection and the transaction card

On Android, in a build you install yourself, the app can detect transaction SMS without any paid service. Every detection ends in a card you confirm. Nothing is saved silently.

### The flow

1. **Detect.** Android wakes a small receiver when an SMS arrives. Every app open also scans the inbox from the last checkpoint, so a late or missed message is still caught. No service runs in the background.
2. **Check it is a transaction.** The message must come from a commercial sender header and contain a transaction verb and an amount. Indian headers have carried a suffix since 6 May 2025: -P promotional, -S service, -T transactional, -G government ([reference](https://kb.smsalert.co.in/?p=2270)). It is a signal, not a guarantee, so the wording is checked too. The same bank arrives under several two-letter prefixes (AX-, AD-, VM-YESBNK-S), which only name the telecom route, so the sender is matched on the six-letter bank code.
3. **Ignore the rest.** OTPs, promotions, failed payments, balance alerts, KYC notices and dispute updates are dropped. OTP text is never stored.
4. **Extract.** Amount, merchant or recipient, date and time, reference number and the last four digits. Banks write dates differently (13-11-2026, 05/11/26, 13Nov26, 03-Nov-26), so each template knows its own format.
5. **Identify the method.** Credit Card when the message names a card, even if it also carries a UPI marker; a card paid by UPI QR ("spent on YES BANK Card X4417 @UPI_shop") is a Credit Card expense. UPI when the message carries UPI markers on a bank account. An ATM cash withdrawal is a transfer to Cash in hand. Otherwise unknown.
6. **Identify the account or card.** The bank comes from the sender code and the last four digits are matched to your saved accounts and cards.
7. **Match existing records.** By reference number first, then by account, amount and date. A message for an expense you already typed in attaches to it as evidence. A repeat of the same payment is dropped.
8. **Show the card.**

[embedded content: SMS to transaction card · 2 triggers, 5 steps, confirmation before saving

Both triggers feed the same scan. A new transaction always stops at the card and waits for you.

### The transaction card

| Element | Behaviour |
| --- | --- |
| Header | A round avatar in the category's colour, the name as the SMS wrote it (for example "MALABAR CORN"), the bank and time, and a red delete icon |
| Amount | Large, for example ₹705.00 |
| Payment source | A strip with a mini card in the bank's colour, the account or card nickname, its last four digits, how it was paid, and a UPI, CC or Cash chip |
| Category | The category learned from earlier payments at that shop. For a new shop, one-tap category chips; choosing one is optional and is remembered with any rename |
| Review | Opens the transaction details, where every field can be edited |
| Looks Good ✓ | Confirms the details and saves the transaction to Money, with Undo |
| Delete | Removes the item from the inbox, with Undo |
| An unclear item | When the method is unknown, or money went to a person (loan or expense?), the card gets an orange border and a single orange Review button. The missing part shows as a dashed "?" strip or a short note. Nothing is half-filled on the card |

The card appears in three places: on Today, in the Review Inbox, and as an Android notification with the same actions, so you can confirm without opening the app. An unconfirmed card stays in the Review Inbox until you act on it. Inside Review you can also choose "Not a payment · ignore messages like this", which removes it and skips similar messages in future.

### Edge cases

| Case | Behaviour |
| --- | --- |
| SMS arrives hours or days late | The card is dated by the time written in the message, so it lands on the correct day and month |
| Bank changes its wording | The bank template misses, a generic extractor tries, and whatever it could not read turns the card into an unclear item with a single Review button |
| Unknown last four digits | The card offers to add the account or card |
| Credit card bill payment | Usually two messages: a bank debit (for example "via UPI to Kiwi Credit") and a card's "payment received" for the same amount. They pair into one settlement, not an expense |
| Money sent to a person | The card asks whether it was money lent or an expense |
| The same message sent twice | The identity hash drops the copy |
| Refund or reversal | Linked to the original expense and shown as refunded |
| Transfer between your own accounts | The debit and credit pair into one transfer |
| ATM withdrawal | A card that moves the amount from the bank account to Cash in hand. Looks Good records a transfer, not spending |
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

The Lending segment answers two questions at a glance: who owes you, and how much has come back. Friends return money monthly or all at once, so there are no due dates and no overdue state.

| Feature | Detail |
| --- | --- |
| People list | Each person with the amount still out and a bar showing how much came back, largest balance first |
| Recording a loan | Person, amount, date, purpose, notes, and the bank account or Cash in hand it was paid from. A UPI payment to a person can become a loan from its card in the Review Inbox |
| Several loans per person | Each loan keeps its own balance; a repayment settles the oldest loan first unless you choose another |
| Repayments | Any amount, any time, in full or in part, into a bank account or Cash in hand |
| Person page | The amount owed, the last repayment, open loans with progress bars, and a history with a running balance |
| Mark received | One tap from the list or the person page |
| History | Every loan, repayment and note for a person, in date order. Corrections show as visible adjustments |
| Statement | A plain-text summary you can share when someone asks what they owe. Nothing is ever sent to the other person by the app |
| Suggested repayment | A bank credit SMS from a borrower is offered as a repayment, on Today and on its card |
| Write off | Closes a balance without recording a false repayment |

The accounting rules are fixed:

- Money lent is a **transfer out**, not an expense.
- A repayment is a **transfer in**, not income.
- Both appear in the bank account's history and in neither spending nor income totals.

People are chosen with the system contact picker, which needs no contacts permission, or typed by name. There are no interest calculations.

## 7. Travel tickets and reminders

A ticket is typed in, detected from an SMS, or shared into the app as a file. Fifteen minutes before departure it is on your lock screen, and it stays there until you press Done.

### The Travel tab

| Part | Detail |
| --- | --- |
| Filter | All, Train and Bus tabs |
| Upcoming | Pass-style cards with a train or bus icon, the route, the departure time and how far away it is, the seat, and a status chip ("Chart prepared", "Booked") |
| Planned trips | A dashed card with "no ticket yet" and a "Book by" date |
| Earlier | Past trips in a compact list |
| Ticket details | One screen for trains and one for buses (below), with Show ticket, Ticket PDF and the four reminder stages |

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
| Journey | Bus, train, flight or other; boarding point; destination; departure date and time; arrival time (optional, as the railway SMS does not carry it) |
| Train | Train number and name, station codes and names, coach, seat or berth, class, PNR, chart and booking status, and the boarding note. The railway SMS carries PNR, train, date, departure time, station codes, class, "P1-S7,80" coach and berth, and chart status |
| Bus | Operator, route, seat, boarding time, and on the travel day the bus number, platform and conductor's phone, which TNSTC sends in a later SMS matched by PNR. A call-conductor button uses that number |
| Booking | Ticket reference, passengers, fare, where it was booked |
| Document | The ticket PDF or image, encrypted on the phone and readable offline |

A trip can also be saved as **Planned** before a ticket exists, with a "book by" reminder. That covers the case of forgetting whether you booked at all. The ticket screen opens full-screen at full brightness for QR checks.

### The four reminder stages

| Stage | When | Purpose |
| --- | --- | --- |
| 1 | 24 hours before departure | Prepare for the journey |
| 2 | 12 hours before departure | Check the journey details |
| 3 | 3 hours before departure | Prepare for boarding |
| 4 | 15 minutes before departure | The final ticket notification |

A trip can leave at any hour, so every stage is counted from the departure time. There are no fixed clock times and no travel time setting, and quiet hours do not apply to travel. A stage whose time has already passed when the ticket is added is skipped. Editing a ticket reschedules every stage and cancelling it removes them.

### The final ticket notification

| Requirement | Android | iOS, Not Yet Verified |
| --- | --- | --- |
| Ticket details | Expanded layout: operator and number, route, departure time, coach and seat, reference | The same details as notification text |
| Visible on the lock screen | Yes, when your lock-screen setting allows notification content. An app setting can hide the details | Depends on the phone's notification preview setting |
| Stays until you dismiss it | Posted as an ongoing notification. On Android 14 and later it cannot be swiped away while the phone is locked and survives Clear all; unlocked, you can still swipe it ([docs](https://developer.android.com/about/versions/14/behavior-changes-all?hl=en)). It is posted once: a ticket swiped away while unlocked stays gone (your choice, 17 November 2026) | Stays in Notification Centre until cleared; it cannot be pinned |
| Not cleared at departure time | No timeout is set and the app never removes it by the clock | Same |
| Show Ticket | Opens the full ticket in the app after unlock. A filled indigo button | Opens the app |
| Done | Clears the notification without opening the app. An outlined button | An action clears it |
| After a restart | Posted again until you press Done | Not verified |
| One notification across stages | Yes. The same notification is updated at each stage | Each stage is a separate scheduled notification in one group. Replacing the earlier one needs the app to be running |

The ticket stays in Travel after the notification is gone.

One Android detail matters at a 15-minute lead. Exact alarms are off by default for new installs on Android 14 and later ([docs](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)). The app asks for that permission when you add your first ticket. If you refuse, stage 4 is scheduled ten minutes earlier so it cannot arrive late.

The earlier "Journey started" action is removed. Copy and share live on the ticket screen, and Android leaves one notification button free if you later want a Copy reference action.

## 8. Notes, Tasks and Document Vault

All three are core modules, kept deliberately small: quick to open, quick to add to, nothing to set up. Notes and Tasks share the **Planner** tab, with a Notes and Tasks switch at the top. The Vault lives in the **More** tab.

### Notes

| Feature | Detail |
| --- | --- |
| List | Colour cards in two columns. Checklists show small tick boxes, and pinned notes show a pin |
| Tap a note | The card presses in slightly, gets a ring in its colour, and shows Pin, Edit and Delete. Delete has Undo |
| Create and edit | A sheet with a large title, a status line ("Checklist · 3 of 4 left"), and either plain text or checklist rows you can tick. Pin and six colours (sand, mint, sky, rose, lilac, lemon) sit below. Saved as you type |
| Organise | Pin to top, a colour for each note, delete with Undo. No folders |
| Quick capture | From the capture sheet, by sharing text into the app, or with "Save to Loopd" in another app's text-selection menu on Android |
| Note to task | Long-press a line to turn it into a task |
| Order | Pinned notes first, then most recently edited |

Not included: images inside notes, rich formatting, shared notes, folders.

### Tasks

| Feature | Detail |
| --- | --- |
| Create | A sheet with the task, optional details, Due (Today, Tomorrow, a date), Remind me, Repeat and a time |
| Reminders | A notification at the due time or a lead you choose, with Done and Snooze. A daily summary of overdue and today's tasks arrives at a time you choose; the app asks for that time the first time you set a task reminder |
| Repeat | None, daily, weekly or monthly |
| Views | Today shows only overdue and today; everything later is under Upcoming; ticked tasks move to Completed |
| Ticking | A small circle that fills green with an animated tick |
| On Today | Tasks due today and overdue ones, tickable in place |

Not included: subtasks, priorities, projects.

### Document Vault

| Feature | Detail |
| --- | --- |
| Add | From files, from a camera photo, or by sharing into the app |
| Organise | Categories with their own icon and colour: Identity, Finance, Insurance, Travel, Vehicle, Medical and Education. "New category" opens a sheet with a name, eight colours and an icon |
| View | PDFs and images open inside the app |
| Expiry date, optional | A reminder before a passport, licence or policy expires, through the shared reminder engine |
| Export | An explicit action that writes a readable copy where you choose |

How the vault is protected:

| Protection | How |
| --- | --- |
| Encryption at rest | Each file is encrypted with Tink streaming AES-256-GCM, with its own key derived for that file. The keyset is protected by a master key held in the Android Keystore. Thumbnails are encrypted too |
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
- A card on Today with the total and the top three apps with their icons, and a tile in More.

### How it works on Android

| Topic                                    | Finding                                                                                                                                                                                                                |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| API                                      | Android's UsageStatsManager provides usage history aggregated by day, week, month and year ([reference](https://developer.android.com/reference/android/app/usage/UsageStatsManager))                                  |
| Permission                               | PACKAGEUSAGESTATS is not a normal permission dialog. You switch it on for the app in Settings under Usage access, and the app opens that screen for you the first time you open Wellbeing                              |
| Sideloaded build on Android 15 and later | Usage access is one of the restricted settings, so it needs the same one-time "Allow restricted settings" step as SMS ([explanation](https://androidauthority.com/android-15-restricted-settings-sideloading-3481098)) |
| History                                  | The system keeps only limited history. The app saves a small daily snapshot of minutes per app, so trends build up from the day you grant access                                                                       |
| Battery                                  | Figures are read when you open the screen, plus one daily job for the snapshot. No continuous monitoring, no accessibility service                                                                                     |
| App names and icons                      | Resolved for launchable apps only, without the broad "see all installed apps" permission                                                                                                                               |
| Accuracy                                 | Totals can differ slightly from the system's own Digital Wellbeing screen, because the two aggregate differently                                                                                                       |
| Privacy                                  | The data stays in the app's encrypted database and never leaves the phone                                                                                                                                              |

Not included: app timers, blocking or a focus mode. Those need accessibility or overlay control and are a different product.

### iPhone

Apple's Screen Time API needs a special entitlement, and usage figures are only available inside a sandboxed report extension. An Apple engineer has confirmed that the data cannot be moved out of that sandbox ([thread](https://developer.apple.com/forums/thread/727958)). The app could not store, total or summarise it, and none of it can be tested without an iPhone. Status: **not currently feasible**. The Wellbeing entry is hidden on iOS.

## 10. Offline assistant

The assistant is a command line inside the capture sheet. It understands a fixed set of phrases and answers from your own data. It is rule-based, needs no network, and is not presented as AI anywhere in the app.

### The capture sheet

| Part | Behaviour |
| --- | --- |
| One input | You type one line. On every keystroke the rules run again and show what they understood as labelled chips, for example AMOUNT ₹250 · CATEGORY Food · PAID WITH UPI · FROM HDFC Savings. Anything not typed falls back to your defaults |
| One button | Its label and colour follow the type: green "Add expense · ₹250", amber "Record loan", teal "Add task", sand "Save note". It creates a draft you confirm |
| Answers in place | A question ("who owes me") shows its answer inside the input card instead of a button |
| Start from | Five round shortcuts (Expense, Loan, Trip, Note, Task) that open each form |
| Ask | Three ready questions with a preview of the answer. Tapping one fills it in |

How it reads a line, in order: the amount (a number, with "k" for thousand), the type from the first word, the category from keyword lists and from shops you have named before, the account from your own banks, nicknames and last four digits, and the method from "upi", "card", "cash" or the account's type. Each step is a few lines of plain Dart and runs in well under a millisecond.

Your section 8 is applied in full: no Claude API, no Claude Pro integration, no OpenAI, no other AI service, no free-tier cloud API and no subscription. The proxy, key handling, usage metering and cost tracking are removed from the architecture, the phases and the estimates.

### What it does

| You type | Result |
| --- | --- |
| spent 250 on lunch hdfc upi | An expense draft: 250 rupees, Food, UPI, HDFC Bank |
| spent 40 on tea cash | An expense draft: 40 rupees, Snacks, Cash |
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

### On-device AI text features: not built

Android offers on-device proofreading, rewriting and summarising through ML Kit's GenAI APIs, on a limited list of phones ([device list](https://developers.google.com/ml-kit/genai)). You decided on 16 November not to build it. It is listed as removed in section 12 and in TO-DO.md.

## 11. Privacy, backup and shared foundations

These apply to every module and are built before the modules that depend on them.

| Feature | Behaviour |
| --- | --- |
| Review Inbox | One place for every unconfirmed item from SMS, sharing or commands. Nothing leaves it without your decision |
| Encrypted database | SQLCipher from the first build, with the key held in the Android Keystore |
| Encrypted backup | A versioned backup (an index file plus parts) containing the database, vault files and ticket documents. It is encrypted with a backup key that your passphrase unlocks through Argon2id; details in section 13 |
| Where backups go | Wherever you pick in the system file picker. That can be a cloud-drive folder on the phone, with no account or API inside the app |
| Restore | Checks the archive's version and integrity before replacing anything |
| Backup reminders | A Today nudge after seven days, and an optional weekly automatic backup to a folder you choose. A backup counts only after it is read back, and the last good backups are never overwritten |
| Backup & restore screen | A status card with Back up now and its progress, where backups are saved, the weekly switch, the passphrase, a size breakdown of what is inside, and Restore with a passphrase warning |
| App lock | Fingerprint, face or device PIN on opening and after a timeout you set |
| App-switcher privacy | Content hidden and screenshots blocked on Android. On iOS a cover screen is shown when the app leaves the foreground, Not Yet Verified |
| Permissions in context | Each permission is asked at the moment its feature needs it, with a one-sentence reason. Every feature still works in a reduced way if you refuse |
| No internet permission | The app declares no network access, so it has no way to send your data anywhere |
| Logs | Kept on the phone with amounts, names, account digits and message text redacted. The Export logs screen picks a time range and which parts to include, shows a redacted preview and the file size, and saves a plain text file where you choose. There are no health screens |

### Settings in the More tab

More opens with two colour tiles, Vault and Screen time, followed by settings in four groups. On and off settings use animated switches.

| Group | Rows |
| --- | --- |
| Money | Accounts and cards, including Cash in hand; Expense categories (opens the category sheet); SMS detection (switch) |
| Reminders | Task reminders (switch; tapping the name opens its screen). Travel has no time setting, because its stages follow the departure time |
| Privacy and backup | App lock; Backup & restore; Export logs |
| Appearance | Dark theme (switch) |

The Task reminders screen sets the default lead (at the time, 10 or 30 minutes, or an hour before), the snooze length, an optional daily summary of overdue and today's tasks at a time you pick (07:00, 08:00, 09:00 or 21:00; 08:00 until you choose), and optional quiet hours from 22:00 to 07:00. These times apply to tasks only. Travel stages, payment cards from SMS and every other alert follow their own rules and arrive when those rules say. A live preview shows how a reminder will look.

When each permission is asked:

| Permission | Asked when |
| --- | --- |
| SMS | You switch on transaction or ticket detection |
| Notifications and exact alarms | You create your first reminder or ticket |
| Usage access | You open Digital Wellbeing |
| Camera | You photograph a document |
| Display over other apps | You switch on the floating bubble |
| Biometrics | You switch on the app lock |

### Shared engines

- **Ledger.** Every money movement goes through it: expense, income, transfer (including ATM withdrawals into Cash in hand), Update cash (setting Cash in hand), card settlement, loan and repayment. Modules never write money rows themselves, so the totals cannot disagree.
- **Capture inbox.** Drafts from SMS, sharing and commands use one confirm-or-review flow.
- **Reminders.** Trips, tasks, the daily task summary, document expiry and backup nudges use one scheduler. Quiet hours apply to task reminders only. It rebuilds its schedule after a restart and whenever the app opens.
- **Backup.** Takes the snapshot, writes and verifies the backup, keeps the retention, and runs the restore checks.

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
| Archived accounts and cards | Removing one keeps its history under the old name |
| Folders in Notes | Notes use colours and pins instead |
| Due dates and overdue state in Lending | Friends repay when they can |
| "Choose" pickers and a disabled Looks Good on unclear cards | Replaced by a single Review button |
| On-device AI text features (ML Kit GenAI proofreading, rewriting, summarising) | Your decision on 16 November |
| Fixed clock times for travel reminders | Every stage is counted from departure |

### Postponed in TO-DO.md

| Item | Why it waits |
| --- | --- |
| Multi-device sync | Needs accounts, a server and conflict handling |
| Google Play release | SMS access needs a policy exception; usage access and overlay need store review and disclosures |
| iOS verification on a real iPhone | No device available. Covers reminders, sharing into the app, the app-switcher cover and widgets |
| iOS Shortcuts bridge for bank messages | A user-made automation could pass message text to the app, but it cannot be verified without an iPhone |
| Tracking money you owe | Not requested; lending covers money owed to you |
| Journey chip in the status bar on Android 16 | Your phone runs Android 16, so it is possible; it waits until you schedule it |
| Bank statement CSV import | Useful for history, not needed for daily use |
| App timers or a focus mode in Digital Wellbeing | A separate feature with heavier permissions |
| Images and rich formatting in notes | Keeps Notes simple for now |
| About screen | Not needed yet; the README states the app's status meanwhile |

Optional enhancements that are still in the roadmap sit in Phase 10: budgets, spending trends, recurring items, upcoming debits and ticket text recognition. None of the core modules depends on them.

## 13. Technical architecture and feasibility

The whole product runs on the phone: a Flutter app organised by feature, one encrypted database, one encrypted file store, and a thin layer of Kotlin for what Flutter cannot reach. There is no server.

The minimum is **Android 15 (API 35)**. Because of that, the restricted-settings step for a sideloaded build, exact alarms being off by default, and lock-screen rules for ongoing notifications always apply, and no code is needed for older versions.

This section is the architecture agreed in the Phase 0A discussion on 16 November 2026. Each decision has a record in [docs/adr](docs/adr/), and the developer guide is [docs/architecture.md](docs/architecture.md). Android is the only implementation target for now; iOS only has to keep compiling.

[embedded content: App architecture · 4 layers, no server

Each layer depends only on the one below. Features never touch the database, the file store or the operating system directly.

### Decisions and why they fit

| Area | Decision | Why it fits this app |
| --- | --- | --- |
| Structure | Feature-first: one folder per business module (today, expenses, lending, travel, notes, tasks, document_vault, digital_wellbeing, capture, settings). Each feature has domain, data and presentation layers only where it has content for them. The tabs are navigation only and live in the app shell, together with the More page | Nine modules built by one person, each in its own phase, without empty layers |
| Boundaries | A feature exposes one public file. Other code imports only that file. Writes that cross modules go through the core engines. A CI script rejects forbidden imports | A rule that is checked does not erode |
| Shared logic | Four engines in `core`: ledger, capture inbox, reminders and backup. Services only wrap the operating system. There is no generic "services" or "utils" folder | One owner for every rule |
| Shared screens | One widget per pattern with a mode, as in the mockups | Fewer screens, and they cannot drift apart |
| State management | Riverpod 3 with code generation. Classes take their dependencies in the constructor; providers only wire them together. No interface-plus-implementation pairs for repositories; a use case only for a flow that spans several owners | Little glue, easy test overrides, no ceremony |
| Navigation | go_router with a five-tab shell and one navigator per tab. Route paths are constants in `core/routing` | Tabs keep their own history; features never import each other's screens |
| Database | Drift on SQLite, encrypted with SQLCipher. The SQLCipher library is the build bundled by the `sqlite3` Dart package (`source: sqlcipher`). One database file with one schema version, tables grouped by owner, one DAO per owner, and only the owner writes its tables | A ledger is sums, joins and date ranges. Drift gives typed queries and generated migration tests |
| Money | A double-entry ledger in whole paise (below). Totals are computed when read, never stored | An edit or a late SMS corrects every total |
| Files | An encrypted file store using Tink streaming encryption, with a separate derived key for each file | Large files never sit unencrypted or whole in memory |
| Native code | Kotlin inside the app's own Android project, not a plugin. One typed interface generated by Pigeon. Code for the personal build only (SMS) lives in that flavour's source set | Per-flavour manifests and permissions come for free; no plugin boilerplate |
| Alarms and notifications | Own Kotlin. The reminder engine (Dart) works out the schedule; Kotlin stores it, sets the exact alarms, re-registers them after a restart, and draws and updates the notifications | One scheduler and one restart path |
| Background work | Event-driven only: an SMS arriving, an alarm, a restart, a daily usage snapshot and the weekly backup. Dart code that must run while the app is closed runs in a short-lived headless Flutter engine started by WorkManager. Only one copy of the app writes the database at a time | No polling and no permanent service in the core app |
| SMS parser and command parser | Two plain-Dart packages with fixture tests | They hold the most logic and are the easiest to test thoroughly |
| Backend | None | Nothing to host, pay for or secure |

### Layers and folders

```text
app/                 start-up, flavour config, router, five-tab shell, More page,
 │                   background entry point (from Phase 0B)
 ▼
features/            one folder per module; each exposes one public file
 │         ╲
 ▼          ▼
core engines         design_system/   (generic UI only, from Phase 1)
(ledger, capture_inbox, reminders, backup)
 │
 ▼
core infrastructure  (database, security, platform, logging, errors, routing, …)
 │                         │
 ▼                         ▼
packages/ (pure Dart)  Kotlin in android/app (reached only through core/platform)
```

| Name | Meaning |
| --- | --- |
| Engine | Owns business rules used by several features, and its own tables. Only an engine writes its tables |
| Service | A thin wrapper over the operating system or input and output. No business rules |
| Repository | Data access for one owner's tables, built on its DAO. A concrete class |
| DAO | The Drift accessor for one owner's tables, used only inside that owner's folder |

The ledger owns accounts, cards, Cash in hand and categories. Their screens live in the expenses feature. The capture inbox owns drafts, the identity hash and merchant memory. The full folder map, the import rules and the naming rules are in [docs/architecture.md](docs/architecture.md).

### The ledger: data model

Every money event is one row in `ledger_transactions` with two or more rows in `postings`.

```text
accounts               id, kind, name, bank_name, bank_code, last4, is_default, created_at, removed_at
                       kind: bank | credit_card | cash | category | income | loan
                             | adjustment | write_off | opening
categories             account_id → accounts, colour, icon, sort_order
ledger_transactions    id, kind, payment_method, channel, occurred_at (UTC ms), local_date,
                       merchant, note, refund_of, revision, created_at, updated_at, deleted_at
                       kind: expense | refund | income | transfer | card_payment | loan
                             | repayment | write_off | adjustment | opening_balance
postings               id, transaction_id, account_id, amount_paise (≠ 0)
                       UNIQUE (transaction_id, account_id)
transaction_sources    draft_id (primary key), transaction_id, role, linked_at      (capture inbox)
balance_checkpoints    id, account_id, as_of, actual_paise, source, note, created_at, deleted_at
transaction_revisions  id, transaction_id, revision, action, snapshot_json, reason,
                       operation_id, changed_at
loans                  account_id → accounts, person_id, purpose                    (lending)
```

**The sign convention.** Every posting says how much moved into (+) or out of (−) one account, and the postings of a transaction always sum to zero. A bank account, Cash in hand or a loan has a positive balance when you have money or are owed money. A credit card has a negative balance for the amount you owe and a positive one for a credit on the card. A category's positive balance is spending, and an income account's negative balance is income.

Examples:

| Event | Postings |
| --- | --- |
| ₹62 by UPI from Primary | Snacks +6200 · Primary −6200 |
| ₹1,299 on the Kiwi card | Shopping +129900 · Kiwi −129900 |
| ₹705 on Kiwi paid by UPI QR | Travel +70500 · Kiwi −70500 (method Credit Card, channel upi_qr) |
| ₹705 card bill paid from Savings | Kiwi +70500 · Savings −70500 (not spending) |
| ₹300 refund of the ₹1,299 order to the card | Kiwi +30000 · Shopping −30000 |
| ₹2,000 at an ATM | Cash in hand +200000 · Savings −200000 (not spending) |
| ₹5,000 lent to Arun | Loan (Arun) +500000 · Savings −500000 |
| ₹1,500 of it repaid | Primary +150000 · Loan (Arun) −150000 |
| ₹60,000 salary | Salary account +6000000 · Salary income −6000000 |

Each loan is its own account, so "oldest loan first" is written directly into the postings. A write-off moves a loan balance to a written-off account, which is never spending.

**Payment method.** `payment_method` is stored on its own, next to the funding account (the posting that is not a category) and the channel (how the SMS says it happened). The ledger rejects a combination that does not fit:

| payment_method | Funding account | Set by |
| --- | --- | --- |
| upi | bank | The form and SMS |
| credit_card | credit_card | The form and SMS |
| cash | cash | The form and the capture line |
| debit_card, net_banking, auto_debit | bank | SMS only; no new button in the form |

It is required for expenses, refunds, loans and repayments, and empty for the other kinds. The three SMS-only methods count as UPI in Today's UPI, Credit Card and Cash split and in every total by method, because Loopd has only those three methods (your decision, 17 November 2026); the stored method still records how the money left.

**Refunds.**

- A refund always points to its original purchase (`refund_of` is required), and the total refunded can never exceed the original. A credit SMS with no known original stays in the Review Inbox as an unclear item.
- The refund's `payment_method` and funding account describe where the money actually came back: the same card, a bank account, or cash.
- Spending reports attribute a refund to the **original's** category, method and card. Balances use the **actual** destination. Example: a ₹1,299 card purchase refunded to Savings by UPI gives Savings +129900 and Shopping −129900. Shopping and the card's spending both fall to zero. The card still shows ₹1,299 owed, because that is still true, and the UPI total does not change.
- A refund counts in the month of the original purchase, so a month's total never changes because of a later month. There is no cash-flow mode (your decision, 18 November 2026, replacing the switch chosen on 17 November). In the Money tab's list, a refund still appears on the day it came back.
- A purchase with live refunds cannot be deleted directly. You see its refunds and choose to edit the purchase, or to delete it together with its refunds as an explicit action. Nothing is removed silently.

**Many SMS, one transaction.** The capture inbox links drafts to transactions:

```sql
CREATE TABLE transaction_sources (
  draft_id       TEXT PRIMARY KEY REFERENCES capture_drafts(id),
  transaction_id TEXT NOT NULL REFERENCES ledger_transactions(id),
  role           TEXT NOT NULL
                 CHECK (role IN ('primary', 'pair_debit', 'pair_credit', 'evidence')),
  linked_at      INTEGER NOT NULL
) STRICT;

-- At most one primary, one pair_debit and one pair_credit per transaction;
-- any number of evidence links.
CREATE UNIQUE INDEX transaction_sources_one_role
  ON transaction_sources (transaction_id, role)
  WHERE role IN ('primary', 'pair_debit', 'pair_credit');
```

- The primary key on `draft_id` means a draft belongs to at most one transaction.
- A card bill uses `pair_debit` and `pair_credit` on one card payment. An SMS for an expense you already typed in is `evidence`, which changes no money.
- The rule "a single primary, or a pair, but not both" spans several rows, so the ledger engine checks it, and the health check confirms it.
- A draft gets its future transaction id when it is created, so confirming it twice (from the app and from the notification) cannot create two transactions.

**Opening and verified balances.**

- An optional opening balance is an `opening_balance` transaction against an opening account, dated "as of" a day you choose. The tracked balance is the opening balance plus the postings dated after it; older history does not count twice.
- A verified balance is a figure you type in after checking your bank or card app. It is stored in `balance_checkpoints` with the **same sign as the ledger**:
  - bank: positive is money in the account, negative an overdraft
  - card: negative is the amount owed, positive a credit on the card
  - The form asks for "Amount owed" or "Credit on the card" and never asks for a sign.
- The difference shown is the actual balance minus the tracked balance.
- Labels:
  - "Movement since …" when there is no opening balance (never called a balance)
  - "Tracked balance" with an opening balance
  - "Verified … · date" when the latest check matches
  - "Tracked … · Bank says … · ₹… unexplained" when it does not
- Each Update cash sets Cash in hand's balance from that moment: the latest count plus what is dated after it. It is kept as a checkpoint, not a money row, so it is never spending and ₹0 is a valid count. Before the first count, Cash in hand starts at ₹0.

**Edits, undo and reconciliation.**

- Every create, edit, delete and restore adds a row to `transaction_revisions` with a full snapshot. History is never rewritten.
- An edit replaces the postings inside one database transaction and keeps the transaction's id, its SMS links and its refund links.
- A delete is a soft delete.
- Undo applies the previous snapshot as a new revision, and only while nothing has changed since; otherwise it says it cannot undo.
- Reconciliation never creates anything by itself:
  - Cash in hand has no bank to compare with, so Update cash simply sets it; nothing is recorded as an adjustment.
  - A bank or card difference is shown. You add the missing transaction, record a labelled adjustment outside spending, or leave it.
  - Editing anything dated before a checkpoint marks that checkpoint for a recheck.
- Unmatched card-bill halves stay in the Review Inbox. They pair on the same amount within a time window still to be confirmed (proposed ±3 days).

**Guards.**

- Only the ledger can import the ledger DAO (checked in CI).
- Every kind has a fixed posting shape.
- Postings must sum to zero, with at least two of them.
- Amounts are never zero, and an account appears once per transaction.
- Tables are SQLite `STRICT` and foreign keys are on.
- Money is in 64-bit integer paise only.
- A health check (sums, legs, refunds within originals, method matching the funding account) runs in tests, on debug starts and after every restore.

### Keys and encryption

| Key | Created | Stored | Protected by |
| --- | --- | --- | --- |
| Keystore master key (AES-256-GCM) | First launch, inside the Android Keystore | Never leaves the Keystore | Hardware or the secure area of the chip |
| Database key (256-bit random) | First launch | Encrypted blob in app-private storage that is never backed up | The master key, through Tink's `AndroidKeystore` helper |
| Vault keyset (Tink streaming) | First vault file | Encrypted keyset blob | The master key |
| Backup master key | When backup is set up | Encrypted blob, plus a copy wrapped by your passphrase inside every backup | The master key, and your passphrase through Argon2id |

- **Libraries, pinned.** Checked on Maven Central on 16 November 2026: `com.google.crypto.tink:tink-android` **1.24.0**, and `org.bouncycastle:bcprov-jdk18on` **1.86**, used only for Argon2id. 1.87 is the newest release but only five days old; it is taken once it is two weeks old and its release notes are clean. Each library is added in the phase that first uses it.
- **Primitives.**
  - Files and backups: Tink streaming AES-GCM-HKDF (AES-256, 256 KiB segments, chosen from the Phase 0B results on 17 November 2026), with associated data binding each file to its identity.
  - Small secrets: AES-256-GCM in the Keystore.
  - Passphrase: Argon2id at 128 MiB memory and 4 iterations, tuned on your phone (about 1.1 seconds).
- **`AndroidKeysetManager` is not used.** In Tink 1.24.0 it quietly stores keysets unencrypted when the Keystore fails, and it tries to read a keyset as unencrypted when decryption fails. Tink's own documentation advises against relying on it. Instead:
  - Keysets are saved only in encrypted form, through Tink's `AndroidKeystore` helper and encrypted keyset serialisation, which have no unencrypted path.
  - One Kotlin class writes key material, and it has a single, encrypted-only write method.
  - A CI check fails the build on `AndroidKeysetManager`, `CleartextKeysetHandle` or unencrypted keyset serialisation.
  - Tests check that the stored bytes cannot be read as a plain key, and that a missing Keystore key raises an error instead of falling back.
  - At start-up, a test value is wrapped and unwrapped. If that fails, the app shows a recovery screen and never starts in a weaker mode.
  - Keystore calls run one at a time on one background thread.
- **Keystore key settings.** No fingerprint requirement and no "unlocked device" requirement, because SMS handling, reminders and backups run while the phone is locked. App lock and the vault's fingerprint prompt control access; they are not the encryption.
- **Large files** are encrypted and decrypted in a stream, one segment at a time, and written to a temporary name before being renamed. A PDF is decrypted to a private temporary file, because Android's PDF renderer needs one; that file is deleted on close, on app lock and at every start.
- **Compatibility.** Every encrypted file and backup records a format version. Committed fixture files from every version must still decrypt in every build.
- **Not production-ready until proven on your phone.** Phase 0B stress-tests the Keystore on your Tecno phone (1,000 wrap-and-unwrap cycles, including after a restart). It also benchmarks streaming encryption and Argon2id against the targets in Phase 0B below. Until those pass, the encryption design is unverified.

### Backup lifecycle

**What a backup is (format version 1).** One backup run produces an index file and one or more part files, written into the folder you chose:

```text
loopd-<run>.lpdb           header: "LPDB", format version, Argon2id settings, salt,
                           backup key id, backup key wrapped by your passphrase
                           + Tink stream (the header is its associated data) holding the
                           manifest: app and schema version, parts with sizes and SHA-256,
                           entries and where each lives
loopd-<run>-p0001.lpdp     Tink stream (associated data: run id + part number) holding a
loopd-<run>-p0002.lpdp     tar archive of whole entries; files larger than a part are split
…                          across numbered members
```

- The database entry is an encrypted copy made with SQLCipher's `sqlcipher_export` under a fresh random key, which travels inside the encrypted manifest. No unencrypted copy is written to disk.
- Vault files are decrypted from the vault stream and sealed straight into the backup stream, so a backup does not depend on this phone's keys.
- The index is written last, so a run without a readable index is not a backup.

**Stages.**

1. **Setup.**
   - You choose a passphrase (minimum length still to decide) and a folder in the system folder picker. The app keeps permanent access to that folder.
   - A random backup key is created. It is wrapped by the Keystore for the weekly runs, and by your passphrase through Argon2id for every backup file. The passphrase itself is never stored.
2. **Weekly backup.**
   - WorkManager starts a normal background job. It needs no visible notification and does not use the foreground-service time Android 15 limits.
   - At the start of a run, the database copy is taken and the run's plan (which entries go into which part) is saved.
   - Each job execution writes whole parts and records each finished part.
3. **Interruption and resume.** If Android stops the job (time limit, low battery, restart or the app being closed), the part being written is discarded and the next execution continues from the last finished part, with the same database copy. If any foreground service is ever used for a manual backup, Android 15's `onTimeout` call is handled the same way: save progress, stop within seconds and resume later. A run that has not finished within 7 days is abandoned and its parts are removed.
4. **Verification.** After the index is written, the run reads everything back: every part's SHA-256, and every stream authenticated. Only then does the run count as successful.
5. **Retention.** Files are never overwritten; every run has its own names. Older backups are removed only after a new one is verified, and only files the app created. At least the last three successful backups are kept. Whether a fourth, older one is also kept is still your decision.
6. **Restore.**
   - Read the index and unlock the backup key with your passphrase.
   - Check every part and entry, and restore into a staging folder.
   - Run the integrity and ledger health checks and the migrations.
   - Create new keys for this phone, then swap the staging folder in. The old data stays until the swap succeeds.

**When things go wrong.**

| Problem | What happens |
| --- | --- |
| Folder access lost (folder deleted, provider removed) | The run stops at once and asks you to choose the folder again; the Today nudge appears after 7 days |
| Out of space | Stop and notify |
| Provider error or timeout | Retry with growing waits, three tries within a day, then notify |
| Read-back check fails | Remove the new files if allowed, retry once, then notify |

A cloud provider only accepts the files; its own app uploads them later, because Loopd has no internet. Some providers may not offer folder access at all, so Phase 0B tests the providers on your phone. The fallback is a local folder that your own sync app copies.

**What can be recovered.**

| Situation | Data on the phone | Old backups | New backups |
| --- | --- | --- | --- |
| Same phone, passphrase forgotten | Untouched | Restorable on this phone only | Continue; a new passphrase can be set (how is still to decide) |
| New phone or reinstall, passphrase known | Restored | Readable | Continue with the same passphrase |
| New phone or reinstall, passphrase forgotten | Lost | Cannot be opened by anyone | Start fresh |
| A damaged backup file | — | That one refused; older ones still work | Continue |

Changing the passphrase creates a new backup key and an immediate fresh backup. Older backups still need the old passphrase on another phone.

### Errors, logging and code standards

- **Errors.** A sealed family of app exceptions (storage, keys, platform, validation and so on). Raw exceptions are converted at the data and platform edges, and the screens turn them into words through one mapping. A result type is used only where an outcome is expected rather than exceptional, such as parser results and form validation.
- **Logs.** Structured events with safe fields only (bank code, template, counts), kept on the phone. Message text, amounts, digits and names are never written, with a redaction pass as a safety net.
- **Code standards.** snake_case files with role suffixes (`_screen`, `_sheet`, `_notifier`, `_repository`, `_dao`, `_engine`, `_service`). Strict analyzer modes and lints, `dart format` checked in CI, and doc comments on the public APIs of engines and packages.

### Testing and CI

| Test | What it covers | Runs |
| --- | --- | --- |
| Unit | Ledger rules and invariants, lending allocation, reminder timing with a fake clock, validators, redaction | Every push |
| Database | DAOs on a test database; SQLCipher encryption proven on a real file; generated migration tests for every schema version | Every push |
| Parser fixtures | Scrambled SMS per bank and date format, duplicates, card-bill pairs | Every push |
| Widget and golden | Screens with faked providers; design-system components in both themes | Every push (goldens on Linux only) |
| Kotlin | Key storage, schedule store, crypto formats and backup format (fixtures from every version) | Every push |
| Backup round trip | Back up, delete app data and keys, restore with the passphrase, compare every table, total and file hash | Before every release, on a device |
| Integration | App launch, add an expense, paste an SMS and confirm, back up and restore | On demand and before a release |

- There is no coverage percentage target. Money, data integrity, security and the main journeys must be covered.
- The pipeline runs on GitHub Actions: format, analyse, the architecture check, Dart tests, Kotlin tests, and release builds of both flavours with a permission check (no internet permission in any build, no SMS permissions in the store build).
- How often the iOS compile check runs is still your decision. Until then it runs only when started by hand.

### Build flavours

- Two Android flavours, `personal` and `store`. Both currently use the application id `com.pursoth.loopd`; whether the store build gets its own id is still to decide.
- The flavours differ only in configuration, manifests and the personal-only native source set. The Dart business code is the same.
- Android's automatic backup and phone-to-phone transfer are switched off for the app, because Keystore keys do not travel.

### Feasibility summary

| Topic | Verdict | Condition or limit |
| --- | --- | --- |
| SMS detection | Feasible on Android in the personal build | Play approval not assumed; none on iOS |
| Ticket notification that stays until Done | Feasible on Android | iOS shows a standard notification that cannot be pinned |
| Digital Wellbeing | Feasible on Android | Needs usage access; not feasible on iOS |
| Document encryption | Feasible | Tink streaming encryption; speed to be confirmed on your phone in Phase 0B |
| Encrypted backup to a folder you choose | Feasible | Through the system folder picker, with no cloud API; providers vary |
| Offline assistant | Feasible as rules | Language features are out |
| Home-screen widgets | Feasible | Buttons and read-only figures; no typing inside a widget |
| Floating bubble | Feasible on Android, with a cost | Details below |
| Fully offline | Feasible | The app ships without the internet permission, checked on every build |

### The floating bubble, honestly

A bubble over other apps needs the "Display over other apps" permission, which is a restricted setting for sideloaded apps on Android 15 and later ([explanation](https://androidauthority.com/android-15-restricted-settings-sideloading-3481098)). It also needs a foreground service for as long as the bubble is shown, which Android displays as a permanent notification. That is the only always-on component in the product.

It is therefore opt-in, off by default, removed while the screen is off, and built last. Android's own Bubbles feature is reserved for conversations, so it is not used. A bubble is not possible on iOS.

### Battery and consistency

- Nothing polls. Work happens when an SMS arrives, an alarm fires, the phone restarts, once a day for screen time, and once a week for the backup.
- SMS parsing and import run off the main thread.
- Every money change is one database transaction through the ledger engine.
- Each SMS has a unique identity hash, so importing twice is harmless.
- Reminders are derived from records and can always be rebuilt from them.

Targets to measure, not results: a usable Today screen within 1.5 seconds of a cold start on a mid-range phone, and smooth scrolling with 10,000 transactions.

### Technical limits to keep in mind

- The Android Keystore is unreliable on a small share of phones. If Phase 0B shows problems on yours, the choice is between refusing to run and a passphrase at app start.
- The SQLCipher build bundled by the `sqlite3` package can lag behind the newest SQLite version. Drift's documentation now favours SQLite3MultipleCiphers, which can read and write the SQLCipher 4 format. It is the documented fallback if the SQLCipher build ever causes trouble.
- The `sqlite3` package downloads its prebuilt library during the build, never at run time.
- iOS: Tink's iOS library has no streaming encryption. If iOS is ever built, Tink's C++ library is tried first, and a Swift implementation tested against shared fixture files only if that fails.

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
| Encrypted database | Yes | Not Yet Verified | Cross-platform |
| Encrypted backup, restore and vault files | Yes | Coming Soon; needs iOS crypto work (Tink C++ first) | iOS-limited |
| App lock | Yes | Not Yet Verified | Cross-platform |
| Paste a message to get a transaction card | Yes | Not Yet Verified | Cross-platform |
| Automatic SMS detection for payments and tickets | Yes, personal build | Not possible | Android-specific |
| Transaction card as a notification | Yes | Not applicable | Android-specific |
| "Save to Loopd" from selected text | Yes | No equivalent | Android-specific |
| Floating bubble | Yes, opt-in, final phase | Not possible | Android-specific |
| Four-stage reminder as one updating notification | Yes | Separate notifications in one group | iOS-limited |
| Final ticket notification that stays until Done | Yes | A standard notification that cannot be pinned | iOS-limited |
| Sharing a file or text into the app | Yes | Coming Soon; needs a Swift share extension | iOS-limited |
| Hiding content in the app switcher | Yes, and screenshots are blocked | Cover screen only, Not Yet Verified | iOS-limited |
| Home-screen widgets | Yes, final phase | Coming Soon; needs a Swift widget | iOS-limited |
| Digital Wellbeing | Yes | Hidden | Not currently feasible on iOS |

## 15. Phased roadmap

Thirteen phases: the architecture and project structure first, core modules next, optional enhancements after them, and widgets with the floating bubble last. Estimates are focused days of about six hours and carry roughly 30% uncertainty either way. No time is allocated to anything removed in section 12.

[embedded content: Roadmap · 13 phases, 4 release gates

Each diamond is a release gate reached when the phase before it passes its checks. Day counts are cumulative.

### Phase 0: Architecture, project structure and spikes (9 days)

Phase 0 has two parts. Part A needs no phone. Part B needs your phone.

#### Phase 0A: Architecture and project foundations (4 days), done

| Item | Detail |
| --- | --- |
| Status | **Done on 17 November 2026** and approved by you. Tested on your Tecno Pova Curve 5G: the app launches into the five tabs, the Keystore-protected key is created, survives a restart and reaches Dart, and the encrypted database opens |
| Objective | Agree the architecture before any feature code (done on 16 November 2026), then build the foundations every later phase uses |
| Decisions | Recorded in `docs/adr/` (0001 to 0017) and summarised in section 13 |
| Features | `docs/architecture.md`; strict lints and formatting; the architecture check script; minSdk 35; `personal` and `store` flavours with the application id `com.pursoth.loopd`; Android backup switched off; the Pigeon bridge with Keystore-protected database key storage; the encrypted database (SQLCipher) opening an empty schema, with the schema snapshot and migration test set-up; logging with redaction, including key events that never show key bytes; the app exception family; route constants; an app that launches into the five-tab shell with placeholder pages, its tab bar drawn to the mockups; the CI pipeline with the release-permission check |
| Not included | Any feature, the design system, the ledger and the other engines, the background entry point (Phase 0B), SMS code and permissions (Phase 3), Bouncy Castle (added with backup) |
| Technical dependencies | The approved mockups and architecture |
| Risks and platform restrictions | Over-designing for features that may never come. Each folder has to serve a named phase, and no empty folders are created |
| Tested on Android | Dart and Kotlin tests pass; both flavours build; the release builds have no internet permission; the app launches into the shell and opens the encrypted database on your phone. The pipeline runs on the pull request |
| Needs an iPhone | Nothing. The iOS project only has to compile |

The folder structure Phase 0A creates (later folders arrive with their phase):

```text
lib/
  main.dart
  app/            start-up, flavour config, router, five-tab shell, placeholder pages
  core/
    database/     AppDatabase, encrypted opening, migrations
    security/     database key access through the bridge
    platform/     Pigeon-generated interface
    logging/      structured logs with redaction
    errors/       app exceptions
    routing/      route path constants
pigeons/          the Pigeon interface definition
tool/             architecture check, release-permission check
drift_schemas/    committed schema snapshots
android/app/      flavours, Kotlin key storage and bridge, JVM tests
test/             mirrors lib/; tool tests
integration_test/ app launch test
docs/architecture.md, docs/adr/
.github/workflows/ci.yml
```

#### Phase 0B: Native spikes on your phone (5 days), next

| Item | Detail |
| --- | --- |
| Objective | Prove the riskiest native pieces on your own phone before building on them |
| Features | SMS receiver and inbox read; a ticket notification that shows on the lock screen, stays until Done and survives a restart; reading app usage; the headless background engine started by WorkManager, with the single-writer handover; Keystore stress test (1,000 wrap-and-unwrap cycles, and after a restart); Tink streaming benchmark (1, 10, 50 and 200 MB; 1 MB and 4 KB segments); Argon2id tuning; writing to and reading back from the folders and cloud providers on your phone; interrupting a long background job and resuming it |
| Pass marks | A 20 MB PDF decrypted in under 1 second; a 10 MB photo encrypted in under 1 second; no memory failure at 200 MB, with under 10 MB of extra memory; Argon2id between 0.5 and 1.5 seconds; no Keystore failures |
| Technical dependencies | Phase 0A; your phone, a Tecno Pova Curve 5G on Android 16 (HiOS 16.3) |
| Risks and platform restrictions | A manufacturer's battery policy may delay the receiver or alarms. Tecno's HiOS manages background apps strictly, so the spikes also check its auto-start and battery settings. Android 16 adds stricter limits on background job run time, which the background-engine spike measures. The restricted-settings step for a sideloaded build has to be walked through on your phone. If the Keystore proves unreliable, a key decision returns to you |
| Tested on Android | Every spike and benchmark, on your phone, with the results recorded in the ADRs. The encryption design counts as verified only after this |
| Needs an iPhone | Nothing. The iOS project only has to compile |

### Phase 1: Design system and Today shell (8 days)

| Item | Detail |
| --- | --- |
| Objective | Make the look real before features exist, so later screens are assembled from finished parts |
| Features | Colour, type, spacing and motion tokens; core components (cards, chips, sheets, animated switch, animated tick, payment-source strip, stacked cards); five-tab shell with Today, Money, Travel, Planner and More; Today with empty states; the More tab with its settings groups; capture sheet shell; light and dark themes with the theme switch |
| Technical dependencies | The approved mockups in docs/mockups |
| Risks and platform restrictions | Custom components cost more than stock ones, so the component list is fixed up front |
| Tested on Android | Component gallery and visual tests in both themes |
| Needs an iPhone | A visual check on a real device. Until then, Not Yet Verified |

### Phase 2: Expenses with UPI, Credit Card and Cash (12 days)

| Item | Detail |
| --- | --- |
| Objective | A manual expense tracker you can use every day, with data that is safe |
| Features | Bank accounts and cards with nickname, last four digits and default, added from a sheet with a searchable bank list and live preview; the shared expense form with UPI, Credit Card and Cash; Cash in hand with Update cash; categories with the category sheet; totals by period, category, method, account and card, with refunds in the purchase month; editing with history and undo; refunds linked to originals; settlement, transfer and income rules; optional opening balances and verified balances; encrypted backup and restore with its screen, read-back verification and keeping the last three backups; app lock; app-switcher privacy |
| Technical dependencies | Phase 1 components. The ledger engine (section 13) and the first version of the backup engine are built here; Bouncy Castle is added for Argon2id |
| Risks and platform restrictions | The backup format must carry a version from its first release |
| Tested on Android | Everything, including restore onto a clean install |
| Needs an iPhone | File picker, biometric lock and cover screen. Not Yet Verified |

### Phase 3: SMS capture and Review Inbox (10 days)

| Item | Detail |
| --- | --- |
| Objective | Payments arrive as cards that you confirm |
| Features | SMS setup with the restricted-settings guide; first-run import; receiver and inbox scan; templates for your banks; sender-code matching; method and account identification, card before UPI; ATM withdrawals as transfers to Cash in hand; duplicate matching; card bill payment pairing through the transaction sources; the transaction card on Today (stacked), in the Review Inbox (with its opening animation) and as a notification; the single Review button for unclear items; delete with Undo; "Not a payment"; paste or share a message as the alternative; merchant memory |
| Technical dependencies | The SMS spike; scrambled fixtures exported from your phone; your list of banks and cards. The capture inbox engine is built here |
| Risks and platform restrictions | Formats from banks you do not use are untested. Templates break when a bank rewords. A message deleted before the scan is lost. This flavour is not for Google Play |
| Tested on Android | A replay over your own inbox, measured against the 95% target |
| Needs an iPhone | Only the paste path exists on iOS. Not Yet Verified |

### Phase 4: Lending and repayments (6 days)

| Item | Detail |
| --- | --- |
| Objective | Replace the mental list of who owes what |
| Features | Everything in section 6: people, loans, repayments of any amount, balances with progress, the person page, history, statement, suggested repayment from a bank credit, and turning a UPI payment to a person into a loan |
| Technical dependencies | The ledger engine from Phase 2 and the SMS pipeline from Phase 3 |
| Risks and platform restrictions | Matching a name in an SMS to a person is fuzzy, so it is only ever a suggestion |
| Tested on Android | Everything, including a check that lending never changes spending totals |
| Needs an iPhone | Reminder notifications. Not Yet Verified |

### Phase 5: Travel tickets and reminders (11 days)

| Item | Detail |
| --- | --- |
| Objective | Tickets are stored, and the final ticket is on your lock screen 15 minutes before departure |
| Features | The Travel list with All, Train and Bus tabs; manual tickets and planned trips; train and bus ticket details; ticket documents; ticket detection from IRCTC and TNSTC SMS, with the journey-day bus message updating the same ticket; call conductor; share to app; the four stages, counted from departure; the final notification with Show Ticket and Done; re-posting after a restart; the exact-alarm permission flow |
| Technical dependencies | The notification spike; the SMS pipeline. The reminder engine and the encrypted file store are built here and reused by Planner and the Vault |
| Risks and platform restrictions | Refusal of exact alarms. Manufacturer battery policies. Ticket SMS wording varies far more than bank SMS. What shows on the lock screen depends on your phone's settings |
| Tested on Android | Stage timing with a fake clock in tests, then real trips on your phone and one other brand |
| Needs an iPhone | Reminder behaviour is Not Yet Verified. Sharing into the app is Coming Soon |

### Phase 6: Planner: Notes and Tasks (9 days)

| Item | Detail |
| --- | --- |
| Objective | Capture a thought or a to-do in seconds, and see what is due on Today |
| Features | Everything in section 8 for Notes and Tasks: colour note cards with tap actions, the add note and add task sheets, checklists, quick capture, share and text-selection entry, repeat rules, reminder actions, and the Task reminders screen with snooze, the daily summary at a time you choose, and quiet hours for tasks |
| Technical dependencies | The reminder engine; the capture sheet; Kotlin entry points for share and selected text |
| Risks and platform restrictions | Scope creep is the main risk. Monthly repeats need care at month ends |
| Tested on Android | Everything |
| Needs an iPhone | Task reminders are Not Yet Verified. Sharing into the app is Coming Soon |

### Phase 7: Document Vault and backup completion (7 days)

| Item | Detail |
| --- | --- |
| Objective | Keep personal documents encrypted, viewable and recoverable |
| Features | Everything in section 8 for the vault, including category icons and the new category sheet; vault files added to the backup; the optional weekly automatic backup, resumable after interruption; the full backup and restore round-trip test; document expiry reminders (read-back verification and keeping the last three backups moved to Phase 2, owner, 18 November 2026) |
| Technical dependencies | The encrypted file store from Phase 5; the app lock; the reminder engine |
| Risks and platform restrictions | Memory use when decrypting large files. A forgotten backup passphrase cannot be recovered |
| Tested on Android | Encryption round trips and a restore onto a clean install |
| Needs an iPhone | Vault encryption is Coming Soon on iOS (needs iOS crypto work); file import Not Yet Verified |

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
| Features | Everything in section 10: the capture sheet with live chips, create commands, the Ask questions, text tools, local summaries, examples for unknown input |
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
| Features | Performance pass against the targets; accessibility pass; first-run onboarding and permission walkthrough; the Export logs screen; signed personal APK from the pipeline; README and decision records; a review of TO-DO.md |
| Technical dependencies | All earlier phases |
| Risks and platform restrictions | Polish is time-boxed. Android developer verification for sideloaded apps is planned to roll out globally in 2027, and a free limited-distribution account covers a small number of devices ([guide](https://developer.android.com/developer-verification/guides)) |
| Tested on Android | A full regression checklist, a 24-hour battery check with detection switched on, and a restore drill of a real backup into a second install (an emulator, or the store flavour once it has its own application id) |
| Needs an iPhone | Nothing new. The README states that iOS is Not Yet Verified |

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

The core product is complete at day 83 and Android v1.0 at day 96. A build worth using every day, Expenses with SMS capture, exists at day 39.

There is no deadline. You said on 16 November that time is not a constraint, so the focused days below only size the work and order it. They are not dates.

| Milestone | Phases | Focused days |
| --- | --- | --- |
| Architecture and folder structure agreed | 0A | 4 |
| Money with SMS capture | 0 to 3 | 39 |
| Core product, all nine modules | 0 to 9 | 83 |
| v1.0 Android | 0 to 11 | 96 |
| v1.1 with widgets and bubble | 0 to 12 | 103 |

Revision 3.1 adds one day: Cash and Cash in hand in Phase 2. Revision 3.2 adds three: the background engine and the extra spikes and benchmarks in Phase 0B, the fuller ledger (opening and verified balances, history and undo, refund modes) in Phase 2, and the resumable, verified backup in Phase 7.

How revision 3 moved Android v1.0 from 86 days to 92:

| Change | Days |
| --- | --- |
| Architecture discussion with decision records and the folder structure as the first step (Phase 0A) | +2 |
| More tab, theme switch and new shared components in the design system (Phase 1) | +1 |
| Add account sheet with a searchable bank list, and the category sheet (Phase 2) | +1 |
| Travel list with filters, and separate train and bus ticket details (Phase 5) | +1 |
| Note colours and tap actions, add sheets, and the Task reminders screen (Phase 6) | +1 |
| Lending without due dates and reminders, About screen postponed | 0, small savings absorbed |

How revision 2 moved Android v1.0 from 74 days to 86:

| Change | Days |
| --- | --- |
| Notes and Tasks, Document Vault and Digital Wellbeing added | +20 |
| Cloud assistant and proxy replaced by the offline assistant | -4 |
| Budgets and widgets phase reduced to optional enhancements, with widgets moved out | -2 |
| Global Search removed from the Money phase | -1 |
| Borrowing removed from the Lending phase | -1 |

The final phase adds 7 days for widgets and the bubble, ending at day 103. The former 8-day iOS phase is gone; keeping the iOS build compiling is part of each phase.

Running cost is zero. There is no API, no server and no subscription. Fees arise only if you later publish to a store.

## 17. Risks and dependencies

The largest risks are device behaviour on Android and the size of the scope for one developer. Neither is a reason to change the plan, and each has a response built into a phase.

| Risk | Effect | Response |
| --- | --- | --- |
| A manufacturer's battery policy delays the SMS receiver or alarms | Late cards or a late reminder | The inbox scan catches missed messages. A missed reminder is detected on next open with a one-time guide to exempt the app. Proven on your phone in Phase 0 |
| Exact alarms refused | The 15-minute reminder loses precision | It is scheduled ten minutes earlier so it cannot be late |
| The Android Keystore misbehaves on your phone | Keys cannot be read; the app cannot open its data | No weaker fallback is ever used silently. Stress-tested in Phase 0B; if it fails, the choice returns to you. Backups restore with your passphrase |
| The SQLCipher build behind the `sqlite3` package lags or breaks | An upgrade is blocked | Pinned versions; SQLite3MultipleCiphers in SQLCipher 4 mode is the documented fallback |
| A cloud provider does not offer folder access, or uploads late | Backups do not reach the cloud | Tested in Phase 0B; a local folder plus your own sync app as the fallback; a backup counts only after it is read back |
| Android stops a long background backup | A backup is left half-written | Backups are written in parts and resume from the last finished part; the last good backup is never touched |
| Restricted settings on a sideloaded build | SMS, usage access and the bubble stay off until allowed | One guided step covers all three |
| A bank rewords its SMS | Cards from that bank become unclear items that need Review | Generic extractor, then a template update with new fixtures |
| Google Play refuses SMS access | No store version with detection | The personal build is the product. Play is in TO-DO.md |
| Android tightens sideloading | More friction installing your own build | Register a limited-distribution developer account before it applies in India |
| No iPhone | iOS problems go unnoticed | The build compiles on every change, and nothing on iOS is described as verified |
| Lost phone or forgotten backup passphrase | Permanent loss of data | Backup nudges, optional weekly backup, and a clear warning when the passphrase is set |
| Nine modules for one developer | Slipping dates | Fixed "not included" lists per module, one droppable optional phase, and approval after every phase |
| Cash in hand drifts from your real wallet | Cash totals are off, because cash spending sends no SMS | Update cash sets Cash in hand to what you counted |
| Usage figures vary between manufacturers | Wellbeing totals differ from the system's | Compared over a week in Phase 8 and stated in the screen |
| The bubble's service is stopped by the system | The bubble disappears | Opt-in, restarted when the app opens, built last |

### Dependencies

- Your phone: a Tecno Pova Curve 5G on Android 16 (HiOS 16.3), confirmed on 17 November 2026.
- The banks, cards and ticket services that send you SMS. Received on 15 November.
- About 200 real messages, with digits scrambled, as parser fixtures. They are exported on your phone by a scrambling tool in the Phase 3 debug build, so raw messages never leave the phone.
- Approved mockups before Phase 1. Reviewed in six rounds; see docs/mockups.
- Your answers in section 19.

The plan needs no account, API key, paid service or Mac.

## 18. Design direction

The interface is colourful but calm: each module has its own accent, and numbers, tickets and documents carry the screen. The approved mockups are the reference for every screen: [docs/mockups](docs/mockups/README.md), viewable on the mockup canvas.

| Element | Direction |
| --- | --- |
| Type | Plus Jakarta Sans for everything, bundled so Android and iOS match, with tabular figures for every amount. JetBrains Mono for PNRs, references and the command line |
| Colour | Neutral surfaces, text in three strengths, one accent per module. Red for overdue and delete; orange for "needs review"; green for Save and Looks Good. UPI is green, Credit Card is violet and Cash is sky blue everywhere |
| Shape and space | A 4-point grid, generous margins, rounded cards and sheets, depth through tonal layers instead of shadows |
| Motion | Short and purposeful: sheets, the Review Inbox cards sliding down from a stack, the green tick on a task, the press-in on a note, sliding switches, and a haptic tick on Looks Good. Honours reduce-motion |
| Touch | A custom press state instead of the Material ripple; 44 to 48 dp minimum targets |
| Themes | Dark and light designed separately, dark first, switched from Today or from More |
| Accessibility | Text contrast of at least 4.5 to 1, text scaling to 130%, spoken labels on amounts and icon buttons |

| Module | Accent | Signature element |
| --- | --- | --- |
| Today | Neutral | A stack of review cards and short cards that disappear when nothing needs you |
| Money | Green, with violet for cards and sky blue for cash | A payment-source strip with a mini card in the bank's colour |
| Lending | Amber | Friend rows with a progress bar of what came back |
| Travel | Indigo | Pass-style ticket cards with train and bus icons and the PNR in monospace |
| Planner | Warm sand, plus six note colours | Colour note cards; a small circle that fills green when a task is done |
| Vault and More | Blue | Solid colour tiles; each Vault category has its own icon and colour |
| Wellbeing | Teal | Bars for days, a ranked list of apps with their icons |
| Assistant | Follows the type being added | One input with labelled chips. No sparkle icons and no gradient, because it is not AI |

The mockups were reviewed in six rounds between 14 and 16 November 2026. Phase 0A was finished on 17 November 2026; the next step is Phase 0B on your phone.

## 19. Questions that still need your answer

Your confirmed decisions are applied and are not reopened here. Each open point states what I will do if you say nothing.

### Answered

- [x] **Your banks, cards and ticket services.** Shared on 15 November: one primary credit card paid by UPI QR, a bank account for small UPI payments, salary, savings and auto-pay accounts, four more credit cards, and IRCTC and TNSTC for travel. Kept out of the repository; only made-up digits appear in the mockups.
- [x] **Lending due dates.** None. Friends repay monthly or all at once.
- [x] **A card shared with family.** Its spending counts as yours.
- [x] **Minimum Android version.** Android 15.
- [x] **The capture sheet.** (a): it stays on every tab. You will confirm it once the sheet is designed and tested.
- [x] **Your phone.** Tecno Pova Curve 5G.
- [x] **Your phone's Android version.** Android 16 with HiOS 16.3 (17 November 2026). Phase 0B tests on Android 16. The minimum stays Android 15.
- [x] **Cash and other bank debits.** Cash is tracked as a third method with one Cash in hand balance (section 4). ATM withdrawals move money to Cash in hand; debit-card, net-banking and auto-debit messages appear in the Review Inbox under their bank account.
- [x] **On-device language features.** Not built.
- [x] **Reminder times.** Travel stages are counted from departure, with no clock times. Only task reminders use times you choose: the lead, the snooze, the daily summary and quiet hours. Payment cards, travel stages and other alerts follow their own rules.
- [x] **Your time.** No limit. The effort table sizes the work and is not a schedule.
- [x] **Architecture.** Approved on 16 November 2026 as described in section 13, with Kotlin and Tink for encryption. Phase 0A was finished on 17 November 2026.
- [x] **The capture button.** Stays on every tab, confirmed after trying the sheet in Phase 1 (17 November 2026).
- [x] **Other bank methods in the split.** Debit-card, net-banking and auto-debit payments count as UPI: Loopd has only UPI, Credit Card and Cash (17 November 2026).
- [x] **Refund reporting.** Purchase month only: a refund reduces the month the purchase was made in. The cash-flow switch chosen on 17 November was dropped after the Money tab design (18 November 2026).
- [x] **Backup retention.** The last three successful backups are kept; no older fourth one (17 November 2026).
- [x] **Restore without the passphrase.** No: every restore asks for the backup passphrase, on this phone too (17 November 2026).
- [x] **Resetting a forgotten passphrase.** Yes, on this phone after a fingerprint, face or PIN check. Older backups keep the old passphrase; new backups use the new one (17 November 2026).
- [x] **Minimum passphrase length.** 12 characters (17 November 2026).

### Still open

- [ ] **Text tools** in section 10 (tidy spacing, sort lines, count words, pull out amounts) have no screen in the mockups. Should they be commands typed in the capture line, or be dropped?
  If you say nothing: commands in the capture line, built in Phase 9.

Architecture choices still pending. Nothing that depends on them is built until you decide:

- [ ] **Pairing window.** The time allowed between the two SMS of a card bill or own transfer (proposed ±3 days). Needed in Phase 3.
- [ ] **Weekly backup conditions.** Battery not low only, or also while charging. Needed in Phase 7.
- [ ] **An in-app "Test restore"** that restores into a staging area and discards it. This would be new scope. Needed in Phase 7 if wanted.
- [ ] **Exact alarms in the personal build:** keep the permission prompt, or use the install-time permission that only sideloaded apps may use. Needed in Phase 5.
- [ ] **The original SMS text** after a transaction is confirmed: keep it (encrypted) or delete it. Needed in Phase 3.
- [ ] **The iOS compile check:** how often it runs in CI. Until you decide, it runs only when started by hand.
- [ ] **Application ids.** Both flavours use `com.pursoth.loopd` for now. Should the store build get its own id, so both can be installed side by side?
- [ ] **If the Keystore proves unreliable** on your phone in Phase 0B: refuse to run, or ask for a passphrase at app start.

Defaults taken because nothing was said: Riverpod for state management and no text filter in Notes. The app is named Loopd (16 November 2026).

## Sources

Checked on 16 Nov 2026 for the architecture in section 13:

- [Maven Central: tink-android versions](https://repo1.maven.org/maven2/com/google/crypto/tink/tink-android/maven-metadata.xml) and [bcprov-jdk18on versions](https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/maven-metadata.xml)
- [Tink 1.24.0 AndroidKeysetManager source](https://github.com/tink-crypto/tink-java/blob/v1.24.0/src/main/java/com/google/crypto/tink/integration/android/AndroidKeysetManager.java) and [AndroidKeystore source](https://github.com/tink-crypto/tink-java/blob/v1.24.0/src/main/java/com/google/crypto/tink/integration/android/AndroidKeystore.java)
- [Tink primitives by language](https://developers.google.com/tink/primitives-by-language), [Tink C++](https://github.com/tink-crypto/tink-cc), [Tink Objective-C](https://github.com/tink-crypto/tink-objc)
- [Drift: encryption](https://drift.simonbinder.eu/platforms/encryption/) and [sqlite3 package build hook options](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md)
- [SQLCipher API, sqlcipher_export](https://www.zetetic.net/sqlcipher/sqlcipher-api)
- [Android: foreground service timeouts](https://developer.android.com/develop/background-work/services/fgs/timeout)

Earlier sources:

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

Two caveats. The UsageStatsManager page did not load in full, so how long the system keeps usage history is to be measured in the Phase 0B spike. Statements about iOS notification behaviour come from platform knowledge and are untested, which is why they are marked Not Yet Verified.
