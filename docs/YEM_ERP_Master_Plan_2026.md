# YEM ERP — الخطة الشاملة لإنشاء نظام محاسبة ومخزون وعهد مالية آمن

**الإصدار:** 1.0  
**التاريخ:** 28 سبتمبر 2026  
**الغرض:** وثيقة واحدة تُرسل إلى مولد ذكاء اصطناعي أو فريق برمجي لبناء التطبيق من البداية حتى APK وWindows.

---

## 1) خلاصة البحث عن أفضل مشاريع GitHub

تمت مقارنة أشهر المشاريع المفتوحة/المتاحة المصدر ذات الصلة بالمحاسبة وERP، مع التركيز على النشاط الحالي، الشعبية، اكتمال المحاسبة والمخزون، سهولة التخصيص، وإمكانية استخدام المشروع كأساس لتطبيق YEM ERP.

### Odoo Community
- المستودع: `odoo/odoo`
- اللغة الأساسية: Python.
- عدد النجوم وقت البحث: نحو **54.7 ألف**.
- نشط جدًا، والفرع الافتراضي الحالي وقت البحث: `20.0`.
- يحتوي منظومة ERP كبيرة جدًا: المبيعات، المشتريات، المخزون، المحاسبة، POS، CRM، وغيرها.
- النسخة Community مرخصة أساسًا تحت LGPLv3، بينما Enterprise لها ترخيص منفصل.
- أقوى مشروع من ناحية الانتشار والحجم، لكنه ضخم ومعقد، وبعض القدرات المتقدمة توجد في Enterprise أو إضافات منفصلة.
- ليس أفضل نقطة انطلاق مباشرة لتطبيق Android Offline-First مخصص جدًا، لأن هندسته الأساسية Web/Server وتعديل قلبه سيبطئ المشروع.

### ERPNext
- المستودع: `frappe/erpnext`
- اللغة الأساسية: Python على Frappe Framework.
- عدد النجوم وقت البحث: نحو **39.6 ألف**.
- نشط جدًا وتوجد تحديثات يومية تقريبًا.
- الترخيص: GPL-3.0.
- يحتوي محاسبة حقيقية، مخزون، مشتريات، مبيعات، أصول، POS، Workflow، صلاحيات، مشاريع وتقارير.
- يدعم REST API وRPC عبر Frappe.
- مناسب جدًا كمرجع محاسبي وكخادم خلفي Base Backend للتطبيق.
- من أفضل الخيارات لمشروع YEM ERP لأن منطق المحاسبة والمخزون موجود أصلًا ويمكن إضافة تطبيق مخصص فوق Frappe بدل إعادة كتابة ERP كامل من الصفر.

### Akaunting
- المستودع: `akaunting/akaunting`
- PHP/Laravel.
- نحو **10.1 ألف نجمة**.
- ممتاز للمحاسبة والفواتير والمصروفات.
- يحتوي نظام تطبيقات/Modules، وبعض وظائف Double-Entry وInventory وغيرها تكون عبر Apps.
- أبسط من Odoo وERPNext، لكنه أقل ملاءمة لمشروع ERP كامل فيه مخزون متقدم، عهد، مزامنة Offline، صلاحيات معقدة، وعمليات متعددة المراحل.

### Invoice Ninja
- المستودع: `invoiceninja/invoiceninja`
- نحو **10.1 ألف نجمة**.
- قوي جدًا في الفواتير، المدفوعات، المصروفات، المشاريع.
- لديه تطبيقات Flutter للهواتف وسطح المكتب.
- ليس ERP مخزون ومحاسبة متكاملًا بمستوى ERPNext/Odoo، لذلك يصلح للاستفادة من هندسة Flutter/الواجهات وليس كأساس كامل لـYEM ERP.

### Dolibarr
- المستودع: `Dolibarr/dolibarr`
- نحو **7.7 ألف نجمة**.
- PHP.
- ERP/CRM عملي ومرن ويحتوي مخزونًا وفواتير ومحاسبة مزدوجة ومصاريف.
- أخف من Odoo، لكن هندسة تطبيق Offline مخصص مع Sync متقدم ستحتاج عملًا كبيرًا كذلك.

### Tryton
- Python ERP قوي ومهني.
- أقل انتشارًا على GitHub مقارنة بالمشاريع السابقة.
- ممتاز تقنيًا، لكن مجتمع GitHub الظاهر أصغر، وبالتالي ليس الاختيار الأسرع لمشروعنا.

