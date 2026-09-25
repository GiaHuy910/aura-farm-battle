import type { createRoomForm } from "@/types/room";

const baseApi = `http://localhost:3001/room`;

export const getRooms = async () => {
  const response = await fetch(`${baseApi}/getRooms`, {
    method: "GET",
    credentials: "include",
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || "Unauthorized");
  }
  return data;
};

export const createRoom = async (body: createRoomForm) => {
  const response = await fetch(`${baseApi}/createRoom`, {
    method: "POST",
    credentials: "include",
    body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || "Unauthorized");
  }
  return data;
};
