---
description: Check TrueFoundry AI Gateway connection and usage status
---

Check the current TrueFoundry AI Gateway status:

1. Check `tfy` CLI availability
2. Verify `tfy login` is already complete
3. Verify TFY_BASE_URL/TFY_HOST are set
4. Test REST connectivity only if TFY_API_KEY is available
5. Show which models are available
6. Display recent usage stats if accessible
7. Check if any rate limits or budget alerts are active

If first-time setup or CLI login is missing, route the user to `truefoundry-onboard` instead of handling onboarding here.

Report results clearly with pass/fail indicators.
