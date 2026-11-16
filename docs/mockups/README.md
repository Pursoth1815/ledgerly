# Mockups

Key screens of Loopd, in dark (designed first) and light themes, for approval before Phase 1.

**View them here:** https://claude.ai/artifact/LGbLMacN52Aq8mq8pi7bNa (private; share it from the page's Share menu if someone else needs to see it).

The files in this folder are the source of that canvas, kept in git so every revision is reviewable in a PR. They are design references, not app code.

## Screens

| # | Screen | Plan section | Interactive |
| --- | --- | --- | --- |
| 1 | Today | 3 | Tick tasks; the review stack opens the Review Inbox |
| 2 | Review Inbox | 5 | Opening animation, Looks Good, delete with Undo, category for a new shop |
| 2b | Transaction details (what Review opens) | 5 | Edit name, method, account and category |
| 3 | Add expense, UPI | 4 | Switch method, account and category |
| 3b | Add expense, Credit Card | 4 | Same form with Credit Card chosen |
| 3c | Add expense, Cash | 4 | Same form with Cash chosen: Cash in hand and what is left after this expense |
| 4 | Accounts and cards | 4 | Cash in hand at the top, with Update count |
| 4b | Add bank account (sheet, searching "hd") | 4 | Type to search banks, pick one, nickname, last four digits, default; live preview |
| 4c | Add credit card (sheet, bank chosen) | 4 | Same sheet for a card |
| 5 | Lending: person page | 6 | |
| 6 | Travel list | 7 | All / Train / Bus filter |
| 6b | Ticket details, train | 7 | |
| 6c | Ticket details, bus | 7 | |
| 7 | Lock screen, 15 minutes before departure | 7 | |
| 8 | Planner: Notes | 8 | Tap a note to press it in and show pin, edit and delete |
| 8b | Add note sheet | 8 | Title, text, checklist, pin and note colour |
| 9 | Planner: Tasks, Today | 8 | Today, Upcoming and Completed tabs; tick tasks off |
| 9b | Tasks, Upcoming | 8 | Same screen on the Upcoming tab |
| 9c | Add task sheet | 8 | Due, reminder, repeat and time |
| 10 | More (last tab) | 3 | Opens the Vault, Screen time and Accounts and cards |
| 10b | Document Vault (inside More) | 8 | |
| 11 | Digital Wellbeing | 9 | |
| 12 | Capture sheet with the command line | 10 | |

Each `*Light.dc.html` file shows the same screen with the light palette.

## Design decisions

- **Colour per module** (plan section 18): Money green, Lending amber, Travel indigo, Notes and Tasks warm sand, Vault slate, Wellbeing teal. Credit Card has its own violet so UPI and CC are told apart at a glance. Cash is sky blue (dark `#38BDF8`, light `#0369A1`).
- **Reserved colours:** red only for overdue; orange only for "needs review".
- **Type:** Plus Jakarta Sans for everything, tabular figures for amounts; JetBrains Mono for PNRs and the command line.
- **Shape:** rounded cards, tonal layers instead of shadows, 44 px minimum touch targets.
- **Reference:** the owner's two earlier mockups (transaction card, Add transaction) set the layout of screens 2 and 3. The colours are new.

All names, amounts and numbers in the mockups are made up.

## Review round 1: Today (15 Nov 2026)

The owner reviewed Today and shared real bank, railway and bus SMS as reference. No real message text, account digits or third-party names are copied into this repo.

| # | Feedback | Change |
| --- | --- | --- |
| 1 | Real accounts and how each is used | Mockup data now follows the owner's setup: a primary credit card paid by UPI QR, a bank account for small UPI spends, separate salary and savings accounts |
| 2 | Header elements unclear and misaligned | Date sits above the title; the Wellbeing (hourglass) and Settings (gear) buttons are centred on the title line |
| 3 | Count badge and stacked cards | Badge reads "N New", or "New" for one. Today shows the top card with the others stacked behind it; tapping the stack opens the Review Inbox, where the cards slide down one after another |
| 4 | Merchant names are often unclear | The name is shown as the SMS writes it. A new shop asks for a category once and is remembered with any rename |
| 5 | Unknown category; wrong account; a catchier section | Unknown category shows one-tap category chips. A payment-source strip shows a mini card in the bank's colour, the account name and how it was paid |
| 6 | Remove "Open Review Inbox · 2 more" | Removed from the closed stack; the link appears only once the stack is open |
| 7 | Train and bus icons; real IRCTC and TNSTC formats | "Trips this week" shows a train and a bus with different icons. Train shows what the railway SMS carries (codes, train, class, coach and berth, chart status). Bus shows route, vehicle, platform and a call-conductor button |
| 8 | Checkbox too big | 20 px circle; ticking fills it green with an animated tick |
| 9 | No due dates for friends | "Lent to friends" shows what is still out and how much came back, with no due or overdue state, plus a suggested repayment from an incoming bank credit |
| 10 | Spending and Backup | Unchanged; the split now reflects card-heavy spending |
| 11 | App icons in screen time | Top three apps with an icon on the left (the app shows the real icon from the phone; the mockup uses letter tiles) |

### Follow-up on the same round

| Feedback | Change |
| --- | --- |
| Don't open the stack on Today | Tapping the stack goes to the Review Inbox. The opening animation lives only there |
| Review Inbox should use the new card | Same card as Today: avatar, payment-source strip, category, Review and Looks Good |
| "Needs a choice" looked ugly | Badge removed. A missing method shows a plain "How did you pay?" UPI / Credit Card switch, and Looks Good reads "Pick UPI or Card" until then |
| What does Review do? | Opens Transaction details (2b): edit amount, name, date, note, method, account and category; see the original SMS; mark "Not a payment" |
| Need a delete icon | Every card has a delete icon. It removes the item from the inbox with Undo. Transaction details has one too |
| RBL card is shared with family | Its spending counts as the owner's spending. No separate "shared card" state |

### Second follow-up, and Accounts and cards

| Feedback | Change |
| --- | --- |
| Delete icon hard to see | Red icon on a soft red circle on every review card and on Transaction details |
| Remove "guessed" | Removed from Today and the Review Inbox |
| Unclear cards (UPI or card unknown; money sent to a person) | No inline pickers or disabled buttons. The card gets an orange border and a single orange Review button. The unknown part shows as a dashed "?" strip or a short note |
| Account nicknames | "Primary" for the everyday UPI account and "Investments" for the auto-pay account |
| Save button | One green "Save ₹amount" button, with no summary text above it, on Add expense and Transaction details |
| Add expense with Credit Card | Screen 3b shows the card list with Kiwi as the default |
| Archived accounts | Removed from the screen and from the plan (section 4). Removing an account keeps its past transactions |
| Adding an account or card | Screens 4b and 4c: type switch, live card preview, bank grid, the SMS sender code it will match, nickname, last four digits and a default switch |

**Implementation note:** Add expense (3, 3b) and Transaction details (2b) are one component, `AddExpense.dc.html`, with a `mode` of `add` or `review`. Review mode adds the delete icon, the "SMS said" line, the remember-this-shop option and the original message. The Flutter screen should follow the same pattern.

## Review round 2: Accounts sheet, Lending, Travel, Lock screen (15 Nov 2026)

| Feedback | Change |
| --- | --- |
| Bottom bar missing on Lending and Travel | The tab bar is on the Lending person page (Money active) and on the Travel list and both ticket pages (Travel active) |
| Add bank account / card should be a sheet | It is a bottom sheet over Accounts and cards |
| Bank should be a searchable dropdown, not chips | A search field with a dropdown. Typing filters the list and highlights the match; an unknown name can be added as a new bank. Screen 4b shows "hd" typed |
| Travel needs a list page | New Travel list (6) with All / Train / Bus tabs, upcoming trips (including a planned trip with a book-by date) and earlier trips |
| Ticket page should match Today | Ticket details now show what the SMS carries. Train (6b): station codes, train number, class, coach, berth, chart status and the boarding note. Bus (6c): route, seat, platform, bus number on the day and a call-conductor button. Arrival time is not in the SMS, so it is an "+ Arrival time" button |
| Lock screen button colours | Tried a green "Done"; the owner preferred the original, so "Show ticket" is indigo and "Done" is outlined |
| Lending wording | The person page no longer shows a due date; it shows the last repayment |

The SMS sender codes shown in the bank dropdown are examples. The real list is built in Phase 3.

## Review round 3: Notes, Tasks and navigation (15 Nov 2026)

| Feedback | Change |
| --- | --- |
| Tasks: "Today" showed tomorrow's task | The Today tab shows only Overdue and Today. Everything later is under Upcoming (9b). The three tabs work |
| Sheets for adding a task and a note | Add note (8b) and Add task (9c) are bottom sheets, opened from "+ Note" and "+ Task" |
| Notes cards too plain | Two columns of colour-tinted cards with checklist previews. Each note has one of six colours |
| Tapping a note | The card presses in slightly, gets a ring in its colour, and shows Pin, Edit and Delete. Delete has Undo |
| Remove the folder tabs | Removed. Notes have no folders; pinned notes come first |
| Settings icon on Today | Replaced by a light or dark theme switch |
| Settings in the bottom bar; Vault moves inside | The last tab is **More**: Vault and Screen time as tiles, then settings grouped as Money, Reminders, Privacy and backup, and App. The name leaves room for later additions |

Plan changes made in the proposal: the tabs are Today, Money, Travel, Planner and More (section 3), and Notes have colours and no folders (section 8).

## Review round 4: Add note, tab name, More and Vault (16 Nov 2026)

| Feedback | Change |
| --- | --- |
| "Title" and "Note" labels in Add note look poor | Labels removed. The note card has a coloured edge, a large title, a status line ("Checklist · 3 of 4 left") and tickable checklist rows with "Add item". A text / checklist switch, pin and colour dots sit below the card |
| The "Notes" tab also holds Tasks | The tab and the page title are now **Planner**, with Notes and Tasks inside |
| Vault tile in More looks plain | Vault and Screen time are solid colour tiles with a large faint icon |
| Switches | Task reminders, SMS detection and Dark theme use animated on and off switches. Dark theme switches the screen live |
| About Loopd | Removed for now |
| Vault header misaligned; unclear "Unlocked" label | The label is gone. Title and Add button are aligned on one line, with "27 documents, encrypted on this phone" below |
| Category icons | Identity card, rupee, shield, plane, car, heart with a cross, graduation cap |
| New category tile | A dashed tile with a + icon and "New category" on one line |

"Categories" in More are the **expense categories** used in Money (Food, Travel, Shopping and so on). The row is renamed "Expense categories" so it is not confused with Vault categories.

## Review round 5: category sheets, theme switch, capture sheet (16 Nov 2026)

| Feedback | Change |
| --- | --- |
| Sheet for Expense categories | 10c: a sheet listing all categories with icon, colour and this month's spend, and a "New category" button |
| New category sheets | 10d (expense) and 10e (Vault) share one component, `CategorySheet.dc.html`: a live preview, name, eight colours and an icon grid. Expense uses bright colours and money icons; Vault uses deep colours and document icons |
| Dark theme switch too light | The switch is dark purple when on |
| Capture sheet looked clumsy | Rebuilt around one input. As you type, it shows what it understood as labelled chips (amount, category, paid with, from), and one coloured button to save. Questions ("who owes me") show the answer in place. Below: five round shortcuts and three ready questions |

**Implementation note:** the capture sheet's chips show the offline assistant's rules at work, so it is never presented as AI. It is plain pattern matching on amounts, keywords and account names (plan section 10).

## Review round 6: settings screens (16 Nov 2026)

| Feedback | Change |
| --- | --- |
| Dark theme switch too dark | Now a medium purple, between the first and second tries |
| Screen for Backup & restore (label renamed by the owner) | 10f: a status card with a working "Back up now" (progress, then "Backed up just now"), where backups are saved, weekly automatic backup switch, passphrase, a size breakdown of what is inside, Restore and a passphrase warning |
| Screen for Task reminders | 10g: master switch, default reminder lead, snooze length, morning summary, quiet hours, and a live preview of how a reminder will look |
| Screen for Export logs | 10h: a privacy note, time range, which parts to include with line counts, a redacted preview and an Export button with the file size |

All three are one component, `SettingsPage.dc.html`, with a `page` of `backup`, `tasks` or `logs`. In More, tapping the Task reminders label opens its screen while the switch still turns reminders on or off.

Decisions that change the plan, to be folded into the proposal:

- **A credit card paid through UPI is a Credit Card expense.** The method is where the money comes from. The card shows "paid by UPI QR". The SMS rule checks for a card before UPI markers.
- **Sender headers are matched on the six-letter bank code** (for example `YESBNK`), ignoring the two-letter prefix, which only names the telecom route. The same bank arriving under several prefixes is one sender.
- **A UPI payment to a person asks "Lent" or "Expense"** on its card.
- **Lending has no due dates by default.** Today shows the amount still out and repayments so far.
- **Card bill payments arrive as two messages** (a bank debit and a card credit for the same amount). They pair into one settlement, as section 5 already plans.

## Update after the owner's answers (16 Nov 2026)

Not a review round: these changes come from the owner's answers to the open points in the plan. Only small parts of existing screens changed.

| Answer | Change |
| --- | --- |
| Track cash | Add expense has a third method, **Cash** (3c). Choosing it replaces the account list with Cash in hand, showing the balance and what is left after this expense |
| Show cash in hand | Accounts and cards (4) opens with a Cash in hand card: balance, the last ATM withdrawal and an Update count button. Today's Spending card splits into UPI, Credit Card and Cash, with a Cash in hand row that opens Accounts |
| Cash from the ATM | The Review Inbox (2) has an ATM withdrawal card with a Cash chip and "Moves to Cash in hand". Looks Good moves the money; it is not spending. Today's badge reads 5 New |
| Travel times follow the trip | Ticket details (6b, 6c) show the four stages at 24 hours, 12 hours, 3 hours and 15 minutes before departure. The "Travel reminder times" row is removed from More |
| Task times are the owner's choice | Task reminders (10g) has a "Daily summary at" choice (07:00, 08:00, 09:00, 21:00). Quiet hours now say they apply to tasks only; travel and payment alerts still come |

The owner's own edit on the canvas, kept in this folder: the Capture sheet shortcut "Loan" is now "Lent", and the shortcut labels use a regular weight.
