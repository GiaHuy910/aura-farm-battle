import Image from "next/image";

import gameTicket from "@/public/game-ticket.ico";
export const GachaTicket = () => {
  return (
    <div>
      <Image
        src={gameTicket}
        width={40}
        height={35}
        alt="game-ticket"
        priority
      />
    </div>
  );
};
