const {onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

exports.sendOtp = onCall(async (request) => {
  const email = request.data.email;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await admin.firestore().collection("otps").doc(email).set({
    otp,
    createdAt: Date.now(),
  });

  await transporter.sendMail({
    from: '"Bae Window" <' + process.env.SMTP_USER + '>',
    to: email,
    subject: "Your OTP Code",
    text: `Your verification code is ${otp}`,
  });

  return {success: true};
});

exports.verifyOtp = onCall(async (request) => {
  const {email, otp} = request.data;
  const doc = await admin.firestore().collection("otps").doc(email).get();

  if (!doc.exists) {
    return {success: false, message: "OTP not found"};
  }

  const {otp: savedOtp, createdAt} = doc.data();

  if (Date.now() - createdAt > 5 * 60 * 1000) {
    return {success: false, message: "OTP expired"};
  }

  if (savedOtp !== otp) {
    return {success: false, message: "Invalid OTP"};
  }

  await admin.firestore().collection("users").doc(email).set(
      {isVerified: true},
      {merge: true},
  );

  return {success: true};
});

const DEFAULT_NOTIFICATION_SETTINGS = {
  newSnap: true,
  drawingNote: true,
  thinkingPulse: true,
  voiceFragment: true,
  taskCompleted: true,
  moodCheckIn: false,
  milestoneReminders: true,
  quietHoursEnabled: true,
  quietHoursStart: "11:00 PM",
  quietHoursEnd: "07:00 AM",
};

function parseClock(value) {
  const match = /^(\d{1,2}):(\d{2})\s*(AM|PM)$/i.exec(value || "");
  if (!match) return null;
  let hour = Number(match[1]) % 12;
  if (match[3].toUpperCase() === "PM") hour += 12;
  return hour * 60 + Number(match[2]);
}

function isQuietHours(userData) {
  const settings = {
    ...DEFAULT_NOTIFICATION_SETTINGS,
    ...(userData.notificationSettings || {}),
  };
  if (!settings.quietHoursEnabled) return false;

  const start = parseClock(settings.quietHoursStart);
  const end = parseClock(settings.quietHoursEnd);
  if (start === null || end === null || start === end) return false;

  const offset = Number(userData.notificationTimezoneOffsetMinutes || 0);
  const now = new Date(Date.now() + offset * 60 * 1000);
  const minutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  return start < end ?
    minutes >= start && minutes < end :
    minutes >= start || minutes < end;
}

async function getPartnerUid(pairId, senderUid) {
  if (!pairId) return null;
  const couple = await admin.firestore().collection("couples").doc(pairId).get();
  if (!couple.exists) return null;
  const data = couple.data();
  if (data.user1Uid === senderUid) return data.user2Uid || null;
  if (data.user2Uid === senderUid) return data.user1Uid || null;
  return null;
}

async function sendToUser({
  recipientUid,
  settingKey,
  title,
  body,
  type,
  route = "home",
  allowDuringQuietHours = false,
}) {
  const userRef = admin.firestore().collection("users").doc(recipientUid);
  const userSnapshot = await userRef.get();
  if (!userSnapshot.exists) return false;
  const userData = userSnapshot.data();
  const settings = {
    ...DEFAULT_NOTIFICATION_SETTINGS,
    ...(userData.notificationSettings || {}),
  };
  if (settings[settingKey] === false) return false;

  const tokens = [...new Set([
    ...(Array.isArray(userData.fcmTokens) ? userData.fcmTokens : []),
    ...(userData.fcmToken ? [userData.fcmToken] : []),
  ].filter(Boolean))];
  if (tokens.length === 0) return false;

  const quiet = !allowDuringQuietHours && isQuietHours(userData);
  const isPulse = settingKey === "thinkingPulse";
  const androidNotification = {
    channelId: isPulse ? "bae_pulse" : quiet ? "bae_quiet" : "bae_activity",
  };
  if (!quiet) androidNotification.sound = "default";
  if (isPulse) {
    androidNotification.vibrateTimingsMillis = [0, 280, 140, 360];
    androidNotification.defaultVibrateTimings = false;
  }

  const aps = {badge: 1};
  if (!quiet) aps.sound = "default";

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data: {
      type,
      route,
      quiet: String(quiet),
      title,
      body,
    },
    android: {
      priority: quiet ? "normal" : "high",
      notification: androidNotification,
    },
    apns: {
      headers: {"apns-priority": quiet ? "5" : "10"},
      payload: {aps},
    },
  });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    const code = result.error && result.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokens.push(tokens[index]);
    }
  });
  if (invalidTokens.length > 0) {
    await userRef.update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
    });
  }
  return true;
}

function changed(before, after, field) {
  return JSON.stringify(before[field] || null) !==
    JSON.stringify(after[field] || null);
}

