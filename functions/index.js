import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

// Récupérer les variables d'environnement
const EMAIL_USER = process.env.EMAIL_USER || "";
const EMAIL_PASSWORD = process.env.EMAIL_PASSWORD || "";

// Créer le transporteur Nodemailer
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: EMAIL_USER,
    pass: EMAIL_PASSWORD,
  },
});

// Cloud Function qui se déclenche quand un document est ajouté à 'emails'
exports.sendEmail = functions
  .region("europe-west1") // Adapter à votre région
  .firestore.document("emails/{docId}")
  .onCreate(async (snap) => {
    const data = snap.data();

    console.log("📧 Processing email:", data);

    try {
      // Vérifier que les champs requis existent
      if (!data.to || !data.subject || !data.message) {
        throw new Error("Missing required fields: to, subject, or message");
      }

      // Envoyer l'email
      const info = await transporter.sendMail({
        from: EMAIL_USER,
        to: data.to,
        subject: data.subject,
        text: data.message,
        html: `
          <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
              <pre style="white-space: pre-wrap; word-wrap: break-word;">
${data.message}
              </pre>
              <hr style="border: none; border-top: 1px solid #ddd; margin-top: 20px;">
              <p style="color: #999; font-size: 12px;">
                Cet email a été envoyé depuis l'application CoEntrepreneurs
              </p>
            </body>
          </html>
        `,
      });

      // Marquer comme envoyé dans Firestore
      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: info.messageId,
      });

      console.log("✅ Email sent successfully:", info.messageId);
    } catch (error) {
      console.error("❌ Error sending email:", error);

      // Marquer comme échoué
      await snap.ref.update({
        status: "failed",
        error: String(error),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });