# Mockups

Key screens of Kanakku, in dark (designed first) and light themes, for approval before Phase 1.

**View them here:** https://claude.ai/artifact/LGbLMacN52Aq8mq8pi7bNa (private; share it from the page's Share menu if someone else needs to see it).

The files in this folder are the source of that canvas, kept in git so every revision is reviewable in a PR. They are design references, not app code.

## Screens

| # | Screen | Plan section | Interactive |
| --- | --- | --- | --- |
| 1 | Today | 3 | Open the review stack, tick tasks |
| 1b | Today with the review stack opened | 3, 5 | Pick a category, choose Lent or Expense |
| 2 | Review Inbox and transaction card | 5 | Looks Good saves; the second card needs a method chosen first |
| 3 | Add expense (UPI or Credit Card) | 4 | Switch method, account and category |
| 4 | Accounts and cards | 4 | |
| 5 | Lending: person page | 6 | |
| 6 | Travel ticket and the four reminder stages | 7 | |
| 7 | Lock screen, 15 minutes before departure | 7 | |
| 8 | Notes | 8 | |
| 9 | Tasks | 8 | Tick tasks off |
| 10 | Document Vault | 8 | |
| 11 | Digital Wellbeing | 9 | |
| 12 | Capture sheet with the command line | 10 | |

Each `*Light.dc.html` file shows the same screen with the light palette.

## Design decisions

- **Colour per module** (plan section 18): Money green, Lending amber, Travel indigo, Notes and Tasks warm sand, Vault slate, Wellbeing teal. Credit Card has its own violet so UPI and CC are told apart at a glance.
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
| 3 | Count badge and stacked cards | Badge reads "N New", or "New" for one. Pending items show as a stack; tapping the stack opens it and the other cards slide down one after another (screen 1b) |
| 4 | Merchant names are often unclear | The name is shown as the SMS writes it. A new shop asks for a category once and is remembered with any rename |
| 5 | Unknown category; wrong account; a catchier section | Unknown category shows one-tap category chips. A payment-source strip shows a mini card in the bank's colour, the account name and how it was paid |
| 6 | Remove "Open Review Inbox · 2 more" | Removed from the closed stack; the link appears only once the stack is open |
| 7 | Train and bus icons; real IRCTC and TNSTC formats | "Trips this week" shows a train and a bus with different icons. Train shows what the railway SMS carries (codes, train, class, coach and berth, chart status). Bus shows route, vehicle, platform and a call-conductor button |
| 8 | Checkbox too big | 20 px circle; ticking fills it green with an animated tick |
| 9 | No due dates for friends | "Lent to friends" shows what is still out and how much came back, with no due or overdue state, plus a suggested repayment from an incoming bank credit |
| 10 | Spending and Backup | Unchanged; the split now reflects card-heavy spending |
| 11 | App icons in screen time | Top three apps with an icon on the left (the app shows the real icon from the phone; the mockup uses letter tiles) |

Decisions that change the plan, to be folded into the proposal:

- **A credit card paid through UPI is a Credit Card expense.** The method is where the money comes from. The card shows "paid by UPI QR". The SMS rule checks for a card before UPI markers.
- **Sender headers are matched on the six-letter bank code** (for example `YESBNK`), ignoring the two-letter prefix, which only names the telecom route. The same bank arriving under several prefixes is one sender.
- **A UPI payment to a person asks "Lent" or "Expense"** on its card.
- **Lending has no due dates by default.** Today shows the amount still out and repayments so far.
- **Card bill payments arrive as two messages** (a bank debit and a card credit for the same amount). They pair into one settlement, as section 5 already plans.
