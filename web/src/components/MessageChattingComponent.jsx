import { useLongPress } from "@uidotdev/usehooks";
import axios from "axios";
import { useContext, useEffect, useMemo, useRef, useState } from "react";
import {
  MdArrowBackIosNew,
  MdAttachFile,
  MdOutlinePhone,
  MdSend,
} from "react-icons/md";
import { MENU_MESSAGE } from "../constant/menu";
import MenuContext from "../context/MenuContext";
import { t } from "../i18n";
import LoadingComponent from "./LoadingComponent";

function safeParseInfo(str) {
  try {
    return JSON.parse(str);
  } catch {
    return null;
  }
}

const Bubble = ({ v, i, isMine, maxWidthPx, onPressProps }) => {
  const baseWrap = isMine ? "flex items-end justify-end" : "flex items-end";
  const baseBox = isMine
    ? "pb-4 px-2 py-1.5 rounded-lg inline-block rounded-br-none bg-[#134D37] text-white text-left"
    : "pb-4 px-2 py-1.5 rounded-lg inline-block rounded-bl-none bg-[#242527] text-white text-left";

  const timePos = isMine
    ? "absolute bottom-0.5 right-1 text-gray-100"
    : "absolute bottom-0 right-1 text-gray-100";

  const allowPress = !v.is_deleted && !(v.minute_diff > 30);

  return (
    <div className={baseWrap} key={i} {...(isMine && allowPress ? onPressProps : null)}>
      <div
        className={`relative flex flex-col text-xs ${isMine ? "items-end" : "items-start"}`}
        style={{ maxWidth: `${maxWidthPx}px` }}
      >
        <div className={baseBox} style={{ minWidth: 100 }}>
          {v.is_deleted ? (
            <span className="text-gray-200 italic">This message was deleted</span>
          ) : v.message === "" ? (
            <img
              className="rounded pb-1"
              src={v.media}
              alt=""
              data-info={JSON.stringify({ msg: v, index: i })}
            />
          ) : (
            <span data-info={JSON.stringify({ msg: v, index: i })}>{v.message}</span>
          )}
        </div>

        <span className={timePos} style={{ fontSize: 10 }}>
          {v.time}
        </span>
      </div>
    </div>
  );
};

