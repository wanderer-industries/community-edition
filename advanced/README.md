# How to Enable Wallet Tracking in Wanderer

You can enable wallet tracking using a separate ESI app and a few configuration steps. Follow the instructions below:

---

## 1. Create a New ESI App

Register a **new ESI app** with the **same configuration** as your main app, but with the **following scopes**:

```
esi-location.read_location.v1
esi-location.read_ship_type.v1
esi-location.read_online.v1
esi-ui.write_waypoint.v1
esi-search.search_structures.v1
esi-wallet.read_character_wallet.v1
```

---

## 2. Set Up Environment Variables

Add the following environment variables in your configuration:

```
EVE_CLIENT_WITH_WALLET_ID=your-esi-app-id
EVE_CLIENT_WITH_WALLET_SECRET=your-esi-app-secret
```

---

## 3. Enable Wallet Tracking

To enable wallet tracking, set the following variable:

```
WANDERER_WALLET_TRACKING_ENABLED=true
```

---

## 4. Restart the App

Restart the app to apply the changes.

---

---

## 4. Final Steps

Once enabled, you'll see a new option available on the `/characters` page.
It’s recommended to **authenticate all 'main' characters** on your server using the wallet-enabled app.
You can **leave alt characters** using the base app credentials.

> ℹ️ Characters authenticated with wallet access will use a **separate rate limit pool**, reducing the chance of hitting ESI limits for your main accounts.

---

✅ **Done!** You’re now tracking character wallets in Wanderer.
