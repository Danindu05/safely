const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

initializeApp();

const firestore = getFirestore();
const messaging = getMessaging();

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
    const userId = typeof alert.userId === "string" ? alert.userId.trim() : "";
    const guardianIds = Array.isArray(alert.guardianIds) ?
      [...new Set(alert.guardianIds.filter((value) => typeof value === "string" && value.trim().length > 0))] :
      [];

    if (!userId || guardianIds.length === 0) {
      logger.info("Alert skipped because recipients are missing.", {
        alertId,
        userId,
        guardianCount: guardianIds.length,
      });
      return;
    }

    let safemateName = "A Safemate";
    try {
      const safemateSnapshot = await firestore.collection("users").doc(userId).get();
      if (safemateSnapshot.exists) {
        const candidateName = safemateSnapshot.get("name");
        if (typeof candidateName === "string" && candidateName.trim().length > 0) {
          safemateName = candidateName.trim();
        }
      }
    } catch (error) {
      logger.error("Failed to load Safemate profile for notification body.", {
        alertId,
        userId,
        error: error instanceof Error ? error.message : String(error),
      });
    }

    const guardianSnapshots = await Promise.all(
      guardianIds.map(async (guardianId) => {
        try {
          const [snapshot, settingsSnapshot] = await Promise.all([
            firestore.collection("users").doc(guardianId).get(),
            firestore.collection("settings").doc(guardianId).get(),
          ]);
          return {guardianId, snapshot, settingsSnapshot};
        } catch (error) {
          logger.error("Failed to load guardian profile.", {
            alertId,
            guardianId,
            error: error instanceof Error ? error.message : String(error),
          });
          return {guardianId, snapshot: null, settingsSnapshot: null};
        }
      }),
    );

    const tokens = [];
    const alertType = String(alert.type ?? "");
    for (const item of guardianSnapshots) {
      const guardianSnapshot = item.snapshot;
      if (!guardianSnapshot || !guardianSnapshot.exists) {
        logger.info("Skipping guardian because the user document was not found.", {
          alertId,
          guardianId: item.guardianId,
        });
        continue;
      }

      const settings = item.settingsSnapshot && item.settingsSnapshot.exists ?
        item.settingsSnapshot.data() :
        {};
      if (!notificationsEnabledForAlert(settings, alertType)) {
        logger.info("Skipping guardian because notification category is disabled.", {
          alertId,
          guardianId: item.guardianId,
          alertType,
        });
        continue;
      }

      const token = guardianSnapshot.get("fcmToken");
      if (typeof token !== "string" || token.trim().length === 0) {
        logger.info("Skipping guardian because no FCM token is stored.", {
          alertId,
          guardianId: item.guardianId,
        });
        continue;
      }

      tokens.push(token.trim());
    }

    if (tokens.length === 0) {
      logger.info("No guardian notification tokens were available.", {
        alertId,
        userId,
      });
      return;
    }

    const notificationContent = buildNotificationContent(
      alertType,
      safemateName,
      alert,
    );

    const message = {
      notification: {
        title: notificationContent.title,
        body: notificationContent.body,
      },
      data: {
        alertId,
        userId,
        type: alertType,
        title: String(alert.title ?? ""),
        description: String(alert.description ?? ""),
        locationLat: alert.locationLat == null ? "" : String(alert.locationLat),
        locationLng: alert.locationLng == null ? "" : String(alert.locationLng),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "safely_alerts",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          priority: "max",
          defaultSound: true,
        },
      },
      tokens,
    };

    try {
      const response = await messaging.sendEachForMulticast(message);

      response.responses.forEach((result, index) => {
        const token = tokens[index];
        if (result.success) {
          logger.info("Guardian notification sent.", {
            alertId,
            token,
            messageId: result.messageId,
          });
          return;
        }

        logger.error("Guardian notification failed.", {
          alertId,
          token,
          error: result.error ? result.error.message : "Unknown messaging error",
        });
      });

      logger.info("Guardian alert notification batch completed.", {
        alertId,
        attempted: tokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    } catch (error) {
      logger.error("sendGuardianAlert failed while sending notifications.", {
        alertId,
        attempted: tokens.length,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);

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
        body: typeof alert.description === "string" && alert.description.trim() ?
          alert.description.trim() :
          "Battery is critically low and last location was shared.",
      };
    case "geofence":
      return {
        title: `Unsafe Zone Alert — ${safemateName} entered a flagged area`,
        body: typeof alert.description === "string" && alert.description.trim() ?
          alert.description.trim() :
          "Location may need attention.",
      };
    case "missed_checkin":
      return {
        title: `Missed Check-in — ${safemateName} did not respond`,
        body: typeof alert.description === "string" && alert.description.trim() ?
          alert.description.trim() :
          "A scheduled safety confirmation was missed.",
      };
    case "manual_checkin":
      return {
        title: `Check-in Update — ${safemateName} checked in`,
        body: typeof alert.description === "string" && alert.description.trim() ?
          alert.description.trim() :
          "A reassurance update is available.",
      };
    case "route_deviation":
      return {
        title: `Route Alert — ${safemateName} may have gone off route`,
        body: typeof alert.description === "string" && alert.description.trim() ?
          alert.description.trim() :
          "Journey monitoring noticed a major route change.",
      };
    default:
      return {
        title: `Safely Alert — ${safemateName} needs attention`,
        body: typeof alert.description === "string" && alert.description.trim() ?
          alert.description.trim() :
          "Open Safely to review the latest alert.",
      };
  }
}
