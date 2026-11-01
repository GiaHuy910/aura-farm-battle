"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import {
  formatAura,
  rarityColor,
  skillImg,
  spriteConfig,
  EFFECT_LABEL,
} from "./battleAssets";
import { EffectIcon, SpriteLayer } from "./SpriteEffect";
import type { ActiveEffect, GameEvent } from "@/websocket/battleTypes";

type SkillUsed = Extract<GameEvent, { kind: "skill_used" }>;
type EffectApplied = Extract<GameEvent, { kind: "effect_applied" }>;

const FALLBACK_SHOW_MS = 2800;

function SkillFx({ ev, mine }: { ev: SkillUsed; mine: boolean }) {
  const hasEffect = ev.effectType !== "";
  return (
    <div
      className="d-flex flex-column align-items-center text-center p-2 rounded shadow"
      style={{
        background: "rgba(255,255,255,0.92)",
        border: `4px solid ${rarityColor(ev.skill.rarity)}`,
        minWidth: 150,
      }}
    >
      <small className="text-uppercase text-muted">
        {mine ? "You" : "Opponent"}
      </small>
      <img
        src={skillImg(ev.skillId)}
        alt={ev.skill.name}
        style={{ width: 110, height: 110, objectFit: "contain" }}
      />
      <strong>{ev.skill.name}</strong>
      <span className="text-success fw-bold">
        {formatAura(ev.auraBefore)} → {formatAura(ev.auraAfter)}
      </span>
      {hasEffect && (
        <span className="badge bg-dark d-inline-flex align-items-center gap-1">
          <EffectIcon type={ev.effectType} size={16} />
          {EFFECT_LABEL[ev.effectType] ?? ev.effectType}
        </span>
      )}
    </div>
  );
}

type Props = {
  seq: number | null;
  round: number | null;
  events: GameEvent[];
  meId: string;
  onRoundComplete: (round: number) => void;
  onBlockingChange: (blocking: boolean) => void;
};

