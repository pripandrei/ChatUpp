/* eslint-disable no-unused-vars */
/* eslint-disable max-len */
/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const firestore = admin.firestore();
const rtdb = admin.database();

// exports.syncToFirestore = functions.database.ref("/users")
//     .onWrite(async (change, context) => {
//       const data = change.after.val();
//       const id = context.params.id;

//       if (data) {
//         await firestore.collection("users").doc(id).set(data);
//       } else {
//         await firestore.collection("users").doc(id).delete();
//       }
//     });


// exports.syncFirestoreToRealtime = functions.firestore.document("/users")
//     .onWrite(async (change, context) => {
//       const afterData = change.after.data(); // Data after the change
//       const beforeData = change.before.data(); // Data before the change

//       const docId = context.params.id;

//       // Handle create or update
//       if (afterData) {
//         await rtdb.ref(`/users/${docId}`).set(afterData);
//       }

//       // Handle delete
//       if (!change.after.exists) {
//         await rtdb.ref(`/users/${docId}`).remove();
//       }

//       return null;
//     });


// exports.syncFirestoreToRealtime = functions.firestore.document("users")
//     .onWrite(async (change, context) => {
//       const afterData = change.after.data(); // Data after the change
//       const beforeData = change.before.data(); // Data before the change

//       if (!change.after.exists) {
//         // Handle delete
//         await rtdb.ref("/users" + context.params.id).remove();
//         return null;
//       }

//       if (!change.before.exists || JSON.stringify(afterData) !== JSON.stringify(beforeData)) {
//         // Handle create or update
//         await rtdb.ref("/users" + context.params.id).set(afterData);
//       }

//       return null;
//     });


exports.syncRealtimeToFirestore = functions.database.ref("/users")
    .onWrite(async (change, context) => {
      const afterData = change.after.val(); // Data after the change
      const beforeData = change.before.val(); // Data before the change

      // Handle create or update for all child nodes
      if (afterData) {
        const updates = Object.keys(afterData).map(async (key) => {
          const data = afterData[key];
          await firestore.collection("users").doc(key).update(data);
        });
        await Promise.all(updates);
      }

      // Handle delete for all child nodes
      if (beforeData) {
        const deletes = Object.keys(beforeData)
            .filter((key) => !afterData || !afterData[key])
            .map(async (key) => {
              await firestore.collection("users").doc(key).delete();
            });
        await Promise.all(deletes);
      }

      return null;
    });
