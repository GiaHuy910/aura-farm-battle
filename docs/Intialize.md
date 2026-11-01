- npx create-next-app@latest
  db.sessions.createIndex(
  { expiresAt: 1 },
  { expireAfterSeconds: 0 }
  )
- db.gachahistories.createIndex({ user_id: 1, item_type: 1, \_id: -1 })
