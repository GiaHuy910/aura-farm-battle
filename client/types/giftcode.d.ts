type RedeemGiftcodeResponse = {
  status: "success";
  rewards: {
    tickets: number;
    skills: string[];
    clothes: string[];
  };
};
