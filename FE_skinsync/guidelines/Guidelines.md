# SkinSync Design System Guidelines

> Phong cách: **Nature · Science · AI Fusion** — tối giản, sang trọng, ấm áp.
> Ngôn ngữ giao diện: **Tiếng Việt** toàn bộ.

---

## 1. Màu sắc (Color Tokens)

### Bảng màu chính (Light Mode)

| Token CSS | Giá trị | Tailwind class | Mô tả |
|---|---|---|---|
| `--background` | `#ffffff` | `bg-background` | Nền trang mặc định |
| `--foreground` | `#2a2a2a` | `text-foreground` | Văn bản chính |
| `--primary` | `#c4a882` | `bg-primary` / `text-primary` | Màu nhấn chính — be vàng ấm |
| `--primary-foreground` | `#ffffff` | `text-primary-foreground` | Văn bản trên nền primary |
| `--secondary` | `#f5f0e8` | `bg-secondary` | Nền phụ — kem nhạt |
| `--secondary-foreground` | `#2a2a2a` | `text-secondary-foreground` | Văn bản trên nền secondary |
| `--muted` | `#faf7f2` | `bg-muted` | Nền muted — kem ấm (nền page chính) |
| `--muted-foreground` | `#6b7280` | `text-muted-foreground` | Văn bản phụ, placeholder |
| `--accent` | `#e8d5b7` | `bg-accent` | Màu nhấn phụ — be nhạt |
| `--accent-foreground` | `#2a2a2a` | `text-accent-foreground` | Văn bản trên accent |
| `--destructive` | `#ef4444` | `bg-destructive` | Cảnh báo / xoá / lỗi |
| `--destructive-foreground` | `#ffffff` | `text-destructive-foreground` | Văn bản trên destructive |
| `--border` | `rgba(0,0,0,0.08)` | `border-border` | Viền mặc định |
| `--ring` | `#e8d5b7` | `ring-ring` | Focus ring |
| `--input` | `transparent` | — | Input border (transparent) |
| `--input-background` | `#faf7f2` | `bg-input-background` | Nền input |

### Bảng màu thương hiệu (Custom Skincare Palette)

| Token CSS | Giá trị | Tên màu | Dùng khi nào |
|---|---|---|---|
| `--cream` | `#f5f0e8` | Cream | Nền section, card |
| `--mint` | `#e8d5b7` | Warm Sand | Đường kẻ, badge, highlight |
| `--soft-pink` | `#f5e6d3` | Soft Peach | Gradient, hover nhẹ |
| `--electric-blue` | `#c4a882` | Warm Gold | Màu nhấn (alias của `--primary`) |
| `--electric-purple` | `#8c6e52` | Deep Warm Brown | Màu đậm cho heading hero, icon |

### Màu trực tiếp thường dùng trong codebase

```
#1a1410  — Nâu đen đậm (heading hero lớn)
#2a2a2a  — Xám đậm (body text chính)
#6b7280  — Xám trung (text phụ, metadata)
#c4a882  — Be vàng ấm (primary accent)
#8c6e52  — Nâu be đậm (text đậm, icon)
#e8d5b7  — Cát ấm (border, badge bg)
#f5e6d3  — Peach nhạt (gradient, hover)
#f5f0e8  — Kem nhạt (card bg, section bg)
#faf7f2  — Kem ấm (page bg chính)
```

> **Cấm dùng:** màu tím (`purple`, `violet`, `indigo`), xanh điện (`electric blue` dạng lạnh), bất kỳ màu lạnh nổi bật nào.

---

## 2. Typography

### Font chữ

| Vai trò | Font | Nguồn | Style |
|---|---|---|---|
| **Heading / Display** | `Cormorant Garamond` | Google Fonts | Serif, italic tuỳ context |
| **Body / UI** | `DM Sans` | Google Fonts | Sans-serif, clean |
| **Fallback** | `Georgia`, `sans-serif` | System | — |

> Nếu chưa cài: thêm vào `src/styles/fonts.css`:
> ```css
> @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;1,300;1,400&family=DM+Sans:wght@300;400;500;600&display=swap');
> ```

### Thang kích thước văn bản

