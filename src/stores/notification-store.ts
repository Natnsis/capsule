import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import AsyncStorage from "@react-native-async-storage/async-storage";

interface NotificationState {
  prompted: boolean;
  setPrompted: () => void;
}

export const useNotificationStore = create<NotificationState>()(
  persist(
    (set) => ({
      prompted: false,
      setPrompted: () => set({ prompted: true }),
    }),
    {
      name: "notification-store",
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
