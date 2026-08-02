import { View, Text, TouchableOpacity, Image } from "react-native";
import { Lock, Unlock, Archive, Timer, PenLine } from "lucide-react-native";
import type { Capsule } from "@/types/capsule";
import { CountdownTimer } from "./countdown-timer";
import { formatDate } from "@/lib/date";
import { parseBlocks } from "@/lib/rich-text";
import { RichTextView } from "@/components/shared/rich-text-view";

interface CapsuleCardProps {
  capsule: Capsule;
  onPress: () => void;
}

const statusConfig = {
  draft: {
    icon: PenLine,
    label: "Draft",
    gradient: "from-[#E8EAEE] to-[#E8EAEE]/80 dark:from-[#353C48] dark:to-[#353C48]/80",
    borderColor: "border-[#C9CFD8]/50",
  },
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
    gradient: "from-[#E8EAEE] to-[#E8EAEE]/80 dark:from-[#353C48] dark:to-[#353C48]/80",
    borderColor: "border-[#C9CFD8]/50",
  },
};

export function CapsuleCard({ capsule, onPress }: CapsuleCardProps) {
  const config = statusConfig[capsule.status];
  const Icon = config.icon;

  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.7}
      className="bg-[#EEF0F3] dark:bg-[#1C2027] rounded-2xl overflow-hidden border border-[#C9CFD8]/50 shadow-sm"
    >
      {/* Color accent bar */}
      <View
        className={`h-1.5 ${capsule.status === "ready" ? "bg-sage" : capsule.status === "sealed" ? "bg-sage/30" : "bg-[#C9CFD8] dark:bg-[#353C48]"}`}
      />

      <View className="p-4">
        {/* Header row */}
        <View className="flex-row items-start justify-between mb-3">
          <View className="flex-1 mr-3">
            <Text
              className="font-heading text-lg font-bold text-[#181B21] dark:text-[#EEF0F3]"
              numberOfLines={1}
            >
              {capsule.title}
            </Text>
            <Text className="font-sans text-xs text-[#5A6072] mt-0.5">
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
                  : "bg-[#E8EAEE] dark:bg-[#353C48]"
            }`}
          >
            <Icon
              size={12}
              color={
                capsule.status === "ready"
                  ? "#EEF0F3"
                  : capsule.status === "sealed"
                    ? "#3B608F"
                    : "#5A6072"
              }
            />
            <Text
              className={`font-sans text-xs font-semibold ${
                capsule.status === "ready"
                  ? "text-[#EEF0F3]"
                  : capsule.status === "sealed"
                    ? "text-sage"
                    : "text-[#5A6072]"
              }`}
            >
              {config.label}
            </Text>
          </View>
        </View>

        {/* Content preview */}
        {capsule.content ? (
          <View className="bg-[#E8EAEE]/50 dark:bg-[#353C48]/50 rounded-xl px-3 py-2.5 mb-3">
            <RichTextView blocks={parseBlocks(capsule.content)} compact />
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
        <View className="flex-row items-center justify-between pt-2.5 border-t border-[#C9CFD8]/50 dark:border-[#353C48]/50">
          <View className="flex-row items-center gap-1.5">
            {capsule.status === "draft" ? (
              <Text className="font-sans text-xs text-[#5A6072]">
                Not sealed yet
              </Text>
            ) : (
              <>
                {capsule.status === "sealed" && (
                  <Timer size={12} color="#5A6072" />
                )}
                <CountdownTimer openAt={capsule.openAt} size="sm" />
              </>
            )}
          </View>
          {capsule.openedAt && (
            <Text className="font-sans text-xs text-[#5A6072]">
              Opened {formatDate(capsule.openedAt)}
            </Text>
          )}
        </View>
      </View>
    </TouchableOpacity>
  );
}
