import { config } from "@/config/config";
import { throwApiError } from "@/api/httpError";

export async function redeemGiftcode(
  code: string,
): Promise<RedeemGiftcodeResponse> {
  const response = await fetch(`${config.server.apiUrl}/giftcode/redeem`, {
    credentials: "include",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ code: code.trim().toUpperCase() }),
  });

  if (!response.ok) await throwApiError(response, "giftcode_request_failed");

  return response.json();
}
