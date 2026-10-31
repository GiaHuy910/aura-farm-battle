import { config } from "@/config/config";
import { throwApiError } from "@/api/httpError";

const baseApi = `${config.server.apiUrl}/user`;

export const sendGachaRequest = async (body: GachaRequest) => {
  const response = await fetch(`${baseApi}/gacha`, {
    credentials: "include",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    await throwApiError(response, "Unauthorized");
  }
  return response.json();
};
export const getUserOwnedItems = async () => {
  const response = await fetch(`${baseApi}/owned-items`, {
    credentials: "include",
    method: "GET",
  });
  if (!response.ok) {
    await throwApiError(response, "Unauthorized");
  }
  return response.json();
};
export const equipUserItem = async (equipItem: equipItemRequest) => {
  const response = await fetch(`${baseApi}/equip-item`, {
    credentials: "include",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(equipItem),
  });
  if (!response.ok) {
    await throwApiError(response, "Unauthorized");
  }
  return response.json();
};
