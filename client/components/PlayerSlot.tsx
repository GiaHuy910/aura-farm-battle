"use client";

import UserCharacter from "@/components/UserCharacter";
import type { Player } from "@/websocket/useRoomSocket";
import { getPlayerClothesAssets } from "@/helpers/getPlayerClothesAssets";

type Props = {
  player: Player | null;
  label: string;
  meId?: string;
};
export default function PlayerSlot({ player, label, meId }: Props) {
  if (!player) {
    return (
      <div
        className="d-flex flex-column align-items-center justify-content-center text-center text-muted rounded p-4"
        style={{ minHeight: 360, border: "3px dashed #888" }}
      >
        <small className="text-uppercase">{label}</small>
        <h5 className="mt-3">Waiting For Player...</h5>
      </div>
    );
  }

  const { base_user_url, acc_user_url, shirt_user_url, shoes_user_url } =
    getPlayerClothesAssets(player?.equipped_clothes);

  return (
    <div
      className="d-flex flex-column align-items-center text-center"
      style={{ opacity: player.online ? 1 : 0.45, transition: "opacity 0.3s" }}
    >
      <small className="text-uppercase text-muted mb-2">{label}</small>

      <UserCharacter
        base_user_url={base_user_url}
        acc_user_url={acc_user_url}
        shirt_user_url={shirt_user_url}
        shoes_user_url={shoes_user_url}
      />

      <h5 className="mt-3 mb-1">
        {player.name}
        {player.id === meId && (
          <span className="badge bg-primary ms-2">You</span>
        )}
      </h5>
      <span
        className={`badge ${player.online ? "bg-success" : "bg-secondary"}`}
      >
        {player.online ? "Online" : "Lost Connection..."}
      </span>
      <div className="mt-2">Aura: {player.total_aura}</div>
    </div>
  );
}
