"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import home from "@/styles/home.module.css";
import page from "../../styles/page.module.css";
import UserCharacter from "@/components/UserCharacter";
import BackgroundButton from "@/components/BackgroundButton";
import { useAuth } from "@/contexts/auth/useAuth";
import { equipUserItem, getUserOwnedItems } from "@/api/user";

const baseSkillsUrl = `/skills`;
const baseClothesUrl = `/clothes`;

const skill_1_name = "NA" as const;
const skill_2_name = "S1" as const;
const skill_3_name = "S2" as const;
const skill_4_name = "ULT" as const;

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

type ownedItemResponse = {
  owned_skills: [string];
  owned_clothes: [string];
};

export default function UserPage() {
  const router = useRouter();
  const { user, loading } = useAuth();

  const [equippedClothes, setEquippedClothes] = useState<string[]>([
    "acc_1",
    "shirt_1",
    "shoes_1",
  ]);
  const [equippedSkills, setEquippedSkills] = useState<string[]>([
    "na_1",
    "s1_1",
    "s2_1",
    "ult_1",
  ]);

  useEffect(() => {
    if (!loading && user) {
      if (user.equipped_clothes) setEquippedClothes(user.equipped_clothes);
      if (user.equipped_skills) setEquippedSkills(user.equipped_skills);

      const fetchOwnedItems = async () => {
        const ownedItems: ownedItemResponse = await getUserOwnedItems();
        setOwnedClothes(ownedItems.owned_clothes);
        setOwnedSkills(ownedItems.owned_skills);
      };
      fetchOwnedItems();
    }
  }, [loading, user]);

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
  const handleReturn = () => {
    router.push("/");
  };
  const handleSelected = async (item_id: string) => {
    const equipSend: equipItemRequest = {
      equip_item: item_id,
    };
    try {
      const data = await equipUserItem(equipSend);
      const addedItem = data.equipped_item;

      if (
        item_id.startsWith("na_") ||
        item_id.startsWith("s1_") ||
        item_id.startsWith("s2_") ||
        item_id.startsWith("ult_")
      ) {
        setEquippedSkills((prev) => {
          const nextSkills = [...prev];
          if (addedItem.startsWith("na_")) nextSkills[0] = addedItem;
          else if (addedItem.startsWith("s1_")) nextSkills[1] = addedItem;
          else if (addedItem.startsWith("s2_")) nextSkills[2] = addedItem;
          else if (addedItem.startsWith("ult_")) nextSkills[3] = addedItem;
          return nextSkills;
        });
      } else {
        setEquippedClothes((prev) => {
          const nextClothes = [...prev];
          if (addedItem.startsWith("acc_")) nextClothes[0] = addedItem;
          else if (addedItem.startsWith("shirt_")) nextClothes[1] = addedItem;
          else if (addedItem.startsWith("shoes_")) nextClothes[2] = addedItem;
          return nextClothes;
        });
      }
    } catch (error) {
      // resolve error
      console.error("Error while processing equipment", error);
    }
  };

  if (loading || equippedClothes.length === 0 || equippedSkills.length === 0) {
    return (
      <div className="position-relative d-flex justify-content-center align-items-center">
        Loading character...
      </div>
    );
  }

  const clothes_0_equipped = "/clothes/base-character.png";
  const clothes_1_equipped = `/clothes/ACC/${equippedClothes[0]}.png`;
  const clothes_2_equipped = `/clothes/SHIRT/${equippedClothes[1]}.png`;
  const clothes_3_equipped = `/clothes/SHOES/${equippedClothes[2]}.png`;

  const skill_1_equipped = `/skills/NA/${equippedSkills[0]}.png`;
  const skill_2_equipped = `/skills/S1/${equippedSkills[1]}.png`;
  const skill_3_equipped = `/skills/S2/${equippedSkills[2]}.png`;
  const skill_4_equipped = `/skills/ULT/${equippedSkills[3]}.png`;
  return (
    <div
      className={`${page.roomsPage} container h-100 position-relative overflow-hidden mb-5`}
      style={{ border: "5px solid darkgoldenrod", background: "transparent" }}
    >
      <button
        className={`${home.optionBtn} position-absolute mt-3`}
        style={{
          padding: "10px 10px",
          color: "white",
          background: "red",
        }}
        onClick={handleReturn}
      >
        RETURN
      </button>
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
        <div className="pt-2">
          <button className="close-btn-left" onClick={handleCloseClothes}>
            &times;
          </button>
          <div className="d-flex justify-content-start h-100">
            <div
              className="d-flex flex-row flex-wrap overflow-auto gap-2"
              style={{ height: "70vh" }}
            >
              {ownedClothes?.map((clothe_id) => {
                const prefixClothes = clothe_id.split("_")[0].toUpperCase();
                const currentImage = `${baseClothesUrl}/${prefixClothes}/${clothe_id}.png`;
                const isMatch = prefixClothes === selectedClotheType;
                const isEquipped = equippedClothes.includes(clothe_id);
                return (
                  isMatch && (
                    <div className={`dropdown-content`} key={clothe_id}>
                      <BackgroundButton
                        imageUrl={currentImage}
                        buttonName={clothe_id}
                        onOpen={() => handleSelected(clothe_id)}
                        isDisabled={isEquipped}
                        isEquipped={isEquipped}
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
                imageUrl={skill_1_equipped}
                buttonName={skill_1_name}
                onOpen={handleShowSkills}
                isDisabled={false}
                isEquipped={false}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_2_equipped}
                buttonName={skill_2_name}
                onOpen={handleShowSkills}
                isDisabled={false}
                isEquipped={false}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_3_equipped}
                buttonName={skill_3_name}
                onOpen={handleShowSkills}
                isDisabled={false}
                isEquipped={false}
              />
            </div>
            <div className="component-item">
              <BackgroundButton
                imageUrl={skill_4_equipped}
                buttonName={skill_4_name}
                onOpen={handleShowSkills}
                isDisabled={false}
                isEquipped={false}
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
              <UserCharacter
                base_user_url={clothes_0_equipped}
                acc_user_url={clothes_1_equipped}
                shirt_user_url={clothes_2_equipped}
                shoes_user_url={clothes_3_equipped}
              />
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
        <div className="pt-2">
          <button className="close-btn-right" onClick={handleCloseSkills}>
            &times;
          </button>
          <div className="d-flex justify-content-end h-100">
            <div
              className="d-flex flex-column flex-wrap gap-2"
              style={{ height: "70vh" }}
            >
              {ownedSkills?.map((skill_id) => {
                const prefixSkill = skill_id.split("_")[0].toUpperCase();
                const currentImage = `${baseSkillsUrl}/${prefixSkill}/${skill_id}.png`;
                const isMatch = prefixSkill === selectedSkillType;
                const isEquipped = equippedSkills.includes(skill_id);
                return (
                  isMatch && (
                    <div className={`dropdown-content`} key={skill_id}>
                      <BackgroundButton
                        imageUrl={currentImage}
                        buttonName={skill_id}
                        onOpen={() => handleSelected(skill_id)}
                        isDisabled={isEquipped}
                        isEquipped={isEquipped}
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