---

# 2) القرار المقترح لمشروع YEM ERP

## ليس المطلوب نسخ Odoo أو ERPNext بالكامل

أفضل وأسرع مسار هو:

**ERPNext/Frappe = المحرك المركزي والمرجع المحاسبي**
+
**Flutter = تطبيق Android وWindows الخاص بنا**
+
**SQLite مشفر = العمل Offline**
+
**Sync API مخصص = المزامنة الآمنة**
+
**إضافات YEM ERP داخل Frappe App منفصل بدون تعديل Core قدر الإمكان**

السبب:

1. لا نعيد اختراع شجرة الحسابات والقيود وStock Ledger والفواتير من الصفر.
2. ERPNext يملك منطقًا محاسبيًا ومخزنيًا ناضجًا.
3. Frappe يوفر API جاهزًا يمكن البناء فوقه.
4. Flutter يعطينا Android + Windows من قاعدة كود مشتركة.
5. نستطيع إنشاء نسخة Android Offline Strict بدون INTERNET Permission.
6. نستطيع بناء واجهة عربية كاملة خاصة بنا دون نسخ واجهة ERPNext.
7. نستطيع إضافة نظام العهد المالية ورسائل الصرافة بالشكل الخاص بنا.

---

# 3) البنية النهائية المقترحة

```text
YEM ERP
│
├── Flutter Android
│   ├── Offline Strict APK
│   ├── LAN APK
│   └── Online APK
│
├── Flutter Windows
│
├── Local Database
│   └── SQLite + SQLCipher
│
├── Local Business Engine
│   ├── Sales
│   ├── Purchases
│   ├── Inventory
│   ├── Custody
│   ├── Expenses
│   └── Local provisional posting
│
├── Sync Engine
│   ├── Outbox
│   ├── Inbox
│   ├── Delta Sync
│   ├── Conflict Resolver
│   └── Idempotency
│
└── Server
    ├── Frappe Framework
    ├── ERPNext
    ├── Custom App: yem_erp_core
    ├── Custom Sync API
    └── MariaDB/PostgreSQL حسب النسخة المعتمدة
```

مهم جدًا:
- لا تعدل ملفات ERPNext Core إلا للضرورة القصوى.
- كل تخصيصاتنا تكون داخل Frappe App مستقل مثل:
  `yem_erp_core`
- التطبيق المحمول لا يتصل بقاعدة البيانات مباشرة.
- الاتصال يكون عبر API فقط.

---

# 4) أوضاع الاتصال الثلاثة

## Offline Strict
نسخة APK لا تحتوي أصلًا على:

```text
android.permission.INTERNET
```

ويمنع فيها:
- Analytics.
- Ads.
- Firebase.
- Crash reports خارجية.
- Telemetry.
- WebView خارجي.
- Update عبر الإنترنت.
- أي SDK يرسل بيانات.

كل شيء محلي.

## LAN Only
يسمح بالمزامنة مع Windows/Server داخل الشبكة المحلية فقط.
مثال:
`192.168.1.20`

ولا يتم إرسال شيء للإنترنت الخارجي.

## Secure Online
- HTTPS فقط.
- TLS حديث.
- Access token قصير.
- Refresh token مشفر.
- Device registration.
- إمكانية إلغاء جلسة/جهاز.
- Rate limiting.
- Audit log.
- Allowlist للخادم.
- Certificate pinning عند تصميمه مع آلية دوران للشهادة.

---

# 5) الوحدات الرئيسية المطلوبة

1. المحاسبة.
2. شجرة الحسابات.
3. القيود اليومية.
4. المبيعات.
5. المشتريات.
6. المخزون.
7. المخازن.
8. العملاء.
9. الموردون.
10. الصندوق.
11. البنوك.
12. سند قبض.
13. سند صرف.
14. سند حوالة.
15. النفقات.
16. العهد المالية.
17. مراكز التكلفة.
18. المشاريع.
19. الأصول.
20. POS.
21. الجرد.
22. الباركود.
23. السيريال.
24. الدفعات Batch.
25. التقارير.
26. الصلاحيات.
27. النسخ الاحتياطي.
28. المزامنة.
29. أرشفة رسائل الصرافة.
30. الإشعارات.
31. الأمان.
32. التفعيل.
33. PDF والطباعة.
34. Excel Import/Export.
35. Windows Client.

