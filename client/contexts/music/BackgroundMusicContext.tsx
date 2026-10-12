import { createContext } from "react";

type BackgroundMusicContextType = {
  selectSource: (source: string | null) => void;
  isPlaying: boolean;
  togglePlay: () => void;
  masterVolume: number;
  setMasterVolume: (volume: number) => void;
};
export const BackgroundMusicContext =
  createContext<BackgroundMusicContextType | null>(null);
