export type EffectType =
  | ""
  | "boost"
  | "curse"
  | "freeze"
  | "guard"
  | "purify"
  | "brainrotify";

export type CardInfo = {
  id: string;
  isUlt: boolean;
  name: string;
  rarity: string;
  mult: number;
  consume: number;
  recover: number;
  effect: string;
  effectDuration: number;
  playable?: boolean;
};

export type ActiveEffect = { type: string; left: number; source: string };

export type FighterPublic = {
  id: string;
  aura: number;
  energy: number;
  effects: ActiveEffect[];
  chosen: boolean;
};

export type FighterSelf = FighterPublic & {
  hand: CardInfo[];
  choice: number | null;
  frozen: boolean;
};

export type BattleView = {
  round: number;
  maxRounds: number;
  order: string[];
  you: FighterSelf | null;
  opponent: FighterPublic | null;
  roundOpen: boolean;
  deadlineAt: number | null;
};

export type GameEvent =
  | {
      kind: "skill_used";
      userId: string;
      skillId: string;
      skill: CardInfo;
      effectType: string;
      mult: number;
      auraBefore: number;
      auraAfter: number;
      energyBefore: number;
      energyAfter: number;
    }
  | { kind: "skipped"; userId: string; reason: string }
  | { kind: "auto_picked"; userId: string; index: number }
  | { kind: "skill_replaced"; userId: string; from: string; to: string }
  | {
      kind: "effect_applied";
      userId: string;
      effectType: string;
      rounds: number;
      source: string;
    }
  | { kind: "effect_blocked"; userId: string; effectType: string; by: string }
  | { kind: "effect_cleansed"; userId: string; effectType: string }
  | { kind: "effect_expired"; userId: string; effectType: string };

export type RoundRecord = { round: number; events: GameEvent[] };

export type FinishedInfo = {
  winnerId: string | null;
  loserId: string | null;
  reason: string;
  players: FighterPublic[];
};

export type RewardItem = {
  id: string;
  kind: "skill" | "clothe";
  name: string;
  rarity: string;
  isUlt?: boolean;
  effect?: string;
  slot?: "acc" | "shirt" | "shoes";
  auraBonus?: number;
};

export type RewardOffer = {
  matchId: string;
  winnerId: string;
  loserId: string;
  tickets: number;
  seconds: number;
  skills: RewardItem[];
  clothes: RewardItem[];
  deadlineAt: number;
};

export type TakenItem = {
  item: RewardItem | null;
  replacedWith: string | null;
};

export type RewardResult = {
  matchId: string;
  winnerId: string;
  loserId: string;
  tickets: number;
  auto: boolean;
  taken: TakenItem[];
  loserAura: number;
};

export type GamePhase = "battle" | "reward" | "ended";

export type GameState = {
  phase: GamePhase;
  battle: BattleView | null;
  finished: FinishedInfo | null;
  offer: RewardOffer | null;
  result: RewardResult | null;
  picked: { skill: boolean; clothe: boolean };
  rematch: string[];
  lastRound: { seq: number; round: number; events: GameEvent[] } | null;
  log: RoundRecord[];
};
