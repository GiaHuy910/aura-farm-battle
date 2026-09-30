"use client";
import { useEffect, useState, type ReactNode } from "react";

import { AuthContext } from "./AuthContext";
import { logOutUser, getCurrentUser, logInUser } from "../../api/auth";

type Props = {
  children: ReactNode;
  initialUser: User | null | undefined;
};

export const AuthProvider = ({ children, initialUser }: Props) => {
  const [user, setUser] = useState<User | null | undefined>(initialUser);
  const [loading, setLoading] = useState(!initialUser);

  const fetchMe = async () => {
    const { data, error, isLoading } = await getCurrentUser();
    if (error) {
      return <div>Error :{error}</div>;
    }
    if (isLoading) {
      setLoading(true);
      return <div>Loadingg.........</div>;
    }
    setUser(data);
  };

  // const fetchMe = async () => {
  //   getCurrentUser()
  //     .then((user) => {
  //       console.log("provider chay", user.data);
  //       setUser(user.data);
  //     })
  //     .catch(() => {
  //       setUser(null);
  //     })
  //     .finally(() => {
  //       setLoading(false);
  //     });
  // };

  // useEffect(() => {
  //   fetchMe();
  // }, []);

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
