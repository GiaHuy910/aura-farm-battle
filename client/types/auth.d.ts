type logInForm = {
  username: string;
  password: string;
};

type AuthMeResponse = {
  auth: {
    message: string;
    status: string;
  };
  me: UserInfo;
};

type UserInfo = {
  user_id: string;
  username: string;
  tickets: number;
  equipped_skills: string[];
  equipped_clothes: string[];
  pity_skill_leg: number;
  pity_clothe_leg: number;
  base_aura: number;
  bonus_aura: number;
  final_aura: number;
};