| Element | Size | Weight | Line height |
|---|---|---|---|
| `h1` | `text-2xl` (1.5rem) | 500 (medium) | 1.5 |
| `h2` | `text-xl` (1.25rem) | 500 | 1.5 |
| `h3` | `text-lg` (1.125rem) | 500 | 1.5 |
| `h4` | `text-base` (1rem) | 500 | 1.5 |
| `label` | `text-base` | 500 | 1.5 |
| `button` | `text-base` | 500 | 1.5 |
| `input` | `text-base` | 400 (normal) | 1.5 |
| Body text | `text-sm` / `text-base` | 400 | 1.5–1.75 |
| Caption / meta | `text-xs` / `text-sm` | 400 | 1.4 |

### Hero Display (Landing Page)

- Heading lớn: `text-4xl` → `text-6xl`, weight 700, màu `#1a1410`
- Subheading: `text-lg` → `text-2xl`, weight 400, màu `#2a2a2a`
- Tagline nhỏ: `text-sm`, weight 600, màu `#2a2a2a`

---

## 3. Border Radius

| Token | Giá trị | Tailwind class |
|---|---|---|
| Base (`--radius`) | `1rem` (16px) | `rounded-lg` |
| Small | `calc(1rem - 4px)` = 12px | `rounded-md` |
| Medium | `calc(1rem - 2px)` = 14px | `rounded-md` |
| Large | `1rem` = 16px | `rounded-lg` |
| Extra Large | `calc(1rem + 4px)` = 20px | `rounded-xl` |

> Mặc định dùng `rounded-xl` (20px) cho card, modal, button lớn. Dùng `rounded-full` cho avatar, badge tròn.

---

## 4. Spacing & Layout

- Hệ thống 8px (Tailwind spacing scale mặc định)
- Container max-width: `max-w-7xl` (1280px) với `px-4 sm:px-6 lg:px-8`
- Section padding dọc: `py-16` → `py-24`
- Card padding: `p-6` → `p-8`
- Gap grid/flex: `gap-6` → `gap-8`

---

## 5. Shadow & Depth

```css
/* Card shadow mặc định */
shadow-sm   → box-shadow: 0 1px 2px rgba(0,0,0,0.05)

/* Card hover / elevated */
shadow-md   → box-shadow: 0 4px 6px rgba(0,0,0,0.07)

/* Modal / Dropdown */
shadow-xl   → box-shadow: 0 20px 25px rgba(0,0,0,0.1)

/* Frosted Glass (dùng cho overlay, nav, modal) */
backdrop-blur-xl bg-white/80 border border-white/20
```

---

## 6. Hiệu ứng đặc trưng (Frosted Glass)

Pattern frosted glass chuẩn của dự án:

```jsx
// Card thông thường
className="bg-white/80 backdrop-blur-xl border border-white/20 rounded-2xl shadow-sm"

// Modal / Dialog
className="bg-white/90 backdrop-blur-2xl border border-[#e8d5b7]/30 rounded-2xl shadow-xl"

// Navigation bar
className="bg-white/70 backdrop-blur-xl border-b border-[#e8d5b7]/30"

// Sidebar admin
className="bg-[#faf7f2]/95 backdrop-blur-sm border-r border-[#e8d5b7]/30"
```

---

## 7. Components

### Button

```jsx
// Primary
className="bg-[#c4a882] hover:bg-[#8c6e52] text-white font-medium px-6 py-3 rounded-xl transition-colors"

// Secondary / Ghost
className="border border-[#e8d5b7] hover:bg-[#f5f0e8] text-[#8c6e52] font-medium px-6 py-3 rounded-xl transition-colors"

// Destructive
className="bg-red-500 hover:bg-red-600 text-white font-medium px-6 py-3 rounded-xl transition-colors"
```

### Input

```jsx
className="w-full bg-[#faf7f2] border border-[#e8d5b7] rounded-xl px-4 py-3 text-[#2a2a2a] placeholder:text-[#6b7280] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/30 focus:border-[#c4a882] transition-all"
```

### Card

```jsx
// Standard
className="bg-white/80 backdrop-blur-xl border border-[#e8d5b7]/30 rounded-2xl p-6 shadow-sm hover:shadow-md transition-shadow"

// Featured / Highlighted
className="bg-gradient-to-br from-[#f5f0e8] to-[#faf7f2] border border-[#e8d5b7] rounded-2xl p-6"
```

### Badge

