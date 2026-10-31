"use client";

import { useEffect, useState } from "react";
import { effectImg, spriteConfig } from "./battleAssets";

const KEYFRAMES = `@keyframes aura-sprite-run { from { background-position-x: 0%; } to { background-position-x: 100%; } }`;

type LayerProps = {
  type: string;
  loop: boolean;
};

export function SpriteLayer({ type, loop }: LayerProps) {
  const cfg = spriteConfig(type);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (loop || !cfg) return;
    const t = setTimeout(() => setDone(true), cfg.ms);
    return () => clearTimeout(t);
  }, [loop, cfg]);

  if (!cfg || done) return null;
  const animated = cfg.frames > 1;
  return (
    <>
      <style>{KEYFRAMES}</style>
      <div
        aria-hidden
        style={{
          position: "absolute",
          inset: 0,
          pointerEvents: "none",
          zIndex: 10,
          backgroundImage: `url('${effectImg(type)}')`,
          backgroundRepeat: "no-repeat",
          backgroundSize: `${cfg.frames * 100}% 100%`,
          backgroundPositionX: "0%",
          animation: animated
            ? `aura-sprite-run ${cfg.ms}ms steps(${cfg.frames}, jump-none) ${loop ? "infinite" : "1 forwards"}`
            : undefined,
        }}
      />
    </>
  );
}

export function EffectIcon({
  type,
  size,
  title,
}: {
  type: string;
  size: number;
  title?: string;
}) {
  const cfg = spriteConfig(type);
  if (!cfg) return null;
  return (
    <span
      title={title}
      style={{
        display: "inline-block",
        width: size,
        height: size,
        backgroundImage: `url('${effectImg(type)}')`,
        backgroundRepeat: "no-repeat",
        backgroundSize: `${cfg.frames * 100}% 100%`,
        backgroundPosition: "0% 0%",
      }}
    />
  );
}
