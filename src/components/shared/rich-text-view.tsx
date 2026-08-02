import { View, Text } from "react-native";
import type { ContentBlock } from "@/lib/rich-text";

interface RichTextViewProps {
  blocks: ContentBlock[];
  compact?: boolean;
  textClassName?: string;
}

export function RichTextView({ blocks, compact, textClassName }: RichTextViewProps) {
  const visible = compact ? blocks.slice(0, 1) : blocks;

  return (
    <View className={compact ? "" : "gap-3"}>
      {visible.map((block) => (
        <Text
          key={block.id}
          numberOfLines={compact ? 2 : undefined}
          className={
            block.type === "heading"
              ? `font-heading text-xl font-bold text-[#181B21] dark:text-[#EEF0F3] ${block.underline ? "underline" : ""} ${textClassName ?? ""}`
              : `font-sans text-base leading-7 text-[#181B21] dark:text-[#EEF0F3] ${block.underline ? "underline" : ""} ${textClassName ?? ""}`
          }
        >
          {block.text}
        </Text>
      ))}
    </View>
  );
}
