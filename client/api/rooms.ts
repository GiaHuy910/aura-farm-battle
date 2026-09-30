import useSWR from "swr";

import { fetcher } from "./customFetcher";

const baseApi = `http://localhost:3001/room`;

export const getRooms = async () => {
  const { data, error, isLoading } = useSWR<Room[]>(
    `${baseApi}/getRooms`,
    fetcher,
  );
  return { data, error, isLoading };
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
