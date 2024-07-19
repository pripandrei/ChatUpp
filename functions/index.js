/* eslint-disable camelcase */
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

          if (data.last_seen) {
            data.last_seen = admin.firestore.Timestamp.fromMillis(data.last_seen * 1000);
          }

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

// - creates user doc inside realtime database when a doc is created inside firestore database

exports.createUserInRealtimeDB = functions.firestore
    .document("users/{docId}")
    .onCreate((snap, context) => {
      // Get the newly created document's data
      const newValue = snap.data();

      // Destructure the required fields from the new document
      const {user_id, is_active, last_seen} = newValue;

      // Get the document ID from the context parameter
      const docId = context.params.docId;

      // Define the reference to the new document in the Realtime Database
      const ref = admin.database().ref("users/" + docId);

      const lastSeenNumber = last_seen ? last_seen.toMillis() / 1000 : null;

      // Set the new document in the Realtime Database with the specified fields
      return ref.set({
        user_id,
        is_active,
        last_seen: lastSeenNumber,
      });
    });

    // - Sync realtime db with firestore on update
    
    exports.syncFirestoreToRTDB = functions.firestore
    .document('users/{docId}')  // Replace 'yourCollection' with your Firestore collection name
    .onUpdate((change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();
        
        // Check if the specific fields are updated
        const isActiveChanged = newValue.is_active !== previousValue.is_active;
        const lastSeenChanged = newValue.last_seen !== previousValue.last_seen;

        if (isActiveChanged || lastSeenChanged) {
            const updates = {};
            if (isActiveChanged) {
                updates['is_active'] = newValue.is_active;
            }
            if (lastSeenChanged) {
                updates['last_seen'] = newValue.last_seen.toMillis() / 1000;  // Convert Firestore timestamp to milliseconds
            }
            
            // Update the corresponding entry in the Realtime Database
            return rtdb.ref(`users/${context.params.docId}`).update(updates);
        } else {
            return null;
        }
    });