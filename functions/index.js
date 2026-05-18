const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onBalanceUpdate = functions.firestore
    .document('wallets/{walletId}')
    .onUpdate(async (change, context) => {
        const dataBefore = change.before.data();
        const dataAfter = change.after.data();

        // Chỉ xử lý nếu số dư thay đổi
        if (dataBefore.balance === dataAfter.balance) return null;

        const diff = dataAfter.balance - dataBefore.balance;
        const ownerId = dataAfter.ownerId;

        // Lấy Token của User
        const userDoc = await admin.firestore().collection('users').doc(ownerId).get();
        if (!userDoc.exists) return null;

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            console.log(`User ${ownerId} không có token.`);
            return null;
        }

        const title = 'Biến động số dư';
        const body = diff > 0
            ? `+${diff.toLocaleString()}đ. Số dư: ${dataAfter.balance.toLocaleString()}đ`
            : `${diff.toLocaleString()}đ. Số dư: ${dataAfter.balance.toLocaleString()}đ`;

        const message = {
            notification: { title, body },
            token: fcmToken,
            data: {
                type: 'transaction',
                walletId: context.params.walletId
            },
            android: { priority: 'high' },
            apns: { payload: { aps: { sound: 'default' } } }
        };
        console.log(`[FCM PAYLOAD]`, JSON.stringify(message));

        try {
            await admin.messaging().send(message);
            console.log(`[SUCCESS] Notification sent to ${ownerId}`);
        } catch (error) {
            console.error('[ERROR] FCM sending failed:', error);
        }
        return null;
    });
