export const getBorderColor = (rarity: string) => {
  switch (rarity?.toLowerCase()) {
    case "mythical":
      return "3px solid #ff0000";
    case "legendary":
      return "3px solid #ffcc00";
    case "epic":
      return "3px solid #a335ee";
    case "rare":
      return "3px solid #0070dd";
    case "uncommon":
      return "3px solid #1eff00";
    case "common":
    default:
      return "3px solid transparent";
  }
};
