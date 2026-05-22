import { useEffect, useMemo, useState, type ReactNode } from "react";
import { Link } from "react-router";
import {
  ArrowLeft,
  Bell,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Clock,
  Edit3,
  Eye,
  Info,
  ListPlus,
  Moon,
  PackageCheck,
  Plus,
  Save,
  ShoppingBag,
  Sun,
  Trash2,
  X,
} from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import {
  createCustomRegimenApi,
  deleteRegimenApi,
  getCurrentRegimenApi,
  updateRegimenApi,
  type CurrentRegimenResponse,
  type RegimenProduct,
} from "../services/regimenService";
import { getProductsApi, type ProductDetail } from "../services/productService";
import {
  completeRoutineApi,
  completeRoutineStepApi,
  getTodayRoutineTrackingApi,
  uncompleteRoutineStepApi,
  type RoutineTrackingToday,
} from "../services/routineTrackingService";
import {
  getRemindersApi,
  saveReminderApi,
  type Reminder,
} from "../services/reminderService";

type RoutineType = "Morning" | "Evening";

interface EditableStep {
  key: string;
  stepId?: string;
  productId: string;
  productName: string;
  brand: string;
  category: string;
  description: string;
  ingredient: string;
  usageGuide: string;
  instruction: string;
  price: number;
  imageUrl?: string | null;
  routineTime: RoutineType;
  stepOrder: number;
}

const fallbackProducts: ProductDetail[] = [
  {
    id: "fallback-cleanser",
    name: "Gentle Cleanser",
    brand: "SkinSync",
    category: "Cleanser",
    description: "Sữa rửa mặt dịu nhẹ cho routine hằng ngày.",
    ingredient: "Glycerin, amino acid surfactants, panthenol",
    usageGuide: "Massage trên da ẩm 60 giây rồi rửa sạch.",
    price: 220000,
    suitableSkinTypes: ["All"],
    imageUrl: "https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500",
    rating: 4.6,
    status: "active",
    createdAt: new Date().toISOString(),
  },
  {
    id: "fallback-toner",
    name: "Hydrating Toner",
    brand: "SkinSync",
    category: "Toner",
    description: "Toner cấp ẩm giúp cân bằng bề mặt da.",
    ingredient: "Hyaluronic acid, beta-glucan, allantoin",
    usageGuide: "Vỗ nhẹ 1 đến 2 lớp sau bước làm sạch.",
    price: 250000,
    suitableSkinTypes: ["All"],
    imageUrl: "https://images.unsplash.com/photo-1664165786318-9af861f2a9c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500",
    rating: 4.5,
    status: "active",
    createdAt: new Date().toISOString(),
  },
  {
    id: "fallback-serum",
    name: "Niacinamide Serum",
    brand: "SkinSync",
    category: "Serum",
    description: "Serum hỗ trợ kiểm soát dầu và làm đều màu da.",
    ingredient: "Niacinamide, zinc PCA, panthenol",
    usageGuide: "Dùng 2 đến 3 giọt trước kem dưỡng.",
    price: 360000,
    suitableSkinTypes: ["All"],
    imageUrl: "https://images.unsplash.com/photo-1770048792339-d8f8d8d2dbeb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500",
    rating: 4.7,
    status: "active",
    createdAt: new Date().toISOString(),
  },
  {
    id: "fallback-moisturizer",
    name: "Barrier Moisturizer",
    brand: "SkinSync",
    category: "Moisturizer",
    description: "Kem dưỡng hỗ trợ phục hồi hàng rào bảo vệ da.",
    ingredient: "Ceramide, cholesterol, fatty acids",
    usageGuide: "Thoa đều sau serum, dùng sáng hoặc tối.",
    price: 330000,
    suitableSkinTypes: ["All"],
    imageUrl: "https://images.unsplash.com/photo-1767360963892-3353defd6584?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500",
    rating: 4.5,
    status: "active",
    createdAt: new Date().toISOString(),
  },
  {
    id: "fallback-sunscreen",
    name: "Daily SPF 50",
    brand: "SkinSync",
    category: "Sunscreen",
    description: "Kem chống nắng phổ rộng cho ban ngày.",
    ingredient: "Modern UV filters, vitamin E, silica",
    usageGuide: "Thoa lượng 2 ngón tay vào cuối routine buổi sáng.",
    price: 300000,
    suitableSkinTypes: ["All"],
    imageUrl: "https://images.unsplash.com/photo-1594332322527-08753d4473c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500",
    rating: 4.8,
    status: "active",
    createdAt: new Date().toISOString(),
  },
];