```jsx
// Status: active
className="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-1 rounded-full"

// Status: warning
className="bg-amber-100 text-amber-700 text-xs font-medium px-2.5 py-1 rounded-full"

// Status: inactive
className="bg-gray-100 text-gray-500 text-xs font-medium px-2.5 py-1 rounded-full"

// Brand accent
className="bg-[#e8d5b7]/40 text-[#8c6e52] text-xs font-medium px-2.5 py-1 rounded-full"
```

### Toast (Sonner)

```jsx
import { toast } from "sonner";

toast.success("Thao tác thành công!");
toast.error("Có lỗi xảy ra, vui lòng thử lại.");
toast.info("Thông tin cần biết.");
```

---

## 8. Biểu đồ (Recharts)

Bảng màu biểu đồ (chart-1 → chart-5):

| Token | Giá trị (oklch) | Màu xấp xỉ |
|---|---|---|
| `--chart-1` | `oklch(0.646 0.222 41.116)` | Cam đất |
| `--chart-2` | `oklch(0.6 0.118 184.704)` | Xanh ngọc nhạt |
| `--chart-3` | `oklch(0.398 0.07 227.392)` | Xanh dương đậm |
| `--chart-4` | `oklch(0.828 0.189 84.429)` | Vàng |
| `--chart-5` | `oklch(0.769 0.188 70.08)` | Vàng cam |

> Sử dụng `var(--chart-1)` → `var(--chart-5)` trong Recharts để đồng nhất với theme.

---

## 9. Cấu trúc Routes

```
/                    → LandingPage
/login               → LoginPage
/register            → RegisterPage
/forgot-password     → ForgotPasswordPage
/reset-password      → ResetPasswordPage
/quiz                → QuizPage (4 bước)
/upload              → UploadPage
/analysis            → SkinAnalysisPage
/routine             → RoutinePage
/profile             → ProfilePage
/checkin             → CheckInPage
/progress            → ProgressPage
/settings/security   → SecuritySettingsPage

/admin               → AdminDashboard (AdminSidebar)
/admin/users         → AdminUsersPage
/admin/products      → AdminProductsPage
/admin/ai-config     → AdminAIConfigPage
/admin/profile       → AdminProfilePage
```

---

## 10. Sidebar Admin (`AdminSidebar`)

- Nền: `bg-[#faf7f2]/95 backdrop-blur-sm`
- Viền phải: `border-r border-[#e8d5b7]/30`
- Active item: `bg-[#c4a882]/10 text-[#8c6e52] border-r-2 border-[#c4a882]`
- Hover item: `hover:bg-[#f5f0e8] text-[#2a2a2a]`
- Logo/Brand: màu `#8c6e52`, font serif, italic

---

## 11. Gradient & Background Patterns

```css
/* Hero gradient */
background: linear-gradient(135deg, #faf7f2 0%, #f5f0e8 50%, #f5e6d3 100%);

/* Subtle mesh pattern (optional) */
background-image: radial-gradient(ellipse at 20% 50%, #f5e6d3 0%, transparent 50%),
                  radial-gradient(ellipse at 80% 20%, #e8d5b7 0%, transparent 40%);

/* Card shine */
background: linear-gradient(to bottom right, #f5f0e8, #faf7f2);
```

---

## 12. Dark Mode

Dark mode được định nghĩa trong `theme.css` nhưng **chưa được kích hoạt** trong giao diện hiện tại. Mọi trang đang dùng Light Mode. Để thêm dark mode sau này, thêm class `dark` vào `<html>`.

---

## 13. Nguyên tắc thiết kế

1. **Tối giản trước** — Không thêm element không cần thiết. Khoảng trống là thiết kế.
2. **Ấm áp, không lạnh** — Tất cả màu sắc phải trong tông warm (cam, be, nâu, peach). Tránh tông lạnh.
3. **Frosted glass cho layers** — Mọi element nổi lên (modal, dropdown, nav) dùng frosted glass.
4. **Tiếng Việt toàn bộ** — Label, placeholder, toast, error message, heading đều bằng tiếng Việt.
5. **Transition nhất quán** — `transition-all duration-200` hoặc `transition-colors duration-200` cho interactive elements.
6. **Accessible contrast** — Text chính `#2a2a2a` trên nền `#faf7f2` đảm bảo WCAG AA.
7. **Icons từ `lucide-react`** — Import theo named export, không dùng icon library khác.
