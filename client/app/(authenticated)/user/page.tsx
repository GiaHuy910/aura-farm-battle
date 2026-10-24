"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import home from "@/styles/home.module.css";
import page from "@/styles/page.module.css";
import UserCharacter from "@/components/UserCharacter";
import BackgroundButton from "@/components/BackgroundButton";
import { useAuth } from "@/contexts/auth/useAuth";
import { usePool } from "@/api/pool";
import { equipUserItem, getUserOwnedItems } from "@/api/user";
import { getPlayerClothesAssets } from "@/helpers/getPlayerClothesAssets";

const baseSkillsUrl = `/skills`;
const baseClothesUrl = `/clothes`;

const skill_1_name = "S1" as const;
const skill_2_name = "S2" as const;
const skill_3_name = "S3" as const;
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
  const { poolData } = usePool();
  const { user, loading, fetchMe } = useAuth();

  useEffect(() => {
    if (!loading && user) {
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
    "s1_1",
    "s2_1",
    "s3_1",
    "ult_1",
  ]);
  // rememebr to test more ownedskills
  const [selectedSkillType, setSelectedSkillType] = useState<SkillType>("S1");
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
      await equipUserItem(equipSend);
      fetchMe();
    } catch (error) {
      // resolve error
      console.error("Error while processing equipment", error);
    }
  };

  if (
    loading ||
    user?.equipped_clothes?.length === 0 ||
    user?.equipped_skills?.length === 0
  ) {
    return (
      <div className="position-relative d-flex justify-content-center align-items-center">
        Loading character...
      </div>
    );
  }
  const { base_user_url, acc_user_url, shirt_user_url, shoes_user_url } =
    getPlayerClothesAssets(user?.equipped_clothes);

  const skill_1_equipped = `/skills/S1/${user?.equipped_skills?.[0]}.png`;
  const skill_2_equipped = `/skills/S2/${user?.equipped_skills?.[1]}.png`;
  const skill_3_equipped = `/skills/S3/${user?.equipped_skills?.[2]}.png`;
  const skill_4_equipped = `/skills/ULT/${user?.equipped_skills?.[3]}.png`;

  const skill_1_rarity = poolData?.skill.find(
    (s: Skill) => s.skill_id === user?.equipped_skills?.[0],
  )?.rarity;
  const skill_2_rarity = poolData?.skill.find(
    (s: Skill) => s.skill_id === user?.equipped_skills?.[1],
  )?.rarity;
  const skill_3_rarity = poolData?.skill.find(
    (s: Skill) => s.skill_id === user?.equipped_skills?.[2],
  )?.rarity;
  const skill_4_rarity = poolData?.skill.find(
    (s: Skill) => s.skill_id === user?.equipped_skills?.[3],
  )?.rarity;

  return (
    <div
      className={`${page.roomsPage} container h-100 position-relative overflow-hidden mb-2`}
      style={{ border: "5px solid darkgoldenrod", backgroundColor: "#eae2c7" }}
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
                const isEquipped = user?.equipped_clothes?.includes(clothe_id);

                const detailedItem = poolData?.clothe.find(
                  (c: Clothe) => c.clothe_id === clothe_id,
                );
                const itemRarity = detailedItem?.rarity || "common";
                return (
                  isMatch && (
                    <div className={`dropdown-content`} key={clothe_id}>
                      <BackgroundButton
                        imageUrl={currentImage}
                        buttonName={clothe_id}
                        onOpen={() => handleSelected(clothe_id)}
                        isDisabled={isEquipped ?? false}
                        isEquipped={isEquipped ?? false}
                        itemRarity={itemRarity}
                        Width="150px"
                        Height="150px"
                        bgSize="150%"
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
          <div className="w-100 mt-5 d-flex flex-row flex-wrap align-items-center justify-content-center">
            <div className="component-item" key={skill_1_equipped}>
              <div className="glow-active">
                <BackgroundButton
                  imageUrl={skill_1_equipped}
                  buttonName={skill_1_name}
                  onOpen={handleShowSkills}
                  isDisabled={false}
                  isEquipped={false}
                  itemRarity={skill_1_rarity}
                  Width="120px"
                  Height="120px"
                  bgSize="150%"
                />
              </div>
            </div>
            <div className="component-item popIn" key={skill_2_equipped}>
              <div className="glow-active">
                <BackgroundButton
                  imageUrl={skill_2_equipped}
                  buttonName={skill_2_name}
                  onOpen={handleShowSkills}
                  isDisabled={false}
                  isEquipped={false}
                  itemRarity={skill_2_rarity}
                  Width="120px"
                  Height="120px"
                  bgSize="150%"
                />
              </div>
            </div>
            <div className="component-item popIn" key={skill_3_equipped}>
              <div className="glow-active">
                <BackgroundButton
                  imageUrl={skill_3_equipped}
                  buttonName={skill_3_name}
                  onOpen={handleShowSkills}
                  isDisabled={false}
                  isEquipped={false}
                  itemRarity={skill_3_rarity}
                  Width="120px"
                  Height="120px"
                  bgSize="150%"
                />
              </div>
            </div>
            <div className="component-item popIn" key={skill_4_equipped}>
              <div className="glow-active">
                <BackgroundButton
                  imageUrl={skill_4_equipped}
                  buttonName={skill_4_name}
                  onOpen={handleShowSkills}
                  isDisabled={false}
                  isEquipped={false}
                  itemRarity={skill_4_rarity}
                  Width="200px"
                  Height="120px"
                  bgSize="150%"
                />
              </div>
            </div>
          </div>
        </div>

        <div
          style={{ border: "5px solid darkgoldenrod" }}
          className="col-md-6 d-flex flex-column align-items-center justify-content-center"
        >
          <div className="w-100 d-flex flex-column align-items-center justify-content-center">
            <div className="component-item d-flex ">
              <p className="text-dark">AURA : </p>
              <span className="text-primary">
                {user?.total_aura}(+{user?.bonus_aura})
              </span>
            </div>
            <div className="component-item">
              <UserCharacter
                base_user_url={base_user_url}
                acc_user_url={acc_user_url}
                shirt_user_url={shirt_user_url}
                shoes_user_url={shoes_user_url}
              />
            </div>
            <div className="component-item mt-5">
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
              className="d-flex flex-row flex-wrap overflow-auto gap-2"
              style={{ height: "70vh" }}
            >
              {ownedSkills?.map((skill_id) => {
                const prefixSkill = skill_id.split("_")[0].toUpperCase();
                const currentImage = `${baseSkillsUrl}/${prefixSkill}/${skill_id}.png`;
                const isMatch = prefixSkill === selectedSkillType;
                const isEquipped = user?.equipped_skills?.includes(skill_id);

                const detailedItem = poolData?.skill.find(
                  (c: Skill) => c.skill_id === skill_id,
                );
                const itemRarity = detailedItem?.rarity || "common";
                return (
                  isMatch && (
                    <div className={`dropdown-content`} key={skill_id}>
                      <BackgroundButton
                        imageUrl={currentImage}
                        buttonName={skill_id}
                        onOpen={() => handleSelected(skill_id)}
                        isDisabled={isEquipped ?? false}
                        isEquipped={isEquipped ?? false}
                        itemRarity={itemRarity}
                        Width="150px"
                        Height="150px"
                        bgSize="100%"
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
