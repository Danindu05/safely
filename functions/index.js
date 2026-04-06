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
          const snapshot = await firestore.collection("users").doc(guardianId).get();
          return {guardianId, snapshot};
        } catch (error) {
          logger.error("Failed to load guardian profile.", {
            alertId,
            guardianId,
            error: error instanceof Error ? error.message : String(error),
          });
          return {guardianId, snapshot: null};
        }
      }),
    );

    const tokens = [];
    for (const item of guardianSnapshots) {
      const guardianSnapshot = item.snapshot;
      if (!guardianSnapshot || !guardianSnapshot.exists) {
        logger.info("Skipping guardian because the user document was not found.", {
          alertId,
          guardianId: item.guardianId,
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

    const message = {
      notification: {
        title: "\uD83D\uDEA8 Emergency Alert",
        body: `${safemateName} triggered an alert`,
      },
      data: {
        alertId,
        userId,
        type: String(alert.type ?? ""),
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
