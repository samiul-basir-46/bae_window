const {onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

exports.sendOtp = onCall(async (request) => {
  const email = request.data.email;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await admin.firestore().collection("otps").doc(email).set({
    otp,
    createdAt: Date.now(),
  });

  await transporter.sendMail({
    from: '"Bae Window" <' + process.env.SMTP_USER + '>',
    to: email,
    subject: "Your OTP Code",
    text: `Your verification code is ${otp}`,
  });

  return {success: true};
});

exports.verifyOtp = onCall(async (request) => {
  const {email, otp} = request.data;
  const doc = await admin.firestore().collection("otps").doc(email).get();

  if (!doc.exists) {
    return {success: false, message: "OTP not found"};
  }

  const {otp: savedOtp, createdAt} = doc.data();

  if (Date.now() - createdAt > 5 * 60 * 1000) {
    return {success: false, message: "OTP expired"};
  }

  if (savedOtp !== otp) {
    return {success: false, message: "Invalid OTP"};
  }

  await admin.firestore().collection("users").doc(email).set(
      {isVerified: true},
      {merge: true},
  );

  return {success: true};
});