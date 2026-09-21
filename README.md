# BozorPro (Savdodaftar) — mobil ilova

Bozorchilar va kichik savdogarlar uchun raqamli daftar: mijozlar, qarz, savdo, ombor, xarajat va biznes nazorati. **Flutter (Android / iOS), uz/ru.**

Slogan: **"Daftaringiz endi telefoningizda!"**

Backend: [savdodaftar-backend](https://gitlab.com/savdodaftar-group/savdodaftar-backend) (Laravel + MySQL).

---

# UI/UX SPETSIFIKATSIYASI

## 0. Global design system

### Ranglar

| Nomi | Qiymat | Qayerda |
|---|---|---|
| Primary | `#00A86B` | Asosiy tugmalar, aktiv holatlar, brend |
| Dark Green | `#006B45` | Splash fon, bosilgan holat, sarlavha aksentlari |
| Light Green | `#E9F8F1` | Yengil fonlar, tanlangan chip, success card fon |
| Background | `#F7F9FA` | Ekran foni |
| Card | `#FFFFFF` | Kartalar, input fon |
| Text Primary | `#1A1A1A` | Asosiy matn |
| Text Secondary | `#7A828A` | Ikkilamchi matn, placeholder |
| Danger | qizil (`#E53935`) | Qarz, xatolik, kam qoldiq |
| Warning | sariq/orange (`#F5A623`) | Ogohlantirish |
| Info | ko'k (`#2F80ED`) | Ma'lumot, Telegram/SMS |
| Success | yashil (`#00A86B`) | To'lov, tasdiq |

### UI uslubi

- Mobile-first, iPhone/Android modern UI, oq fon, minimalist.
- Rounded cards, **12–18px border radius**, juda yengil shadow.
- Katta va tushunarli tugmalar; ko'p ishlatiladigan amallar katta button.
- Icon + text kombinatsiyasi.
- O'zbek tilidagi matnlar (ru lokalizatsiya bilan).
- Pul formati: **150 000 so'm** (ming ajratuvchi bo'sh joy).
- Pastki navigatsiya doimiy ko'rinadi.

### Tipografika

Font: **Inter** (fallback: SF Pro / Roboto)

| Element | O'lcham | Vazn |
|---|---|---|
| Screen title | 20–22px | Bold |
| Section title | 16–18px | Semibold |
| Body | 14–16px | Regular |
| Secondary text | 12–13px | Regular |
| Button | 14–16px | Semibold |

---

## 1. Splash screen

