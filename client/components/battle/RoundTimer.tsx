"use client";

import { useEffect, useState } from "react";

export function useCountdown(deadlineAt: number | null): number | null {
  const [left, setLeft] = useState<number | null>(null);
  useEffect(() => {
    if (deadlineAt === null) {
      setLeft(null);
      return;
    }
    const tick = () =>
      setLeft(Math.max(0, Math.ceil((deadlineAt - Date.now()) / 1000)));
    tick();
    const t = setInterval(tick, 250);
    return () => clearInterval(t);
  }, [deadlineAt]);
  return left;
}

export default function RoundTimer({
  deadlineAt,
  total,
}: {
  deadlineAt: number | null;
  total: number;
}) {
  const left = useCountdown(deadlineAt);
  if (left === null) return <span className="badge bg-secondary">…</span>;
  const urgent = left <= 5;
  return (
    <div style={{ width: 120 }}>
      <div className={`text-center fw-bold ${urgent ? "text-danger" : ""}`}>
        {left}s
      </div>
      <div className="progress" style={{ height: 6 }}>
        <div
          className={`progress-bar ${urgent ? "bg-danger" : "bg-success"}`}
          style={{
            width: `${Math.min(100, (left / total) * 100)}%`,
            transition: "width 0.25s linear",
          }}
        />
      </div>
    </div>
  );
}
