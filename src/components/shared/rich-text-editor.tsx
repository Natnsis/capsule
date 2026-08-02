import { useRef, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView } from "react-native";
import { Heading, Pilcrow, Underline as UnderlineIcon, Plus } from "lucide-react-native";

import { type BlockType, type ContentBlock, createEmptyBlock } from "@/lib/rich-text";

interface RichTextEditorProps {
  blocks: ContentBlock[];
  onChange: (blocks: ContentBlock[]) => void;
  placeholder?: string;
}

export function RichTextEditor({ blocks, onChange, placeholder }: RichTextEditorProps) {
  const [focusedId, setFocusedId] = useState<string | null>(blocks[0]?.id ?? null);
  const inputRefs = useRef<Record<string, TextInput | null>>({});

  const focusedBlock = blocks.find((b) => b.id === focusedId) ?? blocks[0];

  const updateBlock = (id: string, patch: Partial<ContentBlock>) => {
    onChange(blocks.map((b) => (b.id === id ? { ...b, ...patch } : b)));
  };

  const setFormat = (type: BlockType, underline: boolean) => {
    if (!focusedBlock) return;
    updateBlock(focusedBlock.id, { type, underline });
  };

  const addBlock = () => {
    const next = createEmptyBlock(
      focusedBlock?.type ?? "paragraph",
      focusedBlock?.underline ?? false
    );
    onChange([...blocks, next]);
    setFocusedId(next.id);
    requestAnimationFrame(() => inputRefs.current[next.id]?.focus());
  };

  const handleBackspace = (id: string, index: number) => {
    const block = blocks[index];
    if (block.text.length > 0 || blocks.length <= 1 || index === 0) return;
    const prev = blocks[index - 1];
    onChange(blocks.filter((b) => b.id !== id));
    setFocusedId(prev.id);
    requestAnimationFrame(() => inputRefs.current[prev.id]?.focus());
  };

  const isHeading = focusedBlock?.type === "heading";
  const isUnderline = !!focusedBlock?.underline;

  return (
    <View className="flex-1">
      {/* Format toolbar */}
      <View className="flex-row gap-2 mb-3">
        <ToolbarButton
          active={!isHeading}
          icon={Pilcrow}
          label="Paragraph"
          onPress={() => setFormat("paragraph", isUnderline)}
        />
        <ToolbarButton
          active={isHeading}
          icon={Heading}
          label="Header"
          onPress={() => setFormat("heading", isUnderline)}
        />
        <ToolbarButton
          active={isUnderline}
          icon={UnderlineIcon}
          label="Underline"
          onPress={() => focusedBlock && setFormat(focusedBlock.type, !isUnderline)}
        />
      </View>

      {/* Blocks */}
      <View className="flex-1 bg-[#E8EAEE] dark:bg-[#353C48] rounded-2xl px-5 py-4">
        <ScrollView className="flex-1" keyboardShouldPersistTaps="handled">
          <View className="gap-1">
          {blocks.map((block, index) => (
            <TextInput
              key={block.id}
              ref={(el) => {
                inputRefs.current[block.id] = el;
              }}
              value={block.text}
              onChangeText={(text) => updateBlock(block.id, { text })}
              onFocus={() => setFocusedId(block.id)}
              onKeyPress={({ nativeEvent }) => {
                if (nativeEvent.key === "Backspace") handleBackspace(block.id, index);
              }}
              placeholder={index === 0 ? placeholder : undefined}
              placeholderTextColor="#5A6072"
              multiline
              textAlignVertical="top"
              spellCheck
              autoCorrect
              className={
                block.type === "heading"
                  ? `font-heading text-xl font-bold text-[#181B21] dark:text-[#EEF0F3] py-1.5 ${block.underline ? "underline" : ""}`
                  : `font-sans text-base leading-6 text-[#181B21] dark:text-[#EEF0F3] py-1.5 ${block.underline ? "underline" : ""}`
              }
            />
          ))}

          <TouchableOpacity
            onPress={addBlock}
            className="flex-row items-center gap-1.5 py-2 opacity-60"
          >
            <Plus size={14} color="#5A6072" />
            <Text className="font-sans text-xs text-[#5A6072]">Add a line</Text>
          </TouchableOpacity>
          </View>
        </ScrollView>
      </View>
    </View>
  );
}

function ToolbarButton({
  active,
  icon: Icon,
  label,
  onPress,
}: {
  active: boolean;
  icon: typeof Heading;
  label: string;
  onPress: () => void;
}) {
  return (
    <TouchableOpacity
      onPress={onPress}
      accessibilityLabel={label}
      className={`flex-row items-center gap-1.5 rounded-full px-3.5 py-2 ${
        active ? "bg-sage" : "bg-[#E8EAEE] dark:bg-[#353C48]"
      }`}
    >
      <Icon size={14} color={active ? "#EEF0F3" : "#5A6072"} />
      <Text
        className={`font-sans text-xs font-semibold ${
          active ? "text-[#EEF0F3]" : "text-[#5A6072]"
        }`}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );
}
