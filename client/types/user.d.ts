type User = {
  user_id: string;
  username: string;
};

type UserInfo = {
  user_id: string;
  username: string;
  tickets: number;
  equipped_skills: [string];
  equipped_clothes: [string];
  pity_skill_leg: number;
  pity_clothe_leg: number;
};

type GachaRequest = {
  wish: string;
  wish_type: string;
};
