import React from "react";

import { getBorderColor } from "@/helpers/getTypeColors";

type Props = {
  imageUrl: string;
  buttonName: string;
  onOpen: () => void;
  isDisabled: boolean;
  isEquipped: boolean;
  itemRarity?: string | "common";
  Width: string;
  Height: string;
  bgSize: string;
};

const BackgroundButton: React.FC<Props> = ({
  imageUrl,
  buttonName,
  onOpen,
  isDisabled,
  isEquipped,
  itemRarity,
  Width,
  Height,
  bgSize,
}) => {
  const getBackgroundPosition = (btnName: string) => {
    const lowerName = btnName.toLowerCase();
    if (lowerName.includes("acc")) {
      return "top center";
    }
    if (lowerName.includes("shoes")) {
      return "bottom center";
    }
    if (lowerName.includes("shirt")) {
      return "bottom center";
    }
    return "center";
  };
  const buttonStyle: React.CSSProperties = {
    backgroundImage: `url('${imageUrl}')`,
    backgroundSize: bgSize,
    backgroundRepeat: "no-repeat",
    backgroundPosition: getBackgroundPosition(buttonName),
    width: Width,
    height: Height,
    border: getBorderColor(itemRarity ?? "common"),
  };

  const handleClick = () => {
    onOpen();
  };
  return (
    <button
      type="button"
      className={`bg-warning-subtle ${buttonName === "ULT" ? "rounded-5" : "rounded-0"} ${isDisabled} d-flex justify-content-center align-items-center btn overflow-hidden position-relative`}
      style={buttonStyle}
      onClick={handleClick}
      disabled={isDisabled}
    >
      {isEquipped && (
        <div
          style={{ maxWidth: "150px" }}
          className="py-1 px-2 rounded-5 bg-info text-light fw-bold"
        >
          Equipped
        </div>
      )}
    </button>
  );
};

export default BackgroundButton;
