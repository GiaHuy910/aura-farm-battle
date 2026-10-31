"use client";

import { useState } from "react";
import { itemImg, rarityColor, formatAura } from "./battleAssets";
import type {
  FinishedInfo,
  RewardItem,
  RewardOffer,
} from "@/websocket/battleTypes";
import { useCountdown } from "./RoundTimer";

type Props = {
  offer: RewardOffer | null;
  finished: FinishedInfo | null;
  meId: string;
  send: (type: string, data?: unknown) => void;
};

function ItemCard({
  item,
  selected,
  disabled,
  onClick,
}: {
  item: RewardItem;
  selected: boolean;
  disabled: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="btn p-2 text-center"
      style={{
        width: 140,
        background: selected ? "#fff6c9" : "#fff",
        border: `4px solid ${selected ? "#2e7d32" : rarityColor(item.rarity)}`,
        opacity: disabled && !selected ? 0.5 : 1,
      }}
    >
      <img
        src={itemImg(item)}
        alt={item.name}
        style={{ height: 90, maxWidth: "100%", objectFit: "contain" }}
      />
      <div className="fw-bold small mt-1">{item.name}</div>
      <div className="small" style={{ color: rarityColor(item.rarity) }}>
        {item.isUlt ? "ULT · " : ""}
        {item.rarity}
      </div>
      {item.kind === "clothe" && item.auraBonus !== undefined && (
        <div className="small text-success">
          +{formatAura(item.auraBonus)} Aura
        </div>
      )}
      {selected && (
        <div className="small text-success fw-bold">Chosen · tap to undo</div>
      )}
    </button>
  );
}

function Row({
  title,
  items,
  selectedId,
  canPick,
  onPick,
}: {
  title: string;
  items: RewardItem[];
  selectedId: string | null;
  canPick: boolean;
  onPick: (id: string) => void;
}) {
  if (items.length === 0) return null;
  return (
    <div className="mb-3">
      <h6 className="text-center">{title}</h6>
      <div className="d-flex gap-2 justify-content-center flex-wrap">
        {items.map((it) => (
          <ItemCard
            key={it.id}
            item={it}
            selected={selectedId === it.id}
            disabled={!canPick}
            onClick={() => onPick(it.id)}
          />
        ))}
      </div>
    </div>
  );
}

export default function RewardPanel({ offer, finished, meId, send }: Props) {
  const [selSkill, setSelSkill] = useState<string | null>(null);
  const [selClothe, setSelClothe] = useState<string | null>(null);
  const left = useCountdown(offer?.deadlineAt ?? null);

  const isWinner = !!finished && finished.winnerId === meId;

  const [confirmed, setConfirmed] = useState(false);

  const toggle = (kind: "skill" | "clothe", id: string) => {
    if (confirmed) return;
    const cur = kind === "skill" ? selSkill : selClothe;
    const set = kind === "skill" ? setSelSkill : setSelClothe;
    if (cur === id) {
      set(null);
      send("reward.unpick", { itemId: id });
    } else {
      set(id);
      send("reward.pick", { itemId: id });
    }
  };

  if (!offer) {
    return (
      <div className="text-center">
        <div className="spinner-border" role="status" />
        <p className="mt-2">Preparing the reward...</p>
      </div>
    );
  }

  const nothing = offer.skills.length === 0 && offer.clothes.length === 0;
  const complete =
    (offer.skills.length === 0 || selSkill !== null) &&
    (offer.clothes.length === 0 || selClothe !== null);

  return (
    <div className="w-100 overflow-auto">
      <div className="text-center mb-3">
        <h4>
          {isWinner ? (
            <>
              YOU <span className="text-success">WON</span>! Pick your reward
            </>
          ) : (
            <>
              YOU <span className="text-danger">LOST</span>. The winner is
              picking from your items
            </>
          )}
        </h4>
        {isWinner && (
          <div className="text-success fw-bold">
            +{offer.tickets} gacha tickets
          </div>
        )}
        {left !== null && (
          <div className={`fw-bold ${left <= 5 ? "text-danger" : ""}`}>
            {left}s left (the server picks for any row left empty)
          </div>
        )}
      </div>

      {nothing ? (
        <p className="text-center text-muted">
          The loser has nothing that can be taken.
        </p>
      ) : (
        <>
          <Row
            title={isWinner ? "Choose 1 skill" : "Skills at risk"}
            items={offer.skills}
            selectedId={selSkill}
            canPick={isWinner && !confirmed}
            onPick={(id) => toggle("skill", id)}
          />
          <Row
            title={isWinner ? "Choose 1 outfit piece" : "Outfit pieces at risk"}
            items={offer.clothes}
            selectedId={selClothe}
            canPick={isWinner && !confirmed}
            onPick={(id) => toggle("clothe", id)}
          />
          {isWinner && (
            <div className="text-center">
              <button
                className="btn btn-success btn-lg"
                disabled={!complete || confirmed}
                onClick={() => {
                  setConfirmed(true);
                  send("reward.confirm");
                }}
              >
                {confirmed ? "Confirmed..." : "CONFIRM"}
              </button>
              {!complete && (
                <div className="small text-muted mt-1">
                  Pick one in each row to confirm
                </div>
              )}
            </div>
          )}
        </>
      )}
    </div>
  );
}
