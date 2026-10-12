"use client";
import { useBackgroundMusic } from "@/contexts/music/useBackgroundMusic";

export default function MusicControls() {
  const { isPlaying, togglePlay, masterVolume, setMasterVolume } =
    useBackgroundMusic();

  const handleSetVolume = (e: React.ChangeEvent<HTMLInputElement>) => {
    setMasterVolume(Number(e.target.value));
  };
  return (
    <div
      style={{ display: "flex", flexDirection: "column", gap: 8, width: 200 }}
    >
      <input
        type="range"
        min={0}
        max={1}
        step={0.01}
        value={masterVolume}
        onChange={handleSetVolume}
      />
      <button
        onClick={togglePlay}
        className="d-flex justify-content-start align-items-center"
      >
        {isPlaying ? "MUSIC : ON" : "MUSIC : OFF"}
      </button>
    </div>
  );
}
