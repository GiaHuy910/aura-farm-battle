const BASE_CHARACTER_URL = "/clothes/base-character.png";
const DEFAULT_CLOTHES = ["acc_1", "shirt_1", "shoes_1"];

export function getPlayerClothesAssets(equippedClothes: string[] = []) {
  const [acc, shirt, shoes] = DEFAULT_CLOTHES.map(
    (def, i) => equippedClothes[i] || def,
  );

  return {
    base_user_url: BASE_CHARACTER_URL,
    acc_user_url: `/clothes/ACC/${acc}.png`,
    shirt_user_url: `/clothes/SHIRT/${shirt}.png`,
    shoes_user_url: `/clothes/SHOES/${shoes}.png`,
  };
}
