"use client";

import { skillImg, rarityColor, EFFECT_LABEL } from "./battleAssets";
import { EffectIcon } from "./SpriteEffect";
import type { CardInfo } from "@/websocket/battleTypes";

type Props = {
  hand: CardInfo[];
  choice: number | null;
  frozen: boolean;
  open: boolean;
  onPick: (index: number) => void;
};

export default function HandPanel({
  hand,
  choice,
  frozen,
  open,
  onPick,
}: Props) {
  const locked = !open || choice !== null || frozen;

  return (
    <div>
      {frozen && (
        <div className="alert alert-info py-1 text-center">
          You are frozen this round.
        </div>
      )}
      <div className="d-flex gap-2 justify-content-center flex-wrap">
        {hand.map((c, i) => {
          const playable = c.playable !== false;
          const chosen = choice === i;
          const disabled = locked || !playable;
          return (
            <button
              key={`${c.id}-${i}`}
              type="button"
              disabled={disabled}
              onClick={() => onPick(i)}
              className="btn p-2 text-center"
              style={{
                width: 150,
                background: chosen ? "#fff6c9" : "#fff",
                border: `4px solid ${chosen ? "#2e7d32" : rarityColor(c.rarity)}`,
                opacity: !playable
                  ? 0.4
                  : choice !== null && !chosen
                    ? 0.55
                    : 1,
                transform: chosen ? "translateY(-6px)" : "none",
                transition: "transform 0.15s, opacity 0.15s",
              }}
            >
              <div style={{ position: "relative", height: 90 }}>
                <img
                  src={skillImg(c.id)}
                  alt={c.name}
                  style={{
                    height: "100%",
                    maxWidth: "100%",
                    objectFit: "contain",
                  }}
                />
                {c.effect && (
                  <span style={{ position: "absolute", right: 0, bottom: 0 }}>
                    <EffectIcon
                      type={c.effect}
                      size={30}
                      title={EFFECT_LABEL[c.effect] ?? c.effect}
                    />
                  </span>
                )}
              </div>
              <div className="fw-bold small mt-1">{c.name}</div>
              <div className="small" style={{ color: rarityColor(c.rarity) }}>
                {c.isUlt ? "ULT · " : ""}
                {c.rarity}
              </div>
              <div className="small">×{c.mult}</div>
              <div className="small fw-bold">
                {c.isUlt ? (
                  <span className={playable ? "text-danger" : "text-muted"}>
                    −{c.consume} ⚡
                  </span>
                ) : (
                  <span className="text-success">+{c.recover} ⚡</span>
                )}
              </div>
              {chosen && (
                <div className="small text-success fw-bold">Chosen</div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
