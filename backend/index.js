require("dotenv").config();
const express = require("express");
const nodemailer = require("nodemailer");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 3000;

// --- Nodemailer Setup ---
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

// --- API Endpoint ---
app.post("/send-payment-instructions", (req, res) => {
  console.log("Received request for revised branded email...");

  const { name, email, amount, source, userId, transactionCode } = req.body;

  if (!name || !email || !amount || !source || !userId || !transactionCode) {
    return res.status(400).json({ error: "Missing required fields." });
  }

  // --- Data Formatting ---
  const fee = 10.0;
  const baseAmount = amount - fee;
  const formattedBaseAmount = `PHP ${baseAmount.toFixed(2)}`;
  const formattedTotalAmount = `PHP ${amount.toFixed(2)}`;

  // --- Brand Colors and Fonts ---
  const brandColor = "#8E4CB6";
  const bgColor = "#F6F1FF";

  // --- Email Template
  const htmlBody = `
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Manrope:wght@600;700;800&family=Nunito:wght@400;600&display=swap');
        body { font-family: 'Nunito', Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; }
    </style>
    </head>
    <body style="background-color: ${bgColor}; margin: 0; padding: 0;">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%"><tr><td style="padding: 20px 10px;">
            <table align="center" border="0" cellpadding="0" cellspacing="0" width="600" style="max-width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
                
                <!-- Header -->
                <tr><td align="center" style="background: ${brandColor}; padding: 30px 0;">
                    <h1 style="color: #ffffff; margin: 0; font-family: 'Manrope', Arial, sans-serif; font-size: 26px; font-weight: 600;">Cash In Request</h1>
                </td></tr>

                <!-- Main Content -->
                <tr><td style="padding: 30px 30px 40px 30px;">
                    <p style="color: #333; margin: 0 0 25px 0; font-size: 16px; line-height: 1.6;">Hello <strong>${name}</strong>, please follow the instructions below to complete your payment.</p>
                    
                    <!-- Transaction Summary Card -->
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #faf7ff; border: 1px solid #e9d8f8; border-radius: 8px; padding: 20px; font-size: 15px;">
                        <tr><td style="padding-bottom: 15px;" colspan="2"><h3 style="margin:0; font-family: 'Manrope', Arial, sans-serif; font-size: 18px; color: ${brandColor};">Transaction Summary</h3></td></tr>
                        <tr><td style="color: #555; padding: 5px 0; font-family: 'Nunito', Arial, sans-serif;">Name:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">${name}</td></tr>
                        <tr><td style="color: #555; padding: 5px 0; font-family: 'Nunito', Arial, sans-serif;">Amount:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">${formattedBaseAmount}</td></tr>
                        <tr><td style="color: #555; padding: 5px 0; font-family: 'Nunito', Arial, sans-serif;">Service Fee:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">PHP 10.00</td></tr>
                        <tr style="border-top: 1px solid #e9d8f8;"><td style="color: #333; padding: 10px 0 0 0; font-weight: 600; font-family: 'Nunito', Arial, sans-serif; font-size: 16px;">Total Amount Due:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 800; font-size: 18px; padding: 10px 0 0 0;">${formattedTotalAmount}</td></tr>
                    </table>

                    <!-- Payment Instructions Card -->
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-top: 25px; background-color: #ffffff; border: 1px solid #e9d8f8; border-radius: 8px; padding: 20px; font-size: 16px;">
                        <tr><td style="padding-bottom: 15px;" colspan="2"><h3 style="margin:0; font-family: 'Manrope', Arial, sans-serif; font-size: 18px; color: ${brandColor};">Payment Instructions (${source})</h3></td></tr>
                        <tr><td style="color: #555; padding: 8px 0; font-family: 'Nunito', Arial, sans-serif;">Biller Name:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">Komyut Services PH</td></tr>
                        <tr><td style="color: #555; padding: 8px 0; font-family: 'Nunito', Arial, sans-serif;">Reference Number:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">${transactionCode}</td></tr>
                        <tr><td style="color: #555; padding: 8px 0; font-family: 'Nunito', Arial, sans-serif;">Total Amount Due:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">${formattedTotalAmount}</td></tr>
                    </table>
                    
                     <p style="color: #555555; margin: 30px 0 0 0; font-size: 14px; text-align: center; line-height: 1.6;">Your payment will be confirmed and your wallet balance updated within 3-5 business days. Please keep your receipt as proof of payment.</p>
                </td></tr>
            </table>
        </td></tr></table>
    </body></html>
    `;

  // --- Send the Email ---
  transporter.sendMail(
    {
      from: `"komyut" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: `[komyut] Payment Instructions for ${transactionCode}`,
      html: htmlBody,
    },
    (error, info) => {
      if (error) {
        console.error("Error sending email:", error);
        return res
          .status(500)
          .json({ error: "Failed to send email. Check server logs." });
      }
      console.log("Revised email sent successfully!", info.response);
      res.status(200).json({ message: "Instructions sent successfully!" });
    }
  );
});

// --- Start the Server ---
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
