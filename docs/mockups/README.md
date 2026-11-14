# Mockups

Key screens of Kanakku, in dark (designed first) and light themes, for approval before Phase 1.

**View them here:** https://claude.ai/artifact/LGbLMacN52Aq8mq8pi7bNa (private; share it from the page's Share menu if someone else needs to see it).

The files in this folder are the source of that canvas, kept in git so every revision is reviewable in a PR. They are design references, not app code.

## Screens

| # | Screen | Plan section | Interactive |
| --- | --- | --- | --- |
| 1 | Today | 3 | |
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
