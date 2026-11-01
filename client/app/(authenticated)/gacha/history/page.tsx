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
  const hasNextPage =
    pageIndex < historyData.length - 1 ||
    !!historyData[pageIndex]?.pagination.nextCursor;
  return (
    <main className={page.gachaHistoryFrame}>
      <header className="header w-100 flex-shrink-0">
        <h2 className="text-dark">GACHA HISTORY</h2>
      </header>
      <div className={`${page.gachaHistoryFilter} d-flex`}>
        {banners.map((banner) => {
          const label = banner.value === "clothe" ? "Clothes" : "Skills";
          return (
            <button
              key={banner.value}
              type="button"
              className={`btn btn-warning btn-lg ${currentBanner === banner.value ? "disabled" : ""} flex-fill rounded-0 border border-light`}
              onClick={() => handleSetBanner(banner.value)}
            >
              {label}
            </button>
          );
        })}
      </div>
      <section className={page.gachaHistoryContent}>
        <div className={page.gachaHistoryTableWrap}>
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
        </div>
        <nav
          className={page.gachaHistoryPagination}
          aria-label="Gacha history pages"
        >
          <button
            type="button"
            className="btn btn-secondary rounded-0"
            onClick={handlePrevPage}
            disabled={pageIndex === 0}
          >
            Prev
          </button>
          <span className="small" aria-live="polite">
            Page {pageIndex + 1}
          </span>
          <button
            type="button"
            className="btn btn-secondary rounded-0"
            onClick={handleNextPage}
            disabled={!hasNextPage}
          >
            Next
          </button>
        </nav>
      </section>
      <footer className="w-100 d-flex justify-content-start align-items-center flex-shrink-0">
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
      </footer>
    </main>
  );
}
