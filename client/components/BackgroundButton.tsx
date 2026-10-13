import React from "react";

import { getBorderColor } from "@/helpers/getBorderColor";

type Props = {
  imageUrl: string;
  buttonName: string;
  onOpen: () => void;
  isDisabled: boolean;
  isEquipped: boolean;
  itemRarity: string | "common";
};

const BackgroundButton: React.FC<Props> = ({
  imageUrl,
  buttonName,
  onOpen,
  isDisabled,
  isEquipped,
  itemRarity,
}) => {
  const buttonStyle: React.CSSProperties = {
    backgroundImage: `url('${imageUrl}')`,
    backgroundSize: "cover",
    backgroundPosition: "center",
    width: buttonName === "ULT" ? "250px" : "150px",
    height: buttonName === "ULT" ? "80px" : "60px",
    border: getBorderColor(itemRarity),
    boxShadow:
      itemRarity !== "common"
        ? `0 0 15px ${getBorderColor(itemRarity).split(" ")[2]}`
        : "none",
  };

  const handleClick = () => {
    onOpen();
  };
  return (
    <button
      type="button"
      className={`${buttonName === "ULT" ? "rounded-5" : "rounded-0"} ${isDisabled} d-flex justify-content-center align-items-center btn overflow-hidden position-relative`}
      style={buttonStyle}
      onClick={handleClick}
      disabled={isDisabled}
    >
      <div
        style={{ maxWidth: "150px" }}
        className="py-1 px-2 rounded-5 bg-info text-light fw-bold"
      >
        {isEquipped ? "Equipped" : buttonName}
      </div>
    </button>
  );
};

export default BackgroundButton;
