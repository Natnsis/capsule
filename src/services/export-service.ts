import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { getDatabase } from "@/db/database";

const EXPORT_FILENAME = "timecapsule-backup.db";

export const ExportService = {
  async exportDatabase(): Promise<string | null> {
    try {
      await getDatabase();
      const dbDir = `${FileSystem.documentDirectory}SQLite/`;
      const dbPath = `${dbDir}timecapsule.db`;
      const destPath = `${FileSystem.cacheDirectory}${EXPORT_FILENAME}`;

      const dirInfo = await FileSystem.getInfoAsync(dbDir);
      if (!dirInfo.exists) {
        await FileSystem.makeDirectoryAsync(dbDir, { intermediates: true });
      }

      await FileSystem.copyAsync({ from: dbPath, to: destPath });

      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(destPath, {
          mimeType: "application/octet-stream",
          dialogTitle: "Export TimeCapsule Data",
        });
      }

      return destPath;
    } catch (error) {
      console.error("Export failed:", error);
      return null;
    }
  },

  async importDatabase(uri: string): Promise<boolean> {
    try {
      const dbDir = `${FileSystem.documentDirectory}SQLite/`;
      const dbPath = `${dbDir}timecapsule.db`;
      const backupPath = `${dbPath}.backup`;

      const dbInfo = await FileSystem.getInfoAsync(dbPath);
      if (dbInfo.exists) {
        await FileSystem.moveAsync({ from: dbPath, to: backupPath });
      }

      await FileSystem.copyAsync({ from: uri, to: dbPath });

      return true;
    } catch (error) {
      console.error("Import failed:", error);
      return false;
    }
  },
};
