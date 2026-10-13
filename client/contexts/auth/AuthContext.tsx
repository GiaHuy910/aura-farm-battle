import { createContext } from "react";

export type AuthContextType = {
  user: UserInfo | null;
  loading: boolean;
  logout: () => Promise<void>;
  login: (data: logInForm) => Promise<void>;
  fetchMe: () => void;
};

export const AuthContext = createContext<AuthContextType | null>(null);