---

# 6) المحاسبة

## شجرة الحسابات
دعم شجرة غير محدودة المستويات:
- الأصول.
- الخصوم.
- حقوق الملكية.
- الإيرادات.
- المصروفات.

أمثلة:
- الصندوق.
- البنوك.
- العملاء.
- الموردون.
- المخزون.
- عهد الموظفين.
- مصروف الوقود.
- مصروف النقل.
- الرواتب.
- الإيجارات.

## القيد المزدوج
كل قيد يجب أن يحقق:

```text
Total Debit = Total Credit
```

ولا يتم اعتماد مستند مالي إذا لم يتوازن القيد.

## Posting Engine
إنشاء محرك مركزي:

```text
Business Document
      ↓
Posting Engine
      ↓
General Ledger
      +
Stock Ledger عند الحاجة
```

لا تضع منطق القيود داخل صفحات Flutter.

---

# 7) أمثلة القيود التلقائية

## بيع آجل
```text
Debit: العميل
Credit: المبيعات
```

ومع تكلفة المخزون:
```text
Debit: تكلفة البضاعة المباعة
Credit: المخزون
```

## قبض من العميل
```text
Debit: الصندوق/البنك
Credit: العميل
```

## إعطاء عهدة لموظف
```text
Debit: عهد الموظفين
Credit: الصندوق/البنك/حساب الصرافة
```

## اعتماد مصروف من العهدة
```text
Debit: حساب المصروف
Credit: عهدة الموظف
```

## شراء مخزون
يتم إنشاء القيود حسب إعداد المخزون الدائم وطريقة الاستلام/الفاتورة.

---

# 8) المبيعات

دعم:
- عرض سعر.
- أمر بيع.
- تسليم.
- فاتورة.
- قبض.
- مرتجع.
- Credit Note.

الفاتورة تحتوي:
- UUID.
- الرقم.
- العميل.
- التاريخ.
- الفرع.
- المخزن.
- المندوب.
- الأصناف.
- الكمية.
- الوحدة.
- السعر.
- الخصم.
- الضريبة.
- الإجمالي.
- المدفوع.
- المتبقي.
- طريقة الدفع.
- الملاحظات.

---

# 9) المشتريات

دعم:
- طلب شراء.
- طلب عرض سعر.
- أمر شراء.
- استلام بضاعة.
- فاتورة مورد.
- دفع.
- مرتجع شراء.

يجب السماح للمؤسسة باختيار دورة مبسطة أو كاملة.

---

# 10) المخزون

كل حركة يجب أن تدخل Stock Ledger.

حقول أساسية:
- UUID.
- Product.
- Warehouse.
- Document Type.
- Document ID.
- Quantity In.
- Quantity Out.
- Running Balance.
- Cost.
- Timestamp.
- User.
- Device.

لا تعتمد على `products.quantity` كمصدر وحيد للحقيقة.

## التقييم
دعم:
- Weighted Average.
- FIFO مستقبلًا.

## منع السالب
`Allow Negative Stock = OFF` افتراضيًا.

---

# 11) المخازن

دعم مخازن متعددة:
- المخزن الرئيسي.
- معرض.
- مخزن مرتجعات.
- مخزن تالف.
- مخزن مشروع.

دعم:
- تحويل مخزني.
- طلب نقل.
- استلام النقل.
- جرد.
- تسوية.

---

# 12) السيريال والدفعات

## Serial Number
- فريد.
- المورد.
- فاتورة الشراء.
- تاريخ الدخول.
- المخزن.
- العميل عند البيع.
- الضمان.

## Batch
- رقم الدفعة.
- الإنتاج.
- الانتهاء.
- الكمية.

---

# 13) الوحدات

مثال:
```text
1 كرتون = 24 حبة
```

يجب دعم:
- شراء بالكرتون.
- بيع بالحبة.
- تحويل تلقائي.

---

# 14) POS

واجهة سريعة:
- Barcode.
- بحث.
- شاشة لمس.
- نقدي.
- بنك.
- حوالة.
- آجل.
- طرق دفع متعددة.
- طابعة حرارية.
- فتح وإغلاق وردية.

---

# 15) الصندوق والبنوك

## Cash
- أكثر من صندوق.
- صندوق لكل فرع.
- صندوق لكل مستخدم.
- رصيد افتتاحي.
- حركة.
- إغلاق يومي.

