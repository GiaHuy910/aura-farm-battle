"use client";

import type { RoomState } from "@/websocket/useRoomSocket";
import type { GameState } from "@/websocket/battleTypes";
import EffectOverlay from "./EffectOverlay";
import HandPanel from "./HandPanel";
import RewardPanel from "./RewardPannel";
import ResultScreen from "./ResultScreen";
import RoundLog from "./RoundLog";
import RoundTimer from "./RoundTimer";
import ScoreBoard from "./ScoreBoard";

const ROUND_SECS = 20;

const ERROR_TEXT: Record<string, string> = {
  not_open: "The round is not open yet.",
  already_chosen: "You already chose a skill.",
  bad_index: "Invalid card.",
  not_enough_energy: "Not enough energy for that skill.",
  frozen: "You are frozen this round.",
  not_in_offer: "That item is not in the offer.",
  incomplete: "Pick one item in each row first.",
  too_late: "Too late, the reward is being settled.",
  no_reward: "There is no reward to pick.",
};

type Props = {
  room: RoomState;
  game: GameState;
  meId: string;
  send: (type: string, data?: unknown) => void;
  error: string | null;
  onLeave: () => void;
  leaving: boolean;
};

export default function BattleScreen({
  room,
  game,
  meId,
  send,
  error,
  onLeave,
  leaving,
}: Props) {
  const b = game.battle;
  const draw = !!game.finished && game.finished.winnerId === null;

  if (game.phase === "ended" || game.result || draw) {
    return (
      <ResultScreen
        game={game}
        meId={meId}
        send={send}
        onLeave={onLeave}
        leaving={leaving}
      />
    );
  }
  if (game.phase === "reward") {
    return (
      <RewardPanel
        offer={game.offer}
        finished={game.finished}
        meId={meId}
        send={send}
      />
    );
  }

  if (!b || !b.you) {
    return (
      <div className="text-center">
        <div className="spinner-border" role="status" />
        <p className="mt-2">Starting the match...</p>
      </div>
    );
  }

  return (
    <div className="w-100 position-relative overflow-auto">
      <div className="d-flex justify-content-between align-items-center mb-2">
        <h5 className="mb-0">
          Round {b.round} / {b.maxRounds}
        </h5>
        <RoundTimer deadlineAt={b.deadlineAt} total={ROUND_SECS} />
      </div>

      <ScoreBoard
        owner={room.owner}
        guest={room.guest}
        you={b.you}
        opponent={b.opponent}
        meId={meId}
        order={b.order}
        showChosen={b.roundOpen}
        seq={game.lastRound?.seq ?? null}
        events={game.lastRound?.events ?? []}
      />

      <div className="mt-3">
        <HandPanel
          hand={b.you.hand}
          choice={b.you.choice}
          frozen={b.you.frozen}
          open={b.roundOpen}
          onPick={(i) => send("game.action", { index: i })}
        />
        {!b.roundOpen && (
          <p className="text-center text-muted mt-2">Next round is coming...</p>
        )}
        {error && (
          <div className="alert alert-warning py-1 mt-2 text-center">
            {ERROR_TEXT[error] ?? error}
          </div>
        )}
      </div>

      <RoundLog log={game.log} meId={meId} />

      <EffectOverlay
        seq={game.lastRound?.seq ?? null}
        events={game.lastRound?.events ?? []}
        meId={meId}
      />
    </div>
  );
}
