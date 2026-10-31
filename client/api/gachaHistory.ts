import { config } from "@/config/config";
import { throwApiError } from "@/api/httpError";

const baseApi = `${config.server.apiUrl}/gacha-history`;

export const getGachaHistory = async (request: GachaHistoryRequest) => {
  const { limit, cursor, item_type } = request;
  const response = await fetch(
    `${baseApi}?limit=${limit}&cursor=${cursor}&item_type=${item_type}`,
    {
      method: "GET",
      credentials: "include",
    },
  );
  if (!response.ok) await throwApiError(response, "Internal Server Error");
  return response.json();
};
