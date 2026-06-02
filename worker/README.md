# Fintech Push Worker (Cloudflare)

Gửi FCM push khi app gọi `POST /send` (nhắc nợ ví nhóm).

## Setup

1. Firebase Console → Project settings → Service accounts → **Generate new private key**.
2. Đăng nhập Cloudflare: `npx wrangler login`
3. Trong thư mục `worker/`:

```bash
npm install
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON
# Dán toàn bộ nội dung file JSON service account
npx wrangler deploy
```

4. Copy URL Worker (vd. `https://fintech-push.<account>.workers.dev`).

## Chạy Flutter

```bash
flutter run --dart-define=PUSH_WORKER_URL=https://fintech-push.<account>.workers.dev
```

## Test health

```bash
curl https://fintech-push.<account>.workers.dev/health
```

## Test send (cần Firebase ID token)

```bash
curl -X POST https://fintech-push.<account>.workers.dev/send \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"userId":"<borrowerUid>","title":"Test","body":"Hello","type":"debt_reminder","debtId":"<id>","walletId":"<id>"}'
```
