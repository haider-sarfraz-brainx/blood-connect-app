const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Optional: limit maximum concurrent function instances
functions.setGlobalOptions({maxInstances: 10});

// Send FCM notification
exports.sendNotification = functions.https.onRequest(async (req, res) => {
  try {
    const {token, title, body} = req.body;

    const message = {
      notification: {title, body},
      token,
    };

    const response = await admin.messaging().send(message);

    res.status(200).send({success: true, response});
  } catch (error) {
    res.status(500).send({success: false, error: error.message});
  }
});