## Bank
- الحساب.
- IBAN.
- العملة.
- الرصيد.
- إيداع.
- سحب.
- تحويل.
- Bank Reconciliation.

---

# 16) إدارة النفقات

كل مصروف يحتوي:
- رقم.
- التاريخ.
- الفئة.
- الحساب.
- المبلغ.
- العملة.
- الضريبة.
- طريقة الدفع.
- الصندوق/العهدة.
- المورد.
- مركز التكلفة.
- المشروع.
- الفرع.
- الوصف.
- المرفق.
- المستخدم.
- حالة الاعتماد.

أنواع:
- وقود.
- نقل.
- صيانة.
- اتصالات.
- إنترنت.
- إيجار.
- كهرباء.
- ماء.
- ضيافة.
- مشتريات مكتبية.
- سفر.
- رواتب.
- تسويق.
- أخرى.

دعم Recurring Expenses.

---

# 17) نظام الماليين والعهد

هذه وحدة أساسية في المشروع.

## الهيكل
```text
System Admin
  ↓
Finance Manager
  ↓
Finance Supervisor
  ↓
Custodian / Financial Officer
  ↓
Employee
```

## مثال
يمنح المدير المالي الأول:
`1,000,000 ريال`

يسجل المالي يوميًا:
- وقود 50,000.
- نقل 20,000.
- معدات 120,000.

التطبيق يعرض:
```text
العهدة الأصلية: 1,000,000
المصروف:        190,000
المتبقي:        810,000
```

ويعمل بدون إنترنت.

---

# 18) Custody Ledger

لا يتم حفظ المتبقي كرقم يدوي فقط.

الحساب:
```text
الرصيد =
المبالغ المستلمة
+ إضافات العهدة
- المصروفات
- التحويل للآخرين
- المرتجع للمدير
```

كل حركة تسجل:
- UUID.
- Custody ID.
- Employee.
- Type.
- Amount.
- Before balance.
- After balance.
- Reference.
- Device.
- User.
- Sync status.

---

# 19) حالات العهد

```text
Draft
Approved
Active
Partially Settled
Pending Review
Settled
Closed
Cancelled
```

---

# 20) المصروف اليومي للمالي

واجهة سريعة جدًا:
- المبلغ.
- نوع المصروف.
- التاريخ.
- الجهة.
- الغرض.
- طريقة الدفع.
- رقم المرجع.
- الملاحظات.
- صورة الإيصال.

حالات:
```text
Draft
Submitted
Approved
Rejected
Needs Clarification
Posted
```

المصروف المرفوض لا يحذف.

---

# 21) Dashboard المدير المالي

يعرض لكل مالي:
```text
الاسم
العهدة المستلمة
إجمالي المصروف
المتبقي
المعاملات المعلقة
آخر مزامنة
المرفقات الناقصة
الفروقات
```

ويعرض إجمالي الإدارة:
- إجمالي العهد.
- المصروف.
- المتبقي.
- بانتظار المراجعة.
- فروقات.
- أجهزة لم تزامن.

---

# 22) تسوية العهدة

تقرير:
```text
المبلغ المستلم
+ الإضافات
- المصروفات المعتمدة
- المبالغ المرتجعة
= المتبقي
```

يفضل ألا تغلق العهدة إلا عندما:
`Remaining = 0`
أو مع استثناء موثق من المدير.

---

# 23) حدود الصرف والموافقات

مثال:
- حتى 50,000: اعتماد مباشر حسب السياسة.
- 50,001 إلى 200,000: موافقة المشرف.
- أعلى من ذلك: المدير المالي.

يجب أن تكون الحدود قابلة للتعديل.

دعم Maker/Checker:
- منشئ العملية.
- المراجع.
- المعتمد.
- من قام بالترحيل المحاسبي.

---

# 24) أرشفة رسائل الصرافة

إنشاء وحدة:
**Exchange Notification Archive**

مصادر:
1. SMS.
2. Android Notifications.
3. WhatsApp Notification.
4. Share to YEM ERP.

مهم:
- لا يتم اختراق WhatsApp.
- لا تتم قراءة قاعدة بيانات WhatsApp.
- الاستخدام فقط عبر Notification Access الذي يوافق عليه المستخدم أو Share Intent.

---

# 25) حماية الخصوصية في الرسائل

لا يتم أرشفة كل رسائل الهاتف.

يجب أن يكون المسار:

