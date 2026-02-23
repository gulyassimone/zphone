import axios from "axios";
import { useContext, useEffect, useMemo, useRef, useState } from "react";
import { FaBell } from "react-icons/fa6";
import { MdArrowBackIosNew, MdClose } from "react-icons/md";
import { MENU_DEFAULT, MENU_MESSAGE_CHATTING, NAME } from "../constant/menu";
import MenuContext from "../context/MenuContext";
import { t } from "../i18n";
import KordButton from "./KordButton";
import LoadingComponent from "./LoadingComponent";

const ServicesComponent = ({ isShow }) => {
  const { resolution, profile, setMenu, services, setChatting, setServices } =
    useContext(MenuContext);

  const nui = (eventName, data) =>
    fetch(`https://${GetParentResourceName()}/${eventName}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data ?? {}),
    });
  const allowedJobs = useMemo(() => {
    const list = Array.isArray(services?.list) ? services.list : [];
    return new Set(
      list
        .map((svc) => (svc?.job || "").toLowerCase())
        .filter((jobName) => jobName !== "")
    );
  }, [services?.list]);
  const sortedReports = useMemo(() => {
    const list = Array.isArray(services?.reports) ? services.reports : [];
    const filled = list.filter(
      (report) => String(report?.cord ?? "").trim() !== ""
    );

    return [...filled].sort((a, b) => {
      const aTime = Date.parse(a?.created_at ?? "") || 0;
      const bTime = Date.parse(b?.created_at ?? "") || 0;
      return bTime - aTime;
    });
  }, [services?.reports]);

  const [hasNewReports, setHasNewReports] = useState(false);
  const prevReportsLenRef = useRef(sortedReports.length);

  useEffect(() => {
    const currentLen = sortedReports.length;
    if (currentLen > prevReportsLenRef.current) {
      setHasNewReports(true);
    }
    if (currentLen === 0) {
      setHasNewReports(false);
    }
    prevReportsLenRef.current = currentLen;
  }, [sortedReports]);
  const [isShowModal, setIsShowModal] = useState(false);
  const [ackReport, setAckReport] = useState(null);
  const [service, setService] = useState(null);
  const [subMenu, setSubMenu] = useState("list");
  const [solvedReason, setSolvedReason] = useState("");
  const [formDataMessage, setFormDataMessage] = useState({
    message: "",
    cord: "",
  });
  const [kordUsed, setKordUsed] = useState(false);

  const handleMessageFormChange = (e) => {
    const { name, value } = e.target;
    setFormDataMessage({
      ...formDataMessage,
      [name]: value,
    });
  };

  const handleMessageFormSubmit = async (e) => {
    e.preventDefault();
    if (!formDataMessage.message) {
      return;
    }

    const payload = {
      ...formDataMessage,
      job: service.job,
    };
    let result = null;
    try {
      const response = await axios.post(
        "/send-message-service",
        payload
      );
      result = response.data;
      setFormDataMessage({
        message: "",
        cord: "",
      });
      setKordUsed(false);
      setIsShowModal(false);
      setService(null);
    } catch (error) {
      console.error("error /send-message-service", error);
    }
  };

  const deleteMessages = (array, idToDelete) => {
    return array.filter((item) => item.id !== idToDelete);
  };

  const getServiceLogo = (svc) => {
    const job = (svc?.job || "").toLowerCase();
    if (svc?.logo) return svc.logo;
    if (job) return `./images/services/${job}.svg`;
    return "./images/noimage.jpg";
  };

  const setWaypointFromCord = async (cordText) => {
    if (!cordText) return;
    const matches = Array.from(cordText.matchAll(/-?\d+\.?\d*/g)).map((m) => parseFloat(m[0]));
    if (matches.length < 2) return;
    const [x, y] = matches;
    try {
      await nui("phone:setWaypointAt", { x, y });
    } catch (err) {
      console.error("setWaypointAt failed", err);
    }
  };

  const filteredServices = useMemo(() => {
    const list = Array.isArray(services?.list) ? services.list : [];
    return list;
  }, [services?.list]);

  const shouldLock = isShow && (isShowModal || subMenu === "report" || ackReport != null);

  useEffect(() => {
    if (!shouldLock) return;

    nui("phone:setMessagesOpen", { open: true }).catch(() => {});

    return () => {
      nui("phone:setMessagesOpen", { open: false }).catch(() => {});
    };
  }, [shouldLock]);

  return (
    <div
      className="relative flex flex-col w-full h-full"
      style={{
        display: isShow ? "block" : "none",
      }}
    >
      {subMenu == "list" ? (
        <>
          <div
            className={`no-scrollbar absolute w-full h-full z-30 overflow-auto py-10 text-white ${
              isShowModal ? "visible" : "invisible"
            }`}
            style={{
              height: resolution.layoutHeight,
              width: resolution.layoutWidth,
              backgroundColor: "rgba(31, 41, 55, 0.8)",
            }}
          >
            {service != null ? (
              <div className="flex flex-col justify-center rounded-xl h-full w-full px-3">
                <div className="bg-slate-700 rounded-lg py-2 flex flex-col w-full p-3">
                  <div className="flex justify-between items-center pb-1">
                    <span className="truncate font-semibold">
                      {service.service}
                    </span>
                    <div>
                      <MdClose
                        className="text-2xl text-red-500 cursor-pointer hover:text-red-700"
                        onClick={() => {
                          setFormDataMessage((prev) => ({
                            ...prev,
                            message: "",
                            cord: "",
                          }));
                          setKordUsed(false);
                          setIsShowModal(false);
                          setService(null);
                        }}
                      />
                    </div>
                  </div>
                  <form onSubmit={handleMessageFormSubmit} className="w-full">
                    <div className="flex flex-col gap-1 py-2 text-xs">
                        <span className="flex justify-between items-center">
                          <span className="flex justify-between items-center gap-2 w-full">
                            <textarea
                              value={formDataMessage.message}
                              name="message"
                              onChange={handleMessageFormChange}
                              placeholder={t("services_message_placeholder")}
                              rows={4}
                              className="bg-black focus:outline-none text-white w-full text-xs resize-none no-scrollbar bg-slate-800 p-3 rounded-lg"
                            ></textarea>

                            <KordButton
                              disabled={kordUsed}
                              onCoord={(loc) => {
                                setFormDataMessage((prev) => ({ ...prev, cord: loc }));
                                setKordUsed(true);
                              }}
                              onDone={() => setKordUsed(true)}
                            />
                          </span>
                        </span>
                        {formDataMessage.cord ? (
                          <div className="text-xs text-gray-200 bg-slate-800 px-3 py-2 rounded-lg truncate">
                            {formDataMessage.cord}
                          </div>
                        ) : null}
                      <div className="flex justify-end pt-2">
                        <button
                          className="flex font-medium rounded-full text-white bg-blue-500 px-3 py-1 text-sm items-center justify-center"
                          type="submit"
                        >
                          <span>{t("send")}</span>
                        </button>
                      </div>
                    </div>
                  </form>
                </div>
              </div>
            ) : null}
          </div>

          <div className="absolute top-0 flex w-full justify-between py-2 bg-black pt-8 z-10">
            <div
              className="flex items-center px-2 text-blue-500 cursor-pointer"
              onClick={() => setMenu(MENU_DEFAULT)}
            >
              <MdArrowBackIosNew className="text-lg" />
              <span className="text-xs">{t("back")}</span>
            </div>
            <span className="absolute left-0 right-0 m-auto text-sm text-white w-fit">
              {t("menu_services")}
            </span>
            <div className="relative flex items-center px-2 text-white cursor-pointer hover:text-blue-400">
              {allowedJobs.has((profile?.job?.name || "").toLowerCase()) ? (
                <FaBell
                  className={`text-lg ${hasNewReports ? "text-red-500 animate-bounce" : ""}`}
                  onClick={() => {
                    setSubMenu("report");
                    setHasNewReports(false);
                  }}
                />
              ) : null}
            </div>
          </div>
          <div
            className="no-scrollbar flex flex-col w-full h-full overflow-y-auto"
            style={{
              paddingTop: 60,
            }}
          >
            <div className="flex flex-col -mt-1 pb-2 px-2 absolute bg-black z-10">
              <div className="text-lg font-semibold text-white">
                {t("services_title", [NAME])}
              </div>
              <div className="text-xs text-gray-200">
                {t("services_subtitle", [NAME])}
              </div>
            </div>
            {services == undefined ? (
              <LoadingComponent />
            ) : (
              <div
                className="grid grid-cols-2 gap-4 px-2 pb-3"
                style={{
                  marginTop: 75,
                }}
              >
                {filteredServices.map((v, i) => {
                  return (
                    <div
                      className="relative flex flex-col bg-gray-800 rounded-xl items-center p-2 cursor-pointer hover:bg-gray-700"
                      key={i}
                      onClick={() => {
                        setFormDataMessage({ message: "", cord: "" });
                        setKordUsed(false);
                        setIsShowModal(true);
                        setService(v);
                      }}
                    >
                      <img
                        src={getServiceLogo(v)}
                        className="w-14 h-14 object-cover rounded-full mb-1"
                        alt=""
                        onError={(error) => {
                          error.target.src = "./images/noimage.jpg";
                        }}
                      />
                      <div
                        className="flex flex-col items-center"
                        style={{
                          minHeight: 80,
                        }}
                      >
                        <span className="text-white text-center text-xs line-clamp-2">
                          {v.service}
                        </span>
                        <span className="text-xs text-gray-200 font-medium pb-2">
                          {v.type.toUpperCase()}
                        </span>
                      </div>
                      <div className="absolute bottom-0 flex justify-center border-t w-full border-gray-600 py-1">
                        <span className="text-sm font-medium text-white">
                          {t("services_message_button")}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </>
      ) : null}

      {subMenu == "report" ? (
        <>
          <div
            className={`no-scrollbar absolute w-full z-30 overflow-auto py-10 text-white ${
              ackReport != null ? "visible" : "invisible"
            }`}
            style={{
              height: resolution.layoutHeight,
              width: resolution.layoutWidth,
              backgroundColor: "rgba(31, 41, 55, 0.8)",
            }}
          >
            {ackReport == null ? (
              <LoadingComponent />
            ) : (
              <div className="flex flex-col justify-center rounded-xl h-full w-full px-3">
                <div className="bg-slate-700 rounded-lg py-2 flex flex-col w-full p-3">
                  <div className="flex justify-between items-center pb-1">
                    <span className="truncate font-semibold">
                      {ackReport.phone_number}
                    </span>
                    <div>
                      <MdClose
                        className="text-2xl cursor-pointer text-white hover:text-red-500"
                        onClick={() => {
                          setAckReport(null);
                        }}
                      />
                    </div>
                  </div>
                  <div className="w-full">
                    <div className="flex flex-col gap-1 py-2 text-xs">
                      <span className="flex justify-between items-center">
                        <textarea
                          value={ackReport.message}
                          name="message"
                          placeholder={t("services_message_placeholder")}
                          rows={5}
                          className="bg-black focus:outline-none text-white w-full text-xs resize-none no-scrollbar bg-slate-800 px-3 py-2 rounded-lg"
                          readOnly
                        ></textarea>
                      </span>
                    </div>
                    {ackReport.cord ? (
                      <div className="flex items-center justify-start gap-2 mb-2">
                        <button
                          type="button"
                          className="w-10 h-10 rounded-full bg-blue-500 hover:bg-blue-600 text-white text-[10px] font-bold"
                          onClick={() => setWaypointFromCord(ackReport.cord)}
                        >
                          GPS
                        </button>
                      </div>
                    ) : null}
                    <input
                      placeholder={t("services_reason_placeholder")}
                      className="bg-black focus:outline-none text-white w-full text-xs resize-none no-scrollbar bg-slate-800 px-3 py-2 rounded-lg"
                      onChange={(e) => {
                        const { value } = e.target;
                        setSolvedReason(value);
                      }}
                    />
                    <div className="flex justify-center space-x-2 py-2">
                        <button
                          className={`px-2 py-1 text-white text-xs text-center rounded ${solvedReason ? 'bg-green-500 hover:bg-green-600 cursor-pointer' : 'bg-gray-500 cursor-not-allowed'}`}
                          onClick={async () => {
                            if (!solvedReason) return;
                            await axios
                              .post("/solved-message-service", {
                                id: ackReport.id,
                                citizenid: ackReport.citizenid,
                                service: ackReport.service,
                                reason: solvedReason,
                              })
                              .then(function (response) {
                                if (response.data) {
                                  setAckReport(null);
                                  setServices((prevChatting) => ({
                                    ...prevChatting,
                                    reports: deleteMessages(
                                      services.reports,
                                      ackReport.id
                                    ),
                                  }));
                                }
                              })
                              .catch(function (error) {
                                console.log(error);
                              })
                              .finally(function () {});
                          }}
                          disabled={!solvedReason}
                        >
                          {t("services_solved")}
                        </button>
                      <button
                        className="px-2 py-1 text-white text-xs bg-yellow-500 hover:bg-yellow-600 text-center rounded"
                        onClick={async () => {
                          await axios
                            .post("/new-or-continue-chat", {
                              to_citizenid: ackReport.citizenid,
                            })
                            .then(function (response) {
                              if (response.data) {
                                setChatting(response.data);
                                setMenu(MENU_MESSAGE_CHATTING);
                                setAckReport(null);
                              }
                            })
                            .catch(function (error) {
                              console.log(error);
                            })
                            .finally(function () {});
                        }}
                      >
                        {t("services_message_button")}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
          <div className="absolute top-0 flex w-full justify-between py-2 bg-black pt-8 z-10">
            <div
              className="flex items-center px-2 text-blue-500 cursor-pointer"
              onClick={() => setSubMenu("list")}
            >
              <MdArrowBackIosNew className="text-lg" />
              <span className="text-xs">{t("back")}</span>
            </div>
            <span className="absolute left-0 right-0 m-auto text-sm text-white w-fit">
              {/* Services */}
            </span>
            <div className="flex items-center px-2 text-white cursor-pointer hover:text-blue-400"></div>
          </div>
          <div
            className="no-scrollbar flex flex-col w-full h-full overflow-y-auto"
            style={{
              paddingTop: 60,
            }}
          >
            {services == undefined ? (
              <LoadingComponent />
            ) : (
              <>
                {sortedReports.map((v, i) => {
                  return (
                    <div
                      className="flex flex-col pl-1 pr-1"
                      key={i}
                      onClick={() => {
                        setAckReport(v);
                      }}
                    >
                      <div
                        className={`w-full flex flex-col cursor-pointer text-white border-b border-gray-900 pb-1 mb-1 px-2 hover:text-green-400`}
                      >
                        <div className="flex text-xs justify-between w-full">
                          <span className="line-clamp-1">{v.phone_number}</span>
                          <span className="text-gray-300">{v.created_at}</span>
                        </div>
                        <span className="text-xs line-clamp-1">
                          {v.message}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </>
            )}
          </div>
        </>
      ) : null}
    </div>
  );
};
export default ServicesComponent;
