import { throwApiError } from "./httpError";

export const fetcher = async <T>(url: string): Promise<T> => {
  const response = await fetch(url, {
    credentials: "include",
    method: "GET",
  });
  if (!response.ok) {
    await throwApiError(response, "Request failed");
  }
  return response.json();
};
