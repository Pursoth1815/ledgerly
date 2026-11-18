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
| 4 | Accounts and cards | 4 | Cash in hand at the top, with Update cash |
| 4b | Add bank account (sheet, searching "hd") | 4 | Type to search banks, pick one, nickname, last four digits, default; live preview |
| 4c | Add credit card (sheet, bank chosen) | 4 | Same sheet for a card |
| 5 | Lending: person page | 6 | |
| 5a | Money tab: Expenses | 3, 4 | Day / Week / Month, filter by account or card, show all |
| 5b | Show all categories (sheet) | 4 | View and account or card set in Tweaks |
| 5c | Show all expenses (sheet) | 4 | The same sheet in its expenses view |
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

- **Colour per module** (plan section 18): Money green, Lending amber, Travel indigo, Notes and Tasks warm sand, Vault blue (proposal section 18; an earlier slate is no longer used), Wellbeing teal. Credit Card has its own violet so UPI and CC are told apart at a glance. Cash is sky blue (dark `#38BDF8`, light `#0369A1`).
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
| Show cash in hand | Accounts and cards (4) opens with a Cash in hand card: balance, the last ATM withdrawal and an Update cash button. Today's Spending card splits into UPI, Credit Card and Cash, with a Cash in hand row that opens Accounts |
| Cash from the ATM | The Review Inbox (2) has an ATM withdrawal card with a Cash chip and "Moves to Cash in hand". Looks Good moves the money; it is not spending. Today's badge reads 5 New |
| Travel times follow the trip | Ticket details (6b, 6c) show the four stages at 24 hours, 12 hours, 3 hours and 15 minutes before departure. The "Travel reminder times" row is removed from More |
| Task times are the owner's choice | Task reminders (10g) has a "Daily summary at" choice (07:00, 08:00, 09:00, 21:00). Quiet hours now say they apply to tasks only; travel and payment alerts still come |

The owner's own edit on the canvas, kept in this folder: the Capture sheet shortcut "Loan" is now "Lent", and the shortcut labels use a regular weight.

## Built as design tokens (Phase 1, 17 Nov 2026)

The colours in the mockups are now `lib/design_system/loopd_colors.dart`, read in code as `context.colors`. Where mockups disagreed slightly, the code follows the majority:

- Soft tints use the opacity most mockups share; the capture sheet's slightly stronger tints are not kept.
- Vault is blue: `#7C9BFF` as an accent on dark, `#3B5BDB` for solid tiles and in light. The slate in the Lending mockup is not used.

A test checks that every text colour has at least 4.5 to 1 contrast on every surface, in both themes.


## Component review (Phase 1, 17 Nov 2026)

The owner checked the component gallery on the phone. Changes from the mockups:

| Feedback | Change |
| --- | --- |
| The review stack did not read as three cards | Each waiting card now shows a clear 10 px edge below the one in front: up to two edges, each narrower, and the back one slightly faded. Tapping the edges (a 44 px area kept clear of the card's buttons) opens the Review Inbox |
| Button text a little large | Button labels are 14 px Bold (the mockups had 15 px) |
| "Back up now" | Has a cloud-upload icon before the label |
| How a disabled button should look | Three looks were compared on the phone: a soft tint, an outline, and the whole button faded. The owner chose **faded**: a disabled button keeps its own colours at 40% opacity |
| The sheet showed two handles | One handle (a gallery bug, fixed in the sheet component) |

## Phase 1 screens (17 Nov 2026)

Built from the mockups, with these additions for a phase where no features exist yet:

- **Today's empty state:** an "All clear" card, which is not in the mockups. Today hides every card that has nothing to say, so with no data it would otherwise be blank.
- **More:** each row shows which phase builds it ("Phase 2", or "Later" for App lock, which the plan does not place yet). Switches for features not built yet (SMS detection, Task reminders) are faded and cannot be turned on. The Dark theme switch works. The tiles show their phase instead of counts.
- **Capture sheet:** the input, the five shortcuts and the three questions are in place. Shortcuts and questions say which phase builds them. Typed text is not understood until the offline assistant (Phase 9).
- **Icons:** Material icons stand in for the mockups' line icons, except the tab bar, which is drawn from the mockup paths.


## Review round 7: the Money tab (18 Nov 2026)

Designed for Phase 2, part 5 (screens 5a, 5b and 5c) and reviewed in two rounds. The numbers are the made-up November from Today (₹19,070 so far).

- **Header:** the title "Money", a round wallet button that opens the Accounts and cards sheet, and the Expenses | Lending segments. The chosen segment fills with its module colour: Expenses in Money green, Lending in amber. Lending is designed and built in Phase 4; until then its segment says "Lending is built in Phase 4".
- **Period:** Day | Week | Month pills (the chosen one in Money green) and ‹ › to step through earlier periods; › is faded on the current one.
- **Total card:** "Spent in November", the total, then the UPI / Credit Card / Cash bar with each amount. A method with ₹0 is left out of both the bar and the amounts.
- **Refunds always count in the purchase month** (owner, 18 Nov 2026, replacing the switch chosen on 17 Nov): a refund lowers the month its purchase was in, so totals never move between months. A failed payment reversed later by the bank is the same: once confirmed, the reversal cancels the original. In the list, a refund sits on the day it came back, in green ("+₹2,499"), tagged "Counts in Oct" when its purchase was in an earlier month.
- **Spent from:** a row of mini cards in each bank's colour, one per account and card plus Cash, each with the period's total. Tapping one filters everything below it ("Spent in November from Kiwi", "Categories · Kiwi", "Expenses · Kiwi"); tapping it again or Show all clears it.
- **Categories:** the top five with tile, amount, a bar and the share of the total; **Show all N** opens screen 5b.
- **Expenses:** newest first, grouped by day with each day's total; each row has the category tile, the shop, a dot in the method colour with how it was paid ("UPI · Primary", "Kiwi · UPI QR", "Cash"), and the amount. Tapping one opens the expense sheet as **Edit expense**. The app loads more as you scroll; **Show all N** opens screen 5c.
- **Show all (5b, 5c):** one tall sheet with two views, Categories and Expenses. The title, then "November 2026 · 6 categories", then the chosen account or card as a card (or "All accounts and cards"), then the full list. No close button, as on the category sheet: swipe it down or press back.
- No hint texts ("tap one to filter", "tap one to edit") on the screen.

## Phase 2, part 2: Accounts and cards (18 Nov 2026)

Built from screens 4, 4b and 4c, with these additions the mockups do not show:

- **The section above the cash card is titled "Cash"**, not "Cash in hand" (owner, 18 Nov 2026), because the amount on its right ("₹255 in Nov") is this month's cash spending, while the card shows the balance.
- **Negative amounts** put the minus after the ₹: ₹−305, not −₹305 (owner, 18 Nov 2026).
- **A sheet, not a page** (owner, 18 Nov 2026; the mockup draws screen 4 as a full page). It opens from the Accounts and cards row in More, which shows no count (the mockup's "4 · 5" is dropped), and Today and the Money tab will open the same sheet (`showAccountsSheet`). It is a tall sheet over the whole app, tab bar included, with a title, the subtitle and a Close button instead of Back. It keeps one height from the start and shows its list only once everything has loaded, so nothing jumps into place. Close it to switch tabs, so More always comes back as More. The Add, Update cash and account sheets open on top of it.
- **Every sheet opens over the tab bar** (owner, 18 Nov 2026), wherever it is opened from, so no sheet stays behind on a tab you left.
- **Cash in hand before the first count:** the card shows ₹0 and "Count your wallet to set it" (owner, 18 Nov 2026). The line under the amount shows the newer of the last count ("Counted 18 Nov") and the last money in from a bank ("₹2,000 from ATM · 12 Nov"). A cash expense does not change that line.
- **Update cash** (named Update count in the mockup; owner, 18 Nov 2026): a sheet with one large amount field and a plain Save. Before saving it shows what Loopd has and that the count replaces it ("₹150 less than Loopd has. Your count replaces it; the difference is not spending."). There is no adjustment (owner, 18 Nov 2026).
- **Tapping an account or card:** a small sheet with its bank, digits and sender code, "Make default" and a red "Remove". Remove asks once more and says the past expenses stay under the name.
- **Add sheet:** the last four digits are required; the nickname is optional and falls back to the bank's name. The default switch starts off, even for the first one (owner, 18 Nov 2026). The type switch slides its coloured half across to the tapped side. Searching "sbi" finds "State Bank of India (SBI)". A missing bank is offered as a coloured "Add “Zeta Bank” as a new bank" row; once chosen, its card is grey and a soft strip says its SMS are not linked yet but expenses can be added by hand. A listed bank gets the same strip in the sheet's colour, naming its sender code. The arrow and a tap outside a field put the keyboard away. The last four digits must be new among bank accounts, and separately among cards, whatever the bank (owner, 18 Nov 2026): as soon as four digits that are taken are typed, a red line says "Primary already ends ••2210. Each bank account needs its own last four digits." and Add stays off. A bank account and a card may share digits. Form errors use one shared look, `LoopdErrorNote` (owner, 18 Nov 2026): a soft red box with a red border and an error icon on the left.
- **Empty sections:** with no accounts or cards, only the dashed Add button shows, and the section total is hidden.
- **Default on a credit card:** a solid white "Default" pill next to the nickname, in the card's colour, so it shows on any bank colour (owner, 18 Nov 2026).
- **Capture button:** steps aside while any sheet or dialog is open, on every tab (owner, 18 Nov 2026).
- **Toasts** ("Added Savings", "Cash in hand is now ₹2,350") slide down at the top of the screen, under the status bar, over pages and sheets alike (owner, 18 Nov 2026). The Review mockup's toast with Undo sits at the bottom; when the Review Inbox is built (Phase 3) it moves to the top too.

## Phase 2, part 4: expense categories (18 Nov 2026)

Built from screens 10c and 10d (`CategorySheet.dc.html`, expense mode), with these additions:

- **One tall sheet** opened from the Expense categories row in More (the row no longer says "Phase 2"). The list, New category and Edit category are views of the same sheet, with a back arrow to the list, as in the mockup. The phone's back button also returns from the form to the list. **There is no close (X) button** (owner, 18 Nov 2026): swipe the sheet down, or press back on the list. Tapping a row opens it as **Edit category** (rename, recolour or change the icon), with "Save changes", faded until something changes.
- **The icons are drawn from the mockup's own paths**, so they match it exactly.
- **No two categories share a colour or an icon** (owner, 18 Nov 2026), and the categories table enforces it. The icons grow from twelve to **twenty-five** (phone, car, plane, film, book, graduation cap, paw, dumbbell, scissors, Wi-Fi, lightning, shirt and Misc's dots, drawn in the mockup's style), and the palette from eight to **twenty-five colours**, one for each icon. New category shows only the colours and icons no category has; Edit category also shows its own. So there are **at most twenty-five categories**; the limit is the number of icons. Four defaults that shared a colour moved to new ones: Fun, Rent, Subscriptions and Gifts.
- **Misc** is a thirteenth default category (grey, three dots), last in the list on an existing install. It is where a deleted category's expenses go unless the owner picks another.
- **Deleting categories** (owner, 18 Nov 2026): only categories the owner added can be deleted; the thirteen defaults always stay.
  - Below the list, beside New category, a red round delete button starts choosing; so does a long press on a category you added, and Edit category of one you added has a red delete button in its header.
  - While choosing, the title is "Delete categories". The categories you added shake (tick circle and tile, about four degrees each way with a small hop; still when the phone asks for less motion) and show a red tick circle; the defaults are faded with "Default". The bottom button reads "Delete 2 categories".
  - A short sheet then asks "Delete 2 categories?" with one line, "3 expenses will move to Misc.", which follows the chip chosen under "Move to" (every remaining category; Misc first chosen), and "Keep" or "Delete". Without expenses the line is "No expenses to move."
  - Each moved expense and refund is saved as an edit, as if recategorised by hand. The toast says "Deleted Tea · expenses moved to Misc". The deleted category's name, colour and icon are free again.
  - At the limit, the note "You have 25 categories, the most there can be. Delete one you added to make room." shows at the bottom, and the button reads **Delete categories** instead of New category. The expense form's "+ New" says the same in a toast.
- **Names** are required, at most 20 letters, and unique ignoring case and spaces: typing one already used shows "You already have a category called Food." in the red error box, and the button stays faded. A new category starts on the first free colour and the first free icon, and goes last in the list.
- **A renamed category keeps its past expenses.**
- **The expense form** ends its category grid with a dashed "+ New" chip. It opens New category on its own (no list, no back arrow); adding it returns to the form with the new category chosen. The number pad closes first; once New category is fully up, the name field opens the letter keyboard; back on the form no keyboard is open, and the amount is kept (owner, 18 Nov 2026).

## Phase 2, part 3: the expense form (18 Nov 2026)

Built from screens 3, 3b and 3c (`AddExpense.dc.html`, add mode), with these changes:

- **A tall sheet, not a page** (owner, 18 Nov 2026), like Accounts and cards: a title with Close on the right instead of the mockup's centred title and X on the left. It covers the tab bar, keeps one height from the start and draws the form only once the accounts, cards, Cash in hand and categories have loaded. The capture sheet's Expense shortcut closes the capture sheet and opens this one.
- **Save** sits under a hairline at the bottom of the sheet and stays above the keyboard. It reads "Save ₹250" once an amount is typed and stays faded until there is an amount, an account or card, and a category.
- **The account or card** starts on the default; with no default and only one account, on that one; otherwise nothing is chosen until you tap one. With none at all, the list is replaced by a line ("No bank accounts yet. UPI is paid from one.") and the dashed Add button, which opens the Add sheet on top.
- **Category** shows every category in the three-column grid (the mockup shows six); the category sheet arrives in part 4. Nothing is chosen at first. A long name, such as Subscriptions, shrinks a little to fit.
- **Date and time** reads "Today, 10:29 am", "Yesterday, 9:15 pm" or "13 Nov, 10:29 am", and opens the date picker, then the time picker. A time still to come is refused with a red note.
- **The amount** is grouped as you type (1,23,456), with at most two decimals.
- **Default pill** (owner, 18 Nov 2026): the same pill as on Accounts and cards, green for a bank account and violet for a card, instead of the mockup's grey tag. On the chosen row, whose background is already that tint, the pill sits on the plain surface so it still shows. An account removed since an expense was saved shows a grey "Removed" pill.
- **Undo:** after a save, a toast at the top says "Saved ₹250 · Food" with Undo for four seconds. Editing an expense (the same sheet, titled "Edit expense") adds a red delete button next to Close; Delete has Undo too. Expenses are opened for editing from the Money tab's list once it is built (part 5).

## Review of the Phase 1 screens (17 Nov 2026)

Changed in the app and on the canvas (version 57), with nothing else on the canvas changed:

| Feedback | Change |
| --- | --- |
| SMS detection hint did not match the mockup | The app uses the mockup's text: "Turns bank messages into cards to confirm" |
| More tiles | App: the large faint picture sits off the bottom-right corner as in the mockup (120 px, 14% white), a shield for Vault and a timer for Screen time; the small icons stay a folder with a star (Vault) and an hourglass (Screen time). Canvas: Vault's small icon is now the folder with a star instead of the padlock |
| Capture sheet: the input's border and button were missing | App: the input has a visible border, and the Save button sits under it, faded until the assistant understands typed text (Phase 9) |
| Task shortcut colour looked like Expense green | Rose was tried and rejected; from three options in the gallery the owner chose **blue**: `#60A5FA` dark, `#1D4ED8` light, tints `rgba(96,165,250,0.16)` and `#DBEAFE` (canvas version 60) |

Canvas version 58 brings the component review into the mockups too: Today's review stack shows two clear 10 px edges (94% and 88% wide, the back one at 75%), and "Back up now" on the Backup & restore page has the cloud-upload icon and fades to 40% while a backup runs (the faded disabled look). The capture sheet's input border is green in the app, as in the mockup. The Task colour is blue (canvas version 60). The capture button stays on every tab (owner confirmed).
