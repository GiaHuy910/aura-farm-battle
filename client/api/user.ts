const baseApi = `http://localhost:3001/user`;

export const sendGachaRequest = async (body: GachaRequest) => {
  const response = await fetch(`${baseApi}/gacha`, {
    credentials: "include",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.auth.message || "Unauthorized");
  }
  return data;
};
export const getUserOwnedItems = async () => {
  const response = await fetch(`${baseApi}/owned-items`, {
    credentials: "include",
    method: "GET",
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.auth.message || "Unauthorized");
  }
  return data;
};
export const equipUserItem = async (equipItem: equipItemRequest) => {
  const response = await fetch(`${baseApi}/equip-item`, {
    credentials: "include",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(equipItem),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.auth.message || "Unauthorized");
  }
  return data;
};
