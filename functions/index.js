const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

initializeApp();

const firestore = getFirestore();
const messaging = getMessaging();
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

    const alert = snapshot.data();
    const userId = normalizeString(alert.userId);
    const guardianIds = normalizeStringArray(alert.guardianIds);
    const alertType = normalizeString(alert.type);

    if (!userId || guardianIds.length === 0) {
      logger.info("Alert skipped because recipients are missing.", {
        alertId,
        userId,
        guardianCount: guardianIds.length,
      });
      return;
    }

    const safemateName = await loadSafemateName(userId, alertId);
    const guardianRecipients = await loadGuardianRecipients({
      alertId,
      guardianIds,
      alertType,
    });

    if (guardianRecipients.length === 0) {
      logger.info("No guardian notification tokens were available.", {
        alertId,
        userId,
        alertType,
      });
      return;
    }

    const notificationContent = buildNotificationContent(
      alertType,
      safemateName,
      alert,
    );

    const results = await Promise.allSettled(
      guardianRecipients.map((recipient) =>
        sendPushToGuardian({
          recipient,
          alertId,
          userId,
          alertType,
          alert,
          notificationContent,
        }),
      ),
    );

    let successCount = 0;
    let failureCount = 0;

    results.forEach((result, index) => {
      const recipient = guardianRecipients[index];
      if (result.status === "fulfilled") {
        successCount += 1;
        logger.info("Guardian notification sent.", {
          alertId,
          guardianId: recipient.guardianId,
          token: recipient.token,
          messageId: result.value,
        });
        return;
      }

      failureCount += 1;
      logger.error("Guardian notification failed.", {
        alertId,
        guardianId: recipient.guardianId,
        token: recipient.token,
        error: result.reason instanceof Error ?
          result.reason.message :
          String(result.reason),
        code: result.reason && result.reason.code ? result.reason.code : null,
      });
    });

    logger.info("Guardian alert notification batch completed.", {
      alertId,
      attempted: guardianRecipients.length,
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

  const userSnapshot = await firestore.collection(USERS_COLLECTION).doc(uid).get();
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
    const safemateSnapshot =
      await firestore.collection(USERS_COLLECTION).doc(userId).get();
    if (safemateSnapshot.exists) {
      const candidateName = normalizeString(safemateSnapshot.get("name"));
      if (candidateName) {
        safemateName = candidateName;
      }
    }
  } catch (error) {
    logger.error("Failed to load Safemate profile for notification body.", {
      alertId,
      userId,
      error: error instanceof Error ? error.message : String(error),
    });
  }

  return safemateName;
}

async function loadGuardianRecipients({alertId, guardianIds, alertType}) {
  const loadedRecipients = await Promise.all(
    guardianIds.map(async (guardianId) => {
      try {
        const [userSnapshot, settingsSnapshot] = await Promise.all([
          firestore.collection(USERS_COLLECTION).doc(guardianId).get(),
          firestore.collection(SETTINGS_COLLECTION).doc(guardianId).get(),
        ]);

        if (!userSnapshot.exists) {
          logger.info("Skipping guardian because the user document was not found.", {
            alertId,
            guardianId,
          });
          return null;
        }

        const settings = settingsSnapshot.exists ? settingsSnapshot.data() : {};
        if (!notificationsEnabledForAlert(settings, alertType)) {
          logger.info("Skipping guardian because notification category is disabled.", {
            alertId,
            guardianId,
            alertType,
          });
          return null;
        }

        const token = normalizeString(userSnapshot.get("fcmToken"));
        if (!token) {
          logger.info("Skipping guardian because no FCM token is stored.", {
            alertId,
            guardianId,
          });
          return null;
        }

        logger.info("Prepared guardian notification recipient.", {
          alertId,
          guardianId,
          token,
        });

        return {
          guardianId,
          token,
        };
      } catch (error) {
        logger.error("Failed to load guardian profile.", {
          alertId,
          guardianId,
          error: error instanceof Error ? error.message : String(error),
        });
        return null;
      }
    }),
  );

  return loadedRecipients.filter(Boolean);
}

async function sendPushToGuardian({
  recipient,
  alertId,
  userId,
  alertType,
  alert,
  notificationContent,
}) {
  logger.info("Sending guardian notification.", {
    alertId,
    guardianId: recipient.guardianId,
    token: recipient.token,
  });

  try {
    return await messaging.send(
      buildMessageForToken({
        token: recipient.token,
        alertId,
        userId,
        alertType,
        alert,
        notificationContent,
      }),
    );
  } catch (error) {
    if (isInvalidTokenError(error)) {
      await clearGuardianTokenIfUnchanged(recipient.guardianId, recipient.token);
    }
    throw error;
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
    const userRef = firestore.collection(USERS_COLLECTION).doc(guardianId);
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
        title: `Emergency Alert — ${safemateName} triggered SOS`,
        body: "Immediate attention may be needed.",
      };
    case "low_battery":
      return {
        title: `Low Battery Alert — ${safemateName}'s battery is critical`,
        body: normalizeString(alert.description) ||
          "Battery is critically low and last location was shared.",
      };
    case "geofence":
      return {
        title: `Unsafe Zone Alert — ${safemateName} entered a flagged area`,
        body: normalizeString(alert.description) ||
          "Location may need attention.",
      };
    case "missed_checkin":
      return {
        title: `Missed Check-in — ${safemateName} did not respond`,
        body: normalizeString(alert.description) ||
          "A scheduled safety confirmation was missed.",
      };
    case "manual_checkin":
      return {
        title: `Check-in Update — ${safemateName} checked in`,
        body: normalizeString(alert.description) ||
          "A reassurance update is available.",
      };
    case "route_deviation":
      return {
        title: `Route Alert — ${safemateName} may have gone off route`,
        body: normalizeString(alert.description) ||
          "Journey monitoring noticed a major route change.",
      };
    default:
      return {
        title: `Safely Alert — ${safemateName} needs attention`,
        body: normalizeString(alert.description) ||
          "Open Safely to review the latest alert.",
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

  return [...new Set(values
    .map((value) => normalizeString(value))
    .filter((value) => value.length > 0))];
}
