"use client";

import { useState } from "react";

import UserCharacter from "@/components/UserCharacter";
import BackgroundButton from "@/components/BackgroundButton";
import { useAuth } from "@/contexts/auth/useAuth";
import page from "../../styles/page.module.css";

const skill_na = "/skills/na/na_2.png";
const skill_na_name = "NA";
const skill_s1 = "/skills/s1/s1_2.png";
const skill_s1_name = "S1";
const skill_s2 = "/skills/s2/s2_4.png";
const skill_s2_name = "S2";
const skill_ult = "/skills/ult/ult_4.png";
const skill_ult_name = "ULT";

const SKILL_IMAGES: Record<string, string> = {
  na_2: skill_na,
  s1_2: skill_s1,
  s2_4: skill_s2,
  ult_4: skill_ult,
};

type SkillId = { id: string };

export default function UserPage() {
  const { user } = useAuth();

  const [showSkills, setShowSkills] = useState(false);
  const [ownedSkills, setOwnedSkills] = useState<string[]>([
    "na_2",
    "s1_2",
    "s2_4",
    "ult_4",
  ]);
  const handleShowSkills = () => {
    setShowSkills((prev) => !prev);
    setShowClothes(false);
  };
  const handleCloseSkills = () => {
    setShowSkills((prev) => !prev);
  };

  const [showClothes, setShowClothes] = useState(false);
  const [ownedClothes, setOwnedClothes] = useState<string[]>([
    "accessory_1",
    "shirt_1",
    "shoes_1",
  ]);
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
          <button className="btn btn-info rounded-0 flex-fill border border-light">
            Acs
          </button>
          <button className="btn btn-info rounded-0 flex-fill border border-light">
            Shirt
          </button>
          <button className="btn btn-info rounded-0 flex-fill border border-light">
            Shoes
          </button>
        </div>
        <div>
          <button className="close-btn-left" onClick={handleCloseClothes}>
            &times;
          </button>
          <div className="d-flex justify-content-start h-100">
            <div className="d-flex flex-column h-100">
              {ownedClothes?.map((id) => {
                const currentImage = SKILL_IMAGES[id];
                return (
                  <div className="dropdown-content" key={id}>
                    <BackgroundButton
                      imageUrl={currentImage}
                      buttonName={id}
                      onOpen={() => handleSelected(id)}
                    />
                  </div>
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
                imageUrl={skill_na}
                buttonName={skill_na_name}
                onOpen={handleShowSkills}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_s1}
                buttonName={skill_s1_name}
                onOpen={handleShowSkills}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_s2}
                buttonName={skill_s2_name}
                onOpen={handleShowSkills}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_ult}
                buttonName={skill_ult_name}
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
          <button className="btn btn-info rounded-0 flex-fill border border-light">
            NA
          </button>
          <button className="btn btn-info rounded-0 flex-fill border border-light">
            S1
          </button>
          <button className="btn btn-info rounded-0 flex-fill border border-light">
            S2
          </button>
          <button className="btn btn-info rounded-0 flex-fill border border-light">
            ULT
          </button>
        </div>
        <div>
          <button className="close-btn-right" onClick={handleCloseSkills}>
            &times;
          </button>
          <div className="d-flex justify-content-end h-100">
            <div className="d-flex flex-column h-100">
              {ownedSkills?.map((id) => {
                const currentImage = SKILL_IMAGES[id];
                return (
                  <div className="dropdown-content" key={id}>
                    <BackgroundButton
                      imageUrl={currentImage}
                      buttonName={id}
                      onOpen={() => handleSelected(id)}
                    />
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
