const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const axios = require('axios');
const FormData = require('form-data');

admin.initializeApp();

// Upload avatar proxy to imgbb
exports.uploadAvatar = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).send('Method Not Allowed');
        }

        const authHeader = req.headers.authorization || '';
        if (!authHeader.startsWith('Bearer ')) {
            return res.status(401).send('Unauthorized');
        }

        const idToken = authHeader.split('Bearer ')[1];
        let decodedToken;

        try {
            decodedToken = await admin.auth().verifyIdToken(idToken);
        } catch (error) {
            console.error('Token verification failed:', error);
            return res.status(401).send('Unauthorized');
        }

        const { imageBase64, fileName } = req.body || {};
        if (!imageBase64 || !fileName) {
            return res.status(400).send('Missing image payload');
        }

        // Strip data URI prefix if present
        let base64 = imageBase64;
        const commaIndex = base64.indexOf(',');
        if (commaIndex !== -1) base64 = base64.slice(commaIndex + 1);

        const imgbbKey = process.env.IMGBB_KEY || '52dd149a8c2c1242940bd1e77b66cb15';
        const url = `https://api.imgbb.com/1/upload?key=${imgbbKey}`;

        try {
            const form = new FormData();
            form.append('image', base64);
            form.append('name', fileName);

            const resp = await axios.post(url, form, {
                headers: form.getHeaders(),
                maxContentLength: Infinity,
                maxBodyLength: Infinity,
            });

            if (!resp.data || resp.data.status !== 200) {
                console.error('ImgBB response error:', resp.data);
                return res.status(500).send('Upload failed');
            }

            const avatarUrl = resp.data.data.display_url || resp.data.data.image.url;

            await admin.firestore().collection('users').doc(decodedToken.uid).update({
                avatarUrl,
            });

            return res.status(200).json({ avatarUrl });
        } catch (error) {
            console.error('Upload failed:', error?.response?.data || error);
            return res.status(500).send('Upload failed');
        }
    });
});

// NOTE: `onBalanceUpdate` trigger temporarily disabled to allow local
// testing of `uploadAvatar` in the emulator. Re-enable when emulator
// environment supports Firestore triggers.
// exports.onBalanceUpdate = functions.firestore
//     .document('wallets/{walletId}')
//     .onUpdate(async (change, context) => {
//         // ...original implementation (disabled in emulator)
//     });
