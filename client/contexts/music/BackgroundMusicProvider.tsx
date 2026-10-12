"use client";

import {
  useCallback,
  useEffect,
  useRef,
  useState,
  useMemo,
  type ReactNode,
} from "react";
import { usePathname } from "next/navigation";

import { BackgroundMusicContext } from "@/contexts/music/BackgroundMusicContext";
const defaultAudio = "/game-background-music-dynamic.mp4";

export default function BackgroundMusic({ children }: { children: ReactNode }) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const shouldPlayRef = useRef(true);
  const [source, setSource] = useState(defaultAudio);
  const [isPlaying, setIsPlaying] = useState(false);
  const selectSource = useCallback(
    (nextSource: string | null) => setSource(nextSource ?? defaultAudio),
    [],
  );

  const pathname = usePathname();
  const [masterVolume, setMasterVolume] = useState(1);
  const ROUTE_FACTORS: Record<string, number> = {
    "/": 1,
    "/rooms": 0.3,
    "/gacha": 0.3,
    "/user": 0.3,
  };
  const routeFactor = ROUTE_FACTORS[pathname] ?? 1;
  const volume = masterVolume * routeFactor;
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume;
    }
  }, [volume]);

  useEffect(() => {
    const audio = audioRef.current;
    if (audio && shouldPlayRef.current) audio.play().catch(() => {});
  }, [source]);

  const togglePlay = useCallback(async () => {
    const audio = audioRef.current;
    if (!audio) return;

    if (!audio.paused) {
      shouldPlayRef.current = false;
      audio.pause();
    } else {
      shouldPlayRef.current = true;
      try {
        await audio.play();
      } catch (error) {
        console.warn("Can not play music in error", error);
      }
    }
  }, []);
  const value = useMemo(
    () => ({
      selectSource,
      isPlaying,
      togglePlay,
      masterVolume,
      setMasterVolume,
    }),
    [selectSource, isPlaying, togglePlay, masterVolume],
  );
  return (
    <BackgroundMusicContext.Provider value={value}>
      {children}
      <audio
        ref={audioRef}
        src={source}
        loop
        preload="auto"
        onPlay={() => setIsPlaying(true)}
        onPause={() => setIsPlaying(false)}
      />
    </BackgroundMusicContext.Provider>
  );
}
