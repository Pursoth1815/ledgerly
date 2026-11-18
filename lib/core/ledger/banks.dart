/// The banks offered in the Add account sheet (mockup `AddAccount.dc.html`).
///
/// [Bank.code] is the six-letter SMS sender code an account is linked to,
/// whatever the two-letter prefix (review decision, 15 Nov 2026). These codes
/// are the mockup's examples; Phase 3 checks them against real messages and
/// completes the list. A bank that is missing can be typed by name; it then
/// has no code.
library;

class Bank {
  const Bank(this.name, this.code, this.colour, {this.cardsOnly = false});

  final String name;
  final String code;

  /// The card colour, as 0xAARRGGBB. Fixed in both themes, like a real card.
  final int colour;

  /// Listed only when adding a credit card, such as a bank's card division.
  final bool cardsOnly;
}

const banks = <Bank>[
  Bank('HDFC Bank', 'HDFCBK', 0xFF1E3A8A),
  Bank('HDFC Bank Credit Cards', 'HDFCBK', 0xFF1E3A8A, cardsOnly: true),
  Bank('ICICI Bank', 'ICICIT', 0xFF9A3412),
  Bank('State Bank of India (SBI)', 'SBIINB', 0xFF155E75),
  Bank('Federal Bank', 'FEDBNK', 0xFFA16207),
  Bank('Indian Bank', 'INDBNK', 0xFF0F766E),
  Bank('YES BANK', 'YESBNK', 0xFF1D4ED8),
  Bank('RBL Bank', 'RBLBNK', 0xFF7C2D12),
  Bank('Axis Bank', 'AXISBK', 0xFF831843),
  Bank('Kotak Mahindra Bank', 'KOTAKB', 0xFFB91C1C),
  Bank('IDFC FIRST Bank', 'IDFCFB', 0xFF7F1D1D),
  Bank('IndusInd Bank', 'INDUSB', 0xFF78350F),
  Bank('Bank of Baroda', 'BOBTXN', 0xFFC2410C),
  Bank('Canara Bank', 'CANBNK', 0xFF1E40AF),
  Bank('Punjab National Bank', 'PNBSMS', 0xFF9F1239),
];

/// The listed bank called [name], ignoring case; null for a bank typed by
/// hand.
Bank? bankNamed(String? name) {
  if (name == null) return null;
  final wanted = name.trim().toLowerCase();
  for (final bank in banks) {
    if (bank.name.toLowerCase() == wanted) return bank;
  }
  return null;
}
