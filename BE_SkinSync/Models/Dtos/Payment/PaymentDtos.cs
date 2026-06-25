namespace SkinSync.Models.Dtos.Payment;

public class CreatePaymentLinkRequestDto
{
    public string PlanCode { get; set; } = string.Empty;
}

public class PaymentLinkResponseDto
{
    public string CheckoutUrl { get; set; } = string.Empty;
    public long OrderCode { get; set; }
}

public class VerifyPaymentResponseDto
{
    public string Status { get; set; } = "pending"; // "pending", "paid", "cancelled"
    public string PlanCode { get; set; } = string.Empty;
}
