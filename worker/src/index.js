import * as jose from 'jose';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname === '/health') {
      return json({ ok: true });
    }

    if (request.method === 'POST' && url.pathname === '/send') {
      return handleSend(request, env);
    }

    return json({ error: 'Not found' }, 404);
  },
};

async function handleSend(request, env) {
  try {
    const projectId = env.FIREBASE_PROJECT_ID;
    if (!projectId) {
      return json({ error: 'FIREBASE_PROJECT_ID not configured' }, 500);
    }

    const serviceAccount = parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT_JSON);
    if (!serviceAccount) {
      return json({ error: 'FIREBASE_SERVICE_ACCOUNT_JSON secret missing' }, 500);
    }

    const authHeader = request.headers.get('Authorization') || '';
    if (!authHeader.startsWith('Bearer ')) {
      return json({ error: 'Unauthorized' }, 401);
    }
    const idToken = authHeader.slice(7);

    let callerUid;
    try {
      callerUid = await verifyFirebaseIdToken(idToken, projectId);
    } catch (e) {
      return json({ error: 'Invalid token', detail: String(e) }, 401);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Invalid JSON body' }, 400);
    }

    const {
      userId,
      title,
      body: messageBody,
      type,
      debtId,
      walletId,
      notificationId,
    } = body;

    if (!userId || !title || !messageBody || !type) {
      return json({ error: 'Missing userId, title, body, or type' }, 400);
    }

    if (type === 'debt_reminder') {
      if (!debtId) {
        return json({ error: 'debtId required for debt_reminder' }, 400);
      }
      let debt;
      try {
        debt = await getFirestoreDocument(
          env,
          serviceAccount,
          projectId,
          `debts/${debtId}`,
        );
      } catch (e) {
        console.error('Failed to fetch debt document', debtId, e);
        return json({ error: 'Failed to fetch debt', detail: String(e) }, 500);
      }
      if (!debt) {
        return json({ error: 'Debt not found' }, 404);
      }
      const fields = debt.fields || {};
      const lenderId = getStringField(fields, 'lenderId');
      const borrowerId = getStringField(fields, 'borrowerId');
      const isSettled = getBoolField(fields, 'isSettled');

      if (lenderId !== callerUid) {
        return json({ error: 'Forbidden' }, 403);
      }
      if (borrowerId !== userId) {
        return json({ error: 'userId must be borrower' }, 403);
      }
      if (isSettled) {
        return json({ error: 'Debt already settled' }, 400);
      }

    } else if (type === 'transaction') {
      // Cho phép gửi thông báo giao dịch (biến động số dư)
    } else {
      return json({ error: 'Unsupported notification type' }, 400);
    }

    let userDoc;
    try {
      userDoc = await getFirestoreDocument(
        env,
        serviceAccount,
        projectId,
        `users/${userId}`,
      );
    } catch (e) {
      console.error('Failed to fetch user document', userId, e);
      return json({ error: 'Failed to fetch user', detail: String(e) }, 500);
    }
    if (!userDoc) {
      return json({ error: 'User not found', sent: 0, failed: 0 });
    }
    const tokens = extractFcmTokens(userDoc);
    if (tokens.length === 0) {
      return json({ sent: 0, failed: 0, skipped: true, reason: 'no_tokens' });
    }

    let accessToken;
    try {
      accessToken = await getGoogleAccessToken(serviceAccount, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);
    } catch (e) {
      console.error('Failed to get access token', e);
      return json({ error: 'Failed to authenticate with Google', detail: String(e) }, 500);
    }

    const dataPayload = {
      type: String(type),
      ...(debtId ? { debtId: String(debtId) } : {}),
      ...(walletId ? { walletId: String(walletId) } : {}),
      ...(notificationId ? { notificationId: String(notificationId) } : {}),
    };

    let sent = 0;
    let failed = 0;
    const invalidDeviceIds = [];
    const failErrors = [];

    for (const { token, deviceId } of tokens) {
      try {
        await sendFcmV1(projectId, accessToken, {
          token,
          title,
          body: messageBody,
          data: dataPayload,
        });
        sent++;
      } catch (e) {
        failed++;
        failErrors.push({ deviceId, error: e.fcmBody || String(e) });
        if (isInvalidTokenError(e)) {
          invalidDeviceIds.push(deviceId);
        }
        console.error('FCM send failed', deviceId, e);
      }
    }

    if (invalidDeviceIds.length > 0) {
      try {
        await removeInvalidTokens(
          env,
          serviceAccount,
          projectId,
          userId,
          invalidDeviceIds,
        );
      } catch (e) {
        console.error('Failed to remove invalid tokens', e);
      }
    }

    return json({ sent, failed, skipped: false, failErrors });
  } catch (e) {
    console.error('Unexpected error in handleSend', e);
    return json({ error: 'Internal server error', detail: String(e) }, 500);
  }
}

