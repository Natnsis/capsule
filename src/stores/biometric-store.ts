import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import AsyncStorage from "@react-native-async-storage/async-storage";

interface BiometricState {
  enabled: boolean;
  setEnabled: (val: boolean) => void;
  promptedOnHome: boolean;
  setPromptedOnHome: () => void;
}

export const useBiometricStore = create<BiometricState>()(
  persist(
    (set) => ({
      enabled: false,
      setEnabled: (enabled) => set({ enabled }),
      promptedOnHome: false,
      setPromptedOnHome: () => set({ promptedOnHome: true }),
    }),
    {
      name: "biometric-storage",
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
