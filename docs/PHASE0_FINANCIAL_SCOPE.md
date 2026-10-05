# Phase 0 financial boundary

The current increment is ledger infrastructure for the remaining Phase 0 workflows. It does not implement expenses, custody, sales invoices, approvals, stock valuation, fiscal periods, or PDF printing yet. It is not the full Phase 4 accounting module.

- Phase 0 supports the existing company currency YER and two decimal places. Other currencies are rejected explicitly until conversion/rate and precision policies exist. Entered decimals become exact integer minor units; floating point is not used. Posting totals cannot exceed 9,000,000,000,000,000 minor units.
- Account configuration requires administration.manage. Ledger reads require finance.view; posting requires finance.post. Migration 006 upgrades only manager roles attached to the original bootstrap user that still hold administration.manage, using the bootstrap audit rather than an editable role name. A manager can explicitly assign the new permissions to additional roles.
- PostingEngine validates a real calendar date, UUID business reference, 2–100 one-sided positive lines, exact balance, supported currency and company-owned branch/accounts. Entry UUID and display document number are separate.
- BEGIN IMMEDIATE encloses sequence allocation, header/lines, finalization and audit. An audit/database failure rolls everything back. Ledger balances are derived from posted lines using exact BigInt accumulation; no manually stored balance is authoritative.
- The unique company/reference type/reference UUID acts as the local retry identity. Canonically equal retries return the existing entry without another number, posting or audit. Changed content fails as a conflict and cannot overwrite a posted entry.
- SQL constraints independently reject cross-company accounts and malformed amounts. SQL finalization refuses unbalanced totals, and triggers prevent editing/deleting posted headers or lines. Corrections will use explicit reversal documents, not mutation; reversal workflows are not in this increment.

Next: compose atomic expense and basic custody documents with the posting boundary, then basic invoices and PDF. Business document and ledger changes must commit together. Do not wire financial forms before these application services and their tests exist.
