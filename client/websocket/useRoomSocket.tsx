"use client";

import { useCallback, useEffect, useRef, useState } from "react";

import { config } from "@/config/config";
import type {
  BattleView,
  FighterPublic,
  FinishedInfo,
  GameEvent,
  GamePhase,
  GameState,
  RewardOffer,
  RewardResult,
} from "./battleTypes";

export type Player = {
  id: string;
  name: string;
  online: boolean;
  equipped_clothes: string[];
  total_aura: number;
};

export type RoomStatus = "waiting" | "playing" | "finished";

export type RoomState = {
  status: RoomStatus;
  owner: Player;
  guest: Player | null;
};

export type ConnectionState = "connecting" | "open" | "reconnecting";

type RawBattle = Omit<BattleView, "roundOpen" | "deadlineAt"> & {
  timeLeftMs: number | null;
};
type RawOffer = Omit<RewardOffer, "deadlineAt"> & { timeLeftMs: number };
type SnapshotGame = {
  phase: GamePhase;
  battle: RawBattle | null;
  finished: FinishedInfo | null;
  offer: RawOffer | null;
  result: RewardResult | null;
  rematch: string[];
};

type ServerMessage =
  | { type: "room.state"; data: RoomState & { game: SnapshotGame | null } }
  | { type: "room.player_joined"; data: { guest: Player } }
  | { type: "room.player_left"; data: { userId: string } }
  | {
      type: "room.player_online" | "room.player_offline";
      data: { userId: string };
    }
  | {
      type: "room.closed" | "room.kicked" | "room.reset";
      data: Record<string, never>;
    }
  | {
      type: "game.start";
      data: { maxRounds: number; order: string[]; players: FighterPublic[] };
    }
  | { type: "game.round"; data: RawBattle }
  | { type: "game.chosen"; data: { userId: string } }
  | {
      type: "game.round_result";
      data: { round: number; events: GameEvent[]; players: FighterPublic[] };
    }
  | { type: "game.finished"; data: FinishedInfo }
  | { type: "reward.offer"; data: RawOffer }
  | {
      type: "reward.picked";
      data: { kind: "skill" | "clothe"; picked: boolean };
    }
  | { type: "reward.result"; data: RewardResult }
  | { type: "match.ended"; data: Record<string, never> }
  | { type: "rematch.status"; data: { ready: string[] } }
  | { type: "game.error"; data: { code: string } };

const WS_URL = config.server.wsUrl;

function parseMessage(raw: string): ServerMessage | null {
  try {
    return JSON.parse(raw) as ServerMessage;
  } catch {
    return null;
  }
}

function setOnline(
  room: RoomState,
  userId: string,
  online: boolean,
): RoomState {
  return {
    ...room,
    owner: room.owner.id === userId ? { ...room.owner, online } : room.owner,
    guest:
      room.guest && room.guest.id === userId
        ? { ...room.guest, online }
        : room.guest,
  };
}

function toBattle(raw: RawBattle): BattleView {
  const { timeLeftMs, ...rest } = raw;
  return {
    ...rest,
    roundOpen: timeLeftMs !== null,
    deadlineAt: timeLeftMs !== null ? Date.now() + timeLeftMs : null,
  };
}

function toOffer(raw: RawOffer): RewardOffer {
  const { timeLeftMs, ...rest } = raw;
  return { ...rest, deadlineAt: Date.now() + timeLeftMs };
}

function emptyGame(): GameState {
  return {
    phase: "battle",
    battle: null,
    finished: null,
    offer: null,
    result: null,
    picked: { skill: false, clothe: false },
    rematch: [],
    lastRound: null,
    log: [],
  };
}

function fromSnapshot(g: SnapshotGame | null): GameState | null {
  if (!g) return null;
  return {
    ...emptyGame(),
    phase: g.phase,
    battle: g.battle ? toBattle(g.battle) : null,
    finished: g.finished,
    offer: g.offer ? toOffer(g.offer) : null,
    result: g.result,
    rematch: g.rematch,
  };
}

function applyPlayers(b: BattleView, players: FighterPublic[]): BattleView {
  const find = (id: string) => players.find((p) => p.id === id);
  const you = b.you ? find(b.you.id) : undefined;
  const opp = b.opponent ? find(b.opponent.id) : undefined;
  return {
    ...b,
    roundOpen: false,
    deadlineAt: null,
    you: b.you && you ? { ...b.you, ...you } : b.you,
    opponent: b.opponent && opp ? { ...b.opponent, ...opp } : b.opponent,
  };
}

function markChosen(b: BattleView, userId: string): BattleView {
  return {
    ...b,
    you: b.you && b.you.id === userId ? { ...b.you, chosen: true } : b.you,
    opponent:
      b.opponent && b.opponent.id === userId
        ? { ...b.opponent, chosen: true }
        : b.opponent,
  };
}

