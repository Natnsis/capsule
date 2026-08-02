import { useState, useEffect, useMemo } from "react";
import { View, Text, ScrollView, TouchableOpacity, RefreshControl } from "react-native";
import { useRouter } from "expo-router";
import { Plus, Inbox, Lock, Unlock, PenLine, ChevronRight } from "lucide-react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import {
  eachDayOfInterval,
  endOfWeek,
  format,
  isSameDay,
  isToday,
  startOfWeek,
  subDays,
  subWeeks,
} from "date-fns";

import type { Capsule, CapsuleStatus } from "@/types/capsule";
import {
  useCapsules,
  useCapsuleStats,
  useCheckReadyCapsules,
} from "@/hooks/use-capsules";
import { useProfileStore } from "@/stores/profile-store";
import { useBiometricStore } from "@/stores/biometric-store";
import { BiometricService } from "@/services/biometric-service";
import { CapsuleCard } from "@/components/capsules/capsule-card";
import { EmptyState } from "@/components/shared/empty-state";
import { Badge } from "@/components/ui/badge";
import { Dialog } from "@/components/shared/dialog";
import { colors } from "@/constants/colors";

type FilterType = CapsuleStatus | "all";

const filters: { key: FilterType; label: string }[] = [
  { key: "all", label: "All" },
  { key: "draft", label: "Draft" },
  { key: "sealed", label: "Sealed" },
  { key: "ready", label: "Ready" },
  { key: "opened", label: "Opened" },
];

const JOURNEY_WEEKS = 10;

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

