"use client";
import useSWR from "swr";

import { fetcher } from "./customFetcher";

const baseApi = `http://localhost:3001/room`;

export const useRooms = () => {
  return useSWR<Room[] | [] | undefined>(`${baseApi}`, fetcher, {
    revalidateIfStale: false,
    revalidateOnFocus: false,
    revalidateOnReconnect: false,
  });
};

export const createRoom = async (body: createRoomForm) => {
  const response = await fetch(`${baseApi}`, {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || "Unauthorized");
  }
  return data;
};