export function useRoomSocket(roomId: string) {
  const [room, setRoom] = useState<RoomState | null>(null);
  const [game, setGame] = useState<GameState | null>(null);
  const [connection, setConnection] = useState<ConnectionState>("connecting");
  const [closedReason, setClosedReason] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const errorTimer = useRef<ReturnType<typeof setTimeout> | undefined>(
    undefined,
  );

  const send = useCallback((type: string, data: unknown = {}) => {
    const ws = wsRef.current;
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type, data }));
    }
  }, []);

  useEffect(() => {
    let disposed = false;
    let failures = 0;
    let everOpened = false;
    let timer: ReturnType<typeof setTimeout> | undefined;

    setRoom(null);
    setGame(null);
    setClosedReason(null);
    setConnection("connecting");

    const giveUp = (reason: string) => {
      disposed = true;
      setClosedReason(reason);
    };

    const showError = (code: string) => {
      setError(code);
      if (errorTimer.current) clearTimeout(errorTimer.current);
      errorTimer.current = setTimeout(() => setError(null), 3000);
    };

    const handle = (msg: ServerMessage) => {
      switch (msg.type) {
        case "room.state": {
          const { game: g, ...r } = msg.data;
          setRoom(r);
          setGame(fromSnapshot(g));
          break;
        }
        case "room.player_joined":
          setRoom((r) => r && { ...r, guest: msg.data.guest });
          break;
        case "room.player_left":
          setRoom((r) => r && { ...r, guest: null });
          break;
        case "room.player_online":
        case "room.player_offline":
          setRoom(
            (r) =>
              r &&
              setOnline(r, msg.data.userId, msg.type === "room.player_online"),
          );
          break;

        case "game.start":
          setRoom((r) => r && { ...r, status: "playing" });
          setGame(emptyGame());
          break;
        case "game.round":
          setGame((g) => ({
            ...(g ?? emptyGame()),
            phase: "battle",
            battle: toBattle(msg.data),
          }));
          break;
        case "game.chosen":
          setGame((g) =>
            g && g.battle
              ? { ...g, battle: markChosen(g.battle, msg.data.userId) }
              : g,
          );
          break;
        case "game.round_result":
          setGame((g) => {
            if (!g) return g;
            const seq = (g.lastRound?.seq ?? 0) + 1;
            return {
              ...g,
              battle: g.battle
                ? applyPlayers(g.battle, msg.data.players)
                : g.battle,
              lastRound: {
                seq,
                round: msg.data.round,
                events: msg.data.events,
              },
              log: [
                ...g.log,
                { round: msg.data.round, events: msg.data.events },
              ],
            };
          });
          break;
        case "game.finished":
          setRoom((r) => r && { ...r, status: "finished" });
          setGame((g) => ({
            ...(g ?? emptyGame()),
            phase: "reward",
            finished: msg.data,
          }));
          break;

        case "reward.offer":
          setGame((g) => g && { ...g, offer: toOffer(msg.data) });
          break;
        case "reward.picked":
          setGame(
            (g) =>
              g && {
                ...g,
                picked: { ...g.picked, [msg.data.kind]: msg.data.picked },
              },
          );
          break;
        case "reward.result":
          setGame((g) => g && { ...g, result: msg.data });
          break;
        case "match.ended":
          setGame((g) => g && { ...g, phase: "ended", rematch: [] });
          break;
        case "rematch.status":
          setGame((g) => g && { ...g, rematch: msg.data.ready });
          break;
        case "room.reset":
          setGame(null);
          break;

        case "game.error":
          showError(msg.data.code);
          break;
        case "room.closed":
          giveUp("The owner left, the room is closed.");
          break;
        case "room.kicked":
          giveUp("You opened this room in another tab.");
          break;
      }
    };

    const connect = () => {
      const ws = new WebSocket(
        `${WS_URL}/ws/rooms/${encodeURIComponent(roomId)}`,
      );
      wsRef.current = ws;
      let opened = false;

      ws.onopen = () => {
        opened = true;
        everOpened = true;
        failures = 0;
        setConnection("open");
      };

      ws.onmessage = (event: MessageEvent<string>) => {
        const msg = parseMessage(event.data);
        if (msg) handle(msg);
      };

      ws.onclose = () => {
        if (disposed) return;
        failures = opened ? 0 : failures + 1;

        if (!everOpened && failures >= 2) {
          giveUp(
            "Cannot join this room (it does not exist or you are not a member).",
          );
          return;
        }
        if (everOpened && failures >= 6) {
          giveUp("Lost connection to the room.");
          return;
        }

        setConnection("reconnecting");
        timer = setTimeout(connect, Math.min(500 * 2 ** failures, 8000));
      };
    };

    connect();

    return () => {
      disposed = true;
      if (timer) clearTimeout(timer);
      if (errorTimer.current) clearTimeout(errorTimer.current);
      wsRef.current?.close();
    };
  }, [roomId]);

  return { room, game, connection, closedReason, error, send };
}
