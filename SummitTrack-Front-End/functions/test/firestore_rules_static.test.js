const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const rules = fs.readFileSync(
    path.join(__dirname, "..", "..", "firestore.rules"),
    "utf8",
);

const scheduledHikesBlock = rules.match(
    /match \/scheduled_hikes\/\{hikeId\} {[\s\S]*?\n {6}}/,
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