```text
Notification/SMS
      ↓
Local Filter
      ↓
Financial Message?
   ↙         ↘
 Yes          No
 ↓            ↓
Archive       Discard
```

الفلاتر:
- Sender ID.
- رقم محدد.
- اسم شركة.
- كلمات مفتاحية.
- Template.

---

# 26) تحليل رسالة الصرافة

استخراج:
- الاسم.
- المستفيد.
- المبلغ.
- العملة.
- رقم الحوالة.
- رقم العملية.
- رقم السند.
- الغرض.
- الرصيد المتبقي.
- الشركة.
- التاريخ.
- الوقت.
- الرسوم إن وجدت.

ويتم حفظ النص الأصلي كاملًا.

---

# 27) Templates للشركات

لا تستخدم Regex واحدة للجميع.

جدول:
`exchange_message_templates`

حقول:
- provider_id.
- sender patterns.
- amount pattern.
- beneficiary pattern.
- reference pattern.
- balance pattern.
- currency pattern.
- purpose pattern.

كل شركة لها Parser منفصل.

---

# 28) منع التكرار

لكل رسالة:
```text
message_hash = SHA-256(normalized_message)
```

ولا يتم استيراد نفس الرسالة مرتين.

---

# 29) الثقة في الاستخراج

كل حقل مستخرج يمكن أن يحمل:
`confidence`

إذا كانت منخفضة:
- يطلب مراجعة.
- لا يتم اعتماد المعاملة تلقائيًا.

---

# 30) الربط بين الرسالة والعملية

إذا أنشأ المالي عملية تحويل ثم وصلت رسالة مطابقة:
- المبلغ نفسه.
- الاسم قريب.
- التوقيت قريب.
- المرجع مطابق.

يقترح النظام:
**ربط الرسالة بالعملية الموجودة**

ولا ينشئ عملية ثانية.

---

# 31) فرق رصيد الصرافة

إذا ذكرت الرسالة:
`الرصيد المتبقي = 700,000`

يحفظ كـ:
`reported_exchange_balance`

ولا يستبدل الرصيد المحاسبي.

يقارن:
```text
رصيد الصرافة
vs
رصيد النظام
```

وعند وجود فرق:
`Needs Reconciliation`

---

# 32) Ledger للصرافة

لكل شركة صرافة:
- الحساب.
- الرصيد الافتتاحي.
- الإيداعات.
- الحوالات.
- الرسوم.
- الرصيد المحسوب.
- الرصيد المبلغ عنه.
- الفروقات.

---

# 33) الصلاحيات

RBAC مفصل.

أمثلة:
- View Invoice.
- Create Invoice.
- Edit Draft Invoice.
- Submit Invoice.
- Cancel Invoice.
- Print Invoice.
- Export Invoice.
- View Custody.
- Approve Expense.
- View Exchange Messages.
- Export Exchange Archive.
- Manage Devices.
- Revoke Device.
- Restore Backup.

لا يكفي إخفاء الزر.
يجب التحقق من الصلاحية في:
- UI.
- Local service.
- API.
- Backend.

---

# 34) المستخدمون والأجهزة والتفعيل

كل جهاز:
- Device UUID.
- Public Key.
- User.
- Company.
- Status.
- Activated At.
- Last Sync.
- App Version.

الحالات:
```text
Active
Suspended
Revoked
Lost
```

## Activation
يدعم:
- Permanent.
- Timed.

التفعيل يكون بتوقيع رقمي:
- Ed25519 أو ECDSA P-256.

لا تستخدم IMEI كمفتاح وحيد.

المفتاح الخاص بالمنشأة لا يوضع داخل التطبيق.

---

# 35) التشفير

محلي:
- SQLCipher أو تشفير قاعدة مكافئ.
- مفاتيح Android في Keystore.
- Windows عبر DPAPI/Credential Manager/TPM عند توفره.

النقل:
- HTTPS.
- TLS.
- Tokens مشفرة محليًا.

Backup:
- AES-256-GCM.
- Salt.
- KDF مناسب.
- تحقق Integrity.

---

# 36) Audit Log

كل عملية حساسة:
- User.
- Device.
- Timestamp.
- Action.
- Entity.
- Record ID.
- Previous value.
- New value.

يفضل Tamper-Evident Chain:
```text
hash_n = SHA256(hash_previous + canonical_record)
```

---

# 37) النسخ الاحتياطي

دعم:
- Manual.
- Scheduled.
- Local encrypted.
- External file.

