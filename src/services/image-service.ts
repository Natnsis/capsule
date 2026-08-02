import * as FileSystem from "expo-file-system/legacy";

const IMAGES_DIR = `${FileSystem.documentDirectory}capsule-images/`;

export const ImageService = {
  // expo-image-picker returns cache-directory URIs the OS can purge; capsules
  // are sealed for months or years, so picked images must be copied into
  // permanent storage at seal time.
  async persistImages(capsuleId: string, uris: string[]): Promise<string[]> {
    if (uris.length === 0) return [];

    const dir = `${IMAGES_DIR}${capsuleId}/`;
    await FileSystem.makeDirectoryAsync(dir, { intermediates: true }).catch(() => {});

    const persisted: string[] = [];
    for (let i = 0; i < uris.length; i++) {
      const uri = uris[i];
      const ext = uri.split(".").pop()?.split("?")[0] || "jpg";
      const dest = `${dir}${i}.${ext}`;
      try {
        await FileSystem.copyAsync({ from: uri, to: dest });
        persisted.push(dest);
      } catch {
        persisted.push(uri);
      }
    }
    return persisted;
  },

  async deleteImages(capsuleId: string): Promise<void> {
    const dir = `${IMAGES_DIR}${capsuleId}/`;
    await FileSystem.deleteAsync(dir, { idempotent: true }).catch(() => {});
  },
};