- Full screen **Dark Green** fon.
- Markazda: BozorPro logo (do'kon/bozor ikonkasi) + **BozorPro**.
- Pastida: *Daftaringiz endi telefoningizda!*
- Pastki qismda kichik loading animatsiya.

**Flow:** Splash → Onboarding. Agar user avval login qilgan bo'lsa: Splash → PIN → Home.

## 2–4. Onboarding (3 ekran)

| # | Sarlavha | Tavsif | Illustratsiya | Tugma |
|---|---|---|---|---|
| 1 | Qog'oz daftarni unuting | Mijozlar, qarzlar va savdoni telefoningizda saqlang. | Telefon + daftar + checklist + yashil tasdiq ikon | Keyingi |
| 2 | Savdoni hisoblang | Har bir savdo va to'lov avtomatik hisoblanadi. | Telefon, savdo, pul va statistik grafik | Keyingi |
| 3 | Biznesingizni nazorat qiling | Bugungi savdo, foyda, qarzlar va omborni bir joyda ko'ring. | — | Boshlash |

Pastki qismda 3 ta pagination dot.

## 5. Ro'yxatdan o'tish

**Header:** logo *BozorPro*, title *Ro'yxatdan o'tish*.

**Form:**
- Telefon raqami: `+998 90 123 45 67`
- Button: **SMS kodni yuborish**
- Divider: *Yoki*
- Google login button: *Google bilan davom etish*

**Foydalanuvchi ma'lumotlari (OTP dan keyin):**
- Input: *Ismingiz* (masalan: Abdulloh)
- Input: *Do'kon nomi* (masalan: Bozor Market)
- *Nima sotasiz?* chip/buttonlar: `Kiyim` `Oziq-ovqat` `Poyabzal` `Maishiy texnika` `Boshqa`
- Bottom button: **Davom etish**

## 6. SMS tasdiqlash

- Title: *SMS kodi*
- Description: *Telefon raqamingizga yuborilgan kodni kiriting.*
- 6 ta OTP input: `1 2 3 4 5 6`
- Timer: *Qayta yuborish (01:23)*
- Button: **Davom etish**
- Link: *Ortga*

## 7. PIN kod o'rnatish

- Header: back arrow.
- Title: *PIN kod o'rnating*
- Description: *Ilovadan har safar foydalanish uchun PIN kod yarating.*
- PIN indikatori: 4 (yoki 6) ta nuqta `● ● ● ●`
- Numeric keyboard:

```
1  2  3
4  5  6
7  8  9
   0  ⌫
```

- Pastki text: *PIN kodni unutmang!*

**Flow:** PIN yaratish → PINni qayta kiritish → Home.

## 8. Bosh sahifa / Dashboard

**Header:**
- Chap: kichik avatar, *Assalomu alaykum,* **Abdulloh 👋**, sana *16-sentabr, 2026*
- O'ng: notification icon

**Statistik kartalar (4 ta):**

| Savdo | Foyda | Qarz berildi | Qarz qaytdi |
|---|---|---|---|
| 2 450 000 so'm | 630 000 so'm | 450 000 so'm | 200 000 so'm |

**Quick actions (4 ta katta rangli button):** 🛒 Savdo · 💰 Qarz · 💳 To'lov · 📦 Kirim

**Ogohlantirishlar** — section *E'tibor berish kerak*:
- Card: *3 ta mijozning qarzi muddati o'tgan* → button **Ko'rish**
- Card: *5 ta mahsulot tugash arafasida* → button **Omborni ko'rish**

**Bottom Navigation:** Bosh sahifa · Mijozlar · Qarzlar · Ombor · Ko'proq

## 9. Savdo — mahsulotlar

- Header: back arrow, title *Savdo*
- Search: *Mahsulot qidirish...*, o'ng tomonda barcode scanner ikonkasi
- Category chips: `Barchasi` `Kiyim` `Poyabzal` `Boshqa`
- Product card: rasm, nom, sotuv narxi, qoldiq, **+** button
  - Masalan: *Futbolka* — 120 000 so'm — Qoldiq: 12
- Cart (pastki panel): *Savat (2)* — 420 000 so'm → button **To'lovni yakunlash**

## 10. Savdo — mahsulot tanlash

- Rasm, nom *Futbolka*, narx *120 000 so'm*
- Quantity selector: `− 2 +`
- Jami: *240 000 so'm*
- To'lov usuli (radio): ● Naqd ○ Karta ○ Qarz
- Bottom: **Sotuvni yakunlash**

## 11. Savdo yakunlandi / Chek

- Full green confirmation screen, markazda **✓** va *Savdo yakunlandi!*
- Card: *Jami: 420 000 so'm*
- Buttons: **Chekni ko'rish** · **Yuborish** · **Bosh sahifa**

## 12. Mijozlar ro'yxati

- Header: *Mijozlar*
- Search: *Mijoz qidirish...*
- Filter chips: `Barchasi` `Qarzdorlar` `Qarzi yo'q`
- Row: avatar, *Ali*, *+998 90 123 45 67*; o'ngda summa *150 000 so'm* (qizil — qarzdor), qarz bo'lmasa *0 so'm*
- Pastki button: **+ Yangi mijoz**

## 13. Mijoz profili

- Header: back arrow, title *Mijoz profili*
- Profil: avatar, *Ali*, *+998 90 123 45 67*
- Qizil debt card: *Qarzdor* — **150 000 so'm**
- Action buttons: **To'lov qabul qilish** · **Qarz qo'shish** · **Eslatma yuborish** · **Tarix**
- History:
  - 16.09 · +150 000 · qarz
  - 10.09 · −100 000 · to'lov
  - 05.09 · +250 000 · qarz
- Past: *Jami qarz: 150 000 so'm*

## 14. Qarz berish

- Header: *Qarz berish*
- Search: *Mijoz qidirish...*; tanlangan mijoz: *Ali, +998 90 123 45 67*; button **+ Yangi mijoz**
- Form: Qarz summasi *150 000 so'm* · Sabab *2 ta futbolka* · To'lov sanasi *20.09.2026*
- Button: **Qarzga yozish**

## 15. To'lov qabul qilish

- Title: *To'lov qabul qilish*
- Mijoz: *Ali*, Qarz: *150 000 so'm*
- Input: *To'lov summasi* — 100 000 so'm
- Radio: ○ To'liq to'lov ○ Qisman to'lov
- Button: **Saqlash**
- Info card: *Qolgan qarz: 50 000 so'm*

## 16. Qarzdorga eslatma

- Title: *Qarzdorga eslatma*
- Text area (tayyor shablon): *Assalomu alaykum, Ali. Sizda 50 000 so'm qarzdorlik mavjud. To'lovni amalga oshirishingizni so'raymiz.*
- Kanal tugmalari: 🔵 Telegram · 🟢 WhatsApp · 🔵 SMS
- Bottom: **Yuborish**

## 17. Ombor

- Header: back + *Ombor*
- Search: *Mahsulot qidirish...*
- Filter chips: `Barchasi` `Kam qolgan` `Tugagan`
- Product row: nom, qoldiq, narx, status
  - Futbolka · 12 dona · 120 000 so'm · 🟢 Yetarli
  - Shim · 8 dona · 180 000 so'm · 🟢 Yetarli
  - Ko'ylak · 5 dona · 🔴 Kam qolgan
  - Krossovka · 3 dona · 🔴 Kam qolgan
- Bottom: **+ Mahsulot qo'shish**

## 18. Mahsulot qo'shish

- Header: back, title *Mahsulot qo'shish*
- Image upload area: 📷 *Rasm*
- Form: Mahsulot nomi *Futbolka* · Kategoriya *Kiyim* · Kelish narxi *70 000 so'm* · Sotish narxi *120 000 so'm* · Boshlang'ich qoldiq *50* · Minimal qoldiq *5*
- Button: **Saqlash**

## 19. Omborga kirim

- Title: *Omborga kirim*
- Tanlangan mahsulot: *Futbolka*, Hozirgi qoldiq: *12 dona*
- Kirim miqdori: *+30 dona* · Kelish narxi: *70 000 so'm*
- Bottom: **Kirimni saqlash**
- Success: *Yangi qoldiq: 42 dona*

## 20. Xaridlar

- Title: *Xaridlar*
- Filter chips: `Barchasi` `Bugun` `Bu hafta`
- Purchase card: yetkazib beruvchi nomi, summa, status (`Qarzdor` qizil / `To'landi` yashil)
  - Uzbek Textile · 200 000 so'm
  - Kiyim Plus · 2 300 000 so'm
  - Best Shoes · 3 200 000 so'm
- Bottom: **+ Xarid qo'shish**

## 21. Yetkazib beruvchilar

- Title: *Yetkazib beruvchilar*
- Supplier card: nom, telefon, *Qarz: 2 300 000 so'm*, *Original qarz: 2 300 000 so'm*
  - Uzbek Textile · +998 90 112 22 33 · Qarz 2 300 000 so'm
  - Kiyim Plus · telefon · Qarzdor: 0 so'm
- Bottom: **+ Yetkazib beruvchi qo'shish**

## 22. Xarajatlar

- Title: *Xarajatlar*
- List (rangli kategoriya ikonkasi + nom + summa):
  - 🟠 Ijara · 500 000 so'm
  - 🔵 Transport · 120 000 so'm
  - 🟢 Ishchi maoshi · 300 000 so'm
  - 🟢 Elektr · 80 000 so'm
  - 🟣 Reklama · 50 000 so'm
- Bottom: **+ Xarajat qo'shish**

## 23. Hisobot

- Header: *Hisobot*
- Filter chips: `Bugun` `7 kun` `30 kun` `Oy`
- Summary:

| Savdo | Xarajat | Foyda | Qarzga berildi | Naqd | Karta |
|---|---|---|---|---|---|
| 3 240 000 so'm | 120 000 so'm | 820 000 so'm | 450 000 so'm | 1 200 000 so'm | 800 000 so'm |

- Chart: *Kunlik savdo* — bar chart: `Dush | Sesh | Chor | Pay | Juma | Shan | Yak`

## 24. Analitika

- Title: *Analitika*
- Tabs: `Hafta` `Oy` `Yil`
- *Savdo dinamikasi* — line chart
- *Eng ko'p sotilgan mahsulotlar*: Futbolka — 42 dona · Shim — 31 dona · Krossovka — 18 dona
- Qo'shimcha analitika: Eng ko'p foyda bergan mahsulot · Kam sotilayotgan mahsulot · Qoldig'i tez tugayotgan mahsulot · Eng faol mijoz · Eng katta qarzdorlik

## 25. AI yordamchi (Pro)

- Title: *AI yordamchi*, chat interfeysi
- AI birinchi xabar: *Salom! Men biznesingizni boshqarishda yordam beraman.*
- Quick question chips: *Bugun qancha savdo bo'ldi?* · *Bugungi foyda qancha?* · *Kimlarning qarzi bor?* · *Qaysi mahsulot ko'p sotildi?* · *Qaysi mahsulot tugayapti?*
- Input: *Savolingizni yozing...* + send button
- AI action (tasdiq bilan):
  - User: *Ali akaga 100 ming qarz yoz.*
  - AI: *Ali akaga 100 000 so'm qarz yozaymi?* → button **Tasdiqlash**

## 26. Ovozli boshqaruv (Pro)

- Title: *Ovozli boshqaruv*
- Markazda katta microphone icon, status: *Gapiring...*
- Misol buyruqlar: *"Ali akaga 150 ming qarz yoz."* · *"Bugungi savdoni ko'rsat."* · *"Futbolkadan 10 dona kirim qil."* · *"Ali 100 ming qarzini berdi."*
- Button: **Tegish uchun bosing**
- Flow: ovoz → matn → AI tahlil → **Amalni tasdiqlash**

## 27. Eski daftarni ko'chirish — AI/OCR (Pro)

- Title: *Eski daftaringizni ko'chiring*
- Camera interfeysi: user eski qog'oz daftarni suratga oladi
- AI: *AI o'qish jarayoni...* progress **60%**
- Tekshiriladigan ma'lumotlar:
  - ✓ Mijozlar aniqlandi
  - ✓ Qarzlar aniqlandi
  - ✓ Summalar aniqlandi
  - ⚠ Ba'zi yozuvlar tekshirilishi kerak
- Buttons: **Tekshirish** → **Import qilish**

## 28. Qaytarish

- Title: *Qaytarish*
- Info: Mijoz *Ali* · Mahsulot *Futbolka* · Summa *120 000 so'm* · Sabab *Mahsulot qaytarildi*
- Button: **Qaytarishni saqlash**
- Pastki text: *Ombor qoldig'i avtomatik yangilanadi.*

## 29. Inventarizatsiya

- Title: *Inventarizatsiya*, section *Omborni sanash*
- Ilovadagi qoldiq: *100 dona* · Amaldagi qoldiq: *96 dona* · Farq: **−4 dona** (qizil)
- Buttons: **Hisobot yaratish** → **Tuzatishni saqlash**

## 30. Bildirishnomalar

- Title: *Bildirishnomalar*
- Cards (rangli indikator + matn), bosilganda tegishli modul ochiladi:
  - 🔴 Ali qarzining muddati o'tgan.
  - 🟠 Futbolka 4 dona qoldi.
  - 🟢 Bugungi savdo hisoboti tayyor.
  - 🔵 5 ta mahsulot tugash arafasida.

## 31. Sozlamalar

- Profil: avatar, *Abdulloh*, *+998 90 123 45 67*
- Settings list (sarlavha · subtitle):
  - Profil · Do'kon ma'lumotlari
  - Xodimlar · Xodimlarni boshqarish
  - Bildirishnomalar · Telegram / WhatsApp
  - Til · O'zbekcha
  - Valyuta · UZS
  - Ma'lumotlarni eksport qilish · Excel / PDF
  - Backup · Bulutli backup
  - PIN kod · PINni o'zgartirish
  - Yordam · FAQ / Support
  - Chiqish · Akkauntdan chiqish
- Pro tarif holati va **Pro'ga o'tish** qatori (TZ 35.3)

## 32. PIN kodni o'zgartirish

- Title: *PIN kodni o'zgartirish*, description *Yangi PIN kodni kiriting.*
- 4/6 digit PIN keyboard (7-ekran bilan bir xil), PIN dots `● ● ● ●`
- Keyin: *Yangi PINni tasdiqlash*
- Success: ✓ *PIN kod muvaffaqiyatli o'zgartirildi*

## 33. PIN kodni unutdim

Login/PIN ekranida link *PIN kodni unutdingizmi?* → Telefon raqamini tasdiqlash → SMS OTP → Yangi PIN yaratish → PIN tasdiqlash → Home

## 34. Xodimlar (V2)

- Title: *Xodimlar*, button **+ Xodim qo'shish**
- Employee card: *Sardor* · Role *Sotuvchi* · Status 🟢 Faol
- Role options: `Admin` `Sotuvchi` `Omborchi` `Kassir`
- Har bir xodimning amal tarixi ko'rinadi

## 35. Xodim qo'shish (V2)

- Inputs: Ism · Telefon · Lavozim
- Ruxsatlar (checkbox): ☑ Savdo · ☑ Mijozlar · ☐ Qarz · ☐ Ombor · ☐ Hisobot
- Button: **Xodimni qo'shish**

## 36. Chekni ko'rish

Elektron kvitansiya:

```
BozorPro
Bozor Market
16.09.2026

Futbolka     2 × 120 000
Shim         1 × 180 000
-------------------------
Jami           420 000 so'm
To'lov: Naqd
```

Buttons: **Yuborish** · **PDF** · **Chop etish**

## 37. Umumiy navigatsiya

```
┌─────────────────────────┐
│         SCREEN          │
├─────────────────────────┤
│ 🏠     👥     💰     📦    ⋯  │
│ Bosh  Mijoz  Qarz  Ombor Ko'proq│
└─────────────────────────┘
```

Bottom navigation doimiy: **Bosh sahifa · Mijozlar · Qarzlar · Ombor · Ko'proq**. Savdo, Qarz, To'lov, Kirim uchun Dashboard'da katta Quick Action tugmalari.

## 38. Asosiy user flow'lar

| Flow | Ketma-ketlik |
|---|---|
| Birinchi marta | Splash → Onboarding 1 → 2 → 3 → Ro'yxatdan o'tish → SMS → PIN yaratish → Home |
| Keyingi kirish | Splash → PIN → Home |
| Savdo | Home → Savdo → Mahsulot → Savat → To'lov → Chek → Home |
| Qarz | Home → Qarz → Mijoz → Summa → Muddat → Saqlash → Mijoz profili |
| Qarz to'lovi | Mijoz → To'lov qabul qilish → Summa → To'liq/Qisman → Tasdiqlash → Balans yangilanadi |
| Ovoz | Home → 🎤 → Ovoz → Speech→Text → AI tushunadi → Tasdiqlash → Database |
| Eski daftar | Eski daftar → Camera → OCR → AI → Mijozlar + qarzlar → Tekshirish → Import |

## 39. Implementatsiya talablari

> Yuqoridagi barcha ekranlar va UI elementlari aynan ko'rsatilganidek implement qilinadi, boshqa dizaynga o'zgartirilmaydi. Asosiy vizual uslub: **green + white, rounded cards, minimal shadow, clean modern mobile UI**. Barcha ekranlarda spacing, typography, button radius, icon alignment va navigation **bitta design system** asosida ishlaydi. Har bir tugma real navigation/action bilan bog'langan. Mock data bilan boshlash mumkin, lekin arxitektura real API/database ulashga tayyor bo'lishi shart.

### Reusable komponentlar (`lib/core/widgets/`)

| Komponent | Vazifa |
|---|---|
| `AppButton` | Primary / secondary / outline / danger, katta full-width |
| `AppTextField` | Yagona input uslubi (label, hint, error, prefix/suffix) |
| `StatCard` | Dashboard statistik karta (sarlavha + summa + ikon) |
| `ProductCard` | Mahsulot (rasm, nom, narx, qoldiq, + button) |
| `CustomerCard` | Mijoz qatori (avatar, ism, telefon, balans) |
| `DebtCard` | Qizil/yashil qarz kartasi |
| `BottomNavigation` | 5 ta bo'lim, doimiy |
| `AppBar` | Back arrow + title + actions |
| `EmptyState` | Bo'sh ro'yxat holati (illustratsiya + matn + CTA) |
| `ConfirmDialog` | Moliyaviy amallarni tasdiqlash oynasi |
| `MoneyInput` | Pul kiritish, avtomatik `150 000 so'm` format |
| `PinInput` | PIN nuqtalar + numeric keyboard |
| `ProductQuantitySelector` | `− 2 +` miqdor tanlash |

Qo'shimcha: `FilterChips`, `SearchField`, `QuickActionButton`, `AlertCard`, `SectionTitle`, `MoneyText`.
