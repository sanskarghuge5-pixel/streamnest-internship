# StreamNest — beginner setup, step by step

**Status:** This is a starter implementation, not a deployed or fully verified internship submission. It must be connected to YOUR Supabase and Razorpay accounts, tested, and deployed. Do not claim it is an extension of a training project if there was no such project.

## Part A — Run it on your Windows computer

1. Extract `streamnest-internship.zip` to your Desktop, to a folder called `streamnest-internship`.
2. Open Visual Studio Code → **File → Open Folder** → select `streamnest-internship`.
3. In VS Code, select **Terminal → New Terminal**.
4. Type `node -v` and press Enter. You should see version 20.9 or newer. If not, install Node.js LTS and restart VS Code.
5. Type `npm install` and press Enter. This downloads the Next.js/React/Supabase dependencies. Internet connection is required.
6. **Do not run the site yet** if you want authentication and downloads to work: complete Part B and C first. You can run the appearance-only preview immediately using `npm run dev` without a `.env.local` file, but most features will be disabled.

## Part B — Set up Supabase database

1. Visit https://supabase.com/dashboard and create a **new project** if you haven't created one. Wait until the project dashboard becomes available.
2. Choose **SQL Editor → New query**.
3. In VS Code open `supabase/setup.sql`. Select **all** its contents and copy.
4. Paste the SQL into Supabase SQL Editor and press **Run**. The script creates profiles, videos, comments, votes, reports, downloads, payments and watch-party tables, plus security policies and 3 sample videos. Run this once.
5. Go to **Authentication → Providers → Email** and make sure Email is enabled.
6. For a six-digit email code rather than a link, go to **Authentication → Email Templates → Magic Link** and replace the email body with: `<h2>StreamNest verification</h2><p>Your code: {{ .Token }}</p>` then save. See https://supabase.com/docs/guides/auth/auth-email-templates. This matters: the UI asks the user to enter a code, not click a link.
7. If the default email provider refuses sending or rate-limits you, consult the Supabase Authentication SMTP setup. Test with an inbox allowed by your project; do not disable email verification to bypass authentication.
8. Go to **Project Settings → API** (in some dashboard versions, **Connect** or **API Keys**). Copy:
   - **Project URL**, typically `https://xxxxx.supabase.co`
   - **anon/publishable key** (a client-side key — it is acceptable to use in NEXT_PUBLIC variables)
   - **service_role/secret key** (SERVER ONLY — NEVER post this in chat, GitHub or browser code)
9. In the project folder, duplicate `.env.example` and rename the copy to `.env.local`.
10. Edit `.env.local` to enter the project URL and keys. Preserve the names exactly as shown:

```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-or-publishable-key
SUPABASE_SERVICE_ROLE_KEY=your-server-service-role-key
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_your_key_id
RAZORPAY_KEY_SECRET=your_test_secret
```

Never upload `.env.local` to GitHub. It is excluded by `.gitignore`.

## Part C — Razorpay test credentials

1. Open https://dashboard.razorpay.com and select **Test Mode**.
2. Find **Account & Settings → API Keys** and generate/copy your test Key ID and Key Secret.
3. Enter both in `.env.local`, using the field names above. Only use `rzp_test_...` keys for the demo.
4. The Plans section will launch Razorpay Checkout. Use Razorpay's supported test method and confirm that the profile plan changes afterward. Do not use real money.
5. The Account section can print the latest **test receipt**. Sending confirmation email automatically is OPTIONAL and needs an additional Resend sender/API setup, via `RESEND_API_KEY` and `RESEND_FROM_EMAIL`.

## Part D — Start the website

1. In VS Code terminal enter `npm run dev`.
2. Open http://localhost:3000 in Chrome.
3. Go to **Account**, enter your email, and enter the six-digit email OTP.
4. Test free video playback, comment posting, comment translation, reporting and reactions.
5. Try Free-plan downloads twice. The second should be rejected by the daily quota. Try a premium video while on Free; it should be locked.
6. Upgrade on the Plans tab using Razorpay Test Checkout and verify your new download limit.
7. Create a watch party in one browser, copy the room code, then sign in using a second test account in a different browser/incognito window and join the room. Playback should synchronize through Supabase realtime. The **Open video call** button opens Jitsi Meet in a separate browser tab for communication; it is not an embedded proprietary calling service.
8. Change the theme under Account. Auto mode uses **10 AM to 12 PM IST** for light, otherwise dark.

