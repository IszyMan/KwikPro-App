/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

 const axios = require("axios");
 const {onCall} = require("firebase-functions/v2/https");

 const {onDocumentCreated} = require("firebase-functions/v2/firestore");
 const {defineSecret} = require("firebase-functions/params");

 const googleApiKey = defineSecret("GOOGLE_MAPS_API_KEY");

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


const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyTechnicianOnNewRequest = onDocumentCreated(
  "requests/{requestId}",
  async (event) => {
    const snap = event.data;

    if (!snap) return;

    const data = snap.data();

    const technicianId = data.technicianId;

    if (!technicianId) return;

    const techDoc = await admin.firestore()
        .collection("technicians")
        .doc(technicianId)
        .get();

    if (!techDoc.exists) return;

    const techData = techDoc.data();

    const token = techData.fcmToken;

    if (!token) return;

    await admin.messaging().send({
      token,
      notification: {
        title: "New Job Request 🔧",
        body: `${data.service} request near you`,
      },
      data: {
        requestId: event.params.requestId,
        type: "request",
      },
    });

    await admin.firestore()
        .collection("technicians")
        .doc(technicianId)
        .collection("notifications")
        .add({
          title: "New Job Request",
          body: `${data.service} request near you`,
          type: "request",
          requestId: event.params.requestId,
          isRead: false,
          createdAt:
              admin.firestore.FieldValue.serverTimestamp(),
        });
  }
);
