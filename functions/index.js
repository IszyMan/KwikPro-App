/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
//const {onRequest} = require("firebase-functions/https");
//const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyTechnicianOnNewRequest = functions.firestore
  .document("requests/{requestId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const technicianId = data.technicianId;

    if (!technicianId) return null;

    const techDoc = await admin.firestore()
      .collection("technicians")
      .doc(technicianId)
      .get();

    if (!techDoc.exists) return null;

    const techData = techDoc.data();
    const token = techData.fcmToken;

    if (!token) return null;

    // 🔔 SEND PUSH
    await admin.messaging().send({
      token: token,
      notification: {
        title: "New Job Request 🔧",
        body: `${data.service} request near you`,
      },
      data: {
        requestId: context.params.requestId,
        type: "request",
      },
    });

    // 🔔 SAVE IN-APP NOTIFICATION
    await admin.firestore()
      .collection("technicians")
      .doc(technicianId)
      .collection("notifications")
      .add({
        title: "New Job Request",
        body: `${data.service} request near you`,
        type: "request",
        requestId: context.params.requestId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return null;
  });
