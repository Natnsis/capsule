import { View, Text, TouchableOpacity, Image } from "react-native";
import { Lock, Unlock, Archive, Timer } from "lucide-react-native";
import type { Capsule } from "@/types/capsule";
import { CountdownTimer } from "./countdown-timer";
import { formatDate } from "@/lib/date";

interface CapsuleCardProps {
  capsule: Capsule;
  onPress: () => void;
}

const statusConfig = {
  sealed: {
    icon: Lock,
    label: "Sealed",
    gradient: "from-sage/10 to-sage/5",
    borderColor: "border-sage/20",
  },
  ready: {
    icon: Unlock,
    label: "Ready to Open",
    gradient: "from-sage to-sage/90",
    borderColor: "border-sage",
  },
  opened: {
    icon: Archive,
    label: "Opened",
    gradient: "from-[#E4E0DA] to-[#E4E0DA]/80 dark:from-[#5E4F53] dark:to-[#5E4F53]/80",
    borderColor: "border-[#D5D0CA]/50",
  },
};

export function CapsuleCard({ capsule, onPress }: CapsuleCardProps) {
  const config = statusConfig[capsule.status];
  const Icon = config.icon;

  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.7}
      className="bg-[#F2EFEA] dark:bg-[#4E4449] rounded-2xl overflow-hidden border border-[#D5D0CA]/50 shadow-sm"
    >
      {/* Color accent bar */}
      <View
        className={`h-1.5 ${capsule.status === "ready" ? "bg-sage" : capsule.status === "sealed" ? "bg-sage/30" : "bg-[#D5D0CA] dark:bg-[#5E4F53]"}`}
      />

      <View className="p-4">
        {/* Header row */}
        <View className="flex-row items-start justify-between mb-3">
          <View className="flex-1 mr-3">
            <Text
              className="font-heading text-lg font-bold text-[#41393C] dark:text-[#F2EFEA]"
              numberOfLines={1}
            >
              {capsule.title}
            </Text>
            <Text className="font-sans text-xs text-[#7A6E71] mt-0.5">
              Created {formatDate(capsule.createdAt)}
            </Text>
          </View>

          {/* Status badge */}
          <View
            className={`flex-row items-center rounded-full px-3 py-1.5 gap-1.5 ${
              capsule.status === "ready"
                ? "bg-sage"
                : capsule.status === "sealed"
                  ? "bg-sage/10"
                  : "bg-[#E4E0DA] dark:bg-[#5E4F53]"
            }`}
          >
            <Icon
              size={12}
              color={
                capsule.status === "ready"
                  ? "#F2EFEA"
                  : capsule.status === "sealed"
                    ? "#82B090"
                    : "#7A6E71"
              }
            />
            <Text
              className={`font-sans text-xs font-semibold ${
                capsule.status === "ready"
                  ? "text-[#F2EFEA]"
                  : capsule.status === "sealed"
                    ? "text-sage"
                    : "text-[#7A6E71]"
              }`}
            >
              {config.label}
            </Text>
          </View>
        </View>

        {/* Content preview */}
        {capsule.content ? (
          <View className="bg-[#E4E0DA]/50 dark:bg-[#5E4F53]/50 rounded-xl px-3 py-2.5 mb-3">
            <Text
              className="font-sans text-sm text-[#7A6E71] leading-5"
              numberOfLines={2}
            >
              {capsule.content}
            </Text>
          </View>
        ) : null}

        {/* Photos */}
        {capsule.imageUris.length > 0 && (
          <View className="flex-row gap-2 mb-3">
            {capsule.imageUris.slice(0, 3).map((uri, index) => (
              <Image
                key={index}
                source={{ uri }}
                className="w-12 h-12 rounded-lg"
              />
            ))}
          </View>
        )}

        {/* Tags */}
        {capsule.tags.length > 0 && (
          <View className="flex-row flex-wrap gap-1.5 mb-3">
            {capsule.tags.map((tag) => (
              <View
                key={tag}
                className="bg-sage/10 rounded-full px-2.5 py-0.5"
              >
                <Text className="font-sans text-xs text-sage">{tag}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Footer */}
        <View className="flex-row items-center justify-between pt-2.5 border-t border-[#D5D0CA]/50 dark:border-[#5E4F53]/50">
          <View className="flex-row items-center gap-1.5">
            {capsule.status === "sealed" && (
              <Timer size={12} color="#7A6E71" />
            )}
            <CountdownTimer openAt={capsule.openAt} size="sm" />
          </View>
          {capsule.openedAt && (
            <Text className="font-sans text-xs text-[#7A6E71]">
              Opened {formatDate(capsule.openedAt)}
            </Text>
          )}
        </View>
      </View>
    </TouchableOpacity>
  );
}
