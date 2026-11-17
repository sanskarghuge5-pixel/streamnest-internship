# StreamNest — Video Streaming Internship Feature Project

Responsive streaming-platform starter with multilingual moderated comments, Free/Bronze/Silver/Gold access, Razorpay test payments, email OTP login, per-day downloads, adaptive themes and synchronized watch parties. Next.js 16 + React 19 + Supabase.

**Read [SETUP_GUIDE.md](SETUP_GUIDE.md) for complete beginner instructions.**

## Local commands

```bash
npm install
cp .env.example .env.local # On Windows use File Explorer or: copy .env.example .env.local
npm run dev
```

Visit `http://localhost:3000`.

**Before testing backend features**, configure `.env.local` and run the SQL in `supabase/setup.sql` on your own Supabase project. Do not commit API secrets. The protected features require Supabase and payment keys. In the absence of keys, the homepage works as a limited preview.

## Implemented and related feature paths

| Requirement | Where implemented |
|---|---|
| Custom responsive player, gestures & next | `components/StreamApp.tsx`, `app/globals.css` |
| Comments, translation, votes, reports | `components/StreamApp.tsx`, `app/api/translate/route.ts`, `supabase/setup.sql` |
| Quota & download history | `app/api/download/route.ts`, `supabase/setup.sql` |
| Subscription test payment | `app/api/payment/*/route.ts`, `supabase/setup.sql` |
| Email login & theme preference | `components/StreamApp.tsx`, `lib/supabase.ts` |
| Realtime playback & meeting-link calling | `components/StreamApp.tsx`, `supabase/setup.sql` |

## Known scope/limitations

This starter is NOT evidence of a completed internship, verified production deployment, or an extension of an earlier training project. Features require manual integration and end-to-end tests. There is no built-in administrator moderation dashboard, proprietary group video calling or recording. Paid plans are test transactions only. Demo source media is publicly available; production-quality media restriction would need private storage and DRM.

## Security design

- Only publishable/anon Supabase key is sent to the client. Service role and Razorpay secret remain in server environment.
- Every premium playback URL is checked against server-side account entitlements.
- Atomic PostgreSQL download registration enforces per-plan daily limits in IST.
- Profile plan changes are restricted by a PostgreSQL trigger.
- Razorpay callback requires cryptographic verification and payment status verification through the provider.
- Comments are checked by a database trigger; reports are queued, not automatically deleted.

**Do not include `.env.local` or secrets in your GitHub repository, screenshots or demo recording.**
