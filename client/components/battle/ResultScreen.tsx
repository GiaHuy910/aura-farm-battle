"use client";

import { itemImg, rarityColor, formatAura } from "./battleAssets";
import type { GameState } from "@/websocket/battleTypes";

type Props = {
  game: GameState;
  meId: string;
  send: (type: string, data?: unknown) => void;
  onLeave: () => void;
  leaving: boolean;
};

export default function ResultScreen({
  game,
  meId,
  send,
  onLeave,
  leaving,
}: Props) {
  const { finished, result, rematch } = game;
  const draw = !!finished && finished.winnerId === null;
  const won = !!finished && finished.winnerId === meId;
  const iAmReady = rematch.includes(meId);
  const opponentReady = rematch.some((id) => id !== meId);

  return (
    <div className="w-100 text-center">
      <h3>
        {draw ? (
          "DRAW"
        ) : won ? (
          <>
            YOU <span className="text-success">WON</span>!
          </>
        ) : (
          <>
            YOU <span className="text-danger">LOST</span>
          </>
        )}
      </h3>

      {finished && (
        <p className="text-muted">
          {finished.reason === "forfeit"
            ? "The opponent left the match."
            : "Final Aura:"}{" "}
          {finished.players.map((p, i) => (
            <span key={p.id}>
              {i > 0 && " vs "}
              <strong>{p.id === meId ? "You" : "Opponent"}</strong>{" "}
              {formatAura(p.aura)}
            </span>
          ))}
        </p>
      )}

      {draw && <p>It is a draw, so nobody gets a reward.</p>}

      {result ? (
        <div className="my-3">
          {won && (
            <div className="text-success fw-bold mb-2">
              +{result.tickets} gacha tickets
            </div>
          )}
          <h6>{won ? "You received" : "You lost"}</h6>
          {result.taken.length === 0 ? (
            <p className="text-muted">No items were taken.</p>
          ) : (
            <div className="d-flex gap-2 justify-content-center flex-wrap">
              {result.taken.map(
                (t) =>
                  t.item && (
                    <div
                      key={t.item.id}
                      className="p-2 bg-white rounded"
                      style={{
                        width: 150,
                        border: `4px solid ${rarityColor(t.item.rarity)}`,
                      }}
                    >
                      <img
                        src={itemImg(t.item)}
                        alt={t.item.name}
                        style={{
                          height: 90,
                          maxWidth: "100%",
                          objectFit: "contain",
                        }}
                      />
                      <div className="fw-bold small">{t.item.name}</div>
                      <div
                        className="small"
                        style={{ color: rarityColor(t.item.rarity) }}
                      >
                        {t.item.rarity}
                      </div>
                      {!won && t.replacedWith && (
                        <div className="small text-danger">
                          Your slot was reset to the default item
                        </div>
                      )}
                    </div>
                  ),
              )}
            </div>
          )}
          {!won && result.taken.some((t) => t.item?.kind === "clothe") && (
            <p className="small mt-2">
              Your Aura is now {formatAura(result.loserAura)}.
            </p>
          )}
          {result.auto && (
            <p className="small text-muted">
              Some picks were made by the server (time ran out).
            </p>
          )}
        </div>
      ) : (
        !draw && <p className="text-muted">Settling the reward...</p>
      )}

      {game.phase === "ended" ? (
        <div className="mt-3">
          <div className="d-flex gap-3 justify-content-center">
            <button
              className="btn btn-success btn-lg"
              disabled={iAmReady}
              onClick={() => send("game.playagain")}
            >
              {iAmReady ? "Waiting for opponent..." : "PLAY AGAIN"}
            </button>
            <button
              className="btn btn-outline-danger btn-lg"
              disabled={leaving}
              onClick={onLeave}
            >
              LEAVE
            </button>
          </div>
          {!iAmReady && opponentReady && (
            <p className="mt-2 text-success">
              Your opponent wants to play again!
            </p>
          )}
        </div>
      ) : (
        <p className="small text-muted mt-3">
          Buttons appear once everything is settled.
        </p>
      )}
    </div>
  );
}
