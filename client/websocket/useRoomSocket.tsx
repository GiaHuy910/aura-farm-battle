"use client";

import { useCallback, useEffect, useRef, useState } from "react";

import { config } from "@/config/config";

const WS_URL = config.server.wsUrl;

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
  winnerId?: string | null;
};

export type ConnectionState = "connecting" | "open" | "reconnecting";

type ServerMessage =
  | { type: "room.state"; data: RoomState }
  | { type: "room.player_joined"; data: { guest: Player } }
  | { type: "room.player_left"; data: { userId: string } }
  | {
      type: "room.player_online" | "room.player_offline";
      data: { userId: string };
    }
  | { type: "room.closed" | "room.kicked"; data: Record<string, never> }
  | { type: "game.start"; data: Record<string, never> }
  | {
      type: "game.finished";
      data: { winnerId: string | null; reason: string };
    };

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

export function useRoomSocket(roomId: string) {
  const [room, setRoom] = useState<RoomState | null>(null);
  const [connection, setConnection] = useState<ConnectionState>("connecting");
  const [closedReason, setClosedReason] = useState<string | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

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
    setClosedReason(null);
    setConnection("connecting");

    const giveUp = (reason: string) => {
      disposed = true;
      setClosedReason(reason);
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
        if (!msg) return;

        switch (msg.type) {
          case "room.state":
            setRoom(msg.data);
            break;
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
                setOnline(
                  r,
                  msg.data.userId,
                  msg.type === "room.player_online",
                ),
            );
            break;
          case "game.start":
            setRoom((r) => r && { ...r, status: "playing" });
            break;
          case "game.finished":
            setRoom(
              (r) =>
                r && { ...r, status: "finished", winnerId: msg.data.winnerId },
            );
            break;
          case "room.closed":
            giveUp("Room CLOSED, Owner left");
            break;
          case "room.kicked":
            giveUp("KICKED. Do not open this page in another tab");
            break;
        }
      };

      ws.onclose = () => {
        if (disposed) return;
        failures = opened ? 0 : failures + 1;

        if (!everOpened && failures >= 2) {
          giveUp("Not a member or room not exits");
          return;
        }
        if (everOpened && failures >= 6) {
          giveUp("Lost Connection To Room");
          return;
        }

        setConnection("reconnecting");
        timer = setTimeout(connect, Math.min(500 * 2 ** failures, 8000)); // 0.5s, 1s, 2s, 4s, 8s
      };
    };

    connect();

    return () => {
      disposed = true;
      if (timer) clearTimeout(timer);
      wsRef.current?.close();
    };
  }, [roomId]);

  return { room, connection, closedReason, send };
}
