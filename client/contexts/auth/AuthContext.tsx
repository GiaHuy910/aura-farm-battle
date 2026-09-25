import { createContext } from "react";
import { logInForm } from "@/types/auth";

export type User = {
  user_id: string;
  username: string;
  //   avatar: {
  //     url: string | null;
  //   };
};

export type AuthContextType = {
  user: User | null;
  loading: boolean;
  setUser: React.Dispatch<React.SetStateAction<User | null>>;
  logout: () => void;
  login: (data: logInForm) => Promise<void>;
  fetchMe: () => void;
};

export const AuthContext = createContext<AuthContextType | null>(null);
