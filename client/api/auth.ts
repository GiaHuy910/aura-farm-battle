"use client";

import { useEffect } from "react";

import useSWR from "swr";

import { fetcher } from "./customFetcher";
import { throwApiError } from "./httpError";
import { config } from "@/config/config";
import { useRouter } from "next/navigation";

const baseApi = `${config.server.apiUrl}/auth`;

export const useAuthMeSWR = () => {
  const router = useRouter();
  const { data, error, isLoading, mutate } = useSWR<AuthMeResponse | null>(
    `${baseApi}/me`,
    fetcher,
    {
      revalidateIfStale: false,
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
    },
  );
  useEffect(() => {
    if (error) {
      router.push("/");
    }
  }, [error, router]);

  return { data: data || null, error, isLoading, mutate };
};

export const getCurrentUser = async () => {
  const response = await fetch(`${baseApi}/me`, {
    credentials: "include",
    method: "GET",
  });
  if (!response.ok) {
    await throwApiError(response, "Unauthorized");
  }
  const data: AuthMeResponse = await response.json();
  return data.me;
};
export const logOutUser = async () => {
  const response = await fetch(`${baseApi}/logout`, {
    method: "POST",
    credentials: "include",
  });
  if (!response.ok) {
    await throwApiError(response, "Logout failed");
  }
  return response.json();
};
export const logInUser = async (loginData: logInForm) => {
  const response = await fetch(`${baseApi}/login`, {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(loginData),
  });
  if (!response.ok) {
    await throwApiError(response, "Login Failed");
  }
  return response.json();
};
export const registerUser = async (username: string, password: string) => {
  const response = await fetch(`${baseApi}/register`, {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ username, password }),
  });
  if (!response.ok) {
    await throwApiError(response, "Unauthorized");
  }
  return response.json();
};
