import { useEffect, useRef, useCallback } from "react";
import { View, useColorScheme, ActivityIndicator } from "react-native";
import { Stack, useRouter, useSegments } from "expo-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
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
import { useOnboardingStore } from "@/stores/onboarding-store";
import { CapsuleRepository } from "@/db/repositories/capsule-repository";

import "../global.css";

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient();

export default function RootLayout() {
  const router = useRouter();
  const segments = useSegments();
  const systemScheme = useColorScheme();
  const { mode, isDark } = useThemeStore();
  const { completed: onboardingCompleted } = useOnboardingStore();

  const [fontsLoaded] = useFonts({
    Manrope_400Regular,
    Manrope_600SemiBold,
    Manrope_700Bold,
  });

  const initialized = useRef(false);

  useEffect(() => {
    if (!fontsLoaded || initialized.current) return;
    initialized.current = true;

    CapsuleRepository.checkAndUpdateReadyCapsules();
    SplashScreen.hideAsync();
  }, [fontsLoaded]);

  useEffect(() => {
    if (!fontsLoaded) return;
    const inOnboarding = segments[0] === "onboarding";
    if (!onboardingCompleted && !inOnboarding) {
      router.replace("/onboarding");
    }
  }, [fontsLoaded, onboardingCompleted, segments]);

  const effectiveDark =
    mode === "system" ? systemScheme === "dark" : mode === "dark";

  if (!fontsLoaded) {
    return (
      <View className="flex-1 items-center justify-center bg-[#F2EFEA] dark:bg-[#41393C]">
        <ActivityIndicator size="large" color="#82B090" />
      </View>
    );
  }

  return (
    <GestureHandlerRootView className={`flex-1 ${effectiveDark ? "dark" : ""}`}>
      <QueryClientProvider client={queryClient}>
        <SafeAreaProvider>
          <View className="flex-1 bg-[#F2EFEA] dark:bg-[#41393C]">
            <StatusBar style={effectiveDark ? "light" : "dark"} />
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
