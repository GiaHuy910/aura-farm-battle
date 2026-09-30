import { createContext } from "react";

export type AuthContextType = {
  user: User | null | undefined;
  loading: boolean;
  setUser: React.Dispatch<React.SetStateAction<User | null | undefined>>;
  logout: () => void;
  login: (data: logInForm) => Promise<void>;
  fetchMe: () => void;
};

export const AuthContext = createContext<AuthContextType | null>(null);
