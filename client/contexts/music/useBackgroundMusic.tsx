import { useContext } from "react";
import { BackgroundMusicContext } from "@/contexts/music/BackgroundMusicContext";

export const useBackgroundMusic = () => {
  const context = useContext(BackgroundMusicContext);
  if (!context) {
    throw new Error("useBackgroundMusic must be used within BackgroundMusic");
  }
  return context;
};
