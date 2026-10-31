import type { RewardItem } from "@/websocket/battleTypes";
export const skillImg = (id: string) =>
  `/skills/${id.split("_")[0].toUpperCase()}/${id}.png`;

export type SpriteMode = "persist" | "burst";
export type SpriteConfig = { frames: number; ms: number; mode: SpriteMode };

export const EFFECT_SPRITES: Record<string, SpriteConfig> = {
  boost: { frames: 31, ms: 900, mode: "persist" },
  curse: { frames: 31, ms: 1000, mode: "persist" },
  freeze: { frames: 31, ms: 1000, mode: "persist" },
  guard: { frames: 8, ms: 900, mode: "persist" },
  brainrotify: { frames: 8, ms: 1000, mode: "persist" },
  purify: { frames: 12, ms: 1800, mode: "burst" },
};

export const spriteConfig = (type: string): SpriteConfig | null =>
  EFFECT_SPRITES[type] ?? null;

export const effectImg = (type: string) => `/effects/${type}.png`;

export function clotheImg(id: string): string {
  if (id.startsWith("acc_")) return `/clothes/ACC/${id}.png`;
  if (id.startsWith("shirt_")) return `/clothes/SHIRT/${id}.png`;
  return `/clothes/SHOES/${id}.png`;
}

export function itemImg(item: Pick<RewardItem, "id" | "kind">): string {
  return item.kind === "skill" ? skillImg(item.id) : clotheImg(item.id);
}

export { getPlayerClothesAssets as characterUrls } from "@/helpers/getPlayerClothesAssets";
export { getTextColor as rarityColor } from "@/helpers/getTypeColors";

export function formatAura(n: number): string {
  const abs = Math.abs(n);
  if (abs < 10_000) return n.toLocaleString("en-US");
  const units: [number, string][] = [
    [1e15, "Q"],
    [1e12, "T"],
    [1e9, "B"],
    [1e6, "M"],
    [1e3, "K"],
  ];
  for (const [v, s] of units) {
    if (abs >= v) return `${(n / v).toFixed(1).replace(/\.0$/, "")}${s}`;
  }
  return String(n);
}

export const EFFECT_LABEL: Record<string, string> = {
  boost: "Boost",
  curse: "Curse",
  freeze: "Freeze",
  guard: "Guard",
  purify: "Purify",
  brainrotify: "Brainrot",
};
