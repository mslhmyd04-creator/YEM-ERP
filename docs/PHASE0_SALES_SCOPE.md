# Basic sales and inventory boundary

Migration 008 adds cash/credit/service sales with whole-unit stock opening/sales, the minimum Phase 0 stock-backed invoice. Advanced inventory remains a later phase.

- Warehouse belongs to the selected branch/company; archived products cannot enter new invoices.
- Administrators configure default accounts and stock opening. Configuration resumes by code without duplicates; opening quantity/unit cost must be positive.
- Whole units up to one billion and exact YER minor units are supported. No fractional quantities, tax separation, discounts, returns, serials, batches or transfers.
- Quantity/value derive from immutable movements. Moving weighted-average cost rounds half-up; full depletion consumes the exact residual value. Negative stock is rejected.
- Snapshot recheck under the posting lock protects cost; invoice/GL/stock/numbering/audit commit or roll back together. Sales debit cash/receivable, credit sales, and debit COGS/credit inventory for goods.
- UUID is identity; SI number is display numbering. Exact retry creates no extra movement or number; changed customer/payment/product/warehouse/quantity/price conflicts. Retries after other stock movements use stored cost.
- Company/branch/customer/item/unit labels are frozen at posting for historical invoices/PDF.
- sales.view authorizes scoped input/history/PDF reads. Creating invoices requires sales.create and finance.post; configuration/stock opening additionally require administration.manage.
- Arabic PDF embeds licensed Amiri offline, checks the same authenticated session and sales.view before/after async rendering and again at the print callback. Exact large numbers, long SKU and 50-line pagination pass visual review.

Verification: 37352094707 passes analysis, 68 Flutter tests per runner, 17 SQL checks and both builds. PHASE0_PDF_QA.md records visual evidence. Device/printer results remain NOT VERIFIED.
