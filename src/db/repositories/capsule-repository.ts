import { getDatabase } from "@/db/database";
import { ImageService } from "@/services/image-service";
import type { Capsule, CreateCapsuleInput, CapsuleStatus } from "@/types/capsule";

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
    notificationIds: JSON.parse(row.notification_ids || "[]"),
    requireBiometric: !!row.require_biometric,
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
    const status = input.status ?? "sealed";
    const persistedImageUris = await ImageService.persistImages(
      id,
      input.imageUris || []
    );

    await db.runAsync(
      `INSERT INTO capsules (id, title, content, created_at, open_at, status, tags, image_uris, notification_ids, require_biometric)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, '[]', ?)`,
      [
        id,
        input.title,
        input.content,
        now,
        input.openAt,
        status,
        JSON.stringify(input.tags || []),
        JSON.stringify(persistedImageUris),
        input.requireBiometric ? 1 : 0,
      ]
    );

    return {
      id,
      title: input.title,
      content: input.content,
      createdAt: now,
      openAt: input.openAt,
      status,
      openedAt: null,
      tags: input.tags || [],
      imageUris: persistedImageUris,
      notificationIds: [],
      requireBiometric: !!input.requireBiometric,
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

  // Locks a draft: content becomes hidden again and the countdown to
  // openAt starts, exactly like sealing at creation time.
  async sealDraft(id: string): Promise<Capsule | null> {
    const db = await getDatabase();
    await db.runAsync(
      "UPDATE capsules SET status = 'sealed' WHERE id = ? AND status = 'draft'",
      [id]
    );
    return this.getById(id);
  },

  async setNotificationIds(id: string, notificationIds: string[]): Promise<void> {
    const db = await getDatabase();
    await db.runAsync(
      "UPDATE capsules SET notification_ids = ? WHERE id = ?",
      [JSON.stringify(notificationIds), id]
    );
  },

  async addNotificationIds(id: string, newIds: string[]): Promise<void> {
    if (newIds.length === 0) return;
    const capsule = await this.getById(id);
    if (!capsule) return;
    await this.setNotificationIds(id, [...capsule.notificationIds, ...newIds]);
  },

  async delete(id: string): Promise<void> {
    const db = await getDatabase();
    await db.runAsync("DELETE FROM capsules WHERE id = ?", [id]);
    await ImageService.deleteImages(id);
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
    drafts: number;
    sealed: number;
    ready: number;
    opened: number;
  }> {
    const db = await getDatabase();
    const row = await db.getFirstAsync<{
      total: number;
      drafts: number;
      sealed: number;
      ready: number;
      opened: number;
    }>(
      `SELECT
         COUNT(*) as total,
         SUM(CASE WHEN status = 'draft' THEN 1 ELSE 0 END) as drafts,
         SUM(CASE WHEN status = 'sealed' THEN 1 ELSE 0 END) as sealed,
         SUM(CASE WHEN status = 'ready' THEN 1 ELSE 0 END) as ready,
         SUM(CASE WHEN status = 'opened' THEN 1 ELSE 0 END) as opened
       FROM capsules`
    );
    return {
      total: row?.total ?? 0,
      drafts: row?.drafts ?? 0,
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
