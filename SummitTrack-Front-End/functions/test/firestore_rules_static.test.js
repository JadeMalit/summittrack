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
const imageStorageBlock = storageRules.match(
    /match \/images\/\{fileName\} {[\s\S]*?\n {4}}/,
)?.[0] || "";
const videoStorageBlock = storageRules.match(
    /match \/videos\/\{fileName\} {[\s\S]*?\n {4}}/,
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
      /function ownsMediaData\(uid, mediaId\) \{[\s\S]*\^images\/' \+ mediaId/,
  );
  assert.match(
      rules,
      /function ownsMediaData\(uid, mediaId\) \{[\s\S]*\^videos\/' \+ mediaId/,
  );
  assert.match(mediaBlock, /allow read: if ownsUserDocument\(uid\);/);
  assert.match(
      mediaBlock,
      /allow create, update: if ownsUserDocument\(uid\) && ownsMediaData\(uid, mediaId\);/,
  );
  assert.doesNotMatch(mediaBlock, /allow read,\s*write: if true/);
  assert.doesNotMatch(mediaBlock, /allow read: if true/);
});

test("storage media files require authentication and direct image/video paths", () => {
  assert.match(
      storageRules,
      /function signedIn\(\) \{[\s\S]*request\.auth != null/,
  );
  assert.match(
      storageRules,
      /function isImageUpload\(\) \{[\s\S]*request\.resource\.size <= 10 \* 1024 \* 1024/,
  );
  assert.match(
      storageRules,
      /function isImageUpload\(\) \{[\s\S]*request\.resource\.contentType\.matches\('image\/\.\*'\)/,
  );
  assert.match(
      storageRules,
      /function isVideoUpload\(\) \{[\s\S]*request\.resource\.size <= 100 \* 1024 \* 1024/,
  );
  assert.match(
      storageRules,
      /function isVideoUpload\(\) \{[\s\S]*request\.resource\.contentType\.matches\('video\/\.\*'\)/,
  );
  assert.match(imageStorageBlock, /allow read: if signedIn\(\);/);
  assert.match(
      imageStorageBlock,
      /allow create, update: if signedIn\(\) && isImageUpload\(\);/,
  );
  assert.match(videoStorageBlock, /allow read: if signedIn\(\);/);
  assert.match(
      videoStorageBlock,
      /allow create, update: if signedIn\(\) && isVideoUpload\(\);/,
  );
  assert.doesNotMatch(imageStorageBlock, /allow read,\s*write: if true/);
  assert.doesNotMatch(imageStorageBlock, /allow read: if true/);
  assert.doesNotMatch(videoStorageBlock, /allow read,\s*write: if true/);
  assert.doesNotMatch(videoStorageBlock, /allow read: if true/);
});
