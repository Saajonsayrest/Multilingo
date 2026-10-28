#!/bin/bash
# Live check of firestore.rules against your own Firebase project.
#
# Signs in as two throwaway anonymous users, tries what must work and what
# must be refused, then deletes everything it made. Needs curl and jq, and
# lib/firebase_options.dart (made by `flutterfire configure`).
#
#   tool/rules_smoke.sh
#
# Exit 0 = every rule behaved, 1 = something did not.

set -u
cd "$(dirname "$0")/.." || exit 1

OPTS=lib/firebase_options.dart
[ -f "$OPTS" ] || { echo "Missing $OPTS. Run: flutterfire configure"; exit 1; }
KEY=$(grep -o "apiKey: '[^']*'" "$OPTS" | head -1 | cut -d"'" -f2)
PROJECT=$(grep -o "projectId: '[^']*'" "$OPTS" | head -1 | cut -d"'" -f2)
[ -n "$KEY" ] && [ -n "$PROJECT" ] || { echo "Could not read the project from $OPTS"; exit 1; }
DOCS="https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents"

FAIL=0
expect() { # name wanted got
  if [ "$2" = "$3" ]; then echo "ok    $1"; else echo "FAIL  $1 (wanted $2, got $3)"; FAIL=1; fi
}

signup() {
  curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$KEY" \
    -H 'Content-Type: application/json' -d '{"returnSecureToken":true}'
}

A=$(signup)
B=$(signup)
A_TOKEN=$(echo "$A" | jq -r '.idToken // empty')
A_UID=$(echo "$A" | jq -r '.localId // empty')
B_TOKEN=$(echo "$B" | jq -r '.idToken // empty')
B_UID=$(echo "$B" | jq -r '.localId // empty')
if [ -z "$A_TOKEN" ] || [ -z "$B_TOKEN" ]; then
  echo "Anonymous sign-in failed. Is it turned on? Run: firebase deploy --only auth"
  echo "$A" | jq -r '.error.message // empty'
  exit 1
fi

# A save in Firestore's REST format. $1 = revision, $2 = extra JSON fields.
save() {
  local extra='{}'
  [ -n "${2:-}" ] && extra="$2"
  jq -n --arg rev "$1" --argjson extra "$extra" '{fields: ({
    schema: {integerValue: "1"}, rev: {integerValue: $rev}, savedAt: {integerValue: "1"},
    appVersion: {stringValue: "0.1.0"}, activeCourse: {stringValue: "it"},
    profile: {mapValue: {fields: {}}},
    courses: {mapValue: {fields: {it: {mapValue: {fields: {}}}}}}
  } + $extra)}'
}

# A restore point. $1 = reason, $2 = label.
point() {
  jq -n --arg reason "$1" --arg label "$2" '{fields: {
    schema: {integerValue: "1"}, savedAt: {integerValue: "1"},
    appVersion: {stringValue: "0.1.0"}, activeCourse: {stringValue: "it"},
    profile: {mapValue: {fields: {}}},
    courses: {mapValue: {fields: {it: {mapValue: {fields: {}}}}}},
    reason: {stringValue: $reason}, label: {stringValue: $label}
  }}'
}

code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
get() { code "$DOCS/$1" ${2:+-H "Authorization: Bearer $2"}; }
put() { code -X PATCH "$DOCS/$1" -H "Authorization: Bearer $2" -H 'Content-Type: application/json' -d "$3"; }
del() { code -X DELETE "$DOCS/$1" -H "Authorization: Bearer $2"; }

echo "Project: $PROJECT"
expect "signed out cannot read a save"            403 "$(get "users/$A_UID")"
expect "owner reads own missing save"             404 "$(get "users/$A_UID" "$A_TOKEN")"
expect "owner creates revision 1"                 200 "$(put "users/$A_UID" "$A_TOKEN" "$(save 1)")"
expect "owner reads own save"                     200 "$(get "users/$A_UID" "$A_TOKEN")"
expect "revision must go up by exactly one"       403 "$(put "users/$A_UID" "$A_TOKEN" "$(save 3)")"
expect "same revision again is refused"           403 "$(put "users/$A_UID" "$A_TOKEN" "$(save 1)")"
expect "owner saves revision 2"                   200 "$(put "users/$A_UID" "$A_TOKEN" "$(save 2)")"
expect "an extra field is refused"                403 "$(put "users/$A_UID" "$A_TOKEN" "$(save 3 '{"admin":{"booleanValue":true}}')")"
expect "another user cannot read the save"        403 "$(get "users/$A_UID" "$B_TOKEN")"
expect "another user cannot write the save"       403 "$(put "users/$A_UID" "$B_TOKEN" "$(save 3)")"
expect "another user cannot delete the save"      403 "$(del "users/$A_UID" "$B_TOKEN")"
expect "another user saves under their own id"    200 "$(put "users/$B_UID" "$B_TOKEN" "$(save 1)")"
expect "restore point in slot c0"                 200 "$(put "users/$A_UID/checkpoints/c0" "$A_TOKEN" "$(point daily '')")"
expect "restore point in slot c4"                 200 "$(put "users/$A_UID/checkpoints/c4" "$A_TOKEN" "$(point milestone '10 lessons done')")"
expect "a sixth slot is refused"                  403 "$(put "users/$A_UID/checkpoints/c5" "$A_TOKEN" "$(point daily '')")"
expect "an odd slot name is refused"              403 "$(put "users/$A_UID/checkpoints/x1" "$A_TOKEN" "$(point daily '')")"
expect "an unknown reason is refused"             403 "$(put "users/$A_UID/checkpoints/c1" "$A_TOKEN" "$(point hacked '')")"
expect "a long label is refused"                  403 "$(put "users/$A_UID/checkpoints/c1" "$A_TOKEN" "$(point daily "$(printf 'x%.0s' {1..41})")")"
expect "another user cannot read a restore point" 403 "$(get "users/$A_UID/checkpoints/c0" "$B_TOKEN")"
expect "owner reads a restore point"              200 "$(get "users/$A_UID/checkpoints/c0" "$A_TOKEN")"
expect "any other collection is refused"          403 "$(put "notes/x" "$A_TOKEN" "$(save 1)")"

# Clean up what this script made.
del "users/$A_UID/checkpoints/c0" "$A_TOKEN" >/dev/null
del "users/$A_UID/checkpoints/c4" "$A_TOKEN" >/dev/null
expect "owner deletes own save"                   200 "$(del "users/$A_UID" "$A_TOKEN")"
del "users/$B_UID" "$B_TOKEN" >/dev/null
for T in "$A_TOKEN" "$B_TOKEN"; do
  curl -s -o /dev/null -X POST "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$KEY" \
    -H 'Content-Type: application/json' -d "{\"idToken\":\"$T\"}"
done

[ "$FAIL" = 0 ] && echo "All rules behaved." || echo "Some rules did not behave."
exit "$FAIL"
