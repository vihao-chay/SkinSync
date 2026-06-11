# Tai lieu dac ta ung dung di dong SkinSync

Cap nhat theo hien trang source code ngay `2026-06-09`.

## 1. Tong quan

### 1.1 Muc dich
SkinSync la ung dung mobile ho tro nguoi dung cham soc da thong qua:

- phan tich da bang AI tu anh chup khuon mat,
- thu thap ho so da qua quiz,
- sinh routine sang/toi phu hop,
- theo doi tien do cham soc da hang ngay,
- quan ly nhac nho va nhat ky da.

Tai lieu nay mo ta pham vi, luong nghiep vu, man hinh, du lieu va tich hop backend cho phien ban mobile trong thu muc `mobile_skinsync`.

### 1.2 Nen tang va cong nghe

- Framework: Flutter
- Quan ly state: `provider`
- Giao tiep API: `http`
- Luu phien dang nhap: `SessionStore`
- Dang nhap Google: `flutter_web_auth_2`
- Chup/chon anh: `image_picker`
- Kien truc app: feature-based + shared core

### 1.3 Doi tuong su dung

- Nguoi dung cuoi muon phan tich tinh trang da va theo doi routine.
- Quan tri vien can xem dashboard, user, product, AI config.

Luu y: phan admin tren mobile hien co giao dien, nhung nhieu noi dung dang dung mock data/giao dien demo, chua the hien day du tich hop backend trong mobile app.

## 2. Muc tieu san pham

### 2.1 Muc tieu chinh

- Cung cap trai nghiem onboarding va dang nhap nhanh tren mobile.
- Thu thap thong tin skin profile truoc khi phan tich.
- Cho phep upload anh da de nhan ket qua AI.
- Sinh va theo doi routine skincare theo ngay.
- Ghi nhan daily log de quan sat tien trinh cai thien.

### 2.2 Gia tri mang lai

- Ca nhan hoa khuyen nghi cham soc da.
- Bien ket qua AI thanh hanh dong cu the hang ngay.
- Giup nguoi dung duy tri thoi quen qua tracking va reminder.

## 3. Pham vi chuc nang

### 3.1 Trong pham vi

- Onboarding
- Dang ky, dang nhap bang email/password
- Dang nhap Google OAuth
- Quiz ho so da
- Chup/chon anh de phan tich da
- Xem ket qua AI moi nhat
- Xem routine sang/toi
- Check step hoan thanh trong routine
- Cai nhac nho routine
- Xem progress overview
- Ghi daily log
- Xem profile va dang xuat
- Cac man admin co giao dien dieu huong co ban

### 3.2 Ngoai pham vi hoac chua hoan thien tren mobile

- Quen mat khau, doi mat khau, sua profile nang cao tuy backend da co API.
- Chinh sua avatar.
- Xem lich su phan tich chi tiet.
- Xem bieu do progress nang cao, bao cao thang, lich check-in.
- Push notification thuc te tu he thong mobile OS.
- Tich hop backend day du cho toan bo phan admin mobile.
- Upload page rieng (`/upload`) hien la giao dien demo, luong thuc te dang di qua quiz.

## 4. Kien truc va dieu huong

### 4.1 Route chinh

- `/onboarding`
- `/login`
- `/`
- `/quiz`
- `/upload`
- `/dashboard`
- `/analysis`
- `/routine`
- `/progress`
- `/profile`
- `/admin`
- `/admin/users`
- `/admin/products`
- `/admin/ai-config`
- `/admin/profile`

### 4.2 Dieu huong tong quat

1. App mo vao `OnboardingPage`.
2. Nguoi dung di den `LoginPage`.
3. Sau dang nhap:
   - neu chua co `profile` thi vao `QuizPage`,
   - neu da co `profile` thi vao `Dashboard`.
4. Sau khi quiz va upload anh thanh cong, app chuyen sang `Analysis`.
5. Nguoi dung truy cap cac tab chinh trong `MainShell`:
   - Home
   - AI
   - Routine
   - Progress
   - Profile

## 5. Dac ta chuc nang chi tiet

## 5.1 Onboarding

### Muc dich

Gioi thieu nhanh 3 gia tri cot loi:

