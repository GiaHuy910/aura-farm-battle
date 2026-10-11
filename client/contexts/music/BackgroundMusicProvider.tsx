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
    const audio = audioRef.current;
    if (audio) {
      audio.volume = volume;
    }
  }, [volume]);
  const handleChangeVolume = (e: React.ChangeEvent<HTMLInputElement>) => {
    setMasterVolume(Number(e.target.value));
  };

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    audio.load();
    if (shouldPlayRef.current) {
      audio.play().then(
        () => setIsPlaying(true),
        () => setIsPlaying(false),
      );
    }
  }, [source]);

  const togglePlay = async () => {
    const audio = audioRef.current;
    if (!audio) return;

    if (isPlaying) {
      shouldPlayRef.current = false;
      audio.pause();
      setIsPlaying(false);
    } else {
      shouldPlayRef.current = true;
      try {
        await audio.play();
        setIsPlaying(true);
      } catch (error) {
        console.warn("Can not play music in error", error);
        setIsPlaying(false);
      }
    }
  };
  const value = useMemo(() => ({ selectSource }), [selectSource]);
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
      <input
        type="range"
        min={0}
        max={1}
        step={0.01}
        style={{
          width: "180px",
          position: "fixed",
          bottom: "60px",
          right: "10px",
          zIndex: 10,
          padding: "10px 15px",
          background: "#000",
          color: "#fff",
          borderRadius: "8px",
          cursor: "pointer",
        }}
        value={volume}
        onChange={handleChangeVolume}
      />
      <button
        onClick={togglePlay}
        style={{
          width: "180px",
          position: "fixed",
          bottom: "10px",
          right: "1000px",
          zIndex: 10,
          padding: "10px 15px",
          background: "#000",
          color: "#fff",
          borderRadius: "8px",
          cursor: "pointer",
        }}
      >
        {isPlaying ? "MUSIC OFF" : "MUSIC ON"}
      </button>
    </BackgroundMusicContext.Provider>
  );
}
