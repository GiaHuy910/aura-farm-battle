"use client";

import UserCharacter from "@/components/UserCharacter";
import { characterUrls, formatAura } from "./battleAssets";
import type { Player } from "@/websocket/useRoomSocket";
import type { FighterPublic } from "@/websocket/battleTypes";
import EnergyBar from "./EnergyBar";
import { ActiveEffectIcons, FighterFx } from "./EffectOverlay";
import type { GameEvent } from "@/websocket/battleTypes";
import type { ChatMessage } from "@/websocket/useRoomSocket";
import BattleChat, { ChatBubble } from "./BattleChat";

const CHAR_SCALE = 0.7;

type SlotProps = {
  player: Player | null;
  fighter: FighterPublic | null;
  isMe: boolean;
  first: boolean;
  showChosen: boolean;
  seq: number | null;
  events: GameEvent[];
  chatMessage: ChatMessage | null;
  chatError: { code: string; retryAfterMs: number } | null;
  onChatSend: (type: string, data?: unknown) => void;
};

function FighterCard({
  player,
  fighter,
  isMe,
  first,
  showChosen,
  seq,
  events,
  chatMessage,
  chatError,
  onChatSend,
}: SlotProps) {
  if (!player || !fighter)
    return <div className="text-muted text-center">—</div>;
  return (
    <div
      className="d-flex flex-column align-items-center text-center gap-1"
      style={{ opacity: player.online ? 1 : 0.5 }}
    >
      <div className="fw-bold d-flex justify-content-center align-items-center gap-1">
        {player.name}
        {isMe && <span className="badge bg-primary ms-2">You</span>}
        {first && <span className="badge bg-warning text-dark ms-1">1st</span>}
        <BattleChat
          message={chatMessage}
          meId={isMe ? fighter.id : ""}
          userId={fighter.id}
          error={isMe ? chatError : null}
          onSend={onChatSend}
        />
      </div>

      <div style={{ width: 256 * CHAR_SCALE, height: 256 * CHAR_SCALE, position: "relative" }}>
        {chatMessage?.userId === fighter.id && (
          <ChatBubble key={chatMessage.sentAt} message={chatMessage} />
        )}
        <div
          style={{
            transform: `scale(${CHAR_SCALE})`,
            transformOrigin: "top left",
          }}
        >
          <div style={{ position: "relative", width: 256, height: 256 }}>
            <UserCharacter {...characterUrls(player.equipped_clothes)} />
            <FighterFx
              userId={fighter.id}
              effects={fighter.effects}
              seq={seq}
              events={events}
            />
          </div>
        </div>
      </div>

      <div
        className="fs-4 fw-bold"
        title={fighter.aura.toLocaleString("en-US")}
      >
        {formatAura(fighter.aura)}{" "}
        <small className="fs-6 text-muted">Aura</small>
      </div>
      <EnergyBar value={fighter.energy} />
      <ActiveEffectIcons effects={fighter.effects} />
      {showChosen && (
        <span
          className={`badge ${fighter.chosen ? "bg-success" : "bg-secondary"}`}
        >
          {fighter.chosen ? "Ready" : "Choosing..."}
        </span>
      )}
      {!player.online && (
        <span className="badge bg-secondary">Disconnected</span>
      )}
    </div>
  );
}

type Props = {
  owner: Player;
  guest: Player | null;
  you: FighterPublic | null;
  opponent: FighterPublic | null;
  meId: string;
  order: string[];
  showChosen: boolean;
  seq: number | null;
  events: GameEvent[];
  chatMessage: ChatMessage | null;
  chatError: { code: string; retryAfterMs: number } | null;
  onChatSend: (type: string, data?: unknown) => void;
};

export default function ScoreBoard({
  owner,
  guest,
  you,
  opponent,
  meId,
  order,
  showChosen,
  seq,
  events,
  chatMessage,
  chatError,
  onChatSend,
}: Props) {
  const mePlayer = owner.id === meId ? owner : guest;
  const oppPlayer = owner.id === meId ? guest : owner;
  return (
    <div className="row w-100 align-items-center justify-content-center">
      <div className="col-5">
        <FighterCard
          player={mePlayer}
          fighter={you}
          isMe
          first={order[0] === meId}
          showChosen={showChosen}
          seq={seq}
          events={events}
          chatMessage={chatMessage}
          chatError={chatError}
          onChatSend={onChatSend}
        />
      </div>
      <div className="col-2 text-center fs-2 fw-bold">VS</div>
      <div className="col-5">
        <FighterCard
          player={oppPlayer}
          fighter={opponent}
          isMe={false}
          first={!!oppPlayer && order[0] === oppPlayer.id}
          showChosen={showChosen}
          seq={seq}
          events={events}
          chatMessage={chatMessage}
          chatError={chatError}
          onChatSend={onChatSend}
        />
      </div>
    </div>
  );
}
