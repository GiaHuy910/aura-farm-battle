"use client";

import { useEffect, useState } from "react";
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

const SHOW_MS = 2800;

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
  events: GameEvent[];
  meId: string;
};

export default function EffectOverlay({ seq, events, meId }: Props) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (seq === null) return;
    setVisible(true);
    const t = setTimeout(() => setVisible(false), SHOW_MS);
    return () => clearTimeout(t);
  }, [seq]);

  if (!visible) return null;
  const used = events.filter((e): e is SkillUsed => e.kind === "skill_used");
  const skipped = events.filter((e) => e.kind === "skipped");
  if (used.length === 0 && skipped.length === 0) return null;

  return (
    <div
      className="d-flex justify-content-center align-items-center gap-3 flex-wrap"
      style={{
        position: "absolute",
        inset: 0,
        zIndex: 20,
        background: "rgba(0,0,0,0.25)",
      }}
    >
      {used.map((ev) => (
        <SkillFx key={ev.userId} ev={ev} mine={ev.userId === meId} />
      ))}
      {skipped.map((ev) =>
        ev.kind === "skipped" ? (
          <div
            key={ev.userId}
            className="p-2 rounded bg-white text-center shadow"
          >
            <EffectIcon type="freeze" size={80} />
            <div className="fw-bold">
              {ev.userId === meId ? "You are" : "Opponent is"} frozen
            </div>
          </div>
        ) : null,
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
