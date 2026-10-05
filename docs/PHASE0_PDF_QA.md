# Arabic PDF visual acceptance

Code: 5d8c545edab01de34072550d0eee1e1ec630f90e; run 37352094707; artifact invoice-arabic-qa (11362513485).
Extracted PDF SHA-256: 73011965c189c027a7e8241b308d67437efa4d68e7f98acfaaf0f4ecf3b34a49.

Input: 50 synthetic Arabic service rows, 104-character first SKU and maximum supported invoice total. Poppler pdfinfo: seven A4 pages, PDF 1.7, 26,511 bytes, no parser warnings. pdffonts confirms embedded Amiri-Regular CID TrueType with Unicode mapping. All seven pages rendered with pdftoppm at 90 dpi and inspected.

| Check | Result |
| --- | --- |
| Joined Arabic/RTL company/customer/branch and labels | PASS |
| SI/date/page fraction use correct numeric order | PASS |
| Table headers repeat on six item pages | PASS |
| All 50 rows and wrapped long SKU intact | PASS |
| First amount 89999999938725.50 and total 90000000000000.00 YER intact | PASS |
| Complete total/description/note block together on page seven | PASS |
| No clipped/overlapping text, missing glyph boxes or broken borders | PASS |

Earlier notes were orphaned from the total; explicit Inseparable fixes that break. The final artifact was rendered and reviewed again. Native printing and physical-device acceptance remain NOT VERIFIED.
