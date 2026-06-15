import { useState } from "react";
import { View, Text, ScrollView, TouchableOpacity } from "react-native";
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
  const { data: openedCapsules, isLoading } = useOpenedCapsules();
  const searchCapsules = useSearchCapsules();

  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<Capsule[] | null>(null);

  const handleSearch = async (query: string) => {
    setSearchQuery(query);
    if (query.trim().length === 0) {
      setSearchResults(null);
      return;
    }
    const results = await searchCapsules(query);
    setSearchResults(results);
  };

  const displayCapsules = searchResults ?? openedCapsules ?? [];

  return (
    <ScrollView
      className="flex-1 bg-cream dark:bg-brown"
      contentContainerStyle={{ paddingBottom: 120 }}
    >
      <View style={{ paddingTop: insets.top + 16 }} className="px-4 pb-4">
        <Text className="font-heading text-3xl font-bold text-brown dark:text-cream mb-1">
          Archive
        </Text>
        <Text className="font-sans text-base text-muted-foreground mb-4">
          Memories you've already opened
        </Text>

        <SearchBar
          value={searchQuery}
          onChangeText={handleSearch}
          placeholder="Search capsules..."
        />
      </View>

      {displayCapsules.length === 0 ? (
        <EmptyState type="opened" />
      ) : (
        <View className="px-4 gap-3">
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
