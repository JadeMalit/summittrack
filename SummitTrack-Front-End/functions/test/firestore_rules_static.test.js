const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const rules = fs.readFileSync(
    path.join(__dirname, "..", "..", "firestore.rules"),
    "utf8",
);
const storageRules = fs.readFileSync(
    path.join(__dirname, "..", "..", "storage.rules"),
    "utf8",
);

const scheduledHikesBlock = rules.match(
    /match \/scheduled_hikes\/\{hikeId\} {[\s\S]*?\n {6}}/,
)?.[0] || "";
const mediaBlock = rules.match(
    /match \/media\/\{mediaId\} {[\s\S]*?\n {6}}/,
)?.[0] || "";
const userMediaStorageBlock = storageRules.match(
    /match \/users\/\{uid\}\/media\/\{mediaFile\} {[\s\S]*?\n {4}}/,
)?.[0] || "";

const ownerReadRuleTestName =
  "scheduled hike reads are restricted to the authenticated owner path";

test(ownerReadRuleTestName, () => {
  assert.match(
      rules,
      /function ownsUserDocument\(uid\) \{[\s\S]*request\.auth\.uid == uid/,
  );
  assert.match(scheduledHikesBlock, /allow read: if ownsUserDocument\(uid\);/);
  assert.doesNotMatch(scheduledHikesBlock, /allow read,\s*write: if true/);
  assert.doesNotMatch(scheduledHikesBlock, /allow read: if true/);
});

test("user media metadata is restricted to the authenticated UID", () => {
  assert.match(
      rules,
      /function ownsMediaData\(uid, mediaId\) \{[\s\S]*request\.resource\.data\.uid == uid/,
  );
  assert.match(
      rules,
      /function ownsMediaData\(uid, mediaId\) \{[\s\S]*request\.resource\.data\.userId == uid/,
  );
  assert.match(
      rules,
      /function ownsMediaData\(uid, mediaId\) \{[\s\S]*\^users\/' \+ uid \+ '\/media\/' \+ mediaId/,
  );
  assert.match(mediaBlock, /allow read: if ownsUserDocument\(uid\);/);
  assert.match(
      mediaBlock,
      /allow create, update: if ownsUserDocument\(uid\) && ownsMediaData\(uid, mediaId\);/,
  );
  assert.doesNotMatch(mediaBlock, /allow read,\s*write: if true/);
  assert.doesNotMatch(mediaBlock, /allow read: if true/);
});

test("storage media files are restricted to the authenticated UID", () => {
  assert.match(
      storageRules,
      /function ownsTrailPhotoFolder\(uid\) \{[\s\S]*request\.auth\.uid == uid/,
  );
  assert.match(
      storageRules,
      /function isValidUserMediaUpload\(uid, mediaFile\) \{[\s\S]*request\.resource\.metadata\.uid == uid/,
  );
  assert.match(
      storageRules,
      /function isValidUserMediaUpload\(uid, mediaFile\) \{[\s\S]*request\.resource\.metadata\.userId == uid/,
  );
  assert.match(
      storageRules,
      /request\.resource\.metadata\.storagePath == 'users\/' \+ uid \+ '\/media\/' \+ mediaFile/,
  );
  assert.match(userMediaStorageBlock, /allow read: if ownsTrailPhotoFolder\(uid\);/);
  assert.match(
      userMediaStorageBlock,
      /allow create, update: if ownsTrailPhotoFolder\(uid\)\s*&& isValidUserMediaUpload\(uid, mediaFile\);/,
  );
  assert.doesNotMatch(userMediaStorageBlock, /allow read,\s*write: if true/);
  assert.doesNotMatch(userMediaStorageBlock, /allow read: if true/);
});
