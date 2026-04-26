const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const USERS_COLLECTION = "users";
const SETTINGS_COLLECTION = "settings";
const ALERTS_CHANNEL_ID = "safely_alerts";
const CLICK_ACTION = "FLUTTER_NOTIFICATION_CLICK";

exports.sendGuardianAlert = onDocumentCreated(
  "alerts/{alertId}",
  async (event) => {
    const snapshot = event.data;
    const alertId = event.params.alertId;

    if (!snapshot) {
      logger.warn("sendGuardianAlert triggered without snapshot data.", {
        alertId,
      });
      return;
    }

    const alert = snapshot.data() || {};
    const userId = normalizeString(alert.userId);
    const guardianIds = normalizeStringArray(alert.guardianIds);
    const alertType = normalizeString(alert.type) || "sos";

    console.log("sendGuardianAlert triggered", {
      alertId,
      userId,
      guardianIds,
      alertType,
    });

    if (!userId || guardianIds.length === 0) {
      logger.info("Alert skipped because recipients are missing.", {
        alertId,
        userId,
        guardianCount: guardianIds.length,
      });
      return;
    }

    const safemateName = await loadSafemateName(userId, alertId);
    const notificationContent = buildNotificationContent(
      alertType,
      safemateName,
      alert,
    );

    let successCount = 0;
    let failureCount = 0;

    for (const guardianId of guardianIds) {
      let token = "";

      try {
        console.log("Loading guardian document from path:", `users/${guardianId}`);
        const guardianDoc = await db.collection(USERS_COLLECTION).doc(guardianId).get();

        if (!guardianDoc.exists) {
          console.log("Guardian not found:", guardianId);
          continue;
        }

        const guardianData = guardianDoc.data() || {};
        token = normalizeString(guardianData.fcmToken);

        if (!token) {
          console.log("No token for guardian:", guardianId);
          continue;
        }

        const settings = await loadGuardianSettings(guardianId, alertId);
        if (!notificationsEnabledForAlert(settings, alertType)) {
          console.log("Notification category disabled for guardian:", guardianId);
          continue;
        }

        console.log("Sending to:", guardianId);
        console.log("Token:", token);

        const messageId = await messaging.send(
          buildMessageForToken({
            token,
            alertId,
            userId,
            alertType,
            alert,
            notificationContent,
          }),
        );

        successCount += 1;
        console.log("Notification sent successfully:", {
          guardianId,
          messageId,
        });
      } catch (error) {
        failureCount += 1;
        console.error("Notification send failed for guardian:", guardianId, error);

        if (token && isInvalidTokenError(error)) {
          await clearGuardianTokenIfUnchanged(guardianId, token);
        }
      }
    }

    logger.info("Guardian alert notification batch completed.", {
      alertId,
      attempted: guardianIds.length,
      successCount,
      failureCount,
    });
  },
);

exports.sendTestNotification = onCall(async (request) => {
  const uid = normalizeString(request.auth && request.auth.uid);
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to send a test notification.",
    );
  }

  const userSnapshot = await db.collection(USERS_COLLECTION).doc(uid).get();
  if (!userSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "No user profile was found for the authenticated account.",
    );
  }

  const token = normalizeString(userSnapshot.get("fcmToken"));
  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "No FCM token is stored for this account.",
    );
  }

  const name = normalizeString(userSnapshot.get("name")) || "Safely user";
  console.log("Sending test notification to:", uid);
  console.log("Token:", token);

  const messageId = await messaging.send({
    token,
    notification: {
      title: "Safely test notification",
      body: `Push delivery is working for ${name}.`,
    },
    data: {
      type: "test",
      click_action: CLICK_ACTION,
    },
    android: {
      priority: "high",
      notification: {
        channelId: ALERTS_CHANNEL_ID,
        clickAction: CLICK_ACTION,
        priority: "max",
        defaultSound: true,
      },
    },
  });

  logger.info("Test notification sent.", {
    uid,
    token,
    messageId,
  });

  return {
    success: true,
    messageId,
  };
});

async function loadSafemateName(userId, alertId) {
  let safemateName = "A Safemate";

  try {
    const userSnapshot = await db.collection(USERS_COLLECTION).doc(userId).get();
    if (!userSnapshot.exists) {
      console.log("Safemate user document not found:", userId);
      return safemateName;
    }

    const candidateName = normalizeString(userSnapshot.get("name"));
    if (candidateName) {
      safemateName = candidateName;
    }
  } catch (error) {
    console.error("Failed to load Safemate profile:", {
      alertId,
      userId,
      error: error instanceof Error ? error.message : String(error),
    });
  }

  return safemateName;
}

