import * as SQLite from "expo-sqlite";

let db: SQLite.SQLiteDatabase | null = null;

export async function getDatabase(): Promise<SQLite.SQLiteDatabase> {
  if (!db) {
    db = await SQLite.openDatabaseAsync("timecapsule.db");
    await initializeDatabase(db);
  }
  return db;
}

async function initializeDatabase(database: SQLite.SQLiteDatabase): Promise<void> {
  await database.execAsync(`
    PRAGMA journal_mode = WAL;
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS capsules (
      id TEXT PRIMARY KEY NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      open_at INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'sealed' CHECK(status IN ('sealed', 'ready', 'opened')),
      opened_at INTEGER,
      tags TEXT DEFAULT '[]',
      image_uris TEXT DEFAULT '[]',
      notification_id TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_capsules_status ON capsules(status);
    CREATE INDEX IF NOT EXISTS idx_capsules_open_at ON capsules(open_at);
  `);
}
