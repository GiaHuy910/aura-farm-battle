type GachaHistory = {
  _id: string;
  user_id: string;
  item_id: string;
  item_type: string;
  createdAt: string;
};
type Pagination = {
  limit: number;
  nextCursor: string;
};
type GachaHistoryResponse = {
  gacha_history_list: GachaHistory[];
  pagination: Pagination;
};
type GachaHistoryRequest = {
  limit: number;
  cursor: string;
  item_type: string;
};
