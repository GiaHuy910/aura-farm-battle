import { config } from "@/config/config";

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
  const data: GachaHistoryResponse = await response.json();
  if (response.status === 403) {
    throw new Error("Unauthorized");
  } else {
    if (response.ok) {
      return data;
    }
    throw new Error("Internal Server Error");
  }
};
