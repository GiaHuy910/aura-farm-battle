type PoolResponse = {
  clothe: Clothe[];
  skill: Skill[];
};
type Clothe = {
  clothe_id: string;
  clothe_name: string;
  rarity: string;
  aura_bonus: number;
};
type Skill = {
  skill_id: string;
  skill_name: string;
  rarity: string;
  aura_multiplier: double;
  energy_consumption: number;
  energy_recovery: number;
  effect: Effect;
};
type Effect = {
  effect_duration: number;
  effect_type: string;
};
