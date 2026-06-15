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
    <View className="flex-row items-center bg-[#E4E0DA] dark:bg-[#5E4F53] rounded-2xl px-4 py-2.5">
      <Search size={16} color="#7A6E71" />
      <TextInput
        className="flex-1 font-sans text-[#41393C] dark:text-[#F2EFEA] text-sm ml-2.5"
        placeholder={placeholder}
        placeholderTextColor="#7A6E71"
        value={value}
        onChangeText={onChangeText}
      />
    </View>
  );
}