export default function EffectOverlay({
  seq,
  round,
  events,
  meId,
  onRoundComplete,
  onBlockingChange,
}: Props) {
  const [playback, setPlayback] = useState<{
    seq: number | null;
    index: number;
    failed: boolean;
    playBlocked: boolean;
  }>({ seq: null, index: 0, failed: false, playBlocked: false });
  const videoRef = useRef<HTMLVideoElement>(null);
  const completedKey = useRef<string | null>(null);

  useEffect(() => {
    if (seq === null) return;
    setPlayback({ seq, index: 0, failed: false, playBlocked: false });
  }, [seq]);

  const sequence = useMemo(
    () => events.filter((event) => event.kind === "skill_used" || event.kind === "skipped"),
    [events],
  );
  const current = playback.seq === seq ? sequence[playback.index] : undefined;
  const advance = () => {
    setPlayback((previous) => ({
      ...previous,
      index: previous.index + 1,
      failed: false,
      playBlocked: false,
    }));
  };

  useEffect(() => {
    if (!current || (current.kind === "skill_used" && !playback.failed)) return;
    const timer = setTimeout(advance, FALLBACK_SHOW_MS);
    return () => clearTimeout(timer);
  }, [seq, playback.index, playback.failed, current]);

  useEffect(() => {
    onBlockingChange(!!current);
  }, [current, onBlockingChange]);

  useEffect(() => {
    if (seq === null || round === null || playback.seq !== seq || current) {
      return;
    }
    const key = `${seq}:${round}`;
    if (completedKey.current === key) return;
    completedKey.current = key;
    onRoundComplete(round);
  }, [seq, round, playback.seq, current, onRoundComplete]);

  useEffect(
    () => () => onBlockingChange(false),
    [onBlockingChange],
  );

  const playVideo = () => {
    const video = videoRef.current;
    if (!video) return;
    video.muted = false;
    video.volume = 1;
    void video.play().then(
      () =>
        setPlayback((previous) => ({ ...previous, playBlocked: false })),
      () => setPlayback((previous) => ({ ...previous, playBlocked: true })),
    );
  };

  if (seq === null || playback.seq !== seq || !current) return null;

  return (
    <div
      className="d-flex justify-content-center align-items-center p-2"
      style={{
        position: "absolute",
        inset: 0,
        zIndex: 30,
        background: "#000",
        touchAction: "none",
        pointerEvents: "auto",
      }}
      onWheel={(event) => event.preventDefault()}
      onTouchMove={(event) => event.preventDefault()}
    >
      {current.kind === "skill_used" ? (
        <div
          key={`${seq}-${playback.index}`}
          className="d-flex flex-column align-items-center gap-2"
          style={{ width: "min(100%, 720px)" }}
        >
          {!playback.failed ? (
            <video
              ref={videoRef}
              src={`/effects/skills/${current.skillId.split("_")[0].toUpperCase()}/${current.skillId}-effect.mp4`}
              autoPlay
              onCanPlay={playVideo}
              playsInline
              onEnded={advance}
              onError={() =>
                setPlayback((previous) => ({ ...previous, failed: true }))
              }
              aria-label={`${current.skill.name} effect`}
              style={{
                display: "block",
                width: "100%",
                maxHeight: "48vh",
                objectFit: "contain",
                background: "rgba(0,0,0,0.72)",
                border: `3px solid ${rarityColor(current.skill.rarity)}`,
              }}
            />
          ) : (
            <SkillFx ev={current} mine={current.userId === meId} />
          )}
          {!playback.failed && (
            <div className="px-3 py-2 rounded bg-dark bg-opacity-75 text-white text-center">
              <strong>{current.userId === meId ? "You" : "Opponent"}</strong>
              <span className="mx-2">{current.skill.name}</span>
              <span className="text-success fw-bold">
                {formatAura(current.auraBefore)} → {formatAura(current.auraAfter)}
              </span>
            </div>
          )}
          {!playback.failed && playback.playBlocked && (
            <button
              type="button"
              className="btn btn-light"
              onClick={playVideo}
            >
              Play effect with sound
            </button>
          )}
        </div>
      ) : (
        <div className="p-2 rounded bg-white text-center shadow">
          <EffectIcon type="freeze" size={80} />
          <div className="fw-bold">
            {current.userId === meId ? "You are" : "Opponent is"} frozen
          </div>
        </div>
      )}
    </div>
  );
}

type FxProps = {
  userId: string;
  effects: ActiveEffect[];
  seq: number | null;
  events: GameEvent[];
};

export function FighterFx({ userId, effects, seq, events }: FxProps) {
  const persist = effects.filter(
    (e) => spriteConfig(e.type)?.mode === "persist",
  );

  const burstTypes =
    seq === null
      ? []
      : Array.from(
          new Set(
            events
              .filter((e): e is EffectApplied => e.kind === "effect_applied")
              .filter((e) => spriteConfig(e.effectType)?.mode === "burst")
              .filter((e) => e.userId === userId || e.effectType === "purify")
              .map((e) => e.effectType),
          ),
        );

  return (
    <>
      {persist.map((e) => (
        <SpriteLayer key={e.type} type={e.type} loop />
      ))}
      {burstTypes.map((t) => (
        <SpriteLayer key={`${seq}-${t}`} type={t} loop={false} />
      ))}
    </>
  );
}

export function ActiveEffectIcons({ effects }: { effects: ActiveEffect[] }) {
  if (effects.length === 0) return null;
  return (
    <div className="d-flex gap-1 justify-content-center flex-wrap">
      {effects.map((e) => (
        <span key={e.type} className="position-relative d-inline-block">
          <EffectIcon
            type={e.type}
            size={32}
            title={`${EFFECT_LABEL[e.type] ?? e.type} (${e.left} left)`}
          />
          <span
            className="badge bg-dark rounded-pill"
            style={{
              position: "absolute",
              right: -6,
              bottom: -6,
              fontSize: 10,
            }}
          >
            {e.left}
          </span>
        </span>
      ))}
    </div>
  );
}