- hieu lan da,
- xay dung routine,
- theo doi tien trinh.

### Dau vao

- Khong yeu cau dang nhap.

### Dau ra

- Chuyen den trang dang nhap khi nguoi dung chon `Skip`, `Sign In`, hoac `Get Started`.

### Yeu cau chuc nang

- Hien thi 3 slide.
- Cho phep next/skip.
- Co chi bao trang hien tai.

## 5.2 Xac thuc tai khoan

### Chuc nang

- Dang ky tai khoan moi.
- Dang nhap bang email/password.
- Dang nhap Google.
- Tu dong luu session va refresh token.

### Dau vao

- Register: `fullName`, `email`, `password`, `phone` la tuy chon.
- Login: `email`, `password`.
- Google login: callback qua scheme `skinsync://auth`.

### Dau ra

- `accessToken`
- `refreshToken`
- thong tin `user`

### Luat nghiep vu

- Email va password bat buoc khi dang nhap.
- `fullName`, `email`, `password` bat buoc khi dang ky.
- Session duoc luu local de bootstrap lai app.
- Khi API tra `401`, app tu refresh token va gui lai request 1 lan.
- Neu refresh that bai, app coi nhu het phien dang nhap.

### API su dung

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/google/url`
- `POST /api/auth/google`
- `POST /api/auth/refresh`

## 5.3 Quiz ho so da

### Muc dich

Thu thap thong tin nen de ca nhan hoa ket qua AI va routine.

### Buoc quiz

1. Chon loai da:
   - Normal
   - Oily
   - Dry
   - Combination
   - Sensitive
2. Chon concern:
   - Acne
   - Dark spots
   - Dryness
   - Redness
   - Large pores
   - Uneven tone
3. Chon ngan sach:
   - `Tiet kiem`
   - `Trung binh`
   - `Cao cap`
4. Chup/chon anh da.

### Mapping budget trong app

- `Tiet kiem` -> `300000`
- `Trung binh` -> `700000`
- `Cao cap` -> `1200000`

### Du lieu gui backend

- `skinType`
- `monthlyBudget`
- `budgetLabel`
- `concerns`
- `goals`
- `allergies`
- `avoidIngredients`

Gia tri mac dinh hien tai do mobile app tu gan:

- `goals`: `["Healthy skin barrier", "Consistent skincare"]`
- `allergies`: `[]`
- `avoidIngredients`: `[]`

### Yeu cau chuc nang

- Chi cho chuyen buoc khi da chon du lieu bat buoc.
- Cho phep chon anh tu camera hoac gallery.
- Sau khi luu survey, neu co anh thi tu dong goi phan tich AI.

### API su dung

- `PUT /api/users/survey`
- `POST /api/analysis/scan` (multipart, field file mac dinh la `image`)

## 5.4 Phan tich da bang AI

### Muc dich

Sinh ket qua phan tich da ca nhan hoa dua tren selfie va profile da.

### Thong tin hien thi

- skin score
- skin type
- confidence score
- overview
- danh sach issue
- danh sach recommendation
- warnings neu co

### Dau vao

- Anh selfie cua nguoi dung
- profile da da luu truoc do

### Dau ra

- `AnalysisResult`
- `CurrentRegimen` moi hoac cap nhat

### Yeu cau chuc nang

- Neu chua co ket qua thi hien thong diep moi nguoi dung lam quiz.
- Co nut `Open Routine`.
- Co nut `Analyze Again` de quay lai quiz.

### API su dung

- `GET /api/analysis/latest`
- `POST /api/analysis/scan`

## 5.5 Dashboard

### Muc dich

Tong hop nhanh thong tin quan trong nhat cua nguoi dung sau khi dang nhap.

### Noi dung chinh

- Loi chao theo ten
- overview tu ket qua phan tich moi nhat
- skin score
- skin type
- concerns da chon
- cac action nhanh:
  - Analyze Skin
  - View Routine
  - Daily Log
  - Profile
- tien do routine hom nay
- daily tip

### Yeu cau chuc nang

- Ho tro keo de refresh du lieu trang chu.
- Neu co routine tracking, hien thanh progress theo so step da hoan thanh.

### API phu thuoc

- `GET /api/users/survey`
- `GET /api/analysis/latest`
- `GET /api/regimens/current`
- `GET /api/routine-tracking/today`
- `GET /api/progress/overview`
- `GET /api/reminders`
- `GET /api/diary/today`

## 5.6 Routine

### Muc dich

Giup nguoi dung thuc hien routine sang/toi va ghi nhan muc do hoan thanh.

### Noi dung chinh

- Tab `Morning` / `Evening`
- Danh sach step theo thu tu
- Moi step gom:
  - step order
  - category
  - brand + product name
  - purpose
  - instruction
  - caution neu co
- Danh sach reminder hien co
- Nut tao reminder mac dinh:
  - Morning 07:00
  - Evening 21:00

### Yeu cau chuc nang

- Cho phep checkbox step da hoan thanh/chua hoan thanh.
- Khi thay doi step, app cap nhat lai tracking, progress va today log.
- Neu chua co regimen, hien thong diep huong dan phan tich da truoc.

### API su dung

- `GET /api/regimens/current`
- `GET /api/routine-tracking/today`
- `POST /api/routine-tracking/steps/{stepId}/complete`
- `DELETE /api/routine-tracking/steps/{stepId}/complete`
- `GET /api/reminders`
- `PUT /api/reminders`

## 5.7 Progress va Daily Log

### Muc dich

Theo doi xu huong cai thien va luu cam nhan da theo ngay.

### Progress overview hien thi

- current score
- current streak
- improvement percent
- progress insight

### Daily log hien thi

- skin feeling
- notes
- acne level
- hydration level

### Form them daily log

- `skinFeeling`
- `acneLevel`
- `hydrationLevel`
- `notes`

### Yeu cau chuc nang

- Cho phep mo bottom sheet de tao daily log moi.
- Sau khi luu, cap nhat lai `todayLog` va `progress`.
- Daily log co gan thong tin `morningCompleted` va `eveningCompleted` tu tracking hom nay.

### API su dung

- `GET /api/progress/overview`
- `GET /api/diary/today`
- `POST /api/diary/check-in`

## 5.8 Profile

### Muc dich

Hien thi thong tin tai khoan va tom tat skin profile.

### Noi dung chinh

- avatar mac dinh
- full name
- email
- skin type
- concerns
- goals
- budget
- logout

### Yeu cau chuc nang

- Dang xuat se xoa session local va dua app ve trang login o lan truy cap tiep theo.

## 5.9 Admin tren mobile

### Man hinh hien co

- Dashboard
- Users
- Products
- AI Config
- Profile

### Tinh trang hien tai

- Dieu huong va UI admin da ton tai.
- Mot phan noi dung dang doc tu mock data (`MockSkinData`).
- Tai lieu nay xem admin mobile la pham vi demo/prototype, khong phai phan da hoan tat day du ve tich hop backend.

## 6. Mo hinh du lieu chinh tren mobile

### 6.1 AuthSession

- `accessToken`
- `refreshToken`
- `user`

### 6.2 AppUser

- `id`
- `fullName`
- `email`
- `phone`
- `avatarUrl`
- `role`
- `status`

### 6.3 SkinProfile

- `skinType`
- `monthlyBudget`
- `budgetLabel`
- `concerns`
- `goals`
- `allergies`
- `avoidIngredients`

### 6.4 AnalysisResult

- `id`
- `imageUrl`
- `skinType`
- `overallScore`
- `confidenceScore`
- `overview`
- `disclaimer`
- `warnings`
- `issues`
- `recommendations`

### 6.5 CurrentRegimen

- `regimenId`
- `name`
- `morning[]`
- `evening[]`

### 6.6 RegimenStep

- `stepId`
- `productId`
- `name`
- `brand`
- `category`
- `stepOrder`
- `instruction`
- `purpose`
- `frequency`
- `caution`
- `imageUrl`
- `price`

### 6.7 RoutineTrackingToday

- `totalSteps`
- `completedSteps`
- `morningCompleted`
- `eveningCompleted`
- `completedStepIds`

### 6.8 ProgressOverview

- `currentScore`
- `improvementPercent`
- `currentStreak`
- `dailyTip`
- `progressInsight`

### 6.9 DailyLog

- `date`
- `skinFeeling`
- `notes`
- `acneLevel`
- `drynessLevel`
- `rednessLevel`
- `irritationLevel`
- `hydrationLevel`

### 6.10 ReminderItem

- `reminderId`
- `time`
- `routineType`
- `isEnabled`

## 7. Tich hop backend

### 7.1 Base URL

Trong mobile app, gia tri mac dinh hien tai:

- `API_BASE_URL = http://10.0.2.2:5199`

