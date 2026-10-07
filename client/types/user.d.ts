type User = {
  user_id: string;
  username: string;
};

type GachaRequest = {
  wish: string;
  wish_type: string;
};
type GachaResposne = {
  status: string;
  message: string;
  added_items: sting[];
  remaining_tickets: int;
};

type equipItemRequest = {
  equip_item: string;
};
type equipItemResponse = {
  status: string;
  message: string;
  equipped_item: string | "";
};
