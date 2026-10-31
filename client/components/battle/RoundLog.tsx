"use client";

import { useState } from "react";
import { formatAura, EFFECT_LABEL } from "./battleAssets";
import type { GameEvent, RoundRecord } from "@/websocket/battleTypes";

function line(e: GameEvent, who: (id: string) => string): string | null {
  switch (e.kind) {
    case "skill_used":
      return `${who(e.userId)} used ${e.skill.name}: ${formatAura(e.auraBefore)} → ${formatAura(e.auraAfter)}`;
    case "skipped":
      return `${who(e.userId)} was frozen and skipped`;
    case "auto_picked":
      return `${who(e.userId)} ran out of time (auto-picked)`;
    case "skill_replaced":
      return `${who(e.userId)}'s skill was scrambled by Brainrot`;
    case "effect_applied":
      return `${EFFECT_LABEL[e.effectType] ?? e.effectType} on ${who(e.userId)} for ${e.rounds} rounds`;
    case "effect_blocked":
      return `${EFFECT_LABEL[e.effectType] ?? e.effectType} on ${who(e.userId)} blocked by ${e.by}`;
    case "effect_cleansed":
      return `${EFFECT_LABEL[e.effectType] ?? e.effectType} on ${who(e.userId)} was cleansed`;
    case "effect_expired":
      return `${EFFECT_LABEL[e.effectType] ?? e.effectType} on ${who(e.userId)} wore off`;
  }
}

export default function RoundLog({
  log,
  meId,
}: {
  log: RoundRecord[];
  meId: string;
}) {
  const [open, setOpen] = useState(false);
  const who = (id: string) => (id === meId ? "You" : "Opponent");

  return (
    <div className="w-100 mt-3">
      <button
        className="btn btn-sm btn-outline-secondary"
        onClick={() => setOpen((o) => !o)}
      >
        {open ? "Hide log" : "Show log"} ({log.length})
      </button>
      {open && (
        <div
          className="mt-2 p-2 bg-white rounded small"
          style={{ maxHeight: 220, overflowY: "auto" }}
        >
          {[...log].reverse().map((r) => (
            <div key={r.round} className="mb-2">
              <strong>Round {r.round}</strong>
              <ul className="mb-0 ps-3">
                {r.events.map((e, i) => {
                  const t = line(e, who);
                  return t ? <li key={i}>{t}</li> : null;
                })}
              </ul>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
