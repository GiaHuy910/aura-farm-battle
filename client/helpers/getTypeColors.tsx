export const getBorderColor = (rarity: string) => {
  switch (rarity?.toLowerCase()) {
    case "mythical":
      return "5px solid #ff0000";
    case "legendary":
      return "5px solid #ffcc00";
    case "epic":
      return "5px solid #a335ee";
    case "rare":
      return "5px solid #0070dd";
    case "uncommon":
      return "5px solid #1eff00";
    case "common":
      return "5px solid #808080";
    default:
      return "5px solid transparent";
  }
};
export const getTextColor = (rarity: string) => {
  switch (rarity?.toLowerCase()) {
    case "mythical":
      return "#ff0000";
    case "legendary":
      return "#ffcc00";
    case "epic":
      return "#a335ee";
    case "rare":
      return "#0070dd";
    case "uncommon":
      return "#1eff00";
    case "common":
      return "#808080";
    default:
      return "#808080";
  }
};
