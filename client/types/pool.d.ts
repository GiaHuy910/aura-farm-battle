type PoolResponse = {
  clothe: string[Clothe];
  skill: string[Skill];
};
type Clothe = {
  clothe_id: string;
  clothe_name: string;
  rarity: string;
};
type Skill = {
  skill_id: string;
  skill_name: string;
  rarity: string;
};
