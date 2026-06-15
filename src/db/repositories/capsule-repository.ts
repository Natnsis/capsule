import * as SQLite from "expo-sqlite";
import { getDatabase } from "@/db/database";
import type { Capsule, CreateCapsuleInput, CapsuleStatus } from "@/types/capsule";
import { isOpenable } from "@/lib/date";

function rowToCapsule(row: any): Capsule {
  return {
    id: row.id,
    title: row.title,
    content: row.content,
    createdAt: row.created_at,
    openAt: row.open_at,
    status: row.status as CapsuleStatus,
    openedAt: row.opened_at,
    tags: JSON.parse(row.tags || "[]"),
    imageUris: JSON.parse(row.image_uris || "[]"),
    notificationId: row.notification_id,
  };
}

export const CapsuleRepository = {
  async getAll(): Promise<Capsule[]> {
    const db = await getDatabase();
    const rows = await db.getAllAsync(
      "SELECT * FROM capsules ORDER BY created_at DESC"
    );
    return rows.map(rowToCapsule);
  },

  async getById(id: string): Promise<Capsule | null> {
    const db = await getDatabase();
    const row = await db.getFirstAsync(
      "SELECT * FROM capsules WHERE id = ?",
      [id]
    );
    return row ? rowToCapsule(row) : null;
  },

  async getByStatus(status: CapsuleStatus): Promise<Capsule[]> {
    const db = await getDatabase();
    const rows = await db.getAllAsync(
      "SELECT * FROM capsules WHERE status = ? ORDER BY created_at DESC",
      [status]
    );
    return rows.map(rowToCapsule);
  },

  async create(input: CreateCapsuleInput): Promise<Capsule> {
    const db = await getDatabase();
    const id = generateId();
    const now = Date.now();

    await db.runAsync(
      `INSERT INTO capsules (id, title, content, created_at, open_at, status, tags, image_uris)
       VALUES (?, ?, ?, ?, ?, 'sealed', ?, ?)`,
      [
        id,
        input.title,
        input.content,
        now,
        input.openAt,
        JSON.stringify(input.tags || []),
        JSON.stringify(input.imageUris || []),
      ]
    );

    return {
      id,
      title: input.title,
      content: input.content,
      createdAt: now,
      openAt: input.openAt,
      status: "sealed",
      openedAt: null,
      tags: input.tags || [],
      imageUris: input.imageUris || [],
      notificationId: null,
    };
  },

  async updateStatus(id: string, status: CapsuleStatus): Promise<void> {
    const db = await getDatabase();
    const now = status === "opened" ? Date.now() : null;
    await db.runAsync(
      "UPDATE capsules SET status = ?, opened_at = ? WHERE id = ?",
      [status, now, id]
    );
  },

  async setNotificationId(id: string, notificationId: string): Promise<void> {
    const db = await getDatabase();
    await db.runAsync(
      "UPDATE capsules SET notification_id = ? WHERE id = ?",
      [notificationId, id]
    );
  },

  async delete(id: string): Promise<void> {
    const db = await getDatabase();
    await db.runAsync("DELETE FROM capsules WHERE id = ?", [id]);
  },

  async search(query: string): Promise<Capsule[]> {
    const db = await getDatabase();
    const rows = await db.getAllAsync(
      `SELECT * FROM capsules
       WHERE title LIKE ? OR content LIKE ? OR tags LIKE ?
       ORDER BY created_at DESC`,
      [`%${query}%`, `%${query}%`, `%${query}%`]
    );
    return rows.map(rowToCapsule);
  },

  async getStats(): Promise<{
    total: number;
    sealed: number;
    ready: number;
    opened: number;
  }> {
    const db = await getDatabase();
    const row = await db.getFirstAsync<{
      total: number;
      sealed: number;
      ready: number;
      opened: number;
    }>(
      `SELECT
         COUNT(*) as total,
         SUM(CASE WHEN status = 'sealed' THEN 1 ELSE 0 END) as sealed,
         SUM(CASE WHEN status = 'ready' THEN 1 ELSE 0 END) as ready,
         SUM(CASE WHEN status = 'opened' THEN 1 ELSE 0 END) as opened
       FROM capsules`
    );
    return {
      total: row?.total ?? 0,
      sealed: row?.sealed ?? 0,
      ready: row?.ready ?? 0,
      opened: row?.opened ?? 0,
    };
  },

  async checkAndUpdateReadyCapsules(): Promise<number> {
    const db = await getDatabase();
    const now = Date.now();
    const result = await db.runAsync(
      `UPDATE capsules SET status = 'ready'
       WHERE status = 'sealed' AND open_at <= ?`,
      [now]
    );
    return result.changes;
  },
};

function generateId(): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 8);
  return `${timestamp}-${random}`;
}
