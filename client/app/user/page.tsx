"use client";

import { useState } from "react";

import UserCharacter from "@/components/UserCharacter";
import BackgroundButton from "@/components/BackgroundButton";
import { useAuth } from "@/contexts/auth/useAuth";
import page from "../../styles/page.module.css";

const skill_1 = "/skills/na/na_1.png";
const skill_1_name = "NA" as const;
const skill_2 = "/skills/s1/s1_1.png";
const skill_2_name = "S1" as const;
const skill_3 = "/skills/s2/s2_1.png";
const skill_3_name = "S2" as const;
const skill_4 = "/skills/ult/ult_1.png";
const skill_4_name = "ULT" as const;

const SKILL_IMAGES: Record<string, string> = {
  na_1: skill_1,
  s1_1: skill_2,
  s2_1: skill_3,
  ult_1: skill_4,
};

const clothe_1_name = "ACC" as const;
const clothe_2_name = "SHIRT" as const;
const clothe_3_name = "SHOES" as const;

type SkillType =
  | typeof skill_1_name
  | typeof skill_2_name
  | typeof skill_3_name
  | typeof skill_4_name;
type ClotheType =
  | typeof clothe_1_name
  | typeof clothe_2_name
  | typeof clothe_3_name;

export default function UserPage() {
  const { user } = useAuth();

  const [showSkills, setShowSkills] = useState(false);
  const [ownedSkills, setOwnedSkills] = useState<string[]>([
    "na_1",
    "s1_1",
    "s2_1",
    "ult_1",
  ]);
  // rememebr to test more ownedskills
  const [selectedSkillType, setSelectedSkillType] = useState<SkillType>("NA");
  const handleSetSelectedSkillType = (
    e: React.MouseEvent<HTMLButtonElement>,
  ) => {
    const value = e.currentTarget.value;
    // reason to force this type cuz typescript would not believe me
    setSelectedSkillType(value as SkillType);
  };
  const handleShowSkills = () => {
    setShowSkills((prev) => !prev);
    setShowClothes(false);
  };
  const handleCloseSkills = () => {
    setShowSkills((prev) => !prev);
  };

  const [showClothes, setShowClothes] = useState(false);
  const [ownedClothes, setOwnedClothes] = useState<string[]>([
    "acc_1",
    "shirt_1",
    "shoes_1",
  ]);
  const [selectedClotheType, setSelectedClotheType] =
    useState<ClotheType>("ACC");
  const handleSetSelectedClotheType = (
    e: React.MouseEvent<HTMLButtonElement>,
  ) => {
    const value = e.currentTarget.value;
    // reason to force this type cuz typescript would not believe me
    setSelectedClotheType(value as ClotheType);
  };
  const handleShowClothes = () => {
    setShowClothes((prev) => !prev);
    setShowSkills(false);
  };
  const handleCloseClothes = () => {
    setShowClothes(false);
  };
  const handleSelected = (id: string) => {};
  return (
    <div
      className={`${page.roomsPage} container h-100 position-relative overflow-hidden`}
      style={{ border: "5px solid darkgoldenrod", background: "transparent" }}
    >
      <div
        className={`position-absolute custom-dropdown-left ${showClothes ? "open" : ""}`}
      >
        <div
          className="header d-flex justify-content-between flex-wrap"
          style={{ border: "3px solid white" }}
        >
          <button
            value={clothe_1_name}
            className={`btn btn-info ${selectedClotheType === clothe_1_name ? "disabled" : ""} rounded-0 flex-fill border border-light`}
            onClick={handleSetSelectedClotheType}
          >
            {clothe_1_name}
          </button>
          <button
            value={clothe_2_name}
            className={`btn btn-info ${selectedClotheType === clothe_2_name ? "disabled" : ""} rounded-0 flex-fill border border-light`}
            onClick={handleSetSelectedClotheType}
          >
            {clothe_2_name}
          </button>
          <button
            value={clothe_3_name}
            className={`btn btn-info ${selectedClotheType === clothe_3_name ? "disabled" : ""} rounded-0 flex-fill border border-light`}
            onClick={handleSetSelectedClotheType}
          >
            {clothe_3_name}
          </button>
        </div>
        <div>
          <button className="close-btn-left" onClick={handleCloseClothes}>
            &times;
          </button>
          <div className="d-flex justify-content-start h-100">
            <div className="d-flex flex-column h-100">
              {ownedClothes?.map((clothe_name) => {
                const currentImage = SKILL_IMAGES[clothe_name];
                const isMatch =
                  clothe_name.split("_")[0].toUpperCase() ===
                  selectedClotheType;
                return (
                  isMatch && (
                    <div className="dropdown-content" key={clothe_name}>
                      <BackgroundButton
                        imageUrl={currentImage}
                        buttonName={clothe_name}
                        onOpen={() => handleSelected(clothe_name)}
                      />
                    </div>
                  )
                );
              })}
            </div>
          </div>
        </div>
      </div>
      <div className="row h-100">
        <div
          style={{ border: "5px solid darkgoldenrod" }}
          className="col-md-6 d-flex flex-column align-items-center justify-content-center"
        >
          <div className="w-100 d-flex flex-column align-items-center justify-content-center">
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_1}
                buttonName={skill_1_name}
                onOpen={handleShowSkills}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_2}
                buttonName={skill_2_name}
                onOpen={handleShowSkills}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_3}
                buttonName={skill_3_name}
                onOpen={handleShowSkills}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_4}
                buttonName={skill_4_name}
                onOpen={handleShowSkills}
              />
            </div>
          </div>
        </div>

        <div
          style={{ border: "5px solid darkgoldenrod" }}
          className="col-md-6 d-flex flex-column align-items-center justify-content-center"
        >
          <div className="w-100 d-flex flex-column align-items-center justify-content-center">
            <div className="component-item">
              <UserCharacter />
            </div>
            <div className="component-item">
              <button
                className={`${page.optionBtn}`}
                onClick={handleShowClothes}
              >
                Customize
              </button>
            </div>
          </div>
        </div>
      </div>
      <div
        className={`position-absolute custom-dropdown-right ${showSkills ? "open" : ""}`}
      >
        <div
          className="header d-flex justify-content-between flex-wrap"
          style={{ border: "3px solid light" }}
        >
          <button
            value={skill_1_name}
            onClick={handleSetSelectedSkillType}
            className={`btn btn-info ${selectedSkillType === skill_1_name ? "disabled" : ""} rounded-0 flex-fill border border-light`}
          >
            {skill_1_name}
          </button>
          <button
            value={skill_2_name}
            onClick={handleSetSelectedSkillType}
            className={`btn btn-info ${selectedSkillType === skill_2_name ? "disabled" : ""} rounded-0 flex-fill border border-light`}
          >
            {skill_2_name}
          </button>
          <button
            value={skill_3_name}
            onClick={handleSetSelectedSkillType}
            className={`btn btn-info ${selectedSkillType === skill_3_name ? "disabled" : ""} rounded-0 flex-fill border border-light`}
          >
            {skill_3_name}
          </button>
          <button
            value={skill_4_name}
            onClick={handleSetSelectedSkillType}
            className={`btn btn-info ${selectedSkillType === skill_4_name ? "disabled" : ""} rounded-0 flex-fill border border-light`}
          >
            {skill_4_name}
          </button>
        </div>
        <div>
          <button className="close-btn-right" onClick={handleCloseSkills}>
            &times;
          </button>
          <div className="d-flex justify-content-end h-100">
            <div className="d-flex flex-column h-100">
              {ownedSkills?.map((skill_name) => {
                const currentImage = SKILL_IMAGES[skill_name];
                const isMatch =
                  skill_name.split("_")[0].toUpperCase() === selectedSkillType;
                return (
                  isMatch && (
                    <div className="dropdown-content" key={skill_name}>
                      <BackgroundButton
                        imageUrl={currentImage}
                        buttonName={skill_name}
                        onOpen={() => handleSelected(skill_name)}
                      />
                    </div>
                  )
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
