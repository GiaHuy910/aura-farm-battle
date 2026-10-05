"use client";
import { useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";

import { AuthContext } from "./AuthContext";
import { logOutUser, getCurrentUser, logInUser } from "../../api/auth";

type Props = {
  children: ReactNode;
  initialUser: UserInfo | null;
};

export const AuthProvider = ({ children, initialUser }: Props) => {
  const [user, setUser] = useState<UserInfo | null>(initialUser);
  const [loading, setLoading] = useState(!initialUser);
  const router = useRouter();

  const fetchMe = async () => {
    getCurrentUser()
      .then((user) => {
        setUser(user);
      })
      .catch(() => {
        // remove comment after done
        // router.push("/");
        setUser(null);
      })
      .finally(() => {
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchMe();
  }, []);

  const login = async (userData: logInForm) => {
    await logInUser(userData);
  };
  const logout = async () => {
    try {
      await logOutUser();
      setUser(null);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        logout,
        setUser,
        login,
        fetchMe,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