function parseServiceAccount(raw) {
  if (!raw) return null;
  try {
    return typeof raw === 'string' ? JSON.parse(raw) : raw;
  } catch {
    return null;
  }
}

async function verifyFirebaseIdToken(token, projectId) {
  const JWKS = jose.createRemoteJWKSet(
    new URL(
      'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
    ),
  );
  const { payload } = await jose.jwtVerify(token, JWKS, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });
  if (!payload.sub) {
    throw new Error('Missing sub');
  }
  return payload.sub;
}

async function getGoogleAccessToken(serviceAccount, scopes) {
  const now = Math.floor(Date.now() / 1000);
  const jwt = await new jose.SignJWT({
    scope: scopes.join(' '),
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(await jose.importPKCS8(serviceAccount.private_key, 'RS256'));

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!resp.ok) {
    throw new Error(`OAuth token error: ${await resp.text()}`);
  }
  const data = await resp.json();
  return data.access_token;
}

async function getFirestoreDocument(env, serviceAccount, projectId, path) {
  const accessToken = await getGoogleAccessToken(serviceAccount, [
    'https://www.googleapis.com/auth/cloud-platform',
  ]);
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}`;
  const resp = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (resp.status === 404) return null;
  if (!resp.ok) {
    throw new Error(`Firestore GET ${path}: ${await resp.text()}`);
  }
  return resp.json();
}

function extractFcmTokens(userDoc) {
  if (!userDoc?.fields?.fcmTokens?.mapValue?.fields) {
    return [];
  }
  const map = userDoc.fields.fcmTokens.mapValue.fields;
  const result = [];
  for (const [deviceId, value] of Object.entries(map)) {
    const token = value?.stringValue;
    if (token) {
      result.push({ deviceId, token });
    }
  }
  return result;
}

async function sendFcmV1(projectId, accessToken, { token, title, body, data }) {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const resp = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: 'fintech_app_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      },
    }),
  });

  if (!resp.ok) {
    const text = await resp.text();
    const err = new Error(`FCM error: ${text}`);
    err.fcmStatus = resp.status;
    err.fcmBody = text;
    throw err;
  }
}

function isInvalidTokenError(e) {
  const body = e.fcmBody || String(e);
  return (
    body.includes('NOT_FOUND') ||
    body.includes('UNREGISTERED') ||
    body.includes('INVALID_ARGUMENT')
  );
}

async function removeInvalidTokens(
  env,
  serviceAccount,
  projectId,
  userId,
  deviceIds,
) {
  const accessToken = await getGoogleAccessToken(serviceAccount, [
    'https://www.googleapis.com/auth/cloud-platform',
  ]);
  for (const deviceId of deviceIds) {
    const patchUrl =
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}?` +
      `updateMask.fieldPaths=fcmTokens.${encodeURIComponent(deviceId)}`;
    await fetch(patchUrl, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: {
          fcmTokens: {
            mapValue: {
              fields: {
                [deviceId]: { nullValue: null },
              },
            },
          },
        },
      }),
    });
  }
}

function getStringField(fields, name) {
  return fields[name]?.stringValue ?? '';
}

function getBoolField(fields, name) {
  return fields[name]?.booleanValue === true;
}

function getTimestampField(fields, name) {
  const ts = fields[name]?.timestampValue;
  if (!ts) return null;
  return Date.parse(ts);
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
