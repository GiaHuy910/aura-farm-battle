"use client";
import { config } from "@/config/config";

const baseApi = `${config.server.apiUrl}/room`;

export const getRooms = async (request: RoomsRequest) => {
  const query = new URLSearchParams({
    limit: String(request.limit),
    cursor: request.cursor,
  });
  const response = await fetch(`${baseApi}?${query.toString()}`, {
    method: "GET",
    credentials: "include",
  });
  const data: RoomsResponse = await response.json();
  if (!response.ok) {
    throw new Error("Unable to load rooms");
  }
  return data;
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
