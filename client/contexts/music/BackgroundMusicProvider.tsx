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
const defaultVolume = 1;
const lobbyVolume = 0.3;

const ROUTE_FACTORS: Record<string, number> = {
  "/": defaultVolume,
  "/rooms": lobbyVolume,
  "/gacha/history": lobbyVolume,
  "/gacha": lobbyVolume,
  "/user": lobbyVolume,
};

const getFactorFromObject = (pathname: string): number => {
  if (ROUTE_FACTORS[pathname] !== undefined) {
    return ROUTE_FACTORS[pathname];
  }
  const segments = pathname.split("/").filter(Boolean);
  const basePath = segments.length > 0 ? `/${segments[0]}` : "/";

  return ROUTE_FACTORS[basePath] !== undefined ? ROUTE_FACTORS[basePath] : 1;
};

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

  const routeFactor = getFactorFromObject(pathname);
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
