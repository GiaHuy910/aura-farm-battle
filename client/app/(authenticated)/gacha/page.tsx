"use client";

import { useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";

import page from "@/styles/page.module.css";
import home from "@/styles/home.module.css";
import { getBorderColor } from "@/helpers/getTypeColors";
import { useAuth } from "@/contexts/auth/useAuth";
import { usePool } from "@/api/pool";
import { sendGachaRequest } from "@/api/user";
import { GachaTicket } from "@/components/GachaTicket";
import BackgroundButton from "@/components/BackgroundButton";
const banner_1 = "/gacha/background-gacha-3.jpg";
const banner_2 = "/gacha/background-gacha-2.jpg";
const banner_1_name = "Clothes" as const;
const banner_2_name = "Skills" as const;

const gacha_1_button = "1";
const gacha_2_button = "10";

type BannerType = typeof banner_1_name | typeof banner_2_name;

export default function GachaBannerPage() {
  const { user, fetchMe } = useAuth();
  const { poolData } = usePool();
  const router = useRouter();

  const [isAnimating, setIsAnimating] = useState(false);
  const toggleAnimating = () => {
    setIsAnimating((prev) => !prev);
  };
  const [showResult, setShowResult] = useState(false);
  const toggleResult = () => {
    setShowResult((prev) => !prev);
  };
  const [gachaResultItems, setGachaResultItems] = useState<string[]>([]);

  const [showPaymentBoard, setShowPaymentBoard] = useState(false);
  const toggleBoard = () => {
    setShowPaymentBoard((prev) => !prev);
  };

  const [selectedBanner, setSelectedBanner] =
    useState<BannerType>(banner_1_name);
  const handleSetSelectedBanner = (e: React.MouseEvent<HTMLButtonElement>) => {
    const value = e.currentTarget.value;
    // reason to force this type cuz typescript would not believe me
    setSelectedBanner(value as BannerType);
  };

  const validateSufficient = (amount: any) => {
    if ((user?.tickets ?? 0) >= amount) return true;
    else return false;
  };
  const handleGacha = async (e: React.MouseEvent<HTMLButtonElement>) => {
    const gachaAmount = e.currentTarget.value;
    if (!validateSufficient(gachaAmount)) {
      toggleBoard();
      return;
    }

    const amount = "x" + gachaAmount;
    const sendGachaForm: GachaRequest = {
      wish: amount,
      wish_type: selectedBanner.toLowerCase(),
    };

    const resultItem: GachaResposne = await sendGachaRequest(sendGachaForm);

    if (resultItem && resultItem.added_items) {
      setGachaResultItems(resultItem.added_items);
      toggleAnimating();

      fetchMe();

      setTimeout(() => {
        toggleAnimating();
        toggleResult();
      }, 3000);
    }
  };
  const handlePayment = () => {
    toggleBoard();
  };
  const handleReturn = () => {
    router.push("/");
  };
  const handleRedirectGachaHistory = () => {
    router.push("/gacha/history");
  };

  return (
    <div
      className={`${page.roomsPage} backgroundGachaContainer position-relative my-5 d-flex justify-content-center align-items-center flex-column gap-3 container w-100 h-100`}
      style={{
        border: "10px solid rgba(178, 140, 15, 0.69)",
        // backgroundColor: "rgba(255, 255, 255, 0.23)",
        padding: "10px",
      }}
    >
      <div className="header w-100 d-flex">
        <button
          className={`btn btn-warning btn-lg ${selectedBanner === banner_1_name ? "disabled" : ""} flex-fill rounded-0 border border-light`}
          value={banner_1_name}
          onClick={handleSetSelectedBanner}
        >
          {banner_1_name}
        </button>
        <button
          className={`btn btn-warning btn-lg ${selectedBanner === banner_2_name ? "disabled" : ""} flex-fill rounded-0 border border-light`}
          value={banner_2_name}
          onClick={handleSetSelectedBanner}
        >
          {banner_2_name}
        </button>
      </div>
      <div className="w-100 d-flex justify-content-end align-items-center">
        <div
          style={{
            backgroundColor: "rgba(117, 112, 112, 0.82)",
            backdropFilter: "blur(10px)",
          }}
          className="btn rounded-5 d-flex justify-content-center align-items-center gap-4"
        >
          <GachaTicket />
          {user?.tickets ?? 0}
          <button className="btn btn-light rounded-5" onClick={handlePayment}>
            +
          </button>
        </div>
      </div>
      {/* Animation part */}
      {isAnimating && (
        <div
          className="position-absolute vh-100 vw-100 d-flex align-items-center justify-content-center"
          style={{
            zIndex: 3,
            background: "rgba(0, 0, 0, 0.8)",
          }}
        >
          {/* thay class hoac lottie vao day */}
          <div className="text-warning fw-bold fs-1 dynamic-pulse-effect">
            Bảng gacha tạm thời thôi nha
          </div>
        </div>
      )}
      {/* AddedItem Part */}
      {showResult && (
        <div
          className="position-absolute vh-100 vw-100 d-flex align-items-center justify-content-center"
          style={{
            zIndex: 4,
            background: "rgba(0, 0, 0, 0.85)",
            cursor: "pointer",
          }}
          onClick={toggleResult}
        >
          <div
            className="bg-dark text-white border border-warning rounded-0 p-4 text-center"
            style={{ maxWidth: "650px", width: "90%" }}
          >
            <h3 className="text-warning fw-bold mb-4">Reward</h3>
            <div className="d-flex flex-wrap justify-content-center gap-2 my-3">
              {gachaResultItems.map((item, index) => {
                const folder =
                  selectedBanner === banner_1_name ? "clothes" : "skills";
                const prefixMap = [
                  { prefix: "shirt_", folder: "SHIRT" },
                  { prefix: "acc_", folder: "ACC" },
                  { prefix: "shoes_", folder: "SHOES" },
                  { prefix: "s1_", folder: "S1" },
                  { prefix: "s2_", folder: "S2" },
                  { prefix: "s3_", folder: "S3" },
                  { prefix: "ult_", folder: "ULT" },
                ];
                const matched = prefixMap.find((p) =>
                  item.startsWith(p.prefix),
                );
                const typeFolder = matched ? matched.folder : "";
                const detailedItem =
                  poolData?.clothe.find((c: Clothe) => c.clothe_id === item) ||
                  poolData?.skill.find((s: Skill) => s.skill_id === item);
                const itemRarity = detailedItem?.rarity || "common";
                return (
                  <div
                    key={index}
                    className="d-flex flex-column align-items-center rounded popInItem"
                    style={{
                      animationDelay: `${index * 0.1}s`,
                      transition: "transform 0.2s",
                    }}
                  >
                    <BackgroundButton
                      imageUrl={`/${folder}/${typeFolder}/${item}.png`}
                      buttonName={typeFolder}
                      isDisabled={true}
                      isEquipped={false}
                      onOpen={() => {}}
                      itemRarity={itemRarity}
                      Width="80px"
                      Height="80px"
                      bgSize="150%"
                    />
                  </div>
                );
              })}
            </div>
            <div>Click anywhere to close</div>
          </div>
        </div>
      )}
      {/* PaymentBoard Part */}
      {showPaymentBoard && (
        <div
          className="position-absolute vh-100 vw-100"
          style={{
            zIndex: 1,
          }}
        ></div>
      )}
      {showPaymentBoard && (
        <div
          className="position-absolute bg-white border rounded-3 shadow p-3 w-100 d-flex align-items-center justify-content-center flex-column gap-3 text-center"
          style={{
            maxWidth: "400px",
            height: "auto",
            minHeight: "150px",
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
            zIndex: 2,
          }}
        >
          <div className="fw-bold fs-5 text-danger">BBno money?</div>
          <div className="d-flex gap-5 ">
            <button
              onClick={toggleBoard}
              className="btn btn-dark text-info text-decoration-underline"
            >
              NO(payment)
            </button>
            <button
              onClick={toggleBoard}
              className="btn"
              style={{ background: "pink" }}
            >
              yes
            </button>
          </div>
        </div>
      )}
      {/* Banner Part */}
      {selectedBanner === banner_1_name && (
        <Image
          src={banner_1}
          alt={banner_1_name}
          className={`popIn`}
          style={{
            border: "5px solid white",
          }}
          width={700}
          height={380}
          priority
        />
      )}
      {selectedBanner === banner_2_name && (
        <Image
          src={banner_2}
          alt={banner_2_name}
          className={`popIn border border-light`}
          width={700}
          height={380}
          priority
        />
      )}
      <div className="footer w-100 d-flex justify-content-between flex-wrap gap-3">
        <div className="d-flex justify-content-start align-items-center gap-1">
          <button
            className={`${home.optionBtn} me-5`}
            style={{
              padding: "10px 10px",
              color: "white",
              background: "red",
            }}
            onClick={handleReturn}
          >
            RETURN
          </button>
          <button
            onClick={handleRedirectGachaHistory}
            className="btn btn-warning rounded-5"
          >
            History
          </button>
        </div>
        <div className="d-flex justify-content-end gap-3">
          <button
            className="btn btn-light btn-lg rounded-5"
            style={{ minWidth: "80px" }}
            value={gacha_1_button}
            onClick={handleGacha}
          >
            <div className="d-flex justify-content-center align-items-center">
              <GachaTicket />x{gacha_1_button}
            </div>
          </button>
          <button
            className="btn btn-light btn-lg rounded-5"
            style={{ minWidth: "80px" }}
            value={gacha_2_button}
            onClick={handleGacha}
          >
            <div className="d-flex justify-content-center align-items-center">
              <GachaTicket />x{gacha_2_button}
            </div>
          </button>
        </div>
      </div>
    </div>
  );
}
