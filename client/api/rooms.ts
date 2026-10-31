"use client";
import { config } from "@/config/config";
import { throwApiError } from "@/api/httpError";

const baseApi = `${config.server.apiUrl}/room`;

export const getRooms = async (request: RoomsRequest) => {
  const response = await fetch(`${baseApi}?${roomsQuery(request)}`, {
    method: "GET",
    credentials: "include",
  });
  if (!response.ok) {
    await throwApiError(response, "Unable to load rooms");
  }
  return response.json();
};

export const getRoomsByName = async (request: RoomsByNameRequest) => {
  const query = new URLSearchParams({
    name: request.name,
    limit: String(request.limit),
    cursor: request.cursor,
  });
  const response = await fetch(`${baseApi}/search?${query.toString()}`, {
    method: "GET",
    credentials: "include",
  });
  if (!response.ok) {
    await throwApiError(response, "Unable to search rooms");
  }
  return response.json();
};

const roomsQuery = (request: RoomsRequest) =>
  new URLSearchParams({
    limit: String(request.limit),
    cursor: request.cursor,
  }).toString();

export const createRoom = async (body: createRoomForm) => {
  const response = await fetch(`${baseApi}`, {
    method: "POST",
    credentials: "include",
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

export const joinRoom = async (body: joinRoomRequest) => {
  const response = await fetch(`${baseApi}/engagement`, {
    method: "POST",
    credentials: "include",
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
export async function leaveRoom(body: leaveRoomRequest) {
  const response = await fetch(`${baseApi}/leave`, {
    method: "POST",
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    await throwApiError(response, "Unauthorized");
  }
  return response.json();
}