Gia tri nay phu hop Android emulator khi backend chay local. Co the override bang `--dart-define=API_BASE_URL=...`.

### 7.2 Co che xac thuc

- Dung JWT Bearer token.
- Header gui kem: `Authorization: Bearer <accessToken>`.
- Tu dong refresh token neu gap `401`.
- Luong refresh duoc dong bo de tranh goi refresh trung lap.

### 7.3 Chuan response

Api client mobile uu tien doc `content` neu backend tra ve response envelope:

```json
{
  "success": true,
  "statusCode": 200,
  "message": "...",
  "content": {}
}
```

Neu `content` la list, app se chuyen thanh:

```json
{ "items": [...] }
```

## 8. Yeu cau phi chuc nang

### 8.1 Kha nang su dung

- Giao dien phu hop mobile first.
- Dieu huong don gian qua bottom navigation.
- Cac thao tac chinh can hoan thanh bang it buoc.

### 8.2 Hieu nang

- App can bootstrap session nhanh khi mo lai.
- Dashboard can refresh du lieu tong hop sau dang nhap.
- Cac request doc du lieu trang chu duoc goi song song de giam thoi gian cho.

### 8.3 Bao mat

- Khong gui user id tuy chinh tren header; backend doc tu JWT.
- Session duoc luu local.
- Refresh token duoc dung de cap moi access token.