export function RoutinePage() {
  const [regimen, setRegimen] = useState<CurrentRegimenResponse | null>(null);
  const [products, setProducts] = useState<ProductDetail[]>(fallbackProducts);
  const [steps, setSteps] = useState<EditableStep[]>([]);
  const [tracking, setTracking] = useState<RoutineTrackingToday | null>(null);
  const [reminders, setReminders] = useState<Reminder[]>([]);
  const [selectedProduct, setSelectedProduct] = useState<ProductDetail | EditableStep | null>(null);
  const [editMode, setEditMode] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [newRoutineTime, setNewRoutineTime] = useState<RoutineType>("Morning");
  const [newProductId, setNewProductId] = useState("");
  const [newInstruction, setNewInstruction] = useState("");
  const [routineName, setRoutineName] = useState("Lộ trình chăm sóc da");

  useEffect(() => {
    let isMounted = true;

    async function load() {
      const [regimenResult, productsResult, trackingResult, remindersResult] = await Promise.all([
        getCurrentRegimenApi(),
        getProductsApi(),
        getTodayRoutineTrackingApi(),
        getRemindersApi(),
      ]);

      if (!isMounted) {
        return;
      }

      if (productsResult.success && productsResult.content?.length) {
        setProducts(productsResult.content);
        setNewProductId(productsResult.content[0]?.id ?? "");
      } else {
        setNewProductId(fallbackProducts[0]?.id ?? "");
      }

      if (regimenResult.success && regimenResult.content) {
        setRegimen(regimenResult.content);
        setRoutineName(regimenResult.content.name || "Lộ trình chăm sóc da");
        setSteps(mapRegimenToSteps(regimenResult.content));
      } else {
        setSteps(buildFallbackSteps());
        setStatusMessage("Chưa có lộ trình từ server, bạn có thể tạo lộ trình tùy chỉnh.");
      }

      if (trackingResult.success && trackingResult.content) {
        setTracking(trackingResult.content);
      }

      if (remindersResult.success && remindersResult.content) {
        setReminders(mergeDefaultReminders(remindersResult.content));
      } else {
        setReminders(defaultReminders());
      }
    }

    void load();
    return () => {
      isMounted = false;
    };
  }, []);

  const completedStepIds = useMemo(() => {
    return new Set(tracking?.steps.map((step) => step.stepId) ?? []);
  }, [tracking]);

  const totalCost = useMemo(() => {
    return steps.reduce((sum, step) => sum + step.price, 0);
  }, [steps]);

  const morningSteps = useMemo(() => {
    return steps.filter((step) => step.routineTime === "Morning").sort((a, b) => a.stepOrder - b.stepOrder);
  }, [steps]);

  const eveningSteps = useMemo(() => {
    return steps.filter((step) => step.routineTime === "Evening").sort((a, b) => a.stepOrder - b.stepOrder);
  }, [steps]);

  async function refreshTracking() {
    const result = await getTodayRoutineTrackingApi();
    if (result.success && result.content) {
      setTracking(result.content);
    }
  }

  async function toggleStep(step: EditableStep) {
    if (!step.stepId) {
      setErrorMessage("Vui lòng lưu lộ trình trước khi đánh dấu bước.");
      return;
    }

    setErrorMessage(null);
    const result = completedStepIds.has(step.stepId)
      ? await uncompleteRoutineStepApi(step.stepId)
      : await completeRoutineStepApi(step.stepId);

    if (result.success && result.content) {
      setTracking(result.content);
      setStatusMessage("Đã cập nhật tiến độ hôm nay.");
    } else {
      setErrorMessage(result.message || "Không thể cập nhật tiến độ.");
    }
  }

  async function markRoutineDone(routineTime: RoutineType) {
    setErrorMessage(null);
    const result = await completeRoutineApi(routineTime);
    if (result.success && result.content) {
      setTracking(result.content);
      setStatusMessage(`Đã hoàn thành routine ${routineTime === "Morning" ? "buổi sáng" : "buổi tối"}.`);
    } else {
      setErrorMessage(result.message || "Không thể hoàn thành routine.");
    }
  }

  function addStep() {
    const product = products.find((item) => item.id === newProductId);
    if (!product) {
      return;
    }

    setSteps((current) => renumberSteps([
      ...current,
      {
        key: crypto.randomUUID(),
        productId: product.id,
        productName: product.name,
        brand: product.brand,
        category: product.category,
        description: product.description,
        ingredient: product.ingredient,
        usageGuide: product.usageGuide,
        instruction: newInstruction.trim() || product.usageGuide,
        price: product.price,
        imageUrl: product.imageUrl,
        routineTime: newRoutineTime,
        stepOrder: current.filter((step) => step.routineTime === newRoutineTime).length + 1,
      },
    ]));
    setNewInstruction("");
  }

  function removeStep(key: string) {
    setSteps((current) => renumberSteps(current.filter((step) => step.key !== key)));
  }

  function moveStep(key: string, direction: -1 | 1) {
    setSteps((current) => {
      const target = current.find((step) => step.key === key);
      if (!target) {
        return current;
      }

      const group = current
        .filter((step) => step.routineTime === target.routineTime)
        .sort((a, b) => a.stepOrder - b.stepOrder);
      const index = group.findIndex((step) => step.key === key);
      const nextIndex = index + direction;
      if (nextIndex < 0 || nextIndex >= group.length) {
        return current;
      }

      const swapped = [...group];
      [swapped[index], swapped[nextIndex]] = [swapped[nextIndex], swapped[index]];
      const replaced = current.map((step) => {
        const newIndex = swapped.findIndex((item) => item.key === step.key);
        return newIndex >= 0 ? { ...step, stepOrder: newIndex + 1 } : step;
      });
      return renumberSteps(replaced);
    });
  }

  function updateInstruction(key: string, instruction: string) {
    setSteps((current) => current.map((step) => (step.key === key ? { ...step, instruction } : step)));
  }

  async function saveRoutine() {
    setErrorMessage(null);
    const payload = {
      name: routineName,
      steps: renumberSteps(steps).map((step) => ({
        productId: step.productId,
        routineTime: step.routineTime,
        stepOrder: step.stepOrder,
        instruction: step.instruction,
      })),
    };

    const hasFallbackOnly = payload.steps.some((step) => step.productId.startsWith("fallback-"));
    if (hasFallbackOnly) {
      setErrorMessage("Danh sách sản phẩm thật chưa tải được, vui lòng thử lại trước khi lưu.");
      return;
    }

    const result = regimen
      ? await updateRegimenApi(regimen.regimenId, payload)
      : await createCustomRegimenApi(payload);

    if (!result.success || !result.content) {
      setErrorMessage(result.message || "Không thể lưu lộ trình.");
      return;
    }

    setRegimen(result.content);
    setSteps(mapRegimenToSteps(result.content));
    setRoutineName(result.content.name);
    setEditMode(false);
    setStatusMessage("Đã lưu lộ trình tùy chỉnh.");
    await refreshTracking();
  }

  async function deleteRoutine() {
    if (!regimen) {
      setSteps([]);
      return;
    }

    const result = await deleteRegimenApi(regimen.regimenId);
    if (!result.success) {
      setErrorMessage(result.message || "Không thể xóa lộ trình.");
      return;
    }

    setRegimen(null);
    setSteps([]);
    setTracking(null);
    setEditMode(true);
    setStatusMessage("Đã xóa lộ trình. Bạn có thể tạo lộ trình mới.");
  }

  async function saveReminder(reminder: Reminder) {
    setErrorMessage(null);
    const result = await saveReminderApi({
      routineType: reminder.routineType,
      time: reminder.time,
      isEnabled: reminder.isEnabled,
    });

    if (!result.success || !result.content) {
      setErrorMessage(result.message || "Không thể lưu nhắc nhở.");
      return;
    }

    setReminders((current) => mergeDefaultReminders([
      ...current.filter((item) => item.routineType !== result.content?.routineType),
      result.content,
    ]));
    setStatusMessage("Đã cập nhật nhắc nhở.");
    await scheduleReminderNotification(result.content);
  }

  function updateReminder(routineType: RoutineType, patch: Partial<Reminder>) {
    setReminders((current) => current.map((item) => (
      item.routineType === routineType ? { ...item, ...patch } : item
    )));
  }

  return (
    <div className="min-h-screen bg-[#faf7f2] pt-20 pb-12">
      <div className="border-b border-[#e8d5b7]/40 bg-white/75 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <Link to="/analysis" className="inline-flex items-center gap-2 text-sm text-[#6b7280] hover:text-[#8c6e52] transition-colors mb-4">
            <ArrowLeft className="w-4 h-4" />
            Quay lại phân tích
          </Link>
          <div className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-5">
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e8d5b7]/40 text-[#8c6e52] text-xs mb-3">
                <PackageCheck className="w-3.5 h-3.5" />
                Routine cá nhân hóa
              </div>
              <h1 className="text-3xl text-[#2a2a2a]">{routineName}</h1>
              <p className="text-sm text-[#6b7280] mt-1">
                {steps.length} bước mỗi ngày · {formatCurrency(totalCost)} ước tính
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <div className="min-w-[220px] rounded-2xl border border-[#e8d5b7]/50 bg-white/80 px-4 py-3 shadow-sm">
                <div className="flex items-center justify-between text-xs text-[#6b7280] mb-2">
                  <span>Tiến độ hôm nay</span>
                  <span>{tracking?.completedSteps ?? 0}/{tracking?.totalSteps || steps.length}</span>
                </div>
                <div className="h-2 rounded-full bg-[#f5f0e8] overflow-hidden">
                  <div
                    className="h-full rounded-full bg-[#c4a882] transition-all duration-300"
                    style={{ width: `${tracking?.completionPercent ?? 0}%` }}
                  />
                </div>
              </div>
              <button
                type="button"
                onClick={() => setEditMode((value) => !value)}
                className="inline-flex items-center gap-2 px-4 py-3 rounded-xl border border-[#e8d5b7] bg-white text-[#8c6e52] hover:bg-[#f5f0e8] transition-colors"
              >
                <Edit3 className="w-4 h-4" />
                {editMode ? "Xem routine" : "Chỉnh sửa"}
              </button>
              {editMode && (
                <button
                  type="button"
                  onClick={() => void saveRoutine()}
                  className="inline-flex items-center gap-2 px-4 py-3 rounded-xl bg-[#c4a882] text-white hover:bg-[#8c6e52] transition-colors shadow-sm"
                >
                  <Save className="w-4 h-4" />
                  Lưu
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {(statusMessage || errorMessage) && (
          <div className={`mb-5 rounded-2xl border px-4 py-3 text-sm ${
            errorMessage
              ? "border-red-200 bg-red-50 text-red-700"
              : "border-[#e8d5b7] bg-white/80 text-[#8c6e52]"
          }`}>
            {errorMessage || statusMessage}
          </div>
        )}

        <div className="grid lg:grid-cols-[1fr_360px] gap-6">
          <section className="space-y-6">
            {editMode && (
              <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl p-5 shadow-sm">
                <div className="grid md:grid-cols-[1fr_auto] gap-4 mb-5">
                  <div>
                    <label className="block text-sm text-[#2a2a2a] mb-2">Tên lộ trình</label>
                    <input
                      value={routineName}
                      onChange={(event) => setRoutineName(event.target.value)}
                      className="w-full bg-[#faf7f2] border border-[#e8d5b7] rounded-xl px-4 py-3 text-[#2a2a2a] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/30"
                    />
                  </div>
                  <button
                    type="button"
                    onClick={() => void deleteRoutine()}
                    className="self-end inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl border border-red-200 bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                    Xóa routine
                  </button>
                </div>

                <div className="grid lg:grid-cols-[160px_1fr] gap-3">
                  <select
                    value={newRoutineTime}
                    onChange={(event) => setNewRoutineTime(event.target.value as RoutineType)}
                    className="bg-[#faf7f2] border border-[#e8d5b7] rounded-xl px-4 py-3 text-[#2a2a2a] focus:outline-none"
                  >
                    <option value="Morning">Buổi sáng</option>
                    <option value="Evening">Buổi tối</option>
                  </select>
                  <select
                    value={newProductId}
                    onChange={(event) => setNewProductId(event.target.value)}
                    className="bg-[#faf7f2] border border-[#e8d5b7] rounded-xl px-4 py-3 text-[#2a2a2a] focus:outline-none"
                  >
                    {products.map((product) => (
                      <option key={product.id} value={product.id}>
                        {product.category} · {product.brand} · {product.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="grid lg:grid-cols-[1fr_auto] gap-3 mt-3">
                  <input
                    value={newInstruction}
                    onChange={(event) => setNewInstruction(event.target.value)}
                    placeholder="Hướng dẫn riêng cho bước này"
                    className="bg-[#faf7f2] border border-[#e8d5b7] rounded-xl px-4 py-3 text-[#2a2a2a] placeholder:text-[#6b7280] focus:outline-none"
                  />
                  <button
                    type="button"
                    onClick={addStep}
                    className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-[#c4a882] text-white hover:bg-[#8c6e52] transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                    Thêm bước
                  </button>
                </div>
              </div>
            )}

            <RoutineSection
              title="Routine buổi sáng"
              subtitle="Làm sạch, bảo vệ và chuẩn bị da cho cả ngày"
              routineTime="Morning"
              steps={morningSteps}
              icon={<Sun className="w-5 h-5 text-white" />}
              completedStepIds={completedStepIds}
              editMode={editMode}
              onToggleStep={toggleStep}
              onMarkRoutineDone={markRoutineDone}
              onViewProduct={setSelectedProduct}
              onMoveStep={moveStep}
              onRemoveStep={removeStep}
              onUpdateInstruction={updateInstruction}
            />

            <RoutineSection
              title="Routine buổi tối"
              subtitle="Làm sạch sâu, phục hồi và khóa ẩm qua đêm"
              routineTime="Evening"
              steps={eveningSteps}
              icon={<Moon className="w-5 h-5 text-white" />}
              completedStepIds={completedStepIds}
              editMode={editMode}
              onToggleStep={toggleStep}
              onMarkRoutineDone={markRoutineDone}
              onViewProduct={setSelectedProduct}
              onMoveStep={moveStep}
              onRemoveStep={removeStep}
              onUpdateInstruction={updateInstruction}
            />
          </section>

          <aside className="space-y-5">
            <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl p-5 shadow-sm">
              <div className="flex items-center gap-2 mb-4">
                <ShoppingBag className="w-4 h-4 text-[#8c6e52]" />
                <h2 className="text-lg text-[#2a2a2a]">Sản phẩm trong routine</h2>
              </div>
              <div className="space-y-3">
                {steps.slice(0, 8).map((step) => (
                  <button
                    key={`${step.key}-product`}
                    type="button"
                    onClick={() => setSelectedProduct(step)}
                    className="w-full flex items-center gap-3 rounded-xl border border-transparent p-2 text-left hover:border-[#e8d5b7] hover:bg-[#faf7f2] transition-colors"
                  >
                    <div className="w-12 h-12 rounded-xl overflow-hidden bg-[#f5f0e8] flex-shrink-0">
                      <ImageWithFallback src={resolveMediaUrl(step.imageUrl)} alt={step.productName} className="w-full h-full object-cover" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm text-[#2a2a2a] truncate">{step.productName}</p>
                      <p className="text-xs text-[#6b7280] truncate">{step.brand} · {step.category}</p>
                    </div>
                    <Info className="w-4 h-4 text-[#c4a882]" />
                  </button>
                ))}
              </div>
            </div>

            <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl p-5 shadow-sm">
              <div className="flex items-center gap-2 mb-4">
                <Bell className="w-4 h-4 text-[#8c6e52]" />
                <h2 className="text-lg text-[#2a2a2a]">Nhắc nhở</h2>
              </div>
              <div className="space-y-4">
                {reminders.map((reminder) => (
                  <div key={reminder.routineType} className="rounded-xl border border-[#e8d5b7]/40 bg-[#faf7f2] p-3">
                    <div className="flex items-center justify-between gap-3 mb-3">
                      <div className="flex items-center gap-2 text-sm text-[#2a2a2a]">
                        {reminder.routineType === "Morning" ? <Sun className="w-4 h-4 text-amber-500" /> : <Moon className="w-4 h-4 text-[#8c6e52]" />}
                        {reminder.routineType === "Morning" ? "Buổi sáng" : "Buổi tối"}
                      </div>
                      <label className="flex items-center gap-2 text-xs text-[#6b7280]">
                        <input
                          type="checkbox"
                          checked={reminder.isEnabled}
                          onChange={(event) => updateReminder(reminder.routineType, { isEnabled: event.target.checked })}
                          className="accent-[#c4a882]"
                        />
                        Bật
                      </label>
                    </div>
                    <div className="flex gap-2">
                      <input
                        type="time"
                        value={reminder.time}
                        onChange={(event) => updateReminder(reminder.routineType, { time: event.target.value })}
                        className="min-w-0 flex-1 rounded-xl border border-[#e8d5b7] bg-white px-3 py-2 text-[#2a2a2a] focus:outline-none"
                      />
                      <button
                        type="button"
                        onClick={() => void saveReminder(reminder)}
                        className="inline-flex items-center justify-center rounded-xl bg-[#c4a882] px-3 text-white hover:bg-[#8c6e52] transition-colors"
                        aria-label="Lưu nhắc nhở"
                      >
                        <Save className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </aside>
        </div>
      </main>

      {selectedProduct && (
        <ProductDetailModal product={selectedProduct} onClose={() => setSelectedProduct(null)} />
      )}
    </div>
  );
}

function RoutineSection({
  title,
  subtitle,
  routineTime,
  steps,
  icon,
  completedStepIds,
  editMode,
  onToggleStep,
  onMarkRoutineDone,
  onViewProduct,
  onMoveStep,
  onRemoveStep,
  onUpdateInstruction,
}: {
  title: string;
  subtitle: string;
  routineTime: RoutineType;
  steps: EditableStep[];
  icon: ReactNode;
  completedStepIds: Set<string>;
  editMode: boolean;
  onToggleStep: (step: EditableStep) => void | Promise<void>;
  onMarkRoutineDone: (routineTime: RoutineType) => void | Promise<void>;
  onViewProduct: (product: EditableStep) => void;
  onMoveStep: (key: string, direction: -1 | 1) => void;
  onRemoveStep: (key: string) => void;
  onUpdateInstruction: (key: string, instruction: string) => void;
}) {
  return (
    <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl shadow-sm overflow-hidden">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-5 py-4 border-b border-[#e8d5b7]/30 bg-[#f5f0e8]/70">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#c4a882] flex items-center justify-center shadow-sm">
            {icon}
          </div>
          <div>
            <h2 className="text-xl text-[#2a2a2a]">{title}</h2>
            <p className="text-sm text-[#6b7280]">{subtitle}</p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => void onMarkRoutineDone(routineTime)}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl border border-[#c4a882]/40 bg-white text-[#8c6e52] hover:bg-[#faf7f2] transition-colors"
        >
          <CheckCircle2 className="w-4 h-4" />
          Hoàn thành tất cả
        </button>
      </div>

      <div className="p-5 space-y-3">
        {steps.map((step, index) => {
          const done = Boolean(step.stepId && completedStepIds.has(step.stepId));
          return (
            <div key={step.key} className="rounded-2xl border border-[#e8d5b7]/35 bg-white p-4 shadow-sm">
              <div className="flex gap-4">
                <button
                  type="button"
                  onClick={() => void onToggleStep(step)}
                  className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 transition-colors ${
                    done ? "bg-[#c4a882] text-white" : "border border-[#e8d5b7] text-[#c4a882] hover:bg-[#f5f0e8]"
                  }`}
                  aria-label="Đánh dấu bước"
                >
                  {done ? <CheckCircle2 className="w-5 h-5" /> : <span className="text-sm">{index + 1}</span>}
                </button>

                <div className="w-16 h-16 rounded-xl bg-[#f5f0e8] overflow-hidden flex-shrink-0">
                  <ImageWithFallback src={resolveMediaUrl(step.imageUrl)} alt={step.productName} className="w-full h-full object-cover" />
                </div>

                <div className="min-w-0 flex-1">
                  <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-xs text-[#8c6e52]">{step.category}</p>
                      <h3 className="text-base text-[#2a2a2a] truncate">{step.productName}</h3>
                      <p className="text-sm text-[#6b7280]">{step.brand} · {formatCurrency(step.price)}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => onViewProduct(step)}
                        className="inline-flex items-center justify-center w-9 h-9 rounded-xl border border-[#e8d5b7] text-[#8c6e52] hover:bg-[#f5f0e8] transition-colors"
                        aria-label="Xem chi tiết sản phẩm"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      {editMode && (
                        <>
                          <button
                            type="button"
                            onClick={() => onMoveStep(step.key, -1)}
                            className="inline-flex items-center justify-center w-9 h-9 rounded-xl border border-[#e8d5b7] text-[#8c6e52] hover:bg-[#f5f0e8] transition-colors"
                            aria-label="Đưa bước lên"
                          >
                            <ChevronUp className="w-4 h-4" />
                          </button>
                          <button
                            type="button"
                            onClick={() => onMoveStep(step.key, 1)}
                            className="inline-flex items-center justify-center w-9 h-9 rounded-xl border border-[#e8d5b7] text-[#8c6e52] hover:bg-[#f5f0e8] transition-colors"
                            aria-label="Đưa bước xuống"
                          >
                            <ChevronDown className="w-4 h-4" />
                          </button>
                          <button
                            type="button"
                            onClick={() => onRemoveStep(step.key)}
                            className="inline-flex items-center justify-center w-9 h-9 rounded-xl border border-red-200 text-red-500 hover:bg-red-50 transition-colors"
                            aria-label="Xóa bước"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </>
                      )}
                    </div>
                  </div>

                  {editMode ? (
                    <input
                      value={step.instruction}
                      onChange={(event) => onUpdateInstruction(step.key, event.target.value)}
                      className="mt-3 w-full rounded-xl border border-[#e8d5b7] bg-[#faf7f2] px-3 py-2 text-sm text-[#2a2a2a] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/25"
                    />
                  ) : (
                    <p className="mt-3 text-sm text-[#4b5563] leading-relaxed">{step.instruction || step.usageGuide}</p>
                  )}
                </div>
              </div>
            </div>
          );
        })}

        {steps.length === 0 && (
          <div className="rounded-2xl border border-dashed border-[#e8d5b7] bg-[#faf7f2] p-8 text-center">
            <ListPlus className="w-8 h-8 text-[#c4a882] mx-auto mb-3" />
            <p className="text-sm text-[#6b7280]">Chưa có bước nào trong routine này.</p>
          </div>
        )}
      </div>
    </div>
  );
}

function ProductDetailModal({
  product,
  onClose,
}: {
  product: ProductDetail | EditableStep;
  onClose: () => void;
}) {
  const name = "productName" in product ? product.productName : product.name;
  const price = "productName" in product ? product.price : product.price;

  return (
    <div className="fixed inset-0 z-50 bg-black/35 backdrop-blur-sm flex items-center justify-center px-4">
      <div className="w-full max-w-2xl rounded-2xl border border-[#e8d5b7]/50 bg-white/95 backdrop-blur-2xl shadow-xl overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b border-[#e8d5b7]/40">
          <div>
            <p className="text-xs text-[#8c6e52]">{product.brand} · {product.category}</p>
            <h2 className="text-xl text-[#2a2a2a]">{name}</h2>
          </div>
          <button type="button" onClick={onClose} className="w-9 h-9 rounded-xl hover:bg-[#f5f0e8] flex items-center justify-center transition-colors">
            <X className="w-4 h-4 text-[#6b7280]" />
          </button>
        </div>
        <div className="grid md:grid-cols-[220px_1fr] gap-5 p-5">
          <div className="rounded-2xl overflow-hidden bg-[#f5f0e8] aspect-square">
            <ImageWithFallback src={resolveMediaUrl(product.imageUrl)} alt={name} className="w-full h-full object-cover" />
          </div>
          <div className="space-y-4">
            <div>
              <p className="text-xs text-[#6b7280] mb-1">Mô tả</p>
              <p className="text-sm text-[#2a2a2a] leading-relaxed">{product.description || "Chưa có mô tả."}</p>
            </div>
            <div>
              <p className="text-xs text-[#6b7280] mb-1">Thành phần</p>
              <p className="text-sm text-[#2a2a2a] leading-relaxed">{product.ingredient || "Chưa có thông tin thành phần."}</p>
            </div>
            <div>
              <p className="text-xs text-[#6b7280] mb-1">Hướng dẫn dùng</p>
              <p className="text-sm text-[#2a2a2a] leading-relaxed">{product.usageGuide || "Dùng theo hướng dẫn trên bao bì."}</p>
            </div>
            <div className="flex items-center gap-2 text-sm text-[#8c6e52]">
              <Clock className="w-4 h-4" />
              {formatCurrency(price)}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function mapRegimenToSteps(data: CurrentRegimenResponse): EditableStep[] {
  return renumberSteps([
    ...data.morning.map((item) => mapRegimenProduct(item, "Morning")),
    ...data.evening.map((item) => mapRegimenProduct(item, "Evening")),
  ]);
}

function mapRegimenProduct(item: RegimenProduct, routineTime: RoutineType): EditableStep {
  return {
    key: item.stepId,
    stepId: item.stepId,
    productId: item.productId,
    productName: item.name,
    brand: item.brand,
    category: item.category,
    description: item.description,
    ingredient: item.ingredient,
    usageGuide: item.usageGuide,
    instruction: item.instruction || item.usageGuide,
    price: item.price,
    imageUrl: item.imageUrl,
    routineTime,
    stepOrder: item.stepOrder,
  };
}

function buildFallbackSteps(): EditableStep[] {
  const byCategory = new Map(fallbackProducts.map((product) => [product.category, product]));
  const morning = ["Cleanser", "Toner", "Serum", "Sunscreen"]
    .map((category, index) => productToStep(byCategory.get(category), "Morning", index + 1))
    .filter((step): step is EditableStep => Boolean(step));
  const evening = ["Cleanser", "Serum", "Moisturizer"]
    .map((category, index) => productToStep(byCategory.get(category), "Evening", index + 1))
    .filter((step): step is EditableStep => Boolean(step));

  return [...morning, ...evening];
}

function productToStep(product: ProductDetail | undefined, routineTime: RoutineType, stepOrder: number): EditableStep | null {
  if (!product) {
    return null;
  }

  return {
    key: `${routineTime}-${product.id}`,
    productId: product.id,
    productName: product.name,
    brand: product.brand,
    category: product.category,
    description: product.description,
    ingredient: product.ingredient,
    usageGuide: product.usageGuide,
    instruction: product.usageGuide,
    price: product.price,
    imageUrl: product.imageUrl,
    routineTime,
    stepOrder,
  };
}

function renumberSteps(items: EditableStep[]): EditableStep[] {
  return items.map((step) => {
    const order = items
      .filter((item) => item.routineTime === step.routineTime)
      .sort((a, b) => a.stepOrder - b.stepOrder)
      .findIndex((item) => item.key === step.key);

    return { ...step, stepOrder: order + 1 };
  });
}

function defaultReminders(): Reminder[] {
  return [
    { reminderId: "morning-default", routineType: "Morning", time: "07:00", isEnabled: true },
    { reminderId: "evening-default", routineType: "Evening", time: "21:00", isEnabled: true },
  ];
}

function mergeDefaultReminders(serverReminders: Reminder[]): Reminder[] {
  return defaultReminders().map((fallback) => {
    return serverReminders.find((item) => item.routineType === fallback.routineType) ?? fallback;
  });
}

async function scheduleReminderNotification(reminder: Reminder) {
  if (!reminder.isEnabled || !("Notification" in window)) {
    return;
  }

  const permission = Notification.permission === "default"
    ? await Notification.requestPermission()
    : Notification.permission;

  if (permission !== "granted") {
    return;
  }

  const delay = millisecondsUntil(reminder.time);
  window.setTimeout(() => {
    const routineLabel = reminder.routineType === "Morning" ? "buổi sáng" : "buổi tối";
    new Notification("SkinSync", {
      body: `Đến giờ chăm sóc da ${routineLabel}.`,
    });
  }, delay);
}

function millisecondsUntil(time: string): number {
  const [hoursRaw, minutesRaw] = time.split(":");
  const hours = Number(hoursRaw);
  const minutes = Number(minutesRaw);
  const now = new Date();
  const target = new Date(now);
  target.setHours(Number.isFinite(hours) ? hours : 7, Number.isFinite(minutes) ? minutes : 0, 0, 0);

  if (target <= now) {
    target.setDate(target.getDate() + 1);
  }

  return target.getTime() - now.getTime();
}

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(value);
}

function resolveMediaUrl(url?: string | null): string {
  if (!url) {
    return "https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500";
  }

  if (/^https?:\/\//i.test(url)) {
    return url;
  }

  const base = (import.meta.env.VITE_API_BASE_URL ?? "/api").replace(/\/api\/?$/i, "");
  return `${base}${url}`;
}
