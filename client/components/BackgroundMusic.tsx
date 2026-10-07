"use client";

import { useEffect, useRef, useState } from "react";

const sourceAudio = "/game-background-music-dynamic.m4a";

export default function BackgroundMusic() {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);

  const togglePlay = async () => {
    if (!audioRef.current) return;
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      try {
        await audioRef.current.play();
        setIsPlaying(true);
      } catch (error) {
        console.warn(
          "Không thể phát nhạc do chính sách trình duyệt hoặc lỗi file:",
          error,
        );
        setIsPlaying(false);
      }
    }
  };

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    audio
      .play()
      .then(() => {
        setIsPlaying(true);
      })
      .catch(() => {
        setIsPlaying(false);
      });
  }, []);

  return (
    <div>
      <audio ref={audioRef} loop preload="auto">
        <source src={sourceAudio} type="audio/mp4" />
      </audio>
      <button
        onClick={togglePlay}
        style={{
          position: "fixed",
          bottom: "10px",
          right: "20px",
          zIndex: 9999,
          padding: "10px 15px",
          background: "#000",
          color: "#fff",
          borderRadius: "8px",
          cursor: "pointer",
        }}
      >
        {isPlaying ? "MUSIC OFF" : "MUSIC ON"}
      </button>
    </div>
  );
}