### 8.4 Tin cay

- Hien thong bao loi cho nguoi dung qua snackbar/message.
- Neu mot so API home that bai, app se dat state ve `null` hoac danh sach rong thay vi crash.

## 9. Luong nghiep vu tong hop

### 9.1 Luong nguoi dung moi

1. Mo app.
2. Xem onboarding.
3. Dang ky/dang nhap.
4. Hoan thanh quiz.
5. Upload anh selfie.
6. Nhan ket qua AI.
7. Mo routine duoc sinh.
8. Check step routine hang ngay.
9. Ghi daily log.
10. Theo doi progress.

### 9.2 Luong nguoi dung cu

1. Mo lai app.
2. Bootstrap session cu.
3. Tu dong tai dashboard neu session hop le.
4. Refresh du lieu home.
5. Tiep tuc routine va progress.

## 10. Gioi han va ghi chu hien trang

- Route khoi tao mac dinh hien la onboarding, chua co logic bo qua onboarding cho user da tung su dung.
- `LandingPage` ton tai nhung khong phai diem vao mac dinh cua app.
- `UploadPage` ton tai nhung chua noi luong chup/chon anh thuc te.
- Daily log tren mobile hien moi thu thap `skinFeeling`, `notes`, `acneLevel`, `hydrationLevel`; cac chi so khac co trong model nhung chua co UI nhap.
- Reminder hien duoc tao nhanh bang hai moc gio mac dinh, chua co UI tuy chon gio linh hoat.
- Admin mobile chua duoc xem la module production-ready.

## 11. De xuat mo rong tiep theo

- Them forgot password, change password, update profile.
- Them history cho analysis va progress chart.
- Them push notification thuc te cho reminder.
- Them local validation va loading/error state chi tiet hon cho tung man.
- Them phan quyen ro rang de an/hien admin theo `user.role`.
- Hoan thien upload page va tach rieng media permission handling.

## 12. Ket luan

Phien ban mobile SkinSync hien da hoan thien duoc luong nghiep vu cot loi cho end-user:

- xac thuc,
- quiz ho so da,
- phan tich AI,
- sinh routine,
- tracking routine,
- daily log,
- progress,
- profile.

Day la nen tang tot de tiep tuc nang cap thanh ban production hoan chinh, dac biet o cac phan thong bao mobile, profile management, lich su phan tich va admin tich hop that.
