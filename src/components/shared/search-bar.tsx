import { View, TextInput } from "react-native";
import { Search } from "lucide-react-native";

interface SearchBarProps {
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
}

export function SearchBar({
  value,
  onChangeText,
  placeholder = "Search capsules...",
}: SearchBarProps) {
  return (
    <View className="flex-row items-center bg-[#E8EAEE] dark:bg-[#353C48] rounded-2xl px-4 py-2.5">
      <Search size={16} color="#5A6072" />
      <TextInput
        className="flex-1 font-sans text-[#181B21] dark:text-[#EEF0F3] text-sm ml-2.5"
        placeholder={placeholder}
        placeholderTextColor="#5A6072"
        value={value}
        onChangeText={onChangeText}
      />
    </View>
  );
}