قبل Restore:
1. Validate.
2. Verify version.
3. Backup current DB.
4. Test migration.
5. Restore atomically.

---

# 38) Sync Engine

كل Record يحتوي:
- UUID.
- revision.
- created_at.
- updated_at.
- created_by.
- updated_by.
- sync_status.
- server_revision.
- deleted_at.

الحالات:
```text
Local
Pending
Syncing
Synced
Conflict
Failed
```

---

# 39) Outbox Pattern

كل عملية Offline تنشئ Outbox Item:
```text
event_id
entity_type
entity_id
action
payload_hash
created_at
retry_count
next_retry
```

ثم ترسل عند الاتصال.

---

# 40) Idempotency

كل POST حساس يرسل:
`Idempotency-Key`

إذا أعاد الجهاز الطلب بسبب انقطاع الإنترنت:
لا ينشئ الخادم مستندًا مكررًا.

---

# 41) تعارضات المزامنة

لا تستخدم Last-Write-Wins في:
- فواتير معتمدة.
- قيود.
- حركة مخزون.
- سندات.
- عهد.

هذه تدخل Conflict Queue.

---

# 42) Source of Truth

في وضع Online/LAN:
- Server هو المرجع النهائي.
- التطبيق يحتفظ بنسخة محلية للعمل Offline.

في Offline Strict:
- Local DB هو المرجع النهائي لذلك الجهاز.

في Online:
يمكن إنشاء Provisional Local Posting للعرض، لكن الاعتماد النهائي على Server Validation عند Sync.

---

# 43) API

استخدم API مخصصًا داخل Frappe App بدل الاعتماد على CRUD الخام فقط.

أمثلة:
```text
/api/method/yem_erp.sync.pull
/api/method/yem_erp.sync.push
/api/method/yem_erp.auth.device_register
/api/method/yem_erp.custody.submit_expense
/api/method/yem_erp.stock.transfer
/api/method/yem_erp.reports.finance_summary
```

يجب أن تقوم الـAPI بتطبيق:
- Validation.
- Permissions.
- Business rules.
- Idempotency.
- Audit.

---

# 44) الترقيم

لا تستخدم رقم الفاتورة كمفتاح Primary Key.

استخدم UUID داخلي.

الأرقام:
```text
INV-SAN-2026-000001
PUR-SAN-2026-000001
EXP-SAN-2026-000001
CUS-SAN-2026-000001
PAY-SAN-2026-000001
```

وتدار Naming Series من الخادم.

في Offline يمكن تخصيص Block من الأرقام للجهاز أو استخدام Temporary Number ثم Final Number عند Sync.

---

# 45) PDF والطباعة

دعم:
- A4.
- A5.
- 80mm.
- 58mm.
- Bluetooth ESC/POS.
- Windows printer.

كل مستند:
- شعار.
- بيانات الشركة.
- الرقم.
- التاريخ.
- المستخدم.
- تفاصيل العملية.
- QR اختياري.
- التوقيع.

---

# 46) Excel

Import:
- منتجات.
- عملاء.
- موردون.
- أرصدة افتتاحية.
- مخزون.
- أسعار.
- عهد.

عند الخطأ:
```text
Row 18
Column: serial_number
Error: duplicate serial
```

Export:
- تقارير مالية.
- حركة مخزون.
- عهد.
- مصروفات.
- رسائل مالية.

---

# 47) التقارير

المحاسبة:
- Trial Balance.
- General Ledger.
- Balance Sheet.
- Profit & Loss.
- Cash Flow.
- AR Aging.
- AP Aging.
- Bank Reconciliation.

المخزون:
- Stock Balance.
- Stock Ledger.
- Valuation.
- Low Stock.
- Serial.
- Batch.
- Count Variance.

العهد:
- Current Custody.
- Daily Expense.
- Monthly Expense.
- Settlement.
- Employee Balance.
- Missing Receipts.
- Pending Approval.
- Exchange Difference.

---

# 48) البحث العام

البحث عبر:
- رقم فاتورة.
- اسم عميل.
- مورد.
- هاتف.
- منتج.
- Barcode.
- Serial.
- رقم سند.
- رقم حوالة.
- المبلغ.
- الغرض.

---

# 49) الإشعارات

Local notifications:
- مخزون منخفض.
- فاتورة مستحقة.
- عهدة قاربت على النفاد.
- مصروف بانتظار المراجعة.
- لم تتم المزامنة.
- فرق في رصيد الصرافة.

