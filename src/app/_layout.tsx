import { useEffect, useState, useRef } from "react";
import { View, ActivityIndicator, AppState } from "react-native";
import { Stack, useRouter, useSegments } from "expo-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useColorScheme } from "nativewind";
import {
  useFonts,
  Manrope_400Regular,
  Manrope_600SemiBold,
  Manrope_700Bold,
} from "@expo-google-fonts/manrope";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { GestureHandlerRootView } from "react-native-gesture-handler";

import { useThemeStore } from "@/stores/theme-store";
import { useBiometricStore } from "@/stores/biometric-store";
import { useOnboardingStore } from "@/stores/onboarding-store";
import { useNotificationStore } from "@/stores/notification-store";
import { CapsuleRepository } from "@/db/repositories/capsule-repository";
import { NotificationService } from "@/services/notification-service";
import { LockScreen } from "@/components/shared/lock-screen";

import "../global.css";

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient();

export default function RootLayout() {
  const router = useRouter();
  const segments = useSegments();
  const mode = useThemeStore((s) => s.mode);
  const biometricEnabled = useBiometricStore((s) => s.enabled);
  const { completed: onboardingCompleted } = useOnboardingStore();
  const { prompted, setPrompted } = useNotificationStore();
  const { colorScheme: nwScheme, setColorScheme } = useColorScheme();

  const [fontsLoaded] = useFonts({
    Manrope_400Regular,
    Manrope_600SemiBold,
    Manrope_700Bold,
  });

  const [locked, setLocked] = useState(false);
  const [booted, setBooted] = useState(false);
  const bootedRef = useRef(false);

  // Sync theme store -> nativewind immediately via subscription
  useEffect(() => {
    setColorScheme(mode);
    const unsub = useThemeStore.subscribe((state, prev) => {
      if (prev && state.mode !== prev.mode) {
        setColorScheme(state.mode);
      }
    });
    return unsub;
  }, []);

  // App lifecycle — lock on background when biometrics enabled
  useEffect(() => {
    const sub = AppState.addEventListener("change", (state) => {
      if (biometricEnabled && bootedRef.current && state === "active") {
        setLocked(true);
      }
    });
    return () => sub.remove();
  }, [biometricEnabled]);

  useEffect(() => {
    if (!fontsLoaded) return;
    (async () => {
      await CapsuleRepository.checkAndUpdateReadyCapsules();
      SplashScreen.hideAsync();
      bootedRef.current = true;
      setBooted(true);
      if (biometricEnabled) setLocked(true);
    })();
  }, [fontsLoaded]);

  // Fire OS notification permission request once, after onboarding
  useEffect(() => {
    if (!booted) return;
    if (!onboardingCompleted) return;
    if (prompted) return;
    if (locked) return;
    setPrompted();
    NotificationService.requestPermission();
  }, [booted, onboardingCompleted, prompted, locked]);

  useEffect(() => {
    if (!booted) return;
    const inOnboarding = segments[0] === "onboarding";
    if (!onboardingCompleted && !inOnboarding) {
      router.replace("/onboarding");
    }
  }, [booted, onboardingCompleted, segments]);

  if (!fontsLoaded || !booted) {
    return (
      <View className="flex-1 items-center justify-center bg-[#F2EFEA]">
        <ActivityIndicator size="large" color="#82B090" />
      </View>
    );
  }

  if (locked && biometricEnabled) {
    return <LockScreen onUnlock={() => setLocked(false)} />;
  }

  return (
    <GestureHandlerRootView className="flex-1">
      <QueryClientProvider client={queryClient}>
        <SafeAreaProvider>
          <View className="flex-1 bg-[#F2EFEA] dark:bg-[#41393C]">
            <StatusBar style={nwScheme === "dark" ? "light" : "dark"} />
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="onboarding" />
              <Stack.Screen name="(tabs)" />
              <Stack.Screen
                name="create/index"
                options={{ presentation: "modal" }}
              />
              <Stack.Screen
                name="create/preview"
                options={{ presentation: "modal" }}
              />
              <Stack.Screen name="capsule/[id]" />
              <Stack.Screen
                name="unlock/[id]"
                options={{ presentation: "fullScreenModal" }}
              />
            </Stack>
          </View>
        </SafeAreaProvider>
      </QueryClientProvider>
    </GestureHandlerRootView>
  );
}
