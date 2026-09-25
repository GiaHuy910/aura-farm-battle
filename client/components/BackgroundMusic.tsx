"use client";

import { useEffect, useRef, useState } from "react";

const sourceAudio = "/game-background-music-dynamic.mp3";

export default function BackgroundMusic() {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);

  const togglePlay = () => {
    if (audioRef.current) {
      if (isPlaying) {
        audioRef.current.pause();
        setIsPlaying(false);
      } else {
        audioRef.current.play();
        setIsPlaying(true);
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
      <audio ref={audioRef} src={sourceAudio} loop preload="auto" />
      {!isPlaying && (
        <button
          onClick={togglePlay}
          style={{
            position: "fixed",
            bottom: "20px",
            right: "20px",
            zIndex: 9999,
            padding: "10px 15px",
            background: "#000",
            color: "#fff",
            borderRadius: "8px",
            cursor: "pointer",
          }}
        >
          MUSIC ON
        </button>
      )}
    </div>
  );
}
