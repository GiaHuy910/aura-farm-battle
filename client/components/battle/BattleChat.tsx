"use client";

import { FormEvent, useEffect, useState } from "react";
import type { ChatMessage } from "@/websocket/useRoomSocket";
import styles from "./BattleChat.module.css";

const CHAT_COOLDOWN_MS = 15_000;

const CHAT_ERROR_TEXT: Record<string, string> = {
  empty: "Enter a message.",
  too_long: "Maximum 64 characters.",
  cooldown: "Please wait before chatting again.",
  not_in_battle: "Chat is only available during a battle.",
};

type Props = {
  message: ChatMessage | null;
  meId: string;
  userId: string;
  error: { code: string; retryAfterMs: number } | null;
  onSend: (type: string, data?: unknown) => void;
};

export default function BattleChat({
  message,
  meId,
  userId,
  error,
  onSend,
}: Props) {
  const [open, setOpen] = useState(false);
  const [text, setText] = useState("");
  const [cooldownUntil, setCooldownUntil] = useState(0);
  const [now, setNow] = useState(Date.now());
  const [pending, setPending] = useState(false);
  const isMe = userId === meId;

  useEffect(() => {
    if (!isMe || !message || message.userId !== meId) return;
    setPending(false);
    setText("");
  }, [isMe, meId, message]);

  useEffect(() => {
    if (!error) return;
    setPending(false);
    if (error.code === "cooldown" && error.retryAfterMs > 0) {
      setCooldownUntil(Date.now() + error.retryAfterMs);
    }
  }, [error]);

  useEffect(() => {
    if (!pending) return;
    const timeout = setTimeout(() => setPending(false), 5000);
    return () => clearTimeout(timeout);
  }, [pending]);

  useEffect(() => {
    if (cooldownUntil <= Date.now()) return;
    const interval = setInterval(() => {
      const current = Date.now();
      setNow(current);
      if (cooldownUntil <= current) clearInterval(interval);
    }, 250);
    return () => clearInterval(interval);
  }, [cooldownUntil]);

  const remainingMs = Math.max(0, cooldownUntil - now);
  const errorText =
    error && !(error.code === "cooldown" && remainingMs === 0)
      ? (CHAT_ERROR_TEXT[error.code] ?? error.code)
      : null;

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmed = text.trim();
    if (!trimmed || pending || remainingMs > 0) return;
    if (Array.from(trimmed).length > 64) return;
    setCooldownUntil(Date.now() + CHAT_COOLDOWN_MS);
    setNow(Date.now());
    setPending(true);
    onSend("chat.send", { text: trimmed });
  };

  if (!isMe) return null;

  return (
    <span className={styles.chatControl}>
      <button
        type="button"
        className={styles.chatButton}
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
      >
        Chat
      </button>
      {open && (
        <form className={styles.chatForm} onSubmit={submit}>
          <input
            type="text"
            value={text}
            maxLength={128}
            autoFocus
            aria-label="Message opponent"
            placeholder="Message"
            onChange={(event) =>
              setText(Array.from(event.target.value).slice(0, 64).join(""))
            }
            onKeyDown={(event) => {
              if (event.key === "Escape") setOpen(false);
            }}
          />
          <div className={styles.formFooter}>
            <span>
              {errorText ??
                (remainingMs > 0
                  ? `Wait ${Math.ceil(remainingMs / 1000)}s`
                  : `${Array.from(text).length}/64`)}
            </span>
            <button
              type="submit"
              disabled={!text.trim() || pending || remainingMs > 0}
            >
              Enter
            </button>
          </div>
        </form>
      )}
    </span>
  );
}

export function ChatBubble({ message }: { message: ChatMessage | null }) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (!message) {
      setVisible(false);
      return;
    }
    setVisible(true);
    const timeout = setTimeout(() => setVisible(false), 5000);
    return () => clearTimeout(timeout);
  }, [message]);

  if (!message || !visible) return null;

  return (
    <div className={styles.chatBubble} role="status">
      {message.text}
    </div>
  );
}
