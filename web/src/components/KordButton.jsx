const KordButton = ({ className = "", disabled = false, onCoord, onDone }) => {
  const nui = (eventName, data) =>
    fetch(`https://${GetParentResourceName()}/${eventName}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data ?? {}),
    }).then((r) => r.json().catch(() => ({})));

  const handleClick = async () => {
    if (disabled) return;
    try {
      const res = await nui("phone:getLocationText");
      const loc = res?.text || "";
      if (loc && typeof onCoord === "function") {
        onCoord(loc);
      }

      await nui("phone:setWaypoint");
      if (typeof onDone === "function") onDone();
    } catch (error) {
      console.error("kord error", error);
    }
  };

  return (
    <button
      type="button"
      className={`shrink-0 w-10 h-10 rounded-full text-white text-[10px] font-bold ${disabled ? "bg-gray-500 cursor-not-allowed" : "bg-blue-500 hover:bg-blue-600"} ${className}`}
      onClick={handleClick}
      disabled={disabled}
      aria-disabled={disabled}
    >
      KORD
    </button>
  );
};

export default KordButton;
