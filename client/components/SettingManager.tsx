import { useState, type FormEvent } from "react";
import { toast } from "react-toastify";

import home from "@/styles/home.module.css";
import LogOutManager from "@/components/LogOutManager";
import MusicControls from "@/components/MusicControls";
import { useAuth } from "@/contexts/auth/useAuth";
import { redeemGiftcode } from "@/api/giftcode";
import { usePool } from "@/api/pool";
import BackgroundButton from "@/components/BackgroundButton";
import { GachaTicket } from "@/components/GachaTicket";

export default function Setting() {
  const [showSetting, setShowSetting] = useState(false);
  const [giftcode, setGiftcode] = useState("");
  const [redeeming, setRedeeming] = useState(false);
  const [redeemedCodes, setRedeemedCodes] = useState<Set<string>>(
    () => new Set(),
  );
  const [redeemRewards, setRedeemRewards] = useState<
    RedeemGiftcodeResponse["rewards"] | null
  >(null);
  const { user, loading, fetchMe } = useAuth();
  const { poolData } = usePool();

  const handleToggleSetting = () => {
    setShowSetting((prev) => !prev);
  };

  const handleRedeem = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const normalizedCode = giftcode.trim().toUpperCase();
    if (redeemedCodes.has(normalizedCode)) {
      toast.error("You have already redeemed this giftcode.", {
        icon: false,
      });
      return;
    }
    setRedeeming(true);
    try {
      const result = await redeemGiftcode(normalizedCode);
      setRedeemedCodes((previous) => new Set(previous).add(normalizedCode));
      setRedeemRewards(result.rewards);
      setGiftcode("");
      fetchMe();
    } catch (error) {
      const reason = error instanceof Error ? error.message : "";
      const messages: Record<string, string> = {
        not_found: "Giftcode not found.",
        expired: "This giftcode has expired.",
        used_up: "This giftcode has reached its use limit.",
        already_redeemed: "You have already redeemed this giftcode.",
        rate_limited: "Too many attempts. Please try again in a minute.",
      };
      toast.error(
        messages[reason] ?? (reason || "Could not redeem this giftcode."),
        { icon: false },
      );
    } finally {
      setRedeeming(false);
    }
  };

  return (
    <div className="position-absolute ">
      {showSetting ? (
        <div>
          <div
            style={{
              zIndex: 3,
            }}
          ></div>
          <div
            className="modal fade show d-flex align-items-center justify-content-center animate-fade-in"
            style={{
              zIndex: 15,
            }}
          >
            <div className="modal-dialog modal-dialog-centered text-dark">
              <div
                className="modal-content shadow-lg border-0"
                style={{ borderRadius: "12px" }}
              >
                <div className="modal-header border-0 pb-0">
                  <h5 className="modal-title w-100 text-center fw-bold">
                    Settings
                  </h5>
                </div>
                <div className="modal-body text-center text-muted py-3 d-flex flex-column gap-2">
                  <MusicControls />
                  <div className="p-2 border border-dark border-3 rounded-0 d-flex justify-content-start align-items-center">
                    <div>
                      Account :{" "}
                      {loading ? (
                        "Loading..."
                      ) : (
                        <span className="text-info">{user?.username}</span>
                      )}
                    </div>{" "}
                  </div>
                  {!loading && user && (
                    <form
                      onSubmit={handleRedeem}
                      className="p-3 border border-dark border-3 text-start"
                    >
                      <label htmlFor="giftcode" className="form-label fw-bold">
                        Giftcode
                      </label>
                      <div className="d-flex gap-2 ">
                        <input
                          id="giftcode"
                          className="form-control text-uppercase border border-secondary border-2"
                          value={giftcode}
                          onChange={(event) =>
                            setGiftcode(event.target.value.trim().toUpperCase())
                          }
                          placeholder="Enter a giftcode"
                          maxLength={64}
                          autoComplete="off"
                        />
                        <button
                          type="submit"
                          className={`${home.optionBtn} flex-shrink-0`}
                          style={{ padding: "8px 12px" }}
                          disabled={
                            redeeming ||
                            !giftcode.trim()
                          }
                        >
                          {redeeming ? "..." : "REDEEM"}
                        </button>
                      </div>
                    </form>
                  )}
                </div>
                <div className="modal-footer border-0 d-flex justify-content-center gap-3 pb-4">
                  <LogOutManager />{" "}
                  <button
                    className={`${home.optionBtn}`}
                    style={{ padding: "8px 12px" }}
                    onClick={handleToggleSetting}
                  >
                    RETURN
                  </button>
                </div>
              </div>
            </div>
            {redeemRewards && (
              <div
                className="position-fixed top-0 start-0 vh-100 vw-100 d-flex align-items-center justify-content-center p-2"
                style={{
                  zIndex: 30,
                  background: "rgba(0, 0, 0, 0.85)",
                }}
                onClick={() => setRedeemRewards(null)}
              >
                <div
                  className="bg-dark text-white border border-warning rounded-0 p-3 p-md-4 text-center"
                  style={{
                    maxWidth: "650px",
                    width: "100%",
                  }}
                  onClick={(event) => event.stopPropagation()}
                >
                  <h3 className="text-warning fw-bold mb-4">Reward</h3>
                  {redeemRewards.tickets > 0 && (
                    <div className="d-flex justify-content-center align-items-center gap-2 mb-3">
                      <GachaTicket />
                      <span className="fs-4 fw-bold">
                        {redeemRewards.tickets} tickets
                      </span>
                    </div>
                  )}
                  <div className="d-flex flex-wrap justify-content-center gap-2 my-3">
                    {[...redeemRewards.skills, ...redeemRewards.clothes].map(
                      (item) => {
                        const prefixMap = [
                          {
                            prefix: "shirt_",
                            folder: "SHIRT",
                            category: "clothes",
                          },
                          {
                            prefix: "acc_",
                            folder: "ACC",
                            category: "clothes",
                          },
                          {
                            prefix: "shoes_",
                            folder: "SHOES",
                            category: "clothes",
                          },
                          { prefix: "s1_", folder: "S1", category: "skills" },
                          { prefix: "s2_", folder: "S2", category: "skills" },
                          { prefix: "s3_", folder: "S3", category: "skills" },
                          { prefix: "ult_", folder: "ULT", category: "skills" },
                        ];
                        const matched = prefixMap.find((entry) =>
                          item.startsWith(entry.prefix),
                        );
                        const category = matched?.category ?? "skills";
                        const detail =
                          category === "clothes"
                            ? poolData?.clothe.find(
                                (clothe) => clothe.clothe_id === item,
                              )
                            : poolData?.skill.find(
                                (skill) => skill.skill_id === item,
                              );

                        return (
                          <div
                            key={item}
                            className="d-flex flex-column align-items-center"
                          >
                            <BackgroundButton
                              imageUrl={`/${category}/${matched?.folder ?? ""}/${item}.png`}
                              buttonName={matched?.folder ?? ""}
                              isDisabled={true}
                              isEquipped={false}
                              onOpen={() => {}}
                              itemRarity={detail?.rarity ?? "common"}
                              Width="80px"
                              Height="80px"
                              bgSize="150%"
                            />
                            <span className="small mt-1">{item}</span>
                          </div>
                        );
                      },
                    )}
                  </div>
                  <button
                    type="button"
                    className={`${home.optionBtn} mt-2`}
                    style={{ padding: "8px 12px" }}
                    onClick={() => setRedeemRewards(null)}
                  >
                    CLOSE
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      ) : (
        <button
          onClick={handleToggleSetting}
          style={{
            position: "fixed",
            bottom: "10px",
            right: "10px",
            zIndex: 4,
            padding: "10px 15px",
            background: "#000",
            color: "#fff",
            borderRadius: "8px",
            cursor: "pointer",
          }}
        >
          Setting
        </button>
      )}
    </div>
  );
}
