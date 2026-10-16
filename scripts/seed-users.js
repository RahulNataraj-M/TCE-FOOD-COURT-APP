#!/usr/bin/env node
'use strict';

// Provisions food-court staff and administrator accounts in Firebase.
//
// Each account gets a Firebase Authentication user plus a `users/{uid}`
// Firestore document carrying its `role`. The script is idempotent: running it
// again reuses existing Auth users and rewrites their profile document, so an
// account created earlier as a student can simply be promoted by changing its
// role in the seed file.
//
// Two modes are supported:
//
//   1. Admin SDK  - used automatically when a service account key is present at
//                   `secrets/serviceAccountKey.json` (or the path given by
//                   GOOGLE_APPLICATION_CREDENTIALS) and `firebase-admin` is
//                   installed. This is the preferred mode.
//   2. REST API   - fallback when no service account key is available. It uses
//                   the public web API key to create the Auth user and that
//                   user's own ID token to write the Firestore profile. Works
//                   with zero Node dependencies.
//
// Usage:
//   node scripts/seed-users.js
//   node scripts/seed-users.js --seed path/to/users.seed.json

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');

function parseArgs(argv) {
  const args = { seed: null };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--seed' && argv[i + 1]) {
      args.seed = argv[i + 1];
      i += 1;
    }
  }
  return args;
}

function loadJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function readProjectId() {
  const rc = loadJson(path.join(ROOT, '.firebaserc'));
  return rc.projects.default;
}

function readWebApiKey() {
  const source = fs.readFileSync(
    path.join(ROOT, 'lib', 'firebase_options.dart'),
    'utf8',
  );
  const match = source.match(
    /FirebaseOptions web = FirebaseOptions\(\s*apiKey:\s*'([^']+)'/,
  );
  if (!match) {
    throw new Error(
      'Could not find the web apiKey in lib/firebase_options.dart.',
    );
  }
  return match[1];
}

function loadAccounts(seedFile) {
  const data = loadJson(seedFile);
  const accounts = Array.isArray(data) ? data : data.accounts;
  if (!Array.isArray(accounts) || accounts.length === 0) {
    throw new Error(`${seedFile} does not contain any accounts.`);
  }
  for (const account of accounts) {
    if (!account.email || !account.role) {
      throw new Error('Every account needs at least an "email" and a "role".');
    }
    if (account.password && account.password.length < 6) {
      throw new Error(
        `Password for ${account.email} must be at least 6 characters.`,
      );
    }
  }
  return accounts;
}

function displayNameOf(account) {
  return [account.firstName, account.lastName]
    .map((part) => (part || '').trim())
    .filter(Boolean)
    .join(' ');
}

function profileOf(account) {
  return {
    email: account.email.trim().toLowerCase(),
    firstName: (account.firstName || '').trim(),
    lastName: (account.lastName || '').trim(),
    phoneNumber: (account.phoneNumber || '').trim(),
    role: account.role,
  };
}

async function provisionWithAdminSdk(accounts, serviceAccountPath) {
  const admin = require('firebase-admin');
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(loadJson(serviceAccountPath)),
    });
  }
  const auth = admin.auth();
  const firestore = admin.firestore();

  const results = [];
  for (const account of accounts) {
    const email = account.email.trim().toLowerCase();
    let user;
    let created = false;
    try {
      user = await auth.getUserByEmail(email);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      user = await auth.createUser({
        email,
        password: account.password,
        displayName: displayNameOf(account) || undefined,
        emailVerified: false,
      });
      created = true;
    }
    await firestore
      .collection('users')
      .doc(user.uid)
      .set(profileOf(account), { merge: true });
    results.push({ ...profileOf(account), uid: user.uid, created });
  }
  return results;
}

async function identityRequest(endpoint, apiKey, body) {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    },
  );
  const data = await response.json();
  if (!response.ok) {
    const code = (data.error && data.error.message) || `HTTP ${response.status}`;
    const error = new Error(`${endpoint} failed: ${code}`);
    error.code = code;
    throw error;
  }
  return data;
}

async function writeUserDoc({ projectId, idToken, uid, profile }) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/users/${uid}`;
  const fields = {};
  for (const [key, value] of Object.entries(profile)) {
    fields[key] = { stringValue: String(value) };
  }
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ fields }),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(
      `Failed to write users/${uid}: ${JSON.stringify(data.error || data)}`,
    );
  }
}

async function provisionWithRest(accounts, { projectId, apiKey }) {
  const results = [];
  for (const account of accounts) {
    const email = account.email.trim().toLowerCase();
    let session;
    let created = false;
    try {
      session = await identityRequest('signUp', apiKey, {
        email,
        password: account.password,
        returnSecureToken: true,
      });
      created = true;
    } catch (error) {
      if (!String(error.code).startsWith('EMAIL_EXISTS')) throw error;
      session = await identityRequest('signInWithPassword', apiKey, {
        email,
        password: account.password,
        returnSecureToken: true,
      });
    }
    const profile = profileOf(account);
    await writeUserDoc({
      projectId,
      idToken: session.idToken,
      uid: session.localId,
      profile,
    });
    results.push({ ...profile, uid: session.localId, created });
  }
  return results;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const seedFile = args.seed
    ? path.resolve(args.seed)
    : path.join(__dirname, 'users.seed.json');
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS
    ? path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS)
    : path.join(ROOT, 'secrets', 'serviceAccountKey.json');

  const accounts = loadAccounts(seedFile);
  console.log(`Seeding ${accounts.length} account(s) from ${seedFile}\n`);

  let hasAdminSdk = false;
  try {
    require.resolve('firebase-admin');
    hasAdminSdk = true;
  } catch (_) {
    hasAdminSdk = false;
  }

  let results;
  if (hasAdminSdk && fs.existsSync(serviceAccountPath)) {
    console.log(`Mode: Admin SDK (${path.relative(ROOT, serviceAccountPath)})`);
    results = await provisionWithAdminSdk(accounts, serviceAccountPath);
  } else {
    if (!hasAdminSdk) {
      console.log('Mode: REST API (firebase-admin not installed)');
    } else {
      console.log(
        `Mode: REST API (no service account key at ${path.relative(
          ROOT,
          serviceAccountPath,
        )})`,
      );
    }
    results = await provisionWithRest(accounts, {
      projectId: readProjectId(),
      apiKey: readWebApiKey(),
    });
  }

  console.log('\nProvisioned accounts:');
  for (const result of results) {
    const action = result.created ? 'created' : 'updated';
    console.log(`  ${result.email}  ->  ${result.role}  (${action}, uid ${result.uid})`);
  }
  console.log('\nDone.');
}

main().catch((error) => {
  console.error('\nSeeding failed:', error.message || error);
  process.exitCode = 1;
});