Online push اختياري في النسخة Online فقط.

---

# 50) واجهة المستخدم

RTL عربي كامل.

الشريط:
- الرئيسية.
- المحاسبة.
- المبيعات.
- المشتريات.
- المخزون.
- النفقات.
- العهد.
- الصندوق.
- البنوك.
- العملاء.
- الموردون.
- الصرافات.
- التقارير.
- الإعدادات.

يدعم:
- Dark.
- Light.
- حجم خط.
- إعدادات الطباعة.

---

# 51) شاشة Security Center

تعرض:
```text
Mode: OFFLINE STRICT / LAN / ONLINE
Encryption: ON
Database integrity: PASS
Last backup
Last sync
Device status
App signature
Failed logins
Security warnings
```

---

# 52) قاعدة البيانات المقترحة

```text
companies
branches
users
roles
permissions
role_permissions
devices
activations

accounts
journal_entries
journal_entry_lines
fiscal_years
accounting_periods
cost_centers
projects

customers
suppliers

products
product_categories
units
product_prices
serial_numbers
batches

warehouses
stock_ledger
stock_transfers
stock_counts

sales_invoices
sales_invoice_items
sales_returns

purchase_invoices
purchase_invoice_items
purchase_returns

cash_accounts
bank_accounts
payments
receipts
payment_vouchers
transfer_vouchers

expense_categories
expenses
expense_attachments

custodies
custody_ledger
custody_settlements
custody_approvals

exchange_providers
exchange_accounts
exchange_message_templates
exchange_messages
exchange_message_parsed_fields
exchange_ledger
exchange_matches

attachments
audit_logs
security_logs

sync_outbox
sync_inbox
sync_conflicts
sync_checkpoints

backups
settings
number_sequences
```

---

# 53) حماية التطبيق

Android Release:
- Disable debug.
- Obfuscation.
- Signed APK/AAB.
- FLAG_SECURE اختياري.
- Root detection كإشارة فقط وليس كحماية وحيدة.
- لا Logs حساسة.
- لا أسرار داخل APK.
- Network Security Config.
- Strong Keystore usage.

Windows:
- Signed package.
- Encrypted local DB.
- Secure credential storage.
- Firewall guidance.
- Update signature verification.

---

# 54) كلمات المرور

لا تخزن Password Plain Text.

استخدم خوارزمية قوية مثل:
- Argon2id.
أو ما يوفره Frappe/الإطار بشكل آمن ومعتمد.

دعم:
- Password policy.
- Lockout.
- Session expiry.
- MFA للمدير في النسخة Online.

---

# 55) المرفقات

كل مرفق:
- UUID.
- Owner record.
- MIME.
- Size.
- Hash.
- Encryption flag.
- Local path.
- Server object ID.

في Online يمكن تخزين الملفات في Object Storage.

---

# 56) الاختبارات

## Accounting
- Sale.
- Purchase.
- Return.
- Expense.
- Custody.
- Payment.
- Transfer.
- Currency.

## Inventory
- Negative stock.
- Duplicate serial.
- Transfer.
- Count.
- Return.
- Batch expiry.

## Sync
- Device offline أسبوع.
- Duplicate POST.
- Conflict.
- Interrupted upload.
- Two devices same document.

## Security
- Unauthorized API.
- IDOR.
- SQL injection.
- Path traversal.
- Invalid file upload.
- Backup tampering.
- Token reuse.
- Permission bypass.

---

# 57) مراحل التنفيذ الأسرع

## المرحلة 0 — Prototype
- Flutter project.
- SQLite encrypted.
- Auth local.
- Product/warehouse/customer.
- Expense/Custody.
- Basic invoice.
- PDF.

## المرحلة 1 — ERPNext Server
- Deploy Frappe/ERPNext.
- Create `yem_erp_core`.
- Map accounts and stock.
- Add API.

## المرحلة 2 — Sync
- UUID.
- Outbox.
- Pull/Push.
- Idempotency.
- Conflict.

## المرحلة 3 — Custody
- Custody Ledger.
- Manager Dashboard.
- Approval.
- Settlement.

## المرحلة 4 — Accounting
- Posting validation.
- GL link.
- Cash/Bank.
- AR/AP.

## المرحلة 5 — Inventory Advanced
- Serial.
- Batch.
- Count.
- Barcode.
- POS.

