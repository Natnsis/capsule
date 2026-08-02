import { View, Text, type ViewProps } from "react-native";

type BadgeProps = ViewProps & {
  variant?: "default" | "active" | "outline";
  label: string;
};

export function Badge({ variant = "default", label, className, ...props }: BadgeProps) {
  const variantClasses = {
    default: "bg-muted dark:bg-[#353C48]",
    active: "bg-sage",
    outline: "bg-transparent border border-border",
  };

  const textClasses = {
    default: "text-muted-foreground",
    active: "text-cream",
    outline: "text-brown dark:text-cream",
  };

  return (
    <View
      className={`rounded-full px-4 py-1.5 ${variantClasses[variant]} ${className ?? ""}`}
      {...props}
    >
      <Text className={`font-sans text-sm font-medium ${textClasses[variant]}`}>
        {label}
      </Text>
    </View>
  );
}
