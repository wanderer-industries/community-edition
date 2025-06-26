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

---

# 📘 Configuring Additional ESI Tracking Pools

Wanderer Community Edition supports extending character tracking capacity by adding **up to 10 additional tracking pools**. Each tracking pool allows tracking **up to 300 characters by default**, configurable via an environment variable.

---

## 🔧 Step-by-Step: Add a New Tracking Pool

### Register a New ESI App

Each tracking pool requires its own ESI app registered with CCP.

Follow the standard ESI app setup instructions here:  
👉 [Wanderer ESI API Keys Setup](https://github.com/wanderer-industries/community-edition?tab=readme-ov-file#eve-api-keys)

We recommend naming your apps with a postfix for easier tracking, such as:

```
Wanderer Production:1
Wanderer Production:2
…
Wanderer Production:10
```

---

### Update `wanderer-conf.env` File

After registering the new ESI app:

Add the credentials to your environment file using the following format:

```env
EVE_CLIENT_ID_1=<app_id_1>
EVE_CLIENT_SECRET_1=<app_secret_1>

EVE_CLIENT_ID_2=<app_id_2>
EVE_CLIENT_SECRET_2=<app_secret_2>

# ...up to EVE_CLIENT_ID_10 / EVE_CLIENT_SECRET_10
```

> 📝 Note: These variables support up to 10 tracking pools in total. DON'T add empty string variable, only for registered ID/SECRET

### (Optional) Configure Pool Size Limit

By default, each tracking pool handles up to 300 characters. You can override this with:

```env
WANDERER_TRACKING_POOL_MAX_SIZE=300
```
Adjust the value based on your infrastructure capacity and requirements.

## 🔄 Automatic Distribution of Characters

Once new pools are added and configured:
	•	All newly authorized or re-authorized characters will be distributed across available pools.
	•	The distribution is automatic and aims to balance the load across all pools.

⸻

## 📊 Monitoring Tracking Pools

A new tracking pools widget available on admin page:

```
/admin
```

This interface allows you to:
	•	View current character distribution per pool
	•	Monitor pool load and identify when to scale further
