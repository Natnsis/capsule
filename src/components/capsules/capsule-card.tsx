import { View, Text, TouchableOpacity, Image } from "react-native";
import type { Capsule } from "@/types/capsule";
import { StatusBadge } from "./status-badge";
import { CountdownTimer } from "./countdown-timer";
import { formatDate } from "@/lib/date";

interface CapsuleCardProps {
  capsule: Capsule;
  onPress: () => void;
  variant?: "default" | "compact";
}

export function CapsuleCard({ capsule, onPress, variant = "default" }: CapsuleCardProps) {
  if (variant === "compact") {
    return (
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
        className="bg-cream dark:bg-[#4E4449] rounded-xl p-4 flex-row items-center gap-3"
      >
        <View className="w-12 h-12 rounded-full bg-sage/20 items-center justify-center">
          <Text className="font-heading text-lg text-sage font-bold">
            {capsule.title.charAt(0).toUpperCase()}
          </Text>
        </View>
        <View className="flex-1">
          <Text className="font-heading text-base font-semibold text-brown dark:text-cream" numberOfLines={1}>
            {capsule.title}
          </Text>
          <CountdownTimer openAt={capsule.openAt} size="sm" />
        </View>
        <StatusBadge status={capsule.status} />
      </TouchableOpacity>
    );
  }

  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.7}
      className="bg-cream dark:bg-[#4E4449] rounded-2xl p-5 shadow-sm border border-border/50"
    >
      <View className="flex-row items-start justify-between mb-3">
        <Text className="font-heading text-lg font-semibold text-brown dark:text-cream flex-1 mr-2" numberOfLines={1}>
          {capsule.title}
        </Text>
        <StatusBadge status={capsule.status} />
      </View>

      {capsule.content ? (
        <Text className="font-sans text-sm text-muted-foreground mb-3 leading-5" numberOfLines={2}>
          {capsule.content}
        </Text>
      ) : null}

      {capsule.imageUris.length > 0 && (
        <View className="flex-row gap-2 mb-3">
          {capsule.imageUris.slice(0, 3).map((uri, index) => (
            <Image
              key={index}
              source={{ uri }}
              className="w-14 h-14 rounded-lg"
            />
          ))}
        </View>
      )}

      {capsule.tags.length > 0 && (
        <View className="flex-row flex-wrap gap-1.5 mb-3">
          {capsule.tags.map((tag) => (
            <View key={tag} className="bg-sage/10 rounded-full px-2.5 py-0.5">
              <Text className="font-sans text-xs text-sage">{tag}</Text>
            </View>
          ))}
        </View>
      )}

      <View className="flex-row items-center justify-between pt-2 border-t border-border/50">
        <Text className="font-sans text-xs text-muted-foreground">
          Created {formatDate(capsule.createdAt)}
        </Text>
        <CountdownTimer openAt={capsule.openAt} size="sm" />
      </View>
    </TouchableOpacity>
  );
}
