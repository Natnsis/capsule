import { TextInput, type TextInputProps, View } from "react-native";

type InputProps = TextInputProps & {
  icon?: React.ReactNode;
};

export function Input({ icon, className, ...props }: InputProps) {
  return (
    <View className="flex-row items-center bg-muted rounded-full px-4 py-3">
      {icon && <View className="mr-3">{icon}</View>}
      <TextInput
        className={`flex-1 font-sans text-brown dark:text-cream text-base ${className ?? ""}`}
        placeholderTextColor="#7A6E71"
        {...props}
      />
    </View>
  );
}
