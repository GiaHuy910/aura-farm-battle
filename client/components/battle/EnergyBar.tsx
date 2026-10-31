"use client";

export default function EnergyBar({
  value,
  max = 7,
}: {
  value: number;
  max?: number;
}) {
  return (
    <div
      className="d-flex align-items-center gap-2"
      title={`Energy ${value}/${max}`}
    >
      <span className="text-primary fs-1">&#x26A1;&#xFE0E;</span>
      <div className="d-flex gap-1">
        {Array.from({ length: max }, (_, i) => (
          <div
            key={i}
            style={{
              width: 18,
              height: 12,
              borderRadius: 3,
              background: i < value ? "#0077ffec" : "#d9d3bd",
              border: "1px solid #8a6d1d",
            }}
          />
        ))}
      </div>
      <span className="small">
        {value}/{max}
      </span>
    </div>
  );
}
