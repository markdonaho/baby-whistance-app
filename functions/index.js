/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/**
 * Calculates scores for all guesses and saves them back to Firestore.
 *
 * This function should be called when actual baby details are set and guessing is revealed.
 * It expects the caller to be authenticated and have an admin custom claim.
 */
exports.calculateAndSaveScores = functions.https.onCall(async (data, context) => {
  // 1. Authentication/Authorization
  // REMOVE OR SECURE THIS PROPERLY BEFORE PRODUCTION.
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
  }
  functions.logger.info("calculateAndSaveScores called by user:", context.auth.uid);

  // 2. Fetch Actual Baby Details
  const appStatusRef = db.collection("app_status").doc("app_config");
  let appStatusSnap;
  try {
    appStatusSnap = await appStatusRef.get();
  } catch (error) {
    functions.logger.error("Error fetching app_status:", error);
    throw new functions.https.HttpsError("internal", "Could not fetch app status.");
  }

  if (!appStatusSnap.exists) {
    functions.logger.error("App config not found.");
    throw new functions.https.HttpsError("not-found", "App config not found.");
  }
  const appStatus = appStatusSnap.data();
  const actualDetails = (appStatus && appStatus.actual_baby_details) ? appStatus.actual_baby_details : null;
  const guessingStatus = (appStatus && appStatus.guessing_status) ? appStatus.guessing_status : null;

  if (guessingStatus !== "revealed") {
    functions.logger.warn("Guessing status is not 'revealed'. Current status:", guessingStatus);
    const errorMessage =
      `Guessing status must be "revealed" to calculate scores. Current is: ${guessingStatus}`;
    throw new functions.https.HttpsError("failed-precondition", errorMessage);
  }
  if (!actualDetails) {
    functions.logger.error("Actual baby details not found in app_config.");
    throw new functions.https.HttpsError("not-found", "Actual baby details not found.");
  }

  functions.logger.info("Actual Details:", actualDetails);

  const requiredActualFields = [
    "timeOfBirth", "weightPounds", "weightOunces", "lengthInches",
    "hairColor", "eyeColor", "actualLooksLike", "actualBrycenReaction",
  ];
  for (const field of requiredActualFields) {
    if (actualDetails[field] === undefined || actualDetails[field] === null) {
      functions.logger.error(`Missing actual detail: ${field}`);
      throw new functions.https.HttpsError("invalid-argument", `Missing actual detail: ${field}`);
    }
  }

  const actualTimeStr = actualDetails.timeOfBirth;
  const actualWeightOz = (actualDetails.weightPounds * 16) + actualDetails.weightOunces;
  const actualLength = actualDetails.lengthInches;
  const actualHair = actualDetails.hairColor;
  const actualEye = actualDetails.eyeColor;
  const actualLooksLike = actualDetails.actualLooksLike;
  const actualBrycenReaction = actualDetails.actualBrycenReaction;

  let guessesSnapshot;
  try {
    guessesSnapshot = await db.collection("guesses").get();
  } catch (error) {
    functions.logger.error("Error fetching guesses:", error);
    throw new functions.https.HttpsError("internal", "Could not fetch guesses.");
  }

  const allGuesses = [];
  guessesSnapshot.forEach((doc) => {
    allGuesses.push({id: doc.id, ...doc.data()});
  });

  if (allGuesses.length === 0) {
    functions.logger.info("No guesses found to score.");
    return {message: "No guesses found to score.", scoresCalculated: 0};
  }
  functions.logger.info(`Found ${allGuesses.length} guesses to score.`);

  const scoredGuesses = allGuesses.map((guess) => {
    const scoreBreakdown = {
      time_points: 0, weight_points: 0, length_points: 0,
      hair_points: 0, eye_points: 0, looks_like_points: 0,
      brycen_bonus: 0,
    };

    const parseTimeToMinutes = (timeStr) => {
      if (!timeStr || !/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(timeStr)) {
        functions.logger.warn(`Invalid time format for parsing: '${timeStr}'`);
        return null;
      }
      const parts = timeStr.split(":");
      return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
    };

    const actualTimeMins = parseTimeToMinutes(actualTimeStr);
    const guessTimeMins = parseTimeToMinutes(guess.timeGuess);

    guess.timeDiff = (actualTimeMins !== null && guessTimeMins !== null) ?
      Math.abs(actualTimeMins - guessTimeMins) :
      Infinity;
    guess.weightDiff = (typeof guess.weightGuess === "number") ?
      Math.abs(actualWeightOz - guess.weightGuess) :
      Infinity;
    guess.lengthDiff = (typeof guess.lengthGuess === "number") ?
      Math.abs(actualLength - guess.lengthGuess) :
      Infinity;

    if (guess.hairColorGuess === actualHair) scoreBreakdown.hair_points = 20;
    if (guess.eyeColorGuess === actualEye) scoreBreakdown.eye_points = 20;
    if (guess.looksLikeGuess === actualLooksLike) scoreBreakdown.looks_like_points = 20;
    if (guess.brycenReactionGuess === actualBrycenReaction) scoreBreakdown.brycen_bonus = 1;

    return {...guess, scoreBreakdown};
  });

  const awardTopNPoints = (guesses, diffField, pointsCategory, pointsTiers) => {
    const validGuesses = guesses.filter((g) => Number.isFinite(g[diffField]));
    validGuesses.sort((a, b) => a[diffField] - b[diffField]);

    const distinctDiffValues = [];
    if (validGuesses.length > 0) {
      distinctDiffValues.push(validGuesses[0][diffField]);
      for (let i = 1; i < validGuesses.length; i++) {
        if (validGuesses[i][diffField] > distinctDiffValues[distinctDiffValues.length - 1]) {
          distinctDiffValues.push(validGuesses[i][diffField]);
        }
        if (distinctDiffValues.length >= pointsTiers.length) break;
      }
    }

    for (const guess of guesses) {
      if (!Number.isFinite(guess[diffField])) continue;
      for (let i = 0; i < distinctDiffValues.length; i++) {
        if (guess[diffField] === distinctDiffValues[i]) {
          if (i < pointsTiers.length) {
            guess.scoreBreakdown[pointsCategory] = pointsTiers[i];
          }
          break;
        }
      }
    }
  };

  const pointsTiers = [30, 20, 10];
  awardTopNPoints(scoredGuesses, "timeDiff", "time_points", pointsTiers);
  awardTopNPoints(scoredGuesses, "weightDiff", "weight_points", pointsTiers);
  awardTopNPoints(scoredGuesses, "lengthDiff", "length_points", pointsTiers);

  const batch = db.batch();
  let successfulScoresCount = 0;
  for (const guess of scoredGuesses) {
    let currentTotal = 0;
    for (const key in guess.scoreBreakdown) {
      if (Object.prototype.hasOwnProperty.call(guess.scoreBreakdown, key)) {
        currentTotal += guess.scoreBreakdown[key];
      }
    }
    guess.total_score = currentTotal;

    const guessRef = db.collection("guesses").doc(guess.id);
    batch.update(guessRef, {
      score_breakdown: guess.scoreBreakdown,
      total_score: guess.total_score,
    });
    successfulScoresCount++;
    functions.logger.info(`Updating guess ${guess.id} for user ${guess.userId} with total score: ${guess.total_score}`);
  }

  try {
    await batch.commit();
    const successMsg =
      `Scores calculated and saved successfully for ${successfulScoresCount} guesses.`;
    functions.logger.info(successMsg);
    return {message: successMsg, scoresCalculated: successfulScoresCount};
  } catch (error) {
    functions.logger.error("Error committing scores batch:", error);
    throw new functions.https.HttpsError("internal", "Failed to save scores.");
  }
});
