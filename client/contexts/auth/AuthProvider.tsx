"use client";
import { type ReactNode } from "react";

import { AuthContext } from "./AuthContext";
import { logOutUser, logInUser, useAuthMeSWR } from "../../api/auth";

type Props = {
  children: ReactNode;
};

export const AuthProvider = ({ children }: Props) => {
  const { data, isLoading, mutate } = useAuthMeSWR();

  const login = async (userData: logInForm) => {
    await logInUser(userData);
    await mutate();
    // router.push("/");
  };
  const logout = async () => {
    try {
      await logOutUser();
      await mutate(null, false);
      window.location.href = "/";
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user: data?.me || null,
        loading: isLoading,
        logout,
        login,
        fetchMe: mutate,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