export default function HomeScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [activeFilter, setActiveFilter] = useState<FilterType>("all");
  const [refreshing, setRefreshing] = useState(false);

  const { data: capsules, refetch } = useCapsules();
  const { data: stats } = useCapsuleStats();
  const checkReady = useCheckReadyCapsules();
  const { name } = useProfileStore();
  const biometricEnabled = useBiometricStore((s) => s.enabled);
  const setBiometricEnabled = useBiometricStore((s) => s.setEnabled);
  const promptedOnHome = useBiometricStore((s) => s.promptedOnHome);
  const setPromptedOnHome = useBiometricStore((s) => s.setPromptedOnHome);
  const [showBiometricAsk, setShowBiometricAsk] = useState(false);

  const filteredCapsules = capsules?.filter((c: Capsule) =>
    activeFilter === "all" ? true : c.status === activeFilter
  );

  const sealedCount = stats?.sealed ?? 0;
  const readyCount = stats?.ready ?? 0;

  // The one thing worth surfacing above everything else: capsules that are
  // ready right now beat the soonest-upcoming one, which beats a blank-slate
  // nudge to write a first capsule at all.
  const hero = useMemo(() => {
    const list = capsules ?? [];
    const ready = list.filter((c) => c.status === "ready");
    if (ready.length > 0) {
      return { type: "ready" as const, capsule: ready[0], count: ready.length };
    }
    const sealed = list
      .filter((c) => c.status === "sealed")
      .sort((a, b) => a.openAt - b.openAt);
    if (sealed.length > 0) {
      const days = Math.max(0, Math.ceil((sealed[0].openAt - Date.now()) / 86_400_000));
      return { type: "sealed" as const, capsule: sealed[0], days };
    }
    return { type: "empty" as const };
  }, [capsules]);

  // Last 7 days, with a dot under any day a capsule was written.
  const weekStrip = useMemo(() => {
    const today = new Date();
    return eachDayOfInterval({ start: subDays(today, 6), end: today }).map((day) => ({
      date: day,
      label: format(day, "EEE"),
      dayNum: format(day, "d"),
      today: isToday(day),
      hasCapsule: (capsules ?? []).some((c) => isSameDay(new Date(c.createdAt), day)),
    }));
  }, [capsules]);

  // A compact contribution-grid of the last ~10 weeks, one column per week,
  // one square per day, shaded by how many capsules were written that day.
  const journeyGrid = useMemo(() => {
    const gridStart = startOfWeek(subWeeks(new Date(), JOURNEY_WEEKS - 1));
    const gridEnd = endOfWeek(new Date());
    const days = eachDayOfInterval({ start: gridStart, end: gridEnd });
    const columns: { date: Date; count: number; future: boolean }[][] = [];
    for (let i = 0; i < days.length; i += 7) {
      columns.push(
        days.slice(i, i + 7).map((date) => ({
          date,
          future: date > new Date(),
          count: (capsules ?? []).filter((c) => isSameDay(new Date(c.createdAt), date)).length,
        }))
      );
    }
    return columns;
  }, [capsules]);

  const onRefresh = async () => {
    setRefreshing(true);
    await checkReady.mutateAsync();
    await refetch();
    setRefreshing(false);
  };

  // One-time ask: offer biometric capsule protection the first time the
  // user lands on Home, if the device actually supports it.
  useEffect(() => {
    if (promptedOnHome || biometricEnabled) return;
    BiometricService.isAvailable().then((available) => {
      if (available) setShowBiometricAsk(true);
      else setPromptedOnHome();
    });
  }, [promptedOnHome, biometricEnabled]);

  const declineBiometricAsk = () => {
    setShowBiometricAsk(false);
    setPromptedOnHome();
  };

  const acceptBiometricAsk = async () => {
    const ok = await BiometricService.authenticate();
    if (ok) setBiometricEnabled(true);
    setShowBiometricAsk(false);
    setPromptedOnHome();
  };

  const heroPress = () => {
    if (hero.type === "empty") router.push("/create");
    else router.push(`/capsule/${hero.capsule.id}`);
  };

  return (
    <>
      <Dialog
        visible={showBiometricAsk}
        title="Protect your capsules?"
        message="Face ID or fingerprint can lock individual capsules you choose to protect. You can always change this later in Settings."
        onClose={declineBiometricAsk}
        actions={[
          { label: "Not now", variant: "cancel", onPress: declineBiometricAsk },
          { label: "Enable", variant: "default", onPress: acceptBiometricAsk },
        ]}
      />

    <ScrollView
      className="flex-1 bg-cream dark:bg-brown"
      contentContainerStyle={{ paddingBottom: 120 }}
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={onRefresh}
          tintColor={colors.sage}
        />
      }
    >
      <View style={{ paddingTop: insets.top + 16 }} className="px-4 pb-2">
        {/* Header */}
        <View className="flex-row items-center justify-between mb-1">
          <View>
            <Text className="font-sans text-sm text-muted-foreground">
              {getGreeting()}
            </Text>
            <Text className="font-heading text-3xl font-bold text-brown dark:text-cream mt-0.5">
              Hi, {name || "there"}
            </Text>
          </View>
          <TouchableOpacity
            onPress={() => router.push("/(tabs)/settings")}
            className="w-11 h-11 rounded-full bg-sage items-center justify-center"
          >
            <Text className="font-heading text-lg font-bold text-cream">
              {(name || "G").charAt(0).toUpperCase()}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Hero card */}
        <TouchableOpacity
          onPress={heroPress}
          activeOpacity={0.85}
          className="bg-secondary rounded-3xl p-5 mt-5 flex-row items-center"
        >
          <View className="w-12 h-12 rounded-2xl bg-cream/20 items-center justify-center mr-4">
            {hero.type === "ready" ? (
              <Unlock size={22} color={colors.cream} />
            ) : hero.type === "sealed" ? (
              <Lock size={22} color={colors.cream} />
            ) : (
              <PenLine size={22} color={colors.cream} />
            )}
          </View>
          <View className="flex-1">
            <Text className="font-heading text-lg font-bold text-cream" numberOfLines={1}>
              {hero.type === "ready"
                ? hero.count > 1
                  ? `${hero.count} capsules ready to open`
                  : `"${hero.capsule.title}" is ready`
                : hero.type === "sealed"
                  ? hero.days === 0
                    ? `"${hero.capsule.title}" opens today`
                    : `${hero.days} ${hero.days === 1 ? "day" : "days"} until "${hero.capsule.title}"`
                  : "Write your first capsule"}
            </Text>
            <Text className="font-sans text-sm text-cream/70 mt-0.5">
              {hero.type === "ready"
                ? "Tap to open it now"
                : hero.type === "sealed"
                  ? "Sealed and counting down"
                  : "A message for your future self"}
            </Text>
          </View>
          <ChevronRight size={20} color={colors.cream} />
        </TouchableOpacity>

        {/* Week strip */}
        <View className="flex-row justify-between mt-5 px-1">
          {weekStrip.map((d) => (
            <View key={d.date.toISOString()} className="items-center">
              <Text className="font-sans text-xs text-muted-foreground mb-1.5">
                {d.label}
              </Text>
              <View
                className={`w-8 h-8 rounded-full items-center justify-center ${
                  d.today ? "bg-sage" : ""
                }`}
              >
                <Text
                  className={`font-sans text-sm ${
                    d.today ? "text-cream font-semibold" : "text-brown dark:text-cream"
                  }`}
                >
                  {d.dayNum}
                </Text>
              </View>
              <View
                className={`w-1 h-1 rounded-full mt-1.5 ${
                  d.hasCapsule ? "bg-secondary" : "bg-transparent"
                }`}
              />
            </View>
          ))}
        </View>

        {/* Stats row */}
        <View className="flex-row gap-3 mb-2 mt-6">
          <TouchableOpacity
            onPress={() => setActiveFilter("sealed")}
            className="flex-1 bg-sage rounded-2xl p-4"
          >
            <Lock size={20} color={colors.cream} />
            <Text className="font-heading text-3xl font-bold text-cream mt-3">
              {sealedCount}
            </Text>
            <Text className="font-sans text-xs text-cream/70 mt-0.5">Sealed</Text>
          </TouchableOpacity>
          <TouchableOpacity
            onPress={() => setActiveFilter("ready")}
            className="flex-1 bg-card dark:bg-brown-card rounded-2xl p-4 border border-border/50 dark:border-brown-light/50"
          >
            <Inbox size={20} color={colors.sage} />
            <Text className="font-heading text-3xl font-bold text-brown dark:text-cream mt-3">
              {readyCount}
            </Text>
            <Text className="font-sans text-xs text-muted-foreground mt-0.5">
              Ready to open
            </Text>
          </TouchableOpacity>
        </View>

        {/* Your Journey — contribution grid */}
        <View className="mt-4 mb-2">
          <Text className="font-heading text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">
            Your Journey
          </Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View className="flex-row gap-1">
              {journeyGrid.map((column, colIdx) => (
                <View key={colIdx} className="gap-1">
                  {column.map((cell) => (
                    <View
                      key={cell.date.toISOString()}
                      className={`w-3 h-3 rounded-sm ${
                        cell.future
                          ? "bg-transparent"
                          : cell.count === 0
                            ? "bg-muted dark:bg-brown-light"
                            : cell.count === 1
                              ? "bg-sage/40"
                              : cell.count === 2
                                ? "bg-sage/70"
                                : "bg-sage"
                      }`}
                    />
                  ))}
                </View>
              ))}
            </View>
          </ScrollView>
        </View>

        {/* Filters */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          className="mt-3 mb-4"
        >
          <View className="flex-row gap-2 px-1">
            {filters.map((f) => (
              <TouchableOpacity key={f.key} onPress={() => setActiveFilter(f.key)}>
                <Badge
                  variant={activeFilter === f.key ? "active" : "outline"}
                  label={f.label}
                />
              </TouchableOpacity>
            ))}
          </View>
        </ScrollView>
      </View>

      {/* Capsule list */}
      {!filteredCapsules || filteredCapsules.length === 0 ? (
        <EmptyState
          type={
            activeFilter === "all" || activeFilter === "sealed"
              ? "sealed"
              : activeFilter === "draft"
                ? "draft"
                : activeFilter === "ready"
                  ? "ready"
                  : "opened"
          }
        />
      ) : (
        <View className="px-4 gap-4">
          {filteredCapsules.map((capsule: Capsule) => (
            <CapsuleCard
              key={capsule.id}
              capsule={capsule}
              onPress={() => router.push(`/capsule/${capsule.id}`)}
            />
          ))}
        </View>
      )}

      {/* FAB */}
      <TouchableOpacity
        onPress={() => router.push("/create")}
        className="absolute bottom-6 right-6 bg-sage rounded-full w-14 h-14 items-center justify-center shadow-lg shadow-sage/30"
      >
        <Plus size={28} color={colors.cream} />
      </TouchableOpacity>
    </ScrollView>
    </>
  );
}
