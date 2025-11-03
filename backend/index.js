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

// --- HELPER FUNCTION FOR INSTRUCTIONS ---
function getInstructionsForSource(source, formattedAmount, refNumber) {
  // Instructions are now styled to fit the new design
  const tableStyle =
    'role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="font-family: \'Nunito\', Arial, sans-serif; font-size: 16px;"';
  const labelStyle = 'style="padding: 6px 0; color: #555555;"';
  const valueStyle =
    "style=\"text-align: right; font-family: 'Manrope', Arial, sans-serif; font-weight: 700; color: #333333;\"";

  switch (source) {
    case "GCash":
      return `
                <p style="margin: 0 0 15px 0; font-family: 'Nunito', Arial, sans-serif; font-size: 16px; line-height: 1.5;">Please transfer exactly <strong>${formattedAmount}</strong> to the following GCash account:</p>
                <table ${tableStyle}>
                    <tr><td ${labelStyle}>Account Name:</td><td ${valueStyle}>Komyut Inc.</td></tr>
                    <tr><td ${labelStyle}>GCash Number:</td><td ${valueStyle}>0917-123-4567</td></tr>
                </table>
                <p style="margin: 20px 0 0 0; font-size: 14px; color: #555; font-family: 'Nunito', Arial, sans-serif;"><strong>Important:</strong> After sending, please take a screenshot and reply to this email for verification.</p>
            `;
    // Add other cases for BDO, Maya, 7-Eleven etc. here in the same format
    default:
      return `
                <p style="margin: 0 0 15px 0; font-family: 'Nunito', Arial, sans-serif; font-size: 16px; line-height: 1.5;">Please use the following details for your payment via <strong>${source}</strong>:</p>
                <table ${tableStyle}>
                    <tr><td ${labelStyle}>Biller Name:</td><td ${valueStyle}>Komyut Services PH</td></tr>
                    <tr><td ${labelStyle}>Reference No:</td><td ${valueStyle}>${refNumber}</td></tr>
                    <tr><td ${labelStyle}>Amount Due:</td><td ${valueStyle}>${formattedAmount}</td></tr>
                </table>
                 <p style="margin: 20px 0 0 0; font-size: 14px; color: #555; font-family: 'Nunito', Arial, sans-serif;"><strong>Note:</strong> Payments are typically posted within 15 minutes. Please keep your receipt.</p>
            `;
  }
}

// --- API Endpoint ---
app.post("/send-payment-instructions", (req, res) => {
  console.log("Received request for branded email...");

  // We now also accept userId
  const { name, email, amount, source, userId } = req.body;

  if (!name || !email || !amount || !source || !userId) {
    return res.status(400).json({ error: "Missing required fields." });
  }

  // --- Data Generation ---
  const transactionCode = `KMYT-${Math.random()
    .toString(36)
    .substr(2, 9)
    .toUpperCase()}`;
  const date = new Date();
  const formattedDate = date.toLocaleDateString("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  });
  const formattedAmount = `PHP ${amount.toFixed(2)}`;

  const instructions = getInstructionsForSource(
    source,
    formattedAmount,
    transactionCode
  );

  // --- Brand Colors and Fonts ---
  const brandColor = "#8E4CB6";
  const gradient = "linear-gradient(135deg, #B945AA, #8E4CB6, #5B53C2)";
  const bgColor = "#F6F1FF";

  // --- THE NEW BRANDED HTML EMAIL TEMPLATE ---
  const htmlBody = `
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Manrope:wght@700;800&family=Nunito:wght@400;600&display=swap');
        body { font-family: 'Nunito', Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; }
    </style>
    </head>
    <body style="background-color: ${bgColor}; margin: 0; padding: 0;">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%"><tr><td style="padding: 20px 10px;">
            <table align="center" border="0" cellpadding="0" cellspacing="0" width="600" style="max-width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
                
                <!-- Header -->
                <tr><td align="center" style="background: ${gradient}; padding: 30px 0;">
                    <img src="https://i.postimg.cc/13YyZk7R/komyut-logo-email.png" alt="Komyut Logo" width="60" height="60" style="display: block;">
                    <h1 style="color: #ffffff; margin: 10px 0 0 0; font-family: 'Manrope', Arial, sans-serif; font-size: 28px; font-weight: 800;">Cash In Request</h1>
                </td></tr>

                <!-- Main Content -->
                <tr><td style="padding: 30px 30px 40px 30px;">
                    <p style="color: #333; margin: 0 0 25px 0; font-size: 16px; line-height: 1.6;">Hello <strong>${name}</strong>, we've received your request. Please follow the instructions below to complete your payment.</p>
                    
                    <!-- Transaction Summary Card -->
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #faf7ff; border: 1px solid #e9d8f8; border-radius: 8px; padding: 20px; font-size: 15px;">
                        <tr><td style="padding-bottom: 15px;" colspan="2"><h3 style="margin:0; font-family: 'Manrope', Arial, sans-serif; font-size: 18px; color: ${brandColor};">Transaction Summary</h3></td></tr>
                        <tr><td style="color: #555; padding: 5px 0;">User ID:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">${userId}</td></tr>
                        <tr><td style="color: #555; padding: 5px 0;">Transaction No:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">${transactionCode}</td></tr>
                        <tr><td style="color: #555; padding: 5px 0;">Date:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 700;">${formattedDate}</td></tr>
                        <tr style="border-top: 1px solid #e9d8f8;"><td style="color: #555; padding: 10px 0 0 0; font-weight: 600;">Total Amount Due:</td><td style="text-align: right; color: #333; font-family: 'Manrope', Arial, sans-serif; font-weight: 800; font-size: 18px; padding: 10px 0 0 0;">${formattedAmount}</td></tr>
                    </table>

                    <!-- Payment Instructions Card -->
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-top: 25px; background-color: #ffffff; border: 1px solid #e9d8f8; border-radius: 8px; padding: 20px;">
                        <tr><td style="padding-bottom: 15px;" colspan="2"><h3 style="margin:0; font-family: 'Manrope', Arial, sans-serif; font-size: 18px; color: ${brandColor};">Payment Instructions (${source})</h3></td></tr>
                        <tr><td colspan="2">${instructions}</td></tr>
                    </table>
                </td></tr>

                <!-- Footer -->
                <tr><td style="background-color: #faf7ff; padding: 20px 30px; border-top: 1px solid #e9d8f8;">
                    <p style="margin: 0; color: #888888; font-size: 12px; text-align: center; line-height: 1.5;">
                        If you have any questions, please contact our support team.<br>
                        &copy; ${new Date().getFullYear()} komyut. All rights reserved.
                    </p>
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
      console.log("Branded email sent successfully!", info.response);
      res.status(200).json({ message: "Instructions sent successfully!" });
    }
  );
});

// --- Start the Server ---
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
