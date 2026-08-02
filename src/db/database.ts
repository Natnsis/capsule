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
      status TEXT NOT NULL DEFAULT 'sealed' CHECK(status IN ('draft', 'sealed', 'ready', 'opened')),
      opened_at INTEGER,
      tags TEXT DEFAULT '[]',
      image_uris TEXT DEFAULT '[]',
      notification_id TEXT,
      notification_ids TEXT DEFAULT '[]',
      require_biometric INTEGER DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_capsules_status ON capsules(status);
    CREATE INDEX IF NOT EXISTS idx_capsules_open_at ON capsules(open_at);
  `);

  // Migrate databases created before notification_ids / require_biometric existed.
  const columns = await database.getAllAsync<{ name: string }>(
    "PRAGMA table_info(capsules)"
  );
  const columnNames = new Set(columns.map((c) => c.name));

  if (!columnNames.has("notification_ids")) {
    await database.execAsync(
      "ALTER TABLE capsules ADD COLUMN notification_ids TEXT DEFAULT '[]'"
    );
  }
  if (!columnNames.has("require_biometric")) {
    await database.execAsync(
      "ALTER TABLE capsules ADD COLUMN require_biometric INTEGER DEFAULT 0"
    );
  }

  // Widen the status CHECK constraint to allow 'draft' for databases created
  // before drafts existed — ALTER TABLE can't modify a CHECK constraint
  // directly, so rebuild the table.
  const tableInfo = await database.getFirstAsync<{ sql: string }>(
    "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'capsules'"
  );
  if (tableInfo && !tableInfo.sql.includes("'draft'")) {
    await database.execAsync(`
      ALTER TABLE capsules RENAME TO capsules_old;

      CREATE TABLE capsules (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        open_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'sealed' CHECK(status IN ('draft', 'sealed', 'ready', 'opened')),
        opened_at INTEGER,
        tags TEXT DEFAULT '[]',
        image_uris TEXT DEFAULT '[]',
        notification_id TEXT,
        notification_ids TEXT DEFAULT '[]',
        require_biometric INTEGER DEFAULT 0
      );

      INSERT INTO capsules SELECT * FROM capsules_old;
      DROP TABLE capsules_old;

      CREATE INDEX IF NOT EXISTS idx_capsules_status ON capsules(status);
      CREATE INDEX IF NOT EXISTS idx_capsules_open_at ON capsules(open_at);
    `);
  }
}
