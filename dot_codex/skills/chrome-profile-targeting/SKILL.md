---
name: chrome-profile-targeting
description: Select and verify the exact user-specified Chrome profile or account before browser work. Use whenever a request names a Chrome profile, Google account, email-address-owned Chrome, organization profile, or a logged-in session tied to a particular account. Do not use for generic Chrome requests with no profile or account constraint.
---

# Chrome Profile Targeting

Treat the requested browser family, profile/account identity, and target service as separate mandatory constraints. Do not drop an email address, domain, organization name, or ownership modifier from the request.

## Selection invariant

When the user specifies a Chrome profile or account:

1. List connected browser instances before selecting one. Do not use the generic `chrome` family selector as the final selection.
2. Compare every Chrome instance's profile metadata with the user's full identifier.
3. Do not treat `profileIsLastUsed`, profile ordering, the first result, or a partial match as proof.
4. A domain-only profile name does not prove which full email account it represents.
5. Select an instance only after read-only evidence uniquely identifies it. Useful evidence includes exact profile metadata, existing tabs for the target service, and the authenticated identity visibly shown by that service.
6. If multiple candidates remain, inspect them separately using read-only browser operations. Read the browser documentation before interacting with each newly selected instance.
7. If the identity still cannot be verified uniquely, stop and ask the user to distinguish or open the correct profile. Do not guess.

Before substantive work, state which profile was selected and the evidence that identifies it. Keep using that exact browser handle for the task.

## Preserve the requested access path

If the user asks to use a logged-in Chrome session, do not replace it with a public API, another browser, another account, fresh credentials, web search, or an unauthenticated implementation. If the requested profile is unavailable or signed out, report that exact blocker and wait for the requested profile to become usable.

For reverse engineering or CLI work based on a web application, distinguish these verification levels explicitly:

- Unit or mock tests verify local code only.
- An unauthenticated endpoint response verifies reachability only.
- Real operation is verified only after exercising the intended behavior against the authenticated target account and checking its result.

Never claim live-account verification when only local tests, mocks, public documentation, or unauthenticated requests were used.

This skill does not expand authorization. Follow the browser's confirmation requirements for login, credentials, messages, uploads, deletions, and other external side effects.
