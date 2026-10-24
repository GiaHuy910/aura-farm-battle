"use client";
import useSWR from "swr";

import { fetcher } from "./customFetcher";
import { config } from "@/config/config";

const baseApi = `${config.server.apiUrl}/pool`;

export const usePool = () => {
  const { data, error, isLoading } = useSWR<PoolResponse | undefined>(
    `${baseApi}`,
    fetcher,
    {
      revalidateIfStale: false,
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      dedupingInterval: Infinity,
    },
  );
  return { poolData: data, error, isLoading };
};
