import { TouchableOpacity, View } from "react-native";
import { Sun, Moon } from "lucide-react-native";
import { useThemeStore } from "@/stores/theme-store";

export function ThemeToggle() {
  const mode = useThemeStore((s) => s.mode);
  const setDark = useThemeStore((s) => s.setDark);
  const isDark = mode === "dark";

  return (
    <TouchableOpacity
      onPress={() => setDark(!isDark)}
      className="bg-muted rounded-full p-2"
    >
      {isDark ? (
        <Sun size={20} color="#F2EFEA" />
      ) : (
        <Moon size={20} color="#41393C" />
      )}
    </TouchableOpacity>
  );
}