async function loadGuardianSettings(guardianId, alertId) {
  try {
    const settingsSnapshot =
      await db.collection(SETTINGS_COLLECTION).doc(guardianId).get();
    if (!settingsSnapshot.exists) {
      return {};
    }
    return settingsSnapshot.data() || {};
  } catch (error) {
    console.error("Failed to load guardian settings. Defaulting to enabled.", {
      alertId,
      guardianId,
      error: error instanceof Error ? error.message : String(error),
    });
    return {};
  }
}

function buildMessageForToken({
  token,
  alertId,
  userId,
  alertType,
  alert,
  notificationContent,
}) {
  return {
    token,
    notification: {
      title: notificationContent.title,
      body: notificationContent.body,
    },
    data: {
      alertId,
      userId,
      type: alertType,
      title: normalizeString(alert.title),
      description: normalizeString(alert.description),
      locationLat: alert.locationLat == null ? "" : String(alert.locationLat),
      locationLng: alert.locationLng == null ? "" : String(alert.locationLng),
      click_action: CLICK_ACTION,
    },
    android: {
      priority: "high",
      notification: {
        channelId: ALERTS_CHANNEL_ID,
        clickAction: CLICK_ACTION,
        priority: "max",
        defaultSound: true,
      },
    },
  };
}

async function clearGuardianTokenIfUnchanged(guardianId, invalidToken) {
  try {
    const userRef = db.collection(USERS_COLLECTION).doc(guardianId);
    const userSnapshot = await userRef.get();
    if (!userSnapshot.exists) {
      return;
    }

    const currentToken = normalizeString(userSnapshot.get("fcmToken"));
    if (currentToken !== invalidToken) {
      logger.info("Skipped FCM token cleanup because the stored token already changed.", {
        guardianId,
        invalidToken,
      });
      return;
    }

    await userRef.set({fcmToken: null}, {merge: true});
    logger.warn("Removed invalid FCM token from guardian profile.", {
      guardianId,
      invalidToken,
    });
  } catch (error) {
    logger.error("Failed to remove invalid FCM token.", {
      guardianId,
      invalidToken,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

function isInvalidTokenError(error) {
  if (!error || typeof error.code !== "string") {
    return false;
  }

  return (
    error.code === "messaging/invalid-registration-token" ||
    error.code === "messaging/registration-token-not-registered"
  );
}

function notificationsEnabledForAlert(settings, alertType) {
  const valueOrDefault = (key) => {
    if (!settings || typeof settings[key] !== "boolean") {
      return true;
    }
    return settings[key];
  };

  switch (alertType) {
    case "sos":
      return valueOrDefault("sosNotificationsEnabled");
    case "low_battery":
      return valueOrDefault("batteryNotificationsEnabled");
    case "geofence":
    case "route_deviation":
      return valueOrDefault("geofenceNotificationsEnabled");
    case "missed_checkin":
    case "manual_checkin":
      return valueOrDefault("checkInNotificationsEnabled");
    default:
      return true;
  }
}

function buildNotificationContent(alertType, safemateName, alert) {
  switch (alertType) {
    case "sos":
      return {
        title: "Emergency Alert",
        body: `${safemateName} triggered SOS`,
      };
    case "low_battery":
      return {
        title: "Low Battery Alert",
        body: normalizeString(alert.description) ||
          `${safemateName}'s battery is critical`,
      };
    case "geofence":
      return {
        title: "Unsafe Zone Alert",
        body: normalizeString(alert.description) ||
          `${safemateName} entered a flagged area`,
      };
    case "missed_checkin":
      return {
        title: "Missed Check-in",
        body: normalizeString(alert.description) ||
          `${safemateName} did not respond`,
      };
    case "manual_checkin":
      return {
        title: "Check-in Update",
        body: normalizeString(alert.description) ||
          `${safemateName} checked in`,
      };
    case "route_deviation":
      return {
        title: "Route Alert",
        body: normalizeString(alert.description) ||
          `${safemateName} may have gone off route`,
      };
    default:
      return {
        title: "Emergency Alert",
        body: normalizeString(alert.description) ||
          `${safemateName} triggered an alert`,
      };
  }
}

function normalizeString(value) {
  if (typeof value !== "string") {
    return "";
  }

  return value.trim();
}

function normalizeStringArray(values) {
  if (!Array.isArray(values)) {
    return [];
  }

  return [...new Set(
    values
      .map((value) => normalizeString(value))
      .filter((value) => value.length > 0),
  )];
}
