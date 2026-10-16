#!/usr/bin/env node
'use strict';

// Seeds the Firestore `menu_items` collection from the bundled catalog.
//
// The student-facing app ships with a bundled catalog (see MenuCatalog in
// lib/models/menu_item.dart) and only uses it until Firestore answers. The
// admin dashboard, however, reads live Firestore data, so without this seed the
// admin menu starts empty even though students can see items.
//
// This script signs in as an administrator (taken from scripts/users.seed.json)
// and creates one `menu_items` document per bundled item, keyed by a stable
// slug id. It is idempotent: an item whose document already exists is left
// untouched, so re-running after admin edits never clobbers them.
//
// Usage:
//   node scripts/seed-menu.js

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');

// Mirrors MenuCatalog.items in lib/models/menu_item.dart. Keep in sync.
const MENU = [
  {
    name: 'Chicken Biriyani',
    description: 'Aromatic basmati rice with tender chicken',
    price: 150,
    imageAsset: 'assets/images/biriyani_home.jpg',
    category: 'Rice',
    rating: 4.8,
    timesOrdered: 8,
  },
  {
    name: 'Chicken Rice',
    description: 'Stir-fried rice with chicken & veggies',
    price: 120,
    imageAsset: 'assets/images/chicken_fried_rice.jpg',
    category: 'Rice',
    rating: 4.5,
    timesOrdered: 0,
  },
  {
    name: 'Veg Rice',
    description: 'Classic vegetable stir-fried rice',
    price: 60,
    imageAsset: 'assets/images/veg_rice_bowl.jpg',
    category: 'Rice',
    rating: 0,
    timesOrdered: 0,
  },
  {
    name: 'Chicken Noodles',
    description: 'Wok-tossed noodles with chicken strips',
    price: 90,
    imageAsset: 'assets/images/chicken_noodles.jpg',
    category: 'Snacks',
    rating: 0,
    timesOrdered: 0,
  },
  {
    name: 'Veg Noodles',
    description: 'Noodles tossed with fresh vegetables',
    price: 70,
    imageAsset: 'assets/images/veg_noodles.jpg',
    category: 'Snacks',
    rating: 0,
    timesOrdered: 0,
  },
  {
    name: 'Parotta',
    description: 'Flaky layered flatbread',
    price: 20,
    imageAsset: 'assets/images/parotta.jpg',
    category: 'Breakfast',
    rating: 0,
    timesOrdered: 0,
  },
  {
    name: 'Lime Juice',
    description: 'Fresh squeezed sweet lime',
    price: 20,
    imageAsset: 'assets/images/lime_juice_glassy.jpg',
    category: 'Drinks',
    rating: 0,
    timesOrdered: 6,
  },
  {
    name: 'Dosa',
    description: 'Crispy South Indian pancake',
    price: 70,
    imageAsset: 'assets/images.jpeg',
    category: 'Breakfast',
    rating: 0,
    timesOrdered: 0,
  },
];

function loadJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function readProjectId() {
  return loadJson(path.join(ROOT, '.firebaserc')).projects.default;
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
    throw new Error('Could not find the web apiKey in lib/firebase_options.dart.');
  }
  return match[1];
}

function slug(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function adminIdToken(apiKey) {
  const seed = loadJson(path.join(__dirname, 'users.seed.json'));
  const accounts = Array.isArray(seed) ? seed : seed.accounts;
  const admin = accounts.find((account) => account.role === 'admin');
  if (!admin) {
    throw new Error('No administrator found in scripts/users.seed.json.');
  }
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: admin.email.trim().toLowerCase(),
        password: admin.password,
        returnSecureToken: true,
      }),
    },
  );
  const data = await response.json();
  if (!response.ok) {
    const code = (data.error && data.error.message) || `HTTP ${response.status}`;
    throw new Error(`Admin sign-in failed: ${code}`);
  }
  return data.idToken;
}

function toFirestoreFields(item) {
  return {
    name: { stringValue: item.name },
    description: { stringValue: item.description },
    price: { integerValue: String(item.price) },
    imageAsset: { stringValue: item.imageAsset },
    category: { stringValue: item.category },
    rating: { doubleValue: item.rating },
    timesOrdered: { integerValue: String(item.timesOrdered) },
    available: { booleanValue: true },
  };
}

async function createItem({ projectId, idToken, documentId, item }) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/menu_items?documentId=${documentId}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ fields: toFirestoreFields(item) }),
  });
  const data = await response.json();
  if (response.ok) return 'created';
  const message = JSON.stringify(data.error || data);
  if (response.status === 409 || message.includes('ALREADY_EXISTS')) {
    return 'exists';
  }
  throw new Error(`Failed to create "${item.name}": ${message}`);
}

async function main() {
  const projectId = readProjectId();
  const apiKey = readWebApiKey();
  const idToken = await adminIdToken(apiKey);

  console.log(`Seeding ${MENU.length} menu item(s) into ${projectId}\n`);

  const summary = { created: 0, exists: 0 };
  for (const item of MENU) {
    const documentId = slug(item.name);
    const result = await createItem({ projectId, idToken, documentId, item });
    summary[result] += 1;
    console.log(`  ${item.name} (${documentId}) -> ${result}`);
  }

  console.log(
    `\nDone. ${summary.created} created, ${summary.exists} already existed.`,
  );
}

main().catch((error) => {
  console.error('\nSeeding failed:', error.message || error);
  process.exitCode = 1;
});
