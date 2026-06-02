export interface ConflictWarningDTO {
  productAId: string;
  productAName: string;
  productBId: string;
  productBName: string;
  ingredientA: string;
  ingredientB: string;
  severity: "High" | "Medium";
  advice: string;
}

const conflictRules: Record<string, { severity: "High" | "Medium"; advice: string }> = {
  "Retinol-BHA": {
    severity: "High",
    advice: "BHA (Salicylic Acid) và Retinol đều là các hoạt chất mạnh thúc đẩy quá trình sừng hóa của da. Khi kết hợp cùng nhau trong một buổi routine sẽ gây kích ứng cực mạnh, đỏ rát và bong tróc. Hãy chia ra sử dụng BHA vào buổi sáng (kèm kem chống nắng) và Retinol vào buổi tối, hoặc sử dụng xen kẽ các ngày.",
  },
  "Retinol-AHA": {
    severity: "High",
    advice: "AHA (Axit Glycolic/Lactic) hoạt động ở độ pH thấp để tẩy tế bào chết bề mặt, trong khi Retinol hoạt động ở độ pH trung tính để tái tạo tế bào lớp sâu. Dùng chung một buổi sẽ làm hỏng hàng rào bảo vệ da, gây khô và kích ứng nghiêm trọng. Nên dùng AHA buổi sáng hoặc xen kẽ ngày với Retinol buổi tối.",
  },
  "AHA-BHA": {
    severity: "Medium",
    advice: "AHA và BHA đều là axit tẩy tế bào chết. Kết hợp đồng thời dễ dẫn đến tình trạng tẩy tế bào chết quá đà (over-exfoliation), làm suy yếu lớp màng bảo vệ da tự nhiên. Hãy sử dụng BHA cho vùng chữ T nhiều dầu và AHA cho các vùng còn lại, hoặc chia ra sử dụng các ngày khác nhau.",
  },
  "Vitamin C-Retinol": {
    severity: "High",
    advice: "Vitamin C (dạng nguyên bản L-AA) là một chất chống oxy hóa cần môi trường pH thấp, trong khi Retinol cần pH cao hơn. Sử dụng đồng thời có thể làm mất hoạt tính của cả hai và dễ gây kích ứng da. Khuyên dùng Vitamin C vào buổi sáng để tăng hiệu quả kem chống nắng và Retinol vào buổi tối.",
  },
  "Vitamin C-Niacinamide": {
    severity: "Medium",
    advice: "Vitamin C nguyên bản (L-Ascorbic Acid) khi dùng chung với Niacinamide có thể tạo thành phức hợp làm giảm hiệu quả của cả hai hoạt chất và có thể gây đỏ da/nóng rát tạm thời đối với da nhạy cảm. Bạn nên đợi 15-20 phút giữa hai bước, hoặc sử dụng Vitamin C buổi sáng và Niacinamide buổi tối.",
  },
  "Benzoyl Peroxide-Retinol": {
    severity: "High",
    advice: "Benzoyl Peroxide có tính oxy hóa mạnh, có thể làm bất hoạt hoặc phân hủy phân tử Retinol, làm giảm đáng kể hiệu quả trị mụn và trẻ hóa da, đồng thời làm khô da trầm trọng. Nên sử dụng Benzoyl Peroxide làm điểm mụn chấm và Retinol thoa toàn mặt vào các buổi khác nhau.",
  },
  "BHA-Benzoyl Peroxide": {
    severity: "Medium",
    advice: "Cả BHA và Benzoyl Peroxide đều là chất đặc trị mụn mạnh, có thể gây khô da nghiêm trọng nếu dùng chung trong một quy trình. Hãy giãn cách sử dụng: dùng BHA làm sạch lỗ chân lông trước, và chấm Benzoyl Peroxide lên nốt mụn sưng viêm sau đó.",
  },
};

function getConflictRule(actA: string, actB: string) {
  const key1 = `${actA}-${actB}`;
  const key2 = `${actB}-${actA}`;
  return conflictRules[key1] || conflictRules[key2] || null;
}

function getActiveIngredients(product: { name: string; ingredient: string }): string[] {
  const actives: string[] = [];
  const text = (product.name + " " + product.ingredient).toLowerCase();

  if (text.includes("retinol") || text.includes("tretinoin") || text.includes("retinoid")) {
    actives.push("Retinol");
  }
  if (text.includes("salicylic acid") || text.includes("salicylic") || text.includes("bha")) {
    actives.push("BHA");
  }
  if (
    text.includes("glycolic acid") ||
    text.includes("lactic acid") ||
    text.includes("glycolic") ||
    text.includes("lactic") ||
    text.includes("aha")
  ) {
    actives.push("AHA");
  }
  if (
    text.includes("vitamin c") ||
    text.includes("ascorbic acid") ||
    text.includes("ascorbic") ||
    text.includes("l-aa")
  ) {
    actives.push("Vitamin C");
  }
  if (text.includes("niacinamide") || text.includes("vitamin b3")) {
    actives.push("Niacinamide");
  }
  if (text.includes("benzoyl peroxide") || text.includes("benzoyl")) {
    actives.push("Benzoyl Peroxide");
  }

  return actives;
}

export async function checkIngredientConflicts(
  products: { id: string; name: string; ingredient: string }[]
): Promise<ConflictWarningDTO[]> {
  // Giả lập độ trễ của API
  await new Promise((resolve) => setTimeout(resolve, 150));

  const warnings: ConflictWarningDTO[] = [];

  for (let i = 0; i < products.length; i++) {
    for (let j = i + 1; j < products.length; j++) {
      const pA = products[i];
      const pB = products[j];
      const activesA = getActiveIngredients(pA);
      const activesB = getActiveIngredients(pB);

      for (const actA of activesA) {
        for (const actB of activesB) {
          const conflict = getConflictRule(actA, actB);
          if (conflict) {
            warnings.push({
              productAId: pA.id,
              productAName: pA.name,
              productBId: pB.id,
              productBName: pB.name,
              ingredientA: actA,
              ingredientB: actB,
              severity: conflict.severity,
              advice: conflict.advice,
            });
          }
        }
      }
    }
  }

  return warnings;
}