exports.sendPartnerActivityNotifications = onDocumentUpdated(
    "users/{userId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      const senderUid = event.params.userId;
      if (after.pairStatus !== "paired" || !after.pairId) return;

      const partnerUid = await getPartnerUid(after.pairId, senderUid);
      if (!partnerUid) return;
      const senderName = after.nickname || after.name || "Your Bae";
      const notifications = [];

      if (changed(before, after, "latestSnapUrl")) {
        const snapType = String(after.latestSnapType || "Image").toLowerCase();
        if (snapType === "draw") {
          notifications.push(sendToUser({
            recipientUid: partnerUid,
            settingKey: "drawingNote",
            title: `✏️ Drawing from ${senderName}`,
            body: "Your Bae shared a new drawing with you.",
            type: "drawingNote",
          }));
        } else if (snapType === "voice") {
          notifications.push(sendToUser({
            recipientUid: partnerUid,
            settingKey: "voiceFragment",
            title: `🎙️ Voice from ${senderName}`,
            body: "A new voice fragment is waiting for you.",
            type: "voiceFragment",
          }));
        } else {
          notifications.push(sendToUser({
            recipientUid: partnerUid,
            settingKey: "newSnap",
            title: `📸 Snap from ${senderName}`,
            body: "Your Bae sent you a fresh moment.",
            type: "newSnap",
          }));
        }
      }

      if (changed(before, after, "latestPulse")) {
        notifications.push(sendToUser({
          recipientUid: partnerUid,
          settingKey: "thinkingPulse",
          title: `💖 ${senderName} is thinking of you`,
          body: "Your Bae just sent a love pulse.",
          type: "thinkingPulse",
          allowDuringQuietHours: true,
        }));
      }

      if (changed(before, after, "mood")) {
        const mood = after.mood || {};
        notifications.push(sendToUser({
          recipientUid: partnerUid,
          settingKey: "moodCheckIn",
          title: `${mood.emoji || "😊"} ${senderName}'s mood changed`,
          body: mood.text || "Your Bae shared a mood update.",
          type: "moodCheckIn",
        }));
      }

      if (changed(before, after, "latestTaskCompleted")) {
        const task = after.latestTaskCompleted || {};
        notifications.push(sendToUser({
          recipientUid: partnerUid,
          settingKey: "taskCompleted",
          title: `✅ ${senderName} completed a task`,
          body: task.title || "A shared task was completed.",
          type: "taskCompleted",
          route: "tasks",
        }));
      }

      if (changed(before, after, "latestLoveNote")) {
        const note = after.latestLoveNote || {};
        notifications.push(sendToUser({
          recipientUid: partnerUid,
          settingKey: "drawingNote",
          title: `💌 Note from ${senderName}`,
          body: note.text || "Your Bae shared a love note.",
          type: "drawingNote",
        }));
      }

      await Promise.all(notifications);
    },
);

function parseRelationshipDate(value) {
  const months = {
    Jan: 0, Feb: 1, Mar: 2, Apr: 3, May: 4, Jun: 5,
    Jul: 6, Aug: 7, Sep: 8, Oct: 9, Nov: 10, Dec: 11,
  };
  const match = /^([A-Z][a-z]{2})\s+(\d{1,2}),\s+(\d{4})$/.exec(value || "");
  if (!match || months[match[1]] === undefined) return null;
  return {month: months[match[1]], day: Number(match[2])};
}

exports.sendMilestoneReminders = onSchedule(
    {schedule: "0 9 * * *", timeZone: "Asia/Dhaka"},
    async () => {
      const users = await admin.firestore().collection("users")
          .where("pairStatus", "==", "paired").get();
      const writes = [];

      for (const userSnapshot of users.docs) {
        const user = userSnapshot.data();
        const relationshipDate = parseRelationshipDate(
            user.relationshipStartDate,
        );
        if (!relationshipDate) continue;

        const offset = Number(user.notificationTimezoneOffsetMinutes || 360);
        const localNow = new Date(Date.now() + offset * 60 * 1000);
        const todayUtc = Date.UTC(
            localNow.getUTCFullYear(),
            localNow.getUTCMonth(),
            localNow.getUTCDate(),
        );
        let targetYear = localNow.getUTCFullYear();
        let targetUtc = Date.UTC(
            targetYear,
            relationshipDate.month,
            relationshipDate.day,
        );
        if (targetUtc < todayUtc) {
          targetYear += 1;
          targetUtc = Date.UTC(
              targetYear,
              relationshipDate.month,
              relationshipDate.day,
          );
        }
        const daysUntil = Math.round((targetUtc - todayUtc) / 86400000);
        if (![7, 1, 0].includes(daysUntil)) continue;

        const deliveryKey = `${targetYear}-${daysUntil}`;
        if (user.lastMilestoneNotification === deliveryKey) continue;
        const body = daysUntil === 0 ?
          "Your relationship anniversary is today! ❤️" :
          `Your anniversary is in ${daysUntil} day${daysUntil === 1 ? "" : "s"}.`;
        writes.push(sendToUser({
          recipientUid: userSnapshot.id,
          settingKey: "milestoneReminders",
          title: "🎉 Relationship milestone",
          body,
          type: "milestoneReminders",
          route: "profile",
        }).then((sent) => sent ? userSnapshot.ref.set({
          lastMilestoneNotification: deliveryKey,
        }, {merge: true}) : null));
      }

      await Promise.all(writes);
    },
);
