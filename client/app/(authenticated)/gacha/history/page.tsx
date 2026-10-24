"use client";
import { useRouter } from "next/navigation";
import { useState, useEffect } from "react";

import home from "@/styles/home.module.css";
import page from "@/styles/page.module.css";
import { getGachaHistory } from "@/api/gachaHistory";
import { capitalizeFirstLetter } from "@/helpers/capitalizeFirstLetter";
import { usePool } from "@/api/pool";
import { getTextColor } from "@/helpers/getTypeColors";

const banners = [
  {
    value: "clothe",
  },
  {
    value: "skill",
  },
] as const;
const bannerDefaultType = banners[0].value;
const baseLimit = 9;
type BannerType = (typeof banners)[number]["value"];

export default function GachaHistoryPage() {
  const router = useRouter();
  const { poolData } = usePool();
  const [hasData, setHasData] = useState(false);
  const [currentBanner, setCurrentBanner] =
    useState<BannerType>(bannerDefaultType);
  const [pageIndex, setPageIndex] = useState<number>(0);
  const buildRequest = (cursor = ""): GachaHistoryRequest => ({
    limit: baseLimit,
    cursor,
    item_type: currentBanner,
  });
  const [historyData, setHistoryData] = useState<GachaHistoryResponse[]>([]);

  const getItemName = (itemType: string, itemId: string) => {
    if (!poolData) return { name: "Loading....", rarity: "rarity" };
    const typeKey = itemType.toLowerCase() as keyof PoolResponse;

    if (typeKey === "clothe" && poolData.clothe) {
      const found = poolData.clothe.find((c) => c.clothe_id === itemId);
      return found
        ? { name: found.clothe_name, rarity: found.rarity }
        : { name: "Not found Item", rarity: "-" };
    }
    if (typeKey === "skill" && poolData.skill) {
      const found = poolData.skill.find((s) => s.skill_id === itemId);
      return found
        ? { name: found.skill_name, rarity: found.rarity }
        : { name: "Not found Item", rarity: "-" };
    }
    return { name: "Undefined", rarity: "-" };
  };
  const handleSetBanner = (value: BannerType) => {
    setCurrentBanner(value);
  };

  useEffect(() => {
    const fetchFirstPage = async () => {
      setPageIndex(0);
      setHasData(false);
      setHistoryData([]);
      const res = await getGachaHistory(buildRequest());
      setHistoryData([res]);
      setHasData(true);
    };
    fetchFirstPage();
  }, [currentBanner]);

  const handleNextPage = async () => {
    if (pageIndex < historyData.length - 1) {
      setPageIndex((prev) => prev + 1);
      return;
    }

    const currentNextCursor = historyData[pageIndex]?.pagination.nextCursor;
    if (!currentNextCursor) return;
    const payload = buildRequest(currentNextCursor);
    const res = await getGachaHistory(payload);

    setHistoryData((prev) => [...prev, res]);
    setPageIndex((prev) => prev + 1);
  };
  const handlePrevPage = () => {
    if (pageIndex > 0) {
      setPageIndex((prev) => prev - 1);
    }
  };
  const handleReturn = () => {
    router.push("/gacha");
  };

  const currentPageData = historyData[pageIndex]?.gacha_history_list || [];
  return (
    <div
      className={`${page.roomsPage} position-relative my-5 px-lg-5 py-3 d-flex justify-content-center align-items-center flex-column container w-100 h-100`}
      style={{
        border: "10px solid rgba(178, 140, 15, 0.69)",
        background: "#eae2c7",
        padding: "10px",
      }}
    >
      <div className="header w-100 flex-column d-flex justify-content-start ">
        <div>
          <h2 className="text-dark">GACHA HISTORY</h2>
        </div>
      </div>
      <div className="w-100 h-100 d-flex flex-column justify-content-center align-items-center">
        <div
          style={{ height: "15%" }}
          className="w-100 d-flex justify-content-start align-items-center flex-wrap"
        >
          <div
            style={{ border: "3px solid #3a3d3f" }}
            className="position-relative w-100 h-75 d-flex justify-content-center align-items-center bg-warning rounded-5"
          >
            <div
              style={{ width: "30%" }}
              className="rounded-5 h-100 bg-warning d-flex justify-content-center align-items-center"
            >
              GACHA
            </div>
            <div style={{ width: "70%" }} className="h-100 dropdown">
              <button
                type="button"
                data-bs-toggle="dropdown"
                aria-expanded="false"
                className="w-100 h-100 dropdown-toggle border-2 border-light btn btn-secondary rounded-5 d-flex justify-content-between align-items-center"
              >
                <span
                  style={{ visibility: "hidden" }}
                  aria-hidden="true"
                  className="dropdown-toggle"
                ></span>
                <div className="position-absolute w-100">
                  {capitalizeFirstLetter(currentBanner)}
                </div>
              </button>
              <ul
                style={{
                  background: "#eae2c7",
                  border: "3px solid white",
                }}
                className="dropdown-menu rounded-0 dropdown-menu-end w-100 shadow mt-1"
              >
                {banners.map((banner) => (
                  <li key={banner.value}>
                    <button
                      type="button"
                      className={`dropdown-item ${currentBanner === banner.value ? "bg-warning" : ""}`}
                      onClick={() => handleSetBanner(banner.value)}
                    >
                      {banner.value.toUpperCase()}
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
        <div className="position-relative pt-2 w-100 h-100 d-flex flex-column justify-content-start align-items-center">
          <table className="table table-bordered custom-table">
            <thead className="table-warning">
              <tr>
                <th scope="col" className="col-5">
                  Name
                </th>
                <th scope="col" className="col-5">
                  Time
                </th>
              </tr>
            </thead>
            <tbody className="table-group-divider">
              {currentPageData.length > 0 ? (
                currentPageData.map((historyItem) => {
                  const item = getItemName(
                    historyItem.item_type,
                    historyItem.item_id,
                  );
                  return (
                    <tr key={historyItem._id}>
                      <td
                        scope="row"
                        style={{
                          color: getTextColor(item?.rarity),
                        }}
                      >
                        {capitalizeFirstLetter(item?.name)}
                      </td>
                      <td>
                        {new Date(historyItem.createdAt).toLocaleString()}
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={3} className="text-center text-muted py-3">
                    {hasData ? "End." : "No Data"}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
          <div
            style={{
              top: "450px",
            }}
            className="position-absolute d-flex gap-5 justify-content-center align-items-center "
          >
            <button
              className="btn btn-secondary rounded-0"
              onClick={handlePrevPage}
            >
              Prev
            </button>
            {pageIndex + 1}
            <button
              className="btn btn-secondary rounded-0"
              onClick={handleNextPage}
            >
              Next
            </button>
          </div>
        </div>
        <div className="w-100 d-flex justify-content-start align-items-center">
          <button
            onClick={handleReturn}
            className={`${home.optionBtn} ms-2 mb-1 d-flex justify-content-center align-items-center text-decoration-none`}
            style={{
              width: "130px",
              height: "45px",
              background: "red",
            }}
            role="button"
          >
            RETURN
          </button>
        </div>
      </div>
    </div>
  );
}