const MessageChattingComponent = ({ isShow }) => {
  const { setMenu, chatting, setChatting, profile, resolution, photos, setPhotos } =
    useContext(MenuContext);

  const nui = (eventName, data) =>
    fetch(`https://${GetParentResourceName()}/${eventName}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data ?? {}),
    });

  const messagesEndRef = useRef(null);

  const [message, setMessage] = useState("");
  const [deleteCtx, setDeleteCtx] = useState(null); // { msg, index } | null
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [isPhotoPickerOpen, setIsPhotoPickerOpen] = useState(false);
  const [isLoadingPhotos, setIsLoadingPhotos] = useState(false);
  const [isSendingPhoto, setIsSendingPhoto] = useState(false);
  const [photoError, setPhotoError] = useState(null);

  const chatsList = useMemo(
    () => (Array.isArray(chatting?.chats) ? chatting.chats : []),
    [chatting?.chats]
  );

  const maxBubbleWidth = useMemo(() => {
    const w = resolution?.layoutWidth || 0;
    return Math.max(120, w - 50);
  }, [resolution?.layoutWidth]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView();
  };

  useEffect(() => {
    scrollToBottom();
  }, [chatting, chatsList.length]);

  useEffect(() => {
    if (!isShow) return;

    nui("phone:setMessagesOpen", { open: true }).catch(() => {});

    return () => {
      nui("phone:setMessagesOpen", { open: false }).catch(() => {});
    };
  }, [isShow]);

  const closeDelete = () => {
    setDeleteCtx(null);
    setIsDeleteOpen(false);
  };

  const openDeleteFromEvent = (event) => {
    const infoStr = event?.target?.dataset?.info;
    if (!infoStr) return;

    const parsed = safeParseInfo(infoStr);
    if (!parsed) return;

    setDeleteCtx(parsed);
    setIsDeleteOpen(true);
  };

  const onPressChat = useLongPress(openDeleteFromEvent, {
    threshold: 500,
  });

  const fetchPhotos = async () => {
    setIsLoadingPhotos(true);
    setPhotoError(null);

    try {
      const response = await axios.post("/get-photos");
      setPhotos(response.data || []);
    } catch (err) {
      console.error("error /get-photos", err);
      setPhotoError("Failed to load photos");
    } finally {
      setIsLoadingPhotos(false);
    }
  };

  const openPhotoPicker = async () => {
    setIsPhotoPickerOpen(true);
    await fetchPhotos();
  };

  const closePhotoPicker = () => {
    setIsPhotoPickerOpen(false);
    setPhotoError(null);
  };

  const sendTextMessage = async () => {
    const text = message.trim();
    if (!text || !chatting) return;

    setMessage("");

    try {
      const response = await axios.post("/send-chatting", {
        conversationid: chatting.conversationid,
        message: text,
        media: "",
        conversation_name: chatting.conversation_name,
        to_citizenid: chatting.citizenid,
        is_group: chatting.is_group,
      });

      if (response.data) {
        const newMessage = {
          time: "just now",
          message: text,
          sender_citizenid: profile.citizenid,
          id: response.data,
        };

        setChatting((prev) => {
          const prevChats = Array.isArray(prev?.chats) ? prev.chats : [];
          return { ...prev, chats: [...prevChats, newMessage] };
        });
      }
    } catch (err) {
      console.error("error /send-chatting", err);
      // opcionális: visszarakhatod a message-be a szöveget hiba esetén
      // setMessage(text);
    }
  };

  const sendPhotoMessage = async (mediaUrl) => {
    if (!chatting || !mediaUrl || isSendingPhoto) return;
    setIsSendingPhoto(true);

    try {
      const responseSend = await axios.post("/send-chatting", {
        conversationid: chatting.conversationid,
        message: "",
        media: mediaUrl,
        conversation_name: chatting.conversation_name,
        to_citizenid: chatting.citizenid,
        is_group: chatting.is_group,
      });

      if (responseSend.data) {
        const newMessage = {
          time: "just now",
          message: "",
          media: mediaUrl,
          sender_citizenid: profile.citizenid,
          id: responseSend.data,
        };

        setChatting((prev) => {
          const prevChats = Array.isArray(prev?.chats) ? prev.chats : [];
          return { ...prev, chats: [...prevChats, newMessage] };
        });
      }
    } catch (err) {
      console.error("error photo flow", err);
    } finally {
      setIsSendingPhoto(false);
      closePhotoPicker();
    }
  };

  const deleteSelectedMessage = async () => {
    const id = deleteCtx?.msg?.id;
    const index = deleteCtx?.index;

    if (!id || typeof index !== "number") {
      closeDelete();
      return;
    }

    try {
      const response = await axios.post("/delete-message", { id });
      if (response.data) {
        setChatting((prev) => {
          const prevChats = Array.isArray(prev?.chats) ? prev.chats : [];
          if (!prevChats[index]) return prev;

          const nextChats = [...prevChats];
          nextChats[index] = { ...nextChats[index], is_deleted: true };
          return { ...prev, chats: nextChats };
        });
      }
    } catch (err) {
      console.error("error /delete-message", err);
    } finally {
      closeDelete();
    }
  };

  const startCall = async () => {
    if (!chatting || chatting.is_group) return;

    try {
      await axios.post("/start-call", {
        from_avatar: profile.avatar,
        from_phone_number: profile.phone_number,
        to_phone_number: chatting.phone_number,
      });
    } catch (err) {
      console.error("error /start-call", err);
    }
  };

  if (!isShow) return null;

  return (
    <div className="relative flex flex-col w-full h-full">
      {/* Delete overlay */}
      <div
        className={`absolute w-full z-20 ${isDeleteOpen ? "visible" : "invisible"}`}
        style={{
          height: resolution?.layoutHeight || 0,
          width: resolution?.layoutWidth || 0,
          backgroundColor: "rgba(31, 41, 55, 0.8)",
        }}
      >
        <div className="flex flex-col justify-center h-full w-full px-5">
          <div className="flex flex-col space-y-2 bg-slate-600 w-full rounded p-3">
            <span className="text-white text-sm font-semibold">Delete message?</span>
            <span className="text-white text-sm">
              {deleteCtx?.msg?.message === "" ? "Media" : deleteCtx?.msg?.message}
            </span>

            <div className="flex justify-end space-x-4">
              <button className="rounded text-sm text-white" onClick={closeDelete}>
                {t("cancel")}
              </button>
              <button className="rounded text-sm text-red-500" onClick={deleteSelectedMessage}>
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Photo picker overlay */}
      <div
        className={`absolute w-full z-30 ${isPhotoPickerOpen ? "visible" : "invisible"}`}
        style={{
          height: resolution?.layoutHeight || 0,
          width: resolution?.layoutWidth || 0,
          backgroundColor: "rgba(31, 41, 55, 0.8)",
        }}
      >
        <div className="flex flex-col h-full">
          <div className="flex items-center justify-between px-3 py-2 bg-black pt-8">
            <span className="text-sm text-white font-semibold">{t("menu_photos")}</span>
            <button className="text-sm text-white" onClick={closePhotoPicker}>
              {t("cancel")}
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-3">
            {isLoadingPhotos ? (
              <LoadingComponent />
            ) : Array.isArray(photos) && photos.length ? (
              <div className="grid grid-cols-3 gap-2">
                {photos.map((p, idx) => (
                  <div
                    key={p.id || p.photo || idx}
                    className="relative cursor-pointer"
                    onClick={() => sendPhotoMessage(p.photo)}
                  >
                    <img
                      className="w-full h-20 rounded object-cover"
                      src={p.photo}
                      alt=""
                      onError={(e) => {
                        e.target.src = "./images/noimage.jpg";
                      }}
                    />
                    <span className="absolute bottom-1 left-1 bg-black/60 text-[10px] text-white px-1 rounded">
                      {p.created_at}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex h-full items-center justify-center text-white text-xs text-center px-4">
                {photoError || "No photos available"}
              </div>
            )}
          </div>
        </div>
      </div>

      {chatting == undefined ? (
        <LoadingComponent />
      ) : (
        <>
          {/* Header */}
          <div className="absolute top-0 flex w-full justify-between py-1.5 bg-black pt-8 z-10">
            <div className="flex items-center px-2 space-x-2 cursor-pointer">
              <MdArrowBackIosNew
                className="text-lg text-blue-500"
                onClick={() => {
                  nui("phone:setMessagesOpen", { open: false }).catch(() => {});
                  setMenu(MENU_MESSAGE);
                }}
              />

              <img
                src={chatting.avatar}
                className="w-8 h-8 object-cover rounded-full"
                alt=""
                onError={(e) => {
                  e.target.src = "./images/noimage.jpg";
                }}
              />

              <div className="flex flex-col">
                <div className="text-sm text-white line-clamp-1 font-medium">
                  {chatting.conversation_name}
                </div>
                <span className="text-xss font-light text-gray-400">
                  {t("last_seen", [chatting.last_seen])}
                </span>
              </div>
            </div>

            {!chatting.is_group ? (
              <div
                className="flex items-center px-2 text-white cursor-pointer hover:text-green-600"
                onClick={startCall}
              >
                <MdOutlinePhone className="text-lg" />
              </div>
            ) : null}
          </div>

          {/* Chat list */}
          <div className="flex flex-col w-full h-full text-white overflow-y-auto" style={{ paddingTop: 60 }}>
            <div className="flex-1 justify-between flex flex-col h-full">
              <div className="no-scrollbar flex flex-col space-y-4 p-3 overflow-y-auto pb-12">
                {chatsList.map((v, i) => {
                  const isMine = v.sender_citizenid == profile.citizenid;
                  return (
                    <Bubble
                      key={i}
                      v={v}
                      i={i}
                      isMine={isMine}
                      maxWidthPx={maxBubbleWidth}
                      onPressProps={onPressChat}
                    />
                  );
                })}
                <div ref={messagesEndRef} />
              </div>
            </div>
          </div>

          {/* Input */}
          <div className="absolute bottom-0 bg-black flex items-center w-full pb-5 pt-2">
            <div
              className={`flex flex-wrap items-center text-white ml-2 mr-2 cursor-pointer ${
                isSendingPhoto ? "opacity-50 pointer-events-none" : ""
              }`}
              onClick={openPhotoPicker}
            >
              <MdAttachFile className="text-xl" />
            </div>

            <div className="w-full">
              <input
                type="text"
                placeholder="Type your message..."
                className="w-full text-xs text-white flex-1 border border-gray-700 focus:outline-none rounded-full px-2 py-1 bg-[#3B3B3B]"
                value={message}
                autoComplete="off"
                onChange={(e) => setMessage(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") sendTextMessage();
                }}
              />
            </div>

            <div
              onClick={sendTextMessage}
              className="flex items-center bg-[#33C056] text-black rounded-full p-1.5 ml-2 mr-2 hover:bg-[#134d37] cursor-pointer text-white"
            >
              <MdSend className="text-sm" />
            </div>
          </div>
        </>
      )}
    </div>
  );
};


export default MessageChattingComponent;
