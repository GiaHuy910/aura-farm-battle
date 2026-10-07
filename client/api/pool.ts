"use client";
import useSWR from "swr";

import { fetcher } from "./customFetcher";

const baseApi = `http://localhost:3001/pool`;

export const usePools = () => {
  return useSWR<PoolResponse | undefined>(`${baseApi}`, fetcher, {
    revalidateIfStale: false,
    revalidateOnFocus: false,
    revalidateOnReconnect: false,
  });
};