## المرحلة 6 — Exchange Messages
- Notification listener.
- SMS/manual share.
- Parser templates.
- Matching.
- Reconciliation.

## المرحلة 7 — Windows
- Flutter Windows build.
- Admin dashboards.
- Reports.
- Bulk operations.

## المرحلة 8 — Security
- Offline Strict flavor.
- Online flavor.
- Device activation.
- Backup encryption.
- Security audit.

## المرحلة 9 — Production
- Migration tests.
- Integration tests.
- Release signing.
- User documentation.
- Final APKs/Windows package.

---

# 58) ملفات الإخراج المطلوبة

```text
releases/
├── YEM_ERP_Offline.apk
├── YEM_ERP_LAN.apk
├── YEM_ERP_Online.apk
├── YEM_ERP_Windows_x64.zip
└── Server_Deployment_Package.zip
```

---

# 59) تعليمات صارمة لمولد الذكاء الاصطناعي

1. لا تحاول إنشاء النظام في ملف واحد.
2. لا تعدل ERPNext Core إلا عند الضرورة.
3. كل إضافة Server تكون داخل `yem_erp_core`.
4. كل زر في UI يجب أن يكون Functional.
5. كل عملية مالية يجب أن تمر عبر Service/Domain Layer.
6. كل عملية مخزون يجب أن تمر عبر Inventory Engine.
7. كل عملية حساسة تسجل Audit.
8. لا تحفظ مفاتيح أو كلمات مرور كنص.
9. لا تعتبر Build نجاحًا دون Tests.
10. لا تنتقل للمرحلة التالية حتى:

```text
Build = PASS
Unit Tests = PASS
Database Migration = PASS
Accounting Tests = PASS
Stock Tests = PASS
Sync Tests = PASS
```

---

# 60) الخلاصة التنفيذية

**الأعلى شعبية على GitHub:** Odoo.

**الأفضل كأساس عملي لمشروع YEM ERP المطلوب:** ERPNext/Frappe.

**الأسرع لإنهاء التطبيق:** لا تبدأ من الصفر ولا تحاول تحويل Odoo نفسه إلى APK. استخدم ERPNext كخادم/محرك محاسبي، وابنِ Flutter مستقلًا Android + Windows، مع SQLite مشفر وSync Engine مخصص.

**أفضل تقسيم للنسخ:**
1. `YEM ERP Offline Strict` — لا توجد INTERNET Permission.
2. `YEM ERP LAN` — اتصال شبكي داخلي فقط.
3. `YEM ERP Online` — مزامنة مشفرة مع الخادم.

وبهذه البنية تحصل على:
- محاسبة ناضجة.
- مخزون.
- مبيعات ومشتريات.
- عهد ومصروفات.
- متابعة الماليين.
- رسائل الصرافة.
- Android.
- Windows.
- Offline حقيقي.
- Online Sync.
- أمان أقوى.
- وقت تطوير أقل بكثير من كتابة ERP كامل من الصفر.

---

# 61) مصادر مرجعية

- Odoo GitHub: https://github.com/odoo/odoo
- Odoo Documentation: https://www.odoo.com/documentation/
- ERPNext GitHub: https://github.com/frappe/erpnext
- ERPNext Documentation: https://docs.frappe.io/erpnext/
- Frappe REST API: https://docs.frappe.io/framework/user/en/guides/integration/rest_api
- Akaunting GitHub: https://github.com/akaunting/akaunting
- Dolibarr GitHub: https://github.com/Dolibarr/dolibarr
- Invoice Ninja GitHub: https://github.com/invoiceninja/invoiceninja

---

## أمر نهائي للمولد

> قم ببناء المشروع وفق هذه الوثيقة تدريجيًا. ابدأ بإنشاء هيكل المشروع وقاعدة البيانات والطبقات الأساسية، ثم طبق المرحلة 0 واختبرها. بعد كل مرحلة نفذ Build واختبارات تلقائية، أصلح الأخطاء تلقائيًا، وسجل ما تم إنجازه. لا تُنشئ واجهات شكلية غير مرتبطة بالبيانات. يجب أن يبقى المشروع قابلًا للبناء في كل مرحلة، ويجب في النهاية إنتاج APK Offline وAPK Online ونسخة Windows وخادم ERPNext/Frappe مخصص ومجموعة اختبارات ووثائق تشغيل ونسخ احتياطي واستعادة.
