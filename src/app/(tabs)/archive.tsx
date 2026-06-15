import { useState, useCallback } from "react";
import { View, ScrollView } from "react-native";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useOpenedCapsules, useSearchCapsules } from "@/hooks/use-capsules";
import { CapsuleCard } from "@/components/capsules/capsule-card";
import { EmptyState } from "@/components/shared/empty-state";
import { SearchBar } from "@/components/shared/search-bar";
import type { Capsule } from "@/types/capsule";

export default function ArchiveScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { data: openedCapsules } = useOpenedCapsules();
  const searchCapsules = useSearchCapsules();

  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<Capsule[] | null>(null);

  const handleSearch = useCallback(async (query: string) => {
    setSearchQuery(query);
    if (query.trim().length === 0) {
      setSearchResults(null);
      return;
    }
    const results = await searchCapsules(query);
    setSearchResults(results);
  }, [searchCapsules]);

  const displayCapsules = searchResults ?? openedCapsules ?? [];

  return (
    <ScrollView
      className="flex-1 bg-[#F2EFEA] dark:bg-[#41393C]"
      contentContainerStyle={{ paddingBottom: 120 }}
    >
      <View style={{ paddingTop: insets.top + 12 }} className="px-4 pb-2">
        <SearchBar
          value={searchQuery}
          onChangeText={handleSearch}
          placeholder="Search capsules..."
        />
      </View>

      {displayCapsules.length === 0 ? (
        <EmptyState type="opened" />
      ) : (
        <View className="px-4 gap-4 mt-4">
          {displayCapsules.map((capsule: Capsule) => (
            <CapsuleCard
              key={capsule.id}
              capsule={capsule}
              onPress={() => router.push(`/capsule/${capsule.id}`)}
            />
          ))}
        </View>
      )}
    </ScrollView>
  );
}
