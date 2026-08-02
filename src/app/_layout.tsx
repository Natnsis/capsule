import { useEffect, useState, useRef } from "react";
import { View, ActivityIndicator } from "react-native";
import { Stack, useRouter, useSegments } from "expo-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useColorScheme } from "nativewind";
import {
  useFonts,
  Outfit_400Regular,
  Outfit_600SemiBold,
  Outfit_700Bold,
} from "@expo-google-fonts/outfit";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { GestureHandlerRootView } from "react-native-gesture-handler";

import { useThemeStore } from "@/stores/theme-store";
import { useOnboardingStore } from "@/stores/onboarding-store";
import { useNotificationStore } from "@/stores/notification-store";
import { CapsuleRepository } from "@/db/repositories/capsule-repository";
import { colors } from "@/constants/colors";
import { NotificationService } from "@/services/notification-service";
import { reconcileCapsuleReminders } from "@/hooks/use-capsules";

import "../global.css";

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient();

export default function RootLayout() {
  const router = useRouter();
  const segments = useSegments();
  const mode = useThemeStore((s) => s.mode);
  const { completed: onboardingCompleted } = useOnboardingStore();
  const { prompted, setPrompted } = useNotificationStore();
  const { colorScheme: nwScheme, setColorScheme } = useColorScheme();

  const [fontsLoaded] = useFonts({
    Outfit_400Regular,
    Outfit_600SemiBold,
    Outfit_700Bold,
  });

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

  useEffect(() => {
    if (!fontsLoaded) return;
    (async () => {
      await CapsuleRepository.checkAndUpdateReadyCapsules();
      SplashScreen.hideAsync();
      bootedRef.current = true;
      setBooted(true);
      reconcileCapsuleReminders();
    })();
  }, [fontsLoaded]);

  // Navigate to the relevant capsule when a reminder notification is tapped —
  // both while the app is running and on cold start from a killed state.
  useEffect(() => {
    if (!booted) return;

    NotificationService.getInitialCapsuleId().then((capsuleId) => {
      if (capsuleId) router.push(`/capsule/${capsuleId}`);
    });

    let subscription: { remove: () => void } | undefined;
    NotificationService.addResponseListener((capsuleId) => {
      router.push(`/capsule/${capsuleId}`);
    }).then((sub) => {
      subscription = sub;
    });

    return () => subscription?.remove();
  }, [booted]);

  // Fire OS notification permission request once, after onboarding
  useEffect(() => {
    if (!booted) return;
    if (!onboardingCompleted) return;
    if (prompted) return;
    setPrompted();
    NotificationService.requestPermission();
  }, [booted, onboardingCompleted, prompted]);

  useEffect(() => {
    if (!booted) return;
    const inOnboarding = segments[0] === "onboarding";
    if (!onboardingCompleted && !inOnboarding) {
      router.replace("/onboarding");
    }
  }, [booted, onboardingCompleted, segments]);

  if (!fontsLoaded || !booted) {
    return (
      <View className="flex-1 items-center justify-center bg-cream dark:bg-brown">
        <ActivityIndicator size="large" color={colors.sage} />
      </View>
    );
  }

  return (
    <GestureHandlerRootView className="flex-1">
      <QueryClientProvider client={queryClient}>
        <SafeAreaProvider>
          <View className="flex-1 bg-cream dark:bg-brown">
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