## Part E — GitHub repository link

1. Open https://github.com/new.
2. Repository name: `streamnest-internship`. Choose **Public**. Click **Create repository**.
3. From the repository page use **Add file → Upload files**. Drag the project folders/files (including nested `app`, `components`, `lib`, `supabase`, `public`; do NOT upload `node_modules`, `.next` or `.env.local`). Commit changes.
4. Confirm GitHub displays folders such as `app/api/payment` and `supabase/setup.sql`, not only a zipped archive.
5. Copy your actual repository address from the browser. Do not invent or guess the URL.

**Alternative with Git (if installed):**

```
git init
git add .
git commit -m "Build StreamNest internship features"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/streamnest-internship.git
git push -u origin main
```

Create the empty GitHub repo first; replace YOUR_USERNAME with your real GitHub username.

## Part F — Deploy on Vercel

1. Go to https://vercel.com/new, sign in, and authorize your GitHub account if asked.
2. Import `streamnest-internship`.
3. Framework should be detected automatically as **Next.js**.
4. Add five environment variables in **Environment Variables**, using the same values as your local `.env.local`:
   `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `NEXT_PUBLIC_RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`.
   Optional: `RESEND_API_KEY`, `RESEND_FROM_EMAIL`.
5. Choose **Deploy**. On build success, Vercel shows your actual `https://....vercel.app` URL.
6. Open the URL in a private/incognito browser window and confirm that the landing page loads and a test user can log in. The demo URL must work for the evaluator. Vercel automatic redeployments follow GitHub commits, but **your submitted form** cannot be edited once sent.
7. In Supabase **Authentication → URL Configuration**, set your public Site URL to the exact Vercel URL; include local `http://localhost:3000` and the actual Vercel URL in Redirect URLs if using email links.

## Part G — Record 2–5-minute demo

Use Windows **Win+G** (Xbox Game Bar, if available) or a screen-recording tool such as OBS. Record the ACTUAL deployed site and your voice. Keep MP4/WebM/MOV under 100 MB.

Suggested outline:
- 0:00–0:20 — Project name and objective.
- 0:20–0:55 — Mobile-responsive homepage and video controls.
- 0:55–1:35 — Email OTP, comments, language translations, likes/dislikes and report.
- 1:35–2:15 — Free/Premium download limit and Downloads profile.
- 2:15–2:55 — Bronze/Silver/Gold and verified Razorpay test upgrade and test receipt.
- 2:55–3:35 — Watch party invite, syncing, meeting link, light/dark themes.
- 3:35–3:55 — GitHub repository and deployed URL.

Watch the video yourself with sound before uploading. Do not falsely claim features were tested unless they actually worked.

## Important limitations to disclose

- This is a new starter repository. Your internship rule forbids replacing the training project, so confirm eligibility with your mentor. **Do not submit a newly made project as if it were an earlier training project.**
- The three demo videos use external/public sample URLs. Server-side quotas apply inside the application, but those third-party source files are publicly accessible outside it. For protected videos, upload a video you own/have rights to in a private Supabase Storage bucket named `videos` and use `video_url='private/yourfile.mp4'` in the videos table. Browser playback signed URLs can still be copied during validity; DRM requires a dedicated service.
- Translations use the public MyMemory API, which may rate-limit or fail; it is best for demonstrating rather than production traffic.
- Watch-party playback sync is Supabase Realtime; the video call/chat/screen-sharing comes from third-party Jitsi Meet, opened in a new tab. Optional recording is **not implemented**.
- All logins use email OTP; this verifies new devices but does not specifically detect city/state changes.
- Payment receipt is printable after verified test purchase; automatic email requires setting up the optional Resend integration.
- Passwordless sign-in may require configuring custom SMTP to send email OTP to arbitrary evaluators.

## Need help?

Your internship instructions give `training@elevanceskills.com` as the mentor-support email. Include your name, internship domain and working repository URL. Do not send them secrets or private API keys.
