import { useState } from "react";
import { View, Text, ScrollView, TouchableOpacity, RefreshControl } from "react-native";
import { useRouter } from "expo-router";
import {
  Plus,
  Clock,
  Inbox,
  Archive,
  Sparkles,
  Lock,
  Timer,
} from "lucide-react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import type { Capsule, CapsuleStatus } from "@/types/capsule";
import {
  useCapsules,
  useCapsuleStats,
  useCheckReadyCapsules,
} from "@/hooks/use-capsules";
import { useProfileStore } from "@/stores/profile-store";
import { CapsuleCard } from "@/components/capsules/capsule-card";
import { EmptyState } from "@/components/shared/empty-state";
import { Badge } from "@/components/ui/badge";

type FilterType = CapsuleStatus | "all";

const filters: { key: FilterType; label: string }[] = [
  { key: "all", label: "All" },
  { key: "sealed", label: "Sealed" },
  { key: "ready", label: "Ready" },
  { key: "opened", label: "Opened" },
];

export default function HomeScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [activeFilter, setActiveFilter] = useState<FilterType>("all");
  const [refreshing, setRefreshing] = useState(false);

  const { data: capsules, refetch } = useCapsules();
  const { data: stats } = useCapsuleStats();
  const checkReady = useCheckReadyCapsules();
  const { name } = useProfileStore();

  const filteredCapsules = capsules?.filter((c: Capsule) =>
    activeFilter === "all" ? true : c.status === activeFilter
  );

  const sealedCount = stats?.sealed ?? 0;
  const readyCount = stats?.ready ?? 0;

  const onRefresh = async () => {
    setRefreshing(true);
    await checkReady.mutateAsync();
    await refetch();
    setRefreshing(false);
  };

  return (
    <ScrollView
      className="flex-1 bg-[#F2EFEA] dark:bg-[#41393C]"
      contentContainerStyle={{ paddingBottom: 120 }}
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={onRefresh}
          tintColor="#82B090"
        />
      }
    >
      <View style={{ paddingTop: insets.top + 16 }} className="px-4 pb-2">
        {/* Header */}
        <View className="flex-row items-center justify-between mb-2">
          <View>
            <Text className="font-heading text-3xl font-bold text-[#41393C] dark:text-[#F2EFEA]">
              TimeCapsule
            </Text>
            <Text className="font-sans text-sm text-[#7A6E71] mt-0.5">
              {sealedCount > 0
                ? `${sealedCount} sealed · ${readyCount} ready`
                : "Write to your future self"}
            </Text>
          </View>
          <TouchableOpacity
            onPress={() => router.push("/(tabs)/settings")}
            className="w-11 h-11 rounded-full bg-sage items-center justify-center"
          >
            <Text className="font-heading text-lg font-bold text-[#F2EFEA]">
              {(name || "G").charAt(0).toUpperCase()}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Stats row */}
        <View className="flex-row gap-3 mb-6 mt-3">
          <TouchableOpacity
            onPress={() => setActiveFilter("ready")}
            className="flex-1 bg-sage rounded-2xl p-4"
          >
            <Inbox size={22} color="#F2EFEA" />
            <Text className="font-heading text-2xl font-bold text-[#F2EFEA] mt-2">
              {readyCount}
            </Text>
            <Text className="font-sans text-xs text-[#F2EFEA]/70">
              Ready to open
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            onPress={() => setActiveFilter("sealed")}
            className="flex-1 bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl p-4"
          >
            <Lock size={22} color="#7A6E71" />
            <Text className="font-heading text-2xl font-bold text-[#41393C] dark:text-[#F2EFEA] mt-2">
              {sealedCount}
            </Text>
            <Text className="font-sans text-xs text-[#7A6E71]">Sealed</Text>
          </TouchableOpacity>
        </View>

        {/* Filters */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          className="mb-4"
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
        <Plus size={28} color="#F2EFEA" />
      </TouchableOpacity>
    </ScrollView>
  );
}
