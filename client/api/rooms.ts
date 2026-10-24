"use client";
import useSWR from "swr";

import { fetcher } from "./customFetcher";
import { config } from "@/config/config";

const baseApi = `${config.server.apiUrl}/room`;

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
  const data: createRoomResponse = await response.json();
  if (!response.ok) {
    throw new Error(data.status || "Unauthorized");
  }
  return data;
};

export const joinRoom = async (body: joinRoomRequest) => {
  const response = await fetch(`${baseApi}/engagement`, {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const data: joinRoomResponse = await response.json();
  if (!response.ok) {
    throw new Error(data.status || "Unauthorized");
  }
  return data;
};
export async function leaveRoom(body: leaveRoomRequest) {
  const response = await fetch(`${baseApi}/leave`, {
    method: "POST",
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data: leaveRoomResponse = await response.json();
  if (!response.ok) {
    throw new Error(data.status || "Unauthorized");
  }
  return data;
}
