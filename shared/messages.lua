local resourceName = GetCurrentResourceName()
local defaultLang = (Config and Config.Locale) or "en"

local function loadLocales()
  local content = LoadResourceFile(resourceName, 'web/src/locale.json')
  if not content then return {} end

  local ok, data = pcall(json.decode, content)
  if not ok or type(data) ~= 'table' then
    return {}
  end

  return data
end

local locales = loadLocales()

local function pick(serverLocales, section, key, fallback)
  local group = serverLocales[section]
  if group and group[key] then
    return group[key]
  end
  return fallback
end

local function messagesForLang(lang)
  local langData = locales[lang] or locales.en or {}
  local defaultServer = (locales.en and locales.en.server) or {}
  local serverLocales = langData.server or {}

  local function msg(section, key, fallback)
    return pick(serverLocales, section, key, pick(defaultServer, section, key, fallback))
  end

  return {
    Ads = {
      NewAdPosted = msg('ads', 'new_ad_posted', 'New ads posted!'),
    },

    Bank = {
      PayFailed = msg('bank', 'pay_failed', 'Failed to pay bill'),
      BalanceNotEnough = msg('bank', 'balance_not_enough', 'Balance is not enough'),
      InvoicePaid = msg('bank', 'invoice_paid', 'Success pay bill'),
      TransferCheckFailed = msg('bank', 'transfer_check_failed', 'Failed to check receiver!'),
      IbanNotRegistered = msg('bank', 'iban_not_registered', 'IBAN not registered!'),
      CannotSelfTransfer = msg('bank', 'cannot_self_transfer', 'Cannot transfer to your self!'),
      ReceiverOffline = msg('bank', 'receiver_offline', 'Receiver is offline!'),
      TransferSuccess = msg('bank', 'transfer_success', 'Successful Money Transfer'),
      TransferReceived = msg('bank', 'transfer_received', 'Received Money Transfer'),
      TransferEmailSubject = msg('bank', 'transfer_email_subject', 'Successful Money Transfer Confirmation'),
      TransferEmailBody = msg('bank', 'transfer_email_body', [[
We are pleased to inform you that your recent money transfer has been successfully completed.

Here are the details of the transaction:

Total: %s
IBAN : %s
Note : %s

If you have any questions or need further assistance, please don't hesitate to reach out.

Thank you for choosing our services!
      ]]),
    },

    Calls = {
      PhoneNotRegistered = msg('calls', 'phone_not_registered', 'Phone number not registered!'),
      PersonBusy = msg('calls', 'person_busy', 'Person is busy!'),
      PersonInCall = msg('calls', 'person_in_call', 'Person in a call!'),
      PersonUnavailable = msg('calls', 'person_unavailable', 'Person is unavailable to call!'),
      CallDeclined = msg('calls', 'call_declined', 'Call declined!'),
      CallEnded = msg('calls', 'call_ended', 'Call ended!'),
    },

    Chat = {
      CannotChatSelf = msg('chat', 'cannot_chat_self', 'Cannot chat to your self!'),
      InvalidPhone = msg('chat', 'invalid_phone', 'Invalid phone number!'),
    },

    Contact = {
      DeleteSuccess = msg('contact', 'delete_success', 'Success delete contact!'),
      PhoneNotRegistered = msg('contact', 'phone_not_registered', 'Phone Number not registered!'),
      DuplicateContact = msg('contact', 'duplicate_contact', 'Duplicate contact (%s)!'),
      SaveSuccess = msg('contact', 'save_success', 'Success save contact!'),
      RequestReceived = msg('contact', 'request_received', 'New contact request received!'),
      UpdateSuccess = msg('contact', 'update_success', 'Success update contact!'),
    },

    InetMax = {
      BankNotEnough = msg('inetmax', 'bank_not_enough', 'Bank Balance is not enough'),
      PurchaseSuccess = msg('inetmax', 'purchase_success', 'Purchase Successful'),
      EmailSubject = msg('inetmax', 'email_subject', 'Your Internet Data Package Purchase Confirmation'),
      EmailBody = msg('inetmax', 'email_body', [[
Thank you for choosing our services! We are pleased to confirm that your purchase of the internet data package has been successful.

Total: %s
Rate : $%s / %sKB
Status : %s

Your data package will be activated shortly, and you'll receive an email with all the necessary details. If you have any questions or need further assistance, please don't hesitate to reach out.

Thank you for being a valued customer!
      ]]),
    },

    Loops = {
      SignupWelcome = msg('loops', 'signup_welcome', "Awesome, let's signin!"),
      SignupEmailSubject = msg('loops', 'signup_email_subject', 'Your account %s Has Been Created'),
      SignupEmailBody = msg('loops', 'signup_email_body', [[
Welcome aboard!

Username: @%s
Fullname : %s
Password : %s
Phone Number : %s

We're thrilled to have you join our community. Your Loops account signup was successful created, and you're now all set to explore everything.
To get started, log in to your account and check out all tweets.

We're excited to see you dive in and start exploring. Welcome to the Loopsverse!
      ]]),
      ReloginToPost = msg('loops', 'relogin_to_post', 'Please re-login to post tweet!'),
      ReloginToComment = msg('loops', 'relogin_to_comment', 'Please re-login to comment tweet!'),
      UsernameUnavailable = msg('loops', 'username_unavailable', '@%s not available'),
      UpdateSuccess = msg('loops', 'update_success', 'Success update account!'),
      UpdateFail = msg('loops', 'update_fail', 'Please try again later!'),
      NotifyReply = msg('loops', 'notify_reply', '@%s reply on your tweet'),
    },

    News = {
      NewsNotify = msg('news', 'news_notify', 'News from %s'),
    },

    Photos = {},

    Profile = {
      UpdateSuccess = msg('profile', 'update_success', 'Success updated!'),
    },

    Services = {
      Label = msg('services', 'label', 'Services'),
      MessageSent = msg('services', 'message_sent', 'Message sent to the service!'),
      MessageSolved = msg('services', 'message_solved', 'Service message solved!'),
    },
  }
end

-- Expose messages table globally so callbacks can access Msg without requires.
Msg = messagesForLang(defaultLang)

return Msg
