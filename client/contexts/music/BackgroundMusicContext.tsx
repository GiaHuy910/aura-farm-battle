import { createContext } from "react";

type BackgroundMusicContextType = {
  selectSource: (source: string | null) => void;
};
export const BackgroundMusicContext =
  createContext<BackgroundMusicContextType | null>(null);
